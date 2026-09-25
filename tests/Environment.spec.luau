local Config = require("../src/shared/Config")
local Environment = require("../src/server/EnvironmentState")
local FarmState = require("../src/server/FarmState")
local passed = 0
local function test(name, callback)
	callback(); passed += 1; print("PASS " .. name)
end
local function lookup(weights, id)
	for _, entry in ipairs(weights) do if entry.Id == id then return entry end end
	error("Missing mutation " .. id)
end
local function noEvent() return 0.99 end

test("Clear Day weights are exactly the unchanged baseline", function()
	local env = Environment.new(Config, 0)
	local weights, total = env:weights()
	assert(total == 10000)
	for index, base in ipairs(Config.Mutations) do
		assert(weights[index].Id == base.Id and weights[index].Weight == base.Weight and weights[index].Factor == 1)
	end
end)

test("phase boundaries and wraparound follow the server schedule", function()
	local env = Environment.new(Config, 0)
	env:advance(119.99, noEvent); assert(env:snapshot().phase == "Day")
	env:advance(120, noEvent); assert(env:snapshot().phase == "Evening")
	env:advance(160, noEvent); assert(env:snapshot().phase == "Night")
	env:advance(240, noEvent); assert(env:snapshot().phase == "Day")
	assert(env.nextPhase == 360)
end)

test("weather selection uses centralized weights and changes only on schedule", function()
	for _, pair in ipairs({ { 0, "Clear" }, { 0.59, "Clear" }, { 0.6, "Rain" }, { 0.899, "Rain" }, { 0.9, "Thunderstorm" }, { 0.999, "Thunderstorm" } }) do
		local env = Environment.new(Config, 0)
		env:advance(89, function() error("Should not roll yet") end)
		assert(env.weather == "Clear")
		env:advance(90, function() return pair[1] end)
		assert(env.weather == pair[2] and env.nextWeather == 180)
	end
end)

test("rain, storm, night and meteor boost opportunities without guaranteeing Cosmic", function()
	local env = Environment.new(Config, 0)
	local previous = lookup(env:weights(), "Cosmic").Percent
	for _, command in ipairs({ "Rain", "Thunderstorm", "Night", "Meteor" }) do
		assert(env:preview(command, 0))
		local weights = env:weights()
		local cosmic = lookup(weights, "Cosmic")
		assert(cosmic.Percent > previous and cosmic.Percent < 1)
		assert(lookup(weights, "Normal").Weight == 7000)
		previous = cosmic.Percent
	end
	assert(lookup(env:weights(), "Cosmic").Weight == 72)
	for index, expected in ipairs({ 7000, 1800, 1000, 190, 10 }) do assert(Config.Mutations[index].Weight == expected) end
end)

test("every condition combination has valid normalized chances and preserves all outcomes", function()
	for _, phase in ipairs(Config.Environment.Phases) do
		for _, weather in ipairs(Config.Environment.Weather) do
			for _, event in ipairs({ "EndMeteor", "Meteor" }) do
				local env = Environment.new(Config, 0)
				env:preview(phase.Id, 0); env:preview(weather.Id, 0); env:preview(event, 0)
				local weights, total = env:weights()
				local percent, weight = 0, 0
				for _, entry in ipairs(weights) do
					assert(entry.Weight > 0 and entry.Weight % 1 == 0)
					percent += entry.Percent; weight += entry.Weight
				end
				assert(weight == total and math.abs(percent - 100) < 0.00001)
				assert(lookup(weights, "Cosmic").Percent < 1)
			end
		end
	end
end)

test("meteor auto ends without changing underlying weather/time or extending on repeated preview", function()
	local env = Environment.new(Config, 0)
	env:preview("Rain", 0); env:preview("Night", 0)
	local before = env:weights()
	env:preview("Meteor", 10)
	assert(env.meteorEndsAt == 55)
	env:preview("Meteor", 40); assert(env.meteorEndsAt == 55)
	env:advance(54.99, noEvent); assert(env.meteorEndsAt == 55)
	env:advance(55, noEvent); assert(env.meteorEndsAt == 0 and env.nextMeteor == 295)
	assert(env.weather == "Rain" and env:snapshot().phase == "Night")
	for index, weight in ipairs(env:weights()) do assert(weight.Weight == before[index].Weight) end
end)

test("natural meteor check obeys rarity, duration and cooldown", function()
	local env = Environment.new(Config, 0)
	env:preview("Clear", 0); env:preview("Day", 0)
	env:advance(120, function() return Config.Environment.Meteor.Chance end)
	assert(env.meteorEndsAt == 0)
	env:advance(240, function() return 0 end)
	assert(env.meteorEndsAt == 285)
	env:advance(285, noEvent); assert(env.nextMeteor == 525)
	env:advance(524, function() error("Cooldown must not roll") end)
end)

test("QA holds only requested dimensions; Resume resumes and invalid requests do nothing", function()
	local env = Environment.new(Config, 0)
	assert(not env:preview("Cosmic", 0) and not env:preview({}, 0))
	env:preview("Night", 0); env:preview("Clear", 0)
	env:advance(200, noEvent)
	assert(env:snapshot().phase == "Night" and env.weather == "Clear")
	env:preview("Resume", 200)
	assert(not env.holdTime and not env.holdWeather)
	env:advance(280, noEvent); assert(env:snapshot().phase == "Day")
	env:preview("Meteor", 280); env:preview("EndMeteor", 281)
	assert(env.meteorEndsAt == 0 and env.nextMeteor == 521)
end)

test("each crop rolls once with weights at maturity, with no reward/progression changes", function()
	local env = Environment.new(Config, 0)
	for _, cropId in ipairs(Config.CropOrder) do
		local state = FarmState.new(Config)
		state.unlocked[cropId], state.coins = true, 1000
		assert(state:buy(cropId) and state:plant(1, cropId, 0))
		local rolls = 0
		local function last(low, high)
			rolls += 1
			local _, total = env:weights()
			assert(low == 1 and high == total)
			return high
		end
		state:advance(Config.Crops[cropId].GrowSeconds - 0.01, last, env:weights())
		assert(rolls == 0)
		env:preview("Thunderstorm", 0); env:preview("Night", 0); env:preview("Meteor", 0)
		state:advance(Config.Crops[cropId].GrowSeconds, last, env:weights())
		assert(rolls == 1 and state.plots[1].mutation == "Cosmic")
		env:preview("Clear", 0); env:preview("Day", 0); env:preview("EndMeteor", 0)
		state:advance(1000, last, env:weights())
		assert(rolls == 1 and state.plots[1].mutation == "Cosmic")
		assert(state:harvest(1) and state.discoveries[cropId].Cosmic)
		local coins = state.coins
		assert(state:sell() and state.coins == coins + Config.Crops[cropId].BaseValue * 20)
	end
end)

print(passed .. " environment tests passed")
