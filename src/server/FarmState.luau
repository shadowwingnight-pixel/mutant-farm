-- Pure server-side state. No yielding: each purchase/harvest/sale is atomic.
local FarmState = {}
FarmState.__index = FarmState

function FarmState.new(config)
	local self = setmetatable({ config = config, coins = config.StartingCoins, seeds = {}, bag = {}, plots = {} }, FarmState)
	for cropId in pairs(config.Crops) do
		self.seeds[cropId] = 0
		self.bag[cropId] = {}
	end
	for i = 1, config.PlotCount do
		self.plots[i] = { stage = 0 }
	end
	return self
end

function FarmState:buy(cropId)
	local crop = self.config.Crops[cropId]
	if not crop then return false, "Unknown seed." end
	if self.coins < crop.SeedPrice then return false, "Need " .. crop.SeedPrice .. " Coins for a seed." end
	self.coins -= crop.SeedPrice
	self.seeds[cropId] += 1
	return true, cropId .. " Seed +1"
end

function FarmState:plant(index, cropId, now)
	local plot = self.plots[index]
	if not plot or not self.config.Crops[cropId] then return false, "Invalid plot or crop." end
	if plot.stage ~= 0 then return false, "This plot is already growing." end
	if self.seeds[cropId] < 1 then return false, "Buy a Tomato Seed at the green shop first." end
	self.seeds[cropId] -= 1
	plot.cropId, plot.plantedAt, plot.stage = cropId, now, 1
	return true, cropId .. " planted!"
end

function FarmState:advance(now, randomInteger)
	local changed = {}
	for index, plot in ipairs(self.plots) do
		if plot.stage > 0 and plot.stage < 4 then
			local duration = self.config.Crops[plot.cropId].GrowSeconds
			local stage = math.clamp(1 + math.floor((now - plot.plantedAt) / (duration / 3)), 1, 4)
			if stage > plot.stage then
				plot.stage = stage
				if stage == 4 then
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
	if not plot or plot.stage ~= 4 then return false, "Still growing. Watch for READY!" end
	local inventory = self.bag[plot.cropId]
	inventory[plot.mutation] = (inventory[plot.mutation] or 0) + 1
	local message = plot.mutation .. " " .. plot.cropId .. " harvested!"
	self.plots[index] = { stage = 0 }
	return true, message
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
	if count == 0 then return false, "Harvest a ripe Tomato before selling." end
	for cropId in pairs(self.bag) do self.bag[cropId] = {} end
	self.coins += value
	return true, "Sold " .. count .. " Tomatoes! +" .. value .. " Coins"
end

return FarmState
