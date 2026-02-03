return {
	Name = "togglecollisions",
	Aliases = { "showcollisions", "debugcolliders" },
	Description = "Sets current round countdown.",
	Group = "Round",
	Args = {
		{
			Type = "boolean",
			Name = "Show Debug Collisions",
			Description = "Testing Map Collisions",
		},
	},
}