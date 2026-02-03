return {
	Name = "removestatuseffect",
	Aliases = { "removestatus", "clearstatus" },
	Description = "Removes each status effect of provided type from player(s).",
	Group = "Effects",
	Args = {
		{
			Type = "players",
			Name = "From",
			Description = "The player(s) to remove statuses for.",
		},
		{
			Type = "statusEffect",
			Name = "Status Type",
			Description = "The type of the status effect to remove from player(s).",
		},
	},
}