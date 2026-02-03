local Enums = require(game.ReplicatedStorage.Enums)
local ItemsEnum = Enums.ItemTypeEnum

return function (registry)
	local strings = {}
	
	-- parsing registered items
	for enum_string, val in pairs(ItemsEnum) do
		table.insert(strings, enum_string)
	end
	
	-- registry
	registry:RegisterType("gameItem", registry.Cmdr.Util.MakeEnumType("Game item", strings))
end