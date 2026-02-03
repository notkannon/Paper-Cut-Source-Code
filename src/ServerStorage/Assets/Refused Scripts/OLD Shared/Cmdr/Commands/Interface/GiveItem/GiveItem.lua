return {
	Name = "give-item";
	Description = "Creates new item for each player and puts it into their backpacks.";
	Group = "Interface";
	Args = {
		{
			Type = "players";
			Name = "targets";
			Description = "The players to give item for."
		},
		
		{
			Type = "gameItem";
			Name = "item";
			Description = "Item to give."
		}
	}
}
