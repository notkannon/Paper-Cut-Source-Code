return {
	Name = "deletestats",
	Aliases = { "deletestats", "erasestats", "removestats" },
	Description = "WARNING! This command results in a partial or full loss of data. Double check everything twice before running this",
	Group = "Admin",
	Args = {
		{
			Type = "players",
			Name = "For",
			Description = "The players to set his stats",
		},
		{
			Type = "statsType",
			Name = "Stats",
			Description = "Stats",
		}
	},
}
