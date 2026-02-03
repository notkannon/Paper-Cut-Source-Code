--//Services

local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCharacter = require(ReplicatedStorage.Shared.Data.Characters.BaseCharacter)

--//Variables

local Assets = ReplicatedStorage.Assets

--//Returner

return table.freeze(TableKit.DeepReconcile({
	
	Name = "MissThavel",
	CharacterDisplayName = "Miss Thavel",
	MovesetName = "MissThavel", -- wcs moveset name
	IntendedRole = "Teacher",
	IsFree = true,
	Description = "Thavel is the fastest and most persistent of the teachers, actively hunting down and attacking as many students as possible with effortless ease. Being a Wendigo, she uses her heightened senses and sharpened claws to shred whoever she comes across",
	Icon = "rbxassetid://90457046477258",
	
	TerrorData = {
		Radius = 60,
		MusicLayers = {
			"rbxassetid://132697907805397",
			"rbxassetid://123650780632916",
			"rbxassetid://116923349013728",
			"rbxassetid://125357454435196",--133411773241503 C00lKID
		}
	},
	
	PassivesData = {
		
		--combo related passive
		ProgressivePunishmentPassive = {
			Max = 4,
			Duration = 20,
			StaminaIncrement = 40,
			ProgressiveWalkSpeedIncrement = 2,
			BaseWalkSpeedIncrement = 2,
			MaxHighlightDistanceOnHit = nil,
			TunnelingPunishmentDuration = 1.5,
		},
	},

	StatusesData = {
		
		Stunned = {
			Animation = Assets.Animations.Killer.MissThavel.Stun,
		}
	},

	SkillsData = {

		Sprint = {
			Cooldown = 1,
			WalkSpeed = 27,
			Animation = Assets.Animations.Killer.MissThavel.Skills.Sprint,
			AnimationSpeedScale = 0.65,
			StaminaLossPerSecond = 7,
		},
		
		ThavelAttack = {
			Image = "rbxassetid://85844004100775", --"rbxassetid://114841340922324",
			
			Animations = Assets.Animations.Killer.MissThavel.Skills.Attack:GetChildren(),

			Hitbox = {
				Type = "Box",
				Size = Vector3.new(3.5, 5, 7),
				Offset = Vector3.new(0, 0, -3.5),
			},

			Order = 1,
			Damage = 25,
			Cooldown = 1.3,
			MinDamage = 5,
			MaxDamage = 60,
			MinCooldown = 0.65,
		},
		
		Dash = {
			Image = "rbxassetid://101043088834330", --"rbxassetid://123301671733955",
			Animation = Assets.Animations.Killer.MissThavel.Skills.Dash,

			Hitbox = {
				Type = "Box",
				Size = Vector3.new(4, 5, 7),
				Offset = Vector3.new(0, 0, -3.5),
			},

			Order = 2,
			Cooldown = 7,
			Duration = 1.2,
			
			Damage = 25,
			MinDamage = 5,
			MaxDamage = 60,
			
			StaminaLoss = 20,
		},
		
		Flair = {
			Image = "rbxassetid://98338513457153", --"rbxassetid://120316744078964",

			Order = 3,
			Cooldown = 25,
			Duration = 10,
		},
	},

	CharacterData = {
		
		DefaultWalkSpeed = 9,

		Stamina = {
			Max = 100,
			GainPerSecond = 9.5,
		},

		Animations = {
			Idle = Assets.Animations.Killer.MissThavel.Idle,
			Walk = Assets.Animations.Killer.MissThavel.Walk,
		}
	},
	
} :: BaseCharacter.CharacterData, BaseCharacter))