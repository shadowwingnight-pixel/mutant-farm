local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Effects = require(script.Parent.FarmEffects)
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "MutantFarmHUD", false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
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
panel.Size, panel.BackgroundColor3 = UDim2.new(0.94, 0, 0, 143), dark
panel.BackgroundTransparency, panel.Parent = 0.04, gui
round(panel, 14)
constrain(panel, 600, 143)
label(panel, "MUTANT FARM", UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 21), 18)
local cards = {}
for index, info in ipairs({ {"Coins", "Coins", Color3.fromRGB(255, 212, 95)}, {"TomatoSeeds", "Tomato Seeds", Color3.fromRGB(167, 232, 136)}, {"Tomatoes", "Tomatoes", Color3.fromRGB(255, 146, 124)} }) do
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

local toast = label(gui, "", UDim2.new(0.5, 0, 1, -94), UDim2.new(0.86, 0, 0, 48), 17)
toast.AnchorPoint, toast.BackgroundColor3, toast.BackgroundTransparency = Vector2.new(0.5, 0), dark, 0.06
toast.Visible = false
round(toast, 12)
constrain(toast, 540, 48)
local toastScale = Instance.new("UIScale", toast)
local reveal = Instance.new("Frame")
reveal.AnchorPoint, reveal.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 154)
reveal.Size, reveal.BackgroundColor3, reveal.BackgroundTransparency = UDim2.new(0.88, 0, 0, 73), Color3.fromRGB(56, 29, 87), 0.08
reveal.Visible, reveal.Parent = false, gui
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
local function message(payload)
	Effects.burst(payload)
	if payload.kind == "Ready" and payload.mutation == "Cosmic" then
		-- Several crops can mature together: one brief reveal, never a flashing stack.
		if os.clock() >= revealUntil then cosmicReveal(payload.preview) end
	end
	toastVersion += 1
	local version = toastVersion
	toast.Text, toast.TextColor3 = payload.text or "", Effects.color(payload)
	toast.Visible, toast.TextTransparency, toast.BackgroundTransparency = true, 0, 0.06
	toastScale.Scale = 0.94
	TweenService:Create(toastScale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(3.2, function()
		if toastVersion ~= version then return end
		toast.Visible = false
	end)
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
	if targetName == "Soil" and farm then
		for _, item in ipairs(farm:GetChildren()) do
			if item:IsA("BasePart") and string.sub(item.Name, 1, 5) == "Soil_" then
				local stage = item:GetAttribute("GrowthStage") or 0
				if stage == 4 or (stage == 0 and (player:GetAttribute("Ready") or 0) == 0) then target = item; break end
			end
		end
	end
	targetHighlight.Adornee, targetHighlight.Enabled = target, target ~= nil
end
local function amount(name) return player:GetAttribute(name) or 0 end
local function update()
	for name, card in pairs(cards) do
		local value = amount(name)
		card.count.Text = tostring(value)
		if card.value ~= nil and value ~= card.value then
			card.frame.BackgroundColor3 = Color3.fromRGB(74, 105, 71)
			TweenService:Create(card.frame, TweenInfo.new(0.45), { BackgroundColor3 = Color3.fromRGB(39, 64, 52) }):Play()
		end
		card.value = value
	end
	basket.Text = amount("Tomatoes") > 0 and ("Basket value: " .. amount("HarvestValue") .. " Coins • Sell at the orange stall") or "Every Tomato can mutate • 15 seconds to grow"
	if amount("Ready") > 0 then
		guide.Text, targetName = "3  HARVEST • Click / tap READY soil", "Soil"
	elseif amount("Tomatoes") > 0 then
		guide.Text, targetName = "4  SELL • Orange stall → E / tap", "SellStand"
	elseif amount("TomatoSeeds") > 0 and amount("Growing") < Config.PlotCount then
		guide.Text, targetName = "2  PLANT • Click / tap an empty soil plot", "Soil"
	elseif amount("Growing") > 0 then
		guide.Text, targetName = "GROWING • Watch for READY, then harvest", ""
	else
		guide.Text, targetName = "1  BUY • Green Seed Shop → E / tap", "SeedShop"
	end
	refreshTarget()
end
player.AttributeChanged:Connect(update)
ReplicatedStorage:WaitForChild("FarmFeedback").OnClientEvent:Connect(message)
update()
message({ kind = "Notice", text = "Start at the green Seed Shop • Follow the highlighted stall" })
Effects.startOrbits()
-- Retry streamed/late-replicated world targets without per-frame scene searches.
task.spawn(function() while gui.Parent do task.wait(0.5); refreshTarget() end end)
