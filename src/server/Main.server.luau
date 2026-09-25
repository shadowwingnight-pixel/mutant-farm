local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local FarmState = require(script.Parent.FarmState)
local World = require(script.Parent.FarmWorld)

local farms = Instance.new("Folder")
farms.Name, farms.Parent = "MutantFarms", workspace
local sessions, slots = {}, {}
local random = Random.new()
-- Outbound cosmetic events only. No OnServerEvent listener or economic input.
local feedback = Instance.new("RemoteEvent")
feedback.Name, feedback.Parent = "FarmFeedback", ReplicatedStorage
local actionRequest = Instance.new("RemoteEvent")
actionRequest.Name, actionRequest.Parent = "FarmAction", ReplicatedStorage

local function publish(player, session, message, effect)
	local count, value = session.state:bagSummary()
	player:SetAttribute("Coins", session.state.coins)
	player:SetAttribute("HarvestCount", count)
	player:SetAttribute("EarnedCoins", session.state.earnedCoins)
	player:SetAttribute("SelectedCrop", session.state.selectedCrop)
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
	player:SetAttribute("SeedCount", seeds)
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
	if player ~= owner or not session then return false end
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

-- Only identifiers are accepted. Prices, selected seed, unlocks and rewards stay server-owned.
actionRequest.OnServerEvent:Connect(function(player, action, cropId)
	if type(action) ~= "string" or (action ~= "Buy" and action ~= "Select") then return end
	if type(cropId) ~= "string" or not Config.Crops[cropId] then return end
	local session = sessions[player]
	if not session then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local target = action == "Buy" and session.world.shop or root
	if not allowed(player, player, target, Config.ShopDistance) then return end
	local ok, message
	if action == "Buy" then ok, message = session.state:buy(cropId) else ok, message = session.state:select(cropId) end
	if ok and action == "Buy" then message = "+1 " .. cropId .. " Seed • Selected for planting" end
	publish(player, session, message, ok and { kind = action, position = target.Position, cropId = cropId } or nil)
end)

local function prompt(part, action, callback)
	local interaction = Instance.new("ProximityPrompt")
	interaction.ActionText, interaction.ObjectText = action, part.Name == "SeedShop" and "Seed Shop" or "Harvest Basket"
	interaction.MaxActivationDistance = 12
	interaction.RequiresLineOfSight = false
	interaction.HoldDuration = 0
	interaction.Parent = part
	interaction.Triggered:Connect(callback)
end

local function join(player)
	if sessions[player] then return end
	local slot = 1
	while slots[slot] do slot += 1 end
	slots[slot] = true
	local state = FarmState.new(Config)
	local world = World.create(farms, player, slot, Config)
	local session = { state = state, world = world, slot = slot, lastAction = -math.huge }
	sessions[player] = session
	publish(player, session, "Welcome! Buy a Tomato Seed at the green shop.")
	prompt(world.shop, "Browse seeds", function(visitor)
		if not allowed(visitor, player, world.shop, Config.ShopDistance) then return end
		feedback:FireClient(player, { kind = "Shop" })
	end)
	prompt(world.sell, "Sell all crops", function(visitor)
		if not allowed(visitor, player, world.sell, Config.ShopDistance) then return end
		local before = state.coins
		local ok, message, unlocks = state:sell()
		local earned = state.coins - before
		if ok then
			message = "+" .. earned .. " Coins • Harvest sold!"
			if #unlocks > 0 then message ..= "\nUNLOCKED: " .. table.concat(unlocks, ", ") .. "!" end
		end
		publish(player, session, message, ok and { kind = "Sell", position = world.sell.Position, amount = earned, unlocks = unlocks } or nil)
	end)
	for index, view in ipairs(world.plots) do
		local click = Instance.new("ClickDetector")
		click.MaxActivationDistance = Config.InteractionDistance
		click.Parent = view.soil
		click.MouseClick:Connect(function(visitor)
			if not allowed(visitor, player, view.soil, Config.InteractionDistance) then return end
			local ok, message, newDiscovery
			local action = state.plots[index].stage == 0 and "Plant" or "Harvest"
			local mutation = state.plots[index].mutation
			local cropId = state.plots[index].cropId or state.selectedCrop
			if state.plots[index].stage == 0 then
				ok, message = state:plant(index, state.selectedCrop, os.clock())
			else
				ok, message, newDiscovery = state:harvest(index)
			end
			if ok then World.render(view, state.plots[index], Config) end
			if ok then
				message = action == "Plant" and (cropId .. " planted • Watch it grow!") or ("+1 " .. mutation .. " " .. cropId)
				if newDiscovery then message = "NEW DISCOVERY!\n+1 " .. mutation .. " " .. cropId end
			end
			publish(player, session, message, ok and { kind = action, position = view.soil.Position, mutation = mutation, cropId = cropId, discovery = newDiscovery } or nil)
		end)
	end
	local function spawn(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root and sessions[player] == session and player.Character == character then
			character:PivotTo(world.spawn)
		end
	end
	session.connection = player.CharacterAdded:Connect(spawn)
	if player.Character then task.spawn(spawn, player.Character) end
end

Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if not session then return end
	sessions[player] = nil
	slots[session.slot] = nil
	session.connection:Disconnect()
	session.world.model:Destroy()
end)
Players.PlayerAdded:Connect(join)
for _, player in ipairs(Players:GetPlayers()) do join(player) end

require(script.Parent.StudioPreview).install(Config, World, feedback, sessions)

while true do
	task.wait(0.25)
	local now = os.clock()
	for player, session in pairs(sessions) do
		for _, index in ipairs(session.state:advance(now, function(low, high) return random:NextInteger(low, high) end)) do
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
