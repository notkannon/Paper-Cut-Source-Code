--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local SettingsController = require(ReplicatedStorage.Client.Controllers.SettingsController)
local InputController = require(ReplicatedStorage.Client.Controllers.InputController)

local Enums = require(ReplicatedStorage.Shared.Enums)
local KeyBinds = require(ReplicatedStorage.Shared.Data.Keybinds)
local InterfaceUtility = require(ReplicatedStorage.Client.Utility.InterfaceUtility)

local BaseUISettingsComponent = require(script.Parent)

--//Variables

local Player = Players.LocalPlayer
local KeybindUI = BaseComponent.CreateComponent("KeybindUI", { isAbstract = false }, BaseUISettingsComponent) :: Impl

local UIAssets = ReplicatedStorage.Assets.UI
local Binds = UIAssets.Binds

--//Types
type _keybind = Enum.KeyCode | Enum.UserInputType

export type SettingOptions = BaseUISettingsComponent.SettingOptions
export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseUISettingsComponent.MyImpl)),
	
	GetKeybindNameFromImage: (self: Component, Name: string) -> string | _keybind,
	GetKeybindImage: (self: Component, Name: string) -> string,
	SetKeySelectionLock: (self: Component, value: boolean) -> ()
}

export type Fields = BaseUISettingsComponent.Fields & {
	KeybindListenJanitor: Janitor.Janitor,
	Keybind: {
		Keyboard: _keybind,
		Gamepad: _keybind,
	},
	
	KeyActivationJanitor: Signal.Signal<string>,
	KeySelectionLockChanged: Signal.Signal<boolean>,
	KeySelectionLock: boolean,
	IgnoreRepetiveKeybind: boolean,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "KeybindUI", Frame & {}, SettingOptions>
export type Component = BaseComponent.Component<MyImpl, Fields, "KeybindUI", Frame & {}, SettingOptions> 

--//Methods

--@override
function KeybindUI.OnSettingChanged(self: Component, value: { Gamepad: { _keybind }, Keyboard: { _keybind } })
	local KeybindFrame = self.Instance.Content.Keybind :: Frame
	local ComputerButton = KeybindFrame.Computer :: TextButton
	local ConsoleButton = KeybindFrame.Console :: TextButton
	
	BaseUISettingsComponent.OnSettingChanged(self, value)
	
	local KeyboardInput = ""
	local ConsoleInput = ""
	
	--for Type, Data: { _keybind } in self._LastValue do
	--	for _, Key: _keybind in Data do
	--		local KeybindTypeFrame = (Type == "Keyboard" and ComputerButton) or ConsoleButton
	--		print(Key.Name, Key, Type, "DEBUGGING FOR KEYBIND UI IMAGE") 
	--		local ValidImage = self:GetKeybindImage(Key.Name)

	--		KeybindTypeFrame.Icon.Image = ValidImage
	--	end
	--end
	
	--local ImageInput = self:GetKeybindImage(Type.Name)
	--if not ImageInput then
	--	return
	--end
	print(value)
	for Type, Data: { _keybind } in self._LastValue do
		for _, Key: _keybind in Data do
			local KeybindTypeFrame = (Type == "Keyboard" and ComputerButton) or ConsoleButton
			local Name = Key
			print(Key.Name, Key, Type, "DEBUGGING FOR KEYBIND UI IMAGE") 
			local ValidImage = self:GetKeybindImage(Name)

			KeybindTypeFrame.Icon.Image = ValidImage
		end
	end

	ComputerButton.Visible = true
	ConsoleButton.Visible = true

	KeybindFrame.Display.Visible = false
end

function KeybindUI.GetKeybindImage(self: Component, KeyName: string)
	print(KeyName)
	return InterfaceUtility.GetInputNameToImage(KeyName) or ""
end

function KeybindUI.GetKeybindNameFromImage(self: Component, ImageId: string)
	for Name, Image: string in InterfaceUtility.GetAllImagesID() do
		if Image == ImageId then
			return Name
		end
	end
end

function KeybindUI.SetKeySelectionLock(self: Component, value: boolean)
	self.KeySelectionLock = value
end

function KeybindUI.OnConstruct(self: Component, uiController: unknown, SettingOption: SettingOptions)
	BaseUISettingsComponent.OnConstruct(self, uiController, SettingOption)
	
	self._ApplyMethodName = "ChangeKeybind"
	self.KeybindListenJanitor = self.Janitor:Add(Janitor.new())
	self.KeyActivationJanitor = self.Janitor:Add(Signal.new())
	self.KeySelectionLockChanged = self.Janitor:Add(Signal.new())
	
	self.IgnoreRepetiveKeybind = self.SettingOptions.SettingConstructor.IgnoreRepetiveKeybind or false
	self.KeySelectionLock = false
	
	local KeybindFrame = self.Instance.Content.Keybind :: Frame
	local ComputerButton = KeybindFrame.Computer :: TextButton
	local ConsoleButton = KeybindFrame.Console :: TextButton

	print(self._LastValue)
	
	for Type, Data: { _keybind } in self._LastValue do
		for _, Key: _keybind in Data do
			local KeybindTypeFrame = (Type == "Keyboard" and ComputerButton) or ConsoleButton
			print(Key.Name, Key, Type, "DEBUGGING FOR KEYBIND UI IMAGE") 
			local ValidImage = self:GetKeybindImage(Key.Name)

			KeybindTypeFrame.Icon.Image = ValidImage
		end
	end
	
	self.Janitor:Add(self.KeySelectionLockChanged:Connect(function(value: boolean)
		self.KeySelectionLock = value
	end))
end


function KeybindUI.OnConstructClient(self: Component, uiController: unknown)
	BaseUISettingsComponent.OnConstructClient(self, uiController)
	
	--local KeySelection = self.KeySelectionLock
	local Debounce = false
	local Options = self.SettingOptions
	
	local KeybindFrame = self.Instance.Content.Keybind :: Frame
	local ComputerButton = KeybindFrame.Computer :: TextButton
	local ConsoleButton = KeybindFrame.Console :: TextButton

	--advanced events for the keybind functionally
	self.KeybindListenJanitor:Cleanup()
	
	self.Janitor:Add(ComputerButton.MouseButton1Click:Connect(function() -- ORANGISH, it's :Add not .Add
		if self.KeySelectionLock then
			return
		end
		
		if not InputController:IsKeyboard() then
			return
		end

		self.KeySelectionLockChanged:Fire(true)
		
		KeybindFrame.Display.Text = "Press any key"
		KeybindFrame.Display.Visible = true
		
		ComputerButton.Visible = false
		ConsoleButton.Visible = false
		
		self.KeybindListenJanitor:Add(UserInputService.InputBegan:Connect(function(Input)
			if not self.KeySelectionLock then
				return
			end

			if not InputController:IsKeyboard() then
				return
			end
			
			if not Debounce and Input.KeyCode == Enum.KeyCode.MouseLeftButton then
				Debounce = true
				
				return
			end

			if Input.KeyCode == Enum.KeyCode.Escape then
				ComputerButton.Icon.Visible = true
				KeybindFrame.Display.Visible = false
				self.KeySelectionLockChanged:Fire(false)
				self.KeybindListenJanitor:Cleanup()

				return
			end

			-- trying to not set the same last keycode 
			if self:GetKeybindNameFromImage(ComputerButton.Icon.Image) == Input.KeyCode.Name
				or self:GetKeybindNameFromImage(ComputerButton.Icon.Image) == Input.UserInputType.Name then

				return
			end

			print(Input.KeyCode, "Initial keycode for pc")
			local Type = (Input.KeyCode ~= Enum.KeyCode.Unknown and Input.KeyCode) or (Input.UserInputType ~= Enum.UserInputType.None and Input.UserInputType)
			local SettingData = KeyBinds[Options.SettingName]
			if not SettingData then
				return
			end
			
			print(Type)

			local NewData = {
				Keyboard = { Type }
			}

			NewData = TableKit.MergeDictionary(self._LastValue, NewData)
			
			Debounce = false

			self.KeySelectionLockChanged:Fire(false)
			self:OnSettingChanged(NewData)
			self.KeybindListenJanitor:Cleanup()
		end))
	end))
	
	self.Janitor:Add(ConsoleButton.MouseButton1Click:Connect(function() -- ORANGISH, it's :Add not .Add
		if self.KeySelectionLock then
			return
		end
		
		if not InputController:IsGamepad() then
			return
		end

		self.KeySelectionLockChanged:Fire(true)

		KeybindFrame.Display.Text = "Press any key"
		KeybindFrame.Display.Visible = true
		
		ComputerButton.Visible = false
		ConsoleButton.Visible = false

		self.KeybindListenJanitor:Add(UserInputService.InputBegan:Connect(function(Input)
			if not self.KeySelectionLock then
				return
			end

			if not InputController:IsGamepad() then
				return
			end

			print("Console")

			-- trying to not set the same last keycode 
			if self:GetKeybindNameFromImage(ConsoleButton.Icon.Image) == Input.KeyCode.Name then
				return
			end

			print("Passed 1 gamepad")

			print(Input.KeyCode, "Initial keycode for Console")
			local Type = Input.KeyCode
			local SettingData = KeyBinds[Options.SettingName]
			if not SettingData then
				return
			end

			print("passed 2 gamepad")

			print(Type)

			local NewData = {
				Gamepad = { Type }
			}

			NewData = TableKit.MergeDictionary(self._LastValue, NewData)

			self.KeySelectionLockChanged:Fire(false)

			self:OnSettingChanged(NewData)
			self.KeybindListenJanitor:Cleanup()
		end))
	end))
	
	
end

--//Returner

return KeybindUI