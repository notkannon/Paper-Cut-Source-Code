--//Exports

local PlayerData = require(script.PlayerData)

--//Types

export type States = {
	Data: PlayerData.NameState,
}

export type Actions = PlayerData.Actions

--//Returner

return {
	Data = PlayerData,
}