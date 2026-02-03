--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Characters = require(ReplicatedStorage.Shared.Data.Characters)

--//Variables

local Names = {
	"None", --case when we need to revert character selection to player's equipped one
}

--//Returner

for CharacterName, _ in pairs(Characters) do
	table.insert(Names, CharacterName)
end

return function(registery) --: Cmdr.CmdrServer)
	registery:RegisterType("gameCharacter", registery.Cmdr.Util.MakeEnumType("GameCharacter", Names))
end
