local Config = require("../src/shared/Config")
local State = require("../src/server/FarmState")
local Data = require("../src/server/PlayerData")
local Objectives = require("../src/server/Objectives")
local state = State.new(Config)
assert(#Objectives.advance(state,"Researcher") == 0 and state.coins == 100)
assert(state:buy("Tomato"))
assert(#Objectives.advance(state,"BuyTomato") == 1 and state.coins == 95)
assert(#Objectives.advance(state,"BuyTomato") == 0 and state.coins == 95)
assert(state:plant(1,"Tomato",0))
assert(#Objectives.advance(state,"Plant") == 1)
assert(not state:harvest(1)) -- Failed operations must not dispatch objective events.
state:advance(20,function() return 1 end)
assert(state:harvest(1))
assert(#Objectives.advance(state,"Harvest") == 1 and state.objectiveStep == 3)
assert(state:sell())
assert(#Objectives.advance(state,"Sell") == 2 and state.objectiveStep == 5)
assert(state.earnedCoins == 18) -- Tutorial Coins never inflate crop unlock earnings.
local snapshot = Data.capture(state,Config)
state = State.fromData(Config,assert(Data.decode(snapshot,Config)))
assert(state.objectiveStep == 5)
assert(#Objectives.advance(state,"Researcher") == 1 and state.coins == 138)
local restored = State.fromData(Config,assert(Data.decode(Data.capture(state,Config),Config)))
for _=1,20 do
	for _, event in ipairs({"BuyTomato","Plant","Harvest","Sell","Discover","Researcher"}) do
		assert(#Objectives.advance(restored,event) == 0)
	end
end
assert(restored.coins == 138 and restored.objectiveStep == 6)
local old = Data.capture(state,Config)
old.version, old.objectiveStep = 1,nil
local migrated = assert(Data.decode(old,Config))
assert(migrated.objectiveStep == 0 and migrated.coins == old.coins and migrated.discoveries.Tomato.Normal)
for _, bad in ipairs({-1,0.5,7,math.huge,"6",false}) do
	old.objectiveStep = bad
	assert(Data.decode(old,Config) == nil)
end
print("PASS objective order, rewards, discovery credit, migration and reload replay protection")
