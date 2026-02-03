--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)

local DefaultKeybinds = require(ReplicatedStorage.Shared.Data.Keybinds)
local PlayerData = require(ReplicatedStorage.Shared.Slices.PlayerData)

--//Functions

local function SplitKeybindsByString(): { string }
	local NewKeybinds = {} :: { string }

	for ActionName, DeviceType in DefaultKeybinds do
		for DeviceName, Keybinds in DeviceType do
			for _, Key in Keybinds do
				local PrefixName = `{ActionName}:{DeviceName}:{Key}`
				table.insert(NewKeybinds, PrefixName)
			end
		end
	end

	return NewKeybinds
end

--//Variables

local KeybindsLine = table.freeze(SplitKeybindsByString())
local DefaultData: PlayerData.State = table.freeze({
	
	Save = {
		
		Stats = {
			Wins = 0,
			Kills = 0,
			Deaths = 0,
			Points = 5000,
			TimePlayed = 0,
		},
		
		Chances = {
			Anomaly = 0,
			Default = 0,
		},
		
		--currently selected character skins
		SelectedSkins = {
			MissCircle = "Default",
			MissThavel = "Default",
			MissBloomie = "Default",
		},
		
		SelectedCharacters = {
			Anomaly = nil, -- set "Alice" in the future
			Student = "Claire",
			--Teacher = nil -- no point in setting teacher, it's decided at the start of the round
		},
		
		--all owned characters (anomalies/Students)
		Owned = {
			Characters = {
				Claire = {"Default"}, -- Give Claire cuz why not, we gift an character
				Ed = {"Default"},
				MissCircle = {"Default"},
				MissThavel = {"Default"},
				MissBloomie = {"Default"},
			},

		},
		
		ClientSettings = {

			--audio
			VolumeMaster = 100,
			VolumeMusic = 50,
			VolumePlayers = 100,
			VolumeEnvironment = 100,

			--video
			GammaIncrement = 0,
			FieldOfViewIncrement = 0,

			CameraShakeEnabled = true,
			GlobalShadowsEnabled = true,
			LowDetailModeEnabled = false,

			-- debug
			DevelopersToggled = false,
			HitboxDebugToggled = false,
			GenericEffectsToggled = true,

			--keybinds
			Keybinds = KeybindsLine --? / make sure to reset your data
			--ik but... wait a sec
			-- let me see something
		}
	},
	
	Dynamic = {
		Role = "Unknown",
		
		--cant be replicated. Represents all player character data (skills, statuses, passives, animations and etc.)
		RoleConfig = {},
		
		--debug and local session skins & characters selection
		MockSkin = "",
		MockCharacter = "",
	},
})

--[[ Roles:

- Spectator

Killer classes
- Teacher
- Anomaly

Student classes (same level)
- Medic
- Runner
- Troublemaker
- Stealther

When we pick any of killer role we're take currently equipped character for them and their skin if exists.
For teachers we're just making some "selection" on round start, and not saving this choice cuz system works like that

If we pick any of Student role (class) we're defining is it Student via their Team - its same for these classes

IM GENIUS / Kannon


UPDATE

We're keepin .Dynamic.RoleConfig on client/server without replication. It means what client rebuilds own client-sided config version
from data he has (player's skin / character / role currently equipped). So, we're removing SelectRole/SetRole as important changes. The
main change will be :ApplyRoleConfig() / SelectRoleConfig(). First one will trigger second one on client/server (but produced locally,
cuz server don't replicate this data to client cuz this data very huge and can contain private fields)

]]


		--//SAVES//

		--[[

		JUST IN CASE ED'S IDEA DOESN'T WORK

		ClientSettings = {
					
					--audio
					VolumeMaster = 1,
					VolumeMusic = 1,
					VolumePlayers = 1,
					VolumeEnvironment = 1,
					
					--video
					GammaIncrement = 0,
					FieldOfViewIncrement = 0,
					
					CameraShakeEnabled = true,
					GlobalShadowsEnabled = true,
					LowDetailModeEnabled = false,
					
					-- debug
					DevelopersToggled = false,
					HitboxDebugToggled = false,
					GenericEffectsToggled = true,
					
					
				},

		]]--



--//Types

export type Data = typeof(DefaultData)
export type SaveData = typeof(DefaultData.Save)
export type DynamicData = typeof(DefaultData.Dynamic)
export type ClientSettings = typeof(DefaultData.Save.ClientSettings)

--//Returner

return DefaultData :: PlayerData.State