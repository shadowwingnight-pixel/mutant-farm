-- Pure, versioned serialization. Existing malformed/future records fail closed.
local PlayerData = { Version = 3 }
local function integer(value, max)
	return type(value) == "number" and value == value and value >= 0 and value <= max and value % 1 == 0
end
local function map(value, allowed, booleanValues, max)
	if value == nil then value = {} end
	if type(value) ~= "table" then return nil end
	local result = {}
	for key, item in pairs(value) do
		if not allowed[key] then return nil end -- Do not silently delete retired/unknown items.
		if booleanValues then
			if type(item) ~= "boolean" then return nil end
		elseif not integer(item, max) then return nil end
		result[key] = item
	end
	for key in pairs(allowed) do
		if result[key] == nil then
			if booleanValues then result[key] = false else result[key] = 0 end
		end
	end
	return result
end

function PlayerData.decode(raw, config)
	local fresh = raw == nil
	if fresh then raw = { version = PlayerData.Version, coins = config.StartingCoins } end
	if type(raw) ~= "table" then return nil, "Profile is not a table" end
	-- Version 0 is the documented flat predecessor; missing version is accepted
	-- only when coins is valid. Optional new fields migrate to explicit defaults.
	local version = raw.version == nil and 0 or raw.version
	if version ~= 0 and version ~= 1 and version ~= 2 and version ~= 3 then return nil, "Unsupported data version" end
	if not integer(raw.coins, 9000000000000) then return nil, "Invalid Coins" end
	local mutations = {}
	for _, mutation in ipairs(config.Mutations) do mutations[mutation.Id] = true end
	local result = { version = 3, coins = raw.coins, bag = {}, discoveries = {} }
	result.experimentalSeeds = map(raw.experimentalSeeds, config.Research.Catalog, false, config.Research.MaxStack)
	result.researchFound = map(raw.researchFound, config.Research.Discoveries, true)
	result.researchCount = raw.researchCount == nil and 0 or raw.researchCount
	result.selectedExperiment = raw.selectedExperiment == nil and "" or raw.selectedExperiment
	if not result.experimentalSeeds or not result.researchFound or not integer(result.researchCount,1000000000) then return nil, "Invalid research data" end
	if type(result.selectedExperiment) ~= "string" or (result.selectedExperiment ~= "" and not config.Research.Catalog[result.selectedExperiment]) then return nil, "Invalid experimental selection" end
	local source = raw.experimentalBag == nil and {} or raw.experimentalBag
	if type(source) ~= "table" then return nil, "Invalid experimental harvests" end
	for id in pairs(source) do if not config.Research.Catalog[id] then return nil, "Unknown experimental harvest" end end
	result.experimentalBag = {}
	for id in pairs(config.Research.Catalog) do
		result.experimentalBag[id] = map(source[id], mutations, false, config.Research.MaxStack)
		if not result.experimentalBag[id] then return nil, "Invalid experimental harvest counts" end
	end
	result.objectiveStep = raw.objectiveStep == nil and 0 or raw.objectiveStep
	if not integer(result.objectiveStep, #config.Objectives) then return nil, "Invalid objective progress" end
	result.earnedCoins = raw.earnedCoins == nil and 0 or raw.earnedCoins
	result.expansionTier = raw.expansionTier == nil and 1 or raw.expansionTier
	result.selectedCrop = raw.selectedCrop == nil and config.CropOrder[1] or raw.selectedCrop
	if not integer(result.earnedCoins, 9000000000000) then return nil, "Invalid earnings" end
	if not integer(result.expansionTier, #config.Expansions) or result.expansionTier < 1 then return nil, "Invalid expansion tier" end
	if type(result.selectedCrop) ~= "string" or not config.Crops[result.selectedCrop] then return nil, "Unknown selected crop" end
	result.seeds = map(raw.seeds, config.Crops, false, 1000000000)
	result.harvested = map(raw.harvested, config.Crops, false, 9000000000000)
	result.unlocked = map(raw.unlocked, config.Crops, true)
	if not result.seeds or not result.harvested or not result.unlocked then return nil, "Invalid inventory/progression" end
	for _, field in ipairs({ "bag", "discoveries" }) do
		local source = raw[field]
		if source == nil then source = {} end
		if type(source) ~= "table" then return nil, "Invalid " .. field end
		for cropId in pairs(source) do if not config.Crops[cropId] then return nil, "Unknown saved crop" end end
		for cropId in pairs(config.Crops) do
			result[field][cropId] = map(source[cropId], mutations, field == "discoveries", 1000000000)
			if not result[field][cropId] then return nil, "Invalid " .. field .. " entries" end
		end
	end
	result.unlocked[config.CropOrder[1]] = true
	return result, fresh and "New player" or (version < PlayerData.Version and "Migrated v" .. version or "Loaded")
end

function PlayerData.capture(state, config)
	-- decode also deep-copies all durable fields so writes cannot observe later mutations.
	local snapshot, problem = PlayerData.decode({ version = 3, coins = state.coins, seeds = state.seeds,
		bag = state.bag, earnedCoins = state.earnedCoins, harvested = state.harvested,
		unlocked = state.unlocked, discoveries = state.discoveries, selectedCrop = state.selectedCrop,
		expansionTier = state.expansionTier, objectiveStep = state.objectiveStep,
		experimentalSeeds = state.experimentalSeeds, experimentalBag = state.experimentalBag,
		researchFound = state.researchFound, researchCount = state.researchCount, selectedExperiment = state.selectedExperiment }, config)
	assert(snapshot, problem)
	return snapshot -- Never includes plot/growing-crop state.
end

return PlayerData
