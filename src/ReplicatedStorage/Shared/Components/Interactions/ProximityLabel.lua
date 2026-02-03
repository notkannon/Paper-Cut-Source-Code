--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local Signal = require(ReplicatedStorage.Packages.Signal)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseInteraction = require(ReplicatedStorage.Shared.Components.Abstract.BaseInteraction)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local ProximityLabel = BaseComponent.CreateComponent("ProximityLabel", {
	tag = "ProximityLabel",
	isAbstract = false
}, BaseInteraction) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseInteraction.MyImpl)),
}

export type Fields = {} & BaseInteraction.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ProximityLabel", ProximityPrompt, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "ProximityLabel", ProximityPrompt, {}>

--//Returner

return ProximityLabel