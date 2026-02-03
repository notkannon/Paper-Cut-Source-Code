--//Services

local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local BaseRole = require(script.Parent.BaseRole)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseFacePack = require(ReplicatedStorage.Shared.Data.Appearance.BaseFacePack)

--//Variables

local Assets = ReplicatedStorage.Assets

--//Returner

return TableKit.DeepReconcile({
	
	--generic data
	
	Team = Teams.Student,
	Group = "Student", -- ?
	
	Guide = "Try to survive the hunt...",
	RoleDisplayName = "Student",
	Description = "Eternally stuck in a night of torment, Students are who you'll play as most of your time here. Each has their own unique passive that makes them stand out among the others. Pick and choose which student you wish to bring into the never ending hunt",
	Icon = "",
	
	--faces which should be applied for this player
	FacePack = BaseFacePack,
	
	--sound which should be applied for this player
	SoundPack = nil,
	
	--defines if player has inventory
	HasInventory = true,

	StatusesData = {

		Weakness = {},
		HideoutLimited = {},
		HarpoonPierced = {},
		ObjectiveSolving = {},

		Aiming = {
			Animations = {
				Idle = Assets.Animations.Student.Skills.Aim.Idle,
				Start = Assets.Animations.Student.Skills.Aim.Start,
			},

			Cooldown = 0.7,
		},

		HiddenLeaving = {
			Animations = {
				Normal = Assets.Animations.Hideout.Locker.Student.Leave,
				Forced =  Assets.Animations.Hideout.Locker.Student.Kicked,
			}
		},

		HiddenComing = { Animation = Assets.Animations.Hideout.Locker.Student.Enter, },
		Hidden = { Animation = Assets.Animations.Hideout.Locker.Student.Idle, },

		Downed = {
			Animations = {
				Idle = Assets.Animations.Student.Misc.IdleDowned,
				Movement = Assets.Animations.Student.Misc.WalkDowned,
			},
		},
	},

	SkillsData = {

		Sprint = {
			Cooldown = 1,
			WalkSpeed = 30,
			Animation = Assets.Animations.Student.Skills.Sprint,
			AnimationInjured = Assets.Animations.Student.Misc.Injured.SprintInjured,
			AnimationSpeedScale = 0.92,
			StaminaLossPerSecond = 9,
		},

		Vault = {
			Cooldown = 2.5,
			Animation = Assets.Animations.Student.Skills.Vault,
			StaminaLoss = 10,
			MaxUsageDistance = 13.2,
		},
	},

	CharacterData = {
		
		DefaultWalkSpeed = 14,
		
		--base Student stamina config
		Stamina = {
			Max = 100,
			GainPerSecond = 7,
		},

		Animations = {
			Idle = Assets.Animations.Student.Idle,
			Walk = Assets.Animations.Student.Walk,
			IdleInjured = Assets.Animations.Student.Misc.Injured.IdleInjured,
			WalkInjured = Assets.Animations.Student.Misc.Injured.WalkInjured
		}
	},
	
}, BaseRole)