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
	local ground, square, nature = group("GroundAndPaths"), group("TownSquare"), group("Nature")
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
	-- Walk surfaces match existing farm grass (Y=5), with no edits to Studio terrain/baseplate.
	make(ground, "TownMeadow", V(136, 2, 136), V(-112, 4, 4), Color3.fromRGB(101, 176, 115), Enum.Material.Grass)
	make(ground, "SouthBank", V(136, 2, 16), V(-112, 4, 110), Color3.fromRGB(101, 176, 115), Enum.Material.Grass)
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
	require(script.Parent.TownArchitecture).build(self)
	require(script.Parent.Waterfront).build(self)
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
	require(script.Parent.TownPolish).build(self)
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
			ground = world.part(self.routes, "DistrictGrass", V(1, 2, 120), V(0, 3.8, origin.Z - 4), Color3.fromRGB(89, 162, 104), Enum.Material.Grass),
			land = world.part(self.routes, "FarmLane", V(1, 2, 12), V(0, 4, origin.Z + 44), Color3.fromRGB(101, 176, 115), Enum.Material.Grass),
			path = world.part(self.routes, "FarmLanePath", V(1, 0.16, 9), V(0, 5.1, origin.Z + 44), pathColor, Enum.Material.Sand), maxX = -44,
		}
	end
	local lane = self.rows[row]
	lane.maxX = math.max(lane.maxX, origin.X + 8)
	-- A shallow grass foundation closes gaps between occupied farm lots/rows.
	-- It stays below original farm surfaces and leaves all plot coordinates intact.
	lane.ground.Size, lane.ground.Position = V(lane.maxX + 80, 2, 120), V((lane.maxX - 20) / 2, 3.8, origin.Z - 4)
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
	require(script.Parent.TownPolish).farm(self, farm)
end

function Town:updateLighting(phase)
	if self.phase == phase then return end
	self.phase = phase
	local lit = phase ~= "Day"
	for _, entry in ipairs(self.lamps) do
		if entry.light then entry.light.Enabled = lit end
		entry.bulb.Material = lit and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end
end

return Town
