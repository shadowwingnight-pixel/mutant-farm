-- Numbers and identifiers only: also usable by the standalone Luau tests.
local Config = {
	Research = {
		Cost = 20, MaxStack = 999, Cooldown = 1.5,
		TraitOrder = { "Growth", "Size", "Value", "Affinity" },
		Traits = {
			Growth = { Grow = 0.8, Scale = 1, Value = 1.1, Affinity = 1, Color = { 123, 232, 159 }, Code = "GR", Description = "20% faster growth; +10% sale value" },
			Size = { Grow = 1, Scale = 1.25, Value = 1.2, Affinity = 1, Color = { 242, 171, 97 }, Code = "SZ", Description = "25% larger; +20% sale value" },
			Value = { Grow = 1, Scale = 1, Value = 1.5, Affinity = 1, Color = { 255, 224, 114 }, Code = "VL", Description = "+50% sale value" },
			Affinity = { Grow = 1, Scale = 1, Value = 1.1, Affinity = 1.5, Color = { 185, 144, 245 }, Code = "AF", Description = "Modest rare-mutation affinity; +10% sale value" },
		},
		-- Additive parental tendencies in TraitOrder. All outcomes keep positive weight.
		ParentWeights = { Normal = {4,1,1,1}, Giant = {1,7,1,1}, Golden = {1,1,7,2}, Crystal = {1,1,4,6}, Cosmic = {1,2,3,10} },
		Compatibility = { Tomato = { Tomato = true, Strawberry = true }, Strawberry = { Tomato = true, Strawberry = true }, Pumpkin = { Pumpkin = true } },
		Catalog = {}, Order = {}, Specimens = {}, SpecimenOrder = {}, Combinations = {}, Discoveries = {},
	},
	StartingCoins = 100,
	Objectives = {
		{ Event = "BuyTomato", Text = "Buy a Tomato Seed", Coins = 5 },
		{ Event = "Plant", Text = "Plant a crop", Coins = 5 },
		{ Event = "Harvest", Text = "Harvest a crop", Coins = 5 },
		{ Event = "Sell", Text = "Sell your harvest", Coins = 5 },
		{ Event = "Discover", Text = "Record a mutation in Book", Coins = 5 },
		{ Event = "Researcher", Text = "Visit the Researcher • north of Town Square", Coins = 5 },
	},
	PlotCount = 6,
	Expansions = {
		{ Name = "Starter Farm", Plots = 6, Cost = 0 },
		{ Name = "Expansion I", Plots = 9, Cost = 500 },
		{ Name = "Expansion II", Plots = 12, Cost = 1500 },
	},
	InteractionDistance = 24,
	ShopDistance = 14,
	ActionCooldown = 0.2,
	Environment = {
		TransitionSeconds = 5,
		Phases = {
			{ Id = "Day", Seconds = 120, Clock = 12, Brightness = 2.2, Ambient = { 125, 135, 145 } },
			{ Id = "Evening", Seconds = 40, Clock = 18, Brightness = 1.4, Ambient = { 130, 105, 115 } },
			{ Id = "Night", Seconds = 80, Clock = 0, Brightness = 0.8, Ambient = { 85, 95, 130 } },
		},
		WeatherSeconds = 90,
		Weather = {
			{ Id = "Clear", Weight = 60, Brightness = 1, Density = 0.22, Color = { 195, 218, 245 }, Rain = 0 },
			{ Id = "Rain", Weight = 30, Brightness = 0.8, Density = 0.35, Color = { 155, 176, 195 }, Rain = 24 },
			{ Id = "Thunderstorm", Weight = 10, Brightness = 0.55, Density = 0.45, Color = { 110, 125, 155 }, Rain = 40 },
		},
		-- Multipliers affect weights, not final percentages. Normal always keeps its baseline weight.
		Modifiers = {
			Rain = { Golden = 1.1, Giant = 1.1, Crystal = 1.3, Cosmic = 1.4 },
			Thunderstorm = { Golden = 1.2, Giant = 1.2, Crystal = 1.7, Cosmic = 2 },
			Night = { Golden = 1.05, Giant = 1.05, Crystal = 1.15, Cosmic = 1.2 },
			Meteor = { Golden = 1.15, Giant = 1.15, Crystal = 1.8, Cosmic = 3 },
		},
		Meteor = { CheckSeconds = 120, Chance = 0.12, Duration = 45, Cooldown = 240 },
		LightningSeconds = { 10, 18 },
		Visuals = { TickSeconds = 0.05, RainRadius = 26, RainHeight = 28, RainSpeed = 48,
			MeteorInterval = 0.7, MeteorLife = 1.4, MaxMeteors = 3, ThunderSoundId = "" },
	},
	CropOrder = { "Tomato", "Strawberry", "Pumpkin" },
	Crops = {
		Tomato = {
			SeedPrice = 10, BaseValue = 18, GrowSeconds = 15, SeedSeconds = 1.3,
			Unlock = { EarnedCoins = 0 },
			GrowthStages = {
				{ At = 0, Label = "SPROUT", Height = 0.8 },
				{ At = 1 / 3, Label = "YOUNG PLANT", Height = 1.9 },
				{ At = 2 / 3, Label = "TOMATO PLANT", Height = 3.2 },
				{ At = 1, Label = "READY", Height = 3.6 },
			},
			Visual = { Style = "Upright", Color = { 237, 69, 68 }, LeafColor = { 61, 143, 66 },
				FruitSize = { 1.25, 1.05, 1.2 }, FruitStage = 3,
				Offsets = { { -0.85, 0.64, -0.3 }, { 0.85, 0.79, 0.1 }, { 0, 0.98, -0.6 } } },
		},
		Strawberry = {
			SeedPrice = 25, BaseValue = 45, GrowSeconds = 22, SeedSeconds = 1.3,
			Unlock = { EarnedCoins = 400, PreviousCrop = "Tomato", Harvests = 24 },
			GrowthStages = {
				{ At = 0, Label = "SPROUT", Height = 0.4 },
				{ At = 1 / 3, Label = "BERRY BUSH", Height = 0.8 },
				{ At = 2 / 3, Label = "FLOWERING", Height = 1.2 },
				{ At = 1, Label = "READY", Height = 1.5 },
			},
			Visual = { Style = "Berry", Color = { 229, 49, 88 }, LeafColor = { 54, 147, 81 },
				FruitSize = { 0.85, 1.15, 0.85 }, FruitStage = 3,
				Offsets = { { -1, 0.7, -0.6 }, { 1, 0.7, -0.6 }, { -0.5, 0.75, 0.8 }, { 0.5, 0.9, 0.5 } } },
		},
		Pumpkin = {
			SeedPrice = 60, BaseValue = 110, GrowSeconds = 32, SeedSeconds = 1.3,
			Unlock = { EarnedCoins = 1500, PreviousCrop = "Strawberry", Harvests = 24 },
			GrowthStages = {
				{ At = 0, Label = "SPROUT", Height = 0.35 },
				{ At = 1 / 3, Label = "SPREADING VINE", Height = 0.65 },
				{ At = 2 / 3, Label = "YOUNG PUMPKIN", Height = 1.2 },
				{ At = 1, Label = "READY", Height = 1.8 },
			},
			Visual = { Style = "Vine", Color = { 242, 137, 39 }, LeafColor = { 70, 133, 66 },
				FruitSize = { 2.8, 2.5, 2.8 }, FruitStage = 3,
				Offsets = { { 0, 0.78, 0 } } },
		},
	},
	-- Ordered weights total 10,000. Exactly one result per mature crop.
	Mutations = {
		{ Id = "Normal", Weight = 7000, Multiplier = 1, Color = { 237, 69, 68 }, Scale = 1 },
		{ Id = "Golden", Weight = 1800, Multiplier = 3, Color = { 255, 198, 47 }, Scale = 1 },
		{ Id = "Giant", Weight = 1000, Multiplier = 2, Color = { 246, 91, 64 }, Scale = 1.8 },
		{ Id = "Crystal", Weight = 190, Multiplier = 6, Color = { 100, 240, 255 }, Scale = 1.15 },
		{ Id = "Cosmic", Weight = 10, Multiplier = 20, Color = { 188, 105, 255 }, Scale = 1.35 },
	},
}

-- Finite identifiers replace per-item GUIDs/lineage trees: 12 seed stacks, 15 specimen classes.
for _, crop in ipairs(Config.CropOrder) do
	for _, trait in ipairs(Config.Research.TraitOrder) do
		local id = crop .. "_" .. trait
		Config.Research.Catalog[id] = { Crop = crop, Trait = trait, Name = "EXP-" .. string.sub(crop,1,1) .. "-" .. Config.Research.Traits[trait].Code }
		table.insert(Config.Research.Order,id)
	end
	for _, mutation in ipairs(Config.Mutations) do
		local id = crop .. "_" .. mutation.Id
		Config.Research.Specimens[id] = { Crop = crop, Mutation = mutation.Id, Name = mutation.Id .. " " .. crop }
		table.insert(Config.Research.SpecimenOrder,id)
	end
	for other in pairs(Config.Research.Compatibility[crop]) do
		local key = crop < other and crop .. "_" .. other or other .. "_" .. crop
		Config.Research.Combinations[key] = true
	end
end
for key in pairs(Config.Research.Combinations) do Config.Research.Discoveries[key] = true end
for _, trait in ipairs(Config.Research.TraitOrder) do
	Config.Research.Discoveries["Trait_" .. trait] = true
	Config.Research.Discoveries["Grown_" .. trait] = true
end
return Config
