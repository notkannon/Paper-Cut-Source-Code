--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ServerRemotes = require(ServerScriptService.Server.ServerRemotes)
local DefaultPlayerData = require(ReplicatedStorage.Shared.Data.DefaultPlayerData)

local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local MapsManager = require(ServerScriptService.Server.Services.MapsManager)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ProfileService = require(ServerStorage.ServerPackages.ProfileService)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local ProfileStore = ProfileService.GetProfileStore("PlayerData", DefaultPlayerData.Save)
local PlayerService: Impl = Classes.CreateSingleton("PlayerService") :: Impl

if RunService:IsStudio() then
	--ProfileStore = ProfileStore.Mock
end

--//Types

export type Impl = {
	__index: Impl,

	GetName: () -> "PlayerService",
	GetExtendsFrom: () -> nil,
	IsImpl: (self: Service) -> boolean,

	new: () -> Service,
	OnConstructServer: (self: Service) -> (),
	OnPlayerRespawn: (self: Service, player: Player, character: Model) -> (),

	LoadProfile: (Player) -> Promise.TypedPromise<ProfileService.Profile<DefaultPlayerData.SaveData, {}, {}>>,
	GetLoadedPlayerList: (self: Service) -> { Player? },
}

export type Fields = {
	PlayerLoaded: Signal.Signal<Player>,
	PlayerAdded: Signal.Signal<Player>,
	PlayerRemoving: Signal.Signal<Player>,
	CharacterAdded: Signal.Signal<PlayerTypes.Character, Player>,
	CharacterRemoved: Signal.Signal<PlayerTypes.Character, Player>,
}

export type Service = typeof(setmetatable({} :: Fields, PlayerService :: Impl))

--//Methods

function PlayerService.OnPlayerRespawn(self: Service, player: Player, character: PlayerTypes.Character)
	
	local SpawnPoint = workspace.Lobby:FindFirstChildWhichIsA("SpawnLocation")
	
	if RolesManager:IsPlayerSpectator(player) then
		
		character:PivotTo(CFrame.new(SpawnPoint.Position + Vector3.new(0, 3, 0)))
		
	else
		--round related stuff?
		local Spawns = MapsManager:GetSpawnLocationsFor(player)
		print(Spawns, 'spawns for', player)
		
		if Spawns and #Spawns == 0 then
			--fallback on unexpected things
			warn(`Attempted to assign { player.Name }'s' spawn location on map, but no spawns available.`)
			
		elseif Spawns then
			SpawnPoint = Spawns[ math.random(1, #Spawns) ]
		end
	end
	
	-- SpawnPoint can be either CFrame or SpawnLocation, because all we need is its .Position, which both have
	
	--assign to spawn location
	character:PivotTo(CFrame.new(SpawnPoint.Position + Vector3.new(0, 3, 0)))
end

function PlayerService.GetLoadedPlayerList(self: Service)
	return ComponentsManager.GetInstances("PlayerComponent")
end

function PlayerService.LoadProfile(player: Player)
	return Promise.new(function(resolve, reject)
		
		local Profile = ProfileStore:LoadProfileAsync(`Player_{player.UserId}`)
		
		if not Profile then
			reject("Failed to load profile. Profile does not exist.")
		end

		Profile:AddUserId(player.UserId)
		Profile:Reconcile()

		Profile:ListenToRelease(function()
			player:Kick("Profile was released.")
		end)

		if not player:IsDescendantOf(Players) then
			Profile:Release()
			reject("Failed to load profile. Player is not a descendant of Players.")
		end

		resolve(Profile)
	end)
end

function PlayerService.OnConstructServer(self: Service)
	
	self.PlayerAdded = Signal.new()
	self.PlayerLoaded = Signal.new()
	self.PlayerRemoving = Signal.new()
	self.CharacterAdded = Signal.new()
	self.CharacterRemoved = Signal.new()
	
	ServerRemotes.Loaded.SetCallback(function(player: Player)
		local PlayerComponent = ComponentsManager.Get(player, "PlayerComponent")
		
		if not PlayerComponent or PlayerComponent:IsLoaded() then
			return
		end
		
		PlayerComponent._IsLoaded = true
		
		PlayerComponent:SetRole("Spectator")
		PlayerComponent:ResetCharacterMockData()
		PlayerComponent:ApplyRoleConfig(true)
		
		ServerRemotes.LoadedConfirmed.FireAll(player)
		self.PlayerLoaded:Fire(player)
	end)
	
	--probably useless code part cuz we mved to lobby system without menu
	ServerRemotes.SpawnRequest.SetCallback(function(player: Player) end)
	
	ServerRemotes.ClientLookVectorChanged.SetCallback(function(player: Player, direction: Vector3)
		
		if not player.Character then
			return
		end
		
		local AppearanceComponent = ComponentsManager.GetFirstComponentInstanceOf(player.Character, "BaseAppearance")
		
		if not AppearanceComponent then
			return
		end

		ServerRemotes.ServerLookVectorReplicated.FireExcept(player, {
			player = player,
			lookDirection = direction,
			componentName = AppearanceComponent.GetName(),
		})
	end)
	
	Players.PlayerAdded:Connect(function(player)
		
		ComponentsManager.Add(player, "PlayerComponent")
		
		self.PlayerAdded:Fire(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		
		ComponentsManager.Remove(player, "PlayerComponent")
		
		self.PlayerRemoving:Fire(player)
	end)
	
	ComponentsManager.ComponentAdded:Connect(function(component)
		
		if component.GetName() ~= "CharacterComponent" then
			return
		end
		
		local Player = Players:GetPlayerFromCharacter(component.Instance)
		local Character = component.Instance :: PlayerTypes.Character
		local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(Player)
		local MatchService = Classes.GetSingleton("MatchService")
		
		--removing respawn task cuz already respawned
		PlayerComponent.Janitor:Remove("RespawnTask")
		
		self:OnPlayerRespawn(Player, Character)
		
		self.CharacterAdded:Fire(Character, Player)
		
		--respawning player after death
		component.Janitor:Add(MatchService.PlayerDied:Connect(function(player: Player)
			
			if player ~= Player then
				return
			end
			
			--respawning as spectator or setting player's role
			if not PlayerComponent:IsSpectator() then
				
				PlayerComponent.Janitor:Add(
					
					task.delay(Players.RespawnTime, function()
						
						PlayerComponent:SetRole("Spectator")
						PlayerComponent:ApplyRoleConfig(true)
					end),
					
					nil,
					"RespawnTask"
				)
				
			else
				
				PlayerComponent.Janitor:Add(
					task.delay(
						Players.RespawnTime,
						PlayerComponent.Respawn,
						PlayerComponent
					),
					
					nil,
					"RespawnTask"
				)
			end
		end))
		
		component.Janitor:Add(function()
			self.CharacterRemoved:Fire(Character, Player)
		end)
	end)
end

--//Returner

local Singleton = PlayerService.new() :: Service
return Singleton