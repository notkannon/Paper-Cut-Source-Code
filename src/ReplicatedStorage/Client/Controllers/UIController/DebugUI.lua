--//Services

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local CameraController = require(ReplicatedStorage.Client.Controllers.CameraController)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)

--//Variables

local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local DebugUI = BaseComponent.CreateComponent("DebugUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

type ScreenGuiInstance = typeof(StarterGui.Debug)

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	Toggle: (self: Component, value: boolean) -> (),
	
	OnConstructClient: (self: Component, any...) -> (),
	
	_ConnectInputEvents: (self: Component) -> (),
	_ConnectCameraEvents: (self: Component) -> (),
	_ConnectCharacterEvents: (self: Component) -> (),
}

export type Fields = {
	
	Enabled: boolean,
	Instance: ScreenGuiInstance,
	UIController: any,
	
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "DebugUI", ScreenGuiInstance, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "DebugUI", ScreenGuiInstance, {}>

--//Methods

function DebugUI.OnEnabledChanged(self: Component, value: boolean)
	self.Instance.Enabled = value or false
end

function DebugUI._ConnectCharacterEvents(self: Component)
	local Humanoid: Humanoid
	local CharacterComponent: any
	
	local function UpdateWalkSpeed()
		if not Humanoid then
			return
		end
		
		self.Instance.PlayerStats.Content.WalkSpeed.Text =
			`WalkSpeed: { math.round(Humanoid.WalkSpeed) }`
	end
	
	local function UpdateLinearSpeed()
		
		local HumanoidRootPart = Humanoid and Humanoid.RootPart
		
		if not HumanoidRootPart then
			return
		end
		
		self.Instance.PlayerStats.Content.LinearSpeed.Text =
			`LinearSpeed: { math.round(HumanoidRootPart.AssemblyLinearVelocity.Magnitude) }`
	end
	
	local function CharacterAdded(component: BaseComponent.Component)
		
		Humanoid = component.Humanoid
		CharacterComponent = component
		
		self.Janitor:Add(component.Janitor:Add(RunService.Stepped:Connect(UpdateLinearSpeed)))
		self.Janitor:Add(component.Janitor:Add(Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(UpdateWalkSpeed)))
	end
	
	local function CharacterRemoved()
		CharacterComponent = nil
		Humanoid = nil
	end
	
	UpdateWalkSpeed()
	UpdateLinearSpeed()
	
	if PlayerController.CharacterComponent then
		CharacterAdded(PlayerController.CharacterComponent)
	end
	
	PlayerController.CharacterAdded:Connect(CharacterAdded)
	PlayerController.CharacterRemoved:Connect(CharacterRemoved)
end

function DebugUI._ConnectCameraEvents(self: Component)
	self.Janitor:Add(RunService.RenderStepped:Connect(function()
		self.Instance.PlayerStats.Content.Fov.Text = `FoV: { math.round(Camera.FieldOfView) }`
		self.Instance.PlayerStats.Content.DestinatedFov.Text = `Destinated FoV: { CameraController.DestinedFov }`
	end))
end

function DebugUI._ConnectInputEvents(self: Component)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		
		if gameProcessed then
			return
		end
		
		if input.KeyCode == Enum.KeyCode.Backquote then
			
			self:SetEnabled(not self:IsEnabled())
		end
	end)
end

function DebugUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	local PlayerGui = Player:WaitForChild("PlayerGui") :: PlayerGui
	self.Instance.Parent = PlayerGui
	self.Instance.Info.version.Text = string.format(self.Instance.Info.version.Text, game.PlaceVersion)
	
	local function ClearCopies()
		
		for _, Gui: ScreenGui? in ipairs(PlayerGui:GetChildren()) do
			
			if Gui.Name == "Debug" and Gui ~= self.Instance then
				
				Gui:Destroy()
			end
		end
	end
	
	PlayerGui.ChildAdded:Connect(ClearCopies)
	
	self:SetEnabled(false)
	
	self:_ConnectInputEvents()
	self:_ConnectCharacterEvents()
	self:_ConnectCameraEvents()
end

--//Returner

return DebugUI