local server = shared.Server
local requirements = server._requirements

-- requirements
local GlobalSettings = require(game.ReplicatedStorage.GlobalSettings)
local Enums = require(game.ReplicatedStorage.Enums)
local GameService = requirements.GameService

-- RoundUnavailable initial
local RoundUnavailable = require(script.Parent).new()
RoundUnavailable.enum = Enums.GamePhaseEnum.RoundUnavailable
RoundUnavailable.name = 'RoundUnavailable'

-- start function
function RoundUnavailable:Start()
	GameService:SetPhase( RoundUnavailable )
	RoundUnavailable:SetRunning( true )
	GameService:SetCountdown( 0 )
end

-- start function
function RoundUnavailable:Stop()
	RoundUnavailable:SetRunning( false )
end

-- returns true if can start
function RoundUnavailable:CanStart()
end

-- returns true if can continue
function RoundUnavailable:CanContinue()
	return true
end

-- complete
return RoundUnavailable