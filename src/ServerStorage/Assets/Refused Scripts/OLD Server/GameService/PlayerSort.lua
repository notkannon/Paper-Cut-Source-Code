local server = shared.Server
local requirements = server._requirements

-- requirements
local globalSettings = require(game.ReplicatedStorage.GlobalSettings)
local Enums = require(game.ReplicatedStorage.Enums)
local ServerPlayer = requirements.ServerPlayer

-- declarations
local playerService = game:GetService('Players')
local GameRolesEnum = Enums.GameRolesEnum
local GameRoles = globalSettings.Roles

-- PlayerSort initial
local PlayerSort = {}

-- so, we have few teacher roles (~3), and now its randomily picks some role to the player
-- we need to return 1st non picked role or throw an error about "Teacher roles out of range"
local function GetNextTeacherRole( sorted )
	local roles = {}
	
	-- filling a clone table of roles
	for _, role in pairs(GameRoles.Teacher) do
		table.insert( roles, role.enum )
	end
	
	for _, tuple in ipairs(sorted) do
		local copy = table.find(roles, tuple[2])
		if not copy then continue end
		table.remove(roles, copy)
	end
	
	assert( #roles > 0, 'Teacher role list out of range' )
	return roles[1]
end

-- returns a list with player and his team to play with
function PlayerSort:GetTeamSortedPlayers()
	local native_players = self:GetValidPlayers()
	
	local player_count: number = #native_players
	local teachers_count: number = math.clamp(math.round(player_count * 1/3), 1, 3)
	local temp_players = {}
	local chance_sorted = {}
	local sorted_players = {}

	for _, player_object in ipairs(native_players) do
		table.insert(temp_players, player_object)
	end
	
	-- sorting from max chanse to lowest
	while #temp_players > 0 do
		local temp_chance = 0
		local highest_chance_player = temp_players[math.random(1, #temp_players)]

		for _, player_object in ipairs(temp_players) do
			if player_object.KillerChance > temp_chance then
				temp_chance = player_object.KillerChance
				highest_chance_player = player_object
			end
		end

		table.insert(chance_sorted, highest_chance_player)
		table.remove(temp_players, table.find(temp_players, highest_chance_player))
	end
	
	local x = 1
	
	-- TODO: make cool role balancing for teachers
	while x <= player_count do
		table.insert(sorted_players, {
			chance_sorted[x], -- player object
			if x <= teachers_count then -- role enum
				GetNextTeacherRole( sorted_players )
				else GameRolesEnum.Student
		})
		
		x += 1
	end
	
	return sorted_players
end

-- returns ALL existing player objects from the game
function PlayerSort:GetValidPlayers()
	local player_array = {}
	
	for _, player_object in ipairs( ServerPlayer._objects ) do
		if not player_object:Exists() then continue end
		table.insert(player_array, player_object)
	end
	
	return player_array
end

--[[ lol initial method
function PlayerSort:Init()
	-- create a replica for whole game states
	self.Replica = ReplicaService.NewReplica({
		ClassToken = ReplicaService.NewClassToken('PlayerSort'),
		Replication = "All",
		Data = self.replicated
	})
	
	-- running game cycle
	task.spawn(function()
		while task.wait(1) do
			self:DoGameTick()
		end
	end)
	
	print('[Server] PlayerSort cycle started successfully')
end]]


--[[function PlayerSort:NextGameState( state: number? )
	if self.is_preparing then return end -- already preparing to the game
	self.is_preparing = true
	
	if self.replicated.gameState == enumsModule.GameStateEnum.Intermission then
		self.Replica:SetValue({'gameState'}, enumsModule.GameStateEnum.Round)
		task.wait(5)
		
		self:PrepareToRound()
		self.Replica:SetValue({'countdown'}, globalSettings.RoundTime)
	else
		
		self:PrepareToIntermission()
		self.Replica:SetValue({'gameState'}, enumsModule.GameStateEnum.Intermission)
		task.wait(5)
		
		self.Replica:SetValue({'countdown'}, globalSettings.IntermissionTime)
	end
	
	self.is_preparing = false
end]]


--[[function PlayerSort:IsRoundStartPossible()
	local available_players = 0

	for _, player_object in ipairs(self:GetPlayers()) do
		available_players += 1
	end

	-- min players is 2
	--warn('Available players', #available_players > 0, available_players)
	return available_players > 0
end]]


--[[function PlayerSort:IsRoundPossible()
	local killers = 0
	local survivors = 0
	
	for _, player_object in ipairs(self:GetPlayers()) do
		if player_object.reference.Team == game.Teams.Student then
			survivors += 1
		else killers += 1 end
	end
	
	--warn(self:GetPlayers())
	--print('Killers:', killers, 'Survivors:', survivors)
	return true --killers > 0-- and survivors > 0
end]]


--[[ could collect all game players round data and give some awards..
function PlayerSort:PrepareToIntermission()
	
end]]


--[[function PlayerSort:SetCountdown(value: number)
	self.Replica:SetValue({'countdown'}, value)
end]]


--[[function PlayerSort:DoGameTick()
	local replica_data = self.replicated
	if self.is_preparing or replica_data.countdown <= 0 then
		-- we can`t start the game while round isn`t possible to start
		-- attempt to change the game state to next
		self:NextGameState()
		
	elseif not self.is_preparing then
		-- stop the game
		if replica_data.gameState == enumsModule.GameStateEnum.Round then
			if not self:IsRoundPossible() then
				--warn('unavailable to continue round')
				self:NextGameState()
				return
			end
		elseif not self:IsRoundStartPossible() then
			--warn('unavailable to countdown')
			if self.replicated.gameState ~= enumsModule.GameStateEnum.RoundUnavailable then
				self.Replica:SetValue({'gameState'}, enumsModule.GameStateEnum.RoundUnavailable)
			end
			
			return
		else
			--warn('available to countdown')
			if self.replicated.gameState ~= enumsModule.GameStateEnum.Intermission then
				self.Replica:SetValue({'gameState'}, enumsModule.GameStateEnum.Intermission)
			end
		end
		
		-- countdown update
		PlayerSort:SetCountdown(replica_data.countdown - 1)
	end
end]]

-- complete
return PlayerSort