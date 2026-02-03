--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local BaseUISettingsComponent = require(script.Parent)

--//Variables

local Player = Players.LocalPlayer
local ToggleUI = BaseComponent.CreateComponent("ToggleUI", { isAbstract = false }, BaseUISettingsComponent) :: Impl

--//Types
export type SettingOptions = BaseUISettingsComponent.SettingOptions

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseUISettingsComponent.MyImpl)),
}

export type Fields = BaseUISettingsComponent.Fields & {
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ToggleUI", Frame & {}, SettingOptions>
export type Component = BaseComponent.Component<MyImpl, Fields, "ToggleUI", Frame & {}, SettingOptions> 

--//Methods

--@override
function ToggleUI.OnSettingChanged(self: Component, value: boolean) 
	BaseUISettingsComponent.OnSettingChanged(self, value)
	
	local ToggleButton = self.Instance.Content.Toggle :: TextButton
	local ToggleIcon = ToggleButton.Icon :: ImageLabel

	ToggleIcon.ImageTransparency = if value then 0 else 1
end


function ToggleUI.OnConstruct(self: Component, uiController: unknown, SettingOption: SettingOptions)
	BaseUISettingsComponent.OnConstruct(self, uiController, SettingOption)
	
	self:OnSettingChanged(self._LastValue)
end

function ToggleUI.OnConstructClient(self: Component, uiController: unknown)
	BaseUISettingsComponent.OnConstructClient(self, uiController)
	
	local Settings = self.SettingOptions.SettingConstructor
	local ToggleButton = self.Instance.Content.Toggle :: TextButton
	local ToggleIcon = ToggleButton.Icon :: ImageLabel
	
	local Value = self._LastValue

	self.Janitor:Add(ToggleButton.MouseButton1Click:Connect(function()
		
		Value = not Value
		
		self:OnSettingChanged(Value)
		self.OnChanged:Fire(Value)
	end))

	--local Value = self._LastValue

	--ToggleIcon.ImageTransparency = self._LastValue and 0 or 1

	--self.Janitor:Add(ToggleButton.MouseButton1Click:Connect(function()
		
	--	self:OnSettingChanged(not self._LastValue)
	--	print(Value, self._LastValue, "Toggling")
		
	--end))
end

--//Returner

return ToggleUI