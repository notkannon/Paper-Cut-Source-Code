return {
	Name = "setcharacter",
	Aliases = { "equipcharacter", "replacecharacter" },
	Description = "Sets given character for each provided player as Mock data (will not be saved through servers).",
	Group = "RoleConfig",
	Args = {
		{
			Type = "players",
			Name = "For",
			Description = "The players to set character for.",
		},
		{
			Type = "gameCharacter",
			Name = "Character name",
			Description = "The name of the character to set.",
		},
		{
			Type = "characterSkin",
			Name = "Skin name",
			Description = "The name of the skin to set for character.",
			Optional = true
		}
	},
}
