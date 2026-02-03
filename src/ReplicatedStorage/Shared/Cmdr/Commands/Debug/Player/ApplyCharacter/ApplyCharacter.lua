return {
	Name = "applycharacter",
	Aliases = { "applychar" },
	Description = "A quick command for changing characters. Automatically infers the role of the character and instantly applies all data. If the character is a student, it will be of random class",
	Group = "RoleConfig",
	Args = {
		{
			Type = "players",
			Name = "For",
			Description = "The players to apply config for.",
		},
		{
			Type = "gameCharacter",
			Name = "Character name",
			Description = "The name of the character to apply.",
		},
		{
			Type = "characterSkin",
			Name = "Skin name",
			Description = "The name of the skin to set for character.",
			Optional = true,
		},
		--{
		--	Type = "boolean",
		--	Name = "Should respawn",
		--	Description = "Yes - player will be respawned.\nNo - player will be despawned.",
		--	Optional = true
		--},
	},
}
