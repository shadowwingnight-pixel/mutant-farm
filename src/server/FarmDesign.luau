local F = require(script.Parent.SiteForms)
local V,C = Vector3.new,Color3.fromRGB
local Design = {}
function Design.render(world, count)
	local origin, bounds = world.origin, world.bounds
	local extension = (math.ceil(count/3)-2)*13
	local back = -31-extension
	local function p(parent,name,size,position,tint,material,solid,shape)
		return F.part(parent,name,size,origin+position,tint,material,solid,shape)
	end
	-- Rebuild only the generated boundary: crop models and soil hit targets are untouched.
	bounds:ClearAllChildren()
	for _, x in ipairs({-31,31}) do
		for _, y in ipairs({2,3.1}) do p(bounds,"TimberRail",V(0.35,0.35,62+extension),V(x,y,-extension/2),F.Wood,Enum.Material.Wood,true) end
		for z=back,31,12 do
			p(bounds,"StonePier",V(1,3.3,1),V(x,2.45,z),C(174,166,135),Enum.Material.Cobblestone,true)
		end
		p(bounds,"BoundaryPlanting",V(3,1.7,39+extension),V(x+(x<0 and -2 or 2),1.4,-8-extension/2),C(90,148,94),Enum.Material.Grass,false,Enum.PartType.Ball)
	end
	for _, x in ipairs({-18,18}) do
		for _, z in ipairs({back,31}) do
			for _, y in ipairs({2,3.1}) do p(bounds,"CrossRail",V(26,0.35,0.35),V(x,y,z),F.Wood,Enum.Material.Wood,true) end
			for _, dx in ipairs({-13,0,13}) do p(bounds,"GatePier",V(0.9,3.3,0.9),V(x+dx,2.45,z),C(174,166,135),Enum.Material.Cobblestone,true) end
		end
		p(bounds,"RearHedge",V(25,2,3),V(x,1.5,back-2),C(95,151,98),Enum.Material.Grass,false,Enum.PartType.Ball)
	end
	for _, x in ipairs({-6.5,6.5}) do
		p(bounds,"GardenWalk",V(2.5,0.12,34+extension),V(x,1.17,-10-extension/2),C(181,163,122),Enum.Material.Ground)
	end
	-- Gate remains fixed, while the rear garden room, paths and green boundary move with tiers.
	world.model.GardenPath.Transparency = 1
	world.model.GardenPath.CanCollide = false
	world.model.Meadow.Color = C(106,163,108)
	for _, plot in ipairs(world.plots) do plot.soil.Color = C(86,57,39) end
	if world.design then return end
	world.design = F.group(world.model,"FarmUtilityGarden")
	local d=world.design
	p(d,"ToolShed",V(8,6.5,9),V(-25,4.25,-5),C(177,137,92),Enum.Material.WoodPlanks,true)
	F.roof(d,origin+V(-25,7.5,-5),10,11,2.8,C(144,88,62))
	p(d,"ShedDoor",V(3,5,0.25),V(-25,3.5,-0.35),F.Wood,Enum.Material.Wood,true)
	p(d,"ShedWindow",V(2,1.5,0.2),V(-27,5,-0.3),C(177,194,150),Enum.Material.Glass)
	F.beam(d,"RakeHandle",origin+V(-28,1,0.5),origin+V(-27.5,4.5,0.5),0.12,F.Wood)
	p(d,"RakeHead",V(1.4,0.2,0.3),V(-27.5,4.5,0.5),C(93,110,104),Enum.Material.Metal)
	p(d,"WaterTrough",V(3.2,1,8),V(25,1.5,-12),C(163,162,137),Enum.Material.Slate)
	p(d,"TroughWater",V(2.6,0.1,7.3),V(25,2.03,-12),C(82,151,152),Enum.Material.Glass)
	p(d,"IrrigationRun",V(0.25,0.25,18),V(23,1.3,-16),C(107,127,112),Enum.Material.Metal)
	p(d,"BarrelFeed",V(2.2,0.25,0.25),V(24,1.3,-25),C(107,127,112),Enum.Material.Metal)
	p(d,"Sack",V(2,2,1.8),V(-23,2,1.5),C(210,189,143),Enum.Material.Fabric,false,Enum.PartType.Ball)
	p(d,"HarvestCrate",V(3,1.4,2.3),V(-27,1.7,2),F.Wood,Enum.Material.WoodPlanks)
end
return Design
