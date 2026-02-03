local DATA_LOAD_ERROR = 'Data loading went wrong. Try to reconnect. If you keep getting this message contact us in our server!'
type PlayerProfile = {profile: any, replica: any, reference: Player}

local server = shared.Server
local requirements = server._requirements

-- service
local runService = game:GetService('RunService')
local TeamService = game:GetService('Teams')
local playerService = game:GetService('Players')
local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- WCS initial
local WCSController = server:Require(script.WCSController)
local CharacterComponent = server:Require(script.CharacterComponent)
local BackpackComponent = server:Require(script.BackpackComponent)
--local MonetizationService = require(game.ServerStorage.Server.MonetizationService)

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local Signal = require(ReplicatedStorage.Package.Signal)
local ActionTracker = require(script.ActionTracker)
local GlobalSettings = require(ReplicatedStorage.GlobalSettings)
local ProfileService = require(ReplicatedStorage.Package.ProfileService)
local ReplicaService = require(ServerStorage.Server.ReplicaService)

-- enums
local playerActionType = Enums.PlayerActionType
local GameRolesEnum = Enums.GameRolesEnum
local GameRoles = GlobalSettings.Roles

-- data structures
local playerProfileTemplate = GlobalSettings.PlayerProfileTemplate
local PlayerClassToken = ReplicaService.NewClassToken('ReplicaPlayerClassToken')
local playerPrivateToken = ReplicaService.NewClassToken('ReplicaPrivateClassToken')
local playerProfileStore


-- class initial
local ServerPlayer = {}
ServerPlayer._objects = {}
ServerPlayer.__index = ServerPlayer

-- test environment for studio will no save keys
playerProfileStore = ProfileService.GetProfileStore('Player', playerProfileTemplate)
if runService:IsStudio() then playerProfileStore = playerProfileStore.Mock end

-- constructor
function ServerPlayer.new( player: Player )
	local success, profile = pcall(function()
		return playerProfileStore:LoadProfileAsync(
			'plr_'..player.UserId,
			'ForceLoad'
		)
	end)
	
	-- catching error in profile loading
	if not success then
		player:Kick( DATA_LOAD_ERROR )
		warn( profile )
		return
	end

	if profile then
		-- applying profile data structure (new polls?)
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		-- destroy player object and his variables on release
		profile:ListenToRelease(function()
			local wrap = ServerPlayer.GetObjectFromInstance( player )
			if not wrap then return end -- we may already have destroyed this wrap (if player left by himself)
			wrap:Destroy()
		end)

		-- creating a new player class with profile and replica subclasses
		if player:IsDescendantOf(playerService) then
			local self = setmetatable({
				reference = player,
				profile = profile,
				role = nil, -- local side poll. Determines role data table
				
				-- signals
				Removing = Signal.new(),
				connections = {},
				
				-- specials
				killer_chance = 0,
				action_tracker = nil,
				backpack_object = nil,
				CharacterObject = nil,
				wcs_character_object = nil,
				leaderstats_reference = nil,
			}, ServerPlayer)

			table.insert(
				self._objects,
				self
			)
			
			self:Init()
			return self
		end
	end
	
	-- kick with error message
	player:Kick( DATA_LOAD_ERROR )
end

-- returns true if player instance being parented to the game.Players
-- and if player was loaded locally
function ServerPlayer:Exists()
	return self.reference and
		self.reference:IsDescendantOf(playerService)
end


function ServerPlayer.Role()
	return self.role
end

-- returns true if current role being inside Teacher catalogue
function ServerPlayer:IsKiller()
	return self.Role and self.Role.team == TeamService.Teacher
end

-- returns true if player`s role isn`t "Spectator"
function ServerPlayer:IsSpectator()
	return self.Role and self.Role.enum == GameRolesEnum.Spectator
end

-- returns current .wcs_character_object if exists
function ServerPlayer:GetWCSCharacter()
	return self.wcs_character_object
end

-- returns ActionTracker object if exists
function ServerPlayer:GetActionTracker()
	return self.action_tracker
end

-- sets current .action_tracker
function ServerPlayer:SetActionTracker(object)
	self.action_tracker = object
end


function ServerPlayer.GetObjectFromCharacter(character: Model)
	for _, object in ipairs(ServerPlayer._objects) do
		if object.Character.Instance ~= character then continue end
		return object
	end
end


function ServerPlayer.GetObjectFromInstance(player: Player?)
	for _, object in ipairs(ServerPlayer._objects) do
		if object.reference ~= player then continue end
		return object
	end
end


function ServerPlayer:Init()
	local player: Player = self.reference
	
	-- leaderstats ig..
	local leaderstats = Instance.new('Folder', player)
	leaderstats.Name = 'leaderstats'
	self.leaderstats_reference = leaderstats
	
	-- player character initial
	local characterObject = CharacterComponent.new( self )
	self.Character = characterObject
	
	local backpackObject = BackpackComponent.new( self )
	self.Backpack = backpackObject
	backpackObject:Init()
	
	-- global player`s data
	local playerReplica = ReplicaService.NewReplica({
		ClassToken = PlayerClassToken,
		Tags = {Player = player},
		Replication = "All",
		Data = {
			RoleEnum = GameRolesEnum.Spectator, -- spectator default
			Character = characterObject.replicated
		}
	})
	
	-- local player`s data
	local privateReplica = ReplicaService.NewReplica({
		ClassToken = playerPrivateToken,
		Tags = {Player = player},
		Replication = player, -- individual
		
		Data = {
			Profile = self.profile.Data
		}
	})
	
	-- setting new replicas to object
	self.privateReplica = privateReplica
	self.playerReplica = playerReplica

	for _k, _v in pairs(self.profile.Data) do
		if type(_v) == 'table' then continue end
		
		local val = Instance.new('IntValue', leaderstats)
		val.Name = _k
		val.Value = _v
	end
	
	--[[tell game about new join
	self:IncreaseProfileValue('Joins', 1)]] -- i removed Joins poll ig
	
	-- TODO: remove this further. Make NORMAL spawn system, maan
	table.insert(self.connections,
		self.reference.CharacterAdded:Connect(function(character: Model)
			require(script.Character).new(character).Died:Connect(function()
				task.wait(game.Players.RespawnTime)
				self:Respawn()
			end)
		end)
	)
end

-- finds provided value in player`s profile and increases it by given value (INT only)
function ServerPlayer:IncreaseProfileValue(poll_name: string, value: number)
	assert( type(value) == 'number', 'Increase value should be number' )
	assert( self.privateReplica.Data.Profile[ poll_name ], `No poll "{ poll_name }" exists in player's profile` )
	
	self.privateReplica:SetValue('Profile.' .. poll_name, self.privateReplica.Data.Profile[ poll_name ] + value)
	self.leaderstats_reference:FindFirstChild(poll_name).Value = self.privateReplica.Data.Profile[poll_name]
end

--[[ gives some amount of points to player (AKA exp.)
function ServerPlayer:AwardPoints(amount: number)
	self:IncreaseProfileValue( "Points", amount )
end]]

--[[ used for point awards and replication messages
function ServerPlayer:RegisterAction(action_type: number, ...)
	if action_type == playerActionType.Survived then
		self:IncreaseProfileValue('Wins', 1)
		
		-- used to detect player death (also those who killed him to award points)
	elseif action_type == playerActionType.Died then
		local killer_object = ...
		
		-- awarding killer player
		if killer_object then
			killer_object:RegisterAction(
				playerActionType.Kill
			)
		else
			-- died by himself :p
		end
		
		-- we died anyway..
		self:IncreaseProfileValue('Deaths', 1)
		
	elseif action_type == playerActionType.Kill then
		self:IncreaseProfileValue('Kills', 1)
	end
end]]


-- X sets the player`s team and handles some actions from given team (killer or survivor)
-- ROLES UPD.: sets the player`s role and handles some actions from given role (student, teacher - miss bloomie, circle and etc.)
function ServerPlayer:SetRole( source: string|number )
	assert(source, `No role provided`)
	
	-- if player doesn`t exists
	if not self:Exists() then return end
	
	-- role_enum definition
	local role_enum: number
	if type(source) == 'string' then
		role_enum = GameRolesEnum[ source ]
	else role_enum = source end
	
	-- WOMP
	assert(role_enum, `Role doesn't exists ({ source })`)
	
	-- role definition
	local player: Player = self.reference
	local role
	
	-- ROLE GETTING
	-- player currently NOT a game member
	if role_enum == GameRolesEnum.Spectator then
		role = GameRoles.Spectator
		
	-- player currently SURVIVOR team
	elseif role_enum == GameRolesEnum.Student then
		role = GameRoles.Student
		
	else
		-- player currently HUNTERS (TEACHERS) team
		for _, teacher_role in pairs(GameRoles.Teacher) do
			if teacher_role.enum ~= role_enum then continue end
			role = teacher_role
			break
		end
	end
	
	-- poll update
	self.role = role
	player.Team = role.team
	
	-- role replication
	self.playerReplica:SetValue('RoleEnum',
		role_enum
	)
end

-- applies new character from player`s current role
function ServerPlayer:Respawn()
	if not self:Exists() then return end
	if self:IsSpectator() then return end
	
	local player: Player = self.reference
	local role = self.Role
	local morph: Model?
	
	-- morph exists in role?
	if role.team == TeamService.Teacher then
		morph = role.character.morph:Clone()
	end
	
	-- character resetting (with morph?)
	self.Backpack:Defer() -- saving items
	self.Character:Reset( morph )
	
	if role.team == TeamService.Student then
		self.Backpack:Reset()
		self.Backpack:Restore() -- item restoring
	end

	-- WCS moveset applying
	local wcs_character = self.wcs_character_object
	wcs_character:ApplyMoveset( server._requirements.WCS.GetMovesetObjectByName( role.moveset_name ) )
end


-- automatically binds own character as .wcs_character_object
function ServerPlayer:CreateWCSCharacter()
	local character = self.Character.Instance

	-- assertation
	assert( not self:GetWCSCharacter(), 'WCSCharacter object already exists in player' )
	assert( character, 'No character exists to initialize WCSCharacter object' )

	local wcs_character_object = server._requirements.WCS.Character.new( character )
	self.wcs_character_object = wcs_character_object
end

-- destroys .wcs_character_object inside if exшsts
function ServerPlayer:DestroyWCSCharacter()
	if self.wcs_character_object then
		self.wcs_character_object:Destroy()
		self.wcs_character_object = nil
	end
end

-- destroys player`s object and fully removes all child objects from the game
function ServerPlayer:Destroy()
	-- connection drop
	for _, connection: RBXScriptConnection in ipairs(self.connections) do
		connection:Disconnect()
	end
	
	-- removing player from existing ones to avoid recursive profile release
	--(:Release --> :ListenToRelease --> :Destroy --> :Release --> :ListenToRelease...)
	table.remove(
		self._objects,
		table.find(
			self._objects,
			self
		)
	)
	
	self:DestroyWCSCharacter()
	self.profile:Release()
	self.playerReplica:Destroy()
	self.privateReplica:Destroy()
	self.Character:Destroy()
	
	setmetatable(self, nil)
	table.clear(self)
end


-- Player cleanup connection
playerService.PlayerRemoving:Connect(function( player: Player )
	local wrap = ServerPlayer.GetObjectFromInstance( player )
	if not wrap then return end -- player may have not been loaded
	
	-- removing player`s wrap from the game
	wrap:Destroy()
end)

return ServerPlayer