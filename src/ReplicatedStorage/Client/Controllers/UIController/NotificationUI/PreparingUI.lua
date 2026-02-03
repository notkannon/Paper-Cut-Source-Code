--//Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)

--//Variables

local UIAssets = ReplicatedStorage.Assets.UI
local PreparingUI = BaseComponent.CreateComponent("PreparingUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
}

export type Fields = {
	
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "PreparingUI", Frame, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "PreparingUI", Frame, {}>

--//Methods

function PreparingUI.OnEnabledChanged(self: Component, value: boolean)
	
	--handling values
	
	--creating loading sequence
	ComponentsManager[value and "Add" or 'Remove'](self.Instance.Icon, "ClockImageSequenceUI") 
	
	self.Instance.Icon.ImageTransparency = value and 1 or 0
	
	--TODO: AHH that looks kinda weird.. but okay
	TweenUtility.PlayTween(SoundUtility.Sounds, TweenInfo.new(1), {
		Volume = value and 0 or 1,
	})
	
	TweenUtility.PlayTween(self.Instance, TweenInfo.new(1), {
		BackgroundTransparency = value and 0 or 1,
	} :: Frame)
	
	TweenUtility.PlayTween(self.Instance.Icon, TweenInfo.new(1), {
		ImageTransparency = value and 0 or 1,
	} :: ImageLabel)
end

function PreparingUI.OnConstructClient(self: Component, controller: any)
	BaseUIComponent.OnConstructClient(self, controller)
	
	--initial enabling
	self:SetEnabled(MatchStateClient:IsPreparing())
	
	--subscribing to changes
	MatchStateClient.PreparingChanged:Connect(function(value)
		self:SetEnabled(value)
	end)
end

--//Returner

return PreparingUI