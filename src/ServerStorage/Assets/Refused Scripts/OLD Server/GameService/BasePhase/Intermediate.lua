local server = shared.Server
local requirements = server._requirements

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

-- requirements
local GlobalSettings = require(ReplicatedStorage.GlobalSettings)
local PlayerSort = require(ServerStorage.Server.GameService.PlayerSort)
local Enums = require(ReplicatedStorage.Enums)
local GameService = requirements.GameService


-- Intermediate initial
local Intermediate = require(script.Parent).new()
Intermediate.time_length = GlobalSettings.IntermediateLength
Intermediate.enum = Enums.GamePhaseEnum.Intermediate
Intermediate.name = 'Intermediate'

-- start function
function Intermediate:Start()
	GameService:SetCountdown( Intermediate.time_length )
	GameService:SetPhase( Intermediate )
	Intermediate:SetRunning(true)
	
	-- player role sorted array getting
	local team_sorted_players = PlayerSort:GetTeamSortedPlayers()

	-- player roles applying
	for _, tuple in ipairs(team_sorted_players) do
		-- setting roles and respawning players
		tuple[1]:SetRole( tuple[2] )
		tuple[1]:Respawn()
	end
end

-- start function
function Intermediate:Stop()
	Intermediate:SetRunning(false)
end

-- returns true if can start
function Intermediate:CanStart()
	return GameService:GetPhaseByEnum(Enums.GamePhaseEnum.Round):CanStart()
end

-- returns true if can continue
function Intermediate:CanContinue()
	return GameService:GetPhaseByEnum(Enums.GamePhaseEnum.Round):CanContinue()
end

-- complete
return Intermediate