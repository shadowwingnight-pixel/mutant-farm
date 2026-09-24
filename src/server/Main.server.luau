local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local FarmState = require(script.Parent.FarmState)
local World = require(script.Parent.FarmWorld)

local farms = Instance.new("Folder")
farms.Name, farms.Parent = "MutantFarms", workspace
local sessions, slots = {}, {}
local random = Random.new()

local function publish(player, session, message)
	local count, value = session.state:bagSummary()
	player:SetAttribute("Coins", session.state.coins)
	player:SetAttribute("TomatoSeeds", session.state.seeds.Tomato)
	player:SetAttribute("Tomatoes", count)
	player:SetAttribute("HarvestValue", value)
	local growing, ready = 0, 0
	for _, plot in ipairs(session.state.plots) do
		if plot.stage > 0 and plot.stage < 4 then growing += 1 end
		if plot.stage == 4 then ready += 1 end
	end
	player:SetAttribute("Growing", growing)
	player:SetAttribute("Ready", ready)
	for _, mutation in ipairs(Config.Mutations) do
		player:SetAttribute("Tomato_" .. mutation.Id, session.state.bag.Tomato[mutation.Id] or 0)
	end
	if message then
		player:SetAttribute("FarmMessage", message)
		player:SetAttribute("FarmMessageId", (player:GetAttribute("FarmMessageId") or 0) + 1)
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
	if (root.Position - target.Position).Magnitude > distance then return false end
	local now = os.clock()
	if now - session.lastAction < Config.ActionCooldown then return false end
	session.lastAction = now
	return true
end

local function prompt(part, action, callback)
	local interaction = Instance.new("ProximityPrompt")
	interaction.ActionText, interaction.ObjectText = action, part.Name == "SeedShop" and "Tomato Seeds" or "Harvest Basket"
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
	prompt(world.shop, "Buy seed • " .. Config.Crops.Tomato.SeedPrice .. " Coins", function(visitor)
		if not allowed(visitor, player, world.shop, Config.ShopDistance) then return end
		local _, message = state:buy("Tomato")
		publish(player, session, message)
	end)
	prompt(world.sell, "Sell all Tomatoes", function(visitor)
		if not allowed(visitor, player, world.sell, Config.ShopDistance) then return end
		local _, message = state:sell()
		publish(player, session, message)
	end)
	for index, view in ipairs(world.plots) do
		local click = Instance.new("ClickDetector")
		click.MaxActivationDistance = Config.InteractionDistance
		click.Parent = view.soil
		click.MouseClick:Connect(function(visitor)
			if not allowed(visitor, player, view.soil, Config.InteractionDistance) then return end
			local ok, message
			if state.plots[index].stage == 0 then
				ok, message = state:plant(index, "Tomato", os.clock())
			else
				ok, message = state:harvest(index)
			end
			if ok then World.render(view, state.plots[index], Config) end
			publish(player, session, message)
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

while true do
	task.wait(0.25)
	local now = os.clock()
	for player, session in pairs(sessions) do
		for _, index in ipairs(session.state:advance(now, function(low, high) return random:NextInteger(low, high) end)) do
			local plot = session.state.plots[index]
			World.render(session.world.plots[index], plot, Config)
			if plot.stage == 4 then publish(player, session, plot.mutation .. " Tomato is READY! Click its soil to harvest.") end
		end
		for index, plot in ipairs(session.state.plots) do
			World.countdown(session.world.plots[index], plot, Config, now)
		end
	end
end
