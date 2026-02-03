--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Enums = require(ReplicatedStorage.Shared.Enums)

--//Returner

return table.freeze({
	
	Skills = {
		
		Attack = {
			Default = {Amount = 5, Message = "Hit Student"},
			MissCircle = {Amount = 5},
			MissBloomie = {Amount = 7},
		},
		
		ThavelAttack = {
			Default = {Amount = 5, Message = "Hit Student"}
		},
		
		Harpoon = {
			Default = {Amount = 20, Message = "Pierced Student"},
		}
	},
})