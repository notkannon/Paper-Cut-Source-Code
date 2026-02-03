local Client = shared.Client

-- service
local Teams = game:GetService('Teams')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local ClientCharacter = Client:Require(script.ClientCharacter)
local ClientBackpack = Client:Require(script.ClientBackpack)

local Enums = require(ReplicatedStorage.Enums)
local Signal = require(ReplicatedStorage.Package.Signal)
local GlobalSettings = require(ReplicatedStorage.GlobalSettings)
local ClientBackpack = require(script.ClientBackpack)
local ClientCharacter = require(script.ClientCharacter)
local PlayerComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent)
local ReplicaController = require(ReplicatedStorage.Package.ReplicaService.ReplicaController)

-- vars
local PlayersRoles = GlobalSettings.Roles
local PlayerRolesEnum = Enums.GameRolesEnum


--// INITIALIZATION

local LocalPlayer
local ClientPlayer = setmetatable({}, PlayerComponent)
ClientPlayer.__index = ClientPlayer

--// STATIC

-- returns LocalPlayer object if exists
function ClientPlayer.GetLocalPlayer()
	return LocalPlayer
end

--// METHODS

-- Client player constructor
function ClientPlayer.new( ReplicaObject )
	assert( ReplicaObject, 'No PlayerReplica object provided' )
	
	-- new player object
	local self = setmetatable(PlayerComponent.new(ReplicaObject.Tags.Player), ClientPlayer)
	self.ReplicaObject = ReplicaObject

	-- local player setting
	if self:IsLocalPlayer() then
		LocalPlayer = self
		Client.Player = self
		Client.PlayerAdded:Fire( self )
	end

	self:Init()
	return self
end

-- Client initial method override
function ClientPlayer:Init()
	local player: Player = self.Instance
	local replica = self.ReplicaObject

	-- connecting to player .CharacterChanged
	self.CharacterChanged:Connect(function(Character)
		if not Character and self:IsLocalPlayer() then
			ClientBackpack:Clear()
		end
	end)

	--Client._requirements.InteractionService:EnableAll() -- TODO: ... че за пиздец

	-- listen to current player`s role
	if replica.Data.Role then
		self:SetRole( replica.Data.Role )
	end
	
	-- REPLICA
	-- replica role change connection
	replica:ListenToChange('Role', function( RoleEnum: number )
		self:SetRole(RoleEnum)
	end)
	
	-- score actions set
	self.ScoreActions = replica.Data.ScoreActions
	
	replica:ListenToArrayInsert('ScoreActions', function(_, Action: number)
		-- adding action to score
		print('Action registered:', GlobalSettings.Rewards[Action].Label)
	end)

	-- local player initialize
	if self:IsLocalPlayer() then
		--ControlsModule:InitCharacterControls()

		--[[ connections
		local connection_on_client_event = replica:ConnectOnClientEvent(function(ctx: string, ...)
			if ctx == 'character_stunned' then
				playerCharacterObject:Stun()
			end
		end)
		
		playerCharacterObject.HealthChanged:Connect(function( old_health, new_health: number )
			UI.gameplay_ui:PlayerStateSetHealth( old_health or 100, new_health or 100 )
		end)

		playerCharacterObject.StaminaChanged:Connect(function( new_stamina: number, max_stamina: number )
			UI.gameplay_ui:PlayerStateSetStamina( new_stamina, max_stamina )
		end)]]
	end

	-- pre-creating character object if model already exists
	if replica.Data.Character.Instance then
		ClientCharacter.new( replica.Data.Character.Instance )
	end

	-- character replica value listening
	replica:ListenToChange('Character.Instance', function( CharacterModel: Model? )
		if not CharacterModel then
			self.Character:Destroy()
			self.Character = nil
			self.CharacterChanged:Fire()

		else -- creating a new character locally
			ClientCharacter.new( CharacterModel )
		end
	end)

	-- destroying local player object
	replica:AddCleanupTask(function()
		self:Destroy()
	end)

	-- virtual init method call
	PlayerComponent.Init(self)
end

-- returns true if player is equal to Players.LocalPlayer
function ClientPlayer:IsLocalPlayer()
	return self.Instance == Players.LocalPlayer
end

-- Player oject destruction
function ClientPlayer:Destroy()
	if self.Character then
		self.Character:Destroy()
	end

	-- virtual :Destroy() method
	PlayerComponent.Destroy(self)
end


--// HANDLING

-- main player replicator
Client:AddConnection(ReplicaController.ReplicaOfClassCreated('ReplicaPlayerClassToken', function( Replica )
	ClientPlayer.new( Replica )
end), 'PlayerReplica')


--// Returner

return ClientPlayer