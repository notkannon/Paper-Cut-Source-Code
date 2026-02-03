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
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local StudentAppearance = require(ReplicatedStorage.Shared.Components.Appearance.Student)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local KennyAppearance = BaseComponent.CreateComponent("KennyAppearance", {

	isAbstract = false

}, StudentAppearance) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: KennyAppearance.MyImpl)),
}

export type Fields = {

} & KennyAppearance.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "KennyAppearance", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "KennyAppearance", PlayerTypes.Character>

--//Methods

function KennyAppearance.IsDescendantTransparent(self: Component, descendant: Instance)
	
	if not self:IsLocalPlayer() then
		return false
	end
	
	return descendant:IsDescendantOf(self.Head)
		or StudentAppearance.IsDescendantTransparent(self, descendant)
end

--//Returner

return KennyAppearance