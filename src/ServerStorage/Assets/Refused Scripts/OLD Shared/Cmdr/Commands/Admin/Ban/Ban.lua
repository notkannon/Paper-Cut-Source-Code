return {
	Name = "ban";
	Aliases = {};
	Description = "Bans a player or set of players.";
	Group = "Admin";
	Args = {
		{
			Type = "players";
			Name = "player";
			Description = "The player(s) to ban.";
		},
		
		{
			Type = "number";
			Name = "days";
			Description = "Ban length (in days). You may pass float number to ban less than 1 day.";
		},
		
		{
			Type = "string";
			Name = "reason";
			Description = "The reason for player banned.";
		},
	};
}