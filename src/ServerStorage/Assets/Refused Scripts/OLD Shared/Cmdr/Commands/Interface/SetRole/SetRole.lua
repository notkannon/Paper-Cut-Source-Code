return {
	Name = "set-role";
	Description = "Sets given role for each provided player.";
	Group = "Interface";
	Args = {
		{
			Type = "players";
			Name = "targets";
			Description = "The players to set role for."
		},
		
		{
			Type = "gameRole";
			Name = "role";
			Description = "Role to set."
		}
	}
}
