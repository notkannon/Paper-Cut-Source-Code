--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCharacter = require(ReplicatedStorage.Shared.Data.Characters.BaseCharacter)
local AbbieFacePack = require(ReplicatedStorage.Shared.Data.Appearance.FacePacks.Abbie)

--//Returner

return table.freeze(TableKit.DeepReconcile({
	Cost = 400,
	Name = "Abbie",
	Description = "Abbie is a chase-based character, utilising his quick running speed to get away quickly when spotted and stay out of their sight. Despite being a nervous wreck a lot of the time, he tries his best to keep up with the others, no matter how many times he may fall behind",
	Icon = "rbxassetid://96516744120298", --"rbxassetid://138276460209163",
	
	AltIcons = {
		Injured = "rbxassetid://86956517112170",
		Critical = "rbxassetid://92330586893706"
	},
	
	FacePack = AbbieFacePack,
	
	SkillsData = {
		
		--Abbie runs 12.5% faster, however he uses 20% more stamina when doing so
		Sprint = {
			WalkSpeed = 33,
			AnimationSpeedScale = 0.9,
			StaminaLossPerSecond = 11,
		},
	},
	
	PassivesData = {
	},
	
	CharacterData = {
		
		DefaultWalkSpeed = 11.5,
		
		Stamina = {
			GainPerSecond = 7,
		},
	},
	
} :: BaseCharacter.CharacterData, BaseCharacter))