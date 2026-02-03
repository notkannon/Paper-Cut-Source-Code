local Server = shared.Server
local Client = shared.Client
local Shared = Server or Client
local Requirements = shared._requirements

--// service
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--// requirements
local Enums = require(ReplicatedStorage.Enums)
local Signal = require(ReplicatedStorage.Package.Signal)
local GlobalSettings = require(ReplicatedStorage.GlobalSettings)

--// Vars
local PlayerRoles = GlobalSettings.Roles
local PlayerRolesEnum = Enums.GameRolesEnum


--// INITIALIZATION
local PlayerComponent = {}
PlayerComponent._objects = {}
PlayerComponent.__index = PlayerComponent

--// STATIC METHODS
-- returns first Character Object with same player
function PlayerComponent.GetObjectFromInstance(instance: Player)
	for _, Object in ipairs(PlayerComponent._objects) do
		if Object.Instance == instance then return Object end
	end
end

-- returns first Character Object with same player
function PlayerComponent.GetObjectFromCharacter(character: Model)
	for _, Object in ipairs(PlayerComponent._objects) do
		if Object.Character and Object.Character.Instance == character then return Object end
	end
end

--// METHODS
-- constructor
function PlayerComponent.new(player: Player)
	assert(player, 'No player instance provided')
	assert(player:IsDescendantOf(Players), 'Player doesn`t exists')
	assert(not PlayerComponent.GetObjectFromInstance(player), `Already created Player object for player "{ player }"`)
	
	-- object creation
	local self = setmetatable({
		Instance = player,
		KillerChance = 0,
		Character = nil,
		Backpack = nil,
		Role = nil,
		
		CharacterChanged = Signal.new(),
		RoleChanged = Signal.new(),
		Destroying = Signal.new(),

		ScoreActions = {},
		_connections = {}
	}, PlayerComponent)

	-- registry
	table.insert(
		self._objects,
		self)
	return self
end

-- initial method
function PlayerComponent:Init() end

-- returns true if parented to game.Players
function PlayerComponent:Exists()
	return self.Instance and self.Instance:IsDescendantOf(Players)
end

-- returns true if player has teacher role
function PlayerComponent:IsKiller()
	local Role = self.Role
	if not Role then return end
	
	for _, teacher_role in pairs(PlayerRoles.Teacher) do
		if teacher_role.enum ~= Role.enum then continue end
		return true
	end
end

function PlayerComponent:GetTotalScore()
	local TotalScore = 0
	
	for _, Action in ipairs(self.ScoreActions) do
		local ActionReward = GlobalSettings.Rewards[Action]
		
		if not ActionReward then
			continue
		end
		
		TotalScore += ActionReward.Points
	end
	
	return TotalScore
end

function PlayerComponent:GetAllActions()
	return table.clone(self.ScoreActions)
end

function PlayerComponent:HasAction(actionEnum: number)
	return table.find(self.ScoreActions, actionEnum) ~= nil
end

function PlayerComponent:GetActionsAmount()
	local Group = {}
	
	for _, Action in ipairs(self.ScoreActions) do
		Group[Action] = Group[Action] and Group[Action] + 1 or 1
	end
	
	return Group
end

-- returns true if current player role is student
function PlayerComponent:IsSurvivor()
	return self.Role == PlayerRoles.Student
end

-- sets role for current player
function PlayerComponent:SetRole(source: number|string)
	assert(source, `No role name or enum provided`)
	
	-- role_enum definition
	local role_enum: number
	if type(source) == 'string' then
		role_enum = PlayerRolesEnum[ source ]
	else role_enum = source end

	-- assertation
	assert(role_enum, `Role doesn't exists ({ source })`)

	-- role definition
	local role

	--// ROLE GETTING
	-- player currently NOT a game member
	if role_enum == PlayerRolesEnum.Spectator then
		role = PlayerRoles.Spectator

		-- player currently SURVIVOR team
	elseif role_enum == PlayerRolesEnum.Student then
		role = PlayerRoles.Student

	else -- player currently HUNTERS (TEACHERS) team
		for _, teacher_role in pairs(PlayerRoles.Teacher) do
			if teacher_role.enum ~= role_enum then continue end
			role = teacher_role
			break
		end
	end

	-- poll update
	self.Role = role
	self.Instance.Team = role.team
end

-- object destruction
function PlayerComponent:Destroy()
	self.Destroying:Fire()

	for _, connection: RBXScriptConnection in ipairs(self._connections) do
		connection:Disconnect()
	end

	self.CharacterChanged:DisconnectAll()
	self.RoleChanged:DisconnectAll()
	self.Destroying:DisconnectAll()
	self.Character:Destroy()

	table.remove(PlayerComponent._objects,
		table.find(PlayerComponent._objects,
			self
		)
	)

	setmetatable(self, nil)
	table.clear(self)
end

return PlayerComponent