--//Services

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local HealingActComponent = require(ReplicatedStorage.Shared.Components.AbilityRelated.HealingAct)
local InputController = require(ReplicatedStorage.Client.Controllers.InputController)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local LocalPlayer = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI
local HealingActUI = BaseComponent.CreateComponent("HealingActUI", {
	
	isAbstract = false
	
}, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),

	
}

export type Fields = {

} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "HealingActUI", Frame, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "HealingActUI", Frame, {}>

--//Methods

function HealingActUI.HideCancelPrompt(self: Component)
	
	TweenUtility.PlayTween(self.Instance.CancelInfo, TweenInfo.new(0.3), { TextTransparency = 1 })
	TweenUtility.PlayTween(self.Instance.CancelInfo.Key, TweenInfo.new(0.3), {

		TextTransparency = 1,
		BackgroundTransparency = 1
	})
end

function HealingActUI.OnConstructClient(self: Component, controller: any, component: HealingActComponent.Component)
	BaseUIComponent.OnConstructClient(self, controller)

	local IsSelfHeal = component.Healer == component.Target
	local LocalIsHealer = component.Healer == LocalPlayer
	
	local function GetKeyString()
		local InputController = Classes.GetSingleton("InputController")
		return InputController:GetStringsFromContext("Cancel")[1]
	end
	
	self.Instance.CancelInfo.Key.Text = GetKeyString()
	
	self.Component = component
	self.Instance.Visible = true
	self.Instance.Info.Text = `{IsSelfHeal and "SELF-MEDICATED" or (LocalIsHealer and `HEALING { component.Target.Name }` or `HEALED BY { component.Healer.Name }`)} ({ math.round(component.Amount) }%)`
	
	self.Janitor:Add(function()
		self.Component = nil
	end)
	
	local Humanoid = component.Target.Character:FindFirstChildWhichIsA("Humanoid")
	local StarterHealth = Humanoid.Health
	local EndHealth = math.clamp(StarterHealth + component.Amount, 0, Humanoid.MaxHealth)
	
	--resetting
	self.Instance.Progress.Value.Offset = Vector2.new(-1, 0)
	
	--health bar updating
	self.Janitor:Add(Humanoid.HealthChanged:Connect(function(health)
		
		TweenUtility.PlayTween(self.Instance.Progress.Value, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {
			Offset = Vector2.new((health - StarterHealth) / (EndHealth - StarterHealth) - 1, 0)
		} :: UIGradient)
	end))
	
	self.Janitor:Add(component.Target.Character.Destroying:Connect(function()
		self:Destroy()
	end))
	
	local IsCancelled = false
	
	self.Janitor:Add(InputController.ContextStarted:Connect(function(context)
		
		if context ~= "Vault" or IsCancelled then
			return
		end
		
		IsCancelled = true
		
		self:HideCancelPrompt()
	end))
end

function HealingActUI.OnDestroy(self: Component)
	
	TweenUtility.PlayTween(self.Instance.Progress, TweenInfo.new(2), { ImageTransparency = 1 })
	TweenUtility.PlayTween(self.Instance.Info, TweenInfo.new(1.5), { TextTransparency = 1 })
	TweenUtility.PlayTween(self.Instance.Icon, TweenInfo.new(1), { ImageTransparency = 1 })
	TweenUtility.PlayTween(self.Instance.Icon.Glow, TweenInfo.new(1.3), { ImageTransparency = 1 })
	
	self:HideCancelPrompt()
	
	Debris:AddItem(self.Instance, 2)
end

--//Returner

return HealingActUI