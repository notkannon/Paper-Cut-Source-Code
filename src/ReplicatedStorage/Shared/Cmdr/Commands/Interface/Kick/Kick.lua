return {
	Name = "kick";
	Aliases = {};
	Description = "Kicks a player or set of players.";
	Group = "Admin";
	Args = {
		{
			Type = "players";
			Name = "players";
			Description = "The players to kick.";
		},
		
		{
			Type = "string";
			Name = "reason";
			Description = "The reason for player kicked.";
		},
	};
}