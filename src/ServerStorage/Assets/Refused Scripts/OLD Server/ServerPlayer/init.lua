local Server = shared.Server

-- const
local DATA_LOAD_ERROR = 'Data loading went wrong. Try to reconnect. If you keep getting this message contact us in our Discord community server!'

-- service
local Teams = game:GetService('Teams')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local ServerWcsController = Server:Require(script.ServerWcsController)
local ServerCharacter = Server:Require(script.ServerCharacter)
local ServerBackpack = Server:Require(script.ServerBackpack)

local Enums = require(ReplicatedStorage.Enums)
local Signal = require(ReplicatedStorage.Package.Signal)
local GlobalSettings = require(ReplicatedStorage.GlobalSettings)
local ReplicaService = require(ServerStorage.Server.ReplicaService)
local ProfileService = require(ReplicatedStorage.Package.ProfileService)
local PlayerComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent)

-- vars
local PlayersRoles = GlobalSettings.Roles
local PlayerRolesEnum = Enums.GameRolesEnum
local playerActionType = Enums.PlayerActionType
local playerProfileTemplate = GlobalSettings.PlayerProfileTemplate

-- data struct
local PlayerClassToken = ReplicaService.NewClassToken('ReplicaPlayerClassToken')
local playerPrivateToken = ReplicaService.NewClassToken('ReplicaPrivateClassToken')
local playerProfileStore


--// INITIALIZATION
local ServerPlayer = setmetatable({}, PlayerComponent)
ServerPlayer.__index = ServerPlayer


-- test environment for studio will no save keys
playerProfileStore = ProfileService.GetProfileStore('Player', playerProfileTemplate)
if RunService:IsStudio() then playerProfileStore = playerProfileStore.Mock end


-- server constructor override
function ServerPlayer.new(player: Player)
	local Object = setmetatable(PlayerComponent.new(player), ServerPlayer)
	
	-- atempt to load Profile
	local Loaded, Profile = pcall(function()
		return playerProfileStore:LoadProfileAsync(
			'plr_'..player.UserId,
			'ForceLoad'
		)
	end)

	-- catching error in Profile loading
	if not Loaded then
		player:Kick( DATA_LOAD_ERROR )
		warn( Profile )
		return
	end
	
	-- profile loaded
	if Profile then
		Profile:AddUserId(player.UserId)
		Profile:Reconcile() -- applying Profile data structure (new fields e.g.)
		
		-- destroy player object and his variables on release
		Profile:ListenToRelease(function()
			local PlayerObject = ServerPlayer.GetObjectFromInstance( player )
			if not PlayerObject then return end -- we may already have destroyed this PlayerObject (if player left by himself)
			PlayerObject:Destroy()
		end)

		-- Loaded successfully
		if player:IsDescendantOf(Players) then
			Object.Profile = Profile
			
			Object:Init()
			return Object
		end
	end

	-- kick with error message
	player:Kick( DATA_LOAD_ERROR )
end

--// METHODS
-- object initialization
function ServerPlayer:Init()
	local player: Player = self.Instance

	-- backpack initialiation
	local BackpackObject = ServerBackpack.new( self )
	self.Backpack = BackpackObject
	BackpackObject:Init()

	-- global player`s data
	local SharedReplica = ReplicaService.NewReplica({
		ClassToken = PlayerClassToken,
		Tags = { Player = player },
		Replication = "All",
		Data = {
			Character = { Instance = nil },
			ScoreActions = { }
		}
	})

	-- local player`s data
	local PrivateReplica = ReplicaService.NewReplica({
		ClassToken = playerPrivateToken,
		Tags = { Player = player },
		Replication = player, -- individual
		Data = { Safe = self.Profile.Data }
	})

	-- setting new replicas to object
	self.PrivateReplica = PrivateReplica
	self.SharedReplica = SharedReplica
	
	self:ClearActions()
	
	-- leaderstats ig..
	local leaderstats = Instance.new('Folder', player)
	leaderstats.Name = 'leaderstats'
	self.leaderstats_reference = leaderstats
	
	for _k, _v in pairs(self.Profile.Data) do
		if type(_v) == 'table' then continue end
		local val = Instance.new('IntValue', leaderstats)
		val.Name = _k
		val.Value = _v
	end

	-- TODO: remove this further. Make NORMAL spawn system, maan
	table.insert(self._connections,
		self.CharacterChanged:Connect(function(character: Model?)
			if not character then return end -- was destroyed probably
			
			self.Character:GetHumanoid().Died:Connect(function()
				self:Despawn()
				task.wait(game.Players.RespawnTime)
				self:Respawn()
			end)
		end)
	)
	
	-- super initial
	PlayerComponent.Init(self)
end

-- prompt player to set role
function ServerPlayer:SetRole(source: string|number)
	PlayerComponent.SetRole(self, source)
	local Role = self.Role
	
	-- role replication
	self.SharedReplica:SetValue('Role',
		Role.enum
	)
end

-- inserts new action to player`s action history
function ServerPlayer:AddAction(actionEnum: number)
	assert(typeof(actionEnum) == "number")
	self.SharedReplica:ArrayInsert('ScoreActions', actionEnum)
end

-- clears all actions history
function ServerPlayer:ClearActions()
	table.clear(self.ScoreActions)
	self.SharedReplica:SetValue('ScoreActions', { })
	self.ScoreActions = self.SharedReplica.Data.ScoreActions
end

-- returns sum of points to award
function ServerPlayer:PredictAwardedPoints()
	local Points = 0
	
	-- calculating sum points
	for _, ActionEnum: number in ipairs(self.ScoreActions) do
		Points += GlobalSettings.Rewards[ ActionEnum ].Points
	end
	
	return Points
end

-- despawns player (backpack items saving & character object removal)
function ServerPlayer:Despawn()
	local player: Player = self.Instance
	local Backpack = self.Backpack
	
	-- character removal
	Backpack:Defer() -- saving items (deferring)
	self.Character:Destroy()
	self.Character = nil
	self.CharacterChanged:Fire(nil)
end

-- prompts player object to recreate character
function ServerPlayer:Respawn()
	local CharacterModel: Model?
	
	local player: Player = self.Instance
	local Backpack = self.Backpack
	local role = self.Role
	
	-- morph exists in role?
	if role.character.morph then
		CharacterModel = role.character.morph:Clone()
	end
	
	-- old? character removal
	if self.Character then
		self:Despawn()
	end
	
	-- getting default player character instance
	if not CharacterModel then
		player:LoadCharacter()
		CharacterModel = player.Character
		player.Character.Parent = workspace.Players
	else
		-- morph applying
		CharacterModel.Parent = workspace.Players
		player.Character = CharacterModel
	end
	
	-- creating new character
	self.Character = ServerCharacter.new(CharacterModel)
	self.CharacterChanged:Fire(self.Character)
	
	-- if spawned as student then restoring items
	if role.enum == PlayerRolesEnum.Student then
		Backpack:Reset()
		Backpack:Restore()
	end
end

-- Player destruction
function ServerPlayer:Destroy()
	self.Destroying:Fire()

	for _, connection: RBXScriptConnection in ipairs(self._connections) do
		connection:Disconnect()
	end
	
	table.remove(PlayerComponent._objects,
		table.find(PlayerComponent._objects,
			self
		)
	)
	
	-- character removal
	if self.Character then
		self.Character:Destroy()
	end
	
	self.SharedReplica:Destroy()
	self.PrivateReplica:Destroy()
	
	self.CharacterChanged:DisconnectAll()
	self.RoleChanged:DisconnectAll()
	self.Destroying:DisconnectAll()

	setmetatable(self, nil)
	table.clear(self)
end


--// CLEANUP
Players.PlayerRemoving:Connect(function( player: Player )
	local PlayerObject = ServerPlayer.GetObjectFromInstance( player )
	if not PlayerObject then return end -- player may have not been loaded
	PlayerObject.Profile:Release()
end)


return ServerPlayer