return {
	Name = "applyroleconfig",
	Aliases = { "applyconfig", "updateconfig", "updateroleconfig" },
	Description = "Combines all currently applied Role / Character / Skin fields into a single player config. Affects gameplay",
	Group = "RoleConfig",
	Args = {
		{
			Type = "players",
			Name = "For",
			Description = "The players to apply config for.",
		},
		{
			Type = "boolean",
			Name = "Should respawn",
			Description = "Yes - player will be respawned.\nNo - player will be despawned.",
			Optional = true
		},
	},
}
