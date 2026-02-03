--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Roles = require(ReplicatedStorage.Shared.Data.Roles)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local LocalPlayer = Players.LocalPlayer
local BaseMatchState = Classes.CreateSingleton("BaseMatchState", true) :: Impl

--//Types

export type PlayersState = {
	Killers: { Player },
	Students: { Player },
	InGameCount: number,
	InMatchCount: number,
}

export type PlayerDamageInfo = {
	Amount: number,
	Origin: Vector3?,
	Damager: Player?,
}

export type Impl = {
	__index: Impl,

	IsImpl: (self: Singleton) -> boolean,
	GetName: () -> "BaseMatchState",
	GetExtendsFrom: () -> nil,

	IsPlayerAlive: (self: Singleton, player: Player) -> boolean,

	IsResults: (self: Controller) -> boolean,
	IsRound: (self: Controller) -> boolean,
	GetCurrentPhase: (self: Controller) -> string,
	IsPreparing: (self: Singleton) -> boolean,
	IsIntermission: (self: Singleton) -> boolean,
	GetPhaseTimePassed: (self: Singleton) -> number,
	GetPhaseRealTimePassed: (self: Singleton) -> number,
	
	GetPlayersState: (self: Singleton) -> PlayersState,
	GetAlivePlayers: (self: Singleton, byTeam: ("Student" | "Killer" | "Spectator")?, shouldExclude: boolean?) -> { Player? },

	new: () -> Singleton,
	OnConstruct: (self: Singleton) -> (),
	OnConstructServer: (self: Singleton) -> (),
	OnConstructClient: (self: Singleton) -> (),
}

export type Fields = {
	Janitor: Janitor.Janitor,
	
	CurrentPhase: ("Intermission" | "Round" | "Result")?,
	CurrentDuration: number,
	Countdown: number,
	Preparing: boolean,
	
	MatchEnded: Signal.Signal<string>,
	MatchStarted: Signal.Signal<string>,
	CountdownStepped: Signal.Signal<number>,
	PreparingChanged: Signal.Signal<boolean>,
	
	PlayerLoaded: Signal.Signal<Player>,
	PlayerDied: Signal.Signal<Player, {Player?}>,
	PlayerDamaged: Signal.Signal<Player, PlayerDamageInfo>,
	PlayerSpawned: Signal.Signal<Player, PlayerTypes.Character>,
	PlayersChanged: Signal.Signal<PlayersState>, -- triggered on any major player changes, like respawn/role config update/removal
	PlayerHealthChanged: Signal.Signal<Player, number, number>,
	
	_PhaseStartTimestamp: number,
}

export type Singleton = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Functions

local function CreateSingleton(name: string)
	local Singleton: Impl = Classes.CreateSingleton(name, false, BaseMatchState)

	function Singleton.new(controller: {any})
		assert(not Classes.ClassTables.Singletons[Singleton.GetName()], `{ Singleton.GetName() } singleton already exists`)

		local self = setmetatable({}, Singleton)
		Classes.ClassTables.Singletons[Singleton.GetName()] = self

		return self:_Constructor(controller) or self
	end

	return Singleton
end

--//Methods

function BaseMatchState.IsPreparing(self: Singleton)
	return self.Preparing
end

function BaseMatchState.IsResults(self: Singleton)
	return self.CurrentPhase == "Result"
end

function BaseMatchState.IsRound(self: Singleton)
	return self.CurrentPhase == "Round"
end

function BaseMatchState.GetCurrentPhase(self: Singleton)
	return self.CurrentPhase
end

function BaseMatchState.IsIntermission(self: Singleton)
	return self.CurrentPhase == "Intermission"
end

function BaseMatchState.GetPhaseRealTimePassed(self: Singleton)
	return workspace:GetServerTimeNow() - self._PhaseStartTimestamp
end

function BaseMatchState.GetPhaseTimePassed(self: Singleton)
	return self.CurrentDuration - self.Countdown
end

function BaseMatchState.IsPlayerAlive(self: Singleton, player: Player)
	
	--respawn check
	--if RunService:IsServer() then
		
	--	local PlayerComponent = ComponentsManager.Get(player, "PlayerComponent")
		
	--	if not PlayerComponent then
	--		return false
	--	end
		
	--	if PlayerComponent:IsRespawning() then
	--		return true
	--	end
	--end
	
	local Character = player.Character
	
	if not Character then
		return false
	end
	
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
	
	return Humanoid and Humanoid.Health > 0
end

function BaseMatchState.GetAlivePlayers(self: Singleton, byTeam: ("Student" | "Killer" | "Spectator")?, shouldExclude: boolean?)
	
	local alivePlayers = {}

	for _, player in ipairs(Players:GetPlayers()) do
		
		if not self:IsPlayerAlive(player) then
			continue
		end
		
		local isKiller = RolesManager:IsPlayerKiller(player)
		local isStudent = RolesManager:IsPlayerStudent(player)
		local isSpectator = RolesManager:IsPlayerSpectator(player)

		if byTeam then
			if shouldExclude then
				if (byTeam == "Killer" and isKiller) or
					(byTeam == "Student" and isStudent) or
					(byTeam == "Spectator" and isSpectator) then
					continue
				end
			else
				if (byTeam == "Killer" and not isKiller) or
					(byTeam == "Student" and not isStudent) or
					(byTeam == "Spectator" and not isSpectator) then
					continue
				end
			end
		end

		table.insert(alivePlayers, player)
	end

	return alivePlayers
end

function BaseMatchState.GetPlayersState(self: Singleton)
	
	local All = self:GetAlivePlayers()
	local Killers = self:GetAlivePlayers("Killer")
	local Students = self:GetAlivePlayers("Student")
	
	return {
		Killers = Killers,
		Students = Students,
		InGameCount = #Players:GetPlayers(),
		InMatchCount = #All,
	}
end

function BaseMatchState.OnConstruct(self: Singleton)
	
	--used to fire players changed events
	local function OnAnyPlayerUpdate()
		self.PlayersChanged:Fire(
			self:GetPlayersState()
		)
	end
	
	self.PlayerDied:Connect(OnAnyPlayerUpdate)
	self.PlayerSpawned:Connect(OnAnyPlayerUpdate)
	Players.PlayerRemoving:Connect(OnAnyPlayerUpdate)
end

function BaseMatchState.OnConstructClient(self: Singleton) end

function BaseMatchState.OnConstructServer(self: Singleton) end

function BaseMatchState._Constructor(self: Singleton)
	
	self.Janitor = Janitor.new()

	self.PlayerLoaded = Signal.new()
	self.PlayerDied = Signal.new()
	self.PlayerSpawned = Signal.new()
	self.PlayerDamaged = Signal.new()
	self.PlayersChanged = Signal.new()
	self.PlayerHealthChanged = Signal.new()
	
	self.MatchEnded = Signal.new()
	self.MatchStarted = Signal.new()
	self.CountdownStepped = Signal.new()
	self.PreparingChanged = Signal.new()

	self.Preparing = false
	self.Countdown = 0
	self.CurrentPhase = "Intermission"
	self.CurrentDuration = 0
	self.ObjectivesAmount = 0
	self.ObjectivesSolvedAmount = 0
	self._PhaseStartTimestamp = 0
	
	self:OnConstruct()

	if RunService:IsServer() then
		
		self:OnConstructServer()

	elseif RunService:IsClient() then
		
		self:OnConstructClient()
	end

	Classes.SingletonConstructed:Fire(self)
end

--//Returner

return {
	CreateSingleton = CreateSingleton,
}