-- Client-only cosmetics. Bounded bursts, distance-culling, no audio/assets.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Effects = {}
local activeParts = 0
local lastCosmicPulse = -math.huge
local colors = {
	Expand = Color3.fromRGB(133, 219, 255),
	Buy = Color3.fromRGB(164, 236, 136), Plant = Color3.fromRGB(188, 222, 127),
	Harvest = Color3.fromRGB(255, 126, 104), Sell = Color3.fromRGB(255, 212, 95),
	Normal = Color3.fromRGB(244, 102, 81), Golden = Color3.fromRGB(255, 209, 75),
	Giant = Color3.fromRGB(255, 146, 94), Crystal = Color3.fromRGB(117, 243, 255),
	Cosmic = Color3.fromRGB(181, 126, 255), Notice = Color3.fromRGB(201, 227, 208),
}

function Effects.color(payload)
	return colors[payload.mutation] or colors[payload.kind] or colors.Notice
end

function Effects.burst(payload)
	local position = payload.position
	if typeof(position) ~= "Vector3" then return end
	local camera = workspace.CurrentCamera
	if camera and (camera.CFrame.Position - position).Magnitude > 85 then return end
	local cosmic = payload.kind == "Ready" and payload.mutation == "Cosmic"
	local color = Effects.color(payload)
	local count = cosmic and 16 or 7
	for index = 1, count do
		if activeParts >= 48 then break end
		activeParts += 1
		local spark = Instance.new("Part")
		spark.Name = "LocalFarmSpark"
		spark.Size = Vector3.new(0.18, cosmic and 0.65 or 0.25, 0.18)
		spark.Anchored, spark.CanCollide, spark.CanTouch, spark.CanQuery, spark.CastShadow = true, false, false, false, false
		spark.Material, spark.Color = Enum.Material.Neon, index % 2 == 0 and color or Color3.fromRGB(255, 237, 175)
		local angle = index / count * math.pi * 2
		spark.Position = position + Vector3.new(0, cosmic and 4 or 2, 0)
		spark.Parent = workspace
		local radius = cosmic and 5 or 2.3
		TweenService:Create(spark, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(spark.Position + Vector3.new(math.cos(angle) * radius, 1 + index % 3, math.sin(angle) * radius)) * CFrame.Angles(angle, angle, angle),
			Transparency = 1, Size = Vector3.new(0.05, 0.05, 0.05),
		}):Play()
		Debris:AddItem(spark, 1.2)
		task.delay(1.2, function() activeParts -= 1 end)
	end
	if cosmic and os.clock() - lastCosmicPulse >= 1 then
		lastCosmicPulse = os.clock()
		local glow = Instance.new("Part")
		glow.Name, glow.Shape = "LocalCosmicPulse", Enum.PartType.Ball
		glow.Size, glow.Position = Vector3.new(1, 1, 1), position + Vector3.new(0, 4, 0)
		glow.Anchored, glow.CanCollide, glow.CanTouch, glow.CanQuery, glow.CastShadow = true, false, false, false, false
		glow.Material, glow.Color, glow.Transparency = Enum.Material.Neon, color, 0.8
		glow.Parent = workspace
		local light = Instance.new("PointLight")
		light.Color, light.Brightness, light.Range, light.Shadows, light.Parent = color, 2, 14, false, glow
		TweenService:Create(glow, TweenInfo.new(0.9), { Size = Vector3.new(11, 11, 11), Transparency = 1 }):Play()
		TweenService:Create(light, TweenInfo.new(0.9), { Brightness = 0 }):Play()
		Debris:AddItem(glow, 1)
	end
end

function Effects.startOrbits()
	local crops = {}
	local function untrack(model)
		local entry = crops[model]
		if entry then entry.added:Disconnect(); entry.removed:Disconnect(); crops[model] = nil end
	end
	local function track(model)
		untrack(model)
		local stars = {}
		local function add(child)
			if child.Name == "OrbitStar" and child:IsA("BasePart") then stars[child] = true end
		end
		for _, child in ipairs(model:GetChildren()) do add(child) end
		crops[model] = { stars = stars, added = model.ChildAdded:Connect(add), removed = model.ChildRemoved:Connect(function(child) stars[child] = nil end) }
	end
	CollectionService:GetInstanceAddedSignal("CosmicCrop"):Connect(track)
	CollectionService:GetInstanceRemovedSignal("CosmicCrop"):Connect(untrack)
	for _, model in ipairs(CollectionService:GetTagged("CosmicCrop")) do track(model) end
	local elapsed = 0
	RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		if elapsed < 1 / 30 then return end
		elapsed = 0
		local camera = workspace.CurrentCamera
		if not camera then return end
		local now, animated = os.clock(), 0
		for model, entry in pairs(crops) do
			local center = model:GetAttribute("OrbitCenter")
			if not model.Parent then untrack(model); continue end
			if not center or (center - camera.CFrame.Position).Magnitude > 80 or animated >= 8 then continue end
			animated += 1
			for star in pairs(entry.stars) do
				local angle = now * 1.15 + (star:GetAttribute("OrbitIndex") or 0) * math.pi / 6
				star.Position = center + Vector3.new(math.cos(angle) * 2.7, math.sin(angle) * 0.8, math.sin(angle) * 2.7)
			end
		end
	end)
end

return Effects
