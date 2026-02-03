--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)

--//Variables

local BasePassive = BaseComponent.CreateComponent("BasePassive", {
	
	isAbstract = true,
	ancestorWhitelist = { workspace },
	predicate = function(instance)
		return Players:GetPlayerFromCharacter(instance) ~= nil
	end,
	
}, SharedComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: SharedComponent.MyImpl)),

	CreateEvent: SharedComponent.CreateEvent<Component>,
	
	GetConfig: (self: Component) -> { any }?,
	IsEnabled: (self: Component) -> boolean,
	SetEnabled: (self: Component, value: boolean) -> (),

	OnEnabledClient: (self: Component) -> (),
	OnEnabledServer: (self: Component) -> (),
	OnDisabledServer: (self: Component) -> (),
	OnDisabledClient: (self: Component) -> (),
	
	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component, enabled: boolean?) -> (),
	OnConstructClient: (self: Component) -> (),
	OnConstructServer: (self: Component) -> (),
}

export type Fields = {
	
	Player: Player,
	Permanent: boolean,
	EnabledJanitor: Janitor.Janitor,
	EnabledChanged: Signal.Signal<boolean>,	
	
	--ExclusivesSkillNames: { string },
	--ExclusivesStatusNames: { string },
	
	_Enabled: boolean,
	_InternalEnabledReplicator: SharedComponent.ServerToClient<boolean>,
	
} & SharedComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BasePassive", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "BasePassive", PlayerTypes.Character>

--//Methods

function BasePassive.OnEnabledClient(self: Component) end

function BasePassive.OnEnabledServer(self: Component) end

function BasePassive.OnDisabledServer(self: Component) end

function BasePassive.OnDisabledClient(self: Component) end


--returns a table of params defined for current player (role data)
function BasePassive.GetConfig(self: Component)
	
	--extracting from role data
	local RoleConfig = RolesManager:GetPlayerRoleConfig(self.Player)
	
	--data extracting
	return RoleConfig
		and RoleConfig.PassivesData
		and RoleConfig.PassivesData[self.GetName()]
		or nil
end

function BasePassive.IsEnabled(self: Component)
	return self._Enabled
end

function BasePassive.SetEnabled(self: Component, value: boolean)
	
	--no 2nd calls
	if self._Enabled == value then
		return
	end
	
	if not value then
		
		--shouldn't disable permanent passives
		if self.Permanent then
			return
		end
		
		--cleanup janitor on disable
		self.EnabledJanitor:Cleanup()
	end
	
	self._Enabled = value
	self.EnabledChanged:Fire(value)
	
	--replication
	if RunService:IsServer() then
		self._InternalEnabledReplicator.Fire(self.Player, value)
	end
	
	--calling changing methods
	self[`On{ value and "Enabled" or "Disabled" }{ RunService:IsServer() and "Server" or "Client" }`](self)
end

--function BasePassive._InitExclusives(self: Component)
	
--	--getting WCS character reference
--	local WCSCharacter = self.Janitor:AddPromise(WCSUtility.PromiseCharacterAdded(self.Instance)):expect()
	
	
--end

function BasePassive.OnConstruct(self: Component, enabled: boolean?)
	SharedComponent.OnConstruct(self, {
		
		Sync = { "_Enabled" },
		SyncOnCreation = true,
		
	} :: SharedComponent.SharedComponentConstructOptions)
	
	self.Player = Players:GetPlayerFromCharacter(self.Instance)
	self.Permanent = false
	self.EnabledChanged = self.Janitor:Add(Signal.new())
	self.EnabledJanitor = self.Janitor:Add(Janitor.new())
	
	self._Enabled = enabled ~= nil and enabled or true
	
	self._InternalEnabledReplicator = self:CreateEvent(
		"InternalEnabledReplicator",
		"Reliable",
		function(...) return typeof(...) == "boolean" end
	)
end

function BasePassive.OnConstructClient(self: Component)
	
	--syncing with server
	self.Janitor:Add(self._InternalEnabledReplicator.On(function(enabled)
		self:SetEnabled(enabled)
	end))
	
	--starter state
	if self:IsEnabled() then
		self:OnEnabledClient()
	else
		self:OnDisabledClient()
	end
end

function BasePassive.OnConstructServer(self: Component)
	
	--creating only for player owner
	ComponentReplicator:PromptCreate(self, { self.Player }, self:IsEnabled())
	
	--starter state
	if self:IsEnabled() then
		self:OnEnabledServer()
	else
		self:OnDisabledServer()
	end
end

function BasePassive.OnDestroy(self: Component)
	
	if RunService:IsServer() then
		
	--prompting to destroy passive component
		ComponentReplicator:PromptDestroy(self, { self.Player })
		
		return
	end
end

--//Returner

return BasePassive