--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)

local Utility = require(ReplicatedStorage.Shared.Utility)
local EnumsType = require(ReplicatedStorage.Shared.Enums)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local Player = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI.Misc
local HideoutUI = BaseComponent.CreateComponent("HideoutUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),

	OnConstructClient: (self: Component, any...) -> (),

	_ConnectComponentsEvents: (self: Component) -> (),
}

export type Fields = {
	UIController: any,
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "HideoutUI", ImageLabel, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "HideoutUI", ImageLabel, {}>

--//Methods

function HideoutUI.OnEnabledChanged(self: Component, value: boolean)
	TweenUtility.PlayTween(self.Instance, TweenInfo.new(0.3), {ImageTransparency = value and 0 or 1})
end

function HideoutUI._ConnectComponentsEvents(self: Component)

	ComponentsManager.ComponentAdded:Connect(function(component: { WCSCharacter: WCS.Character })

		if component.GetName() ~= "ClientCharacterComponent" then
			return
		end

		component.Janitor:Add(component.WCSCharacter.StatusEffectStarted:Connect(function(status)
			
			if status.Name == "HideoutPanicking" then
				
				self:SetEnabled(true)
				
				local InitialPose = self.InitialPose
				local Duration = status:GetActiveDuration()
				local StartTime = os.clock()
				local EndTime = StartTime + Duration
				
				--resetting filling value
				self.Instance.Value.Offset = Vector2.new(0, 1)
				
				--filling panicking indicator
				self.ActiveJanitor:Add(TweenUtility.PlayTween(self.Instance.Value, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {
					Offset = Vector2.zero
				}))
				
				self.ActiveJanitor:Add(RunService.RenderStepped:Connect(function()
					
					local Alpha = math.clamp((os.clock() - StartTime) / Duration, 0, 1)
					local ShakePose = UDim2.fromOffset(
						math.random(-20, 20),
						math.random(-20, 20)
					)
					
					self.Instance.Rotation = math.random(-150, 150) / 10 * Alpha
					self.Instance.Position = self.Instance.Position:Lerp(InitialPose:Lerp(InitialPose + ShakePose, Alpha), 1/7)
				end))
			end
		end))

		component.Janitor:Add(component.WCSCharacter.StatusEffectEnded:Connect(function(status)
			if status.Name == "HideoutPanicking" then
				self:SetEnabled(false)
			end
		end))

		--unlocking mouse
		component.Janitor:Add(function()
			self:SetEnabled(false)
		end)
	end)
end

function HideoutUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	self.InitialPose = self.Instance.Position
	self.Instance.Visible = true
	
	self:SetEnabled(false)
	self:_ConnectComponentsEvents()
end

--//Returner

return HideoutUI