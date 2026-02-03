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
	
	Name = "MissBloomie",
	CharacterDisplayName = "Miss Bloomie",
	MovesetName = "MissBloomie", -- wcs moveset name
	IntendedRole = "Teacher",
	IsFree = true,
	Description = "Miss Bloomie is the smallest and most agile of the teachers, slinking around to catch students off guard and hit them where it hurts the most. Putting her blade to use, she’s able to effectively hunt down survivors from the shadows and leave a mark when she strikes",
	Icon = "rbxassetid://84902544600895", --"rbxassetid://132612665084342",
	
	TerrorData = {
		Radius = 55, 
		MusicLayers = {
			"rbxassetid://132697907805397",
			"rbxassetid://123650780632916",
			"rbxassetid://116923349013728",
			"rbxassetid://125357454435196",
		}
	},

	StatusesData = {
		Stunned = {
			Animation = Assets.Animations.Killer.MissBloomie.Stun,
		}
	},
	
	PassivesData = {
		SerratedBladePassive = {
			BleedDuration = 10,
			BleedInterval = 2,
			BleedDamage = 1
		}	
	},

	SkillsData = {

		Sprint = {
			Animation = Assets.Animations.Killer.MissBloomie.Skills.Sprint,
			Cooldown = 1,
			WalkSpeed = 28,
			StaminaLossPerSecond = 7.5,
			AnimationSpeedScale = 0.8,
		},
		
		BloomieAttack = {
			Input = Enum.UserInputType.MouseButton1,
			Image = "rbxassetid://137411167978329",

			Animations = Assets.Animations.Killer.MissBloomie.Skills.Attack:GetChildren(),
			Hitbox = {
				Type = "Box",
				Size = Vector3.new(3.5, 5, 7),
				Offset = Vector3.new(0, 0, -3.5),
			},

			Order = 1,
			Damage = 22,
			Cooldown = 1.7,
		},

		Stealth = {
			Input = Enum.KeyCode.Q,
			Image = "rbxassetid://129927731280701",

			Order = 2,
			Cooldown = 30,
			Duration = 17,
			WalkSpeed = 18,
			EndBoostDuration = 0.5,
			EndSpeedMultiplier = 1.7,
			
			StaminaGainMultiplier = 0.5,
			SneakAttackDelay = 4,
		},

		Locate = {
			Input = Enum.UserInputType.MouseButton2,
			Image = "rbxassetid://92717089675765",

			Order = 3,
			Cooldown = 20,
		}
	},

	CharacterData = {
		DefaultWalkSpeed = 12,
		
		Stamina = {
			Max = 100,
			GainPerSecond = 9,
		},

		Animations = {
			Idle = Assets.Animations.Killer.MissBloomie.Idle,
			Walk = Assets.Animations.Killer.MissBloomie.Walk,
		}
	},
	
} :: BaseCharacter.CharacterData, BaseCharacter))