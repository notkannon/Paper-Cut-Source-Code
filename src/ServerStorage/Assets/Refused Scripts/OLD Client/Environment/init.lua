-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local soundService = game:GetService('SoundService')
local tweenService = game:GetService('TweenService')
local lightingService = game:GetService('Lighting')

-- requirements
local GlobalSettings = require(ReplicatedStorage.GlobalSettings)
local Util = require(ReplicatedStorage.Shared.Util)
local Enums = require(ReplicatedStorage.Enums)
local GamePhaseEnum = Enums.GamePhaseEnum
local GameService = require(ReplicatedStorage.Shared.GameService)
local Lighting = require(script.Lighting)
local Camera = require(script.Parent.Camera)
local Clock = require(script.Clock)

-- class initial
local Initialized = false
local Environment = {}

-- initial metod
function Environment:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	Environment:ApplyPhase(GameService:GetPhase())
	
	-- listeners
	-- phase listener
	GameService.PhaseChanged:Connect(function(NewPhase: number, PreviousPhase: number)
		Environment:ApplyPhase(NewPhase)
	end)
	
	-- countdown listener
	GameService.ConuntdownChanged:Connect(function(countdown: number)
		Clock:Apply(countdown, GameService:GetPhase())
	end)
end

-- locally applies game phase and handles some visual effects (day/night and etc.)
function Environment:ApplyPhase( phase: number )
	-- phase indexer
	if phase == GamePhaseEnum.Intermission then
		Camera:Shake(3, .5, 'Bump')
		Lighting:ApplyDay()
		
	elseif phase == GamePhaseEnum.Intermediate then
		Camera:Shake(3, .5, 'Bump')
		Lighting:ApplyNight()
		
	elseif phase == GamePhaseEnum.Round then
		-- sdadasda
		
	elseif phase == GamePhaseEnum.RoundUnavailable then
		Environment:ApplyPhase( GamePhaseEnum.Intermission )
	end
end


function Environment:ApplyCountdown()
	
end

-- complete
return Environment