return {
	Name = "applyface",
	Aliases = { "setface" },
	Description = "Sets given role for each provided player.",
	Group = "RoleConfig",
	Args = {
		{
			Type = "players",
			Name = "For",
			Description = "The players to apply face to.",
		},
		{
			Type = "facialExpression",
			Name = "Name",
			Description = "The name of the face to apply.",
		},
		{
			Type = "positiveInteger",
			Name = "Duration",
			Description = "How long to apply the face for"
		}
	},
}
