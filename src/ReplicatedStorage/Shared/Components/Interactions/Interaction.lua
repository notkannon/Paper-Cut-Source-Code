--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseInteraction = require(ReplicatedStorage.Shared.Components.Abstract.BaseInteraction)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)

--//Variables

local Interaction = BaseComponent.CreateComponent("Interaction", {
	tag = "Interaction",
	isAbstract = false
}, BaseInteraction) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseInteraction.MyImpl)),
	
	CooldownJanitor: Janitor.Janitor,
	
	IsHolded: boolean,
	IsActive: boolean,

	Ended: Signal.Signal<Player>,
	Started: Signal.Signal<Player>,
	HoldEnded: Signal.Signal<Player>,
	HoldStarted: Signal.Signal<Player>,
}

export type Fields = {
	IsCooldowned: (self: Component) -> boolean,
	ApplyCooldown: (self: Component, duration: number) -> (),
} & BaseInteraction.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "Interaction", ProximityPrompt, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "Interaction", ProximityPrompt, {}>

--//Methods

function Interaction.IsCooldowned(self: Component)
	return self.Attributes.Cooldowned
end

function Interaction.ApplyCooldown(self: Component, duration: number)
	assert(RunService:IsServer(), "Attempted to call :ApplyCooldown() on client")
	assert(typeof(duration) == "number", `Duration argument expected, got { typeof(duration) }`)
	
	self.Attributes.Cooldowned = true
	
	self.CooldownJanitor:Cleanup()
	self.CooldownJanitor:Add(task.delay(duration, function()
		self.Attributes.Cooldowned = false
	end))
end

function Interaction.OnConstruct(self: Component)
	BaseInteraction.OnConstruct(self, {
		Sync = {
			"Enabled",
			"_TeamAccessibility",
			"_RoleAccessibility",
			"_PlayerAccessibility",
		},
		
		SyncOnCreation = false, -- cuz client makes request to get data after initialization
	})
	
	self.IsHolded = false
	self.IsActive = false
	
	self.Ended = self.Janitor:Add(Signal.new())
	self.Started = self.Janitor:Add(Signal.new())
	self.HoldEnded = self.Janitor:Add(Signal.new())
	self.HoldStarted = self.Janitor:Add(Signal.new())
	
	self.Instance.Style = Enum.ProximityPromptStyle.Custom
	
	self.Janitor:Add(self.Instance.PromptButtonHoldBegan:Connect(function(player: Player)
		if not self:PlayerHasAccess(player) or self:IsCooldowned() then
			return
		end
		
		self.IsHolded = true
		self.HoldStarted:Fire(player)
	end))

	self.Janitor:Add(self.Instance.PromptButtonHoldEnded:Connect(function(player: Player)
		if not self:PlayerHasAccess(player) or self:IsCooldowned() then
			return
		end
		
		self.IsHolded = false
		self.HoldEnded:Fire(player)
	end))

	self.Janitor:Add(self.Instance.Triggered:Connect(function(player: Player)
		if not self:PlayerHasAccess(player) or self:IsCooldowned() then
			return
		end

		self.IsActive = true
		self.Started:Fire(player)
	end))

	self.Janitor:Add(self.Instance.TriggerEnded:Connect(function(player: Player)
		if not self:PlayerHasAccess(player) or self:IsCooldowned() then
			return
		end
		
		self.IsActive = false
		self.Ended:Fire(player)
	end))
end

function Interaction.OnConstructServer(self: Component, ...)
	self.CooldownJanitor = self.Janitor:Add(Janitor.new())
end

function Interaction.OnConstructClient(self: Component)
	BaseInteraction.OnConstructClient(self)
	
	self:SyncClient()
end

--//Returner

return Interaction