return {
	Name = "setround",
	Aliases = { "setphase", "setstage", "switchround" },
	Description = "Sets another round provided for the game.",
	Group = "Round",
	Args = {
		{
			Type = "roundNames",
			Name = "Target round name",
			Description = "The round game set to.",
		},
		{
			Type = "mapNames",
			Name = "Map Name",
			Optional = true,
			Description = "SchoolMap or CampingMap (default: School)"
		}
	},
}
