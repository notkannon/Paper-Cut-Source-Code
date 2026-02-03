--//Services

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)
local MouseUnlockedEffect = require(ReplicatedStorage.Shared.Combat.Statuses.MouseUnlocked)

local Utility = require(ReplicatedStorage.Shared.Utility)
local EnumsType = require(ReplicatedStorage.Shared.Enums)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)

--//Constants

local CROSSHAIR_SPACING = 0.23
local CROSSHAIR_OFFSETS = {
	A = Vector2.new(0, -1),
	B = Vector2.new(-1, 0),
	C = Vector2.new(0, 1),
	D = Vector2.new(1, 0),
}

--//Variables

local Player = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI.Misc

local CursorUI = BaseComponent.CreateComponent("CursorUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

type CursorDisplayMode = "Disabled" | "Default" | "Dot" | "Aim"

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	ToggleCrossHair: (self: Component, value: boolean) -> (),
	SetIconVisibility: (self: Component, visible: boolean) -> (),
	ChangeDisplayMode: (self: Component, mode: CursorDisplayMode) -> (),
	
	OnConstructClient: (self: Component, any...) -> (),
	
	_ConnectComponentsEvents: (self: Component) -> (),
	_ConnectMatchEvents: (self: Component) -> (),
}

export type Fields = {
	UIController: any,
	
	_CrossHairEnabled: boolean,
	
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "CursorUI", Frame, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "CursorUI", Frame, {}>

--//Methods

function CursorUI.ToggleCrossHair(self: Component, value: boolean)
	self._CrossHairEnabled = value
	
	for _, Frame: Frame in ipairs(self.Instance.CrossHair:GetChildren()) do
		if value then
			local Offset = CROSSHAIR_OFFSETS[ Frame.Name ] :: Vector2
			
			Frame.Position = UDim2.fromScale(0.5, 0.5)
			
			TweenUtility.PlayTween(Frame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(Offset.X * CROSSHAIR_SPACING + 0.5, Offset.Y * CROSSHAIR_SPACING + 0.5),
				BackgroundTransparency = 0.7,
			})
		else
			TweenUtility.PlayTween(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
			})
		end
	end
end

function CursorUI.SetIconVisibility(self: Component, visible: boolean)
	self.Instance.Icon.Visible = visible
end

function CursorUI.ChangeDisplayMode(self: Component, mode: CursorDisplayMode)
	
	self:ToggleCrossHair(mode == "Aim")
	self:SetIconVisibility(mode == "Dot")
	UserInputService.MouseIconEnabled = mode == "Default"
end

function CursorUI._ConnectMatchEvents(self: Component)
	
end

function CursorUI._ConnectComponentsEvents(self: Component)
	
	ComponentsManager.ComponentAdded:Connect(function(component: { WCSCharacter: WCS.Character })
		
		if component.GetName() ~= "ClientCharacterComponent" then
			return
		end
		
		MatchStateClient.MatchStarted:Connect(function(Match)
			if Match ~= "Result" then
				return
			end

			self:ChangeDisplayMode("Disabled")
		end)
		
		--role applying
		if PlayerController:IsSpectator() then
			self:ChangeDisplayMode("Default")
		else
			self:ChangeDisplayMode("Dot")
		end
		
		local function OnAimStateChanged(active)
			self:ChangeDisplayMode(active and "Aim" or "Dot")
		end
		
		local function IsMouseUnlocked()
			return WCSUtility.HasActiveStatusEffectsWithNames(component.WCSCharacter, {"MouseUnlocked"})
		end
		
		component.Janitor:Add(component.WCSCharacter.StatusEffectStarted:Connect(function(status)
			if IsMouseUnlocked() then
				self:ChangeDisplayMode("Default")
			elseif status.Name == "Aiming" then
				OnAimStateChanged(true)
			end
		end))
		
		component.Janitor:Add(component.WCSCharacter.StatusEffectEnded:Connect(function(status)
			if not IsMouseUnlocked() and status.Name == "MouseUnlocked" then
				self:ChangeDisplayMode("Dot")
			elseif status.Name == "Aiming" then
				OnAimStateChanged(false)
			end
		end))
		
		--unlocking mouse
		component.Janitor:Add(function()
			self:ChangeDisplayMode("Default")
		end)
	end)
end

function CursorUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	self:ChangeDisplayMode("Disabled")
	self:_ConnectComponentsEvents()
end

--//Returner

return CursorUI