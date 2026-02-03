--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Roles = require(ReplicatedStorage.Shared.Data.Roles)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)
local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)
local ClientProducer = require(ReplicatedStorage.Client.ClientProducer)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local BaseMatchState = require(ReplicatedStorage.Shared.Classes.Abstract.BaseMatchState)

--//Variables

local LocalPlayer = Players.LocalPlayer
local MatchStateClient = BaseMatchState.CreateSingleton("MatchStateClient") :: Impl

--//Types

export type Impl = {
	__index: typeof(setmetatable({} :: Impl, {} :: BaseMatchState.Impl)),
	
	IsImpl: (self: Controller) -> boolean,
	GetName: () -> "MatchStateClient",
	GetExtendsFrom: () -> nil,
	
	new: () -> Controller,
	OnConstruct: (self: Controller) -> (),
	OnConstructClient: (self: Controller) -> (),
	
	IsPlayerAlive: (self: Controller, player: Player) -> boolean,
	IsPlayerKiller: (self: Controller, player: Player) -> boolean,
	IsPlayerStudent: (self: Controller, player: Player) -> boolean,
	IsPlayerSpectator: (self: Controller, player: Player) -> boolean,
	
	IsPlayerLoaded: (self: Controller, player: Player) -> boolean, 
	IsPlayerEngaged: (self: Controller, player: Player) -> boolean,
	
	IsPreparing: (self: Controller) -> boolean,
	IsIntermission: (self: Controller) -> boolean,
	GetPhaseTimePassed: (self: Controller) -> number,

	GetAlivePlayers: (self: Controller, byTeam: ("Student" | "Killer")?) -> { Player? },
	GetPlayersEngaged: (self: Controller) -> { Player? },
	GetPlayerRoleString: (self: Controller, player: Player) -> string?,
	GetPlayerRoleConfig: (self: Controller, player: Player) -> Roles.Role?,
	
	_InitEvents: (self: Controller) -> (),
	_IsPlayerTeam: (self: Controller, player: Player, teamString: string) -> boolean,
	_SubscribePlayerState: (self: Controller, player: Player) -> (),
	_UnsubscribePlayerState: (self: Controller, player: Player) -> (),
	
} & BaseMatchState.Impl

export type Fields = BaseMatchState.Fields & {
	CurrentMap: string?, 
	PlayersLoaded: {Player?},
	PlayerHealthChanged: Signal.Signal<Player, number, number>
}

export type Controller = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Methods

function MatchStateClient.IsPlayerEngaged(self: Controller, player: Player)
	local Valid = false
	
	if self.PlayersLoaded[player] then
		Valid = true
	end
	
	return Valid
end

function MatchStateClient.GetPlayersEngaged(self: Controller)
	return TableKit.DeepCopy(self.PlayersLoaded)
end

function MatchStateClient.GetPlayerRoleString(self: Controller, player: Player)
	return ClientProducer.Root:getState(Selectors.SelectRole(player.Name))
end

function MatchStateClient._UnsubscribePlayerState(self: Controller, player: Player)
	if self._SubscribedPlayerListeners[player] then
		--destroying janitor binded to provided player
		self._SubscribedPlayerListeners[player]:Destroy()
		self._SubscribedPlayerListeners[player] = nil
		
	elseif self.PlayersLoaded[player] then
		self.PlayersLoaded[player] = nil
	end
end

function MatchStateClient._SubscribePlayerState(self: Controller, player: Player)
	
	local Janitor = Janitor.new()
	
	--called on player spawn
	local function OnCharacterAdded(character)
		
		local Humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local PreviousHealth = Humanoid.Health
		
		--telling player has spawned
		self.PlayerSpawned:Fire(player, character)
		
		--health tracking
		Janitor:Add(Humanoid.HealthChanged:Connect(function(newHealth)
			print(newHealth)
			self.PlayerHealthChanged:Fire(player, newHealth, PreviousHealth)
			
			PreviousHealth = newHealth
		end))
	end
	
	--binding janitor to a player
	self._SubscribedPlayerListeners[player] = Janitor
	
	if player.Character then
		OnCharacterAdded(player.Character)
		
		if table.find(self.PlayersLoaded, player) then
			return
		end

		table.insert(self.PlayersLoaded, player)
	end
	
	--subscribing to player role changes
	Janitor:Add(
		
		ClientProducer.Root:subscribe(
			
			Selectors.SelectRole(player.Name),
			
			function(roleString)
				RolesManager.PlayerRoleChanged:Fire(player, RolesManager:GetPlayerRoleConfig(player))
			end
		)
	)
	
	--character stuff
	Janitor:Add(player.CharacterAdded:Connect(OnCharacterAdded))
end

function MatchStateClient._InitEvents(self: Controller)
	
	--subscribing to new players
	Players.PlayerAdded:Connect(function(player)
		self:_SubscribePlayerState(player)
	end)
	
	--unsubscribing left players
	Players.PlayerRemoving:Connect(function(player)
		self:_UnsubscribePlayerState(player)
	end)
	
	--subscribing existing players
	for _, Player in ipairs(Players:GetPlayers()) do
		self:_SubscribePlayerState(Player)
	end
	
	--damage events
	ClientRemotes.DamageTaken.On(function(args)
		self.PlayerDamaged:Fire(args.player, {
			Damager = args.damager,
			Amount = args.damage,
			Origin = args.origin,
		})
	end)
	
	--death handling
	ClientRemotes.PlayerDied.On(function(args)
		self.PlayerDied:Fire(args.player, args.killers)
	end)
	
	--preparing state connection
	ClientRemotes.MatchServiceSetPreparing.SetCallback(function(value)
		self.Preparing = value
		self.PreparingChanged:Fire(value)
	end)
	
	--round state connection
	ClientRemotes.MatchServiceSetMatchState.SetCallback(function(args)
		
		if not args.ended then
			
			self.CurrentPhase = args.name
			self.CurrentDuration = args.duration
			self.MatchStarted:Fire(args.name)
			
		else
			
			self.MatchEnded:Fire(args.name)
			self.Janitor:Cleanup()
		end
	end)
	
	ClientRemotes.MatchServiceSetMap.On(function(Map)
		print(Map)
		if not Map then
			return
		end
		
		self.CurrentMap = Map
	end)
	
	--round countdown state
	ClientRemotes.MatchServiceCountdownChanged.SetCallback(function(data)
		self.Countdown = data.value
		self.CountdownStepped:Fire(data.value, data.reason)
		
		
	end)
	
	ClientRemotes.LoadedConfirmed.SetCallback(function(Player)
		if table.find(self.PlayersLoaded, Player) then
			return
		end

		table.insert(self.PlayersLoaded, Player)
		
		self.PlayerLoaded:Fire(Player)
		print("Loaded confirmed to "..Player.Name, self.PlayersLoaded)
	end)
	
	Players.PlayerRemoving:Connect(function(Player)
		table.remove(self.PlayersLoaded, 
			table.find(self.PlayersLoaded, Player)
		)
	end)
end

function MatchStateClient.OnConstructClient(self: Controller)
	
	self.PlayerHealthChanged = Signal.new()	

	self.PlayersLoaded = {}
	self._SubscribedPlayerListeners = {}
	
	self:_InitEvents()
end

--//Returner

local Controller = MatchStateClient.new()
return Controller