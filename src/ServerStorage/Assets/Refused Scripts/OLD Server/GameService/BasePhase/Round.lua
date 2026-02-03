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
local GameRolesEnum = Enums.GameRolesEnum
local GameRoles = GlobalSettings.Roles


-- Round initial
local Round = require(script.Parent).new()
Round.time_length = GlobalSettings.RoundTime
Round.enum = Enums.GamePhaseEnum.Round
Round.name = 'Round'

-- start function
function Round:Start()
	for _, ServerPlayer in ipairs(PlayerSort:GetValidPlayers()) do
		ServerPlayer:ClearActions()
	end
	
	print("START")
	GameService:SetCountdown( Round.time_length )
	GameService:SetPhase( Round )
	Round:SetRunning( true )
	
	-- TODO: some additional events here, like doors opening, also clients doing some things..
end

-- start function
function Round:Stop()
	-- awards and other player changing
	for _, player_object in ipairs( PlayerSort:GetValidPlayers() ) do
		if player_object:IsKiller() then
			player_object.KillerChance = 0 -- resetting a killer chance

			-- adding value [.3, 1] to the player`s chance to be killer for more randomily
		else player_object.KillerChance += math.random(30, 100)/100 end
		
		print('Player award:', player_object.Instance.Name, player_object:PredictAwardedPoints())
		player_object:ClearActions()
	end

	-- only teachers could be respawned when game ends
	for _, player_object in ipairs( PlayerSort:GetValidPlayers() ) do
		if player_object:IsKiller() then
			
			player_object:SetRole( GameRolesEnum.Student )
			player_object:Respawn()
		end
	end
	
	-- stopping phase running
	Round:SetRunning( false )
end

-- returns true if can start
function Round:CanStart()
	local available_players = 0
	local ValidPlayers = PlayerSort:GetValidPlayers()
	
	-- getting valid players count
	for _, player_object in ipairs( ValidPlayers ) do
		available_players += 1
	end

	-- min players is 2
	return available_players > 0
end

-- returns true if can continue
function Round:CanContinue()
	local killers = 0
	local survivors = 0
	local ValidPlayers = PlayerSort:GetValidPlayers()

	for _, player_object in ipairs( ValidPlayers ) do
		if player_object.Instance.Team == game.Teams.Student then
			survivors += 1
		else killers += 1 end
	end

	--warn(self:GetPlayers())
	--print('Killers:', killers, 'Survivors:', survivors)
	return true --killers > 0-- and survivors > 0
end

-- complete
return Round