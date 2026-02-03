--//Services

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Variables

local Maps = ServerStorage.Maps


local School = table.freeze({

	Instance = Maps.School.Map,
	Terrain = Maps.School.Terrain,
	--Lighting = Maps.School.Lighting,

	Hideouts = {

		LockerCount = 20,
	},

	Objectives = {

		Amount = 8,
		MinSpawnDistance = 100,
	},
})

local Camping = table.freeze({

	Instance = Maps.Camp.Map, -- Change this to the Schooling map
	Terrain = Maps.Camp.Terrain, -- Change this to the camping map
	--Lighting = Maps.Camp.Lighting, -- Change this to the camping map

	Hideouts = {

		LockerCount = 20,
	},

	Objectives = {

		Amount = 8,
		MinSpawnDistance = 100,
	},
})


local MapsData = table.freeze({
	SchoolMap = School,
	CampingMap = Camping,
})

--//Types

export type Map = typeof(MapsData)

--//Returner

return MapsData