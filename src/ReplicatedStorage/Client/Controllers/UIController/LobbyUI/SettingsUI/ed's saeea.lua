----//Services

--local Players = game:GetService("Players")
--local Lighting = game:GetService("Lighting")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local UserInputService = game:GetService("UserInputService")

----//Imports

--local Signal = require(ReplicatedStorage.Packages.Signal)
--local Janitor = require(ReplicatedStorage.Packages.Janitor)
--local Classes = require(ReplicatedStorage.Shared.Classes)
--local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)

--local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
--local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
--local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
--local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)

--local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
--local InputController = require(ReplicatedStorage.Client.Controllers.InputController)
--local SettingsController = require(ReplicatedStorage.Client.Controllers.SettingsController)
--local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)

--local Utility = require(ReplicatedStorage.Shared.Utility)
--local EnumsType = require(ReplicatedStorage.Shared.Enums)
--local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
--local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
--local MusicUtility = require(ReplicatedStorage.Client.Utility.MusicUtility)


--local DefaultPlayerData = require(ReplicatedStorage.Shared.Data.DefaultPlayerData)

--local SettingsConstructors = require(ReplicatedStorage.Shared.Data.UiRelated.SettingsConstructors)

----//Variables

--local LocalPlayer = Players.LocalPlayer
--local Mouse = LocalPlayer:GetMouse()
--local UIAssets = ReplicatedStorage.Assets.UI
--local UISettingsAssets = ReplicatedStorage.Assets.UI.Settings
--local SettingsUI = BaseComponent.CreateComponent("SettingsUI", { isAbstract = false }, BaseUIComponent) :: Impl

----// Constants
--local UI_KEYBINDS = {
--	Enum.UserInputType.MouseButton1,
--	Enum.KeyCode.ButtonA,
--}

----//Types
--export type _setting = {
--	Name: string,
--	Description: string,
--	Type: SettingsConstructors.MyOptionType,
--	InitialValue: string | number | boolean,
--	Requirements: { [string]: any }
--}

--export type Settings = {
--	Object: Instance,
--	Config: _setting,
--	Value: string | number | boolean
--}

--export type MyImpl = {
--	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
--	ChangeValues: (self: Component, Setting: string, Value: any) -> (),
--	ValidRequirements: (self: Component, Setting: string) -> boolean,
	
--	_ConnectUiEvents: (self: Component) -> (),
--	_ConnectMatchEvents: (self: Component) -> (),
	
--	_ConstructPages: (self: Component) -> (),
--	_ConstructSettings: (self: Component, SettingsConstructor: SettingsConstructors.MySection) -> (),
	
--	_LoadSettings: (self: Component) -> (),
--	--_UpdateSetting: (self: Component, setting: _setting, value: any) -> ()
--}

--export type Fields = {
--	JanitorSettings: Janitor.Janitor,
	
--	_IsModified: boolean,
--	_IsInConfirmation: boolean,
--	Settings: { [string]: Settings },
--	PreSavedSettings: { string },
	
--	PageChanged: Signal.Signal<string>,
--	SettingsValueChanged: Signal.Signal<string, string | number | boolean>
--} & BaseUIComponent.Fields
--export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "SettingsUI", Frame & any, {}>
--export type Component = BaseComponent.Component<MyImpl, Fields, "SettingsUI", Frame & any, {}>

----//Methods

--local function Snap(value, Snapvalue) -- just a function for the other function below
--	return value - (value % Snapvalue)
--end

--local function GetLocalBlur(): BlurEffect
--	local Blur: BlurEffect
--	if Lighting:FindFirstChild("LocalBlur") then
--		Blur = Lighting.LocalBlur
--	else
--		Blur = Instance.new("BlurEffect")
--		Blur.Name = "LocalBlur"
--		Blur.Size = 0
--		Blur.Parent = Lighting
--	end
	
--	return Blur
--end

--function SettingsUI.ValidRequirements(self: Component, Setting: string)
--	if not self.Settings[Setting] then
--		return false
--	end
	
--	local Data = self.Settings[Setting].Config
--	if not Data.Requirements then
--		return true
--	end
	
--	for SettingName, Value in Data.Requirements do
--		local SettingDataValue = SettingsController:GetSetting(Setting)
--		print(SettingDataValue)
		
--		if SettingDataValue ~= Value then
--			return false
--		end
		
--		return true
--	end
	
--	return false
--end

--function SettingsUI.OnEnabledChanged(self: Component, value: boolean)
--	self.Instance.Visible = value
--	self:_ConstructSettings(SettingsConstructors.Video.Settings)
	
--	local Blur = GetLocalBlur()
--	print('setting blur', Blur, 'to', value and 16 or 0)
--	Blur.Size = value and 16 or 0
	
--	if value then
--		local ConfirmationFrame = self.Instance.Confirmation :: Frame
--		local Overlay = self.Instance.Sections.Overlay :: Frame
--		ConfirmationFrame.Visible = false
--		Overlay.Visible = false
--	else
--		self.JanitorSettings:Cleanup()
--		self._IsInConfirmation = false
--	end
--end

--function SettingsUI._ConnectUiEvents(self: Component)
--	local ConfirmationFrame = self.Instance.Confirmation :: Frame
--	local SaveButton = ConfirmationFrame.Options.Save :: TextButton
--	local CancelButton = ConfirmationFrame.Options.Cancel :: TextButton
--	local Overlay = self.Instance.Sections.Overlay :: Frame
	
--	self.Janitor:Add(self.Instance.SectionTitle.CloseButton.MouseButton1Click:Connect(function()
--		if self._IsModified then
--			self._IsInConfirmation = true
--			ConfirmationFrame.Visible = true
--			Overlay.Visible = true
--			self.JanitorSettings:Cleanup()
--		else
--			self:SetEnabled(false)
--		end
--	end))
	
--	self.Janitor:Add(SaveButton.MouseButton1Click:Connect(function()
--		self._IsModified = false
--		SettingsController:SaveSettingsRequest()
--		self:SetEnabled(false)
--	end))
	
--	self.Janitor:Add(CancelButton.MouseButton1Click:Connect(function()
--		self._IsModified = false
--		self:_LoadSettings()
--		self:SetEnabled(false)
--	end))

		
	
--	self.Janitor:Add(self.SettingsValueChanged:Connect(function(SettingsName, Value)
--		if not self._IsModified then
--			--self.Instance.Sections.SettingsContent.SaveButton.Visible = true 
--			self._IsModified = true
--		end
		
--		-- changing values
--		local Setting = self.Settings[SettingsName]
--		if not Setting then
--			return
--		end
		
--		if Setting.Value == Value then
--			return
--		end
		
--		Setting.Value = Value
		
--		--updating ui
--		--for SettingName, Data in self.Settings do
--		--	print("test")
--		--	if not Data.Object then -- that means the setting isnt from current tab
--		--		return
--		--	end
--		--	Data.Object.Visible = self:ValidRequirements(SettingsName)
--		--end
--		--Sending slices
--		SettingsController:ChangeSetting(SettingsName, Value)
--	end))
--end

--function SettingsUI._ConnectMatchEvents(self: Component)
--	self.Janitor:Add(MatchStateClient.MatchEnded:Connect(function()
--		self:SetEnabled(false)
--		self.JanitorSettings:Cleanup()
--	end))
--end

--function SettingsUI._ConstructPages(self: Component)

--	local Bottom = self.Instance.Bottom :: Frame
--	local Sections = self.Instance.Sections :: Frame
--	local SectionTitle = self.Instance.SectionTitle :: TextLabel

--	-- cleanning tabs and sections
--	for _, v in Bottom:GetChildren() do
--		if not v:IsA("TextButton") then
--			continue
--		end

--		v:Destroy()
--	end

--	-- building sections
--	for SectionName, SectionData in SettingsConstructors do
--		local Data = {
--			Name = SectionData.DisplayName,
--			Order = SectionData.Order,
--			Image = SectionData.Image
--		}

--		local TabButton = UISettingsAssets.Tab:Clone() :: TextButton

--		TabButton.Parent = self.Instance.Bottom
--		TabButton.SettingsName.Text = Data.Name
--		TabButton.LayoutOrder = Data.Order
		
--		self.Janitor:Add(TabButton.MouseButton1Click:Connect(function()
--			if self._IsInConfirmation then
--				return
--			end
			
--			--Sections.SettingsContent.Settings.Content.Title.Text = Data.DisplayName
--			--Sections.SettingsContent.Settings.Content.Description.Text = Data.Description
--			self.PageChanged:Fire(SectionName)
			
--			self:_ConstructSettings(SectionData.Settings)
--		end))
--		self.Janitor:Add(TabButton.MouseEnter:Connect(function()
--			TabButton.BackgroundColor3 = Color3.fromRGB(170,170,170)
--		end))
--		self.Janitor:Add(TabButton.MouseLeave:Connect(function()
--			TabButton.BackgroundColor3 = Color3.fromRGB(0,0,0)
--		end))
--	end

--end

--function SettingsUI._ConstructSettings(self: Component, SettingsSection: SettingsConstructors.MySection) -- comments by orange!
	
--	local Bottom = self.Instance.Bottom :: Frame
--	local Sections = self.Instance.Sections :: Frame
--	local SectionTitle = self.Instance.SectionTitle :: TextLabel
	
--	-- its ok
--	for i,v in pairs(self.Instance.Sections.SettingsContent:GetChildren()) do -- Destroys ALL previous settings already there
--		if not v:IsA("Frame") then
--			continue
--		end
		
--		v:Destroy()
--	end
	
--	self.JanitorSettings:Cleanup()
--	for SettingsName, SettingsData: SettingsConstructors.MySettings in SettingsSection do
--		local IsHovering = false
--		local SettingFrame = UISettingsAssets:FindFirstChild(`{SettingsData.Type}Setting`):Clone()
--		local SettingsTitle = SettingFrame.Content.SettingName :: TextLabel
		
--		local Data = {
--			Name = SettingsData.DisplayName,
--			Description = SettingsData.Description,
--			Type = SettingsData.Type,
--			InitialValue = SettingsData.InitialValue,
--			CurrentValue = nil,
--			Requirements = SettingsData.Require,
--			_IsModified = false
--		}
		
--		SettingFrame.Name = SettingsName
--		SettingsTitle.Text = Data.Name
--		SettingFrame.Parent = self.Instance.Sections.SettingsContent
		
--		--registery settingadded
--		if not self.Settings[SettingsName] then
--			self.Settings[SettingsName] = {
--				Object = SettingFrame,
--				Config = Data,
--				Value = Data.InitialValue
--			}
--		else
--			self.Settings[SettingsName].Object = SettingFrame
--		end
		
--		-- checking Requirements
--		if not self:ValidRequirements(SettingsName) then
--			SettingFrame.Visible = false
--		end
		
--		self.JanitorSettings:Add(SettingsTitle.MouseEnter:Connect(function() -- Settings Hovering aspect
--			local MouseHoverUIFrame = self.JanitorSettings:Add(UISettingsAssets.MouseHoverInformation:Clone(), nil, "SettingTooltip") :: Frame
--			local Title = MouseHoverUIFrame.Title :: TextLabel
--			local Description = MouseHoverUIFrame.Description :: TextLabel
			
--			Title.Text = Data.Name
--			Description.Text = Data.Description
			
--			MouseHoverUIFrame.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
--			MouseHoverUIFrame.Parent = self.Instance.Parent.Parent
--			IsHovering = true
--			while IsHovering do
--				task.wait()
--				MouseHoverUIFrame.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
--			end
--		end))
--		self.JanitorSettings:Add(SettingsTitle.MouseLeave:Connect(function() -- Settings Hovering aspect
--			self.JanitorSettings:Remove("SettingTooltip")
--			IsHovering = false
--		end))
		
--		local InitialValue = self.Settings[SettingsName].Value

--		if Data._IsModified == false then
--			InitialValue = (SettingsController:GetSetting(SettingsName) ~= nil and SettingsController:GetSetting(SettingsName)) 
--				or self.Settings[SettingsName].Value
--		else
--			InitialValue = self.Settings[SettingsName].Value
--		end
--	end
--end

--function SettingsUI._LoadSettings(self: Component)
--	for _, SectionData in SettingsConstructors do
--		print("", SectionData)
--		for Name, Data in SectionData.Settings do
--			local SettingData = SettingsController:GetSetting(Name)
--			--print(SettingData)
--			if SettingData then
--				Data.OnChanged(SettingData)
--			end

--			--registery
--			self.Settings[Name] = {
--				Config = Data,
--				Value = Data.InitialValue
--			}
--		end
--	end
--end

--function SettingsUI.OnConstruct(self: Component, ...)
--	BaseUIComponent.OnConstruct(self, ...)
	
--	self._IsModified = false
	
--	self.Settings = {}
--	self.PreSavedSettings = {}
	
--	self.JanitorSettings = self.Janitor:Add(Janitor.new())
--	self.PageChanged = Signal.new()
--	self.SettingsValueChanged = Signal.new()
--end

--function SettingsUI.OnConstructClient(self: Component, ...)
--	BaseUIComponent.OnConstructClient(self, ...) -- does what BaseUIComponent does on creation (necessary)
	
--	-- custom, SettingsUI-specific behaviour
--	self:SetEnabled(false)
--	self:_ConnectUiEvents()
--	self:_ConnectMatchEvents()
--	self:_ConstructPages()
	
--	self:_LoadSettings()
--end

----//Returner

--return SettingsUI
return nil