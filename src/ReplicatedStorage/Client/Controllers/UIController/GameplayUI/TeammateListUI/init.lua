--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local BaseUI = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local ClientMatchState = require(ReplicatedStorage.Client.Controllers.MatchStateClient)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

local RoleListUI = require(script.RoleListUI)

--//Variables

local LocalPlayer = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI
local TeammatesListUI = BaseComponent.CreateComponent("TeammatesListUI", {

	isAbstract = false,

}, BaseUI) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUI.MyImpl) ),
	
	Cleanup: (self: Component) -> (),
	RegisterRoleList: (self: Component, instance: Frame, options: {
		Role: "Killer" | "Student" | "Anomaly",
		Mode: "LeftRight" | "Center",
		IgnoreHealth: boolean?
	}) -> RoleListUI
}

export type Fields = {

	Tabs: { PlayerTab },

} & BaseUI.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "TeammatesListUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "TeammatesListUI", Frame & any, {}>

--//Methods

function TeammatesListUI.Cleanup(self: Component)
	self.StudentList:Cleanup()
	self.KillerList:Cleanup()
end

function TeammatesListUI.RegisterRoleList(self: Component, instance: Frame, options)
	local Component = ComponentsManager.Add(instance, RoleListUI, options)
	return Component
end

function TeammatesListUI.OnConstructClient(self: Component, ...)
	BaseUI.OnConstructClient(self, ...)
	
	self.StudentList = self:RegisterRoleList(self.Instance.StudentList, {Role = "Student", Mode = "LeftRight"})
	self.KillerList = self:RegisterRoleList(self.Instance.KillerList, {Role = "Killer", Mode = "Center", IgnoreHealth = true})
	
end

--//Returner

return TeammatesListUI