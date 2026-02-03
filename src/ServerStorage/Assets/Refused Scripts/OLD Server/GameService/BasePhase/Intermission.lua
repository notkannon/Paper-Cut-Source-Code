local server = shared.Server
local requirements = server._requirements

--//Service

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- requirements
local GlobalSettings = require(ReplicatedStorage.GlobalSettings)
local Enums = require(ReplicatedStorage.Enums)
local GameService = requirements.GameService


-- Intermission initial
local Intermission = require(script.Parent).new()
Intermission.time_length = GlobalSettings.IntermissionTime
Intermission.enum = Enums.GamePhaseEnum.Intermission
Intermission.name = 'Intermission'

-- start function
function Intermission:Start()
	GameService:SetCountdown( Intermission.time_length )
	GameService:SetPhase( Intermission )
	Intermission:SetRunning( true )
end

-- start function
function Intermission:Stop()
	Intermission:SetRunning( false )
end

-- returns true if can start
function Intermission:CanStart()
	return true -- always starts
end

-- returns true if can continue
function Intermission:CanContinue()
	return true -- always continues
end

-- complete
return Intermission