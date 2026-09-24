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

print("All " .. passed .. " gameplay-state tests passed.")
