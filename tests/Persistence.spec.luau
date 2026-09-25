local Config = require("../src/shared/Config")
local FarmState = require("../src/server/FarmState")
local Data = require("../src/server/PlayerData")
local Store = require("../src/server/ProfileStore")
local passed = 0
local function test(name, run)
	run()
	passed += 1
	print("PASS " .. name)
end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end
local function equal(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then return a == b end
	for key, value in pairs(a) do if not equal(value, b[key]) then return false end end
	for key in pairs(b) do if a[key] == nil then return false end end
	return true
end
local function fixture(initial)
	local env = { records = initial or {}, time = 1000, failures = 0, ambiguous = 0, calls = 0, writes = 0, tokens = 0 }
	local backend = {}
	function backend:UpdateAsync(key, transform)
		env.calls += 1
		if env.failures > 0 then env.failures -= 1; error("simulated offline") end
		local updated = transform(copy(env.records[key]))
		if updated == nil then return nil end
		env.records[key] = copy(updated)
		env.writes += 1
		if env.ambiguous > 0 then env.ambiguous -= 1; error("response lost after commit") end
		return copy(updated)
	end
	env.store = Store.new(backend, Data, Config, {
		now = function() return env.time end,
		wait = function(seconds) env.time += seconds end,
		token = function() env.tokens += 1; return "session-" .. env.tokens end,
	})
	return env
end

test("fresh profiles have clean defaults and independent maps", function()
	local a, b = Data.decode(nil, Config), Data.decode(nil, Config)
	assert(a.coins == 100 and a.expansionTier == 1 and a.unlocked.Tomato)
	assert(a.unlocked.Strawberry == false and a.discoveries.Tomato.Cosmic == false)
	a.seeds.Tomato = 4
	assert(b.seeds.Tomato == 0 and b.bag.Pumpkin.Cosmic == 0)
end)

test("legacy fields migrate; malformed and future data fail closed", function()
	local migrated = Data.decode({ coins = 345, seeds = { Tomato = 2 } }, Config)
	assert(migrated.version == 3 and migrated.coins == 345 and migrated.expansionTier == 1 and migrated.objectiveStep == 0)
	for _, bad in ipairs({ {}, false, "bad", { coins = -1 }, { coins = 1.5 }, { coins = math.huge },
		{ coins = 0 / 0 }, { coins = 100, version = 99 }, { coins = 100, bag = false },
		{ coins = 100, seeds = { Unknown = 1 } }, { coins = 100, unlocked = { Tomato = 1 } },
		{ coins = 100, discoveries = { Tomato = { Cosmic = 1 } } }, { coins = 100, expansionTier = 4 } }) do
		assert(Data.decode(bad, Config) == nil)
	end
end)

test("expansion is priced, sequential, bounded and preserves planted crops", function()
	local state = FarmState.new(Config)
	assert(not state:expand() and state.coins == 100 and #state.plots == 6)
	state.coins = 2010
	assert(state:buy("Tomato") and state:plant(1, "Tomato", 0))
	assert(state:expand() and state.coins == 1500 and #state.plots == 9)
	assert(state.plots[1].cropId == "Tomato" and state.plots[9].stage == 0)
	assert(state:expand() and state.coins == 0 and #state.plots == 12)
	assert(not state:expand() and state.coins == 0 and state.expansionTier == 3)
end)

test("durable state round trips; growing crops reset without seed refunds", function()
	local state = FarmState.new(Config)
	state.coins, state.earnedCoins = 2500, 1700
	state.harvested.Tomato, state.harvested.Strawberry = 24, 24
	state:refreshUnlocks()
	assert(state:expand() and state:expand())
	assert(state:buy("Pumpkin") and state:buy("Strawberry") and state:buy("Tomato"))
	assert(state:plant(1, "Tomato", 0))
	state.bag.Pumpkin.Cosmic = 2
	state.discoveries.Pumpkin.Cosmic = true
	local snapshot = Data.capture(state, Config)
	assert(snapshot.plots == nil and snapshot.config == nil)
	local restored = FarmState.fromData(Config, assert(Data.decode(snapshot, Config)))
	assert(equal(snapshot, Data.capture(restored, Config)))
	assert(#restored.plots == 12 and restored.plots[1].stage == 0 and restored.seeds.Tomato == 0)
	state.seeds.Pumpkin = 99
	state.discoveries.Pumpkin.Cosmic = false
	assert(snapshot.seeds.Pumpkin == 1 and snapshot.discoveries.Pumpkin.Cosmic)
end)

test("save, release and rejoin retain data; another key is clean", function()
	local env = fixture()
	local profile = assert(env.store:load("one"))
	local state = FarmState.fromData(Config, profile.data)
	state.coins = 2000
	assert(state:expand())
	assert(state:buy("Tomato"))
	assert(env.store:save(profile, Data.capture(state, Config), true))
	assert(profile.closed and env.records.one.lock == nil)
	local rejoin = assert(env.store:load("one"))
	assert(rejoin.data.coins == 1490 and rejoin.data.seeds.Tomato == 1 and rejoin.data.expansionTier == 2)
	assert(env.store:load("two").data.coins == 100)
end)

test("load failure produces no profile and never writes defaults", function()
	local env = fixture({ one = { coins = 875 } })
	env.failures = 3
	assert(env.store:load("one") == nil)
	assert(env.calls == 3 and env.writes == 0 and env.records.one.coins == 875)
end)

test("malformed saved records remain untouched", function()
	for _, record in ipairs({ { coins = 900, version = 99 }, { recordVersion = 1 },
		{ recordVersion = 1, data = { coins = 900 }, lock = { token = "x", expires = math.huge } },
		{ recordVersion = 8, data = { coins = 900 } } }) do
		local env = fixture({ one = copy(record) })
		assert(env.store:load("one") == nil)
		assert(env.writes == 0 and equal(env.records.one, record))
	end
end)

test("active lock blocks a second server; expired owner cannot overwrite", function()
	local env = fixture()
	local first = assert(env.store:load("one"))
	assert(env.store:load("one") == nil)
	env.time += 181
	local second = assert(env.store:load("one"))
	second.data.coins = 432
	assert(env.store:save(second, second.data, false))
	first.data.coins = 999
	assert(not env.store:save(first, first.data, false) and first.lost)
	assert(env.records.one.data.coins == 432 and env.records.one.lock.token == second.token)
end)

test("failed saves preserve stored data and can retry", function()
	local env = fixture()
	local profile = assert(env.store:load("one"))
	profile.data.coins = 321
	env.failures = 3
	assert(not env.store:save(profile, profile.data, false))
	assert(env.records.one.data.coins == 100 and not profile.saving)
	assert(env.store:save(profile, profile.data, false))
	assert(env.records.one.data.coins == 321 and profile.expires == env.time + 180)
end)

test("expired lease cannot save even if no new server claimed it", function()
	local env = fixture()
	local profile = assert(env.store:load("one"))
	env.time += 180
	assert(not env.store:save(profile, profile.data, false) and profile.lost)
end)

test("ambiguous load, save and final release retry idempotently", function()
	local env = fixture()
	env.ambiguous = 1
	local profile = assert(env.store:load("one"))
	profile.data.coins = 567
	env.ambiguous = 1
	assert(env.store:save(profile, profile.data, false))
	assert(env.records.one.data.coins == 567)
	env.ambiguous = 1
	assert(env.store:save(profile, profile.data, true))
	assert(profile.closed and env.records.one.lock == nil)
	assert(env.store:load("one").data.coins == 567)
end)

test("invalid snapshots and concurrent saves cannot overwrite valid data", function()
	local env = fixture()
	local profile = assert(env.store:load("one"))
	local calls = env.calls
	assert(not env.store:save(profile, nil, false))
	assert(not env.store:save(profile, { coins = -1 }, false))
	profile.saving = true
	assert(not env.store:save(profile, profile.data, false))
	assert(env.calls == calls and env.records.one.data.coins == 100)
end)

print(passed .. " persistence/expansion tests passed")
