--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local RubyFacePack = require(ReplicatedStorage.Shared.Data.Appearance.FacePacks.Ruby)
local BaseCharacter = require(ReplicatedStorage.Shared.Data.Characters.BaseCharacter)

--//Returner

return table.freeze(TableKit.DeepReconcile({
	Cost = 700,
	Name = "Ruby",
	Icon = "rbxassetid://95309288031160",
	Description = "Ruby is a survivalist character that’s a lot more durable than other students. Though she may be a teenage robot, Ruby is no different to other students mentally or characteristically despite some beliefs",
	
	AltIcons = {
		Injured = "rbxassetid://78520454758969",
		Critical = "rbxassetid://103171173233730"
	},
	
	FacePack = RubyFacePack,
	
	PassivesData = {},
	
	CharacterData = {
		UniqueProperties = {
			DamageTakenMultiplier = 0.825, -- 17.5% less damage
		}
	},
	
} :: BaseCharacter.CharacterData, BaseCharacter))