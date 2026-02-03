return {
	Name = "clearitems",
	Aliases = { "RemoveItems", "DestroyItems", "ItemsClear" },
	Description = "Removes (destroys) each dropped item of provided type.",
	Group = "Items",
	Args = {
		{
			Type = "itemConstructor",
			Name = "Item Type",
			Description = "The type of the items to clear from map.",
		},
	},
}