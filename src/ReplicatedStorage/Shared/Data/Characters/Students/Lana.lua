--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCharacter = require(ReplicatedStorage.Shared.Data.Characters.BaseCharacter)
local LanaFacePack = require(ReplicatedStorage.Shared.Data.Appearance.FacePacks.Lana)

--//Returner

return table.freeze(TableKit.DeepReconcile({
	Cost = 400,
	Name = "Lana",
	Icon = "rbxassetid://122534820252292", --"rbxassetid://84840457339771",
	Description = "Lana is a survivalist character that manages to keep a level head when panic creeps up on them. She’s never ever seen without her sock puppets, always trying to cheer her friends up with them just to brighten their day, even if only a little bit",
	
	AltIcons = {
		Injured = "rbxassetid://137091640810281",
		Critical = "rbxassetid://125612393267597"
	},
	
	FacePack = LanaFacePack,

	SkillsData = {

	},

	PassivesData = {
	},

	CharacterData = {
		UniqueProperties = {
			LockerTimeMultiplier = 1.5
		}
	},

} :: BaseCharacter.CharacterData, BaseCharacter))