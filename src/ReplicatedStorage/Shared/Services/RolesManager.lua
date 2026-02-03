--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Roles = require(ReplicatedStorage.Shared.Data.Roles)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)
local Characters = require(ReplicatedStorage.Shared.Data.Characters)
local GlobalSettings = require(ReplicatedStorage.Shared.Data.GlobalSettings)

local ThreadUtility = require(ReplicatedStorage.Shared.Utility.ThreadUtility)

local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil
local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil
local ClientProducer = RunService:IsClient() and require(ReplicatedStorage.Client.ClientProducer) or nil
local ServerProducer = RunService:IsServer() and require(ServerScriptService.Server.ServerProducer) or nil

--//Variables

local LocalPlayer = Players.LocalPlayer
local MorphsFolder = ReplicatedStorage.Assets.Morphs
local RolesManager = Classes.CreateSingleton("RolesManager") :: Impl

--//Types

export type Impl = {
	__index: Impl,

	IsImpl: (self: Singleton) -> boolean,
	GetName: () -> "RolesManager",
	GetExtendsFrom: () -> nil,
	
	IsPlayerKiller: (self: Singleton, player: Player) -> boolean,
	IsPlayerStudent: (self: Singleton, player: Player) -> boolean,
	IsPlayerSpectator: (self: Singleton, player: Player) -> boolean,
	
	GetPlayerRoleString: (self: Singleton, player: Player) -> string?,
	GetPlayerRoleConfig: (self: Singleton, player: Player) -> Roles.Role?,
	GetPlayerSkinName: (self: Singleton, player: Player, equippedForCharacter: string?) -> string?,
	GetPlayerCharacterName: (self: Singleton, player: Player, equippedForGroup: ("Anomaly"|"Teacher"|"Student")?) -> string?,

	new: () -> Singleton,
	OnConstruct: (self: Singleton) -> (),
	OnConstructServer: (self: Singleton) -> (),
	OnConstructClient: (self: Singleton) -> (),
	
	_BuildRoleConfig: (self: Singleton, player: Player, roleString: string, characterName: string, skinName: string) -> Roles.Role,
	_ApplyPlayerRoleConfig: (self: Singleton, player: Player, roleString: string?, characterName: string?, skinName: string?) -> (),
}

export type Fields = {
	
	PlayerRoleChanged: Signal.Signal<Player, Roles.Role>,
	PlayerRoleConfigChanged: Signal.Signal<Player, Roles.Role>,
}

export type Singleton = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Methods

function RolesManager.IsPlayerKiller(self: Singleton, player: Player)
	local RoleConfig = self:GetPlayerRoleConfig(player)
	return RoleConfig and RoleConfig.Team and RoleConfig.Team.Name == "Killer"
end

function RolesManager.IsPlayerStudent(self: Singleton, player: Player)
	local RoleConfig = self:GetPlayerRoleConfig(player)
	return RoleConfig and RoleConfig.Team and RoleConfig.Team.Name == "Student"
end

function RolesManager.IsPlayerSpectator(self: Singleton, player: Player)
	local RoleConfig = self:GetPlayerRoleConfig(player)
	return RoleConfig and RoleConfig.Team and RoleConfig.Team.Name == "Spectator"
end

function RolesManager.GetPlayerRoleConfig(self: Singleton, player: Player)
	
	if not player then
		return nil
	end
	
	--creating selector for this player
	local Producer = RunService:IsServer() and ServerProducer or ClientProducer.Root
	local RoleSelector = Selectors.SelectRoleConfig(player.Name)

	return Producer:getState(RoleSelector)
end

--[[

if provided "GroupName" then will be returned character selected for exact group.
If not provided "GroupName" then will be returned current player's character name from config (if exists)

]]
function RolesManager.GetPlayerCharacterName(self: Singleton, player: Player, equippedForGroup: ("Anomaly" | "Teacher" | "Student")?)
	
	local Producer = RunService:IsServer() and ServerProducer or ClientProducer.Root
	
	if equippedForGroup then
		
		local Mock = Producer:getState(Selectors.SelectMock(player.Name, "MockCharacter"))

		--mock character is higher priority
		if Mock and Mock ~= "" then
			return Mock
		end
		
		return Producer:getState(Selectors.SelectCharacter(player.Name, equippedForGroup))
	else
		local RoleConfig = self:GetPlayerRoleConfig(player)
		return RoleConfig and RoleConfig.CharacterName or nil
	end
end

--[[

if provided "EquippedForCharacter" then will be returned skin selected for exact character.
If not provided "EquippedForCharacter" then will be returned current player's skin name from config (if exists)

]]
function RolesManager.GetPlayerSkinName(self: Singleton, player: Player, equippedForCharacter: string?)
	
	local Producer = RunService:IsServer() and ServerProducer or ClientProducer.Root

	if equippedForCharacter then
		
		local Mock = Producer:getState(Selectors.SelectMock(player.Name, "MockSkin"))

		--mock skin is higher priority
		if Mock and Mock ~= "" then
			return Mock
		end
		
		return Producer:getState(Selectors.SelectSkin(player.Name, equippedForCharacter))
	else
		local RoleConfig = self:GetPlayerRoleConfig(player)
		return RoleConfig and RoleConfig.SkinName or nil
	end
end

function RolesManager.GetPlayerRoleString(self: Singleton, player: Player)
	local Producer = RunService:IsServer() and ServerProducer or ClientProducer.Root
	return Producer:getState(Selectors.SelectRole(player.Name))
end

function RolesManager._ApplyPlayerRoleConfig(self: Singleton, player: Player, roleString: string?, characterName: string?, skinName: string?)
	
	local SkinName = skinName
	local CharacterName = characterName
	local Producer = RunService:IsServer() and ServerProducer or ClientProducer.Root
	
	--we're taking Role as main config definition field (Role --> Character --> Skin)
	local Role = roleString or self:GetPlayerRoleString(player)
	assert(Role, `Attempted to apply { player.Name }'s role config without applied role`)
	assert(Roles[Role], `Provided role doesn't exist "{ Role }"`) -- fixed a typo -Provitia
	
	local Group = Roles[Role].Group :: string
	assert(Group, `No group defined for role { Role }`)
	
	--strict check only for other roles
	if Role ~= "Spectator" and RunService:IsServer() then
		
		--we do this on server cuz client always receives function args faster than Reflex replication
		
		CharacterName = characterName or self:GetPlayerCharacterName(player, Group)
		assert(CharacterName, `No character equipped for { player.Name } in group "{ Group }"`)
		
		SkinName = skinName or self:GetPlayerSkinName(player, CharacterName)
		assert(SkinName, `No any skin equipped for { player.Name } on character { CharacterName }`)
	end
	
	--skin just overrides default Character data fields
	if SkinName == ""or SkinName == "Default" then
		SkinName = nil
	end
	
	local Config = self:_BuildRoleConfig(player, Role, CharacterName, SkinName)
	
	--dispatching config data:
	Producer.ApplyRoleConfig(player.Name, Config)
	
	self.PlayerRoleConfigChanged:Fire(player, Config)
end

--in this method you can modify any role data! So useful
function RolesManager._BuildRoleConfig(self: Singleton, player: Player, roleString: string, characterName: string, skinName: string)
	
	local Producer = RunService:IsServer() and ServerProducer or ClientProducer.Root
	local RoleData = Roles[roleString] :: Roles.Role
	
	local CharacterData = Characters[characterName]
	local SkinData = CharacterData and CharacterData.Skins[skinName] or nil
	
	-- start with a fresh table and merge in order: RoleData <- CharacterData <- SkinData
	local Role = {} :: Roles.Role

	TableKit.DeepMerge(Role, RoleData or {})
	TableKit.DeepMerge(Role, CharacterData or {})
	TableKit.DeepMerge(Role, SkinData or {})
	
	--removing unnecessary data
	Role.Name = roleString
	Role.Description = RoleData.Description
	Role.Skins = nil -- no skins table
	Role.SkinName = SkinData and SkinData.Name or nil
	Role.DisplayName = RoleData.DisplayName
	Role.CharacterName = CharacterData and CharacterData.Name or nil
	
	--original data
	Role.Role = RoleData
	Role.Skin = SkinData
	Role.Character = CharacterData
	
	--moveset handling
	if Role.Group == "Teacher" then
		Role.MovesetName = characterName
	end
	
	--morph selection
	local RoleCharacters = MorphsFolder and MorphsFolder:FindFirstChild(Role.Group)
	local CharacterMorphs = RoleCharacters and RoleCharacters:FindFirstChild(Role.Character.Name)
	local Morph = CharacterMorphs and CharacterMorphs:FindFirstChild(Role.SkinName or "Default")
	
	--fallback
	if not Morph and Role.Name ~= "Spectator" then
		
		error(`No morph instance found for skin { Role.SkinName }; Character name: { Role.Character.Name }; Group name: { Role.Group }; Role name: { Role.Name }`)
		
	elseif Morph then
		
		Role.CharacterData.MorphInstance = Morph
	end
	
	--freeze config
	return table.freeze(Role)
end

function RolesManager.OnConstruct(self: Singleton)
	
	self.PlayerRoleChanged = Signal.new() --IMPORTANT: This event called from client/server MatchState cuz IM LAZY peace of shit and i didnt added player join/leave listening
	self.PlayerRoleConfigChanged = Signal.new()
end

function RolesManager.OnConstructClient(self: Singleton)
	
	--client builds all role configs from existing state
	for _, Player in pairs(Players:GetPlayers()) do
		
		local PlayerData = ClientProducer.Root:getState(
			Selectors.SelectPlayerData(Player.Name)
		)
		
		if not PlayerData then
			continue
		end
		
		self:_ApplyPlayerRoleConfig(Players:FindFirstChild(Player.Name))
	end
	
	local ReflexDataPromise: Promise.Promise
	
	--applies from event
	local function Apply(args)
		self:_ApplyPlayerRoleConfig(
			args.player,
			args.params.Role,
			args.params.Character,
			args.params.Skin
		)
	end	
	
	--real time updates
	ClientRemotes.RebuildRoleConfigClient.SetCallback(function(args)
		
		--cancelling on new event (kinda overwriting with new args)
		if ReflexDataPromise then
			ReflexDataPromise:cancel()
			ReflexDataPromise = nil
		end
		
		--initial state unexpected behavior
		if not ClientProducer.GetReflexData() then
			
			--some code that awaits till producer local player data will be added
			ReflexDataPromise = ClientProducer.Root:wait(
				
				Selectors.SelectPlayerData(LocalPlayer.Name)
				
			):finally(function(status)
				if status == "Resolved" then
					Apply(args)
				end
			end)
			
			return
		end
		
		--normal apply
		Apply(args)
	end)
end

--//Returner

local Singleton = RolesManager.new()
return Singleton :: Singleton