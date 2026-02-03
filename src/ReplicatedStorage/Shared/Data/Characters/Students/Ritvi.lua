--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCharacter = require(ReplicatedStorage.Shared.Data.Characters.BaseCharacter)
local RitviFacePack = require(ReplicatedStorage.Shared.Data.Appearance.FacePacks.Ritvi)

--//Returner

return table.freeze(TableKit.DeepReconcile({
	Cost = 800,
	Name = "Ritvi",
	Icon = "rbxassetid://73218004072780",
	AltIcons = {
		Injured = "rbxassetid://75897536870447",
		Critical = "rbxassetid://92004035244736"
	},

	Description = "Ritvi is a chase-based character, utilising his energy reserves when it matters. He’s often seen moping around the school grounds, looking like a man with nothing to lose unless he’s doing the one thing he loves, making music",
	
	FacePack = RitviFacePack,

	SkillsData = {

	},

	PassivesData = {
		MinOnHitDurationBoost = 1,
		MaxOnHitDurationBoost = 3
	},

	CharacterData = {
		
	},

} :: BaseCharacter.CharacterData, BaseCharacter))