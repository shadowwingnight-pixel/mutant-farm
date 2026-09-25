-- One shared town west of the validated farm grid. Static, original primitive geometry.
local Town = {}
Town.__index = Town
local V = Vector3.new
local cream = Color3.fromRGB(247, 228, 187)
local wood = Color3.fromRGB(132, 92, 65)
local pathColor = Color3.fromRGB(224, 201, 161)

function Town.new(world)
	local model = Instance.new("Model")
	model.Name, model.Parent = "MutantFarmTown", workspace
	local self = setmetatable({ model = model, world = world, lamps = {}, rows = {} }, Town)
	local function group(name)
		local folder = Instance.new("Folder")
		folder.Name, folder.Parent = name, model
		return folder
	end
	local ground, square, shops, lab, river, nature = group("GroundAndPaths"), group("TownSquare"), group("ShopArchitecture"), group("ResearchLab"), group("RiverAndBridge"), group("Nature")
	self.routes = group("FarmDistrictRoads")
	local function make(parent, name, size, position, tint, material, decorative)
		local item = world.part(parent, name, size, position, tint, material)
		if decorative then item.CanCollide, item.CanQuery, item.CastShadow = false, false, false end
		return item
	end
	local function road(parent, name, x, z, width, depth)
		return make(parent, name, V(width, 0.16, depth), V(x, 5.1, z), pathColor, Enum.Material.Sand)
	end
	local function sign(parent, text, x, z, width)
		make(parent, "SignPost", V(0.35, 3.6, 0.35), V(x, 6.8, z), wood, Enum.Material.Wood)
		local board = make(parent, "Wayfinding", V(width or 8, 2.5, 0.3), V(x, 8.5, z), Color3.fromRGB(41, 83, 67), nil, true)
		world.label(board, text, 0, 210, 52)
	end
	local function tree(x, z, scale)
		scale = scale or 1
		make(nature, "Trunk", V(1.3, 6 * scale, 1.3), V(x, 5 + 3 * scale, z), wood, Enum.Material.Wood)
		local crown = make(nature, "Canopy", V(7, 8, 7) * scale, V(x, 5 + 7 * scale, z), Color3.fromRGB(67, 142, 91), Enum.Material.Grass, true)
		crown.Shape = Enum.PartType.Ball
	end
	local function lamp(x, z)
		make(square, "LampPost", V(0.4, 8, 0.4), V(x, 9, z), Color3.fromRGB(49, 72, 70), Enum.Material.Metal)
		local bulb = make(square, "Lantern", V(1.4, 1.7, 1.4), V(x, 13, z), cream, nil, true)
		make(square, "LanternCap", V(2, 0.3, 2), V(x, 14, z), Color3.fromRGB(49, 72, 70), nil, true)
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness, light.Shadows, light.Enabled = cream, 17, 1.1, false, false
		light.Parent = bulb
		table.insert(self.lamps, { light = light, bulb = bulb })
	end
	local function roof(parent, x, z, width, depth, height, tint)
		-- Two sloping panels, a ridge and deep eaves give modest buildings a distinct silhouette.
		for _, side in ipairs({ -1, 1 }) do
			local panel = make(parent, "PitchedRoof", V(width / 2 + 1.5, 0.6, depth + 2), V(x + side * width / 4, height, z), tint)
			panel.CFrame *= CFrame.Angles(0, 0, -side * math.rad(20))
		end
		make(parent, "RoofRidge", V(0.7, 0.7, depth + 2.3), V(x, height + width / 4 * math.tan(math.rad(20)), z), cream, nil, true)
	end
	-- Walk surfaces match existing farm grass (Y=5), with no edits to Studio terrain/baseplate.
	make(ground, "TownMeadow", V(136, 2, 144), V(-112, 4, 8), Color3.fromRGB(101, 176, 115), Enum.Material.Grass)
	make(ground, "SouthBank", V(136, 2, 24), V(-112, 4, 106), Color3.fromRGB(101, 176, 115), Enum.Material.Grass)
	road(ground, "FarmToSquare", -100, 44, 124, 12)
	road(ground, "ResearchWalk", -110, 4, 12, 80)
	road(ground, "SeedWalk", -153, 36, 12, 28)
	road(ground, "MarketWalk", -65, 34, 12, 28)
	road(ground, "RiverWalk", -110, 65, 12, 30)
	road(ground, "SouthWalk", -110, 105, 12, 24)
	local plaza = make(square, "RoundPlaza", V(0.3, 43, 43), V(-110, 5.17, 44), Color3.fromRGB(201, 190, 163), Enum.Material.Cobblestone)
	plaza.Shape = Enum.PartType.Cylinder
	plaza.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	local planter = make(square, "CentralPlanter", V(1.6, 10, 10), V(-110, 5.9, 44), cream, Enum.Material.Slate)
	planter.Shape = Enum.PartType.Cylinder
	planter.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	local seed = make(square, "SeedSculpture", V(3, 5, 3), V(-110, 9, 44), Color3.fromRGB(245, 186, 78), Enum.Material.SmoothPlastic, true)
	seed.Shape = Enum.PartType.Ball
	seed.CFrame *= CFrame.Angles(0, 0, math.rad(-18))
	for _, side in ipairs({ -1, 1 }) do
		local leaf = make(square, "SculptureLeaf", V(4, 0.6, 2), V(-110 + side * 2, 8, 44), Color3.fromRGB(67, 143, 83), nil, true)
		leaf.Shape = Enum.PartType.Ball
		leaf.CFrame *= CFrame.Angles(0, 0, side * math.rad(25))
		local x = -110 + side * 15
		make(square, "BenchSeat", V(7, 0.5, 2), V(x, 6.5, 56), wood, Enum.Material.WoodPlanks)
		make(square, "BenchBack", V(7, 2, 0.4), V(x, 7.5, 57), wood, Enum.Material.WoodPlanks)
		for _, dx in ipairs({ -2.5, 2.5 }) do make(square, "BenchLeg", V(0.4, 1.5, 1.6), V(x + dx, 5.75, 56), cream) end
	end
	sign(square, "MUTANT FARM TOWN\nSeed Square", -126, 61, 10)
	sign(square, "← SEEDS   •   MARKET →\n↑ RESEARCH   •   FARMS →", -92, 57, 10)
	-- Open-front service counters reuse the existing authoritative gameplay endpoints.
	make(shops, "SeedStoreBack", V(24, 9, 1), V(-153, 9.5, 13), cream, Enum.Material.WoodPlanks)
	for _, x in ipairs({ -165, -141 }) do make(shops, "SeedStoreSide", V(0.7, 9, 15), V(x, 9.5, 20), Color3.fromRGB(119, 170, 115), Enum.Material.WoodPlanks) end
	roof(shops, -153, 20, 26, 18, 14, Color3.fromRGB(58, 119, 91))
	self.shop = make(model, "SeedShop", V(19, 2.5, 3), V(-153, 6.25, 28), wood, Enum.Material.WoodPlanks)
	make(shops, "SeedCounterTop", V(20, 0.25, 3.5), V(-153, 7.65, 28), cream)
	world.label(self.shop, "SEEDS / FARM SUPPLIES\nE / tap • Browse seeds", 8, 225, 55)
	for index = 1, 3 do
		local x = -161 + index * 4
		make(shops, "SupplyBin", V(2.8, 1, 2), V(x, 5.5, 17), wood, Enum.Material.Wood)
		local sprout = make(shops, "DisplaySprout", V(1.5, 2, 1.5), V(x, 7, 17), Color3.fromRGB(100, 183, 94), nil, true)
		sprout.Shape = Enum.PartType.Ball
	end
	self.sell = make(model, "SellStand", V(18, 2.5, 4), V(-65, 6.25, 19), wood, Enum.Material.WoodPlanks)
	world.label(self.sell, "PRODUCE MARKET\nE / tap • Sell your harvest", 8, 225, 55)
	for _, x in ipairs({ -75, -55 }) do make(shops, "MarketPost", V(0.6, 8, 0.6), V(x, 9, 13), cream, Enum.Material.Wood) end
	for index = 0, 6 do make(shops, "MarketCanopy", V(3.2, 0.6, 14), V(-74.6 + index * 3.2, 13, 14), index % 2 == 0 and Color3.fromRGB(231, 155, 64) or cream) end
	for index = 1, 3 do
		local x = -77 + index * 6
		make(shops, "ProduceCrate", V(4, 0.6, 3), V(x, 7.8, 19), Color3.fromRGB(168, 122, 68), Enum.Material.WoodPlanks)
		local produce = make(shops, "ProduceDisplay", V(1.5, 1.5, 1.5), V(x, 8.5, 19), index == 3 and Color3.fromRGB(240, 153, 48) or Color3.fromRGB(230, 81, 84), nil, true)
		produce.Shape = Enum.PartType.Ball
	end
	-- Closed greenhouse/lab: a future landmark only, no economy or mutation mechanics.
	make(lab, "LabBody", V(28, 11, 20), V(-110, 10.5, -36), Color3.fromRGB(157, 191, 184), Enum.Material.SmoothPlastic)
	roof(lab, -110, -36, 30, 22, 17, Color3.fromRGB(77, 105, 133))
	local door = make(lab, "ClosedDoor", V(5, 7, 0.25), V(-110, 8.5, -25.8), Color3.fromRGB(51, 82, 95))
	world.label(door, "MUTATION RESEARCH\nResearch wing • Coming later", 9, 230, 55)
	for _, x in ipairs({ -119, -101 }) do
		make(lab, "LabWindow", V(5, 4, 0.3), V(x, 11, -25.7), Color3.fromRGB(124, 228, 222), Enum.Material.Glass, true)
		local pod = make(lab, "SpecimenPod", V(2.4, 4, 2.4), V(x, 7, -22), Color3.fromRGB(171, 132, 237), Enum.Material.Neon)
		pod.Shape = Enum.PartType.Cylinder
		pod.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	end
	-- Shallow, walk-out river: solid bed one stud below land; no deep-water trap.
	make(river, "ShallowRiverBed", V(136, 2, 14), V(-112, 3, 87), Color3.fromRGB(128, 161, 151), Enum.Material.Sand)
	local water = make(river, "RiverSurface", V(136, 0.12, 14), V(-112, 4.3, 87), Color3.fromRGB(66, 164, 188), Enum.Material.Glass, true)
	water.Transparency = 0.3
	for _, x in ipairs({ -167, -143, -78, -52 }) do make(river, "WaterRipple", V(8, 0.04, 0.15), V(x, 4.4, 87), Color3.fromRGB(175, 224, 225), nil, true) end
	make(river, "BridgeDeck", V(13, 0.45, 19), V(-110, 5.1, 87), wood, Enum.Material.WoodPlanks)
	for _, x in ipairs({ -117, -103 }) do
		make(river, "BridgeRail", V(0.4, 0.5, 19), V(x, 7.8, 87), cream, Enum.Material.Wood)
		for _, z in ipairs({ 78, 87, 96 }) do make(river, "BridgePost", V(0.7, 3, 0.7), V(x, 6.5, z), wood, Enum.Material.Wood) end
	end
	sign(river, "RIVER WALK\nBridge → future district", -124, 72)
	for _, position in ipairs({ { -168, -27 }, { -168, -46 }, { -143, -52 }, { -72, -43 }, { -63, -21 }, { -174, 54 }, { -158, 68 }, { -57, 61 }, { -150, 108 }, { -70, 108 } }) do tree(position[1], position[2], 0.9) end
	road(nature, "ForestTrail", -151, -15, 9, 40)
	road(nature, "GroveLink", -130, -8, 46, 8)
	sign(nature, "GROVE WALK\nFuture forest trail", -161, -7)
	for _, entry in ipairs({ { -110, 112, "FUTURE DISTRICT" }, { -151, -35, "FOREST TRAIL" } }) do
		make(nature, "RoadClosedBarrier", V(12, 2, 0.6), V(entry[1], 6.5, entry[2]), Color3.fromRGB(237, 186, 77), Enum.Material.Wood)
		sign(nature, entry[3] .. "\nROAD CLOSED • Coming later", entry[1], entry[2], 12)
	end
	for _, position in ipairs({ { -132, 44 }, { -88, 44 }, { -133, 7 }, { -87, 7 }, { -124, -16 }, { -96, -16 }, { -120, 76 }, { -100, 98 } }) do lamp(position[1], position[2]) end
	self.spine = make(self.routes, "DistrictSpine", V(12, 2, 12), V(-44, 4, 44), Color3.fromRGB(101, 176, 115), Enum.Material.Grass)
	self.spinePath = road(self.routes, "DistrictSpinePath", -44, 44, 10, 12)
	self.maxRow = 0
	for _, z in ipairs({ 37, 51 }) do make(square, "TownGatePost", V(0.7, 9, 0.7), V(-44, 9.5, z), wood, Enum.Material.Wood) end
	local gate = make(square, "TownWelcome", V(0.8, 1.4, 15), V(-44, 14.5, 44), Color3.fromRGB(41, 83, 67))
	world.label(gate, "MUTANT FARM TOWN\n← Seed Square   •   Farm District →", 2, 250, 52)
	local partCount = 0
	for _, item in ipairs(model:GetDescendants()) do if item:IsA("BasePart") then partCount += 1 end end
	model:SetAttribute("StaticTownParts", partCount)
	return self
end

function Town:connectFarm(farm, player, slot)
	local world, origin = self.world, farm.origin
	local row = math.floor((slot - 1) / 4)
	if not self.rows[row] then
		self.rows[row] = {
			land = world.part(self.routes, "FarmLane", V(1, 2, 12), V(0, 4, origin.Z + 44), Color3.fromRGB(101, 176, 115), Enum.Material.Grass),
			path = world.part(self.routes, "FarmLanePath", V(1, 0.16, 9), V(0, 5.1, origin.Z + 44), pathColor, Enum.Material.Sand), maxX = -44,
		}
	end
	local lane = self.rows[row]
	lane.maxX = math.max(lane.maxX, origin.X + 8)
	lane.land.Size, lane.land.Position = V(lane.maxX + 44, 2, 12), V((lane.maxX - 44) / 2, 4, origin.Z + 44)
	lane.path.Size, lane.path.Position = V(lane.maxX + 44, 0.16, 9), V((lane.maxX - 44) / 2, 5.1, origin.Z + 44)
	self.maxRow = math.max(self.maxRow, row)
	local depth = self.maxRow * 120 + 12
	self.spine.Size, self.spine.Position = V(12, 2, depth), V(-44, 4, 44 + self.maxRow * 60)
	self.spinePath.Size, self.spinePath.Position = V(10, 0.16, depth), V(-44, 5.1, 44 + self.maxRow * 60)
	world.part(farm.model, "TownEntrancePath", V(9, 0.16, 16), origin + V(0, 1.1, 37), pathColor, Enum.Material.Sand)
	world.part(farm.model, "EntranceGround", V(12, 2, 12), origin + V(0, 0, 38), Color3.fromRGB(101, 176, 115), Enum.Material.Grass)
	for _, x in ipairs({ -5.7, 5.7 }) do world.part(farm.model, "EntrancePost", V(0.7, 7, 0.7), origin + V(x, 4.5, 32), wood, Enum.Material.Wood) end
	local arch = world.part(farm.model, "FarmEntrance", V(13, 1.2, 0.7), origin + V(0, 8.2, 32), cream, Enum.Material.Wood)
	world.label(arch, player.DisplayName .. "'s FARM\n← TOWN SQUARE • Seeds • Market", 2, 235, 48)
	farm.spawn = CFrame.lookAt(origin + V(0, 5, 35), origin + V(-35, 5, 44))
end

function Town:updateLighting(phase)
	if self.phase == phase then return end
	self.phase = phase
	local lit = phase ~= "Day"
	for _, entry in ipairs(self.lamps) do
		entry.light.Enabled = lit
		entry.bulb.Material = lit and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end
end

return Town
