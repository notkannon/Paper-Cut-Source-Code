--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local T = require(ReplicatedStorage.Packages.Type)
local Types = require(ReplicatedStorage.Shared.Types)
local Immut = require(ReplicatedStorage.Packages.Immut)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
--local SettingsConstructors = require(ReplicatedStorage.Shared.Data.UiRelated.SettingsConstructors)

--//Types

type Producer = Reflex.Producer<NameState, Actions>

export type NameState = { [string]: State }
export type State = {
	Save: {
		Stats: {
			Wins: number,
			Kills: number,
			Deaths: number,
			Points: number,
			TimePlayed: number,
		},
		
		Chances: { [string]: number },

		SelectedSkins: { [string]: string }, -- Character/Skin

		--groupName: characterName
		SelectedCharacters: {
			--Teacher: string, -- nonsense
			Anomaly: string,
			Student: string,
		},

		Owned: {
			Characters: {
				[string]: {string}
			}	
		},

		ClientSettings: {
			VolumeMusic: number,
			VolumePlayers: number,
			VolumeEnvironment: number,

			CameraShakeEnabled: boolean,
			LowDetailModeEnabled: boolean,
			GlobalShadowsEnabled: boolean,
			
			Keybinds: {
				[string]: {
					Keyboard: { Enum.KeyCode | Enum.UserInputType },
					Gamepad: { Enum.KeyCode | Enum.UserInputType },
				}
			},
		},
	},

	Dynamic: {
		
		Role: string,
		RoleConfig: {any},
		
		MockSkin: string,
		MockCharacter: string,
	},
}

export type Actions = {
	
	SetRole: (playerName: string, role: string) -> (),
	SetSkin: (playerName: string, characterName: string, skinName: string) -> (),
	SetCharacter: (playerName: string, groupName: "Anomaly" | "Student", characterName: string) -> (),
	SetMockData: (state: NameState, playerName: string, key: "MockCharacter"|"MockSkin", value: any?) -> (),
	
	ApplyRoleConfig: (state: NameState, playerName: string, config: {any}, shouldRespawn: boolean?) -> (),
	
	SetPlayerData: (playerName: string, data: State) -> (),
	DeletePlayerData: (playerName: string) -> (),
	
	UpdateChance: (state: NameState, playerName: string, group: "Default"|"Anomaly", value: number) -> (),
	UpdateRoundStats: (state: NameState, playerName: string, statFieldName: string, value: any) -> (),
	UpdatePlayerStats:  (state: NameState, playerName: string, statFieldName: string, value: any) -> (),
	UpdateOwnedCharacter: (state: NameState, playerName: string, CharacterName: string) -> (),
	UpdateOwnedSkins: (state: NameState, playerName: string, Character: string, SkinList: {string}) ->(),
	UpdateSelectedSkin: (state: NameState, playerName: string, CharacterName: string, SkinName: string) -> (),
	
	UpdatePlayerSettings: (state: NameState, playerName: string, data: { [string]: any} ) -> (),
}


-- built dynamically
local function BuildSettingInterface()
	local Map = {}
	
	--for _, Data 
	
	return Map
end

--//Returner

return Reflex.createProducer({}, {
	
	SetPlayerData = function(state: NameState, playerName: string, data: State)
		return Immut.produce(state, function(Draft)
			
			T.strict(T.string)(playerName)
			
			Draft[playerName] = data
		end)
	end,

	DeletePlayerData = function(state: NameState, playerName: string)
		return Immut.produce(state, function(Draft)
			
			T.strict(T.string)(playerName)
			
			Draft[playerName] = nil
		end)
	end,
	
	--[[ This method called from RoleManager both client/server, It dont replicates from server to client.
	
	Caches player's role config from his applied data (Role/Character/Skin)
	
	]]
	ApplyRoleConfig = function(state: NameState, playerName: string, config: {any})
		return Immut.produce(state, function(Draft: State)
			
			T.strict(T.string)(playerName)
			
			Draft[playerName].Dynamic.RoleConfig = config
		end)
	end,
	
	--used to update player's mock (dynamic) fields data
	SetMockData = function(state: NameState, playerName: string, key: "MockCharacter"|"MockSkin", value: any?)
		return Immut.produce(state, function(Draft: State)
			
			T.strict(T.string)(playerName)

			assert(Draft[playerName].Dynamic[key] ~= nil, `Unexpected Mock field name provided ({ key })`)

			Draft[playerName].Dynamic[key] = value
--			print(Draft[playerName].Dynamic[key])
		end)
	end,
	
	--used to set player's selected skin for provided character (default or another)
	SetSkin = function(state: NameState, playerName: string, characterName: string, skinName: string?)
		return Immut.produce(state, function(Draft)
			
			T.strict(T.string)(playerName)
			T.strict(T.string)(characterName)
			T.strict(T.string)(skinName)
			
			Draft[playerName].Save.SelectedSkins[characterName] = skinName
			print(Draft, Draft[playerName].Save.SelectedSkins)
		end)
	end,
	
	--used to set player's selected character for exact group (anomaly/Student)
	SetCharacter = function(state: NameState, playerName: string, groupName: "Anomaly" | "Student", characterName: string)
		return Immut.produce(state, function(Draft)
			
--			print(groupName, characterName)
			
			T.strict(T.string)(playerName)
			T.strict(T.string)(groupName)
			T.strict(T.string)(characterName)

			Draft[playerName].Save.SelectedCharacters[groupName] = characterName
		end)
	end,

	SetRole = function(state: NameState, playerName: string, role: string)
		return Immut.produce(state, function(Draft)
			
			T.strict(T.string)(playerName)
			T.strict(T.string)(role)
			
			Draft[playerName].Dynamic.Role = role
		end)
	end,
	

	UpdatePlayerSettings = function(state: NameState, playerName: string, Data: {[string]: any})
		return Immut.produce(state, function(Draft)
			
			T.strict(T.string)(playerName)
			T.strict(T.table)(Data)
			
			
			Draft[playerName].Save.ClientSettings = Data
			--print(Draft[playerName].Save.ClientSettings)
		end)
	end,
	
	UpdatePlayerStats = function(state: NameState, playerName: string, statFieldName: string, value: any)
		return Immut.produce(state, function(Draft)
			
			T.strict(T.string)(playerName)
			
			local Table = Draft[playerName].Save.Stats
			
			T.strict(T[ typeof(Table[statFieldName]) ])(value)
			
			Table[statFieldName] = value
		end)
	end,
	
	UpdateOwnedSkins = function(state: NameState, playerName: string, Character: string, SkinList: {string})
		return Immut.produce(state, function(Draft)
			local Table = Draft[playerName].Save.Owned.Characters
			
			print(Character, SkinList, Table, playerName)
			
			T.strict(T.table)(Table)
			T.strict(T.string)(Character)
			T.strict(T.table)(SkinList)
			
			if not Table then
				return
			end
			
			Table[Character] = SkinList
		end)
	end,
	
	UpdateOwnedCharacter = function(state: NameState, playerName: string, CharacterName: string)
		return Immut.produce(state, function(Draft)
			
			local Table = Draft[playerName].Save.Owned.Characters

			T.strict(T.table)(Table)
			T.strict(T.string)(CharacterName)
			--T.strict(T.string)(SkinName)
			
			Table[CharacterName] = Table[CharacterName] or {"Default"}
			print(Table, 'updated', Table[CharacterName])
		end)
	end,
	
	--UpdateRoundStats = function(state: NameState, playerName: string, statFieldName: string, value: any)
	--	return Immut.produce(state, function(Draft)
			
	--		local Table = Draft[playerName].Dynamic.RoundStats
			
	--		T.strict(T[ typeof(Table[statFieldName]) ])(value)
			
	--		Table[statFieldName] = value
	--	end)
	--end,
	
	UpdateChance = function(state: NameState, playerName: string, group: "Default"|"Anomaly", value: number)
		return Immut.produce(state, function(Draft)
			
			local Table = Draft[playerName].Save.Chances
			
			T.strict(T.table)(Table)
			T.strict(T.string)(group)
			T.strict(T.number)(value)
			
			Table[group] = value
		end)
	end,
	
}) :: Producer