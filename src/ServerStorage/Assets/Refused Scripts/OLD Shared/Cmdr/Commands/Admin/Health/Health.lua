return {
	Name = "health";
	Aliases = {"hp"};
	Description = "Sets the given health amount for a player or set of players.";
	Group = "Admin";
	Args = {
		{
			Type = "players";
			Name = "targets";
			Description = "The players to set health.";
		},
		
		{
			Type = "integer";
			Name = "amount";
			Description = "Amount of health.";
		},
	};
}