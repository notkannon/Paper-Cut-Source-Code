return {
	Name = "setcountdown",
	Aliases = { "settime", "countdown" },
	Description = "Sets current round countdown.",
	Group = "Round",
	Args = {
		{
			Type = "positiveInteger",
			Name = "New countdown",
			Description = "Countdown whole positive number value (> 0) to set.",
		},
	},
}