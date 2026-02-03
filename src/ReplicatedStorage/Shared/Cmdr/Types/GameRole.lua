--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

--local Cmdr = require(ReplicatedStorage.Packages.Cmdr) --FIXME: Cmdr Types
local Roles = require(ReplicatedStorage.Shared.Data.Roles)

--//Variables

local Names = {}

--//Returner

for RoleName, _ in pairs(Roles) do
	table.insert(Names, RoleName)
end

return function(registery) --: Cmdr.CmdrServer)
	registery:RegisterType("gameRole", registery.Cmdr.Util.MakeEnumType("GameRole", Names))
end
