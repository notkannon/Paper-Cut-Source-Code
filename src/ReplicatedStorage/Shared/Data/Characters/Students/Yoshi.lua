--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCharacter = require(ReplicatedStorage.Shared.Data.Characters.BaseCharacter)
local YoshiFacePack = require(ReplicatedStorage.Shared.Data.Appearance.FacePacks.Yoshi)

--//Returner

return table.freeze(TableKit.DeepReconcile({
	Cost = 500,
	Name = "Yoshi",
	Icon = "rbxassetid://135408507005888",
	Description = "Yoshi is a survivalist character that thrives when there’s no one to bother them. She’s often found on her own due to not being a very social person, often avoiding any and all social interaction if she can help it",

	AltIcons = {
		Injured = "rbxassetid://112453944978036",
		Critical = "rbxassetid://112998850471565"
	},
	
	FacePack = YoshiFacePack,

	SkillsData = {
		
	},

	PassivesData = {
		
		RoomToBreathe = {
			HealAmount = 60
		}
		
	},

	CharacterData = {
		
	},

} :: BaseCharacter.CharacterData, BaseCharacter))