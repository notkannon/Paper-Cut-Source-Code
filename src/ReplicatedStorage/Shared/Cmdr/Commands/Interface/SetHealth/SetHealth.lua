return {
	Name = "sethealth",
	Aliases = { "heal", "health", "damage" },
	Description = "Sets any health for each provided player.",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "For",
			Description = "The players to set role for.",
		},
		{
			Type = "number",
			Name = "Amount",
			Description = "The amount of the health to set.",
		},
	},
}
