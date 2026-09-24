local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "MutantFarmHUD", false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function round(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), object
end

local panel = Instance.new("Frame")
panel.AnchorPoint, panel.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 10)
panel.Size = UDim2.new(0.94, 0, 0, 176)
panel.BackgroundColor3 = Color3.fromRGB(24, 47, 40)
panel.BackgroundTransparency = 0.06
panel.Parent = gui
round(panel, 14)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize, limit.Parent = Vector2.new(620, 176), panel

local function text(parent, name, content, position, size, fontSize, color)
	local label = Instance.new("TextLabel")
	label.Name, label.Text = name, content
	label.Position, label.Size = position, size
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color3.fromRGB(255, 243, 212)
	label.Font, label.TextSize = Enum.Font.GothamBold, fontSize
	label.TextWrapped = true
	label.Parent = parent
	return label
end

text(panel, "Title", "MUTANT FARM", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 24), 20)
local coins = text(panel, "Coins", "", UDim2.new(0, 6, 0, 39), UDim2.new(1 / 3, -8, 0, 38), 18, Color3.fromRGB(255, 214, 104))
local seeds = text(panel, "Seeds", "", UDim2.new(1 / 3, 2, 0, 39), UDim2.new(1 / 3, -4, 0, 38), 18, Color3.fromRGB(165, 237, 145))
local tomatoes = text(panel, "Tomatoes", "", UDim2.new(2 / 3, 2, 0, 39), UDim2.new(1 / 3, -8, 0, 38), 18, Color3.fromRGB(255, 143, 124))
local basket = text(panel, "Basket", "", UDim2.fromOffset(10, 80), UDim2.new(1, -20, 0, 40), 13)
local guide = text(panel, "Guide", "", UDim2.fromOffset(12, 123), UDim2.new(1, -24, 0, 43), 14, Color3.fromRGB(168, 235, 218))

local toast = text(gui, "Message", "", UDim2.new(0.5, 0, 1, -88), UDim2.new(0.9, 0, 0, 58), 17)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.BackgroundColor3, toast.BackgroundTransparency = Color3.fromRGB(24, 47, 40), 0.1
round(toast, 12)
local toastLimit = Instance.new("UISizeConstraint")
toastLimit.MaxSize, toastLimit.Parent = Vector2.new(640, 58), toast

local function amount(name) return player:GetAttribute(name) or 0 end
local function update()
	coins.Text = amount("Coins") .. "\nCoins"
	seeds.Text = amount("TomatoSeeds") .. "\nTomato Seeds"
	tomatoes.Text = amount("Tomatoes") .. "\nTomatoes"
	local variants = {}
	for _, mutation in ipairs(Config.Mutations) do
		local count = amount("Tomato_" .. mutation.Id)
		if count > 0 then table.insert(variants, mutation.Id .. " " .. count) end
	end
	basket.Text = #variants > 0 and (table.concat(variants, " • ") .. " | " .. amount("HarvestValue") .. " Coins") or "Basket empty • Every Tomato can mutate"
	if amount("Ready") > 0 then
		guide.Text = "HARVEST  •  Click / tap READY soil to collect your Tomato."
	elseif amount("Tomatoes") > 0 then
		guide.Text = "SELL  •  Visit the orange stand. Press E / tap its prompt."
	elseif amount("TomatoSeeds") > 0 then
		guide.Text = "PLANT  •  Walk to empty soil and click / tap it."
	elseif amount("Growing") > 0 then
		guide.Text = "GROW  •  Watch your plants! One mutation rolls at maturity."
	else
		guide.Text = "BUY  •  Visit the green seed shop. Press E / tap its prompt."
	end
end

local toastVersion = 0
local toastTween
local function message()
	toastVersion += 1
	local version = toastVersion
	if toastTween then toastTween:Cancel(); toastTween = nil end
	toast.Text = player:GetAttribute("FarmMessage") or "Buy → Plant → Grow → Harvest → Sell"
	local cosmic = string.find(toast.Text, "Cosmic", 1, true) ~= nil
	toast.BackgroundColor3 = cosmic and Color3.fromRGB(87, 35, 131) or Color3.fromRGB(24, 47, 40)
	toast.TextColor3 = cosmic and Color3.fromRGB(150, 255, 235) or Color3.fromRGB(255, 243, 212)
	toast.Visible = true
	if cosmic then
		toastTween = TweenService:Create(toast, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 5, true), { BackgroundColor3 = Color3.fromRGB(40, 94, 124) })
		toastTween:Play()
	end
	task.delay(cosmic and 9 or 5, function() if toastVersion == version then toast.Visible = false end end)
end

player.AttributeChanged:Connect(function(name)
	if name == "FarmMessageId" then message() else update() end
end)
update()
message()

-- Cosmetic only. All mutation selection and value remain on the server.
local cosmicCrops = {}
local function track(model)
	-- Tags can arrive before descendants; discover the fruit during rendering.
	cosmicCrops[model] = true
end
CollectionService:GetInstanceAddedSignal("CosmicCrop"):Connect(track)
CollectionService:GetInstanceRemovedSignal("CosmicCrop"):Connect(function(model) cosmicCrops[model] = nil end)
for _, model in ipairs(CollectionService:GetTagged("CosmicCrop")) do track(model) end
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for model in pairs(cosmicCrops) do
		if not model.Parent then cosmicCrops[model] = nil; continue end
		local fruit = model:FindFirstChild("Tomato")
		if not fruit then continue end
		local index = 0
		for _, star in ipairs(model:GetChildren()) do
			if star.Name ~= "OrbitStar" or not star:IsA("BasePart") then continue end
			index += 1
			local angle = now * 1.2 + index * math.pi / 6
			star.Position = fruit.Position + Vector3.new(math.cos(angle) * 2.5, math.sin(angle) * 0.7, math.sin(angle) * 2.5)
		end
	end
end)
