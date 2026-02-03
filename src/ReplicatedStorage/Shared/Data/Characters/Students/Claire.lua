--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCharacter = require(ReplicatedStorage.Shared.Data.Characters.BaseCharacter)
local ClaireFacePack = require(ReplicatedStorage.Shared.Data.Appearance.FacePacks.Claire)

--//Returner

return table.freeze(TableKit.DeepReconcile({
	Cost = 0,
	Name = "Claire",
	Icon = "rbxassetid://71546966166264", --"rbxassetid://115921236982201",
	Description = "Claire is a chase-based character that tries her best to run for as long as possible, focusing more on distance than speed. Her relatively calm demeanor allows her to keep a level head when put in stressful situations, no matter how dire they might be",
	
	AltIcons = {
		Injured = "rbxassetid://119480047567485",
		Critical = "rbxassetid://100732456281968"
	},
	
	FacePack = ClaireFacePack,

	SkillsData = {

		--Claire moves 6% slower than other students, but consumes 17.5% less stamina than others
		Sprint = {
			WalkSpeed = 28.2,
			AnimationSpeedScale = 0.89,
			StaminaLossPerSecond = 7.425,
		},
	},

	PassivesData = {
	},

	CharacterData = {
		
		DefaultWalkSpeed = 15,

		Stamina = {
			GainPerSecond = 7,
		},
	},

} :: BaseCharacter.CharacterData, BaseCharacter))