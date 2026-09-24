local World = {}
local green = Color3.fromRGB(89, 173, 113)
local cream = Color3.fromRGB(255, 242, 205)

function World.part(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Position = name, size, position
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function World.label(part, text, offset, width, height)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(width or 180, height or 54)
	gui.StudsOffset = Vector3.new(0, offset or 3, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 70
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(25, 43, 39)
	label.BackgroundTransparency = 0.12
	label.TextColor3 = cream
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextWrapped = true
	label.Text = text
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
	return label
end

local function kiosk(parent, position, name, color, text)
	local stand = World.part(parent, name, Vector3.new(9, 3, 6), position + Vector3.new(0, 1.5, 0), color)
	World.part(parent, "Canopy", Vector3.new(11, 0.6, 8), position + Vector3.new(0, 6, 0), color)
	for _, x in ipairs({ -4, 4 }) do
		World.part(parent, "Post", Vector3.new(0.35, 6, 0.35), position + Vector3.new(x, 3, 2.5), cream, Enum.Material.Wood)
	end
	World.label(stand, text, 6, 190, 60)
	return stand
end

function World.create(parent, player, slot, config)
	local model = Instance.new("Model")
	model.Name = "Farm_" .. player.UserId
	model:SetAttribute("OwnerUserId", player.UserId)
	model.Parent = parent
	local origin = Vector3.new(((slot - 1) % 4) * 80, 4, math.floor((slot - 1) / 4) * 80)
	World.part(model, "Meadow", Vector3.new(64, 2, 64), origin, green, Enum.Material.Grass)
	World.part(model, "Path", Vector3.new(54, 0.15, 11), origin + Vector3.new(0, 1.1, 14), Color3.fromRGB(223, 206, 164), Enum.Material.Sand)
	local sign = World.part(model, "FarmSign", Vector3.new(14, 2, 0.5), origin + Vector3.new(0, 5, -30), Color3.fromRGB(31, 70, 57))
	World.label(sign, "MUTANT FARM\n" .. player.DisplayName .. "'s garden", 2, 240, 58)
	for _, x in ipairs({ -31, 31 }) do
		World.part(model, "Fence", Vector3.new(0.5, 2, 62), origin + Vector3.new(x, 2, 0), cream, Enum.Material.Wood)
	end
	for _, z in ipairs({ -31, 31 }) do
		World.part(model, "Fence", Vector3.new(62, 2, 0.5), origin + Vector3.new(0, 2, z), cream, Enum.Material.Wood)
	end
	local shop = kiosk(model, origin + Vector3.new(-21, 1, 17), "SeedShop", Color3.fromRGB(49, 136, 94), "SEED SHOP\nTomato Seed • " .. config.Crops.Tomato.SeedPrice .. " Coins")
	local sell = kiosk(model, origin + Vector3.new(21, 1, 17), "SellStand", Color3.fromRGB(220, 143, 58), "SELL HARVEST\nTomatoes → Coins")
	local plots = {}
	for index = 1, config.PlotCount do
		local position = origin + Vector3.new(((index - 1) % 3 - 1) * 13, 1.3, -5 - math.floor((index - 1) / 3) * 13)
		World.part(model, "PlotBorder", Vector3.new(11, 0.5, 10), position, cream, Enum.Material.Wood)
		local soil = World.part(model, "Soil_" .. index, Vector3.new(10, 0.6, 9), position + Vector3.new(0, 0.1, 0), Color3.fromRGB(83, 53, 40), Enum.Material.Ground)
		soil:SetAttribute("OwnerUserId", player.UserId)
		local label = World.label(soil, "PLANT TOMATO\nClick / tap soil", 1.6)
		local crop = Instance.new("Model")
		crop.Name, crop.Parent = "Crop", model
		plots[index] = { soil = soil, label = label, crop = crop }
	end
	return { model = model, origin = origin, plots = plots, shop = shop, sell = sell, spawn = CFrame.new(origin + Vector3.new(0, 5, 23)) }
end

function World.render(view, plot, config)
	view.crop:ClearAllChildren()
	view.crop:RemoveTag("CosmicCrop")
	view.label.Parent.StudsOffset = Vector3.new(0, 1.6, 0)
	if plot.stage == 0 then
		view.label.Text = "PLANT TOMATO\nClick / tap soil"
		view.label.TextColor3 = cream
		return
	end
	local mutation = config.Mutations[1]
	for _, candidate in ipairs(config.Mutations) do
		if candidate.Id == plot.mutation then mutation = candidate; break end
	end
	local mature = plot.stage == 4
	local scale = mature and mutation.Scale or 1
	local color = Color3.fromRGB(table.unpack(mutation.Color))
	local base = view.soil.Position + Vector3.new(0, 0.4, 0)
	local height = ({ 0.9, 1.8, 2.8, 3.5 })[plot.stage]
	height *= scale
	local stem = World.part(view.crop, "Stem", Vector3.new(0.3, height, 0.3), base + Vector3.new(0, height / 2, 0), Color3.fromRGB(51, 125, 60))
	stem.CanCollide, stem.CanQuery = false, false
	for _, direction in ipairs({ -1, 1 }) do
		local leaf = World.part(view.crop, "Leaf", Vector3.new(height * 0.7, 0.18, height * 0.35), base + Vector3.new(direction * height * 0.25, height * 0.6, 0), green)
		leaf.CFrame *= CFrame.Angles(0, 0, direction * math.rad(22))
		leaf.CanCollide, leaf.CanQuery = false, false
	end
	if plot.stage >= 3 then
		local fruit = World.part(view.crop, "Tomato", Vector3.new(2, 2, 2) * scale, base + Vector3.new(0, height, 0), mature and color or Color3.fromRGB(125, 191, 69))
		fruit.Shape = Enum.PartType.Ball
		fruit.CanCollide, fruit.CanQuery = false, false
		local crown = World.part(view.crop, "Calyx", Vector3.new(1.2, 0.16, 1.2) * scale, fruit.Position + Vector3.new(0, scale, 0), Color3.fromRGB(46, 125, 61))
		crown.CFrame *= CFrame.Angles(0, math.rad(45), 0)
		crown.CanCollide, crown.CanQuery = false, false
		if mature and mutation.Id == "Golden" then fruit.Material = Enum.Material.Metal end
		if mature and (mutation.Id == "Crystal" or mutation.Id == "Cosmic") then
			fruit.Material = Enum.Material.Neon
			for i = 1, 5 do
				local angle = i * math.pi * 2 / 5
				local shard = World.part(view.crop, "CrystalShard", Vector3.new(0.5, 1.6, 0.5) * scale, fruit.Position + Vector3.new(math.cos(angle) * scale, 0.4, math.sin(angle) * scale), color, Enum.Material.Neon)
				shard.CFrame *= CFrame.Angles(math.rad(25), angle, math.rad(25))
				shard.CanCollide, shard.CanQuery = false, false
			end
			local light = Instance.new("PointLight")
			light.Color, light.Brightness, light.Range = color, 1.5, 12
			light.Parent = fruit
		end
		if mature and mutation.Id == "Cosmic" then
			fruit.Color = Color3.fromRGB(64, 24, 123)
			for i = 1, 12 do
				local angle = i * math.pi / 6
				local star = World.part(view.crop, "OrbitStar", Vector3.new(0.28, 0.28, 0.28), fruit.Position + Vector3.new(math.cos(angle) * 2.5, math.sin(angle) * 0.7, math.sin(angle) * 2.5), i % 2 == 0 and Color3.fromRGB(107, 255, 234) or Color3.fromRGB(255, 212, 111), Enum.Material.Neon)
				star.Shape = Enum.PartType.Ball
				star.CanCollide, star.CanQuery = false, false
			end
			local sparkles = Instance.new("Sparkles")
			sparkles.SparkleColor, sparkles.Parent = color, fruit
			local highlight = Instance.new("Highlight")
			highlight.FillColor, highlight.OutlineColor = color, Color3.fromRGB(128, 255, 240)
			highlight.FillTransparency = 0.7
			highlight.Adornee, highlight.Parent = view.crop, view.crop
			view.crop:AddTag("CosmicCrop")
		end
	end
	view.label.Text = mature and ("READY • Click / tap\n" .. mutation.Id .. " " .. plot.cropId) or ({ "SPROUT", "GROWING", "RIPENING" })[plot.stage]
	view.label.TextColor3 = mature and color or cream
	view.label.Parent.StudsOffset = Vector3.new(0, mature and (height + 2.2) or 1.6, 0)
end

function World.countdown(view, plot, config, now)
	if plot.stage == 0 or plot.stage == 4 then return end
	local seconds = math.max(0, math.ceil(config.Crops[plot.cropId].GrowSeconds - (now - plot.plantedAt)))
	local text = ({ "SPROUT", "GROWING", "RIPENING" })[plot.stage] .. " • " .. seconds .. "s\nMutation at maturity"
	if view.label.Text ~= text then view.label.Text = text end
end

return World
