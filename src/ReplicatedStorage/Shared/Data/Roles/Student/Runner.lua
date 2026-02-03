--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseStudentData = require(ReplicatedStorage.Shared.Data.Roles.Student)

--//Variables

local Assets = ReplicatedStorage.Assets

--//Returner

return table.freeze(TableKit.DeepReconcile({
	
	Icon = "rbxassetid://128955826030596",
	DisplayName = "Runner",
	MovesetName = "Runner", -- wcs moveset name
	Description = "Quick on their feet, students who prefer to run tend to move quicker and conserve their energy for when they need it most. Runners will be best suited for drawing out what might come for them inevitably",
	
	SkillsData = {

		Evade = {

			Order = 1,
			Image = "rbxassetid://124895405863491",
			
			AutoVaultDistance = 11,
			Animation = Assets.Animations.Student.Skills.Dash,
			Duration = 0.6,
			
			Cooldown = 5,
			
			MaxUses = 1,
			StartingUses = 0,
			
			-- charge allows to generate Uses at some rate
			Charge = {
				MaxCharge = 100,
				StartingCharge = 0,
				
				-- fill sources list sources of charge
				FillSources = {
					TerrorRadius = {
						Amount = 2.5,
						Type = "PerSecond"
					},
					Chase = {
						Amount = 2.5,
						Type = "PerSecond"
					},
					--Stun = {
					--	Amount = 20,
					--	Type = "OneTime" -- [not implemented] apparently stuns are currently horribly tracked idk if i should
					--},
					Passive = {
						Amount = 0.5,
						Type = "PerSecond"
					}
				}
			}
		}
	},

	PassivesData = {
		LightfootedPace = {
			StaminaLossMultiplier = 0.75,
			Delay = 5,
			FadeIn = 5,
			FadeOut = 0
		}
	},
	
}, BaseStudentData))