--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local UITypes = require(ReplicatedStorage.Client.Types.UITypes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local BaseUI = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)

local LobbyUI = require(script.LobbyUI)
local DebugUIComponent = require(script.DebugUI)
local CursorUIComponent = require(script.CursorUI)
local GameplayUIComponent = require(script.GameplayUI)
local PreloadingUIComponent = require(script.PreloadingUI)
local NotificationUIComponent = require(script.NotificationUI)
local InteractionUIComponent = require(script.InteractionUI)

--//Variables

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UIAssets = ReplicatedStorage.Assets.UI

local UIController: Impl = Classes.CreateSingleton("UIController") :: Impl

--//Types

type AnyInterfaceName =
	"DebugUI"
| "CursorUI"
| "GameplayUI"
| "PreloadingUI"
| "NotificationUI"

export type InterfaceOptions = {
	Parent: BaseUI.Component?,
	Children: { BaseUI.Component }?,
}

export type InterfaceData = {
	Component: BaseUI.Component,
} & InterfaceOptions

export type Impl = {
	__index: Impl,

	GetName: () -> "UIController",
	GetExtendsFrom: () -> nil,
	IsImpl: (self: Controller) -> boolean,

	--GetInterfaceData: (self: Controller, component: BaseUI.Component) -> ({ Component: BaseUI.Component } & InterfaceOptions)?,
	GetInterface: (self: Controller, name: AnyInterfaceName) -> BaseUI.Component?,
	ToggleInterface: (self: Controller, name: AnyInterfaceName, value: boolean) -> (),
	RegisterInterface: (self: Controller, instance: Instance, impl: BaseUI.Impl, ...any) -> BaseUI.Component,
	GetUserThumbnailCallback: (self: Controller, player: Player, callback: (imageId: string) -> ()) -> (),

	new: () -> Controller,
	OnConstructClient: (self: Controller) -> (),

	_ForceCoreDisable: (self: Controller) -> (),
}

export type Fields = {
	
	Instance: typeof(StarterGui.Interface),
	
	Interfaces: { BaseUI.Component },
	InterfaceAdded: Signal.Signal<BaseUI.Component>,
	InterfaceEnabledChanged: Signal.Signal<BaseUI.Component, boolean>,
}

export type Controller = typeof(setmetatable({} :: Fields, UIController :: Impl))

--//Methods

function UIController._ForceCoreDisable()
	local Attempt = 0
	local Success = false

	task.spawn(function()

		while Attempt < 5 and not Success do

			Success = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
				--StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			end)

			Attempt += 1
		end
	end)
end

function UIController.ToggleInterface(self: Controller, name: AnyInterfaceName, value: boolean)
	
	local Interface = self:GetInterface(name)
	
	if not Interface then
		return
	end
	
	Interface:SetEnabled(value)
end

function UIController.GetInterface(self: Controller, name: AnyInterfaceName)

	for _, Interface in ipairs(self.Interfaces) do

		if Interface.GetName() == name then
			return Interface
		end
	end
end

function UIController.GetButtonComponent(self: Controller, name: string)
	
	for _, Component in ipairs(ComponentsManager.GetInstances("BaseUIButton")) do
		
		if Component.Instance.Name == name then
			
			return Component
		end
	end
end

function UIController.GetUserThumbnailCallback(self: Controller, player: Player, callback: (imageId: string) -> ())
	local function GetPromise()
		return Promise.new(function(resolve, reject)
			local UserThumbnail = Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size180x180
			)

			if not UserThumbnail then
				reject()
				return
			end
			
			resolve(UserThumbnail)
		end)
	end
	
	Promise.retryWithDelay(GetPromise, 5, 5):andThen(callback, function()
		warn("Failed to load User Thumbnail for", Player)
	end)
end

--function UIController.GetInterfaceData(self: Controller, component: BaseUI.Component)

--	for _, Interface in ipairs(self.Interfaces) do

--		if Interface.Component == component then

--			return Interface
--		end
--	end
--end

function UIController.RegisterInterface(self: Controller, instance: Instance, impl: BaseUI.Impl, ...: any?)
	
	----repeat check
	--if self:GetInterfaceData(component) then
	--	warn(`Interface { component.GetName() } already registered with data`)
	--	return
	--end
	
	----creating interface data table
	--local Interface = {
	--	Component = component,
	--	Children = options and options.Children or {},
	--	Parent = options and options.Parent,
	--}
	
	--if options then
		
	--	if options.Parent then
			
	--		local ParentData = self:GetInterfaceData(options.Parent)
			
	--		if not ParentData then
				
	--			print("Created new parent, parented under it", options.Parent.GetName())
	--			self:RegisterInterface(options.Parent, { Children = { component } })
	--		else
	--			print("Parented component to existing parent", options.Parent.GetName())
	--			table.insert(ParentData.Children, component)
	--		end
	--	end
	--end
	
	local Component = ComponentsManager.Add(instance, impl, ...)
	
	--removal
	Component.Janitor:Add(function()
		
		table.remove(self.Interfaces,
			table.find(self.Interfaces, Component)
		)
	end)
	
	table.insert(self.Interfaces, Component)
	
	self.InterfaceAdded:Fire(Component)
	
	----toggle events
	--component.Janitor:Add(component.EnabledChanged:Connect(function(value)
	--	self.InterfaceEnabledChanged:Fire(component, value)
	--	print(component.GetName(), "enabled changed,", value)
	--end))

	----removal on destruction
	--component.Janitor:Add(function()

	--	--deep cleanup
	--	if Interface.Parent then

	--		local ParentData = self:GetInterfaceData(Interface.Parent)

	--		table.remove(ParentData.Children,
	--			table.find(ParentData.Children, component)
	--		)
	--	end

	--	--global removal
	--	table.remove(self.Interfaces,
	--		table.find(self.Interfaces, Interface)
	--	)
	--end)
	
	return Component
end

function UIController._InitPresences(self: Controller)
	
end

function UIController._InitInterfaces(self: Controller)
	
	local Debug = StarterGui:FindFirstChild("Debug")
	
	self:RegisterInterface(Debug, DebugUIComponent, self)
	self:RegisterInterface(self.Instance.Screen.Lobby, LobbyUI, self)
	self:RegisterInterface(self.Instance.Screen.Gameplay, GameplayUIComponent, self)
	self:RegisterInterface(self.Instance.Screen.Notification, NotificationUIComponent, self)
	self:RegisterInterface(self.Instance.Screen.Global.Cursor, CursorUIComponent, self)
	self:RegisterInterface(self.Instance.Screen.Global.Interaction, InteractionUIComponent, self)
	self:RegisterInterface(self.Instance.Screen.Preloading, PreloadingUIComponent, self)
end

function UIController.OnConstructClient(self: Controller)

	--uhm yes we could disable some core GUIs
	self:_ForceCoreDisable()
	
	local Gui = UIAssets:FindFirstChild("Interface") or StarterGui:FindFirstChild("Interface")

	self.Instance = Gui
	self.Interfaces = {}
	self.Instance.Enabled = true
	self.Instance.Parent = Player.PlayerGui
	self.InterfaceAdded = Signal.new()
	self.InterfaceEnabledChanged = Signal.new()

	self.Instance.Screen.BackgroundTransparency = 1

	--aooh yes
	self:_InitInterfaces()

	local function ClearCopies(Gui: ScreenGui)

		if not Gui:IsA("ScreenGui") then
			return
		end

		if Gui.Name == self.Instance.Name
			and Gui ~= self.Instance then

			Gui:Destroy()
		end
	end

	Player.PlayerGui.ChildAdded:Connect(ClearCopies)

	for _, Gui: ScreenGui in ipairs(Player.PlayerGui:GetChildren()) do
		ClearCopies(Gui)
	end
	
	--TODO: mouse icon improvements
	UserInputService.MouseIconEnabled = false
	
end

--//Returner

local Controller = UIController.new()
return Controller