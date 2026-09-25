local Config = require("../src/shared/Config")
local State = require("../src/server/FarmState")
local Data = require("../src/server/PlayerData")
local Environment = require("../src/server/EnvironmentState")
local function low(a) return a end
local function fresh()
	local s=State.new(Config)
	s.coins=100
	s.bag.Tomato.Normal=2
	return s
end
local s=fresh()
local ok,_,id,first=s:research("Tomato_Normal","Tomato_Normal",low)
assert(ok and first and id=="Tomato_Growth")
assert(s.coins==80 and s.bag.Tomato.Normal==0 and s.experimentalSeeds[id]==1 and s.researchCount==1)
assert(not s:research("Tomato_Normal","Tomato_Normal",low) and s.coins==80)
assert(s:selectExperiment(id) and s:plant(1,"Tomato",0))
assert(s.experimentalSeeds[id]==0 and s.plots[1].experiment==id)
assert(not s:plant(2,"Tomato",0))
s:advance(11,low); assert(s.plots[1].mutation==nil)
s:advance(12,low); assert(s.plots[1].mutation=="Normal")
assert(s:harvest(1)); assert(not s:harvest(1))
assert(s.experimentalBag[id].Normal==1 and s.bag.Tomato.Normal==0 and s.researchFound.Grown_Growth)
local count,value=s:bagSummary(); assert(count==1 and value==19)
local saved=Data.capture(s,Config)
local restored=State.fromData(Config,assert(Data.decode(saved,Config)))
assert(restored.experimentalBag[id].Normal==1 and restored.researchCount==1 and restored.researchFound.Tomato_Tomato)
assert(restored:sell() and restored.coins==99 and not restored:sell())
-- Reject bad requests without invoking RNG or mutating either inventory.
for _,spec in ipairs({{"fake","Tomato_Normal"},{false,"Tomato_Normal"},{"Tomato_Normal",{}},{"Tomato_Normal","Pumpkin_Normal"}}) do
	local state=fresh(); state.bag.Pumpkin.Normal=1
	assert(not state:research(spec[1],spec[2],function() error("invalid request reached RNG") end))
	assert(state.coins==100 and state.bag.Tomato.Normal==2 and state.bag.Pumpkin.Normal==1 and state.researchCount==0)
end
for _,case in ipairs({"one","poor","full"}) do
	local state=fresh()
	if case=="one" then state.bag.Tomato.Normal=1 elseif case=="poor" then state.coins=19 else state.experimentalSeeds.Tomato_Value=999 end
	local coins,parents=state.coins,state.bag.Tomato.Normal
	assert(not state:research("Tomato_Normal","Tomato_Normal",low))
	assert(state.coins==coins and state.bag.Tomato.Normal==parents and state.researchCount==0)
end
-- Every mutation pair can cross; both endpoint RNG choices always produce a finite catalog ID.
for _,a in ipairs(Config.Mutations) do
	for _,b in ipairs(Config.Mutations) do
		for _,upper in ipairs({false,true}) do
			local state=fresh(); state.bag.Tomato[a.Id]=2; state.bag.Strawberry[b.Id]=2
			local success,_,result=state:research("Tomato_"..a.Id,"Strawberry_"..b.Id,function(lo,hi) return upper and hi or lo end)
			assert(success and Config.Research.Catalog[result] and state.experimentalSeeds[result]==1)
		end
	end
end
-- Affinity stacks on environmental weights; Normal and Cosmic both remain possible.
local state=fresh(); state.experimentalSeeds.Tomato_Affinity=2
assert(state:selectExperiment("Tomato_Affinity")); assert(state:plant(1,"Tomato",0)); assert(state:plant(2,"Tomato",0))
local env=Environment.new(Config,0); env.weather="Thunderstorm"; env.phase=3; env:startMeteor(0)
local weights=env:weights()
local calls=0
state:advance(20,function(lo,hi) calls+=1; return calls==1 and lo or hi end,weights)
assert(state.plots[1].mutation=="Normal" and state.plots[2].mutation=="Cosmic")
-- Old records acquire research defaults without erasing M7 progress/items.
local old=Data.capture(s,Config)
old.version=2; old.experimentalSeeds=nil; old.experimentalBag=nil; old.researchFound=nil; old.researchCount=nil; old.selectedExperiment=nil
old.objectiveStep=6; old.coins=1234
local migrated=assert(Data.decode(old,Config))
assert(migrated.version==3 and migrated.coins==1234 and migrated.objectiveStep==6 and migrated.researchCount==0 and migrated.experimentalSeeds.Tomato_Growth==0)
for _,bad in ipairs({-1,1.5,1000,math.huge,0/0,"1"}) do
	local raw=Data.capture(s,Config); raw.experimentalSeeds.Tomato_Growth=bad
	assert(Data.decode(raw,Config)==nil)
end
local invalid=Data.capture(s,Config); invalid.experimentalSeeds.Fake=1; assert(Data.decode(invalid,Config)==nil)
invalid=Data.capture(s,Config); invalid.experimentalBag.Tomato_Growth.Fake=1; assert(Data.decode(invalid,Config)==nil)
invalid=Data.capture(s,Config); invalid.researchFound.Fake=true; assert(Data.decode(invalid,Config)==nil)
print("PASS research atomicity, inheritance bounds, farming/sale integration, environmental rarity and save migration")
