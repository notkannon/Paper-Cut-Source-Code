--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BasePassive = require(ReplicatedStorage.Shared.Components.Abstract.BasePassive)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local HushedActions = BaseComponent.CreateComponent("HushedActions", {

	isAbstract = false,

}, BasePassive) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BasePassive.MyImpl)),
	
	TrackedPlayers: { [Player]: Janitor.Janitor },
	
	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component, enabled: boolean?) -> (),
	OnConstructServer: (self: Component) -> (),
}

export type Fields = {
	
} & BasePassive.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "HushedActions", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "HushedActions", PlayerTypes.Character>

--//Methods

function HushedActions.OnConstructServer(self: Component, enabled: boolean?)
	BasePassive.OnConstructServer(self)
	
	self.Permanent = true
	
	local Config = self:GetConfig()
	self.Janitor:AddPromise(ComponentsManager.AwaitFirstComponentInstanceOf(self.Player.Character, "BaseAppearance"):andThen(function(Appearance)
		Appearance.Attributes.ActionVolumeScale *= Config.ActionVolumeScale
		Appearance.Attributes.ActionRollOffScale *= Config.ActionRollOffScale
	end))
	
end

--//Returner

return HushedActions