--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BasePassive = require(ReplicatedStorage.Shared.Components.Abstract.BasePassive)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)

--//Variables

local BaseComboPassive = BaseComponent.CreateComponent("BaseComboPassive", {

	isAbstract = true,
	
}, BasePassive) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BasePassive.MyImpl)),
	
	GetConfig: (self: Component) -> {
		Max: number,
		Duration: number,
		StaminaIncrement: number,
		WalkSpeedIncrement: number,
	},
	
	IsMaxCombo: (self: Component) -> boolean,
	IsComboActive: (self: Component) -> boolean,

	ResetCombo: (self: Component) -> (),
	IncrementCombo: (self: Component) -> (),
	ResetComboTimeout: (self: Component) ->(),
	
	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component, enabled: boolean?) -> (),
	OnConstructServer: (self: Component) -> (),
}

export type Fields = {
	
	Player: Player & {Character: PlayerTypes.Character},
	Amount: number,
	Changed: Signal.Signal<number, number>,
	TimeoutChanged: Signal.Signal<number, number>,
	
	_TimeoutTimestamp: number,
	_InternalClientListener: SharedComponent.ServerToClient,
	_InternalTimeoutListener: SharedComponent.ServerToClient,
	
} & BasePassive.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseComboPassive", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseComboPassive", PlayerTypes.Character>

--//Methods

function BaseComboPassive.IsMaxCombo(self: Component)
	return self.Amount == self:GetConfig().Max
end

function BaseComboPassive.IsComboActive(self: Component)
	return self.Amount > 0
end

function BaseComboPassive.ResetComboTimeout(self: Component)
	assert(RunService:IsServer())
	
	local Config = self:GetConfig()

	self.Janitor:Remove("TimeoutThread")
	self.Janitor:Add(task.delay(Config.Duration, self.ResetCombo, self), nil, "TimeoutThread")
	self._InternalTimeoutListener.Fire(self.Player, workspace:GetServerTimeNow() + Config.Duration)
end

function BaseComboPassive.IncreaseCombo(self: Component)
	assert(RunService:IsServer())

	local Old = self.Amount

	if self.Amount < self:GetConfig().Max then

		self.Amount += 1

		self._InternalClientListener.Fire(self.Player, self.Amount, Old)
		self.Changed:Fire(self.Amount, Old)

	else

		self:Reset()

		return
	end

	self:ResetComboTimeout()
end

function BaseComboPassive.ResetCombo(self: Component)
	assert(RunService:IsServer())

	if self.Amount == 0 then
		return
	end

	local Old = self.Amount

	self.Amount = 0
	self.LastHitHumanoid = nil

	self.Janitor:Remove("TimeoutThread")
	self._InternalClientListener.Fire(self.Player, 0, Old)

	self.Changed:Fire(0, Old)
end

function BaseComboPassive.OnConstructClient(self: Component)
	BasePassive.OnConstructClient(self)

	self.Janitor:Add(self._InternalTimeoutListener.On(function(timestamp)
		self._TimeoutTimestamp = timestamp

		--(duration, endTimestamp)
		self.TimeoutChanged:Fire(workspace:GetServerTimeNow() - timestamp, timestamp)
	end))

	self.Janitor:Add(self._InternalClientListener.On(function(new, old)
		self.Amount = new
		self.Changed:Fire(new, old)
	end))
end

function BaseComboPassive.OnConstruct(self: Component)
	BasePassive.OnConstruct(self)

	self.Amount = 0
	self.Player = Players:GetPlayerFromCharacter(self.Instance)
	self.Changed = self.Janitor:Add(Signal.new())
	self.TimeoutChanged = self.Janitor:Add(Signal.new())

	self._TimeoutTimestamp = 0
	
	--combo timer state
	self._InternalTimeoutListener = self:CreateEvent(
		"InternalTimeoutListener",
		"Reliable",

		function(...) return typeof(...) == "number" end
	)
	
	--combo counting state
	self._InternalClientListener = self:CreateEvent(
		"ChangedReplicator",
		"Reliable",

		function(...) return typeof(...) == "number" end,
		function(...) return typeof(...) == "number" end
	)
end

--//Returner

return BaseComboPassive