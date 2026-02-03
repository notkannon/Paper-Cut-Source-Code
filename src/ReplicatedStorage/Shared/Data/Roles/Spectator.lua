--//Services

local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Variables

local Assets = ReplicatedStorage.Assets
local BaseRole = require(script.Parent.BaseRole)
local TableKit = require(ReplicatedStorage.Packages.TableKit)

--//Returner

return TableKit.DeepReconcile({
	
	Team = Teams.Spectator,
	Group = "Spectators",
	MovesetName = "Spectator", --wcs moveset name
	DisplayName = "Spectator",

	Keybinds = {},
	SkillsData = {
		
		Sprint = {
			StaminaLossPerSecond = 0,
			Animation = Assets.Animations.R6STUDENT.Skills.Sprint,
			WalkSpeed = 30,
			Cooldown = 1,
		},

		Jump = {
			Animations = {
				Jump = Assets.Animations.R6STUDENT.Jump,
				Land = Assets.Animations.R6STUDENT.Land,
				FreeFall = Assets.Animations.R6STUDENT.FreeFall,
			},

			StaminaLoss = 10,
			JumpPower = 10,
			Cooldown = 1.5,
		},
	},
	
	CharacterData = {
		
		DefaultWalkSpeed = 14,

		Stamina = {
			Max = 100,
			GainPerSecond = 100,
		},

		Animations = {
			Idle = Assets.Animations.R6STUDENT.Idle,
			Walk = Assets.Animations.R6STUDENT.Walk,
		}
	},
	
	StatusesData = {},
	
}, BaseRole)