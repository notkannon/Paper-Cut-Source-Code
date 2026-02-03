--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCharacter = require(ReplicatedStorage.Shared.Data.Characters.BaseCharacter)
local OliverFacePack = require(ReplicatedStorage.Shared.Data.Appearance.FacePacks.Oliver)

--//Returner

return table.freeze(TableKit.DeepReconcile({
	Cost = 1000,
	Name = "Oliver",
	Icon = "rbxassetid://95087720061726",
	Description = "Oliver is a bully character, seeking out trouble in every nook and cranny available to him. Being the biggest bully in the school and also being Alice’s biggest fan, he often thinks of himself as immune to any kind of punishment no matter what he does.",
	
	AltIcons = {
		Injured = "rbxassetid://118516629713476",
		Critical = "rbxassetid://117611309657475"
	},
	
	FacePack = OliverFacePack,
	
	PassivesData = {
		
		EyeForTrouble = {
			CooldownTime = 30, -- how often to trigger the passive
			SelfHighlightDuration = 3, -- how long to highlight self to teachers
			TeacherHighlightDuration = 3, -- how long to highlight teachers to self
		},
		
	},
	
	CharacterData = {
		
	},
	
} :: BaseCharacter.CharacterData, BaseCharacter))