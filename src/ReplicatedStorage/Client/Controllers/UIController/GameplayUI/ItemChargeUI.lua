--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local BaseItemComponent = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local UIAssets = ReplicatedStorage.Assets.UI
local LocalPlayer = Players.LocalPlayer
local ItemChargeUI = BaseComponent.CreateComponent("ItemChargeUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	SetItem: (self: Component, item: BaseItemComponent.Component?) -> (),
	
	_ConnectComponentEvents: (self: Component) -> (),
}

export type Fields = {

} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ItemChargeUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "ItemChargeUI", Frame & any, {}>

--//Methods

function ItemChargeUI.OnEnabledChanged(self: Component, value: boolean)
	
	TweenUtility.ClearAllTweens(self.Instance)
	TweenUtility.ClearAllTweens(self.Instance.Info)
	
	TweenUtility.PlayTween(self.Instance.Info, TweenInfo.new(0.2), {
		TextTransparency = value and 0.5 or 1
	} :: TextLabel)
	
	TweenUtility.PlayTween(self.Instance, TweenInfo.new(0.2), {
		ImageTransparency = value and 0.5 or 1
	} :: ImageLabel)
end

function ItemChargeUI.SetItem(self: Component, item: BaseItemComponent.Component)
	
	self:SetEnabled(item ~= nil)
	
	--reset on empty item
	if not item then
		return
	end
	
	local OldCharge = 1
	local Gradient = self.Instance:FindFirstChildWhichIsA("UIGradient")
	local Label = self.Instance:FindFirstChild("Info") :: TextLabel
	
	TweenUtility.ClearAllTweens(Gradient)
	Gradient.Offset = Vector2.new(item.Attributes.Charge - 1, 0)
	Label.RichText = true
	
	local function UpdateText()
		Label.Text = item.GetName():upper():sub(1, -5).." ("..math.round(item.Attributes.Charge * 100).."%)"
	end
	
	--initial update
	UpdateText()
	
	self.ActiveJanitor:Add(item.Attributes.AttributeChanged:Connect(function(attribute, value)
		
		--attribute check
		if attribute ~= "Charge" then
			return
		end
		
		UpdateText()
		
		TweenUtility.ClearAllTweens(Gradient)

		TweenUtility.PlayTween(
			Gradient,
			TweenInfo.new(math.abs(OldCharge - value), Enum.EasingStyle.Linear),
			{ Offset = Vector2.new(math.clamp(value, 0, 1) - 1, 0) }
		)

		OldCharge = value
	end))
end

function ItemChargeUI._ConnectComponentEvents(self: Component)
	
	self.Janitor:Add(ComponentsManager.ComponentAdded:Connect(function(component)

		--class check & does item have charge
		if not Classes.InstanceOf(component, BaseItemComponent)
			or not component.Attributes.Charge then
			
			return
		end

		component.Janitor:Add(component.Instance.Equipped:Connect(function()
			self:SetItem(component)
		end))
		
		component.Janitor:Add(component.Instance.Unequipped:Connect(function()
			self:SetItem(nil)
		end))
		
		component.Janitor:Add(function()
			
			--check if component currently equipped
			if not component.Equipped then
				return
			end
			
			self:SetItem(nil)
		end)
	end))
end

function ItemChargeUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	self:SetItem(nil)
	self:_ConnectComponentEvents()
end

--//Returner

return ItemChargeUI