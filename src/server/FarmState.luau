-- Pure server-side state. No yielding: each purchase/harvest/sale is atomic.
local FarmState = {}
FarmState.__index = FarmState

function FarmState.new(config)
	local self = setmetatable({ config = config, coins = config.StartingCoins, seeds = {}, bag = {}, plots = {},
		earnedCoins = 0, harvested = {}, unlocked = {}, discoveries = {}, selectedCrop = config.CropOrder[1], expansionTier = 1, objectiveStep = 0 }, FarmState)
	for cropId in pairs(config.Crops) do
		self.seeds[cropId] = 0
		self.bag[cropId] = {}
		self.harvested[cropId] = 0
		self.discoveries[cropId] = {}
	end
	self.experimentalSeeds, self.experimentalBag, self.researchFound = {}, {}, {}
	self.researchCount, self.selectedExperiment = 0, ""
	for id in pairs(config.Research.Catalog) do self.experimentalSeeds[id] = 0; self.experimentalBag[id] = {} end
	for i = 1, config.PlotCount do
		self.plots[i] = { stage = 0 }
	end
	self:refreshUnlocks()
	return self
end

-- Data passed here has already been decoded/validated by PlayerData.
function FarmState.fromData(config, data)
	local self = FarmState.new(config)
	for _, field in ipairs({ "coins", "seeds", "bag", "earnedCoins", "harvested", "unlocked", "discoveries", "selectedCrop", "expansionTier", "objectiveStep" }) do
		self[field] = data[field]
	end
	self:refreshUnlocks()
	if not self.unlocked[self.selectedCrop] then self.selectedCrop = config.CropOrder[1] end
	for _, field in ipairs({"experimentalSeeds", "experimentalBag", "researchFound", "researchCount", "selectedExperiment"}) do self[field] = data[field] end
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
	self.selectedExperiment = ""
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
	self.selectedExperiment = ""
	return true, cropId .. " Seed +1"
end

function FarmState:plant(index, cropId, now)
	local plot = self.plots[index]
	local experiment = self.config.Research.Catalog[self.selectedExperiment]
	if experiment then
		if not plot or plot.stage ~= 0 then return false, "Choose empty soil." end
		if self.experimentalSeeds[self.selectedExperiment] < 1 then return false, "No experimental seed left. Select another seed." end
		self.experimentalSeeds[self.selectedExperiment] -= 1
		plot.cropId, plot.plantedAt, plot.stage, plot.experiment = experiment.Crop, now, 1, self.selectedExperiment
		return true, experiment.Name .. " planted!"
	end
	if not plot or not self.config.Crops[cropId] then return false, "Invalid plot or crop." end
	if not self.unlocked[cropId] then return false, "This crop is locked." end
	if plot.stage ~= 0 then return false, "This plot is already growing." end
	if self.seeds[cropId] < 1 then return false, "No " .. cropId .. " Seeds. Buy more or select another seed." end
	self.seeds[cropId] -= 1
	plot.cropId, plot.plantedAt, plot.stage = cropId, now, 1
	return true, cropId .. " planted!"
end

function FarmState:advance(now, randomInteger, mutationWeights)
	local baseline = mutationWeights or self.config.Mutations
	local changed = {}
	for index, plot in ipairs(self.plots) do
		local crop = self.config.Crops[plot.cropId]
		if crop and plot.stage > 0 and plot.stage < #crop.GrowthStages then
			local experiment = self.config.Research.Catalog[plot.experiment]
			local trait = experiment and self.config.Research.Traits[experiment.Trait]
			local mutations = baseline
			if trait and trait.Affinity ~= 1 then
				mutations = {}
				for _, mutation in ipairs(baseline) do
					table.insert(mutations, { Id = mutation.Id, Weight = math.max(1,math.floor(mutation.Weight * (mutation.Id == "Normal" and 1 or trait.Affinity))) })
				end
			end
			local stage = 1
			for index, growth in ipairs(crop.GrowthStages) do
				if now - plot.plantedAt >= crop.GrowSeconds * (trait and trait.Grow or 1) * growth.At then stage = index end
			end
			if stage > plot.stage then
				plot.stage = stage
				if stage == #crop.GrowthStages then
					local total = 0
					for _, mutation in ipairs(mutations) do total += mutation.Weight end
					local roll = randomInteger(1, total)
					for _, mutation in ipairs(mutations) do
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
	local inventory = plot.experiment and self.experimentalBag[plot.experiment] or self.bag[plot.cropId]
	if plot.experiment and (inventory[plot.mutation] or 0) >= self.config.Research.MaxStack then return false, "Experimental basket full for this result. Sell before harvesting." end
	inventory[plot.mutation] = (inventory[plot.mutation] or 0) + 1
	self.harvested[plot.cropId] += 1
	local newDiscovery = not self.discoveries[plot.cropId][plot.mutation]
	self.discoveries[plot.cropId][plot.mutation] = true
	if plot.experiment then
		local key = "Grown_" .. self.config.Research.Catalog[plot.experiment].Trait
		newDiscovery = newDiscovery or not self.researchFound[key]
		self.researchFound[key] = true
	end
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
	for id, inventory in pairs(self.experimentalBag) do
		local entry = self.config.Research.Catalog[id]
		local trait = self.config.Research.Traits[entry.Trait]
		for _, mutation in ipairs(self.config.Mutations) do
			local amount = inventory[mutation.Id] or 0
			count += amount
			value += amount * math.floor(self.config.Crops[entry.Crop].BaseValue * mutation.Multiplier * trait.Value)
		end
	end
	return count, value
end

function FarmState:sell()
	local count, value = self:bagSummary()
	if count == 0 then return false, "Harvest a ripe crop before selling." end
	for cropId in pairs(self.bag) do self.bag[cropId] = {} end
	for id in pairs(self.experimentalBag) do self.experimentalBag[id] = {} end
	self.coins += value
	self.earnedCoins += value
	return true, "Sold " .. count .. " crops! +" .. value .. " Coins", self:refreshUnlocks()
end

function FarmState:selectExperiment(id)
	local entry = type(id) == "string" and self.config.Research.Catalog[id]
	if not entry or self.experimentalSeeds[id] < 1 then return false, "Experimental seed unavailable." end
	self.selectedExperiment, self.selectedCrop = id, entry.Crop
	return true, "Planting " .. entry.Name .. " • " .. entry.Trait
end

function FarmState:research(aId, bId, randomInteger)
	local config = self.config.Research
	local a = type(aId) == "string" and config.Specimens[aId]
	local b = type(bId) == "string" and config.Specimens[bId]
	if not a or not b then return false, "Choose two valid harvested specimens." end
	if not config.Compatibility[a.Crop][b.Crop] then return false, "Incompatible: Pumpkin crosses only with Pumpkin in V1." end
	if self.coins < config.Cost then return false, "Need " .. config.Cost .. " Coins." end
	if (self.bag[a.Crop][a.Mutation] or 0) < (aId == bId and 2 or 1) or (self.bag[b.Crop][b.Mutation] or 0) < 1 then return false, "Not enough specimens. Nothing consumed." end
	-- Check every possible result before rolling. Full inventories never spend parents.
	for _, crop in ipairs({a.Crop,b.Crop}) do
		for _, trait in ipairs(config.TraitOrder) do
			if self.experimentalSeeds[crop .. "_" .. trait] >= config.MaxStack then return false, "Experimental seed storage full. Plant seeds first." end
		end
	end
	local weights, total = {},0
	for i in ipairs(config.TraitOrder) do weights[i] = 1 + config.ParentWeights[a.Mutation][i] + config.ParentWeights[b.Mutation][i]; total += weights[i] end
	local roll, inherited = randomInteger(1,total), config.TraitOrder[1]
	for i, weight in ipairs(weights) do roll -= weight; if roll <= 0 then inherited = config.TraitOrder[i]; break end end
	local crop = randomInteger(1,2) == 1 and a.Crop or b.Crop
	local id = crop .. "_" .. inherited
	-- Atomic acceptance: RNG and all validation finish before consuming anything.
	self.coins -= config.Cost
	self.bag[a.Crop][a.Mutation] -= 1
	self.bag[b.Crop][b.Mutation] -= 1
	self.experimentalSeeds[id] += 1
	self.researchCount = math.min(1000000000,self.researchCount + 1)
	local combo = a.Crop < b.Crop and a.Crop .. "_" .. b.Crop or b.Crop .. "_" .. a.Crop
	local first = not self.researchFound[combo] or not self.researchFound["Trait_" .. inherited]
	self.researchFound[combo], self.researchFound["Trait_" .. inherited] = true,true
	return true, (first and "NEW RESEARCH DISCOVERY!\n" or "CROSS SUCCESSFUL!\n") .. config.Catalog[id].Name .. " • " .. inherited .. " seed created", id, first
end
return FarmState
