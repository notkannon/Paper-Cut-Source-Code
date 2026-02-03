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

	Name = "MissCircle",
	CharacterDisplayName = "Miss Circle",
	MovesetName = "MissCircle", -- wcs moveset name
	Description = "Miss Circle is the powerhouse of the three teachers, featuring a taller stature than the others by a wide margin. Utilising her Compass and her brute strength, she controls where others can go and makes sure they don’t get too far",
	IntendedRole = "Teacher",
	IsFree = true,
	Thumbnail = "rbxassetid://131144984011670",
	Icon = "rbxassetid://128118722931777",
	
	TerrorData = {
		Radius = 70,
		MusicLayers = {
			"rbxassetid://132697907805397",
			"rbxassetid://123650780632916",
			"rbxassetid://116923349013728",
			"rbxassetid://125357454435196",
		}
	},

	StatusesData = {
		
		Aiming = {
			Animations = {
				Idle = Assets.Animations.Killer.MissCircle.Skills.Harpoon.Aiming,
				Start = Assets.Animations.Killer.MissCircle.Skills.Harpoon.Equip,
			},

			Cooldown = 0.7,
		},
		
		Stunned = {
			Animation = Assets.Animations.Killer.MissCircle.Stun,
		},
	},
	
	PassivesData = {
		
		FailureInstinctPassive = {
			OutOfChaseTime = 45,
		},
	},

	SkillsData = {

		Sprint = {
			Cooldown = 1,
			WalkSpeed = 26,
			Animation = Assets.Animations.Killer.MissCircle.Skills.Sprint,
			AnimationSpeedScale = 0.37,
			StaminaLossPerSecond = 6,
		},

		Attack = {
			Image = "rbxassetid://118400373417816",
			Input = Enum.UserInputType.MouseButton1,

			Animations = Assets.Animations.Killer.MissCircle.Skills.Attack:GetChildren(),

			Hitbox = {
				Type = "Box",
				Size = Vector3.new(3.5, 5, 7),
				Offset = Vector3.new(0, 0, -3.5),
			},

			Order = 1,
			Damage = 31,
			Cooldown = 2,
		},
		
		Harpoon = {
			Order = 2,
			Input = Enum.UserInputType.MouseButton1,
			Image = "rbxassetid://98949968438618",
			Damage = 20,
			SnapDamage = 5, -- when harpoon snaps early
			DoorDamage = 25, -- harpoon deals that much damage to doors
			Duration = 10, -- how much time before ability end
			MissDuration = 4, -- how much time before ability end, cancels if hit a student
			Cooldown = 10,
			Velocity = 200,
			Animations = Assets.Animations.Killer.MissCircle.Skills.Harpoon,
		},
		
		Shockwave = {
			
			Hitbox = {
				Size = 60,
				Type = "Sphere",
				Offset = Vector3.zero,
			},
			
			Order = 3,
			Input = Enum.KeyCode.Q,
			Image = "rbxassetid://111380415471102",
			Cooldown = 15,
			Animation = Assets.Animations.Killer.MissCircle.Skills.Shockwave,
			
			SlownessDuration = 1.5,
			SlownessFadeOutTime = 3.25,
			
			BoostDuration = 1.5,
			BoostMultiplier = 1.2,
			BoostFadeOutTIme = 3.5,
		},
	},

	CharacterData = {
		DefaultWalkSpeed = 8,
		FootstepQuakeScale = 0.65,
		
		Stamina = {
			Max = 100,
			GainPerSecond = 7,
		},

		Animations = {
			Idle = Assets.Animations.Killer.MissCircle.Idle,
			Walk = Assets.Animations.Killer.MissCircle.Walk,
		}
	},
	
} :: BaseCharacter.CharacterData, BaseCharacter))