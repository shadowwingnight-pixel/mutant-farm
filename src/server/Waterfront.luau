local F = require(script.Parent.SiteForms)
local V, C = Vector3.new, Color3.fromRGB
local Waterfront = {}
function Waterfront.build(town)
	local root = F.group(town.model,"RiverAndBridge")
	-- A continuous shallow safety bed supports the whole redesigned corridor.
	F.part(root,"ShallowRiverBed",V(136,2,30),V(-112,3,87),C(144,164,142),Enum.Material.Sand,true)
	local points = {
		V(-180,4.25,89),V(-163,4.25,85),V(-146,4.25,84),V(-129,4.25,87),
		V(-112,4.25,87),V(-95,4.25,90),V(-78,4.25,91),V(-61,4.25,88),V(-44,4.25,86),
	}
	local widths = {14,18,15,12,15,19,16,13}
	for index=1,#points-1 do
		local a,b = points[index],points[index+1]
		local center=(a+b)/2
		local length=(b-a).Magnitude
		local water=F.part(root,"WaterReach",V(widths[index],0.12,length+1.2),center,C(60,145,157),Enum.Material.Glass)
		water.CFrame=CFrame.lookAt(center,b)
		water.Reflectance=0.12 -- Opaque avoids overlapping transparent seams and excessive overdraw.
		for _, side in ipairs({-1,1}) do
			local z=center.Z + side*(widths[index]/2+2)
			F.part(root,"RoundedShore",V(23,1,7),V(center.X,4.15,z),C(182,176,139),Enum.Material.Sand,true,Enum.PartType.Ball)
			F.part(root,"MeadowBank",V(24,1.5,10),V(center.X,4.45,z+side*3.4),C(104,161,111),Enum.Material.Grass,true,Enum.PartType.Ball)
			if index%3==1 then
				F.part(root,"BankStone",V(4,1.8,2.5),V(center.X-4,4.9,z),C(133,151,140),Enum.Material.Slate,false,Enum.PartType.Ball)
				F.part(root,"ReedIsland",V(2,1.9,1.4),V(center.X+4,5.2,z+side),C(130,151,86),Enum.Material.Grass,false,Enum.PartType.Ball)
			end
		end
		if index%2==0 and index~=4 then
			local ripple=F.part(root,"CurrentGlint",V(0.12,0.025,4),center+V(0,0.1,0),C(167,213,201))
			ripple.CFrame=CFrame.lookAt(center+V(0,0.1,0),b+V(0,0.1,0))
		end
	end
	-- A low three-piece deck rises less than a stud; both ends meet continuous stone approaches.
	F.part(root,"NorthApproach",V(14,0.25,8),V(-110,5.05,74.5),C(166,168,146),Enum.Material.Cobblestone,true)
	F.part(root,"SouthApproach",V(14,0.25,8),V(-110,5.05,99.5),C(166,168,146),Enum.Material.Cobblestone,true)
	for _, spec in ipairs({ {80.5,5.5,-6}, {87,5.85,0}, {93.5,5.5,6} }) do
		local deck=F.part(root,"BridgeDeck",V(13,0.4,7),V(-110,spec[2],spec[1]),C(143,110,75),Enum.Material.WoodPlanks,true)
		deck.CFrame *= CFrame.Angles(math.rad(spec[3]),0,0)
	end
	for _, x in ipairs({-117.5,-102.5}) do
		for _, z in ipairs({78,96}) do
			F.part(root,"StoneAbutment",V(2.5,3,4),V(x,5,z),C(147,155,137),Enum.Material.Cobblestone,true)
			F.part(root,"StoneCap",V(2.8,0.4,4.2),V(x,6.7,z),F.Cream)
		end
		for _, z in ipairs({78,87,96}) do F.part(root,"RailPost",V(0.55,3,0.55),V(x,7.1,z),F.Wood,Enum.Material.Wood,true) end
		F.beam(root,"Handrail",V(x,8.3,78),V(x,8.7,87),0.4,F.Cream,true)
		F.beam(root,"Handrail",V(x,8.7,87),V(x,8.3,96),0.4,F.Cream,true)
		F.beam(root,"LowerRail",V(x,6.8,78),V(x,7.2,87),0.25,F.Wood,true)
		F.beam(root,"LowerRail",V(x,7.2,87),V(x,6.8,96),0.25,F.Wood,true)
	end
	local marker=F.part(root,"RiverMarker",V(1,2.2,1),V(-124,6,71),C(154,166,143),Enum.Material.Slate)
	town.world.label(marker,"RIVER WALK\nStonebridge → Future Road",2,210,44)
end
return Waterfront
