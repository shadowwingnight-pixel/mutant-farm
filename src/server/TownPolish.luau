-- Additive scenery for the existing M6A footprint. No gameplay, remotes or update loops.
local Polish = {}
local V = Vector3.new
local C = Color3.fromRGB
local cream, timber, leaf = C(246, 226, 187), C(119, 81, 57), C(75, 143, 91)

local function folder(parent, name)
	local item = Instance.new("Folder")
	item.Name, item.Parent = name, parent
	return item
end

local function builder(world, parent)
	return function(name, size, position, tint, material, shape, solid)
		local item = world.part(parent, name, size, position, tint, material)
		item.CanCollide, item.CanQuery, item.CastShadow = solid == true, solid == true, solid == true
		if shape then item.Shape = shape end
		return item
	end
end

local function planter(make, x, z, length, tint)
	make("PlanterBox", V(length, 0.7, 2), V(x, 5.35, z), timber, Enum.Material.WoodPlanks)
	make("Planting", V(length - 0.3, 1.1, 1.8), V(x, 6, z), leaf, Enum.Material.Grass, Enum.PartType.Ball)
	for _, dx in ipairs({ -length / 3, length / 3 }) do
		make("FlowerCluster", V(1.1, 0.45, 1.1), V(x + dx, 6.5, z), tint, nil, Enum.PartType.Ball)
	end
end

local function glow(town, bulb, useLight)
	local light
	if useLight then
		light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness, light.Shadows, light.Enabled = bulb.Color, 12, 0.75, false, false
		light.Parent = bulb
	end
	table.insert(town.lamps, { bulb = bulb, light = light })
end

local function house(town, parent, x, z, tint, roofTint, label, yaw)
	local model = Instance.new("Model")
	model.Name, model.Parent = label, parent
	local create = builder(town.world, model)
	local frame = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw or 0, 0)
	local function make(name, size, offset, color, material, solid)
		local part = create(name, size, V(0, 0, 0), color, material, nil, solid)
		part.CFrame = frame * CFrame.new(offset)
		return part
	end
	make("ClosedBuilding", V(15, 8, 12), V(0, 9, 0), tint, Enum.Material.SmoothPlastic, true)
	make("FoundationTrim", V(15.4, 0.7, 12.4), V(0, 5.4, 0), cream)
	for _, side in ipairs({ -1, 1 }) do
		local roof = make("SlopingRoof", V(8.9, 0.55, 14), V(side * 4, 14, 0), roofTint)
		roof.CFrame *= CFrame.Angles(0, 0, -side * math.rad(24))
		make("CornerBeam", V(0.45, 8, 0.35), V(side * 7.2, 9, -6.15), timber, Enum.Material.Wood)
		local window = make("WarmWindow", V(2.6, 2.8, 0.2), V(side * 4.6, 10, -6.15), C(246, 197, 114))
		glow(town, window, false) -- Emissive windows, no extra dynamic lights.
		make("WindowSill", V(3.4, 0.25, 0.6), V(side * 4.6, 8.5, -6.4), cream)
		for _, dx in ipairs({ -1.65, 1.65 }) do make("Shutter", V(0.55, 3, 0.3), V(side * 4.6 + dx, 10, -6.3), roofTint, Enum.Material.WoodPlanks) end
	end
	make("Ridge", V(0.6, 0.6, 14.2), V(0, 15.9, 0), cream)
	make("ClosedDoor", V(3, 5.8, 0.25), V(0, 7.9, -6.2), timber, Enum.Material.WoodPlanks)
	make("DoorLintel", V(4, 0.4, 0.6), V(0, 11, -6.4), cream)
	make("Chimney", V(1.8, 4, 1.8), V(4, 15.5, 2), C(163, 128, 112), Enum.Material.Brick)
	local plaque = make("SceneryPlaque", V(4, 0.7, 0.2), V(0, 11.8, -6.3), roofTint)
	town.world.label(plaque, label .. "\nDecorative exterior • Closed", 0, 160, 36)
end

function Polish.build(town)
	local root = folder(town.model, "VisualPolish")
	local architecture = builder(town.world, folder(root, "ArchitectureDetails"))
	local street = builder(town.world, folder(root, "StreetsAndSquare"))
	local plants = builder(town.world, folder(root, "PlantingAndBanks"))
	local distant = builder(town.world, folder(root, "DistantScenery"))
	local houses = folder(root, "ClosedTownBuildings")
	house(town, houses, -167, 63, C(231, 190, 132), C(127, 87, 91), "GARDEN HOUSE")
	house(town, houses, -75, 64, C(226, 196, 161), C(71, 133, 133), "OLD BAKERY")
	house(town, houses, -78, -53, C(183, 112, 83), C(98, 104, 119), "SEED BARN", math.pi)
	-- Facade and roof details stay clear of the existing transaction counters.
	for _, x in ipairs({ -165, -141 }) do
		architecture("StoreFrontBeam", V(0.6, 8, 0.6), V(x, 9, 28), timber, Enum.Material.Wood)
		architecture("StoreEave", V(0.5, 0.7, 19), V(x, 13, 20), cream)
	end
	architecture("StoreFascia", V(25, 0.8, 0.45), V(-153, 12.9, 29.3), cream)
	architecture("StoreAwning", V(23, 0.35, 4), V(-153, 11.7, 30), C(120, 170, 105))
	architecture("StoreChimney", V(2, 4, 2), V(-160, 16, 17), C(173, 128, 97), Enum.Material.Brick)
	for _, x in ipairs({ -162, -144 }) do planter(plants, x, 32.5, 3, C(249, 201, 113)) end
	for _, x in ipairs({ -75, -55 }) do
		architecture("MarketFrontBeam", V(0.5, 7, 0.5), V(x, 8.5, 20.8), timber, Enum.Material.Wood)
		architecture("MarketCanopyFringe", V(1.8, 1, 0.3), V(x, 12.4, 21), C(231, 155, 64))
	end
	architecture("MarketBackSign", V(16, 1.5, 0.4), V(-65, 11, 7), cream)
	for _, p in ipairs({ V(-77, 5.8, 15), V(-52, 5.8, 16) }) do architecture("StackedCrate", V(2.8, 1.6, 2.6), p, timber, Enum.Material.WoodPlanks) end
	-- The lab gains a compact roof lantern and framing, not a new accessible wing.
	architecture("LabRoofLantern", V(7, 3, 6), V(-110, 21, -36), C(113, 180, 183))
	architecture("LabLanternBase", V(8, 0.7, 7), V(-110, 19.2, -36), cream)
	architecture("LabLanternCap", V(8, 0.5, 7), V(-110, 22.8, -36), C(65, 88, 120))
	for _, x in ipairs({ -123, -97 }) do architecture("LabVerticalTrim", V(0.6, 11, 0.4), V(x, 10.5, -25.6), cream) end
	architecture("LabLintel", V(29, 0.6, 0.45), V(-110, 15.8, -25.5), cream)
	for _, x in ipairs({ -119, -101 }) do
		architecture("WindowMullion", V(0.18, 4, 0.4), V(x, 11, -25.4), cream)
		architecture("SpecimenBase", V(3, 0.5, 3), V(x, 5.3, -22), C(61, 90, 98))
	end
	for _, p in ipairs({ V(-141, 10, 29), V(-65, 11, 21.3), V(-110, 12.5, -25.4) }) do
		local bulb = architecture("ExteriorLantern", V(0.8, 1.2, 0.8), p, cream)
		glow(town, bulb, true)
	end
	-- Short pedestrian lane connects the new facades without closing square exits.
	street("GardenStreet", V(117, 0.12, 3), V(-111.5, 5.15, 53), C(205, 189, 159), Enum.Material.Cobblestone)
	for _, x in ipairs({ -167, -75 }) do street("DoorWalk", V(4, 0.12, 5), V(x, 5.15, 55.5), cream, Enum.Material.Slate) end
	for _, spec in ipairs({ { -148, 29 }, { -64, 49 } }) do
		for _, z in ipairs({ 38, 50 }) do street("RoadEdge", V(spec[2], 0.18, 0.4), V(spec[1], 5.22, z), cream) end
	end
	for _, x in ipairs({ -116, -104 }) do street("ResearchPathEdge", V(0.3, 0.15, 33), V(x, 5.22, 2), cream) end
	for _, z in ipairs({ 68, 73, 100, 105 }) do street("BridgeApproachStone", V(6.5, 0.12, 2), V(-110, 5.22, z), C(182, 181, 157), Enum.Material.Slate) end
	for _, z in ipairs({ 28, 60 }) do
		for _, x in ipairs({ -124, -96 }) do planter(plants, x, z, 5, z == 28 and C(244, 170, 121) or C(186, 158, 219)) end
	end
	local board = architecture("TownNoticeBoard", V(5, 3.5, 0.4), V(-137, 8, 59), timber, Enum.Material.Wood)
	town.world.label(board, "TOWN NOTICEBOARD\nGrow • Explore • Discover", 0, 185, 44)
	architecture("NoticeBoardRoof", V(6, 0.4, 2), V(-137, 10, 59), C(72, 122, 97))
	for _, x in ipairs({ -139, -135 }) do architecture("NoticePost", V(0.35, 3, 0.35), V(x, 6.5, 59), timber) end
	-- Decorated bridge rails and bank planting leave the full deck and shallow exits clear.
	for z = 79, 95, 2 do street("DeckSeam", V(12.5, 0.025, 0.08), V(-110, 5.34, z), C(91, 64, 48)) end
	for _, x in ipairs({ -117, -103 }) do
		for _, z in ipairs({ 82.5, 91.5 }) do
			local brace = street("BridgeBrace", V(0.22, 0.25, 9.2), V(x, 6.7, z), cream, Enum.Material.Wood)
			brace.CFrame *= CFrame.Angles(math.rad(12), 0, 0)
		end
	end
	for _, spec in ipairs({ { -162, 77 }, { -143, 96 }, { -82, 77 }, { -60, 98 } }) do
		local x, z = spec[1], spec[2]
		plants("BankRock", V(4, 1.6, 3), V(x, 5.4, z), C(144, 158, 150), Enum.Material.Slate, Enum.PartType.Ball)
		for _, dx in ipairs({ -3, 3 }) do plants("ReedClump", V(0.6, 2.2, 0.6), V(x + dx, 6, z), C(133, 159, 89)) end
	end
	for _, spec in ipairs({ { -172, 35 }, { -137, 19 }, { -88, -5 }, { -164, -17 }, { -140, -23 }, { -62, -9 } }) do
		plants("Shrub", V(4, 2.2, 3), V(spec[1], 5.8, spec[2]), C(91, 154, 103), Enum.Material.Grass, Enum.PartType.Ball)
	end
	-- Horizon-only geometry: no new playable terrain, districts, collisions or physics.
	for index, p in ipairs({ V(-203, 5, -47), V(-202, 3, 16), V(-204, 4, 76), V(-167, 3, -88), V(-113, 5, -91), V(-63, 3, -85), V(-158, 2, 142), V(-77, 3, 146) }) do
		distant("BackdropHill", V(48, 24 + index % 3 * 5, 45), p, index % 2 == 0 and C(110, 151, 129) or C(102, 139, 124), Enum.Material.Grass, Enum.PartType.Ball)
	end
	for _, p in ipairs({ V(-191, 5, -23), V(-191, 5, 43), V(-162, 5, -73), V(-143, 5, -77), V(-155, 5, 125), V(-77, 5, 127) }) do
		distant("SilhouetteTrunk", V(1, 6, 1), p, timber)
		distant("SilhouetteCrown", V(7, 10, 7), p + V(0, 5, 0), C(73, 122, 100), Enum.Material.Grass, Enum.PartType.Ball)
	end
	root:SetAttribute("AddedPointLights", 3)
	local count = 0
	for _, item in ipairs(root:GetDescendants()) do if item:IsA("BasePart") then count += 1 end end
	root:SetAttribute("AddedParts", count)
end

function Polish.farm(town, farm)
	local make = builder(town.world, folder(farm.model, "EntranceScenery"))
	local origin = farm.origin
	-- All additions sit at the front edge, away from soil and northward expansions.
	for _, side in ipairs({ -1, 1 }) do
		make("EntryHedge", V(5, 1.5, 2), origin + V(side * 11, 1.7, 33), leaf, Enum.Material.Grass, Enum.PartType.Ball)
		make("GateFlowers", V(2, 0.6, 1.8), origin + V(side * 8, 1.6, 36), C(245, 203, 119), nil, Enum.PartType.Ball)
		make("EntryPathEdge", V(0.25, 0.12, 9), origin + V(side * 4.7, 1.2, 37), cream)
	end
	make("StackedHay", V(3, 1.7, 2), origin + V(-17, 1.8, 33), C(212, 176, 92), Enum.Material.Grass)
	local barrel = make("EntryBarrel", V(2, 2.5, 2.5), origin + V(17, 2, 33), timber, Enum.Material.WoodPlanks, Enum.PartType.Cylinder)
	barrel.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
end

return Polish
