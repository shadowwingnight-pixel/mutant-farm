local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local FarmState = require(script.Parent.FarmState)
local Objectives = require(script.Parent.Objectives)
local TownNPCs = require(script.Parent.TownNPCs)
local World = require(script.Parent.FarmWorld)
local Persistence = require(script.Parent.Persistence)
local persistence = Persistence.new(Config)
local environment = require(script.Parent.EnvironmentService).new(Config)
local town = require(script.Parent.TownWorld).new(World)

local farms = Instance.new("Folder")
farms.Name, farms.Parent = "MutantFarms", workspace
local sessions, slots = {}, {}
local pendingLoads = {}
local closingCount, shuttingDown = 0, false
local random = Random.new()
-- Outbound cosmetic events only. No OnServerEvent listener or economic input.
local feedback = Instance.new("RemoteEvent")
feedback.Name, feedback.Parent = "FarmFeedback", ReplicatedStorage
local actionRequest = Instance.new("RemoteEvent")
actionRequest.Name, actionRequest.Parent = "FarmAction", ReplicatedStorage

local function publish(player, session, message, effect)
	local count, value = session.state:bagSummary()
	player:SetAttribute("Coins", session.state.coins)
	player:SetAttribute("ObjectiveStep", session.state.objectiveStep)
	player:SetAttribute("PlotCount", #session.state.plots)
	player:SetAttribute("ExpansionTier", session.state.expansionTier)
	player:SetAttribute("HarvestCount", count)
	player:SetAttribute("EarnedCoins", session.state.earnedCoins)
	player:SetAttribute("SelectedCrop", session.state.selectedCrop)
	player:SetAttribute("SelectedExperiment", session.state.selectedExperiment)
	player:SetAttribute("ResearchCount", session.state.researchCount)
	local experimentalCount = 0
	for _, id in ipairs(Config.Research.Order) do
		local amount = session.state.experimentalSeeds[id]
		experimentalCount += amount
		player:SetAttribute("ExpSeed_" .. id, amount)
		for _, mutation in ipairs(Config.Mutations) do player:SetAttribute("ExpBag_" .. id .. "_" .. mutation.Id,session.state.experimentalBag[id][mutation.Id] or 0) end
	end
	for key in pairs(Config.Research.Discoveries) do player:SetAttribute("Research_" .. key,session.state.researchFound[key] == true) end
	player:SetAttribute("ExperimentalSeedCount",experimentalCount)
	player:SetAttribute("HarvestValue", value)
	local growing, ready = 0, 0
	for _, plot in ipairs(session.state.plots) do
		local crop = Config.Crops[plot.cropId]
		if crop and plot.stage > 0 and plot.stage < #crop.GrowthStages then growing += 1 end
		if crop and plot.stage == #crop.GrowthStages then ready += 1 end
	end
	player:SetAttribute("Growing", growing)
	player:SetAttribute("Ready", ready)
	local seeds, discoveries = 0, 0
	for _, cropId in ipairs(Config.CropOrder) do
		seeds += session.state.seeds[cropId]
		player:SetAttribute("Seeds_" .. cropId, session.state.seeds[cropId])
		player:SetAttribute("Unlocked_" .. cropId, session.state.unlocked[cropId] == true)
		player:SetAttribute("Harvested_" .. cropId, session.state.harvested[cropId])
		for _, mutation in ipairs(Config.Mutations) do
			local discovered = session.state.discoveries[cropId][mutation.Id] == true
			if discovered then discoveries += 1 end
			player:SetAttribute("Found_" .. cropId .. "_" .. mutation.Id, discovered)
			player:SetAttribute("Bag_" .. cropId .. "_" .. mutation.Id, session.state.bag[cropId][mutation.Id] or 0)
		end
	end
	player:SetAttribute("SeedCount", seeds + experimentalCount)
	player:SetAttribute("DiscoveryCount", discoveries)
	if message then
		player:SetAttribute("FarmMessage", message)
		player:SetAttribute("FarmMessageId", (player:GetAttribute("FarmMessageId") or 0) + 1)
		local payload = effect or { kind = "Notice" }
		payload.text = message
		feedback:FireClient(player, payload)
	end
end

-- Native interaction events still need ownership, distance, alive and rate checks.
local function allowed(player, owner, target, distance)
	local session = sessions[player]
	if player ~= owner or not session or session.closing or shuttingDown or not persistence:canPlay(session.profile) then return false end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return false end
	-- The positive comparison also rejects non-finite/NaN positions.
	if not ((root.Position - target.Position).Magnitude <= distance) then return false end
	local now = os.clock()
	if now - session.lastAction < Config.ActionCooldown then return false end
	session.lastAction = now
	return true
end

local bindPlots
local function objectiveEvent(player, session, event)
	local completed = Objectives.advance(session.state, event)
	if #completed > 0 then
		session.nextSave = math.min(session.nextSave, os.clock() + 3)
		for _, text in ipairs(completed) do feedback:FireClient(player, { kind = "Objective", text = text }) end
	end
end
TownNPCs.build(town, function(player, definition, target)
	if not allowed(player, player, target, 11) then return end
	local session = sessions[player]
	if session.lastTalk and os.clock() - session.lastTalk < 1 then return end
	session.lastTalk = os.clock()
	if definition.Id == "Researcher" then objectiveEvent(player, session, "Researcher") end
	publish(player, session)
	feedback:FireClient(player, TownNPCs.dialogue(definition, session.state, environment.state:snapshot()))
end)
require(script.Parent.ResearchService).install(Config,World,town,sessions,allowed,publish,feedback)
-- Only identifiers are accepted. Prices, selected seed, unlocks and rewards stay server-owned.
actionRequest.OnServerEvent:Connect(function(player, action, cropId)
	if action == "Expand" then
		local session = sessions[player]
		if not session or not allowed(player, player, session.world.upgrade, Config.ShopDistance) then return end
		local ok, message = session.state:expand()
		if ok then
			World.expand(session.world, #session.state.plots, player.UserId)
			bindPlots(player, session)
			session.nextSave = math.min(session.nextSave, os.clock() + 3)
		end
		publish(player, session, message, ok and { kind = "Expand", position = session.world.upgrade.Position } or nil)
		return
	end
	if type(action) ~= "string" or (action ~= "Buy" and action ~= "Select") then return end
	if type(cropId) ~= "string" or not Config.Crops[cropId] then return end
	local session = sessions[player]
	if not session then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local target = action == "Buy" and session.world.shop or root
	if action == "Buy" and (root.Position - town.shop.Position).Magnitude < (root.Position - target.Position).Magnitude then target = town.shop end
	if not allowed(player, player, target, Config.ShopDistance) then return end
	local ok, message
	if action == "Buy" then ok, message = session.state:buy(cropId) else ok, message = session.state:select(cropId) end
	if ok and action == "Buy" then message = "+1 " .. cropId .. " Seed • Selected for planting" end
	if ok and action == "Buy" and cropId == "Tomato" then objectiveEvent(player, session, "BuyTomato") end
	publish(player, session, message, ok and { kind = action, position = target.Position, cropId = cropId } or nil)
end)

local function prompt(part, action, callback)
	local interaction = Instance.new("ProximityPrompt")
	interaction.ActionText, interaction.ObjectText = action, part.Name == "SeedShop" and "Seed Shop" or "Harvest Basket"
	if part.Name == "FarmUpgrade" then interaction.ObjectText = "Farm Expansion" end
	interaction.MaxActivationDistance = 12
	interaction.RequiresLineOfSight = false
	interaction.HoldDuration = 0
	interaction.Parent = part
	interaction.Triggered:Connect(callback)
end

local function sellHarvest(player, session, stand)
	local state = session.state
	local before = state.coins
	local ok, message, unlocks = state:sell()
	local earned = state.coins - before
	if ok then
		message = "+" .. earned .. " Coins • Harvest sold!"
		objectiveEvent(player, session, "Sell")
		if #unlocks > 0 then message ..= "\nUNLOCKED: " .. table.concat(unlocks, ", ") .. "!" end
	end
	publish(player, session, message, ok and { kind = "Sell", position = stand.Position, amount = earned, unlocks = unlocks } or nil)
end

prompt(town.shop, "Browse seeds", function(player)
	if not allowed(player, player, town.shop, Config.ShopDistance) then return end
	feedback:FireClient(player, { kind = "Shop" })
end)
prompt(town.sell, "Sell all crops", function(player)
	if not allowed(player, player, town.sell, Config.ShopDistance) then return end
	sellHarvest(player, sessions[player], town.sell)
end)

local function join(player)
	if sessions[player] or pendingLoads[player] or shuttingDown then return end
	pendingLoads[player] = true
	local profile, problem = persistence:load(player)
	if not profile then
		pendingLoads[player] = nil
		warn("Mutant Farm load refused for " .. player.UserId .. ": " .. tostring(problem))
		player:Kick("Your save could not be safely loaded. No existing data was replaced. Please rejoin later. " .. tostring(problem))
		return
	end
	local state = FarmState.fromData(Config, profile.data)
	if shuttingDown or player.Parent ~= Players then
		persistence:save(player, { profile = profile, state = state }, true)
		pendingLoads[player] = nil
		return
	end
	local slot = 1
	while slots[slot] do slot += 1 end
	slots[slot] = true
	local world = World.create(farms, player, slot, Config, #state.plots)
	town:connectFarm(world, player, slot)
	local session = { state = state, world = world, slot = slot, lastAction = -math.huge,
		profile = profile, nextSave = os.clock() + persistence.autosaveSeconds + slot % 7 }
	sessions[player] = session
	pendingLoads[player] = nil
	publish(player, session, "Welcome to Mutant Farm Town! Your farm is here • Follow the road left to Seed Square.")
	prompt(world.shop, "Browse seeds", function(visitor)
		if not allowed(visitor, player, world.shop, Config.ShopDistance) then return end
		feedback:FireClient(player, { kind = "Shop" })
	end)
	prompt(world.sell, "Sell all crops", function(visitor)
		if not allowed(visitor, player, world.sell, Config.ShopDistance) then return end
		sellHarvest(player, session, world.sell)
	end)
	prompt(world.upgrade, "View farm upgrades", function(visitor)
		if not allowed(visitor, player, world.upgrade, Config.ShopDistance) then return end
		feedback:FireClient(player, { kind = "Upgrades" })
	end)
	bindPlots(player, session)
	local function spawn(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root and sessions[player] == session and player.Character == character then character:PivotTo(world.spawn) end
	end
	session.connection = player.CharacterAdded:Connect(spawn)
	if player.Character then task.spawn(spawn, player.Character) end
end

bindPlots = function(player, session)
	local state, world = session.state, session.world
	for index, view in ipairs(world.plots) do
		if view.bound then continue end
		view.bound = true
		local click = Instance.new("ClickDetector")
		click.MaxActivationDistance = Config.InteractionDistance
		click.Parent = view.soil
		click.MouseClick:Connect(function(visitor)
			if not allowed(visitor, player, view.soil, Config.InteractionDistance) then return end
			local ok, message, newDiscovery
			local action = state.plots[index].stage == 0 and "Plant" or "Harvest"
			local mutation = state.plots[index].mutation
			local cropId = state.plots[index].cropId or state.selectedCrop
			local experimentId = action == "Plant" and state.selectedExperiment or state.plots[index].experiment
			if state.plots[index].stage == 0 then
				ok, message = state:plant(index, state.selectedCrop, os.clock())
			else
				ok, message, newDiscovery = state:harvest(index)
			end
			if ok then
				World.render(view, state.plots[index], Config)
				objectiveEvent(player, session, action)
			end
			if ok then
				local experiment = Config.Research.Catalog[experimentId]
				local name = experiment and (experiment.Name .. " • " .. experiment.Trait) or cropId
				message = action == "Plant" and (name .. " planted • Watch it grow!") or ("+1 " .. mutation .. " " .. name)
				if newDiscovery then message = "NEW DISCOVERY!\n+1 " .. mutation .. " " .. name end
			end
			publish(player, session, message, ok and { kind = action, position = view.soil.Position, mutation = mutation, cropId = cropId, discovery = newDiscovery } or nil)
		end)
	end
end

local function leave(player)
	local session = sessions[player]
	if not session or session.closing then return end
	session.closing = true
	closingCount += 1
	sessions[player] = nil
	local ok, saved, problem = pcall(function() return persistence:save(player, session, true) end)
	if not ok or not saved then warn("Mutant Farm final save incomplete: " .. tostring(problem or saved)) end
	slots[session.slot] = nil
	session.connection:Disconnect()
	session.world.model:Destroy()
	closingCount -= 1
end
Players.PlayerRemoving:Connect(leave)
Players.PlayerAdded:Connect(join)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(join, player) end

game:BindToClose(function()
	shuttingDown = true
	local remaining = {}
	for player in pairs(sessions) do table.insert(remaining, player) end
	for _, player in ipairs(remaining) do task.spawn(leave, player) end
	local deadline = os.clock() + 25
	while (closingCount > 0 or next(pendingLoads) ~= nil) and os.clock() < deadline do task.wait(0.1) end
end)

local RunService = game:GetService("RunService")
if RunService:IsStudio() and RunService:IsServer() then
	local command = Instance.new("BindableFunction")
	command.Name = "MutantFarmSave"
	command.OnInvoke = function(userId)
		if not RunService:IsStudio() or not RunService:IsServer() then return "Studio server only." end
		if userId ~= nil and (type(userId) ~= "number" or userId % 1 ~= 0) then return "Invalid UserId." end
		local player = Players:GetPlayers()[1]
		if userId ~= nil then player = Players:GetPlayerByUserId(userId) end
		local session = player and sessions[player]
		if not session or session.closing then return "No loaded session." end
		if session.lastManualSave and os.clock() - session.lastManualSave < 10 then return "Wait 10 seconds between manual saves." end
		session.lastManualSave = os.clock()
		local saved, problem = persistence:save(player, session, false)
		return saved and (persistence.cloud and "Saved" or "Session only; enable Studio test persistence before Play for rejoin tests") or problem
	end
	command.Parent = game:GetService("ServerStorage")
end

require(script.Parent.StudioPreview).install(Config, World, feedback, sessions)

while true do
	task.wait(0.25)
	environment:step()
	town:updateLighting(environment.state:snapshot().phase)
	local now = os.clock()
	for player, session in pairs(sessions) do
		if not persistence:canPlay(session.profile) then
			player:Kick("Saving is unavailable or this profile moved to another server. Please rejoin; your last successful save is protected.")
			continue
		end
		if not shuttingDown and now >= session.nextSave and not session.profile.saving then
			session.nextSave = now + persistence.autosaveSeconds
			task.spawn(function()
				local saved = persistence:save(player, session, false)
				if not saved and sessions[player] == session then session.nextSave = os.clock() + 15 end
			end)
		end
		for _, index in ipairs(session.state:advance(now, function(low, high) return random:NextInteger(low, high) end, environment.currentWeights)) do
			local plot = session.state.plots[index]
			World.render(session.world.plots[index], plot, Config)
			if plot.stage == #Config.Crops[plot.cropId].GrowthStages then
				local message = plot.mutation == "Normal" and (string.upper(plot.cropId) .. " READY!") or (string.upper(plot.mutation) .. " " .. string.upper(plot.cropId) .. "!")
				publish(player, session, message, { kind = "Ready", mutation = plot.mutation, cropId = plot.cropId, position = session.world.plots[index].soil.Position })
			end
		end
		for index, plot in ipairs(session.state.plots) do
			World.countdown(session.world.plots[index], plot, Config, now)
		end
	end
end
