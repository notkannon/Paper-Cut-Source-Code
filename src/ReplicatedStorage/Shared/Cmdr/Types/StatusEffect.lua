--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Items = require(ReplicatedStorage.Shared.Data.Items)

--//Variables

local Names = {
	
}

for _, Status in ipairs(ReplicatedStorage.Shared.Combat.Statuses:GetDescendants()) do
	if not Status:IsA("ModuleScript") then
		continue
	end
	
	table.insert(Names, Status.Name)
end

--//Returner

return function(registery) --: Cmdr.CmdrServer)
	registery:RegisterType("statusEffect", registery.Cmdr.Util.MakeEnumType("StatusEffect", Names))
end