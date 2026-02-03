--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)

--//Returner

return function(_, countdown: number)
	local MatchService = Classes.GetSingleton("MatchService")
	MatchService:SetCountdown(countdown, "SetCountdownCMDR")

	return `{ MatchService.CurrentPhase.GetName() } countdown was set to { countdown }`
end