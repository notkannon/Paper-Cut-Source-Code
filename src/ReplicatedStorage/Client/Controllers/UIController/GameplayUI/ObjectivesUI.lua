--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local BaseObjective = require(ReplicatedStorage.Shared.Components.Abstract.BaseObjective)
--local BaseTestPaper = require(ReplicatedStorage.Shared.Components.Abstract.BaseObjective.BaseTestPaper)
--local TestPaper = require(ReplicatedStorage.Shared.Components.Objectives.TestPaper)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local Player = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI
local ObjectivesUI = BaseComponent.CreateComponent("ObjectivesUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	AddMinigameComponent: (self: Component, component: Component, minigameImpl: string) -> Component
}

export type Fields = {

} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ObjectivesUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "ObjectivesUI", Frame & any, {}>

--//Methods

function ObjectivesUI.AddMinigameComponent(self: Component, Component: Component, MinigameImpl: string)
	local ObjectiveInstance = UIAssets.Objectives.TestPapers:FindFirstChild(MinigameImpl:split("TestPaperUI")[1]):Clone()
	ObjectiveInstance.Parent = self.Instance.Content
	
	print(MinigameImpl, ObjectiveInstance)

	--registery & removal
	local subComponent = Component.Janitor:Add(

		self.Controller:RegisterInterface(
			ObjectiveInstance,
			MinigameImpl,
			self.Controller
		)
	)

	Component.Janitor:Add(function()
		ObjectiveInstance:Destroy()
	end)
	
	return subComponent
end

function ObjectivesUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	for _, Reflex in self.Instance.Content:GetChildren() do
		if Reflex.Name == "Reflex" then
			Reflex:Destroy()
		end
	end
	
end

--//Returner

return ObjectivesUI