--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseStudentData = require(ReplicatedStorage.Shared.Data.Roles.Student)

--//Variables

local Assets = ReplicatedStorage.Assets

--//Returner

return table.freeze(TableKit.DeepReconcile({
	
	Icon = "rbxassetid://124217046268706",
	DisplayName = "Troublemaker",
	MovesetName = "Troublemaker", -- wcs moveset name
	Description = "Making a ruckus is your strong suit, disturbing chases and getting the attention of the teachers you interrupt so abruptly. Confidence must be paired with competence when using this skill set to endure the night",
	
	SkillsData = {

		Swing = {

			Order = 1,
			Image = "rbxassetid://137067025238662",
			
			Hitbox = {
				Type = "Box",
				Size = Vector3.new(3.5, 5, 5),
				Offset = Vector3.new(0, 0, -2.5),
			},
			
			Cooldown = 35,
			StunDuration = 5,
			SpeedModifier = 0, --stopping player
			BoostAfterHit = 1.15,
			BoostAfterHitDuration = 2,

			Visuals = {
				
				Gear = Assets.Skills.Swing.TennisRacket, --gear used in animation (kinda sword, tennis racket and etc.)
				Animation = Assets.Animations.Student.Skills.Swing,
			},
		},
		
		Spray = {
			
			Order = 1,
			Image = "rbxassetid://100308192279896",
			
			DetonationDelay = 1.25,
			Cooldown = 45,
			Duration = 9,
			
			DetonationBlindnessDuration = 5,
			FoamBlindnessDuration = 3,
			FadeoutBlindnessDuration = 3,
			
			DetonationHitbox = {
				Type = "Sphere",
				Size = 20,
				Offset = Vector3.new(0, 14, 0)
			},
			
			SprayHitbox = {
				Type = "Box",
				Size = Vector3.new(8, 30, 15),
				Offset = Vector3.new(0, 15, 0)
			},
			
			Visuals = {
				Gear = Assets.Skills.Spray.FireExtinguisher,
				Animation = Assets.Animations.Student.Skills.Aim.Release
			}
		}
	},

	PassivesData = {
		MischievousHeadstart = {
			
		}
	},
	
}, BaseStudentData))