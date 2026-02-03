return {
	Name = "giveitem",
	Aliases = { "giveitem" },
	Description = "Creates a new item for each provided player.",
	Group = "Items",
	Args = {
		{
			Type = "players",
			Name = "For",
			Description = "The players to set role for.",
		},
		{
			Type = "itemConstructor",
			Name = "Item Name",
			Description = "The name of the item to give.",
		},
		{
			Type = "positiveInteger",
			Name = "Amount",
			Optional = true,
			Description = "How many instances of item to give per person"
		},
		{
			Type = "boolean",
			Name = "Overstack",
			Optional = true,
			Description = "Whether to drop items that don't fit in the inventory next to the players"
		}
	},
}
