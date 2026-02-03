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
local TextBoxUI = BaseComponent.CreateComponent("TextBoxUI", { isAbstract = false }, BaseUISettingsComponent) :: Impl

--//Types
export type SettingOptions = BaseUISettingsComponent.SettingOptions

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseUISettingsComponent.MyImpl)),
}

export type Fields = BaseUISettingsComponent.Fields & {
	LastText: string
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "TextBoxUI", Frame & {}, SettingOptions>
export type Component = BaseComponent.Component<MyImpl, Fields, "TextBoxUI", Frame & {}, SettingOptions> 

--//Methods

--@override
function TextBoxUI.OnSettingChanged(self: Component, value: boolean) 
	BaseUISettingsComponent.OnSettingChanged(self, value)
end


function TextBoxUI.OnConstruct(self: Component, uiController: unknown, SettingOption: SettingOptions)
	BaseUISettingsComponent.OnConstruct(self, uiController, SettingOption)
	
	self.LastText = self._LastValue
end


function TextBoxUI.OnConstructClient(self: Component, uiController: unknown)
	BaseUISettingsComponent.OnConstructClient(self, uiController)
	
	local Settings = self.SettingOptions.SettingConstructor
	local Textbox = self.Instance.Content.TextBox.TextBox :: TextBox
	
	Textbox.Text = self._LastValue or ""
	
	self.Janitor:Add(Textbox.FocusLost:Connect(function()
		local Value = Textbox.Text
		self:OnSettingChanged(Value)
		self.OnChanged:Fire()
	end))
end

--//Returner

return TextBoxUI