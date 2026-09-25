-- Numbers and identifiers only: also usable by the standalone Luau tests.
return {
	StartingCoins = 100,
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
