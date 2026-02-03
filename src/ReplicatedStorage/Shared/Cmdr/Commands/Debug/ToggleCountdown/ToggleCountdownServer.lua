--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)

--//Returner

return function(_, value: boolean)
	local MatchService = Classes.GetSingleton("MatchService")
	
	MatchService:ToggleCountdown(not value)
	
	return `{ MatchService.CurrentPhase.GetName() } countdown was { value and "resumed" or "paused" }`
end