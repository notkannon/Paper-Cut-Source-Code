--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Refx = require(ReplicatedStorage.Packages.Refx)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BasePassive = require(ReplicatedStorage.Shared.Components.Abstract.BasePassive)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)

local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local PlayerHealEffect = require(ReplicatedStorage.Shared.Effects.PlayerHeal)

--//Variables

local RoomToBreathe = BaseComponent.CreateComponent("RoomToBreathe", {

	isAbstract = false,

}, BasePassive) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BasePassive.MyImpl)),

	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component, enabled: boolean?) -> (),
	OnConstructServer: (self: Component) -> (),
}

export type Fields = {

} & BasePassive.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "RoomToBreathe", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "RoomToBreathe", PlayerTypes.Character>

--//Methods

function RoomToBreathe.OnConstructServer(self: Component)
	BasePassive.OnConstructServer(self)
	
	self.Janitor:Add(self._InternalLMSListener.On(function(...)
		if self.Instance then
			local Config = self:GetConfig()
			self.Instance.Humanoid.Health += Config.HealAmount
			PlayerHealEffect.new(self.Instance, Config.HealAmount):Start(Players:GetPlayers())
		end
	end))
end

function RoomToBreathe.OnConstruct(self: Component)
	BasePassive.OnConstruct(self)
	
	self._InternalLMSListener = self:CreateEvent(
		"StartLMS",
		"Reliable"
	)
end

function RoomToBreathe.OnConstructClient(self: Component)
	BasePassive.OnConstructClient(self)
	
	
	self.Janitor:Add(task.spawn(function()
		--print('hi it works', ClientRemotes, ClientRemotes.MatchServiceStartLMS, self.Instance)
		
		ClientRemotes.MatchServiceStartLMS.On(function()
			
			self._InternalLMSListener.Fire()
			
		end)
	end))
end

--//Returner

return RoomToBreathe