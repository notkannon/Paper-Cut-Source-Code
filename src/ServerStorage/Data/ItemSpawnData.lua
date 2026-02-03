--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Enums = require(ReplicatedStorage.Shared.Enums)

--//Variables

local ItemIdsEnum = Enums.ItemIdsEnum

--//Types

export type ItemSpawnData = {
	MinAmount: number?,
	MaxAmount: number?,
}

--//Returner

--[ItemId]: params
return table.freeze({
	
	Global = {
		DefaultMinAmount = 0,
		DefaultMaxAmount = 4,
	},
	
	ItemsShouldSpawnOnMap = {
		ItemIdsEnum.Apple,
		ItemIdsEnum.Banana,
		ItemIdsEnum.Flashlight,
		ItemIdsEnum.ThrowableBook,
		ItemIdsEnum.ThrowablePaperAirplane,
	},
	
	Specific = {
		[ItemIdsEnum.ThrowableBook] = {
			MinAmount = 1,
			MaxAmount = 4
		},
		
		[ItemIdsEnum.Flashlight] = {
			MinAmount = 1,
			MaxAmount = 3
		}
	} :: { [number]: ItemSpawnData }
})