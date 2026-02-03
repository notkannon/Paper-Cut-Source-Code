--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Spring = require(ReplicatedStorage.Packages.Spring)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ProceduralAnimations = require(ReplicatedStorage.Client.Controllers.ViewmodelController.Animations)

--//Variables

local PI = math.pi
local LEFT_OFFSET = CFrame.new(-1, -1.3, 0) * CFrame.Angles(0, -PI/2 or 0, 0)
local RIGHT_OFFSET = CFrame.new(1, -1.3, 0) * CFrame.Angles(0, PI/2 or 0, 0)
local RSHOULDER_INITIAL = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
local LSHOULDER_INITIAL = CFrame.new(-1, 0.5, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0)

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local SwaySpring = Spring.create()

local StudentViewmodel = BaseComponent.CreateComponent("StudentViewmodel", {
	isAbstract = false,
	predicate = function(instance: Instance)
		return typeof(instance) == "Instance" and instance:IsA("Player")
	end,
}) :: Impl

StudentViewmodel._Role = "Student"
StudentViewmodel._DefaultInstance = Player -- path to instance

--//Types

export type MyImpl = {
	__index: MyImpl,
	
	_Role: string,
	_DefaultInstance: Player,
	
	Update: (self: Component, deltaTime: number) -> (),
	SetEnabled: (self: Component, value: boolean) -> (),
	
	_BindRenderSteps: (self: Component) -> (),
	_UnbindRenderSteps: (self: Component) -> (),
}

export type Fields = {
	Instance: Player,
	Character: Model,
	
	Enabled: boolean,
	PreviousOffset: Vector3,
	
	LeftArmJoint: Motor6D,
	RightArmJoint: Motor6D,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "StudentViewmodel", Player, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "StudentViewmodel", Player, {}> 

--//Methods

function StudentViewmodel.SetEnabled(self: Component, value: boolean)
	if self.Enabled == value then
		return
	end
	
	self.Enabled = value
	
	if not value then
		
		self:_UnbindRenderSteps()
		
		self.RightArmJoint.C0 = RSHOULDER_INITIAL
		self.LeftArmJoint.C0 = LSHOULDER_INITIAL
		
	else
		self:_BindRenderSteps()
	end
end

function StudentViewmodel._Update(self: Component, deltaTime: number)
	assert(self.Enabled, self.GetName() .. " viewmodel is not enabled")
	
	if not self.Character then
		self:SetEnabled(false)
		return
	end
	
	local OffsetCFrame
	local CameraCFrame = workspace.CurrentCamera.CFrame
	local Resolution = Camera.ViewportSize
	local MouseDelta = UserInputService:GetMouseDelta()
	local Humanoid = self.Character.Humanoid :: Humanoid
	local Torso = self.Character.Torso
	
	local LeftJoint = self.LeftArmJoint
	local RightJoint = self.RightArmJoint
	local TorsoSpace = CameraCFrame:ToObjectSpace(Torso.CFrame):Inverse()
	
	if Humanoid.MoveDirection.Magnitude > 0 then
		OffsetCFrame = ProceduralAnimations.GetMovementOffset(math.sqrt(Humanoid.WalkSpeed) * 4.5, .3)
	else
		OffsetCFrame = ProceduralAnimations.GetIdleOffset(3, .5)
	end
	
	SwaySpring:shove( Vector3.new(-MouseDelta.X / 500, MouseDelta.Y / 200, 0) )
	local SwayOffset: Vector3 = SwaySpring:update(deltaTime)
	
	RightJoint.C0 = RightJoint.C0:Lerp(TorsoSpace * RIGHT_OFFSET * CFrame.new(SwayOffset.X, SwayOffset.Y, SwayOffset.Y), 1) * self.PreviousOffset
	LeftJoint.C0 = LeftJoint.C0:Lerp(TorsoSpace * LEFT_OFFSET * CFrame.new(SwayOffset.X, SwayOffset.Y, SwayOffset.Y), 1) * self.PreviousOffset

	self.PreviousOffset = self.PreviousOffset:Lerp(OffsetCFrame, 1/5)
end

function StudentViewmodel.OnConstructClient(self: Component)
	self.Enabled = true
	self.PreviousOffset = CFrame.new()
	
	self.Character = self.Instance.Character
	self.LeftArmJoint = self.Instance.Character.Torso:FindFirstChild("Left Shoulder")
	self.RightArmJoint = self.Instance.Character.Torso:FindFirstChild("Right Shoulder")
	
	self:_BindRenderSteps()
end

function StudentViewmodel._UnbindRenderSteps(self: Component)
	RunService:UnbindFromRenderStep("ClientViewmodelRenderSteps")
end

function StudentViewmodel._BindRenderSteps(self: Component)
	if not self.Enabled then
		return
	end
	
	RunService:BindToRenderStep("ClientViewmodelRenderSteps", Enum.RenderPriority.Camera.Value + 1, function(...: number)
		if not self.Enabled then
			self:_UnbindRenderSteps()
			return
		end

		self:Update(...)
	end)
end

function StudentViewmodel.OnDestroy(self: Component)
	self:_UnbindRenderSteps()
end

--//Returner

return StudentViewmodel
--return nil