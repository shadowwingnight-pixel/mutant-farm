-- Three anchored original townsfolk. Prompts only request a guarded conversation.
local F = require(script.Parent.SiteForms)
local V, C = Vector3.new, Color3.fromRGB
local NPCs = {}
local definitions = {
	{ Id = "Shopkeeper", Name = "Mira", Role = "Seed keeper", Position = V(-140,5.25,34), Coat = C(89,143,99), Skin = C(190,133,90) },
	{ Id = "Merchant", Name = "Bram", Role = "Harvest merchant", Position = V(-53,5.25,26), Coat = C(194,119,65), Skin = C(128,86,64) },
	{ Id = "Researcher", Name = "Dr. Lumen", Role = "Mutation researcher", Position = V(-106,5.25,-20), Coat = C(179,205,196), Skin = C(223,175,132) },
}
function NPCs.build(town, talk)
	local root = F.group(town.model, "Townsfolk")
	for _, def in ipairs(definitions) do
		local model = F.group(root, def.Id)
		local function part(name, size, offset, color, shape)
			return F.part(model, name, size, def.Position + offset, color, Enum.Material.SmoothPlastic, false, shape)
		end
		for _, x in ipairs({-0.45,0.45}) do
			part("Boot",V(0.7,0.5,1),V(x,0.25,0.1),C(64,65,57))
			part("Leg",V(0.65,1.3,0.65),V(x,1,0),C(61,77,75))
			part("Sleeve",V(0.55,1.65,0.65),V(x*2.6,2.5,0),def.Coat)
			part("Hand",V(0.5,0.5,0.5),V(x*2.6,1.65,0),def.Skin,Enum.PartType.Ball)
		end
		part("Coat",V(1.85,1.9,0.85),V(0,2.45,0),def.Coat)
		part("Head",V(1.35,1.3,1.15),V(0,4,0),def.Skin,Enum.PartType.Ball)
		for _, x in ipairs({-0.27,0.27}) do
			local eye = part("Eye",V(0.12,0.15,0.08),V(x,4.1,0.55),C(40,47,45))
			local blink = game:GetService("TweenService"):Create(eye, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 3.2), { Size = V(0.12,0.025,0.08) })
			blink:Play()
			model.Destroying:Connect(function() blink:Cancel() end)
		end
		part("Smile",V(0.32,0.08,0.08),V(0,3.76,0.56),C(91,64,52))
		if def.Id == "Shopkeeper" then
			part("StrawBrim",V(2.15,0.16,1.65),V(0,4.65,0),C(223,195,126))
			part("HatCrown",V(1.3,0.5,1.1),V(0,4.9,0),C(205,176,109))
			part("Apron",V(1.3,1.45,0.12),V(0,2.2,0.49),C(232,216,172))
		elseif def.Id == "Merchant" then
			part("Cap",V(1.45,0.45,1.2),V(0,4.6,0),C(104,73,58))
			part("Apron",V(1.4,1.6,0.12),V(0,2.2,0.49),C(89,103,110))
			part("Ledger",V(0.65,0.85,0.16),V(1.25,1.7,0.4),C(147,86,61))
		else
			part("Hair",V(1.5,0.5,1.15),V(0,4.6,-0.1),C(224,226,210))
			for _, x in ipairs({-0.28,0.28}) do part("Goggle",V(0.45,0.33,0.12),V(x,4.12,0.58),C(105,179,171)) end
			part("SampleVial",V(0.25,0.6,0.25),V(0.5,2.6,0.6),C(162,133,207))
		end
		local anchor = model.Coat
		town.world.label(anchor, def.Name .. " • " .. def.Role, 3.5, 210, 32)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText, prompt.ObjectText = "Talk", def.Name
		prompt.KeyboardKeyCode = Enum.KeyCode.F -- Leave existing E shop prompts intact.
		prompt.MaxActivationDistance, prompt.RequiresLineOfSight = 9, false
		prompt.Parent = anchor
		prompt.Triggered:Connect(function(player) talk(player, def, anchor) end)
		-- Bounded blink tweens above provide idle life without AI, physics or frame loops.
	end
end
function NPCs.dialogue(def, state, environment)
	local lines = {}
	if environment.meteorEndsAt > 0 then
		table.insert(lines, def.Id == "Researcher" and "The readings are spiking. If you're hunting rare mutations, now might be interesting. Nothing is guaranteed!" or "Look up! Meteor energy is passing through town. A good moment to tend your crops.")
	elseif environment.weather == "Thunderstorm" then
		table.insert(lines, "Storm energy can make unusual mutations more likely. Let's see what your next harvest brings.")
	elseif environment.weather == "Rain" then
		table.insert(lines, "Rain changes the energy around our crops. Rare mutations have a little more opportunity today.")
	elseif environment.phase == "Night" then
		table.insert(lines, "A quiet night in town. Crops still grow, and the darkness can bring a little extra mutation luck.")
	end
	if def.Id == "Shopkeeper" then
		table.insert(lines, "I'm Mira. Good gardens start small! Browse the counter beside me for Tomato Seeds, then click an empty soil plot at home.")
		table.insert(lines, "Sell harvests and keep farming to unlock Strawberry, then Pumpkin. The Seeds menu shows exactly what you need.")
	elseif def.Id == "Merchant" then
		table.insert(lines, "Bram's the name. Bring your harvested crops to this counter and sell the whole basket. I like a busy market!")
		table.insert(lines, "Golden, Giant, Crystal and Cosmic harvests sell for more. Your basket shows the value before you sell.")
	else
		if state.researchCount == 0 then
			table.insert(lines,"Bring two harvested specimens to my workbench. Press R for Research: review both slots and the Coin cost before confirming. Keep interesting crops instead of selling them!")
		else
			table.insert(lines,"Your experiments are bearing fruit! Check Book → Research for discoveries, or Seeds → Experimental to plant a result. Rare parents influence traits, never guarantee a mutation.")
		end
		for _, crop in ipairs(state.config.CropOrder) do
			if (state.bag[crop].Cosmic or 0) > 0 then table.insert(lines,"A Cosmic specimen! Its unusual energy favors affinity traits. Even its offspring won't be guaranteed Cosmic."); break end
		end
		table.insert(lines, state.objectiveStep == #state.config.Objectives and "You've learned the town's farming loop! Keep exploring your Discovery Book. There's always another unusual harvest to find." or "I'm Dr. Lumen. Every mature crop rolls one mutation. Harvest it to record that crop-and-mutation combination in your Discovery Book.")
		local missing
		for _, crop in ipairs(state.config.CropOrder) do
			for _, mutation in ipairs(state.config.Mutations) do
				if not state.discoveries[crop][mutation.Id] then missing = crop; break end
			end
			if missing then break end
		end
		table.insert(lines, missing and ("Your " .. missing .. " page still has mysteries. Open Book in the HUD to see what you've recorded. Weather, night and meteors influence chances at maturity, never guarantee a result.") or "Every current combination is recorded! Your Book keeps those discoveries even after you sell. Cosmic remains rare, whatever the weather.")
	end
	return { kind = "Dialogue", name = def.Name .. " • " .. def.Role, lines = lines }
end
return NPCs
