local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Effects = require(script.Parent.FarmEffects)
local FarmPanels = require(script.Parent.FarmPanels)
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "MutantFarmHUD", false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local panels = FarmPanels.create(gui, player, Config, ReplicatedStorage:WaitForChild("FarmAction"))
local cream = Color3.fromRGB(255, 243, 214)
local dark = Color3.fromRGB(24, 45, 38)

local function round(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), object
end
local function label(parent, content, position, size, fontSize, color)
	local text = Instance.new("TextLabel")
	text.Text, text.Position, text.Size = content, position, size
	text.BackgroundTransparency, text.TextColor3 = 1, color or cream
	text.Font, text.TextSize, text.TextWrapped = Enum.Font.GothamBold, fontSize, true
	text.Parent = parent
	return text
end
local function constrain(object, width, height)
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize, constraint.Parent = Vector2.new(width, height), object
end
local panel = Instance.new("Frame")
panel.AnchorPoint, panel.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 8)
panel.Size, panel.BackgroundColor3 = UDim2.new(0.94, 0, 0, 168), dark
panel.BackgroundTransparency, panel.Parent = 0.04, gui
round(panel, 14)
constrain(panel, 600, 168)
local titleLabel = label(panel, "MUTANT FARM", UDim2.fromOffset(9, 7), UDim2.new(0.48, 0, 0, 21), 17)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
for index, info in ipairs({ { "Seeds", panels.openSeeds }, { "Book", panels.openBook } }) do
	local button = Instance.new("TextButton")
	button.Position, button.Size = UDim2.new(0.5 + (index - 1) * 0.25, 0, 0, 5), UDim2.new(0.25, -7, 0, 25)
	button.Text, button.Font, button.TextSize = info[1], Enum.Font.GothamBold, 13
	button.TextColor3, button.BackgroundColor3, button.Parent = cream, Color3.fromRGB(60, 106, 74), panel
	round(button, 7)
	button.Activated:Connect(info[2])
end
local cards = {}
for index, info in ipairs({ {"Coins", "Coins", Color3.fromRGB(255, 212, 95)}, {"SeedCount", "Seeds", Color3.fromRGB(167, 232, 136)}, {"HarvestCount", "Harvest", Color3.fromRGB(255, 146, 124)} }) do
	local card = Instance.new("Frame")
	card.Position, card.Size = UDim2.new((index - 1) / 3, 7, 0, 33), UDim2.new(1 / 3, -14, 0, 54)
	card.BackgroundColor3, card.Parent = Color3.fromRGB(39, 64, 52), panel
	round(card, 9)
	local count = label(card, "0", UDim2.fromOffset(0, 2), UDim2.new(1, 0, 0, 28), 23, info[3])
	count.TextScaled = true
	local textLimit = Instance.new("UITextSizeConstraint")
	textLimit.MinTextSize, textLimit.MaxTextSize, textLimit.Parent = 12, 23, count
	label(card, info[2], UDim2.fromOffset(0, 31), UDim2.new(1, 0, 0, 17), 12)
	cards[info[1]] = { frame = card, count = count, value = nil }
end
local basket = label(panel, "Basket empty", UDim2.fromOffset(10, 91), UDim2.new(1, -20, 0, 19), 12)
local guide = label(panel, "BUY → PLANT → HARVEST → SELL", UDim2.fromOffset(10, 113), UDim2.new(1, -20, 0, 25), 13, Color3.fromRGB(175, 240, 205))
local saveStatus = label(gui, "Loading...", UDim2.new(0.5, 0, 1, -30), UDim2.new(0.94, 0, 0, 23), 12)
saveStatus.AnchorPoint = Vector2.new(0.5, 0)
saveStatus.BackgroundColor3, saveStatus.BackgroundTransparency = dark, 0.2
constrain(saveStatus, 600, 23)
round(saveStatus, 6)
local conditions = label(panel, "DAY • CLEAR", UDim2.fromOffset(8, 143), UDim2.new(1, -16, 0, 20), 12, Color3.fromRGB(188, 213, 245))

local toast = label(gui, "", UDim2.new(0.5, 0, 1, -94), UDim2.new(0.86, 0, 0, 48), 17)
toast.AnchorPoint, toast.BackgroundColor3, toast.BackgroundTransparency = Vector2.new(0.5, 0), dark, 0.06
toast.Visible = false
toast.ZIndex = 30
round(toast, 12)
constrain(toast, 540, 48)
local toastScale = Instance.new("UIScale", toast)
local reveal = Instance.new("Frame")
reveal.AnchorPoint, reveal.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 185)
reveal.Size, reveal.BackgroundColor3, reveal.BackgroundTransparency = UDim2.new(0.88, 0, 0, 73), Color3.fromRGB(56, 29, 87), 0.08
reveal.Visible, reveal.Parent = false, gui
reveal.ZIndex = 20
round(reveal, 14)
constrain(reveal, 500, 73)
local border = Instance.new("UIStroke", reveal)
border.Color, border.Thickness = Color3.fromRGB(139, 246, 226), 2
local title = label(reveal, "COSMIC MUTATION!", UDim2.fromOffset(8, 9), UDim2.new(1, -16, 0, 29), 23, Color3.fromRGB(165, 255, 235))
local subtitle = label(reveal, "A tiny universe grew in your garden.", UDim2.fromOffset(10, 41), UDim2.new(1, -20, 0, 22), 13)
local revealScale = Instance.new("UIScale", reveal)
local revealVersion, revealUntil = 0, 0
local function cosmicReveal(preview)
	revealVersion += 1
	local version = revealVersion
	revealUntil = os.clock() + 3.6
	reveal.Visible, revealScale.Scale = true, 0.85
	title.TextTransparency, subtitle.TextTransparency, border.Transparency = 0, 0, 0
	reveal.BackgroundTransparency = 0.08
	subtitle.Text = preview and "STUDIO PREVIEW • Visual only • No rewards" or "A tiny universe grew in your garden."
	TweenService:Create(revealScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(3, function()
		if revealVersion ~= version then return end
		TweenService:Create(title, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(subtitle, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(border, TweenInfo.new(0.5), { Transparency = 1 }):Play()
		TweenService:Create(reveal, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		task.delay(0.55, function() if revealVersion == version then reveal.Visible = false end end)
	end)
end
local toastVersion = 0
local toastLocked = false
local importantQueue = {}
local function showToast(payload)
	local important = payload.kind == "Expand" or payload.discovery or (payload.unlocks and #payload.unlocks > 0)
	if toastLocked then
		if important and #importantQueue < 8 then table.insert(importantQueue, payload) end
		return
	end
	toastLocked = important == true
	toastVersion += 1
	local version = toastVersion
	toast.Text, toast.TextColor3 = payload.text or "", Effects.color(payload)
	toast.Visible, toast.TextTransparency, toast.BackgroundTransparency = true, 0, 0.06
	toastScale.Scale = 0.94
	TweenService:Create(toastScale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(important and 2.6 or 3.2, function()
		if toastVersion ~= version then return end
		toast.Visible, toastLocked = false, false
		if #importantQueue > 0 then showToast(table.remove(importantQueue, 1)) end
	end)
end
local function message(payload)
	if payload.kind == "Shop" then panels.openSeeds(); return end
	if payload.kind == "Upgrades" then panels.openLand(); return end
	if payload.kind == "Select" then panels.close() end
	Effects.burst(payload)
	if payload.kind == "Ready" and payload.mutation == "Cosmic" then
		if os.clock() >= revealUntil then cosmicReveal(payload.preview) end
	end
	showToast(payload)
end

local targetHighlight = Instance.new("Highlight")
targetHighlight.Name, targetHighlight.FillTransparency = "LocalNextStep", 0.92
targetHighlight.OutlineColor, targetHighlight.FillColor = Color3.fromRGB(255, 226, 137), Color3.fromRGB(255, 226, 137)
targetHighlight.DepthMode, targetHighlight.Parent = Enum.HighlightDepthMode.Occluded, workspace
local targetName = "SeedShop"
local function refreshTarget()
	local farms = workspace:FindFirstChild("MutantFarms")
	local farm = farms and farms:FindFirstChild("Farm_" .. player.UserId)
	local target = farm and farm:FindFirstChild(targetName)
	if targetName == "SeedShop" or targetName == "SellStand" then
		local town = workspace:FindFirstChild("MutantFarmTown")
		local shared = town and town:FindFirstChild(targetName)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if shared and root and (not target or (root.Position - shared.Position).Magnitude < (root.Position - target.Position).Magnitude) then target = shared end
	end
	if targetName == "Soil" and farm then
		for _, item in ipairs(farm:GetChildren()) do
			if item:IsA("BasePart") and string.sub(item.Name, 1, 5) == "Soil_" then
				local stage = item:GetAttribute("GrowthStage") or 0
				if item:GetAttribute("Ready") or (stage == 0 and (player:GetAttribute("Ready") or 0) == 0) then target = item; break end
			end
		end
	end
	targetHighlight.Adornee, targetHighlight.Enabled = target, target ~= nil
end
local function amount(name) return player:GetAttribute(name) or 0 end
local function update()
	saveStatus.Text = (player:GetAttribute("SaveStatus") or "Loading...") .. " • " .. (player:GetAttribute("SaveMode") or "")
	for name, card in pairs(cards) do
		local value = amount(name)
		card.count.Text = tostring(value)
		if card.value ~= nil and value ~= card.value then
			card.frame.BackgroundColor3 = Color3.fromRGB(74, 105, 71)
			TweenService:Create(card.frame, TweenInfo.new(0.45), { BackgroundColor3 = Color3.fromRGB(39, 64, 52) }):Play()
		end
		card.value = value
	end
	local selected = player:GetAttribute("SelectedCrop") or Config.CropOrder[1]
	local collectionSize = #Config.CropOrder * #Config.Mutations
	basket.Text = amount("HarvestCount") > 0 and ("Basket: " .. amount("HarvestValue") .. " Coins • Discoveries: " .. amount("DiscoveryCount") .. "/" .. collectionSize) or ("Selected: " .. selected .. " (" .. amount("Seeds_" .. selected) .. ") • Book: " .. amount("DiscoveryCount") .. "/" .. collectionSize)
	if amount("Ready") > 0 then
		guide.Text, targetName = "3  HARVEST • Click / tap READY soil", "Soil"
	elseif amount("HarvestCount") > 0 then
		guide.Text, targetName = "4  SELL • Orange stall → E / tap", "SellStand"
	elseif amount("Seeds_" .. selected) > 0 and amount("Growing") < (player:GetAttribute("PlotCount") or Config.PlotCount) then
		guide.Text, targetName = "2  PLANT " .. selected .. " • Click empty soil", "Soil"
	elseif amount("SeedCount") > 0 and amount("Growing") < (player:GetAttribute("PlotCount") or Config.PlotCount) then
		guide.Text, targetName = "Choose a seed to plant using Seeds above", ""
	elseif amount("Growing") > 0 then
		guide.Text, targetName = "GROWING • Watch for READY, then harvest", ""
	else
		guide.Text, targetName = "1  BUY • Green Seed Shop → E / tap", "SeedShop"
	end
	refreshTarget()
end
local updateQueued = false
player.AttributeChanged:Connect(function()
	if updateQueued then return end
	updateQueued = true
	task.defer(function() updateQueued = false; update() end)
end)
ReplicatedStorage:WaitForChild("FarmFeedback").OnClientEvent:Connect(message)
update()
message({ kind = "Notice", text = "Welcome to Mutant Farm Town • Your farm is here; town road leads left" })
Effects.startOrbits()
task.spawn(function() require(script.Parent.EnvironmentView).start(gui, conditions, Config) end)
-- Retry streamed/late-replicated world targets without per-frame scene searches.
task.spawn(function() while gui.Parent do task.wait(0.5); refreshTarget(); panels.refresh() end end)
