local server = shared.Server
local client = shared.Client

-- declarations
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedFirst = game:GetService('ReplicatedFirst')
local ServerStorage = game:GetService('ServerStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local MessagingEvent = script.Messaging

-- requirements
local Signal = require(ReplicatedStorage.Package.Signal)
local Enums = require(ReplicatedStorage.Enums)
local GamePhaseEnum = Enums.GamePhaseEnum

-- declarations
local BasePhase -- required (server)
local GetRunningPhase

local PhaseRoundUnvailable
local PhaseIntermediate
local PhaseIntermission
local PhaseRound

local Events = {
	Blackout = require(script.Events.Blackout)
}

-- const
local Attributes = {
	PHASE = 'Phase',
	FROZEN = 'Frozen',
	COUNTDOWN = 'Countdown',
	PREV_PHASE = 'PreviousPhase'
}


-- GameService initial
local Initialized = false
local GameService = {}
GameService.ConuntdownChanged = Signal.new()
GameService.PhaseChanged = Signal.new()

-- intial method
function GameService:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	-- events initialization
	Events.Blackout:Init()
	
	-- server
	if server then
		BasePhase = require(ServerStorage.Server.GameService.BasePhase)
		GameService.Phases = BasePhase._objects
		
		-- SERVER FUNCTIONS SET
		-- (IM SORRY FOR THIS SHIT, WE NEED IT..)
		function GetRunningPhase()
			assert(server, 'Attempted to call :GetRunningPhase() on client')

			for _, phase_object in ipairs(GameService.Phases) do
				if phase_object:IsRunning() then return phase_object end
			end
		end
		
		-- server phases initial
		PhaseRoundUnvailable = require(ServerStorage.Server.GameService.BasePhase.RoundUnvailable)
		PhaseIntermediate = require(ServerStorage.Server.GameService.BasePhase.Intermediate)
		PhaseIntermission = require(ServerStorage.Server.GameService.BasePhase.Intermission)
		PhaseRound = require(ServerStorage.Server.GameService.BasePhase.Round)
		
		-- attribute initial
		script:SetAttribute(Attributes.COUNTDOWN, 0)
		script:SetAttribute(Attributes.FROZEN, false)
		PhaseIntermission:Start()
		
		-- running game cycle
		task.spawn(function()
			while task.wait(1) do
				GameService:Update()
				Events.Blackout:Update()
			end
		end)
		
	-- client
	elseif client then
		script.AttributeChanged:Connect(function( attribute: string )
			-- some client code to apply effects..
			if attribute == Attributes.PHASE then
				GameService.PhaseChanged:Fire(
					GameService:GetPhase(),
					GameService:GetPreviousPhase()
				)
				
			elseif attribute == Attributes.COUNTDOWN then
				GameService.ConuntdownChanged:Fire(
					GameService:GetCountdown()
				)
			end
		end)
	end
end

-- GETTERS
function GameService:GetPhase(): number return script:GetAttribute(Attributes.PHASE) end
function GameService:IsFrozen(): boolean return script:GetAttribute(Attributes.FROZEN) end
function GameService:GetCountdown(): number return script:GetAttribute(Attributes.COUNTDOWN) end
function GameService:GetPreviousPhase(): number return script:GetAttribute(Attributes.PREV_PHASE) end

-- returns phase object with same enum (SERVER-ONLY?!)
function GameService:GetPhaseByEnum(enum: number)
	assert(server, 'Attempted to call :GetPhaseByEnum() on client')

	for _, phase_object in ipairs(GameService.Phases) do
		if phase_object:GetEnum() == enum then return phase_object end
	end
end

-- SETTERS (SERVER-ONLY)
-- sets game countdown value
function GameService:SetCountdown( amount: number )
	assert(server, 'Attempted to call :SetCountdown() on client')
	script:SetAttribute(Attributes.COUNTDOWN, amount)
end

-- sets game countdown frozen
function GameService:SetFrozen( frozen: boolean )
	assert(server, 'Attempted to call :SetFrozen() on client')
	script:SetAttribute(Attributes.FROZEN, frozen)
end

-- sets game phase its to enum (phase is object)
function GameService:SetPhase( phase )
	assert(server, 'Attempted to call :SetPhase() on client')
	script:SetAttribute(Attributes.PREV_PHASE, GameService:GetPhase())
	script:SetAttribute(Attributes.PHASE, phase:GetEnum())
end

-- handles next phase for a game
function GameService:NextPhase()
	assert(server, 'Attempted to call :NextPhase() on client')
	
	-- phase getting
	local phase = GetRunningPhase()
	local PhaseEnum = phase:GetEnum()
	
	-- conditions
	if PhaseEnum == GamePhaseEnum.Intermission then
		if PhaseIntermediate:CanStart() then
			-- changing to Intermediate phase
			PhaseIntermission:Stop()
			PhaseIntermediate:Start()
		else
			-- game could not start due some reasons
			PhaseIntermission:Stop()
			PhaseRoundUnvailable:Start()
		end
		
	elseif PhaseEnum == GamePhaseEnum.Intermediate then
		-- changing to Round
		if PhaseRound:CanStart() then
			-- starting round
			PhaseIntermediate:Stop()
			PhaseRound:Start()
		else
			-- can`t start round due some reasons
			--GameService:SetFrozen( false )
			PhaseIntermediate:Stop()
			PhaseRoundUnvailable:Start()
		end
		
	elseif PhaseEnum == GamePhaseEnum.Round then
		-- changng to intermission
		PhaseRound:Stop()
		PhaseIntermission:Start()
		
	elseif PhaseEnum == GamePhaseEnum.RoundUnavailable then
		-- restarting intermission?
		if not PhaseRound:CanStart() then
			-- repeat until phase will be able
		else
			-- resumes game cycle
			PhaseRoundUnvailable:Stop()
			PhaseIntermission:Start()
		end
	end
	
	GameService:SetFrozen( false )
end

-- server game phase update
function GameService:Update()
	assert(server, 'Attempted to call :Update() on client')
	
	-- passing conditions
	if GameService:IsFrozen() then return end
	
	-- phase getting
	local phase = GetRunningPhase()
	
	-- prompt to next game state
	if not phase:CanContinue() or GameService:GetCountdown() <= 0 then
		GameService:SetFrozen( true )
		GameService:NextPhase()
		return
	end
	
	-- countdown real
	GameService:SetCountdown(GameService:GetCountdown() - 1)
end

-- complete
return GameService