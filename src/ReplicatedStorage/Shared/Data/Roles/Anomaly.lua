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
	Group = "Anomalies",

	Guide = "Its time for you..",
	RoleDisplayName = "Anomaly",
	Description = "Anomalies are solo killers with variable powers depending on the amount of players. Anomalies can only be present on the anomalous rounds which happen blah blah blah can selkie write this for me isnt he like the writer ok",
	
	--sound which should be applied for this player
	SoundPack = nil,

	StatusesData = {
	},

	SkillsData = {
	},

	CharacterData = {
		
		DefaultWalkSpeed = 14,

		Stamina = {
			Max = 100,
			GainPerSecond = 7,
		},

		Animations = {
			Idle = Assets.Animations.Student.Idle,
			Walk = Assets.Animations.Student.Walk,
		}
	},
	
}, BaseRole)