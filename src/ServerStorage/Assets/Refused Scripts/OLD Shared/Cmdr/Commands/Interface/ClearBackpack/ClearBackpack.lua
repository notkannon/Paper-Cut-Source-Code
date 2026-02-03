return {
	Name = "clear-backpack";
	Aliases = {};
	Description = "Clears backpack for a player or set of players.";
	Group = "Interface";
	Args = {
		{
			Type = "players";
			Name = "targets";
			Description = "The players backpack clears for.";
		},
	};
}