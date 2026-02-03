return {
	Name = "setlms",
	Aliases = { "togglelms" },
	Description = "Triggers LMS. WARNING: CAN BRICK THE SERVER, USE CAUTIOUSLY",
	Group = "Round",
	Args = {
		{
			Type = "boolean",
			Name = "Enabled?",
			Description = "Whether to trigger (works) or attempt to detrigger (TBA) LMS",
		},
	},
}