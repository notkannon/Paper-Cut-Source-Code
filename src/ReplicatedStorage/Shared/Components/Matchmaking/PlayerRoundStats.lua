--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Enums = require(ReplicatedStorage.Shared.Enums)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)
local PointsData = require(ReplicatedStorage.Shared.Data.Points)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ThrowablesService = require(ReplicatedStorage.Shared.Services.ThrowablesService)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)

local ServerProducer = RunService:IsServer() and require(ServerScriptService.Server.ServerProducer) or nil
local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil
local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil

local WCS = require(ReplicatedStorage.Packages.WCS)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)

local ChaseReplicator = RunService:IsServer() and require(ServerScriptService.Server.Services.ChaseReplicator) or nil

-- for hardcoding :sob:
local Characters = require(ReplicatedStorage.Shared.Data.Characters)
local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)

-- here put events that use the exact same template function
local GenericPointRewards = {
	-- un-used
	--VaultOpened = {Action = Enums.PlayerActionsEnum.Vault, Type = "Others", Reward = 5, Message = "Opened a vault"},
	--VaultStarted = {Action = Enums.PlayerActionsEnum.Vault, Type = "Others", Reward = 5, Message = "Vaulted"},
	--DoorUnlocked = {Action = Enums.PlayerActionsEnum.UnlockDoor, Reward = 1, Message = "Opened a door"},
	--RunnerDashed = {Action = Enums.PlayerActionsEnum.Dash, Type = "Abilities", Reward = 10, Message = "Used Evade"},
	--Stealthed = {Action = Enums.PlayerActionsEnum.Stealth, Type = "Abilities", Reward = 10, Message = "Used Stealth"},
	
	-- action is deprecated, dont bother adding it in!
	
	--// Chase \\--
	VaultClosed = {Action = Enums.PlayerActionsEnum.Vault, Type = "Discipline", Reward = 5, Message = "Closed a vault", Cap = 10},
	DoorSlammed = {Action = Enums.PlayerActionsEnum.DamageDoor, Type = "Chase", Reward = 5, Message = "Slammed a door", Cap = 5},
	DoorDamaged = {Action = Enums.PlayerActionsEnum.DamageDoor, Type = "Chase", Reward = 5, Message = "Damaged a door", Cap = 5},
	DoorHarpooned = {Action = Enums.PlayerActionsEnum.DamageDoor, Type = "Chase", Reward = 3, Message = "Harpooned a door", Cap = 5},
	
	--// Abilities Circle \\--
	ShockwaveSlowed = {Action = Enums.PlayerActionsEnum.Ability, Type = "Chase", Reward = 15, Message = "Slowed a student with Shockwave", Cap = 10},
	ShockwaveClosed = {Action = Enums.PlayerActionsEnum.Ability, Type = "Discipline", Reward = 10, Message = "Closed a vault with Shockwave", Cap = 10},
	ShockwaveLockerKicked = {Action = Enums.PlayerActionsEnum.Ability, Type = "Discipline", Reward = 10, Message = "Kicked a student out of a locker with Shockwave", Cap = 5},
	
	--// Abilities Thavel \\--
	ThavelProgressivePunishmentMax = {Action = Enums.PlayerActionsEnum.HitPlayer, Type = "Chase", Reward = 35, Message = "Completed combo", Cap = 5},
	ThavelProgressivePunishmentIncrease = {Action = Enums.PlayerActionsEnum.HitPlayer, Type = "Chase", Reward = 10, Message = "Increased combo", Cap = 25},
	ThavelProgressivePunishmentStart = {Action = Enums.PlayerActionsEnum.HitPlayer, Type = "Chase", Reward = 10, Message = "Started combo", Cap = 10},
	
	--// Abilities Bloomie \\--
	StealthBloomieNaturalEnd = {Action = Enums.PlayerActionsEnum.Ability, Type = "Discipline", Reward = 10, Message = "Stayed in Stealth until the end", Cap = 5},

	--// Abilities Others \\--
	BleedingInflicted = {Action = Enums.PlayerActionsEnum.HitPlayer, Type = "Chase", Reward = 3, Message = "Bleeding inflicted", Cap = 50},
	StudentPulledOutOfLocker = {Action = Enums.PlayerActionsEnum.Ability, Type = "Discipline", Reward = 15, Message = "Found a student in locker", Cap = 5},
	
	--// Others \\--
	StealthBloomieSneakAttack = {Action = Enums.PlayerActionsEnum.HitPlayer, Type = "Chase", Reward = 20, Message = "Landed a Sneak Attack", Cap = 3},
	LockerHidingSuccessful = {Action = Enums.PlayerActionsEnum.LeaveLocker, Type = "Utility", Reward = 15, Message = "Successfully hid in locker", Cap = 3}
} :: {[string]: {Action: PlayerActionsEnum, Type: ActionTypes, Reward: number, Message: string}}

--//Variables

local Player = Players.LocalPlayer
local PlayerRoundStats = BaseComponent.CreateComponent("PlayerRoundStats", {
	
	isAbstract = false,
	predicate = function(instance)
		print(RunService:IsClient(), instance, Player.Character)
		return RunService:IsClient() and instance == Player.Character
	end,

}, SharedComponent) :: Impl

--//Types

type PlayerActionsEnum = typeof(Enums.PlayerActionsEnum)

export type ActionTypes = "Objectives" | "Abilities" | "Others" | "Chase" | "Survival"

export type ClientAwardsType = {
	[string]: number
}

export type MyImpl = {
	__index: MyImpl,
	CreateEvent: SharedComponent.CreateEvent<Component>,
	
	AwardPoints: (self: Component, type: ActionType, amount: number, action: string, cap: number?) -> (),
	GetAwardData: (self: Component, awardName: string) -> ClientAwardsType? | number?,
	GetLastDamageInfo: (self: Component) -> any,
	GetOrderedDamagersList: (self: Component) -> { Player? },
	
	OnConstruct: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
	OnConstructServer: (self: Component) -> (),

	UpdateAwardsToClient: (self: Component) -> (),

	_InitEventsServer: (self: Component) -> (),
	_InitDamageEventsServer: (self: Component) -> (),
	
	ProcessRoundEnd: (self: Component, students: {Player?}, teachers: {Player}) -> (),
	
	_StopTracking: (self: Component) -> (),
	_IsActive: (self: Component) -> boolean,
	GetSurvivalTime: (self: Component) -> number
}

export type Fields = {
	
	PointsGained: number,
	PlayerJanitor: Janitor.Janitor,
	
	Kills: number,
	Deaths: number,
	DamageTaken: number,
	DamageDealed: number,
	TasksCompleted: number?,
	
	Damagers: { Player? },			-- a players (killers) who dealed any damage to current player in a queue
	PlayersKilled: { Player? },
	PlayersDamaged: { Player? },
	
	_Stats: { [string]: ClientAwardsType },
	_AwardMap: {[string]: {Cap: number, Reward: number}}, -- message: point cost, for example { ["Slowed a student with shockwave"] = {Cap = 5, Reward = 15} }. Built dynamically
	_LastDamageInfo: unknown,
	--_InternalSavePointsListener: SharedComponent.ServerToClient<ClientAwardsType>, UnUsed
	_InternalClientListener: SharedComponent.ServerToClient,
	
	StartTimestamp: number,
	EndTimestamp: number?
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "PlayerRoundStats", Player>
export type Component = BaseComponent.Component<MyImpl, Fields, "PlayerRoundStats", Player>

--//Functions

local function AddAtTableStart(subject: unknown, t: { unknown })
	local Indexed = table.find(t, subject)

	if Indexed then
		table.remove(t, Indexed)
	end

	table.insert(t, 1, subject)
end

--//Methods

function PlayerRoundStats.GetAwardData(self: Component, awardName: string)
	local Data = self._Stats[awardName]
	
	return Data ~= nil and Data or 0
end

function PlayerRoundStats.AwardPoints(self: Component, type: ActionTypes, amount: number, message: string, cap: number)
	assert(RunService:IsServer())
	assert(type and amount and message)
	
	if not self._Stats.Others[type] then
		self._Stats.Others[type] = {}
	end
	
	if not self._Stats.Others[type][message] then
		self._Stats.Others[type][message] = 0
	end
	
	if cap and self._Stats.Others[type][message] >= cap then
		return
	end
	
	self._Stats.Others[type][message] += 1
	
	if self._AwardMap[message] then
		assert(cap == self._AwardMap[message].Cap, `Inconsistent cap detected for award: '{message}'. Expected: {self._AwardMap[message].Cap}, gotten: {cap}`)
		assert(amount == self._AwardMap[message].Reward, `Inconsistent amount detected for award: '{message}'. Expected: {self._AwardMap[message].Reward}, gotten: {amount}`)
	else
		self._AwardMap[message] = {}
	end
	
	self._AwardMap[message] = {Cap = cap, Reward = amount}
	
	
	--print(self._Stats.Others[type][message], "Awarded to Player")
	
	local Message = string.format("+%s Points: %s", amount, message)

	self.PointsGained += amount

	--getting player's stats
	local CurrentStats = ServerProducer:getState(Selectors.SelectStats(self.Instance.Name))
	
	--updating player's points data
	ServerProducer.UpdatePlayerStats(
		self.Instance.Name,
		"Points",
		CurrentStats.Points + amount
	)
	
	--TODO
	--umm its like an action..? Probably remake with:
	--ServerRemotes.ServerPlayerActionCallback.Fire(...)
	ServerRemotes.PointsAwarded.Fire(
	 	self.Instance,
		{
			actionId = actionId,
			message = Message,
			amount = amount,
		}
	)
	
	self._Stats.Total += amount
	print(self.PointsGained, self._Stats.Total)
end

function PlayerRoundStats.GetLastDamageInfo(self: Component)
	
end

function PlayerRoundStats.GetOrderedDamagersList(self: Component)
	return table.clone(
		self.Damagers
	)
end

function PlayerRoundStats._InitDamageEventsServer(self: Component)
	assert(RunService:IsServer())
	
	local MatchService = Classes.GetSingleton("MatchService")
	local PlayerService = Classes.GetSingleton("PlayerService")
	
	local PlayerComponent = ComponentsManager.Get(self.Instance, "PlayerComponent")
	local CharacterComponent
	
	local function RebuildCharacterEvents()
		if not CharacterComponent then
			self.PlayerJanitor:Cleanup()
			return
		end

		CharacterComponent.Janitor:Add(CharacterComponent.Humanoid.HealthChanged:Connect(function()
			print("Health Changed")
			self._Stats.Health = CharacterComponent.Humanoid.Health
		end))
		
		--CharacterComponent.Janitor:Add(function()
		--	CharacterComponent = nil
		--	RebuildCharacterEvents()
		--end)
	end
	
	self.Janitor:Add(PlayerService.CharacterAdded:Connect(function(_, Player)
		if Player ~= self.Instance then
			return
		end
		
		CharacterComponent = PlayerComponent.CharacterComponent
		print(CharacterComponent)
		
		RebuildCharacterEvents()
	end))
	
	self.Janitor:Add(PlayerService.CharacterRemoved:Connect(function(_, Player)
		if Player ~= self.Instance then
			return
		end
		
		CharacterComponent = nil
		RebuildCharacterEvents()
	end))
	
	
	--self.PlayerJanitor:Add(PlayerService.CharacterAdded:Connect(function(Character, Player)
	--	if Player ~= self.Instance then
	--		return
	--	end
		
	--	local Humanoid = Character:FindFirstChild("Humanoid") :: Humanoid
	--	self.PlayerJanitor:Add(Humanoid.HealthChanged:Connect(function()
	--		print(Humanoid.Health)
			
	--		self._Stats.Health = Humanoid.Health
	--		if Humanoid.Health == 0 then
	--			self.PlayerJanitor:Remove("__HealthCharacterConnection")
	--		end
			
	--	end), nil, "__HealthCharacterConnection")
	--end))
	
	--self.Janitor:Add(PlayerService.CharacterRemoved:Connect(function(Character, Player)
	--	if Player ~= self.Instance then
	--		return
	--	end
		
		
	--end))
	
	--print(CharacterComponent, PlayerComponent)
	--self.PlayerJanitor:Add(Humanoid.HealthChanged:Connect(function()
	--	print(Humanoid.Health, "HealthChanged")
	--end))
	
	--self.PlayerJanitor:Add(Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
	--	print(Humanoid.Health, "GetPropertyChangedSignal")
	--end))
	
	--handling any death cases related to current player
	self.Janitor:Add(MatchService.PlayerDied:Connect(function(subject, killers: { Player }?)
		
		--played has died.
		if subject == self.Instance then
			local IsKiller = RolesManager:IsPlayerKiller(subject)
			if IsKiller then
				return -- doesnt will account the killer deaths unless we make smth will kill it
			end
			
			self._Stats.Deaths += 1
			--self:AwardPoints(Enums.PlayerActionsEnum.Died, 5, "Match result: Dead")
			
			self:_StopTracking()
			
		elseif killers and killers[1] == self.Instance then -- checking if player is the last source of damage
			
			--player killed someone
			
			self._Stats.Kills += 1
			
			AddAtTableStart(subject, self.PlayersKilled)
			
			self:AwardPoints("Brutality", 35, "Killed a student", 12)
		end
	end))
	
	--handling multiple damage cases (current player damaged, other player damaged by current and etc.)
	self.Janitor:Add(MatchService.PlayerDamaged:Connect(function(subject, damageInfo)
		print(subject, damageInfo)
		if subject == self.Instance then
			-- current player took damage

			--self._Stats.Health
			self.DamageTaken += damageInfo.Amount
			
			if damageInfo.Damager then
				AddAtTableStart(damageInfo.Damager, self.Damagers)
			end
			
			
		elseif damageInfo.Damager == self.Instance then
			-- current player damaged someone
			
			self.DamageDealed += damageInfo.Amount
			
			AddAtTableStart(subject, self.PlayersDamaged)
			
			if damageInfo.Source == "Harpoon" then
				if damageInfo.Amount == Characters.MissCircle.SkillsData.Harpoon.Damage then
					self:AwardPoints("Chase", 15, "Harpooned a Student", 10)
				else
					self:AwardPoints("Chase", 5, "Student escaped the harpoon", 10)
				end
			else
				self:AwardPoints("Chase", 10, "Hit a Student", 50)
			end
		end
	end))
end

--function PlayerRoundStats.UpdateAwardsToClient(self: Component)
--	assert(RunService:IsServer())
	
--	local CurrentData = self._Stats
--	self._InternalSavePointsListener.Fire(self.Instance, CurrentData)
--end

function PlayerRoundStats._IsActive(self: Component)
	return self.EndTimestamp == nil or self.EndTimestamp < self.StartTimestamp
end

function PlayerRoundStats._StopTracking(self: Component)
	if self:_IsActive() then
		self.EndTimestamp = os.clock()
	end
end

function PlayerRoundStats._InitEventsServer(self: Component)
	self:_InitDamageEventsServer()
	
	--throwables stuff
	self.Janitor:Add(ThrowablesService.Hit:Connect(function(data, hit)
		
		--filtering only current player
		if data.Performer ~= self.Instance then
			return
		end
		
		local Player = hit:IsA("Player") and hit
		
		if not Player or not RolesManager:IsPlayerKiller(Player) then
			return
		end
		
		local WCSCharacter = WCS.Character.GetCharacterFromInstance(Player.Character)
		
		if WCSUtility.HasActiveStatusEffectsWithNames(WCSCharacter, { "Stunned" }) then
			return
		end
		
		ProxyService:AddProxy("ValidStun"):Fire(self.Instance, Player)
		
		local RoleString = RolesManager:GetPlayerRoleString(Player)
		
		self:AwardPoints("Utility", 15, if RoleString == "Teacher" then "Stunned a Teacher" else "Stunned an Anomaly", 4)
	end))
	
	-- round stuff
	-- TODO: Students: survive the round, survive the lms; Teachers: end round with everyone dead, with 1 survivor alive, with more than 1 alive
	local MatchService = Classes.GetSingleton("MatchService")
	local Round = MatchService._Rounds.Round
	
	self.Janitor:Add(Round.LastManStandingStarted:Connect(function(student, killers)
		if student == self.Instance then
			self:AwardPoints(Enums.PlayerActionsEnum.SurviveTillLMS, 50, "Survived until LMS", 1)
			
		elseif table.find(killers, self.Instance) then
			--self:AwardPoints(Enums.PlayerActionsEnum.EliminateTillLMS, 50, "LMS started") -- should do it at the end of the round
		end
	end))
	
	-- objectives stuff
	local ObjectivesService = Classes.GetSingleton("ObjectivesService")
	self.Janitor:Add(ObjectivesService.ObjectiveCompleted:Connect(function(objectiveComponent, player, state)
		if not player or player ~= self.Instance then return end
		
		if state == "Success" then
			self._Stats.Objectives.Completed += 1
			self:AwardPoints("Academics", 15, "Completed an objective", 3)
		end
	end))
	
	self.Janitor:Add(ProxyService:AwaitProxyAndConnect("SubObjectiveCompleted", function(player, subobjectiveNumber, state)
		if player ~= self.Instance then return end

		self._Stats.Objectives.Resolved += 1
		self:AwardPoints("Academics", 5, "Completed a minigame", 15)
	end))
	
	-- misc. proxy stuff
	for ProxyName, RewardData in GenericPointRewards do
		self.Janitor:Add(ProxyService:AwaitProxyAndConnect(ProxyName, function(player)
			if player ~= self.Instance then
				return
			end
			
			self:AwardPoints(RewardData.Type, RewardData.Reward, RewardData.Message, RewardData.Cap)
		end))
	end
	
	self.Janitor:Add(ProxyService:AwaitProxyAndConnect("RunnerDashed", function(player)
		if player ~= self.Instance then return end
		if ChaseReplicator:IsPlayerInChase(player) then 
			self:AwardPoints("Athletics", 10, "Dashed in chase", 5) 
		end

		self._Stats.Abilities.Dashed += 1
	end))
	
	self.Janitor:Add(ProxyService:AwaitProxyAndConnect("GumDestroyed", function(destroyer, owner)
		if destroyer == self.Instance then
			self:AwardPoints("Chase", 10, "Destroyed a jammed door", 5)
		elseif owner == self.Instance then
			self:AwardPoints("Utility", 10, "Your jammed door was destroyed", 3)
		end
	end))
	
	self.Janitor:Add(ChaseReplicator.ChaseEnded:Connect(function(player)
		if player ~= self.Instance then
			return
		end
		if not RolesManager:IsPlayerStudent(player) then
			return
		end
		local Data = ChaseReplicator.ActiveChases[player]
		if Data.EndTimestamp - Data.StartTimestamp >= 15 then
			if RolesManager:GetPlayerRoleConfig(player).MovesetName == "Runner" then
				self:AwardPoints("Athletics", 20, "Escaped a chase as Runner", 5)
			else
				self:AwardPoints("Athletics", 10, "Escaped a chase", 5)
			end
		end
	end))
	
	self.Janitor:Add(ProxyService:AwaitProxyAndConnect("VaultStarted", function(player)
		if player ~= self.Instance then return end
		if not ChaseReplicator:IsPlayerInChase(player) then return end
		
		self:AwardPoints("Athletics", 10, "Vaulted in chase", 5)
	end))
	
	self.Janitor:Add(ProxyService:AwaitProxyAndConnect("Stealthed", function(player)
		if player ~= self.Instance then return end
		
		self._Stats.Abilities.Stealthed += 1
	end))

	self.Janitor:Add(ProxyService:AwaitProxyAndConnect("StealthStealtherNaturalEnd", function(player)
		if player ~= self.Instance then return end
		if ChaseReplicator:GetTerrorRadiusFromPlayer(player).CurrentLayer <= 0 then return end
		
		self:AwardPoints("Utility", 25, "Stealthed in Terror Radius", 5)
	end))
	
	self.Janitor:Add(ProxyService:AwaitProxyAndConnect("StealthStealtherInterrupted", function(player)
		if player ~= self.Instance then return end
		if ChaseReplicator:GetTerrorRadiusFromPlayer(player).CurrentLayer <= 0 then return end

		self:AwardPoints("Utility", 10, "Stealth in Terror Radius interrupted", 5)
	end))
	
	self.Janitor:Add(ProxyService:AwaitProxyAndConnect("HealCompleted", function(player, healee)
		if player ~= self.Instance then return end
		local IsSelfHeal = player == healee
		
		self._Stats.Abilities.Healed += 1
		self:AwardPoints("Utility", 25, IsSelfHeal and "Healed self" or "Healed a Student", 2)
	end))
	
	self.Janitor:Add(ProxyService:AwaitProxyAndConnect("HealCanceled", function(player, healee)
		print(player, healee)
		if player ~= self.Instance then return end
		local IsSelfHeal = player == healee

		self:AwardPoints("Utility", 15, IsSelfHeal and "Tried to heal self" or "Tried to heal a Student", 2)
	end))
	
	self.Janitor:Add(ProxyService:AwaitProxyAndConnect("HealerDamaged", function(damager, damagee)
		if damager ~= self.Instance then return end
		self:AwardPoints("Discipline", 15, "Interrupted a Medic heal", 5)
	end))
	
	self.Janitor:Add(ProxyService:AwaitProxyAndConnect("TroublemakerFoamBlinded", function(player, blindee)
		if player ~= self.Instance then return end
		
		local IsBlindeeTeacher = RolesManager:IsPlayerKiller(blindee)
		if not IsBlindeeTeacher then return end
		
		local RoleString = RolesManager:GetPlayerRoleString(Player)
		self:AwardPoints("Utility", 20, if RoleString == "Teacher" then "Blinded a Teacher" else "Blinded an Anomaly", 3)
		
		self._Stats.Abilities.KillerBlinded += 1
	end))
	
	self.Janitor:Add(ProxyService:AwaitProxyAndConnect("TeacherAttack", function(player)
		if player ~= self.Instance then return end
		
		self._Stats.Hits += 1 -- will saving this 
	end))
	
	self.Janitor:Add(task.delay(60, function()
		if RolesManager:IsPlayerStudent(self.Instance) then
			self:AwardPoints("Survival", 5, "Survived a minute", 1)
		end
	end), nil, "PassivePointAward")
end

function PlayerRoundStats.OnConstructServer(self: Component)
	SharedComponent.OnConstructServer(self)

	--mirror component creation on client
	ComponentReplicator:PromptCreate(self, { self.Instance })
	
	self:_InitEventsServer()
	
	-- prompt destroy
	self.Janitor:Add(function()
		ComponentReplicator:PromptDestroy(self, { self.Instance })
	end)
end

--function PlayerRoundStats.OnConstructClient(self: Component)
--	SharedComponent.OnConstructClient(self)	

--	self.Janitor:Add(self._InternalSavePointsListener.On(function(Data)
--		if self._Stats == Data then
--			return
--		end
		
--		print(Data, self._Stats)
--		self._Stats = Data
--	end))
--end

function PlayerRoundStats.OnDestroy(self: Component)
	self.PlayerJanitor:Cleanup()
	self.PlayerJanitor:Destroy()
end

function PlayerRoundStats.ProcessRoundEnd(self: Component)
	assert(RunService:IsServer())
	
	local MatchService = Classes.GetSingleton("MatchService")
	
	self.Janitor:Remove("PassivePointAward")
	
	local students = MatchService:GetAlivePlayers("Student")
	local teachers = MatchService:GetAlivePlayers("Killer")
	
	--print(students, teachers)
	
	local IsStudent = table.find(students, self.Instance) ~= nil
	local IsTeacher = table.find(teachers, self.Instance) ~= nil
	
	self:_StopTracking()
	
	if IsStudent then
		if #students > 1 then
			self:AwardPoints("Survival", 100, "Survived the match", 1)
		else
			if #teachers == 3 then
				self:AwardPoints("Survival", 150, "Survived LMS (3v1)", 1)
			end
			self:AwardPoints("Survival", 100, "Survived LMS", 1)
		end
	elseif RolesManager:IsPlayerStudent(self.Instance) then
		self:AwardPoints("Survival", 20, "Died", 1)
	end
	
	if IsTeacher then
		if #students == 0 then
			self:AwardPoints("Brutality", 100, "Noone survived", 1)
		elseif #students == 1 then
			self:AwardPoints("Brutality", 40, "One student survived", 1)
		else
			self:AwardPoints("Brutality", 20, "Students won", 1)
		end
	end
	
	self._Stats.SurvivalTime = self:GetSurvivalTime()
end

function PlayerRoundStats.GetSurvivalTime(self: Component)
	return math.round((self.EndTimestamp or os.clock()) - self.StartTimestamp)
end

function PlayerRoundStats.OnConstruct(self: Component)
	SharedComponent.OnConstruct(self)
	
	self.PlayerJanitor = Janitor.new()
	
	self.PointsGained = 0
	
	self.Kills = 0
	self.Deaths = 0
	self.DamageTaken = 0
	self.DamageDealed = 0
	self.TasksCompleted = 0

	self.Damagers = {}
	self.PlayersKilled = {}
	self.PlayersDamaged = {}
	self._Stats = {
		Objectives = {
			Resolved = 0,
			Completed = 0,
		},
		
		Abilities = {
			Dashed = 0,
			KillerBlinded = 0,
			Stealthed = 0,
			Healed = 0,
		},
		
		Others = {
			
		},
		
		SurvivalTime = 0,
		
		Health = 100,
		Deaths = 0,
		Hits = 0,
		Kills = 0,
		Total = 0,
	}
	self._AwardMap = {}
	
	self.StartTimestamp = os.clock() -- from which time we started tracking stats
	self.EndTimestamp = nil -- at which time we stopped tracking stats
	
	--self._InternalSavePointsListener = self:CreateEvent(
	--	"InternalPlayerStats_Awards", 
	--	"Reliable", 
	--	function(...) return typeof(...) == "table" end
	--)
end

--//Returner

return PlayerRoundStats :: Component