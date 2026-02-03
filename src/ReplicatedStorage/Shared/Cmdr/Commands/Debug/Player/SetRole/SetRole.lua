return {
	Name = "setrole",
	Aliases = { "giverole" },
	Description = "Sets given role for each provided player.",
	Group = "RoleConfig",
	Args = {
		{
			Type = "players",
			Name = "For",
			Description = "The players to set role for.",
		},
		{
			Type = "gameRole",
			Name = "Name",
			Description = "The name of the role to set.",
		},
	},
}
