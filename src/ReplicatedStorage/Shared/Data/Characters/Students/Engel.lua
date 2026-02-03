--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCharacter = require(ReplicatedStorage.Shared.Data.Characters.BaseCharacter)
local EngelFacePack = require(ReplicatedStorage.Shared.Data.Appearance.FacePacks.Engel)

--//Returner

return table.freeze(TableKit.DeepReconcile({
	Cost = 1000,
	Name = "Engel",
	Icon = "rbxassetid://82210122700382",
	Description = "Engel is a supportive character, acting as a meat shield to take hits and bear the burdens of others as much as he can. With a smile, Engel does his best to support his friends when times get tough, offering comfort and standing up against those who threaten his friends",
	
	AltIcons = {
		Injured = "rbxassetid://100405297678048",
		Critical = "rbxassetid://114869357638203"
	},
	
	FacePack = EngelFacePack,

	SkillsData = {

	},

	PassivesData = {
		
		GuardianAngel = {
			MaxProtectionDistance = 18,
			DamageTakenMultiplier = 0.7,
			IgnoreOtherEngels = true
		},
		
	},

	CharacterData = {
	},

} :: BaseCharacter.CharacterData, BaseCharacter))