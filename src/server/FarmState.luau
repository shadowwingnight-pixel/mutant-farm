-- Pure server-side state. No yielding: each purchase/harvest/sale is atomic.
local FarmState = {}
FarmState.__index = FarmState

function FarmState.new(config)
	local self = setmetatable({ config = config, coins = config.StartingCoins, seeds = {}, bag = {}, plots = {},
		earnedCoins = 0, harvested = {}, unlocked = {}, discoveries = {}, selectedCrop = config.CropOrder[1], expansionTier = 1 }, FarmState)
	for cropId in pairs(config.Crops) do
		self.seeds[cropId] = 0
		self.bag[cropId] = {}
		self.harvested[cropId] = 0
		self.discoveries[cropId] = {}
	end
	for i = 1, config.PlotCount do
		self.plots[i] = { stage = 0 }
	end
	self:refreshUnlocks()
	return self
end

-- Data passed here has already been decoded/validated by PlayerData.
function FarmState.fromData(config, data)
	local self = FarmState.new(config)
	for _, field in ipairs({ "coins", "seeds", "bag", "earnedCoins", "harvested", "unlocked", "discoveries", "selectedCrop", "expansionTier" }) do
		self[field] = data[field]
	end
	self:refreshUnlocks()
	if not self.unlocked[self.selectedCrop] then self.selectedCrop = config.CropOrder[1] end
	self.plots = {}
	for index = 1, config.Expansions[self.expansionTier].Plots do self.plots[index] = { stage = 0 } end
	return self
end

function FarmState:expand()
	local nextTier = self.config.Expansions[self.expansionTier + 1]
	if not nextTier then return false, "Your farm is fully expanded." end
	if self.coins < nextTier.Cost then return false, "Need " .. nextTier.Cost .. " Coins to expand." end
	self.coins -= nextTier.Cost
	self.expansionTier += 1
	for index = #self.plots + 1, nextTier.Plots do self.plots[index] = { stage = 0 } end
	return true, nextTier.Name .. " unlocked! " .. nextTier.Plots .. " plots"
end

function FarmState:refreshUnlocks()
	local newlyUnlocked = {}
	for _, cropId in ipairs(self.config.CropOrder) do
		local rule = self.config.Crops[cropId].Unlock
		if not self.unlocked[cropId] and self.earnedCoins >= rule.EarnedCoins
			and (not rule.PreviousCrop or (self.unlocked[rule.PreviousCrop] and self.harvested[rule.PreviousCrop] >= rule.Harvests)) then
			self.unlocked[cropId] = true
			table.insert(newlyUnlocked, cropId)
		end
	end
	return newlyUnlocked
end

function FarmState:select(cropId)
	if type(cropId) ~= "string" or not self.config.Crops[cropId] then return false, "Unknown seed." end
	if not self.unlocked[cropId] then return false, cropId .. " is locked. Check Seeds for requirements." end
	if self.seeds[cropId] < 1 then return false, "Buy a " .. cropId .. " Seed first." end
	self.selectedCrop = cropId
	return true, "Planting " .. cropId .. " • Click empty soil"
end

function FarmState:buy(cropId)
	if type(cropId) ~= "string" then return false, "Unknown seed." end
	local crop = self.config.Crops[cropId]
	if not crop then return false, "Unknown seed." end
	if not self.unlocked[cropId] then return false, cropId .. " is locked. Check Seeds for requirements." end
	if self.coins < crop.SeedPrice then return false, "Need " .. crop.SeedPrice .. " Coins for a seed." end
	self.coins -= crop.SeedPrice
	self.seeds[cropId] += 1
	self.selectedCrop = cropId
	return true, cropId .. " Seed +1"
end

function FarmState:plant(index, cropId, now)
	local plot = self.plots[index]
	if not plot or not self.config.Crops[cropId] then return false, "Invalid plot or crop." end
	if not self.unlocked[cropId] then return false, "This crop is locked." end
	if plot.stage ~= 0 then return false, "This plot is already growing." end
	if self.seeds[cropId] < 1 then return false, "No " .. cropId .. " Seeds. Buy more or select another seed." end
	self.seeds[cropId] -= 1
	plot.cropId, plot.plantedAt, plot.stage = cropId, now, 1
	return true, cropId .. " planted!"
end

function FarmState:advance(now, randomInteger)
	local changed = {}
	for index, plot in ipairs(self.plots) do
		local crop = self.config.Crops[plot.cropId]
		if crop and plot.stage > 0 and plot.stage < #crop.GrowthStages then
			local stage = 1
			for index, growth in ipairs(crop.GrowthStages) do
				if now - plot.plantedAt >= crop.GrowSeconds * growth.At then stage = index end
			end
			if stage > plot.stage then
				plot.stage = stage
				if stage == #crop.GrowthStages then
					local total = 0
					for _, mutation in ipairs(self.config.Mutations) do total += mutation.Weight end
					local roll = randomInteger(1, total)
					for _, mutation in ipairs(self.config.Mutations) do
						roll -= mutation.Weight
						if roll <= 0 then plot.mutation = mutation.Id; break end
					end
				end
				table.insert(changed, index)
			end
		end
	end
	return changed
end

function FarmState:harvest(index)
	local plot = self.plots[index]
	if not plot or not plot.cropId or plot.stage ~= #self.config.Crops[plot.cropId].GrowthStages then return false, "Still growing. Watch for READY!" end
	local inventory = self.bag[plot.cropId]
	inventory[plot.mutation] = (inventory[plot.mutation] or 0) + 1
	self.harvested[plot.cropId] += 1
	local newDiscovery = not self.discoveries[plot.cropId][plot.mutation]
	self.discoveries[plot.cropId][plot.mutation] = true
	local message = plot.mutation .. " " .. plot.cropId .. " harvested!"
	self.plots[index] = { stage = 0 }
	return true, message, newDiscovery
end

function FarmState:bagSummary()
	local count, value = 0, 0
	for cropId, inventory in pairs(self.bag) do
		for _, mutation in ipairs(self.config.Mutations) do
			local amount = inventory[mutation.Id] or 0
			count += amount
			value += amount * math.floor(self.config.Crops[cropId].BaseValue * mutation.Multiplier)
		end
	end
	return count, value
end

function FarmState:sell()
	local count, value = self:bagSummary()
	if count == 0 then return false, "Harvest a ripe crop before selling." end
	for cropId in pairs(self.bag) do self.bag[cropId] = {} end
	self.coins += value
	self.earnedCoins += value
	return true, "Sold " .. count .. " crops! +" .. value .. " Coins", self:refreshUnlocks()
end

return FarmState
