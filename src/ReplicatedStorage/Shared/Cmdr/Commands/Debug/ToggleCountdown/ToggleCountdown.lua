return {
	Name = "togglecountdown",
	Aliases = { "enablecountdown", "countdown" },
	Description = "Toggles countdown cycle.",
	Group = "Round",
	Args = {
		{
			Type = "boolean",
			Name = "Enabled?",
			Description = "Countdown will be toggled via provided value.",
		},
	},
}