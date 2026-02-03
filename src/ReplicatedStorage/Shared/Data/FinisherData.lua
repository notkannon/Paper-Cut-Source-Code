--//Services

local Teams = game:GetService("Teams")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Variables

local Assets = ReplicatedStorage.Assets
local Sounds = SoundService.Master

--//Returner

return table.freeze({
	
	MissThavel = {

		Student = {
			Sound = Sounds.Players,
			Animations = {
				Killer = Assets.Animations.Killer.MissThavel.Finisher.Killer,
				Student = Assets.Animations.Killer.MissThavel.Finisher.Student,
			}
		}
	},
	
	MissBloomie = {

		Student = {
			Animations = {
				Killer = Assets.Animations.Killer.MissBloomie.Finisher.Killer,
				Student = Assets.Animations.Killer.MissBloomie.Finisher.Student,
			}
		}
	},
	
	MissCircle = {

		Student = {
			Animations = {
				Killer = Assets.Animations.Killer.MissCircle.Finisher.Killer,
				Student = Assets.Animations.Killer.MissCircle.Finisher.Student,
			}
		}
	},
})