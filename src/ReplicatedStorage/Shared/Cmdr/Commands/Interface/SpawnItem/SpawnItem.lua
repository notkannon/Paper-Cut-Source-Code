return {
	Name = "spawnitem",
	Aliases = { "SpawnItem", "ItemSpawn", "NewItem" },
	Description = "Creates a new item on current player's position.",
	Group = "Items",
	Args = {
		{
			Type = "itemConstructor",
			Name = "Item Name",
			Description = "The name of the item to create.",
		},
		
		{
			Type = "positiveInteger",
			Name = "Amount",
			Description = "Amount of items to create."
		}
	},
}