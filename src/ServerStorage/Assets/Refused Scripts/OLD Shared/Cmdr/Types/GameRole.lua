local Enums = require(game.ReplicatedStorage.Enums)
local RolesEnum = Enums.GameRolesEnum

return function (registry)
	local strings = {}
	
	-- parsing registered items
	for enum_string, val in pairs(RolesEnum) do
		table.insert(strings, enum_string)
	end
	
	-- registry
	registry:RegisterType("gameRole", registry.Cmdr.Util.MakeEnumType("Game role", strings))
end