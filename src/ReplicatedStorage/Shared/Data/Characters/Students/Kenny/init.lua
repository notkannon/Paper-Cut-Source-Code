--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCharacter = require(ReplicatedStorage.Shared.Data.Characters.BaseCharacter)
local BullyFemaleFacePack = require(ReplicatedStorage.Shared.Data.Appearance.FacePacks.BullyFemale)
local KennyFacePack = require(ReplicatedStorage.Shared.Data.Appearance.FacePacks.Kenny)

--//Returner

return table.freeze(TableKit.DeepReconcile({
	
	Cost = 600,
	Name = "Kenny",
	Description = "Kenny is a survivalist character that often keeps to herself, not meaning to get in others’ way. Due to her overwhelming shyness, Kenny doesn’t talk to others directly very often and will make very brief small talk whenever she does speak to someone",
	Thumbnail = "rbxassetid://131144984011670",
	Icon = "rbxassetid://130166550424482",
	
	AltIcons = {
		Injured = "rbxassetid://94652772894670",
		Critical = "rbxassetid://107381722957317"
	},
	
	FacePack = KennyFacePack,
	
	PassivesData = {
		
		-- legacy passive data
		--ShyReticence = {
			
		--	Downtime = 4, -- how long it takes to stand still to start turning invisible
		--	Transparency = 0.9,
			
		--	TweenConfig = {
		--		Time = 3,
		--		EasingStyle = Enum.EasingStyle.Cubic,
		--		EasingDirection = Enum.EasingDirection.In,
		--	}
		--}
		
	},
	
	SkillsData = {
		
		--strengthen stealth active, but without passive
		-- uncomment only if kenny's passive doesnt work well with stealther ability
		--ConcealedPresence = {
		--	Cooldown = 30,
		--	Duration = 15,
		--	Transparency = 0.95,
		--	SpeedModifier = 0.65,
		--}
	},
	
	CharacterData = {
		UniqueProperties = {
			LMSPanickedDurationMultiplier = 2/3, -- if this property exists and is set to <1, LMS doesnt apply permanent panicked, but temporary instead.
			PanickedDurationMultiplier = 2/3
		}
	},
	
} :: BaseCharacter.CharacterData, BaseCharacter))