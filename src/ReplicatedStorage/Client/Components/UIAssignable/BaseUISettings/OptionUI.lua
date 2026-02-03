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
local OptionUI = BaseComponent.CreateComponent("OptionUI", { isAbstract = false }, BaseUISettingsComponent) :: Impl

--//Types
export type SettingOptions = BaseUISettingsComponent.SettingOptions

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseUISettingsComponent.MyImpl)),
}

export type Fields = BaseUISettingsComponent.Fields & {
	OptionList: { string },
	IndexSelected: number
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "OptionUI", Frame & {}, SettingOptions>
export type Component = BaseComponent.Component<MyImpl, Fields, "OptionUI", Frame & {}, SettingOptions> 

--//Methods

--@override
function OptionUI.OnSettingChanged(self: Component, value: boolean) 
	BaseUISettingsComponent.OnSettingChanged(self, value)
end


function OptionUI.OnConstruct(self: Component, uiController: unknown, SettingOption: SettingOptions)
	BaseUISettingsComponent.OnConstruct(self, uiController, SettingOption)
	
	self.OptionList = SettingOption.SettingConstructor.OptionList
	self.IndexSelected = self._LastValue 
end


function OptionUI.OnConstructClient(self: Component, uiController: unknown)
	BaseUISettingsComponent.OnConstructClient(self, uiController)
	
	local Constructor = self.SettingOptions.SettingConstructor
	local OptionFrame = self.Instance.Content.Option :: Frame
	local Title = OptionFrame.OptionName :: TextLabel
	
	local LeftButton = OptionFrame.Left :: TextButton
	local RightButton = OptionFrame.Right :: TextButton
	
	Title.Text = Constructor.OptionList[self.IndexSelected]
	
	self.Janitor:Add(LeftButton.MouseButton1Click:Connect(function()
		self.IndexSelected -= 1
		
		if self.IndexSelected < 1 then
			self.IndexSelected = #self.OptionList
		end
		
		Title.Text = Constructor.OptionList[self.IndexSelected]
		self:OnSettingChanged(self.IndexSelected)
		--self.OnChanged:Fire()
	end))
	
	self.Janitor:Add(RightButton.MouseButton1Click:Connect(function()
		self.IndexSelected += 1
		
		if self.IndexSelected > #self.OptionList then
			self.IndexSelected = 1
		end
		
		Title.Text = Constructor.OptionList[self.IndexSelected]
		self:OnSettingChanged(self.IndexSelected)
		--self.OnChanged:Fire()
	end))
end

--//Returner

return OptionUI