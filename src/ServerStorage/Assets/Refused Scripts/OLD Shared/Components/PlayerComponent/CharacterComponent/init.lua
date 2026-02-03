-- service
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local MessagingEvent = script.Messaging

-- const
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local Signal = require(ReplicatedStorage.Package.Signal)

local Sounds = require(script.Sounds)
local Animator = require(script.Animator)
local Appearance = require(script.Appearance)


-- CharacterComponent initial
local CharacterComponent = {}
CharacterComponent._objects = {}
CharacterComponent.__index = CharacterComponent

--// STATIC METHODS
-- returns first Character Object with same player
function CharacterComponent.GetObjectFromInstance(instance: Model)
	for _, Object in ipairs(CharacterComponent._objects) do
		if Object.Instance == instance then return Object end
	end
end

-- returns first Character Object with same player
function CharacterComponent.GetObjectFromPlayer(player: Player)
	for _, Object in ipairs(CharacterComponent._objects) do
		if Object.Player.Instance == player then return Object end
	end
end

-- returns first Character object if instance is descendant of it
function CharacterComponent.GetObjectFromDescendant(descendant: Instance)
	for _, Object in ipairs(CharacterComponent._objects) do
		local character: Model = Object.Instance
		if descendant:IsDescendantOf(character) then return Object end
	end
end

--// METHODS
-- constructor
function CharacterComponent.new(instance: Model)
	assert(instance, 'No character instance provided')
	assert(instance:IsDescendantOf(workspace), 'Attempted to create a character not in workspace')
	assert(Players:GetPlayerFromCharacter(instance), 'No player exists for given character instance')
	assert(not CharacterComponent.GetObjectFromInstance(instance), `Already created Character object for Instance "{ instance }"`)
	
	-- getting player component for character
	local PlayerComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent)
	
	-- object creation
	local self = setmetatable({
		Player = PlayerComponent.GetObjectFromInstance(Players:GetPlayerFromCharacter( instance )),
		Instance = instance,
		
		HealthChanged = Signal.new(),
		Destroying = Signal.new(),
		Died = Signal.new(),
		
		_connections = {}
	}, CharacterComponent)
	
	-- registry
	table.insert(
		self._objects,
		self)
	return self
end

-- initial method
function CharacterComponent:Init()
	self.Appearance = Appearance.new(self)
	self.Appearance:SetActive(true)
	
	self.Animator = Animator.new(self)
	self.Animator:Init(self.Player.Role.character.animations)
	
	self.Sounds = Sounds.new(self)
	self.Sounds:Init()
	
	-- default humanoid states applying
	local Humanoid: Humanoid = self.Instance.Humanoid
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
end

-- returns humanoid instance if exists
function CharacterComponent:GetHumanoid(): Humanoid
	local character: Model = self.Instance
	return character and character:FindFirstChildOfClass('Humanoid')
end

-- returns true if Humanoid`s MoveDirection is more than 0
function CharacterComponent:HumanoidMoving(): boolean
	local humanoid: Humanoid = self:GetHumanoid()
	if not humanoid then return end
	return humanoid.MoveDirection.Magnitude > 0
end

-- returns HumanoidRootPart position if exists
function CharacterComponent:GetPosition(): Vector3
	local character: Model = self.Instance
	if not character then return end
	local primaryPart: BasePart = character:FindFirstChild('HumanoidRootPart')
	if not primaryPart then return end
	return primaryPart.Position
end

-- returns AssemblyLinearVelocity of character HumanoidRootpart
function CharacterComponent:GetVelocity(): Vector3
	local character: Model = self.Instance
	if not character then return end
	local primaryPart: BasePart = character:FindFirstChild('HumanoidRootPart')
	if not primaryPart then return end
	return primaryPart.AssemblyLinearVelocity
end

-- calls remote event on client and sends any data to server character object
function CharacterComponent:SendMessageToServer(...)
	assert(IsClient, 'Attempted to call :SendMessageToServer() on server')
	MessagingEvent:FireServer(...)
end

-- calls remote event on server and sends any data to client character object
function CharacterComponent:SendMessageToClient(...)
	assert(IsServer, 'Attempted to call :SendMessageToClient() on client')
	MessagingEvent:FireClient(self.Player.Instance, self.Player.Instance, ...)
end

-- calls remote event on server and sends any data to all clients for current character object
function CharacterComponent:SendMessageToAllClients(...)
	assert(IsServer, 'Attempted to call :SendMessageToAllClients() on client')
	MessagingEvent:FireAllClients(self.Player.Instance, ...)
end

-- @override methods called on contextual events
function CharacterComponent:OnClientMessage(...) warn(':OnClientMessage() wasn`t overriden by client') end
function CharacterComponent:OnServerMessage(...) warn(':OnServerMessage() wasn`t overriden by client') end

-- Object destruction
function CharacterComponent:Destroy()
	self.Destroying:Fire()
	
	-- connection dropping
	for _, connection: RBXScriptConnection in ipairs(self._connections) do
		connection:Disconnect()
	end
	
	-- child removal
	self.Appearance:Destroy()
	self.Animator:Destroy()
	self.Sounds:Destroy()
	
	-- signal removal
	self.HealthChanged:DisconnectAll()
	self.Destroying:DisconnectAll()
	self.Died:DisconnectAll()
	
	table.remove(CharacterComponent._objects,
		table.find(CharacterComponent._objects,
			self
		)
	)
	
	setmetatable(self, nil)
	table.clear(self)
end


if IsClient then
	MessagingEvent.OnClientEvent:Connect(function(player: Player, ...)
		local CharacterObject = CharacterComponent.GetObjectFromPlayer(player)
		if not CharacterObject then return end
		
		-- handling client message
		CharacterObject:OnClientMessage(...)
	end)
	
elseif IsServer then
	MessagingEvent.OnServerEvent:Connect(function(sender: Player, ...)
		local CharacterObject = CharacterComponent.GetObjectFromPlayer(sender)
		if not CharacterObject then return end
		
		-- handling server mesage
		CharacterObject:OnServerMessage(...)
	end)
end

return CharacterComponent