-- Presentation only: the existing FarmState owns all growth and mutation decisions.
local CropVisuals = {}

function CropVisuals.render(view, plot, config, world, now)
	view.crop:RemoveTag("CosmicCrop")
	view.crop:ClearAllChildren()
	view.label.Parent.StudsOffset = Vector3.new(0, 1.3, 0)
	view.label.TextColor3 = Color3.fromRGB(255, 242, 205)
	view.visualPhase = "EMPTY"
	if plot.stage == 0 then
		view.label.Text = "PLANT • Click / tap"
		return
	end
	local base = view.soil.Position + Vector3.new(0, view.soil.Size.Y / 2, 0)
	local function piece(name, size, position, color, material, shape)
		local part = world.part(view.crop, name, size, position, color, material)
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.CastShadow = false
		if shape then part.Shape = shape end
		return part
	end
	local leafGreen = Color3.fromRGB(61, 143, 66)
	if plot.stage == 1 and now - plot.plantedAt < 1.3 then
		view.visualPhase = "SEED"
		piece("SeedMound", Vector3.new(1.5, 0.3, 1.2), base + Vector3.new(0, 0.06, 0), Color3.fromRGB(105, 67, 43), Enum.Material.Ground, Enum.PartType.Ball)
		piece("Seed", Vector3.new(0.25, 0.14, 0.4), base + Vector3.new(0, 0.24, 0), Color3.fromRGB(240, 219, 158), nil, Enum.PartType.Ball)
		view.label.Text = "SEED PLANTED"
		return
	end
	view.visualPhase = ({ "SPROUT", "YOUNG PLANT", "TOMATO PLANT", "READY" })[plot.stage]
	local mutation = config.Mutations[1]
	for _, candidate in ipairs(config.Mutations) do
		if candidate.Id == plot.mutation then mutation = candidate; break end
	end
	local ready = plot.stage == 4
	local scale = ready and mutation.Scale or 1
	local color = ready and Color3.fromRGB(table.unpack(mutation.Color)) or Color3.fromRGB(140, 187, 76)
	local height = ({ 0.8, 1.9, 3.2, 3.6 })[plot.stage] * scale
	if ready and mutation.Id == "Golden" then leafGreen = Color3.fromRGB(192, 162, 49) end
	if ready and mutation.Id == "Crystal" then leafGreen = Color3.fromRGB(59, 178, 181) end
	if ready and mutation.Id == "Cosmic" then leafGreen = Color3.fromRGB(102, 66, 163) end
	piece("Stem", Vector3.new(0.22, height, 0.22) * Vector3.new(scale, 1, scale), base + Vector3.new(0, height / 2, 0), leafGreen)
	for level = 1, math.min(plot.stage + 1, 4) do
		local y = height * (0.2 + level * 0.15)
		for _, side in ipairs({ -1, 1 }) do
			local leaf = piece("Leaf", Vector3.new(height * 0.46, 0.15 * scale, height * 0.22), base + Vector3.new(side * height * 0.22, y, (level % 2 == 0 and 0.2 or -0.2) * scale), leafGreen)
			leaf.CFrame *= CFrame.Angles(0, math.rad(level * 25), side * math.rad(24))
		end
	end
	if plot.stage >= 3 then
		piece("SupportStake", Vector3.new(0.12, height + 0.35, 0.12), base + Vector3.new(0, height / 2, 0.45 * scale), Color3.fromRGB(165, 126, 77), Enum.Material.Wood)
		for index, offset in ipairs({ Vector3.new(-0.85, 0.64, -0.3), Vector3.new(0.85, 0.79, 0.1), Vector3.new(0, 0.98, -0.6) }) do
			local center = base + Vector3.new(offset.X * scale, offset.Y * height, offset.Z * scale)
			local size = Vector3.new(1.25, 1.05, 1.2) * scale
			local material = Enum.Material.SmoothPlastic
			if ready and mutation.Id == "Golden" then material = Enum.Material.Metal end
			if ready and (mutation.Id == "Crystal" or mutation.Id == "Cosmic") then material = Enum.Material.Neon end
			local fruit = piece(index == 3 and "Tomato" or "Fruit", size, center, color, material, Enum.PartType.Ball)
			if ready and mutation.Id == "Golden" then fruit.Reflectance = 0.18 end
			local crown = piece("Calyx", Vector3.new(0.8, 0.12, 0.8) * scale, center + Vector3.new(0, 0.53 * scale, 0), leafGreen)
			crown.CFrame *= CFrame.Angles(0, math.rad(45), 0)
			if ready and (mutation.Id == "Crystal" or mutation.Id == "Cosmic") then
				for shardIndex = 1, 3 do
					local angle = shardIndex * math.pi * 2 / 3
					local shard = piece("CrystalFacet", Vector3.new(0.35, 0.95, 0.35) * scale, center + Vector3.new(math.cos(angle) * 0.5, 0.1, math.sin(angle) * 0.5) * scale, color, Enum.Material.Neon)
					shard.CFrame *= CFrame.Angles(0.4, angle, 0.5)
				end
			end
		end
	end
	if ready and mutation.Id ~= "Normal" and mutation.Id ~= "Giant" then
		local fruit = view.crop:FindFirstChild("Tomato")
		local light = Instance.new("PointLight")
		light.Color, light.Brightness, light.Range, light.Shadows = color, 0.7, 9, false
		light.Parent = fruit
	end
	if ready and mutation.Id == "Cosmic" then
		local center = base + Vector3.new(0, height * 0.8, 0)
		view.crop:SetAttribute("OrbitCenter", center)
		for index = 1, 12 do
			local angle = index * math.pi / 6
			local star = piece("OrbitStar", Vector3.new(0.24, 0.24, 0.24), center + Vector3.new(math.cos(angle) * 2.7, math.sin(angle) * 0.8, math.sin(angle) * 2.7), index % 2 == 0 and Color3.fromRGB(108, 255, 228) or Color3.fromRGB(255, 218, 130), Enum.Material.Neon, Enum.PartType.Ball)
			star:SetAttribute("OrbitIndex", index)
		end
		local highlight = Instance.new("Highlight")
		highlight.FillColor, highlight.OutlineColor = color, Color3.fromRGB(132, 255, 237)
		highlight.FillTransparency = 0.82
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Adornee, highlight.Parent = view.crop, view.crop
		view.crop:AddTag("CosmicCrop")
	end
	view.label.Text = ready and (string.upper(mutation.Id) .. " • READY\nClick / tap to harvest") or view.visualPhase
	view.label.TextColor3 = ready and color or Color3.fromRGB(255, 242, 205)
	view.label.Parent.StudsOffset = Vector3.new(0, ready and height + 1.4 or 1.3, 0)
end

return CropVisuals
