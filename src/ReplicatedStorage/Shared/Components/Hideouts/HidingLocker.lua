--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local BaseHideout = require(ReplicatedStorage.Shared.Components.Abstract.BaseHideout)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local HidingLocker = BaseComponent.CreateComponent("HidingLocker", {
	tag = "HidingLocker",
	
	isAbstract = false,
	
	predicate = function(instance: Instance)
		return instance:HasTag("HidingLocker") and instance:HasTag("Hideout")
	end,
	
}, BaseHideout) :: Impl

--//Types

export type Fields = {} & BaseHideout.Fields

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseHideout.MyImpl)),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "HidingLocker", BaseHideout.BaseHideoutModel, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "HidingLocker", BaseHideout.BaseHideoutModel, {}> 

--//Methods

function HidingLocker.OnConstruct(self: Component)
	BaseHideout.OnConstruct(self)
	self.AnimationsSource = ReplicatedStorage.Assets.Animations.Hideout.Locker
end

--//Returner

return HidingLocker