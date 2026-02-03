--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local SettingsConstructors = require(ReplicatedStorage.Shared.Data.UiRelated.SettingsConstructors)
local SettingsController = require(ReplicatedStorage.Client.Controllers.SettingsController)

local BaseUIComponent = require(script.Parent.BaseUI)

local TableKit = require(ReplicatedStorage.Packages.TableKit)

--//Variables

local BaseUISettings = BaseComponent.CreateComponent("BaseUISettings", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types
export type SettingOptions = {
	SettingName: string,
	InitialValue: any?,
	IsKeybinds: boolean?,
	SettingConstructor: SettingsConstructors.MySettings,
}

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl)),
	
	OnSettingChanged: (self: Component, Value: any) -> (),
	OnResetSetting: (self: Component) -> (),
	
	SetValue: (self: Component, value: any) -> (),
	
	_IsModifiedSetting: (self: Component) -> boolean,
	Reset: (self: Component) -> (),
	ApplySetting: (self: Component) -> (),
}

export type Fields = BaseUIComponent.Fields & {
	SettingOptions: SettingOptions,
	OnChanged: Signal.Signal<any>,
	
	_IsModified: boolean,
	_LastValue: any?,
	_ApplyMethodName: string,
	
	IsKeybind: boolean
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseUISettings", Frame & {}, SettingOptions>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseUISettings", Frame & {}, SettingOptions> 

--//Methods

--@override
function BaseUISettings.OnSettingChanged(self: Component, value: boolean)
	local Data = self.SettingOptions.SettingConstructor
	
	self._LastValue = value
	self._IsModified = true
	
	Data.OnChanged(value)
	self.OnChanged:Fire(value)
	
	self.Instance.Content.ResetButton.Visible = self:_IsModifiedSetting()
end

--@override
function BaseUISettings.OnResetSetting(self: Component, value: boolean) end

function BaseUISettings._IsModifiedSetting(self: Component)
	local DefaultValue = SettingsController:GetDefaultSetting(self.SettingOptions.SettingName, self.IsKeybind)
	local CurrentValue = self._LastValue
	
	-- need a way to test for tables! cuz {} == {} is false
	if type(DefaultValue) == "table" and type(CurrentValue) == "table" then
		return not TableKit.CompareTables(DefaultValue, CurrentValue)
	end
	
	return CurrentValue ~= DefaultValue
end

function BaseUISettings.Reset(self: Component, mode: "Default" | "Server")
	if mode == nil then mode = "Default" end
	
	if not self:_IsModifiedSetting() and mode == "Default" then
		return
	end
	local Value
	
	if mode == "Default" then
		Value = SettingsController:GetDefaultSetting(self.SettingOptions.SettingName, self.IsKeybind)
	elseif mode == "Server" then
		Value = SettingsController:GetSetting(self.SettingOptions.SettingName, self.IsKeybind)
	end
	
	print(Value, 'resetting: ', mode , self.Instance)
	self:OnSettingChanged(Value)
	self:OnResetSetting()
	
	self.Instance.Content.ResetButton.Visible = self:_IsModifiedSetting()
end

function BaseUISettings.ApplySetting(self: Component)
	if not self._IsModified then
		return
	end
	
	if SettingsController:GetSetting(self.SettingOptions.SettingName) == self._LastValue then
		return
	end
	
	--print("settings applied")
	
	self._IsModified = false
	SettingsController[self._ApplyMethodName](SettingsController, self.SettingOptions.SettingName, self._LastValue)
end

function BaseUISettings.OnConstruct(self: Component, uiController: unknown, SettingOption: SettingOptions)
	BaseUIComponent.OnConstruct(self, uiController) 
	
	local IsKeybind = SettingOption.SettingConstructor.Type == "Keybind"
	local Value = (SettingsController:GetSetting(SettingOption.SettingName, IsKeybind, true) 
		or SettingsController:GetDefaultSetting(SettingOption.SettingName, IsKeybind))

	self.SettingOptions = SettingOption
	self.OnChanged = self.Janitor:Add(Signal.new())
	
	--print(SettingsController:GetKeybindSetting(SettingOption.SettingName))
	print(self.SettingOptions.SettingConstructor.InitialValue, Value)
	self._LastValue = Value
	self.IsKeybind = IsKeybind
	self._IsModified = false
	self._ApplyMethodName = "ChangeSetting"
end

function BaseUISettings.OnConstructClient(self: Component, uiController: unknown)
	BaseUIComponent.OnConstructClient(self, uiController)
	
	local SettingsConstructor = self.SettingOptions.SettingConstructor
	
	-- applying initial values
	self.Instance.Content.ResetButton.Visible = self:_IsModifiedSetting()
	self.Instance.Content.SettingName.Text = self.SettingOptions.SettingConstructor.DisplayName
	
	-- applying changes
	if SettingsConstructor.OnChanged then
		SettingsConstructor.OnChanged(self._LastValue)
	end
	
	--connecting events
	self.Janitor:Add(self.Instance.Content.ResetButton.MouseButton1Click:Connect(function()
		print('resetting')
		self:Reset()
	end))
	
	self.Janitor:Add(SettingsController.SettingChanged:Connect(function(Name, Value)
		if Name ~= self.SettingOptions.SettingName then
			return
		end
		
		if self:IsDestroying() then
			return
		end
		
		if SettingsController:GetSetting(self.SettingOptions.SettingName, self.IsKeybind) == Value then
			return
		end
		
		self:OnSettingChanged(Value)
	end))
end

function BaseUISettings.OnDestroy(self: Component)
	BaseUIComponent.OnDestroy(self)
	
	self.Janitor:Cleanup()
end

--//Returner

return BaseUISettings