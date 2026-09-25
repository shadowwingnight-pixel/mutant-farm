local World = {}
local green = Color3.fromRGB(89, 173, 113)
local cream = Color3.fromRGB(255, 242, 205)

function World.part(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Position = name, size, position
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanTouch = false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function World.label(part, text, offset, width, height)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(width or 166, height or 42)
	gui.StudsOffset = Vector3.new(0, offset or 3, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 48
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(25, 43, 39)
	label.BackgroundTransparency = 0.12
	label.TextColor3 = cream
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextWrapped = true
	label.Text = text
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
	return label
end

local function decoration(parent, name, size, position, color, material, shape)
	local part = World.part(parent, name, size, position, color, material)
	part.CanCollide, part.CanQuery, part.CastShadow = false, false, false
	if shape then part.Shape = shape end
	return part
end

local function kiosk(parent, position, name, color, text)
	local stand = World.part(parent, name, Vector3.new(9, 2.5, 5), position + Vector3.new(0, 1.25, 0), Color3.fromRGB(148, 108, 69), Enum.Material.WoodPlanks)
	World.part(parent, "Counter", Vector3.new(9.6, 0.35, 5.6), position + Vector3.new(0, 2.7, 0), cream, Enum.Material.Wood)
	for stripe = 0, 6 do
		World.part(parent, "AwningStripe", Vector3.new(1.55, 0.4, 7), position + Vector3.new(-4.65 + stripe * 1.55, 6, 0), stripe % 2 == 0 and color or cream)
	end
	for _, x in ipairs({ -4, 4 }) do
		World.part(parent, "Post", Vector3.new(0.35, 6, 0.35), position + Vector3.new(x, 3, 2.5), cream, Enum.Material.Wood)
	end
	World.label(stand, text, 6.4, 190, 60)
	if name == "SeedShop" then
		for index = 1, 3 do
			local packet = decoration(parent, "SeedPacket", Vector3.new(1.2, 1.7, 0.2), position + Vector3.new((index - 2) * 2, 3.7, 0), cream)
			decoration(parent, "TomatoEmblem", Vector3.new(0.65, 0.65, 0.18), packet.Position + Vector3.new(0, 0, 0.2), Color3.fromRGB(233, 82, 65), nil, Enum.PartType.Ball)
		end
	else
		decoration(parent, "HarvestCrate", Vector3.new(4, 0.8, 2.6), position + Vector3.new(-1, 3.25, 0), Color3.fromRGB(111, 73, 42), Enum.Material.WoodPlanks)
		for index = 1, 3 do
			decoration(parent, "MarketTomato", Vector3.new(0.9, 0.9, 0.9), position + Vector3.new(index - 3, 3.9, 0), Color3.fromRGB(233, 82, 65), nil, Enum.PartType.Ball)
		end
		for index = 1, 3 do
			local coin = decoration(parent, "CoinStack", Vector3.new(0.18, 1, 1), position + Vector3.new(2.5, 2.9 + index * 0.19, 0), Color3.fromRGB(255, 200, 67), Enum.Material.Metal, Enum.PartType.Cylinder)
			coin.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
		end
	end
	return stand
end

function World.create(parent, player, slot, config, plotCount)
	local model = Instance.new("Model")
	model.Name = "Farm_" .. player.UserId
	model:SetAttribute("OwnerUserId", player.UserId)
	model.Parent = parent
	local origin = Vector3.new(((slot - 1) % 4) * 80, 4, math.floor((slot - 1) / 4) * 120)
	World.part(model, "Meadow", Vector3.new(76, 2, 76), origin, green, Enum.Material.Grass)
	World.part(model, "Path", Vector3.new(54, 0.15, 11), origin + Vector3.new(0, 1.1, 14), Color3.fromRGB(223, 206, 164), Enum.Material.Sand)
	World.part(model, "GardenPath", Vector3.new(6, 0.12, 43), origin + Vector3.new(0, 1.1, 0), Color3.fromRGB(223, 206, 164), Enum.Material.Sand)
	World.part(model, "CrossPath", Vector3.new(48, 0.12, 3), origin + Vector3.new(0, 1.1, -11.5), Color3.fromRGB(223, 206, 164), Enum.Material.Sand)
	for index = 1, 4 do
		decoration(model, "SteppingStone", Vector3.new(3.8, 0.18, 2), origin + Vector3.new(0, 1.15, 21 + index * 2.5), Color3.fromRGB(185, 183, 157), Enum.Material.Slate)
	end
	local sign = World.part(model, "FarmSign", Vector3.new(14, 2, 0.5), origin + Vector3.new(0, 5, -30), Color3.fromRGB(31, 70, 57))
	World.label(sign, "MUTANT FARM\n" .. player.DisplayName .. "'s garden", 2, 240, 58)
	for _, x in ipairs({ -34, 34 }) do
		World.part(model, "TreeTrunk", Vector3.new(1.4, 6, 1.4), origin + Vector3.new(x, 4, -25), Color3.fromRGB(121, 88, 61), Enum.Material.Wood)
		decoration(model, "TreeCrown", Vector3.new(7, 7, 7), origin + Vector3.new(x, 8, -25), Color3.fromRGB(60, 127, 80), Enum.Material.Grass, Enum.PartType.Ball)
		for index = 1, 3 do
			decoration(model, "FlowerPatch", Vector3.new(1.2, 0.35, 1.2), origin + Vector3.new(x, 1.3, index * 4), index % 2 == 0 and Color3.fromRGB(255, 202, 107) or Color3.fromRGB(195, 164, 228), nil, Enum.PartType.Ball)
		end
	end
	decoration(model, "HayBale", Vector3.new(4, 2.5, 3), origin + Vector3.new(-25, 2.25, -25), Color3.fromRGB(217, 180, 91), Enum.Material.Grass)
	decoration(model, "WaterBarrel", Vector3.new(3, 3, 3), origin + Vector3.new(25, 2.5, -25), Color3.fromRGB(90, 126, 138), Enum.Material.WoodPlanks)
	local shop = kiosk(model, origin + Vector3.new(-21, 1, 17), "SeedShop", Color3.fromRGB(49, 136, 94), "1  SEED SHOP\nBrowse • Buy • Unlock")
	local sell = kiosk(model, origin + Vector3.new(21, 1, 17), "SellStand", Color3.fromRGB(220, 143, 58), "4  SELL HARVEST\nCrops → Coins → Unlocks")
	local gardenSign = decoration(model, "GardenGuide", Vector3.new(0.3, 2, 0.3), origin + Vector3.new(0, 2, 5), cream, Enum.Material.Wood)
	World.label(gardenSign, "2  PLANT  →  3  HARVEST\nClick / tap the soil", 2, 220, 48)
	local upgrade = World.part(model, "FarmUpgrade", Vector3.new(4, 3, 0.5), origin + Vector3.new(25, 3, 3), Color3.fromRGB(62, 109, 133), Enum.Material.Wood)
	World.label(upgrade, "FARM EXPANSION\n6 → 9 → 12 plots", 3, 195, 52)
	local bounds = Instance.new("Folder")
	bounds.Name, bounds.Parent = "Boundaries", model
	local world = { model = model, origin = origin, plots = {}, shop = shop, sell = sell, upgrade = upgrade,
		bounds = bounds, spawn = CFrame.new(origin + Vector3.new(0, 5, 23)) }
	World.expand(world, plotCount or config.PlotCount, player.UserId)
	return world
end

function World.expand(world, plotCount, ownerId)
	local model, origin = world.model, world.origin
	local extension = (math.ceil(plotCount / 3) - 2) * 13
	local back = -31 - extension
	model.Meadow.Size = Vector3.new(76, 2, 76 + extension)
	model.Meadow.Position = origin + Vector3.new(0, 0, -extension / 2)
	model.GardenPath.Size = Vector3.new(6, 0.12, 43 + extension)
	model.GardenPath.Position = origin + Vector3.new(0, 1.1, -extension / 2)
	model.FarmSign.Position = origin + Vector3.new(0, 5, back + 1)
	for index = #world.plots + 1, plotCount do
		local position = origin + Vector3.new(((index - 1) % 3 - 1) * 13, 1.3, -5 - math.floor((index - 1) / 3) * 13)
		World.part(model, "PlotBorder", Vector3.new(11, 0.5, 10), position, Color3.fromRGB(148, 126, 91), Enum.Material.Slate)
		local soil = World.part(model, "Soil_" .. index, Vector3.new(10, 0.6, 9), position + Vector3.new(0, 0.1, 0), Color3.fromRGB(83, 53, 40), Enum.Material.Ground)
		soil:SetAttribute("OwnerUserId", ownerId)
		for row = -3, 3, 2 do decoration(model, "SoilFurrow", Vector3.new(9, 0.08, 0.14), soil.Position + Vector3.new(0, 0.32, row), Color3.fromRGB(103, 70, 45), Enum.Material.Ground) end
		local label = World.label(soil, "PLANT • Click / tap", 1.3)
		local crop = Instance.new("Model")
		crop.Name, crop.Parent = "Crop", model
		world.plots[index] = { soil = soil, label = label, crop = crop }
		if index > 6 and index % 3 == 1 then
			World.part(model, "ExpansionPath", Vector3.new(48, 0.12, 3), origin + Vector3.new(0, 1.1, position.Z - origin.Z + 6.5), Color3.fromRGB(223, 206, 164), Enum.Material.Sand)
		end
	end
	require(script.Parent.FarmDesign).render(world, plotCount)
end
function World.render(view, plot, config)
	require(script.Parent.CropVisuals).render(view, plot, config, World, os.clock())
end

function World.countdown(view, plot, config, now)
	local crop = config.Crops[plot.cropId]
	if not crop or plot.stage == 0 or plot.stage == #crop.GrowthStages then return end
	if view.visualPhase == "SEED" and now - plot.plantedAt >= crop.SeedSeconds then World.render(view, plot, config) end
	local experiment = config.Research.Catalog[plot.experiment]
	local duration = crop.GrowSeconds * (experiment and config.Research.Traits[experiment.Trait].Grow or 1)
	local seconds = math.max(0, math.ceil(duration - (now - plot.plantedAt)))
	local text = (experiment and experiment.Name .. " • " .. experiment.Trait or plot.cropId) .. " • " .. (view.visualPhase or "GROWING") .. "\n" .. seconds .. "s"
	if view.label.Text ~= text then view.label.Text = text end
end

return World
