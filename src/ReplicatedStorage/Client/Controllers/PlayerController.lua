--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports 

local Types = require(ReplicatedStorage.Shared.Types)
local Roles = require(ReplicatedStorage.Shared.Data.Roles)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local RoleTypes = require(ReplicatedStorage.Shared.Types.RoleTypes)
local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)
local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)
local ClientProducer = require(ReplicatedStorage.Client.ClientProducer)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local Utility = require(ReplicatedStorage.Shared.Utility)
local ThreadUtility = require(ReplicatedStorage.Shared.Utility.ThreadUtility)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ClientInventoryComponent = require(ReplicatedStorage.Client.Components.ClientInventoryComponent)
local ClientCharacterComponent = require(ReplicatedStorage.Client.Components.ClientCharacterComponent)

--//Variables

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerController = Classes.CreateSingleton("PlayerController") :: Impl

--//Types

export type Impl = {
	__index: Impl,
	
	CharacterAdded: Signal.Signal<ClientCharacterComponent.Component>,
	InventoryAdded: Signal.Signal<ClientInventoryComponent.Component>,
	CharacterRemoved: Signal.Signal,
	InventoryRemoved: Signal.Signal,
	RoleConfigChanged: Signal.Signal<RoleTypes.Role>,

	GetName: () -> "PlayerController",
	GetExtendsFrom: () -> nil,
	IsImpl: (self: Controller) -> boolean,

	GetRoleConfig: (self: Controller) -> RoleTypes.Role?,
	GetRoleString: (self: Controller) -> string,
	
	IsKiller: (self: Controller) -> boolean,
	IsStudent: (self: Controller) -> boolean,
	IsSpectator: (self: Controller) -> boolean,

	new: () -> Controller,
	OnConstruct: (self: Controller) -> (),
	OnConstructClient: (self: Controller) -> (),
	
	_InitCharacter: (self: Controller) -> (),
	_InitInventory: (self: Controller) -> (),
	_ConnectNetworkEvents: (self: Controller) -> (),
}

export type Fields = {
	Instance: Player,
	InventoryComponent: ClientInventoryComponent.Component?,
	CharacterComponent: ClientCharacterComponent.Component?,
}

export type Controller = typeof(setmetatable({} :: Fields, PlayerController :: Impl))

--//Methods

function PlayerController.GetRoleConfig(self: Controller)
	return RolesManager:GetPlayerRoleConfig(LocalPlayer)
end

function PlayerController.GetRoleString(self: Controller)
	return ClientProducer.GetReflexData(Selectors.SelectRole)
end

function PlayerController.IsKiller()
	return LocalPlayer.Team ~= nil and LocalPlayer.Team.Name == "Killer"
end

function PlayerController.IsSpectator()
	return LocalPlayer.Team ~= nil and LocalPlayer.Team.Name == "Spectator"
end

function PlayerController.IsStudent()
	return LocalPlayer.Team ~= nil and LocalPlayer.Team.Name == "Student"
end

function PlayerController._ConnectNetworkEvents(self: Controller)
	
	--used for responsible client impulse from server
	ClientRemotes.ApplyImpulse.SetCallback(function(args)
		
		if not args.part then
			return
		end

		if args.isAngular then
			
			args.part:ApplyAngularImpulse(args.impulse)
		else
			
			args.part:ApplyImpulse(args.impulse)
		end
	end)
	
	--used to track local player damage data
	ClientRemotes.DamageTaken.On(function(args)
		
		if args.player ~= LocalPlayer then
			return
		end
		
		local CameraController = Classes.GetSingleton("CameraController")
		local CharacterComponent = ComponentsManager.Get(LocalPlayer.Character, ClientCharacterComponent)
		
		if not CharacterComponent then
			return
		end
		
		local Angle = math.rad((args.damage / CharacterComponent.Humanoid.MaxHealth) * 100)

		if args.origin and args.origin.Magnitude > 0 then
			
			local YAxis = select(2, CFrame.lookAt(Vector3.zero, Camera.CFrame.Rotation:PointToObjectSpace(args.origin)):ToOrientation())

			CameraController.Cameras.Default:TiltCamera(
				CFrame.fromOrientation(0, YAxis, 0)
					* CFrame.Angles(Angle, 0, 0)
					* CFrame.fromOrientation(0, -YAxis, 0)
			)
		else
			
			CameraController.Cameras.Default:TiltCamera(CFrame.Angles(0, 0, Angle))
		end
	end)
end


function PlayerController._InitInventory(self: Controller)
	
	local function OnInventoryAdded(component: ClientInventoryComponent.Component)
		
		self.InventoryAdded:Fire(component)
		
		component.Janitor:Add(function()
			self.InventoryRemoved:Fire()
		end)
	end
	
	ComponentsManager.ComponentAdded:Connect(function(component)
		
		if component.GetName() ~= "ClientInventoryComponent" then
			return
		end
		
		OnInventoryAdded(component)
	end)
	
	local Component = ComponentsManager.Get(LocalPlayer.Backpack, "ClientInventoryComponent")
	
	if Component then
		OnInventoryAdded(Component)
	end
end

function PlayerController._InitCharacter(self: Controller)
	
	local function HandleCharacterRemoved(character)
		
		ComponentsManager.Remove(character, ClientCharacterComponent)
		
		self.CharacterRemoved:Fire(self.CharacterComponent)
		self.CharacterComponent = nil
	end

	local function HandleCharacterAdded(character)
		
		self.CharacterComponent = ComponentsManager.Add(character, ClientCharacterComponent)
		self.CharacterAdded:Fire(self.CharacterComponent)

		character:WaitForChild("Humanoid").Died:Once(function()
			HandleCharacterRemoved(character)
		end)
	end

	LocalPlayer.CharacterAdded:Connect(HandleCharacterAdded)
	LocalPlayer.CharacterRemoving:Connect(HandleCharacterRemoved)

	if LocalPlayer.Character then
		task.spawn(HandleCharacterAdded, LocalPlayer.Character)
	end
end

function PlayerController.OnConstructClient(self: Controller)
	
	self.CharacterAdded = Signal.new()
	self.CharacterRemoved = Signal.new()
	self.InventoryAdded = Signal.new()
	self.InventoryRemoved = Signal.new()
	self.RoleConfigChanged = Signal.new()
	
	self.Instance = LocalPlayer
	
	self:_InitCharacter()
	self:_InitInventory()
	self:_ConnectNetworkEvents()

	ClientProducer.Root:subscribe(Selectors.SelectRoleConfig(LocalPlayer.Name), function(...)
		
		self.RoleConfigChanged:Fire(select(1, ...))
		
		if RunService:IsStudio() then
			print("Role config changed on client!", ...)
		end
	end)
end

--//Returner

local Controller = PlayerController.new()
return Controller