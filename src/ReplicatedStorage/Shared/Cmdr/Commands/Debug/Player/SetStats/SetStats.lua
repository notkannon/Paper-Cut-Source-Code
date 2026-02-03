return {
	Name = "setstats",
	Aliases = { "setstats" },
	Description = "Sets the player stats to the player",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "For",
			Description = "The players to set the stats for",
		},
		{
			Type = "numericStatsType",
			Name = "Stats",
			Description = "Stats that can be represented with a numeric value",
		},
		{
			Type = "number",
			Name = "Value",
			Description = "Value to the new stats"
		}
	},
}
