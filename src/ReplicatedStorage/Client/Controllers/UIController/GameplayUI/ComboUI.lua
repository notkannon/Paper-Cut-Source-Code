--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local BaseComboPassive = require(ReplicatedStorage.Shared.Combat.Passives.Abstract.BaseCombo)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local Player = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI
local ComboUI = BaseComponent.CreateComponent("ComboUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	_OnComboChanged: (self: Component, new: number, old: number) -> (),
	_ConnectComponentEvents: (self: Component) -> (),
}

export type Fields = {
	
	Combo: BaseComboPassive.Component?,
	
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ComboUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "ComboUI", Frame & any, {}>

--//Methods

function ComboUI._OnComboChanged(self: Component, new: number, old: number)
	
	local Glow = self.Instance.Glow :: ImageLabel
	local Indicator = self.Instance.Indicator :: ImageLabel
	local ProgressGradient = Indicator:FindFirstChildWhichIsA("UIGradient")
	
	TweenUtility.ClearAllTweens(Glow)
	TweenUtility.ClearAllTweens(Indicator)
	TweenUtility.ClearAllTweens(self.Instance)
	TweenUtility.ClearAllTweens(ProgressGradient)
	
	if new > old then
		
		self.Instance.Text = new
		ProgressGradient.Offset = Vector2.new(0, 0)
		self.Instance.TextTransparency = 0
		Indicator.ImageTransparency = 0
		Glow.ImageTransparency = 0
		
		TweenUtility.PlayTween(Glow, TweenInfo.new(0.5), {ImageTransparency = 1})
		TweenUtility.PlayTween(ProgressGradient, TweenInfo.new(self.Combo:GetConfig().Duration, Enum.EasingStyle.Linear), {
			Offset = Vector2.new(0, 1)
		})
		
	else
		TweenUtility.PlayTween(Glow, TweenInfo.new(1), {ImageTransparency = 1})
		TweenUtility.PlayTween(Indicator, TweenInfo.new(1), {ImageTransparency = 1})
		TweenUtility.PlayTween(self.Instance, TweenInfo.new(1), {TextTransparency = 1})
	end
end

function ComboUI._ConnectComponentEvents(self: Component)
	local InitialPose = self.Instance.Position
	
	self.Janitor:Add(ComponentsManager.ComponentAdded:Connect(function(component)
		
		--class check
		if not Classes.InstanceOf(component, BaseComboPassive) then
			return
		end
		
		self.Combo = component
		
		component.Janitor:Add(RunService.RenderStepped:Connect(function()
			
			if not component:IsComboActive() then
				return
			end
			
			local ShakePose = UDim2.fromOffset(
				math.random(-20, 20),
				math.random(-20, 20)
			)
			
			self.Instance.Position = InitialPose:Lerp(InitialPose + ShakePose, component.Amount / component:GetConfig().Max * (1 - self.Instance.TextTransparency))
		end))
		
		component.Janitor:Add(component.Changed:Connect(function(...)
			self:_OnComboChanged(...)
		end))
		
		component.Janitor:Add(function()
			self.Combo = nil
			self:_OnComboChanged(0, 0)
		end)
	end))
end

function ComboUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	self:_OnComboChanged(0, 0)
	self:_ConnectComponentEvents()
end

--//Returner

return ComboUI