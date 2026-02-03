--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--//Imports
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local Type = require(ReplicatedStorage.Packages.Type)
local Enums = require(ReplicatedStorage.Shared.Enums)
local Classes = require(ReplicatedStorage.Shared.Classes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local DefaultPlayerData = require(ReplicatedStorage.Shared.Data.DefaultPlayerData)
local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)
local ClientProducer = require(ReplicatedStorage.Client.ClientProducer)
local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)

--//Variables

local Player = Players.LocalPlayer

local SettingsController = Classes.CreateSingleton("SettingsController") :: Controller
SettingsController.SettingChanged = Signal.new()
SettingsController.SettingsLoaded = Signal.new()
SettingsController.Settings = {}

--//Types

type _Keybind = Enum.KeyCode | Enum.UserInputType

export type Impl = {
	__index: Impl,

	GetName: () -> "SettingsController",
	GetExtendsFrom: () -> nil,
	IsImpl: (self: Controller) -> boolean,
	
	TableKeybindToString: (self: Controller, Action: string, Data: { any? }) -> { string },
	StringKeybindToTable: (self: Controller, Data: string) -> { Keyboard: { any }, Gamepad: { any } },
	
	GetSetting: (self: Controller, setting: string, isKeybind: boolean) -> any,
	GetDefaultSetting: (self: Controller, setting: string, isKeybind: boolean) -> any,
	GetKeybindSetting: (self: Controller, Keybind: string) -> { Keyboard: { any }, Gamepad: { any } },
	GetFullKeybindString: (seLf: Controller, Keybind: string, IsController: boolean) -> _Keybind,
	--GetFullKeybindActions: (self: Controller, Action: string) -> {string},
	
	ChangeKeybind: (self: Controller, Keybind: string, Value: { any? }) -> (),
	ChangeSetting: (self: Controller, setting: string, to: any) -> (),
	--ApplySettingValue: (self: Controller, setting: string, value: any) -> (),
	SaveSettingsRequest: (self: Controller) -> (),
	
	new: () -> Controller,
	OnConstruct: (self: Controller) -> (),
	OnConstructServer: (self: Controller) -> (),
	OnConstructClient: (self: Controller) -> (),
}

export type Fields = {
	Settings: DefaultPlayerData.ClientSettings,
	SettingChanged: Signal.Signal<string, any>,
	SettingsLoaded: Signal.Signal,
}

export type Controller = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Functions

local function ApplySettingValue(setting: string, value: any)
	SettingsController.Settings[setting] = value
	SettingsController.SettingChanged:Fire(setting, value)
	
	print(SettingsController.Settings, "All Settings", setting, "The setting we changed to", value)
end

--//Methods

function SettingsController.TableKeybindToString(self: Controller, Action: string, DataTable: { any? }): { string }
	local Data: { string } = {}
	for DeviceName, Keybinds: { _Keybind? } in DataTable do
		for _, Input in Keybinds do
			table.insert(Data, `{Action}:{DeviceName}:{Input}`)
		end
	end
	
	return Data
end

function SettingsController.StringKeybindToTable(self: Controller, DataString: string)
	local DataKeybinds = { Keyboard = {}, Gamepad = {} }

	local Data = DataString:split(":")
	local Action = Data[1]
	local DeviceName = Data[2]
	local SplitedKeybind = Data[3]:split(".")
	local KeyName = SplitedKeybind[3]
	-- maybe this will work. if no, well idk :sob:
	local MergedKeybind = Enum[SplitedKeybind[2]][KeyName]
	--print(MergedKeybind)
	
	if DeviceName == "Keyboard" then
		table.insert(DataKeybinds.Keyboard, MergedKeybind)
	elseif DeviceName == "Gamepad" then
		table.insert(DataKeybinds.Gamepad, MergedKeybind)
	end
	
	return DataKeybinds
end

function SettingsController.GetFullKeybindString(self: Controller, KeybindName: string, IsController: boolean)
	local Keybinds = self:GetSetting("Keybinds")
	if not Keybinds then
		return
	end
	
	local Name = ""
	local Prefix = IsController and "Gamepad" or "Keyboard"
	for _, KeybindData: string in Keybinds do
		local Data = KeybindData:split(":")
		if Data[1] == KeybindName then
			if Data[2] ~= Prefix then
				continue
			end
			
			Name = KeybindData
			break
		end
	end
	
	return Name
end

function SettingsController.GetKeybindSetting(self: Controller, KeybindName: string)
	local Keybinds = self:GetSetting("Keybinds")
	if not Keybinds then
		return
	end
	
	local Data = {
		Keyboard = {},
		Gamepad = {}
	}
	
	for _, Action: string in Keybinds do
		if Action:split(":")[1] ~= KeybindName then
			continue
		end

		local DataSplited = Action:split(":")
		local Device = DataSplited[2]
		local Inputs = DataSplited[3]:split(".")

		local TableToSave = Data[Device]
		local KeyEnum = Enum[Inputs[2]][Inputs[3]]

		table.insert(TableToSave, KeyEnum)
		--print(TableToSave, KeyEnum)
	end

	--print(Data, "Data keybinds", KeybindName)
	
	return Data
end

function SettingsController.ChangeKeybind(self: Controller, Keybind: string, Data: { Keyboard: {any}, Gamepad: { any }})
	local InitialKeybinds = self:GetSetting("Keybinds")
	if not InitialKeybinds then
		return
	end
	
	--getting the last input
	local KeyboardInfoPos = table.find(InitialKeybinds, self:GetFullKeybindString(Keybind, false))
	local GamepadInfoPos = table.find(InitialKeybinds, self:GetFullKeybindString(Keybind, true))
	
	print(KeyboardInfoPos, GamepadInfoPos)
	
	--transforming table to string
	local Keybinds = self:TableKeybindToString(Keybind, Data)
	local Keyboard = Keybinds[1]
	local Gamepad = Keybinds[2]
	
	--overwriting the posision its locaded
	local NewData = InitialKeybinds
	NewData[KeyboardInfoPos] = Keyboard
	NewData[GamepadInfoPos] = Gamepad
	
	print("Newdata: ", Data, "LastData: ", InitialKeybinds)
	ApplySettingValue("Keybinds", NewData)
end

function SettingsController.SaveSettingsRequest(self: Controller)
	--print(self.Settings)
	ClientRemotes.ClientSettingSaveRequest.Fire(self.Settings)
end

function SettingsController.GetSetting(self: Controller, Setting: string, IsKeybind: boolean, useFromSettings: boolean)
	local SettingData = ClientProducer.Root:getState(Selectors.SelectSettings(Player.Name))
	
	if useFromSettings then
		SettingData = SettingsController.Settings
	end
	
	if not SettingData then
		return nil
	end
	
	local Data = SettingData
	local Result
	if not Data then
		return nil
	end
	
	if IsKeybind then
		Result = self:GetKeybindSetting(Setting)
	else
		Result = Data[Setting]
	end
	
--	print(SettingData, Setting, SettingData and SettingData[Setting], Result)
	return Result
end

function SettingsController.GetDefaultSetting(self: Controller, Setting: string, IsKeybind: boolean)
	if IsKeybind == nil then
		IsKeybind = false
	end

	local Base = DefaultPlayerData.Save.ClientSettings
	local Scope
	
	-- BTW also check :GetSetting, it also has IsKeybind
	
	if IsKeybind then
		local Data = {
			Keyboard = {},
			Gamepad = {}
		}
		
		for _, Action: string in Base.Keybinds do
			if Action:split(":")[1] ~= Setting then
				continue
			end

			local DataSplited = Action:split(":")
			local Device = DataSplited[2]
			local Inputs = DataSplited[3]:split(".")

			local TableToSave = Data[Device]
			local KeyEnum = Enum[Inputs[2]][Inputs[3]]

			table.insert(TableToSave, KeyEnum)
			--print(TableToSave, KeyEnum)
		end
		
		Scope = Data
	else
		Scope = Base[Setting]
	end
	
	return Scope
end

-- make it awaitable?
function SettingsController.ChangeSetting(self: Controller, setting: string, to: any)
	Type.strict(Type[typeof(self.Settings[setting])])(to)
	ApplySettingValue(setting, to)
end

function SettingsController.OnConstructClient(self: Controller)
	local SettingsData = ClientProducer.Root:getState(Selectors.SelectSettings(Player.Name))
	--print(SettingsData)
	
	if SettingsData then
		for Setting, Value in pairs(SettingsData) do
			if self.Settings[Setting] == nil then
				continue
			end
			
			ApplySettingValue(Setting, Value)
		end
	end
	
	ClientProducer.Root:once(Selectors.SelectSettings(Player.Name), function()
		--print(ClientProducer.Root:getState(Selectors.SelectSettings(Player.Name)))
		SettingsController.SettingsLoaded:Fire()
	end)
	
	ClientProducer.Root:subscribe(Selectors.SelectSettings(Player.Name), function(newSettings)
		for Setting, Value in pairs(newSettings) do
			if self.Settings[Setting] == Value then
				print("Yuh uh", Setting, Value)
				continue
			end
			
			--print(SettingsData, Setting, Value)
			ApplySettingValue(Setting, Value)
		end
	end)
end

--//Returner

local Controller = SettingsController.new()
return Controller