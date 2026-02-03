--//Services

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--//Imports

local Promise = require(ReplicatedStorage.Packages.Promise)

local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)
local ClientProducer = require(ReplicatedStorage.Client.ClientProducer)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

local Utility = require(ReplicatedStorage.Shared.Utility)
local EnumsType = require(ReplicatedStorage.Shared.Enums)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

local SettingsUI = require(script.SettingsUI)
local SpectatingUI = require(script.SpectatingUI)
local ShopUI = require(script.ShopUI)

--//Variables

local LocalPlayer = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI.Misc
local LobbyUI = BaseComponent.CreateComponent("LobbyUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	_InitPanel: (self: Component) -> (),
	_ConnectRoleEvents: (self: Component) -> (),
}

export type Fields = {
	
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "LobbyUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "LobbyUI", Frame & any, {}>

--//Methods

function LobbyUI._InitPanel(self: Component)
	
	local Panel = self.Instance.Panel :: Frame
	local SpectatingUIComponent = self.Controller:GetInterface("SpectatingUI")
	local ShopUIComponent = self.Controller:GetInterface("ShopUI")
	local SettingsUIComponent = self.Controller:GetInterface("SettingsUI")
	
	--initials
	
	Panel.Visible = true
	Panel.PlayerName.Text = LocalPlayer.Name
	Panel.DisplayName.Text = LocalPlayer.DisplayName
	
	--applying player's avatar thumbnail
	self.Controller:GetUserThumbnailCallback(LocalPlayer, function(imageId: string)
		Panel.Avatar.Image = imageId or Panel.Avatar.Image
	end)
	
	--syncing with root state
	--TODO: Attempt fix bug doest get the points
	local PlayerStats = ClientProducer.Root:getState(Selectors.SelectStats(LocalPlayer.Name))
	Panel.Points.Text = PlayerStats and PlayerStats.Points or 0

	ClientProducer.Root:subscribe(Selectors.SelectStats(LocalPlayer.Name), function(data)
		Panel.Points.Text = data.Points
	end)
	
	--buttons initials
	
	--enabling paned depending on spectating UI enabled
	SpectatingUIComponent.EnabledChanged:Connect(function(value)
		Panel.Visible = not value
	end)
	
	ShopUIComponent.EnabledChanged:Connect(function(value)
		Panel.Visible = not value
	end)
	
	SettingsUIComponent.EnabledChanged:Connect(function(value)
		Panel.Visible = not value
	end)
	
	CollectionService:GetTagged("SpectateUIButton")[1].MouseButton1Click:Connect(function()
		
		--ignore if not spectator
		if not PlayerController:IsSpectator() 
			or not MatchStateClient:IsRound() then

			return
		end
		
		--toggle spectating UI
		SpectatingUIComponent:SetEnabled(
			not SpectatingUIComponent:IsEnabled()
		)
	end)
	
	CollectionService:GetTagged("SettingsUIButton")[1].MouseButton1Click:Connect(function()
		SettingsUIComponent:SetEnabled(
			not SettingsUIComponent:IsEnabled()
		)
	end)
end

function LobbyUI._ConnectRoleEvents(self: Component)
	
	local SpectatingUIComponent = self.Controller:GetInterface("SpectatingUI")
	local ShopUIComponent = self.Controller:GetInterface("ShopUI")

	--show/hide depending on role
	PlayerController.RoleConfigChanged:Connect(function()
		
		local IsSpectator = PlayerController:IsSpectator()
		self:SetEnabled(IsSpectator)
		
		--disabling if role is not spectator
		if not IsSpectator then
			SpectatingUIComponent:SetEnabled(false)
		end
	end)
	
	--initial enabling
	self:SetEnabled(PlayerController:IsSpectator())
end

function LobbyUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	self.Controller:RegisterInterface(self.Instance.Settings, SettingsUI, self.Controller)
	self.Controller:RegisterInterface(self.Instance.Spectating, SpectatingUI, self.Controller)
	self.Controller:RegisterInterface(self.Instance.Store, ShopUI, self.Controller)
	
	self:_InitPanel()
	self:_ConnectRoleEvents()
	
end

--//Returner

return LobbyUI