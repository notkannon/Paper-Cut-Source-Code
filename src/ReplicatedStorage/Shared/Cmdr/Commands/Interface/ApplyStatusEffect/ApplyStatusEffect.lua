return {
	Name = "applystatuseffect",
	Aliases = { "applystatus", "addstatus", "addstatuseffect" },
	Description = "Applies status effect of provided type for player(s).",
	Group = "Effects",
	Args = {
		{
			Type = "players",
			Name = "For",
			Description = "The player(s) to apply statuses for.",
		},
		{
			Type = "statusEffect",
			Name = "Status Type",
			Description = "The type of the status effect to apply for player(s).",
		},
		{
			Type = "positiveInteger",
			Name = "Duration",
			Description = "Duration of each applied status.",
		},
		{
			Type = "string",
			Name = "Metadata",
			Optional = true,
			Description = `Experimental argument by Provitia. Pass metadata as a string of arguments and types. Example: Multiply:string;5:number will send "Multiply" as the first argument and 5 as the second`
		}
	},
}