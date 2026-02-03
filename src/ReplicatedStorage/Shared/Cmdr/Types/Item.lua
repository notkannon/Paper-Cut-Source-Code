--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Items = require(ReplicatedStorage.Shared.Data.Items)

--//Variables

local Names = {} :: { string }

--//Returner

for _, Item in pairs(Items) do
	table.insert(Names, Item.Constructor:sub(1, -5))
end

return function(registery) --: Cmdr.CmdrServer)
	registery:RegisterType("itemConstructor", registery.Cmdr.Util.MakeEnumType("ItemConstructor", Names))
end