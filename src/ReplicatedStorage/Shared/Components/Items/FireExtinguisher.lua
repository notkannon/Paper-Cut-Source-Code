--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Imports

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseItem = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local ItemsData = require(ReplicatedStorage.Shared.Data.Items)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local FallDamageService = require(ReplicatedStorage.Shared.Services.FallDamageService)
local PhysicsStatusEffect = require(ReplicatedStorage.Shared.Combat.Statuses.Physics)
local FireExtinguisherEffect = require(ReplicatedStorage.Shared.Effects.FireExtinguisher)

--//Constants

local FLIGHT_LEVEL = 5.5

local DOOR_CHECK_RAYCAST_PARAMS = RaycastParams.new()
DOOR_CHECK_RAYCAST_PARAMS.CollisionGroup = "Players"
DOOR_CHECK_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
DOOR_CHECK_RAYCAST_PARAMS.RespectCanCollide = true
DOOR_CHECK_RAYCAST_PARAMS.FilterDescendantsInstances = { workspace.Characters, workspace.Temp }

--//Variables

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local FireExtinguisherItem = BaseComponent.CreateComponent("FireExtinguisherItem", {
	isAbstract = false,
	defaults = {
		Charge = 1,
	}
	
}, BaseItem) :: BaseItem.Impl

--//Types

export type Fields = {
	Instance: typeof(ItemsData.FireExtinguisher.Instance),
	SoundLoop: Sound,
	
	Attributes: {
		Charge: number,
	} & BaseItem.ItemAttributes,
	
	Velocity: BodyVelocity,
	Orientation: AlignOrientation,
	PhysicsStatus: WCS.StatusEffect,
	
} & BaseItem.Fields

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseItem.MyImpl)),
	
	CheckObstacleOnWay: (self: Component) -> boolean,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, Tool, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, string, Tool, {}>

--//Functions

local function CheckDoorOnWay() : ()
	assert(RunService:IsClient())
	
	local HumanoidRootPart = Player.Character.HumanoidRootPart :: BasePart
	local Result = workspace:Raycast(
		HumanoidRootPart.Position,
		HumanoidRootPart.CFrame.LookVector.Unit * 4.5,
		DOOR_CHECK_RAYCAST_PARAMS
	)

	local DoorModel = Result and Result.Instance:FindFirstAncestorWhichIsA("Model") :: Model?
	if not DoorModel or not DoorModel:HasTag("Door") then
		return
	end

	local DoorComponent = ComponentsManager.GetComponentsFromInstance(DoorModel)[1]
	if not DoorComponent then
		return
	end

	DoorComponent:PromptSlamClient()
end

local function GetFlightLevel(): number
	local Result = workspace:Raycast(
		Player.Character.HumanoidRootPart.Position,
		Vector3.new(0, -1000, 0),
		DOOR_CHECK_RAYCAST_PARAMS
	)
	
	return Result and Result.Position.Y + FLIGHT_LEVEL or Player.Character.HumanoidRootPart.Position.Y
end

--//Methods

function FireExtinguisherItem.ShouldStart(self: Component)
	if RunService:IsClient() and self:CheckObstacleOnWay()then
		return
	end
	
	return self.Attributes.Charge > 0
end

function FireExtinguisherItem.CheckObstacleOnWay(self: Component)
	local HumanoidRootPart = self.CharacterComponent.HumanoidRootPart :: BasePart
	
	local Result = workspace:Raycast(
		HumanoidRootPart.Position,
		self.Velocity.Velocity.Unit * 3,
		DOOR_CHECK_RAYCAST_PARAMS
	)

	return not not Result
end

function FireExtinguisherItem.OnConstructServer(self: Component)
	BaseItem.OnConstructServer(self)
	
	local Status
	
	self.SoundLoop = SoundUtility.CreateSound(
		SoundUtility.Sounds.Instances.Items.Misc.FireExtinguisherLoop,
		true
	)
	
	self.SoundLoop.Parent = self.Handle
	
	self.Janitor:Add(self.InventoryChanged:Connect(function(inventory)
		if inventory then
			self.PhysicsStatus = self.Janitor:Add(PhysicsStatusEffect.new(self.CharacterComponent.WCSCharacter), "Destroy", "PhysicsStatus")
			self.PhysicsStatus.DestroyOnEnd = false
			Status = self.PhysicsStatus
			
		else 
			
			if not Status or Status:IsDestroyed() then
				return
			end
			
			Status:Destroy()
			self.Janitor:Remove("PhysicsStatus")
		end
	end))
end

function FireExtinguisherItem.OnConstructClient(self: Component)
	BaseItem.OnConstructClient(self)
	
	local Velocity = self.Janitor:Add(Instance.new("BodyVelocity"))
	Velocity.Parent = self.Handle
	Velocity.P = 10
	
	local Orientation = self.Janitor:Add(Instance.new("AlignOrientation"))
	Orientation.Enabled = false
	Orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	Orientation.Parent = self.Handle
	Orientation.AlignType = Enum.AlignType.AllAxes
	Orientation.Attachment0 = self.Handle:FindFirstChild("Alignment")
	
	self.Velocity = Velocity
	self.Orientation = Orientation
end

function FireExtinguisherItem.OnEquipClient(self: Component)
	self.Velocity.MaxForce = Vector3.zero
	self.Velocity.P = 0
end

function FireExtinguisherItem.OnStartServer(self: Component)
	self.SoundLoop:Play()
	self.PhysicsStatus:Start()
	
	local Effect = FireExtinguisherEffect.new(self.Instance)
	Effect:Start(Players:GetPlayers())
	
	self.ActiveJanitor:Add(Effect, "Destroy")
	self.ActiveJanitor:Add(self.SoundLoop, "Stop")
	self.ActiveJanitor:Add(self.PhysicsStatus, "End")
	
	self.ActiveJanitor:Add(function()
		self:ApplyCooldown(3)
	end)
	
	self.ActiveJanitor:Add(RunService.Stepped:Connect(function()
		if self.Attributes.Charge == 0 then
			self:Destroy()
			
			return
		end
		
		self.Attributes.Charge = math.max(0, self.Attributes.Charge -1 / 500)
	end))
end

function FireExtinguisherItem.OnAssumeStartClient(self: Component)
	
	local Humanoid = self.CharacterComponent.Humanoid :: Humanoid
	local Velocity = self.Velocity :: BodyVelocity 
	local Orientation = self.Orientation :: AlignOrientation
	local HumanoidRootPart = self.CharacterComponent.HumanoidRootPart :: BasePart
	local FlightLevel = GetFlightLevel()
	
	local _, Y = Camera.CFrame:ToOrientation()
	Orientation.Enabled = true
	Orientation.CFrame = CFrame.Angles(0, Y, 0)
	
	Velocity.P = 10
	Velocity.Velocity = Vector3.zero
	Velocity.MaxForce = Vector3.one * 5000
	
	self.ActiveJanitor:Add(function()
		self:ApplyCooldown(3)
	end)
	
	self.ActiveJanitor:Add(AnimationUtility.QuickPlay(Humanoid, ReplicatedStorage.Assets.Animations.Items.FireExtinguisher.FlightLoop, {
		Looped = true,
		Priority = Enum.AnimationPriority.Action4,
	}), "Stop")
	
	self.ActiveJanitor:Add(RunService.Stepped:Connect(function(frameDelta)
		
		if self.Attributes.Charge == 0 or self:CheckObstacleOnWay() then
			
			self.ActiveJanitor:Remove("StepsConnection")
			self.Instance:Deactivate()
			
			return
		end
		
		CheckDoorOnWay()
		
		local _, Y = Camera.CFrame:ToOrientation()
		
		Orientation.CFrame = Orientation.CFrame:Lerp(CFrame.Angles(0, Y, 0), 1 / 35)
		Velocity.Velocity = Velocity.Velocity:Lerp(Orientation.CFrame.LookVector * 40, 1 / 7)
		
		--resetting falling height
		FallDamageService._FallStartHeight = HumanoidRootPart.Position.Y
		
		Player.Character:PivotTo(
			CFrame.new(
				HumanoidRootPart.Position.X,
				FlightLevel,
				HumanoidRootPart.Position.Z
			) * HumanoidRootPart.CFrame.Rotation
		)
	end), nil, "StepConnection")
end

function FireExtinguisherItem.OnEndClient(self: Component)
	
	local Humanoid = self.CharacterComponent.Humanoid :: Humanoid
	local Velocity = self.Velocity :: BodyVelocity 
	local Orientation = self.Orientation :: AlignOrientation
	local HumanoidRootPart = self.CharacterComponent.HumanoidRootPart :: BasePart
	
	HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
	
	Velocity.Velocity = Vector3.zero
	Velocity.MaxForce = Vector3.zero
	Orientation.Enabled = false
end

--//Returner

return FireExtinguisherItem