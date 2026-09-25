-- Additive scenery for the existing M6A footprint. No gameplay, remotes or update loops.
local Polish = {}
local F = require(script.Parent.SiteForms)
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
		make("CornerBeam", V(0.45, 8, 0.35), V(side * 7.2, 9, -6.15), timber, Enum.Material.Wood)
		local window = make("WarmWindow", V(2.6, 2.8, 0.2), V(side * 4.6, 10, -6.15), C(246, 197, 114))
		glow(town, window, false) -- Emissive windows, no extra dynamic lights.
		make("WindowSill", V(3.4, 0.25, 0.6), V(side * 4.6, 8.5, -6.4), cream)
		for _, dx in ipairs({ -1.65, 1.65 }) do make("Shutter", V(0.55, 3, 0.3), V(side * 4.6 + dx, 10, -6.3), roofTint, Enum.Material.WoodPlanks) end
	end
	F.roof(model, V(x,13,z), 17.5, 14, 3, roofTint)
	make("ClosedDoor", V(3, 5.8, 0.25), V(0, 7.9, -6.2), timber, Enum.Material.WoodPlanks)
	make("DoorLintel", V(4, 0.4, 0.6), V(0, 11, -6.4), cream)
	make("Chimney", V(1.8, 4, 1.8), V(4, 15.5, 2), C(163, 128, 112), Enum.Material.Brick)
	local plaque = F.sign(model,"SceneryPlaque",label,V(4,0.7,0.2),V(0,0,0),roofTint)
	plaque.CFrame = frame * CFrame.new(0,11.8,-6.3) * CFrame.Angles(0,math.pi,0)
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
	root:SetAttribute("AddedPointLights", 0)
	local count = 0
	for _, item in ipairs(root:GetDescendants()) do if item:IsA("BasePart") then count += 1 end end
	root:SetAttribute("AddedParts", count)
end

function Polish.farm(town, farm)
	local make = builder(town.world, folder(farm.model, "EntranceScenery"))
	local origin = farm.origin
	F.roof(farm.model, origin + V(0,8.8,32), 15.5,3.5,2.5,C(158,99,65))
	for _, x in ipairs({-5.7,5.7}) do make("GateStoneFoot",V(1.5,2,1.5),origin+V(x,1.8,32),C(169,160,130),Enum.Material.Cobblestone) end
	for _, x in ipairs({-5.7,5.7}) do make("GateGlow",V(0.45,0.7,0.45),origin+V(x,6.3,32.6),cream,Enum.Material.Neon) end
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
