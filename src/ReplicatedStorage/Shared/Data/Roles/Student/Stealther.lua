--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseStudentData = require(ReplicatedStorage.Shared.Data.Roles.Student)

--//Variables

local Assets = ReplicatedStorage.Assets

--//Returner

return table.freeze(TableKit.DeepReconcile({
	
	Icon = "rbxassetid://75979993906194",
	DisplayName = "Stealther",
	MovesetName = "Stealther", -- wcs moveset name
	Description = "Sneaking around and remaining out of sight is your surefire way to survive the night, even if it comes at the cost of others. While a selfish means of going about the night, it’s sure to keep you alive longer than some others",
	
	SkillsData = {

		ConcealedPresence = {
			
			Order = 1,
			Image = "rbxassetid://113825467539362",
			
			Cooldown = 35,
			Duration = 10,
			Transparency = 0.95,
			SpeedModifier = 0.6,
			
			Animations = {
				
				Idle = Assets.Animations.Student.Misc.Crouch.Idle,
				Intro = Assets.Animations.Student.Misc.Crouch.Intro,
				Movement = Assets.Animations.Student.Misc.Crouch.Movement,
			},
			
			Cancelable = true
		}
	},

	PassivesData = {
		HushedActions = {
			ActionVolumeScale = 0.5,
			ActionRollOffScale = 0.5
		}
	},
	
}, BaseStudentData))