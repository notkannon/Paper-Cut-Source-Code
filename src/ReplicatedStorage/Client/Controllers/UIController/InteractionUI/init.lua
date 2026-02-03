--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local InteractionService = require(ReplicatedStorage.Shared.Services.InteractionService)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

local Label = require(script.Label)

--//Variables

local Player = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI
local InteractionUI = BaseComponent.CreateComponent("InteractionUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	_InitServiceConnections: (self: Component) -> (),
}

export type Fields = {
	
	Label: any,
	UIController: any,
	
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "InteractionUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "InteractionUI", Frame & any, {}>

--//Methods

function InteractionUI._InitServiceConnections(self: Component)
	InteractionService.InteractionShown:Connect(function(component)
		local LabelObject = Label.GetFromComponent(component)
		
		if LabelObject then
			LabelObject:CancelHide()
			LabelObject:Show()
			
			return
		end
		
		local OtherLabel = Label.GetFromInstance(self.Label)
		
		if OtherLabel then
			OtherLabel.Instance = nil
			OtherLabel:Destroy()
		end
		
		Label.new(component, self.Label):Show()
	end)
	
	InteractionService.InteractionHidden:Connect(function(component)
		local LabelObject = Label.GetFromComponent(component)
		
		if not LabelObject then
			return
		end
		
		LabelObject:Hide()
	end)
end

function InteractionUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	self.Label = UIAssets.Proximities.Label:Clone()
	self.Label.Parent = self.Instance.Content
	self.Label.Visible = false
	
	self:_InitServiceConnections()
end

--//Returner

return InteractionUI