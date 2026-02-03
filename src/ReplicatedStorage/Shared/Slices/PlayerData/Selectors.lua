--//Variables

local PLAYER_DATA_TYPES = { "Save", "Dynamic" }

--//Functions

--listens to player'r role config changing
local function SelectRoleConfig(playerName: string)
	return function(state)

		local PlayerData = state.Data[playerName]

		if not PlayerData then
			return
		end

		return PlayerData.Dynamic.RoleConfig
	end
end

--listens to exact mock (local server data) value changing (Character, Skin)
local function SelectMock(playerName: string, key: "MockCharacter"|"MockSkin")
	return function(state)

		local PlayerData = state.Data[playerName]

		if not PlayerData then
			return
		end

		return PlayerData.Dynamic[key]
	end
end

--track currently equipped skin for exact character (save data)
local function SelectSkin(playerName: string, characterName: string)
	return function(state)

		local PlayerData = state.Data[playerName]
		
		if not PlayerData then
			return
		end
		
		--print(PlayerData, "CHECKING SKINS")

		return PlayerData.Save.SelectedSkins[characterName]
	end
end

--listens to player's character selection on exact group (anomalies/students)
local function SelectCharacter(playerName: string, groupName: "Anomaly" | "Teacher" | "Student")
	return function(state)
		
		--assert(groupName ~= "Teacher")
		
		
		
		local PlayerData = state.Data[playerName]
		
		--print(state.Data, PlayerData, playerName, groupName)

		if not PlayerData then
			return
		end

		return PlayerData.Save.SelectedCharacters[groupName]
	end
end

local function SelectPlayerData(playerName: string, dataType: "Save" | "Dynamic"?)
	return function(state)
		local PlayerData = state.Data[playerName]
		return PlayerData and (dataType and table.find(PLAYER_DATA_TYPES, dataType) and PlayerData[dataType] or PlayerData)
	end
end

local function SelectSettings(playerName: string)
	return function(state)
		
		local PlayerData = state.Data[playerName]
		
		return PlayerData
			and PlayerData.Save
			and PlayerData.Save.ClientSettings
	end
end

local function SelectStats(playerName: string)
	return function(state)
		
		local PlayerData = state.Data[playerName]
		
		return PlayerData
			and PlayerData.Save
			and PlayerData.Save.Stats
	end
end

local function SelectRole(playerName: string)
	return function(state)
		local PlayerData = state.Data[playerName]
		return PlayerData and PlayerData.Dynamic.Role
	end
end

local function SelectChance(playerName: string, group: "Default"|"Anomaly")
	return function(state)
		
		local PlayerData = state.Data[playerName]
		
		return PlayerData
			and PlayerData.Save
			and PlayerData.Save.Chances[group or "Default"]
	end
end

local function SelectOwnedCharacters(playerName: string)
	return function(state)

		local PlayerData = state.Data[playerName]

		return PlayerData 
			and PlayerData.Save
			and PlayerData.Save.Owned.Characters
	end	
end

local function SelectOwnedSkins(playerName: string, CharacterName: string)
	return function(state)

		local PlayerData = state.Data[playerName]

		return PlayerData 
			and PlayerData.Save
			and PlayerData.Save.Owned.Characters[CharacterName]
	end	
end

local function SelectOwnedFalcuties(playerName: string)
	return function(state)
		
	end
end

--//Returner

return {
	
	SelectSkin = SelectSkin,
	SelectRole = SelectRole,
	SelectCharacter = SelectCharacter,
	SelectMock = SelectMock,
	
	SelectRoleConfig = SelectRoleConfig,
	
	SelectStats = SelectStats,
	SelectChance = SelectChance,
	SelectSettings = SelectSettings,
	SelectPlayerData = SelectPlayerData,
	
	SelectOwnedCharacters = SelectOwnedCharacters,
	SelectOwnedSkins = SelectOwnedSkins,
}