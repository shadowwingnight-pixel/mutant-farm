local F = require(script.Parent.SiteForms)
local V, C = Vector3.new, Color3.fromRGB
local Architecture = {}
function Architecture.build(town)
	local root = F.group(town.model, "LandmarkArchitecture")
	local store, market, lab = F.group(root, "PorchSeedStore"), F.group(root, "HarvestPavilion"), F.group(root, "GreenhouseResearch")
	-- Store: deep service porch in front of a closed, windowed general-store volume.
	F.part(store, "StoreBody", V(24,9,13), V(-153,9.5,17.5), C(208,196,157), Enum.Material.WoodPlanks, true)
	F.roof(store, V(-153,13.8,17.5), 27,17,5, C(65,103,85))
	F.part(store, "PorchApron", V(27,0.18,11), V(-153,5.12,28), C(191,166,126), Enum.Material.WoodPlanks, true)
	local porch = F.part(store, "LeanToPorch", V(27,0.45,9), V(-153,12,28.5), C(86,129,103), Enum.Material.Slate)
	porch.CFrame *= CFrame.Angles(math.rad(12),0,0)
	F.beam(store, "PorchLintel", V(-165,10.8,32), V(-141,10.8,32),0.55,F.Wood)
	for _, x in ipairs({ -165,-141 }) do
		F.part(store,"PorchPost",V(0.55,5.7,0.55),V(x,7.9,32),F.Wood,Enum.Material.Wood,true)
		F.beam(store,"Bracket",V(x,9.2,32),V(x+(x==-165 and 2 or -2),10.8,32),0.25,F.Wood)
	end
	for _, x in ipairs({ -160,-146 }) do
		F.part(store,"DisplayWindow",V(6,4.5,0.2),V(x,10,24.1),C(108,163,157),Enum.Material.Glass)
		F.part(store,"WindowSill",V(6.5,0.4,0.8),V(x,7.6,24.4),F.Cream)
		F.part(store,"WindowFrame",V(0.22,4.5,0.35),V(x,10,24.3),F.Cream)
	end
	F.sign(store,"StoreSign","SEED STORE\nFARM SUPPLIES",V(12,2.3,0.4),V(-153,12.1,32.5),C(46,84,66))
	F.part(store,"Chimney",V(2.2,5,2),V(-161,16.5,15),C(160,127,103),Enum.Material.Brick)
	for _, x in ipairs({ -167,-139 }) do
		F.part(store,"SupplyPot",V(2,1.6,2),V(x,5.8,29),C(165,106,74),Enum.Material.SmoothPlastic,false,Enum.PartType.Ball)
		F.part(store,"Broadleaf",V(2.6,2,2.6),V(x,7.3,29),C(84,142,91),Enum.Material.Grass,false,Enum.PartType.Ball)
		F.part(store,"SeedSack",V(1.8,2.1,1.5),V(x,6,26),C(205,184,140),Enum.Material.Fabric,false,Enum.PartType.Ball)
	end
	town.shop = town.world.part(town.model,"SeedShop",V(19,2.5,3),V(-153,6.25,28),F.Wood,Enum.Material.WoodPlanks)
	town.world.label(town.shop,"Browse seeds • E / tap",2.6,180,32)
	F.part(store,"ServiceCounterLip",V(20,0.3,3.3),V(-153,7.65,28),F.Cream)
	-- Market: airy four-post pavilion with a stepped ventilation roof and paired displays.
	F.part(market,"MarketApron",V(28,0.2,23),V(-65,5.12,14),C(190,172,137),Enum.Material.Cobblestone,true)
	F.roof(market,V(-65,12,14),27,20,3.3,C(159,102,70))
	F.part(market,"VentClerestory",V(7,1.4,11),V(-65,15.5,14),F.Wood,Enum.Material.WoodPlanks)
	F.roof(market,V(-65,16,14),9,13,1.4,C(139,86,67))
	for _, x in ipairs({-75,-55}) do
		for _, z in ipairs({6,23}) do F.part(market,"PavilionPost",V(0.65,7,0.65),V(x,8.5,z),F.Wood,Enum.Material.Wood,true) end
		F.beam(market,"RoofTie",V(x,11.7,5),V(x,11.7,24),0.55,F.Cream)
	end
	F.sign(market,"MarketSign","HARVEST MARKET",V(15,1.8,0.4),V(-65,11.2,24),C(120,75,48))
	town.sell = town.world.part(town.model,"SellStand",V(18,2.5,4),V(-65,6.25,19),F.Wood,Enum.Material.WoodPlanks)
	town.world.label(town.sell,"Sell harvest • E / tap",2.8,190,32)
	for index, x in ipairs({-71,-65,-59}) do
		F.part(market,"ProduceTray",V(4.7,0.6,3),V(x,7.75,19),C(168,125,78),Enum.Material.WoodPlanks)
		local tint = index==3 and C(230,151,60) or (index==2 and C(195,67,86) or C(227,91,64))
		F.part(market,"ProduceMound",V(3.5,1.1,2.3),V(x,8.3,19),tint,nil,false,Enum.PartType.Ball)
	end
	for _, x in ipairs({-72,-58}) do
		F.part(market,"PackingTable",V(5,2,3),V(x,6,9),F.Wood,Enum.Material.WoodPlanks,true)
		F.part(market,"HarvestBasket",V(3,1.2,2),V(x,7.6,9),C(198,158,92),Enum.Material.Wood,false,Enum.PartType.Ball)
	end
	-- Research: asymmetric greenhouse and agricultural silo, with restrained teal/cosmic accents.
	F.part(lab,"GreenhousePlinth",V(18,1.4,22),V(-117,5.7,-36),C(133,153,141),Enum.Material.Slate,true)
	F.part(lab,"ClosedGreenhouse",V(16,6,20),V(-117,9,-36),C(122,171,155),Enum.Material.Glass,true)
	F.roof(lab,V(-117,12,-36),19,23,4,C(135,188,177),Enum.Material.Glass)
	for _, x in ipairs({-124,-117,-110}) do
		F.part(lab,"GreenhouseFrame",V(0.3,6.5,0.4),V(x,9.2,-25.7),F.Cream)
	end
	local silo=F.part(lab,"ResearchSilo",V(14,10,10),V(-102,12,-36),C(173,181,158),Enum.Material.Metal,true,Enum.PartType.Cylinder)
	silo.CFrame *= CFrame.Angles(0,0,math.pi/2)
	local cap=F.part(lab,"SiloCap",V(1.2,11,11),V(-102,19.3,-36),C(80,113,117),Enum.Material.Metal,false,Enum.PartType.Cylinder)
	cap.CFrame *= CFrame.Angles(0,0,math.pi/2)
	F.part(lab,"SiloObservation",V(5,1.1,0.25),V(-102,15,-30.9),C(145,197,186),Enum.Material.Neon)
	F.beam(lab,"TransferPipe",V(-102,16,-30),V(-102,13,-29),0.6,C(108,129,123)).Material = Enum.Material.Metal
	F.beam(lab,"TransferPipe",V(-102,13,-29),V(-109,13,-29),0.6,C(108,129,123)).Material = Enum.Material.Metal
	F.part(lab,"ClosedDoor",V(4,5.5,0.3),V(-110,8.4,-25.5),C(52,88,86),Enum.Material.Wood,true)
	F.sign(lab,"ResearchSign","MUTATION RESEARCH",V(17,1.8,0.35),V(-116,12,-25.3),C(48,84,82))
	for _, x in ipairs({-122,-101}) do
		F.part(lab,"SpecimenPlanter",V(3.4,1,3.4),V(x,5.5,-21),C(139,148,130),Enum.Material.Slate)
		F.part(lab,"CurledSpecimen",V(2.1,3,2.1),V(x,7.4,-21),C(137,162,142),nil,false,Enum.PartType.Ball)
		F.part(lab,"MutationTip",V(0.7,0.9,0.7),V(x+0.5,8.5,-21),C(164,146,195),Enum.Material.Neon,false,Enum.PartType.Ball)
	end
	F.lantern(town,store,V(-141,10,29),F.Cream)
	F.lantern(town,market,V(-65,10,23),F.Cream)
	F.lantern(town,lab,V(-110,10.5,-24.8),C(176,215,193))
end
return Architecture
