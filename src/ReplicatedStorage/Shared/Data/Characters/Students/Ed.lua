--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCharacter = require(ReplicatedStorage.Shared.Data.Characters.BaseCharacter)
local EdFacePack = require(ReplicatedStorage.Shared.Data.Appearance.FacePacks.Ed)

--//Returner

return table.freeze(TableKit.DeepReconcile({
	Cost = 0,
	Name = "Ed",
	Icon = "rbxassetid://72373720665805", --"rbxassetid://134153062735981",
	Description = "Ed is a survivalist character that’s got a craving for food to keep himself sustained. Having a deep interest in sports, he often is seen playing games like Basketball or Volleyball with endless passion and energy.",
	
	AltIcons = {
		Injured = "rbxassetid://95572448030895",
		Critical = "rbxassetid://119737129435725"
	},
	
	FacePack = EdFacePack,

	SkillsData = {

	},

	PassivesData = {
	},

	CharacterData = {
		UniqueProperties = {
			FoodHealingMultiplier = 1.5
		}
	},

} :: BaseCharacter.CharacterData, BaseCharacter))