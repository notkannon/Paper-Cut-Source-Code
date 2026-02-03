--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

--//Imports

local Roles = require(ReplicatedStorage.Shared.Data.Roles)
local Enums = require(ReplicatedStorage.Shared.Enums)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local EnumUtil = require(ReplicatedStorage.Shared.Utility.EnumUtility)
local RoundTypes = require(ServerScriptService.Server.Types.RoundTypes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ServerRemotes = require(ServerScriptService.Server.ServerRemotes)
local ServerProducer = require(ServerScriptService.Server.ServerProducer)
local PlayerService = require(ServerScriptService.Server.Services.PlayerService)

local BaseMatchState = require(ReplicatedStorage.Shared.Classes.Abstract.BaseMatchState)

--//Variables

local MatchService = BaseMatchState.CreateSingleton("MatchService") :: Impl

--//Types

export type Impl = {
	__index: Impl,
	
	GetName: () -> "RoundsService",
	GetExtendsFrom: () -> nil,
	IsImpl: (self: Service) -> boolean,
	
	SetPreparing: (self: Service, value: boolean) -> (),
	SetCountdown: (self: Service, countdown: number, reason: string?) -> (),
	IncrementCountdown: (self: Service, factor: number, reason: string?) -> (),
	ToggleCountdown: (self: Service, state: boolean) -> (),
	
	IsPlayerKiller: (self: Singleton, player: Player) -> boolean,
	IsPlayerStudent: (self: Singleton, player: Player) -> boolean,
	IsPlayerSpectator: (self: Singleton, player: Player) -> boolean,
	
	IsRound: (self: Singleton) -> boolean,
	IsPreparing: (self: Singleton) -> boolean,
	IsIntermission: (self: Singleton) -> boolean,
	GetPhaseTimePassed: (self: Singleton) -> number,
	
	GetEngagedPlayers: (self: Singleton) -> {Player?},
	GetEngagedPlayerComponents: (self: Singleton) -> { any? },
	GetAlivePlayers: (self: Singleton, byTeam: ("Student" | "Killer")?) -> { Player? },
	--GetPlayerRoleString: (self: Singleton, player: Player) -> string?,
	--GetPlayerRoleConfig: (self: Singleton, player: Player) -> Roles.Role?,
	GetChanceSortedPlayers: (self: Service, group: "Default"|"Anomaly") -> { Player },
	GetPlayerChances: (self: Service, group: "Default"|"Anomaly") -> { { Player: Player, Chance: number } },
	
	HasPlayerRoundStats: (self: Service, player: Player) -> boolean,
	GetPlayersWithRoundStats: (self: Service) -> {Player?},
	GetPlayerComponentsWithRoundStats: (self: Service) -> {Player?},

	new: () -> Service,
	OnConstruct: (self: Service) -> (),
	OnConstructServer: (self: Service) -> (),
	OnConstructClient: (self: Service) -> (),

	_SetMap: (self: Service, Map: "Camping" | "School") -> (),
	_SetPhase: (self: Service, round: RoundTypes.AnyRound) -> (),
	_EndPhase: (self: Service, ignoreCountdown: boolean?) -> (),
	_NextPhase: (self: Service) -> (),
	_StartPhase: (self: Service, round: RoundTypes.AnyRound) -> (),
	_StartCountdown: (self: Service) -> (),
}

export type Fields = {
	
	CurrentPhase: RoundTypes.AnyRound?,
	DefaultPhase: RoundTypes.AnyRound?,
	DisablePhases: boolean,
	
	MapSelected: "Camping" | "School",
	SetMap: "Camping" | "School",

	Countdown: number,
	PhaseDuration: number,
	FreezeCountdown: boolean,
	
	_Rounds: {
		Intermission: RoundTypes.AnyRound,
		Round: RoundTypes.AnyRound,
	},
	
} & BaseMatchState.Fields

export type Service = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Methods

function MatchService.GetEngagedPlayers()
	local EngagedPlayers = {}
	for _, Player in Players:GetPlayers() do
		if MatchService.IsPlayerEngaged(Player) then
			table.insert(EngagedPlayers, Player)
		end
	end
	
	--	print("ENGAGED PLAYERS:", EngagedPlayers, #EngagedPlayers)
	
	return EngagedPlayers
end

function MatchService.GetEngagedPlayerComponents()
	local EngagedPlayerComponents = {}
	for _, component in ComponentsUtility.GetAllPlayerComponents() do
		if MatchService.IsPlayerEngaged(component.Instance) then
			table.insert(EngagedPlayerComponents, component)
		end
	end
	
	return EngagedPlayerComponents
end

function MatchService.GetPlayersWithRoundStats()
	local PlayersWhoPlayed = {}
	for _, Player in Players:GetPlayers() do
		if MatchService.HasPlayerRoundStats(Player) then
			table.insert(PlayersWhoPlayed, Player)
		end
	end
	
	return PlayersWhoPlayed
end

function MatchService.GetPlayerComponentsWithRoundStats()
	local PlayersComponent = {}
	for _, component in ComponentsUtility.GetAllPlayerComponents() do
		if MatchService.HasPlayerRoundStats(component.Instance) then
			table.insert(PlayersComponent, component)
		end
	end

	return PlayersComponent
end

function MatchService.HasPlayerRoundStats(player: Player)
	return ComponentsManager.GetFirstComponentInstanceOf(player, "PlayerRoundStats") ~= nil
end

function MatchService.IsPlayerEngaged(player: Player)
	-- engaged players are players who are not AFK, have loaded in and eligible to participate in a round
	-- TODO: add an AFK condition, if there's ever an AFK system
	local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(player)
	return PlayerComponent
		and PlayerComponent:IsLoaded()
end

function MatchService.IsRound(self: Service)
	return self.CurrentPhase.GetName() == "Round"
end

function MatchService.IsIntermission(self: Service)
	return self.CurrentPhase.GetName() == "Intermission"
end

--function MatchService.GetPlayerRoleConfig(self: Service, player: Player)
--	return RolesManager:GetPlayerRoleConfig(player)
--end

function MatchService.SetPreparing(self: Service, value: boolean)
	
	--no same calls
	if self.Preparing == value then
		return
	end
	
	self.Preparing = value
	self.PreparingChanged:Fire(value)
	ServerRemotes.MatchServiceSetPreparing.FireAll(value)
end

function MatchService.SetCountdown(self: Service, countdown: number, reason: string?)
	assert(typeof(countdown) == "number", "Countdown should be number")
	
	self.Countdown = countdown
	self.CountdownStepped:Fire(self.Countdown)
	
	ServerRemotes.MatchServiceCountdownChanged.FireAll({value = self.Countdown, reason = reason})
end

function MatchService.IncrementCountdown(self: Service, factor: number, reason: string?)
	assert(typeof(factor) == "number", "Factor should be a number")
	
	local NewValue = math.max(self.Countdown + factor, 0)
	
	self:SetCountdown(NewValue, reason)
end

function MatchService.GetRoundActivationState(self: Service)
	return MatchService.RoundStats[1] or "Loading"
end

function MatchService.ToggleCountdown(self: Service, value: boolean)
	self.FreezeCountdown = value
end

function MatchService._NextPhase(self: Service)
	if self.MatchesDisabled then
		return
	end
	
	assert(self.CurrentPhase, "No current round was set")

	local ToRound = self._Rounds[self.CurrentPhase.NextPhaseName] :: RoundTypes.AnyRound
	
	assert(ToRound, `No .NextPhaseName was set for round { self.CurrentPhase.GetName() }. Could not go to next round`)
	
	-- returning to Intermission in any of bad cases
	if not ToRound:ShouldStart() then
		
		if self.CurrentPhase == self.DefaultPhase then
			
			self:_StartPhase(self.CurrentPhase)
			
		else
			
			self:_SetPhase(self.DefaultPhase)
		end
		
		return
	end
	
	self:_SetPhase(ToRound)
end

function MatchService._SetPhase(self: Service, round: RoundTypes.AnyRound)
	self:_EndPhase()
	self:_StartPhase(round)
end

function MatchService._EndPhase(self: Service, ignoreCountdown: boolean?)
	
	if not ignoreCountdown then
		self.Janitor:Remove("CountdownSteps")
	end

	for _, Round in pairs(self._Rounds) do
		
		if Round:GetState() ~= Enums.RoundState.InProgress then
			continue
		end

		Round:End()
	end
end

function MatchService._SetMap(self: Service, Map: "Camping" | "School")
	print(Map, "MatchService")
	
	self.MapSelected = Map
	ServerRemotes.MatchServiceSetMap.FireAll(Map)
end

function MatchService._StartPhase(self: Service, round: RoundTypes.AnyRound)
--	print("Starting phase", round.GetName(), "current phase:", self.CurrentPhase)
	if self.CurrentPhase
		and type(self.CurrentPhase) ~= "string" -- for some reason on server startup current phase is actually a string what
		and self:IsRound()
		and round.GetName() == "Round" then
		error("ATTEMPTING TO CREATE ROUND TWICE! this is a critical bug - investigate the stack trace")
	end
	
	self.CurrentPhase = round
	
	round:Start()

	self.PhaseDuration = round.PhaseDuration
	self.Countdown = self.PhaseDuration
	self._PhaseStartTimestamp = workspace:GetServerTimeNow()
	
	self:_StartCountdown()
end

function MatchService._StartCountdown(self: Service)
	
	self.Janitor:Remove("CountdownSteps")
	self:SetCountdown(self.CurrentPhase.PhaseDuration)
	
	local LastTick = os.clock()
	
	self.Janitor:Add(RunService.Stepped:Connect(function()
		
		if self.FreezeCountdown then
			return
		end

		if (os.clock() - LastTick) < 1 then
			return
		end

		self:SetCountdown(math.max(0, self.Countdown - 1), "CountdownStep")

		LastTick = os.clock()

		if self.Countdown == 0 then
			
			self.Janitor:Remove("CountdownSteps")
			
			task.wait(1)
			
			self:_NextPhase()
		end
		
	end), nil, "CountdownSteps")
end

--function MatchService.GetPlayerRoleString(self: Service, player: Player)
--	return ServerProducer:getState(Selectors.SelectRole(player.Name))
--end

function MatchService.GetChanceSortedPlayers(self: Service, group: "Default"|"Anomaly")
	
	local Sorted = self:GetPlayerChances(group)
	
	table.sort(Sorted, function(a, b)
		return a.Chance > b.Chance
	end)
	
	local SortedPlayers = {}
	
	for _, Data in ipairs(Sorted) do
		table.insert(SortedPlayers, Data.Player)
	end

	return SortedPlayers
end

function MatchService.GetPlayerChances(self: Service, group: "Default"|"Anomaly")
	
	local PlayerChances = {}

	for _, Player in ipairs(self.GetEngagedPlayers()) do
		local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(Player)
		local Chance = PlayerComponent:GetChance(group)

		table.insert(PlayerChances, {
			Player = PlayerComponent.Instance,
			Chance = Chance,
		})
	end
	
	return PlayerChances
end

function MatchService._HandleDamageTaken(self: Service, data)
	
	--firing damage data globally
	ServerRemotes.DamageTaken.FireAll(data)
	
	--locally
	self.PlayerDamaged:Fire(data.player, {
		Damager = data.damager,
		Amount = data.damage,
		Origin = data.origin,
		Source = data.source
	})
end

function MatchService._InitEvents(self: Service)
	
	--handling character added
	PlayerService.PlayerLoaded:Connect(function(player)
		
		local PlayerComponent = ComponentsManager.Get(player, "PlayerComponent")
		local PlayerJanitor = PlayerComponent.Janitor:Add(Janitor.new())
	
		local function OnCharacterAdded(character)
			
			local Humanoid = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
			local PreviousHealth = Humanoid.Health
			
			--telling player has spawned
			self.PlayerSpawned:Fire(character, player)
			
			--health tracking
			PlayerJanitor:Add(Humanoid.HealthChanged:Connect(function(newHealth)

				self.PlayerHealthChanged:Fire(player, newHealth, PreviousHealth)

				PreviousHealth = newHealth
			end))

			--death handling
			PlayerJanitor:Add(Humanoid.Died:Once(function()
				
				local RoundStatsComponent = ComponentsManager.Get(player, "PlayerRoundStats")
				local KillerList = RoundStatsComponent and RoundStatsComponent:GetOrderedDamagersList() or nil

				--locally
				self.PlayerDied:Fire(player, KillerList)

				--replicated
				ServerRemotes.PlayerDied.FireAll({
					player = player,
					killers = KillerList,
				})
			end))
		end
		
		--data sync
		if self.FreezeCountdown then
			ServerRemotes.MatchServiceCountdownChanged.Fire(player, {value = self.Countdown, reason = "CountdownStep"}) -- the client-side doesnt know what time is it
		end
		
		if self.CurrentPhase.GetName ~= "Intermission" then
			ServerRemotes.MatchServiceSetMap.Fire(player, self.MapSelected)
		end
		
		ServerRemotes.MatchServiceSetPreparing.Fire(player, self:IsPreparing())
		ServerRemotes.MatchServiceSetMatchState.Fire(player, {
			name = self.CurrentPhase.GetName(),
			ended = false,
			duration = self.CurrentPhase.PhaseDuration,
			countdown = self.Countdown,
		})
		
		--role connection
		PlayerJanitor:Add(ServerProducer:subscribe(Selectors.SelectRole(player.Name), function(roleString)
			RolesManager.PlayerRoleChanged:Fire(player, RolesManager:GetPlayerRoleConfig(player))
		end))
		
		--handling player spawn and death
		PlayerJanitor:Add(PlayerService.CharacterAdded:Connect(function(character)
			
			if character ~= player.Character then
				return
			end
			
			OnCharacterAdded(character)
		end))
		
		if player.Character then
			OnCharacterAdded(player.Character)
		end
		
		for _, Player in self:GetEngagedPlayers() do
			if Player == player then return end
			
			ServerRemotes.LoadedConfirmed.Fire(player, Player)
		end
	end)
end

function MatchService.OnConstructServer(self: Service)
	
	self.MatchesDisabled = false
	self.SetMap = ""
	self.MapSelected = "School" -- hardcode booooo!!!
	self.FreezeCountdown = RunService:IsStudio()
	
	self._Rounds = {}
	
	--injecting sub-match modules
	for _, ImplModule: ModuleScript in ipairs(script:GetChildren()) do
		
		local Impl = require(ImplModule)
		local Round = Impl.new(self)

		Round.Started:Connect(function()
			self.MatchStarted:Fire(Round)
		end)

		Round.Ended:Connect(function()
			self.MatchEnded:Fire(Round)
		end)

		self._Rounds[Impl.GetName()] = Round
	end
	
	self:_InitEvents()
	
	--match bootstrap
	self.DefaultPhase = self._Rounds.Intermission
	self:_StartPhase(self._Rounds.Intermission)
end

--//Returner

local Singleton = MatchService.new()
return Singleton