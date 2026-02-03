--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)

--//Returner

return function(_, value: boolean)
	local MatchService = Classes.GetSingleton("MatchService")
	
	if not value then
		return "TBA"
	end
	
	if MatchService.CurrentPhase and MatchService.CurrentPhase:GetName() == "Round" then
		local Round = MatchService.CurrentPhase
		Round.IsLastManStanding = true
		Round:OnLastManStandingStart(MatchService:GetPlayersState())
	else
		return "Currently not round"
	end
	
	return `Triggered LMS`
end