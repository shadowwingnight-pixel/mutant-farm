-- Numbers and identifiers only: also usable by the standalone Luau tests.
return {
	StartingCoins = 100,
	PlotCount = 6,
	InteractionDistance = 24,
	ShopDistance = 14,
	ActionCooldown = 0.2,
	Crops = {
		Tomato = { SeedPrice = 10, BaseValue = 18, GrowSeconds = 15 },
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
