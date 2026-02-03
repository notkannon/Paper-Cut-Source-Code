--//Services

local Players = game:GetService("Players")
local Lighting = game:GetService("RunService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--//Imports

local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Classes = require(ReplicatedStorage.Shared.Classes)
local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local BaseUISettingsComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUISettings)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)

local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local InputController = require(ReplicatedStorage.Client.Controllers.InputController)
local SettingsController = require(ReplicatedStorage.Client.Controllers.SettingsController)
local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)
local SettingsConstructors = require(ReplicatedStorage.Shared.Data.UiRelated.SettingsConstructors)

local ClientProducer = require(ReplicatedStorage.Client.ClientProducer)
local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

local DefaultPlayerData = require(ReplicatedStorage.Shared.Data.DefaultPlayerData)
local Keybinds = require(ReplicatedStorage.Shared.Data.Keybinds)

--//Variables

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local UIAssets = ReplicatedStorage.Assets.UI
local UISettingsAssets = ReplicatedStorage.Assets.UI.Settings
local SettingsUI = BaseComponent.CreateComponent("SettingsUI", { isAbstract = false }, BaseUIComponent) :: Impl

local ConfirmationIntent: {Action: "Close" | "Move", Goal: string?}

--// Constants

local UI_KEYBINDS = {
	Enum.UserInputType.MouseButton1,
	Enum.KeyCode.ButtonA,
}

--// Types

export type _setting = {
	Component: BaseUISettingsComponent.Component,
	Value: any?,
}

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	CheckRequiredments: (self: Component, Setting: _setting) -> boolean,
	
	ConstructSettingsTab: (self: Component) -> (),
	ConstructSettingPage: (self: Component, Data: { [string]: SettingsConstructors.MySettings }) -> (),

	_ConnectEvents: (self: Component) -> (),
	_LoadConfig: (self: Component) -> (),
}

export type Fields = {
	TempJanitor: Janitor.Janitor,
	Settings: { [string]: _setting },

	LoadPromise: Promise.Promise,
	KeySelectionLock: boolean,
	_IsModified: boolean,
	_IsLoaded: boolean,

	SettingValueChanged: Signal.Signal<string, any?>,
	
	KeySelectionLockChanged: Signal.Signal<boolean>
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "SettingsUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "SettingsUI", Frame & any, {}>

--//Functions

local function GetLocalBlur(): BlurEffect
	local Blur: BlurEffect
	if Lighting:FindFirstChild("LocalBlur") then
		Blur = Lighting.LocalBlur
	else
		Blur = Instance.new("BlurEffect")
		Blur.Name = "LocalBlur"
		Blur.Size = 0
		Blur.Parent = Lighting
	end

	return Blur
end

--//Methods

function SettingsUI.OnEnabledChanged(self: Component, Value: boolean)
	BaseUIComponent.OnEnabledChanged(self, Value)

	local Confirmation = self.Instance.Confirmation :: Frame
	local SectionsFrame = self.Instance.Sections :: Frame
	local SectionsContent = SectionsFrame.SettingsContent :: ScrollingFrame
	local Blur = GetLocalBlur()
	Blur.Size = Value and 10 or 0
	Blur.Enabled = Value

	if Value then
		if self._IsLoaded then
			self:ConstructSettingPage(SettingsConstructors.Video.Settings)
		end
		Confirmation.Visible = false
		SectionsFrame.Overlay.Visible = false
		SectionsFrame.SettingsContent.Visible = true
	else
		self._IsModified = false
		self.TempJanitor:Cleanup()
		for i,v in pairs(SectionsContent:GetChildren()) do
			if v:IsA("Frame") then
				v:Destroy()
			end
		end
	end
end

function SettingsUI.CheckRequiredments(self: Component, Data: _setting)
	local Component = Data.Component
	local Constructor = Component.SettingOptions.SettingConstructor
	
	if not TableKit.IsEmpty(Constructor.Required) then
		for SettingName, Value in Constructor.Required do
			if not self.Settings[SettingName] then
				continue
			end

			Component:SetEnabled(self.Settings[SettingName].Value == Value)
			return self.Settings[SettingName].Value == Value
		end
	end
	
	return false
end

function SettingsUI.ConstructSettingsTab(self: Component)
	local Bottom = self.Instance.Bottom :: Frame
	local Sections = self.Instance.Sections :: Frame
	local SectionTitle = self.Instance.SectionTitle :: TextLabel

	for _, v in Bottom:GetChildren() do
		if not v:IsA("TextButton") then
			continue
		end

		v:Destroy()
	end

	-- building sections
	for Name, Data in SettingsConstructors do
		local TabButton = UISettingsAssets.Tab:Clone()
		TabButton.LayoutOrder = Data.Order
		TabButton.SettingsName.Text = Data.DisplayName
		TabButton.Parent = Bottom

		self.Janitor:Add(TabButton.MouseButton1Click:Connect(function()
			if self._IsModified then
				ConfirmationIntent = {Action = "Move", Goal = Data.Settings}
				local Confirmation = self.Instance.Confirmation :: Frame
				Confirmation.Visible = true
				Sections.Overlay.Visible = true
				return
			end
			self:ConstructSettingPage(Data.Settings)
		end))

		self.Janitor:Add(TabButton.MouseEnter:Connect(function()
			TabButton.BackgroundColor3 = Color3.fromRGB(170, 170, 170)
		end))

		self.Janitor:Add(TabButton.MouseLeave:Connect(function()
			TabButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		end))
	end
end

function SettingsUI.ConstructSettingPage(self: Component, SettingData: { [string]: SettingsConstructors.MySettings })
	local Bottom = self.Instance.Bottom :: Frame
	local Sections = self.Instance.Sections :: Frame
	local SectionTitle = self.Instance.SectionTitle :: TextLabel

	self.TempJanitor:Cleanup()
	for _, v in Sections.SettingsContent:GetChildren() do
		if not v:IsA("Frame") then
			continue
		end

		local Data = self.Settings[v.Name]
		if Data and Data.Component ~= nil then
			Data.Component:Destroy()
		end
		
		v:Destroy()
	end
	
	local KeybindUIComponents = {}

	for Name, Data in SettingData do

		--print(self.Settings)

		local IsHovering = false
		local ComponentData = {
			SettingName = Name,
			InitialValue = self.Settings[Name].Value,
			SettingConstructor = Data,
		}

		local SettingFrame = UISettingsAssets:FindFirstChild(`{Data.Type}Setting`):Clone() :: Frame
		local SettingComponent: BaseUISettingsComponent.Component = ComponentsManager.Add(SettingFrame, `{Data.Type}UI`, self.Controller, ComponentData) :: BaseUISettingsComponent.Component
		local SettingsTitle = SettingFrame.Content.SettingName :: TextLabel
		SettingFrame.Name = Name
		SettingFrame.Parent = Sections.SettingsContent
		SettingFrame.LayoutOrder = Data.Order or 0
		SettingsTitle.Text = Data.DisplayName

		self.TempJanitor:Add(SettingsTitle.MouseEnter:Connect(function() -- Settings Hovering aspect
			local MouseHoverUIFrame = self.TempJanitor:Add(UISettingsAssets.MouseHoverInformation:Clone(), nil, "SettingTooltip") :: Frame
			local Title = MouseHoverUIFrame.Title :: TextLabel
			local Description = MouseHoverUIFrame.Description :: TextLabel

			Title.Text = Data.DisplayName
			Description.Text = Data.Description

			MouseHoverUIFrame.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
			MouseHoverUIFrame.Parent = self.Instance.Parent.Parent
			IsHovering = true
			while IsHovering do
				task.wait()
				MouseHoverUIFrame.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
			end
		end))
		self.TempJanitor:Add(SettingsTitle.MouseLeave:Connect(function() -- Settings Hovering aspect
			self.TempJanitor:Remove("SettingTooltip")
			IsHovering = false
		end))

		self.TempJanitor:Add(SettingComponent.OnChanged:Connect(function(Value)
			--print(Value, Name)
			self.SettingValueChanged:Fire(Name, Value)
		end))
		
		if Data.Type == "Keybind" then
			table.insert(KeybindUIComponents, SettingComponent)
			--print('keybind lock :fire:', KeybindUIComponents)
			SettingComponent.Janitor:Add(SettingComponent.KeySelectionLockChanged:Connect(function(value: boolean)
				self.KeySelectionLock = value
				--print(value)
				
				for _, Component in ipairs(KeybindUIComponents) do
					Component:SetKeySelectionLock(value)
				end
			end))
		end

		self.Settings[Name].Component = SettingComponent
		self:CheckRequiredments(self.Settings[Name])
	end
end

function SettingsUI._ConnectEvents(self: Component)

	local Bottom = self.Instance.Bottom :: Frame
	local Sections = self.Instance.Sections :: Frame
	local Confirmation = self.Instance.Confirmation :: Frame

	local SectionTitle = self.Instance.SectionTitle :: TextLabel

	local CloseButton = SectionTitle.CloseButton :: TextButton
	local ResetButton = Sections.SettingsContent:FindFirstChild("Reset") :: TextButton

	self.Janitor:Add(CloseButton.MouseButton1Click:Connect(function()
		if self._IsModified then
			Confirmation.Visible = true
			Sections.Overlay.Visible = true
			Sections.SettingsContent.Visible = false
			ConfirmationIntent = {Action = "Close"}
			return
		end

		self:SetEnabled(false)
	end))

	self.Janitor:Add(ResetButton.MouseButton1Click:Connect(function()
		for Name, Data in self.Settings do
			if Data.Component == nil then
				continue
			end

			Data.Component:Reset()
		end
	end))
	
	local function ConfirmationCleanup()
		if ConfirmationIntent.Action == "Close" then
			self:SetEnabled(false)
		elseif ConfirmationIntent.Action == "Move" then
			self:ConstructSettingPage(ConfirmationIntent.Goal)
		end
		self._IsModified = false
		Confirmation.Visible = false
		Sections.Overlay.Visible = false
		Sections.SettingsContent.Visible = true
	end

	self.Janitor:Add(Confirmation.Options.Save.MouseButton1Click:Connect(function()
		self._IsModified = false
		

		for _, Data: _setting in self.Settings do
			if not Data.Component then
				continue
			end

			Data.Component:ApplySetting()
		end

		SettingsController:SaveSettingsRequest()
		
		ConfirmationCleanup()
	end))

	self.Janitor:Add(Confirmation.Options.Cancel.MouseButton1Click:Connect(function()
		Confirmation.Visible = false
		Sections.Overlay.Visible = false
		
		
		for Name, Data in self.Settings do
			if Data.Component == nil or Data.Component._Destroyed or Data.Component._Destroying then
				continue
			end
			
			Data.Component:Reset("Server")
		end
		
		ConfirmationCleanup()
	end))

	self.Janitor:Add(MatchStateClient.MatchEnded:Connect(function()
		self:SetEnabled(false)
		self.TempJanitor:Cleanup()
	end))

	self.Janitor:Add(self.SettingValueChanged:Connect(function(SettingName, Value)
		local Data = self.Settings[SettingName]
		--local IsKeybind = Data.Component.IsKeybind
		if Data.Value == Value then
			return
		end
		
		--if IsKeybind then
		--	for Name, Data in self.Settings do
		--		if Data.Component.IsKeybind then
					
		--		end
		--	end
		--end

		self:CheckRequiredments(Data)

		--print("firing ong")
		Data.Value = Value
		self._IsModified = true -- condition literally didnt matter
	end))
end

function SettingsUI._LoadConfig(self: Component)
	for _, Data in SettingsConstructors do
		local Settings = Data.Settings
		--print(self.Settings)
		for Name, Data in Settings do
			local IsKeybind = Data.Type == "Keybind" -- right?
			local Value = SettingsController:GetSetting(Name, IsKeybind) or SettingsController:GetDefaultSetting(Name, IsKeybind)

			print(Value, IsKeybind, " <- IsKeybind")

			Data.OnChanged(Value)
			self.Settings[Name] = {
				Value = Value
			}
		end
	end
	--print(self.Settings)
end

function SettingsUI.OnConstruct(self: Component, ...)
	BaseUIComponent.OnConstruct(self, ...)

	self.TempJanitor = self.Janitor:Add(Janitor.new())
	self.SettingValueChanged = Signal.new()

	self.Settings = {}

	self._IsModified = false
end

function SettingsUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...) -- does what BaseUIComponent does on creation (necessary)
	
	local function Promised()
		return Promise.new(function(resolve)
			local a = SettingsController.SettingsLoaded:Once(function()
				resolve()
			end)
		end)
	end

	self.LoadPromise = Promised()

	-- custom, SettingsUI-specific behaviour
	self:SetEnabled(false)
	self:ConstructSettingsTab()
	self:_ConnectEvents()
	--self:_LoadConfig()

	self.LoadPromise:andThen(function()
		print("Settings Loaded Successfully")
		self:_LoadConfig()
		
		self._IsLoaded = true
	end)
end

--//Returner

return SettingsUI