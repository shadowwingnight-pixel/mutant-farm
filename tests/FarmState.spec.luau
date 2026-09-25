local Config = require("../src/shared/Config")
local FarmState = require("../src/server/FarmState")
local passed = 0
local function test(name, callback)
	callback()
	passed += 1
	print("PASS " .. name)
end
local function normal() return 1 end
local function planted()
	local state = FarmState.new(Config)
	assert(state:buy("Tomato"))
	assert(state:plant(1, "Tomato", 0))
	return state
end

test("new players have 100 Coins, empty inventories and six independent plots", function()
	local a, b = FarmState.new(Config), FarmState.new(Config)
	assert(a.coins == 100 and a.seeds.Tomato == 0 and #a.plots == 6)
	assert(a:bagSummary() == 0)
	a:buy("Tomato")
	assert(b.coins == 100 and b.seeds.Tomato == 0)
end)

test("purchase charges 10; overspending and invalid crops do not change inventory", function()
	local state = FarmState.new(Config)
	for _ = 1, 10 do assert(state:buy("Tomato")) end
	assert(state.coins == 0 and state.seeds.Tomato == 10)
	assert(not state:buy("Tomato"))
	assert(not state:buy("Fake"))
	assert(state.coins == 0 and state.seeds.Tomato == 10)
end)

test("plant consumes one seed and rejects occupied, invalid and seedless plots", function()
	local state = FarmState.new(Config)
	assert(not state:plant(1, "Tomato", 0))
	state:buy("Tomato")
	assert(not state:plant(7, "Tomato", 0))
	assert(not state:plant(1, "Fake", 0))
	assert(state.seeds.Tomato == 1)
	assert(state:plant(1, "Tomato", 0))
	assert(not state:plant(1, "Tomato", 0))
	assert(state.seeds.Tomato == 0 and state.plots[2].stage == 0)
end)

test("growth advances at 5, 10, 15 seconds; mutation rolls once at maturity", function()
	local state, calls = planted(), 0
	local function roll(low, high)
		calls += 1
		assert(low == 1 and high == 10000)
		return 10000
	end
	for _, step in ipairs({ { 0, 1 }, { 4.99, 1 }, { 5, 2 }, { 9.99, 2 }, { 10, 3 }, { 14.99, 3 } }) do
		state:advance(step[1], roll)
		assert(state.plots[1].stage == step[2] and calls == 0)
	end
	assert(not state:harvest(1))
	state:advance(15, roll)
	assert(state.plots[1].stage == 4 and state.plots[1].mutation == "Cosmic" and calls == 1)
	for _ = 1, 100 do state:advance(100, roll) end
	assert(calls == 1)
end)

test("a delayed scheduler catches up without extra rolls", function()
	local state, calls = planted(), 0
	state:advance(1000, function() calls += 1; return 7001 end)
	assert(state.plots[1].stage == 4 and state.plots[1].mutation == "Golden" and calls == 1)
end)

test("every weighted roll maps to exactly its configured mutation", function()
	local observed = {}
	for roll = 1, 10000 do
		local state = planted()
		state:advance(15, function() return roll end)
		local id = state.plots[1].mutation
		assert(id ~= nil)
		observed[id] = (observed[id] or 0) + 1
	end
	for _, mutation in ipairs(Config.Mutations) do
		assert(observed[mutation.Id] == mutation.Weight, mutation.Id)
	end
end)

test("harvest is one-time, frees soil and does not award Coins until sale", function()
	local state = planted()
	state:advance(15, normal)
	assert(state:harvest(1))
	assert(not state:harvest(1))
	assert(not state:harvest(99))
	assert(state.coins == 90 and state.plots[1].stage == 0)
	local count, value = state:bagSummary()
	assert(count == 1 and value == 18)
	assert(state.bag.Tomato.Normal == 1)
end)

test("full loop yields 108 Coins, repeated sale pays nothing, next seed costs 10", function()
	local state = planted()
	state:advance(15, normal)
	state:harvest(1)
	assert(state:sell())
	assert(state.coins == 108 and state:bagSummary() == 0)
	assert(not state:sell())
	assert(state.coins == 108)
	assert(state:buy("Tomato"))
	assert(state.coins == 98 and state.seeds.Tomato == 1)
	assert(state:plant(1, "Tomato", 20))
	assert(state.plots[1].mutation == nil)
end)

test("all mutation rewards use server config, mixed basket sells once", function()
	local state = FarmState.new(Config)
	local roll, expected = 1, 100
	for index, mutation in ipairs(Config.Mutations) do
		assert(state:buy("Tomato"))
		assert(state:plant(index, "Tomato", 0))
		state:advance(15, function() return roll end)
		assert(state:harvest(index))
		expected += 18 * mutation.Multiplier - 10
		roll += mutation.Weight
	end
	assert(state:bagSummary() == 5)
	assert(state:sell())
	assert(state.coins == expected)
	assert(not state:sell())
end)

test("six simultaneous crops mature and harvest independently", function()
	local state, calls = FarmState.new(Config), 0
	for index = 1, 6 do state:buy("Tomato"); state:plant(index, "Tomato", index) end
	state:advance(16, function() calls += 1; return 1 end)
	assert(calls == 1 and state.plots[2].stage == 3)
	state:advance(21, function() calls += 1; return 1 end)
	assert(calls == 6)
	for index = 1, 6 do assert(state:harvest(index)) end
	assert(state:bagSummary() == 6)
	state:sell()
	assert(state.coins == 148)
end)

local function batch(state, cropId, now, roll)
	for index = 1, Config.PlotCount do
		assert(state:buy(cropId))
		assert(state:plant(index, cropId, now))
	end
	local finish = now + Config.Crops[cropId].GrowSeconds
	state:advance(finish, function() return roll or 1 end)
	for index = 1, Config.PlotCount do assert(state:harvest(index)) end
	assert(state:sell())
	return finish + 1
end

test("new session locks higher tiers and starts with an empty discovery book", function()
	local state = FarmState.new(Config)
	assert(state.unlocked.Tomato and not state.unlocked.Strawberry and not state.unlocked.Pumpkin)
	assert(state.earnedCoins == 0 and state.selectedCrop == "Tomato")
	for _, cropId in ipairs(Config.CropOrder) do
		assert(state.harvested[cropId] == 0 and next(state.discoveries[cropId]) == nil)
	end
	assert(not state:buy("Strawberry"))
	assert(not state:buy("Pumpkin"))
	assert(not state:select("Pumpkin"))
	assert(state.coins == 100)
end)

test("malformed crop requests cannot change economy or seed selection", function()
	local state = FarmState.new(Config)
	for _, value in ipairs({ 99, {}, false, "", "Fake", string.rep("x", 1000) }) do
		assert(not state:buy(value))
		assert(not state:select(value))
	end
	assert(not state:buy(nil) and not state:select(nil))
	assert(state.coins == 100 and state.selectedCrop == "Tomato" and state.seeds.Tomato == 0)
end)

test("unlock requires both actual harvest count and cumulative sale earnings", function()
	local state = FarmState.new(Config)
	state.coins = 100000 -- Wallet alone is not progression; test fixture only.
	assert(#state:refreshUnlocks() == 0)
	state.earnedCoins = 400
	state.harvested.Tomato = 23
	assert(#state:refreshUnlocks() == 0)
	state.harvested.Tomato = 24
	state.earnedCoins = 399
	assert(#state:refreshUnlocks() == 0)
	state.earnedCoins = 400
	local unlocked = state:refreshUnlocks()
	assert(#unlocked == 1 and unlocked[1] == "Strawberry")
	assert(state.coins == 100000 and #state:refreshUnlocks() == 0)
	assert(not state.unlocked.Pumpkin)
end)

test("all-Normal six-plot route unlocks Strawberry then Pumpkin without bankruptcy", function()
	local state, now = FarmState.new(Config), 0
	for _ = 1, 3 do now = batch(state, "Tomato", now) end
	assert(not state.unlocked.Strawberry)
	now = batch(state, "Tomato", now)
	assert(state.unlocked.Strawberry and state.harvested.Tomato == 24)
	assert(state.earnedCoins == 432 and state.coins == 292)
	for _ = 1, 3 do now = batch(state, "Strawberry", now) end
	assert(not state.unlocked.Pumpkin)
	now = batch(state, "Strawberry", now)
	assert(state.unlocked.Pumpkin and state.harvested.Strawberry == 24)
	assert(state.earnedCoins == 1512 and state.coins == 772)
	now = batch(state, "Pumpkin", now)
	assert(state.coins == 1072 and state.harvested.Pumpkin == 6)
	assert(state.discoveries.Tomato.Normal and state.discoveries.Strawberry.Normal and state.discoveries.Pumpkin.Normal)
	assert(now == 189) -- 180 seconds of growth plus nine one-second batch gaps; interactions add real time.
end)

test("discovery happens on harvest, once per crop-mutation, survives selling", function()
	local state = planted()
	state:advance(15, function() return 7001 end)
	assert(not state.discoveries.Tomato.Golden)
	local ok, _, discovery = state:harvest(1)
	assert(ok and discovery and state.discoveries.Tomato.Golden)
	state:sell()
	assert(state.discoveries.Tomato.Golden)
	state:buy("Tomato"); state:plant(1, "Tomato", 20)
	state:advance(35, function() return 7001 end)
	local again, _, repeated = state:harvest(1)
	assert(again and not repeated and state.harvested.Tomato == 2)
	assert(not state:harvest(1) and state.harvested.Tomato == 2)
	local other = FarmState.new(Config)
	assert(not other.discoveries.Tomato.Golden)
end)

test("selected crop requires owned seeds and buying selects the purchased crop", function()
	local state = FarmState.new(Config)
	state.unlocked.Strawberry = true -- Isolated selection fixture.
	assert(not state:select("Strawberry"))
	assert(state:buy("Strawberry") and state.selectedCrop == "Strawberry")
	assert(state:buy("Tomato") and state.selectedCrop == "Tomato")
	assert(state:select("Strawberry") and state.selectedCrop == "Strawberry")
	assert(state:plant(1, state.selectedCrop, 0))
	assert(state.seeds.Strawberry == 0 and state.seeds.Tomato == 1)
	assert(not state:select("Strawberry") and not state:plant(2, "Strawberry", 0))
end)

test("every crop honors configured stages and rolls exactly once at maturity", function()
	for _, cropId in ipairs(Config.CropOrder) do
		local crop = Config.Crops[cropId]
		local state, rolls = FarmState.new(Config), 0
		state.unlocked[cropId] = true
		assert(state:buy(cropId)); assert(state:plant(1, cropId, 0))
		local function roll() rolls += 1; return 10000 end
		for index = 2, #crop.GrowthStages do
			local at = crop.GrowSeconds * crop.GrowthStages[index].At
			state:advance(at - 0.001, roll)
			assert(state.plots[1].stage == index - 1 and rolls == 0)
			state:advance(at, roll)
			assert(state.plots[1].stage == index)
		end
		state:advance(1000, roll)
		assert(rolls == 1 and state.plots[1].mutation == "Cosmic")
	end
end)

test("all fifteen crop-mutation combinations yield correct mixed-basket rewards", function()
	local state, expected, now = FarmState.new(Config), 10000, 0
	state.coins = expected
	for _, cropId in ipairs(Config.CropOrder) do
		state.unlocked[cropId] = true
		local roll = 1
		for _, mutation in ipairs(Config.Mutations) do
			assert(state:buy(cropId)); assert(state:plant(1, cropId, now))
			now += Config.Crops[cropId].GrowSeconds
			state:advance(now, function() return roll end)
			assert(state.plots[1].mutation == mutation.Id)
			local ok, _, discovery = state:harvest(1)
			assert(ok and discovery and state.discoveries[cropId][mutation.Id])
			expected += Config.Crops[cropId].BaseValue * mutation.Multiplier - Config.Crops[cropId].SeedPrice
			roll += mutation.Weight
		end
	end
	assert(state:bagSummary() == 15)
	assert(state:sell() and state.coins == expected)
	assert(not state:sell() and state.coins == expected)
	local found = 0
	for _, entries in pairs(state.discoveries) do for _ in pairs(entries) do found += 1 end end
	assert(found == 15)
end)

test("crop config stays internally consistent and mutation probabilities are unchanged", function()
	local weights = { Normal = 7000, Golden = 1800, Giant = 1000, Crystal = 190, Cosmic = 10 }
	for _, mutation in ipairs(Config.Mutations) do assert(mutation.Weight == weights[mutation.Id]) end
	for _, cropId in ipairs(Config.CropOrder) do
		local crop = Config.Crops[cropId]
		assert(crop.BaseValue > crop.SeedPrice and crop.SeedPrice > 0 and crop.GrowSeconds > crop.SeedSeconds)
		assert(crop.GrowthStages[1].At == 0 and crop.GrowthStages[#crop.GrowthStages].At == 1)
		for index = 2, #crop.GrowthStages do assert(crop.GrowthStages[index].At > crop.GrowthStages[index - 1].At) end
		assert(crop.Visual and #crop.Visual.Offsets > 0 and crop.Visual.FruitStage <= #crop.GrowthStages)
	end
end)

print("All " .. passed .. " gameplay-state tests passed.")
