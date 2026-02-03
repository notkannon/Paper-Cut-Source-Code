--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Enums = require(ReplicatedStorage.Shared.Enums)

--//Variables

local FaceExpressionsEnum = Enums.FaceExpression
local Names = {} :: { string }

--//Returner

for Name, Item in pairs(FaceExpressionsEnum) do
	if type(Item) == "number" then
		table.insert(Names, Name)
	end
end

return function(registery) --: Cmdr.CmdrServer)
	registery:RegisterType("facialExpression", registery.Cmdr.Util.MakeEnumType("FacialExpression", Names))
end