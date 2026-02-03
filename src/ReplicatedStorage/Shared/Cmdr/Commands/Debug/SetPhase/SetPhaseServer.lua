--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local GlobalSettings = require(ReplicatedStorage.Shared.Data.GlobalSettings)

--//Returner

return function(_, roundString: string, mapSelected: string)
	local MatchService = Classes.GetSingleton("MatchService")
	local MapToSet
	
	local To = MatchService._Rounds[roundString]
	
	if not To then
		return `Provided phase name doesn't exist`
	end
	
	if MatchService:IsPreparing() then
		return `The current phase is preparing, you cannot change the phase at this moment`
	end

	if not To:ShouldStart() then
		return `This phase's start conditions are not met`
	end
	
	if MatchService.CurrentPhase.GetName() == roundString then
		return `Phase with provided name already running`
	end
	
	if mapSelected == "" or not mapSelected then
		MapToSet = MatchService.MapSelected
	else
		MapToSet = mapSelected
	end
	
	print(mapSelected, MapToSet)
	if roundString == "Round" then
		MatchService:_SetMap(MapToSet)
	end
	
	MatchService:_SetPhase(To)

	return `Game phase was changed to { roundString }, With Map Selected: { MapToSet }`
end