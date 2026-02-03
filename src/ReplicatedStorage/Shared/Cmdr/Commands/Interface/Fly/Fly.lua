return {
	Name = "fly";
	Aliases = {};
	Description = "Makes player or set of players fly.";
	Group = "Admin";
	Args = {
		{
			Type = "players";
			Name = "players";
			Description = "The players to teleport";
		},
		{
			Type = "boolean";
			Name = "enabled";
			Description = "Enable or disable fly"
		}
	};
}