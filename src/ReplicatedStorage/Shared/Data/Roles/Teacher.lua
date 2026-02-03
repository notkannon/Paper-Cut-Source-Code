--//Services

local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Variables

local Assets = ReplicatedStorage.Assets
local BaseRole = require(script.Parent.BaseRole)
local TableKit = require(ReplicatedStorage.Packages.TableKit)

--//Returner

return TableKit.DeepReconcile({

	--generic data

	Team = Teams.Killer,
	Group = "Teacher",

	Guide = "Do what you must...",
	RoleDisplayName = "Teacher",
	Description = "The terrors of the night, Teachers offer discipline to students who fail miserably in survival. Each bring their own tools of torment to dismember, maim, and bludgeon the students in their own unique way. Work with two other teachers to properly educate your victims on how to endure the hunt",
	
	SkillsData = {},
	StatusesData = {},
	
	PassivesData = {
		CollectiveAwareness = {
			MinDistance = 50			
		}
	},

	CharacterData = {

		Morph = nil,

		DefaultWalkSpeed = 12,

		Stamina = {
			Max = 100,
			GainPerSecond = 8,
		},
	},
	
}, BaseRole)