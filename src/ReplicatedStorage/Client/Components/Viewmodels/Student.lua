--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Spring = require(ReplicatedStorage.Packages.Spring)
local Classes = require(ReplicatedStorage.Shared.Classes)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseViewmodel = require(ReplicatedStorage.Client.Components.Viewmodels.BaseViewmodel)
local ProceduralAnimations = require(ReplicatedStorage.Client.Utility.ViewmodelAnimations)

--//Constants

local PI = math.pi
local LEFT_OFFSET = CFrame.new(-1, -1.3, 0) * CFrame.Angles(0, -PI/2 or 0, 0)
local RIGHT_OFFSET = CFrame.new(1, -1.3, 0) * CFrame.Angles(0, PI/2 or 0, 0)
local RSHOULDER_INITIAL = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
local LSHOULDER_INITIAL = CFrame.new(-1, 0.5, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0)

--//Variables

local Camera = workspace.CurrentCamera
local SwaySpring = Spring.create(0.3, 5, 1, 0.5)
local LocalPlayer = Players.LocalPlayer

local StudentViewmodel = BaseComponent.CreateComponent("StudentViewmodel", {
	
	tag = "Character",
	isAbstract = false,
	predicate = function(instance: Instance)
		return instance == LocalPlayer.Character
			and Classes.GetSingleton("PlayerController"):IsStudent()
	end,
	
}, BaseViewmodel) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseViewmodel.Impl)),
}

export type Fields = {
	
	Enabled: boolean,
	
	PreviousOffset: Vector3,
	InitialOffsetLeft: CFrame,
	InitialOffsetRight: CFrame,
	
	LeftArmJoint: Motor6D,
	RightArmJoint: Motor6D,

} & BaseViewmodel.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "StudentViewmodel", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "StudentViewmodel", PlayerTypes.Character> 

--//Methods

function StudentViewmodel.OnEnabledChanged(self: Component, enabled: boolean)
	
	--ignore enabling
	if enabled then
		return
	end
	
	--resetting arms offset
	
	self.LeftArmJoint.C0 = self.InitialOffsetLeft
	self.RightArmJoint.C0 = self.InitialOffsetRight
end

function StudentViewmodel.OnUpdate(self: Component, deltaTime: number)
	-- Ограничиваем deltaTime для стабильности
	local DeltaTime = math.min(deltaTime, 1/60)

	-- Получаем необходимые компоненты
	local CameraCFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -0.7)
	local MouseDelta = UserInputService:GetMouseDelta()
	local Humanoid = self.Instance:FindFirstChildWhichIsA("Humanoid")
	local Torso = self.Instance:FindFirstChild("UpperTorso")
	local HumanoidRootPart = self.Instance:FindFirstChild("HumanoidRootPart")
	
	local LeftJoint = self.LeftArmJoint
	local RightJoint = self.RightArmJoint

	if not Torso
		or not Humanoid
		or not HumanoidRootPart then
		
		return
	end

	-- Вычисляем разницу между поворотом камеры и персонажа
	local cameraYaw = select(2, CameraCFrame:ToOrientation())
	local characterYaw = select(2, HumanoidRootPart.CFrame:ToOrientation())
	local yawDifference = cameraYaw - characterYaw

	-- Создаем компенсирующее вращение
	local rotationCompensation = CFrame.Angles(0, -yawDifference, 0)

	-- Вычисляем TorsoSpace с компенсацией
	local TorsoSpace = (CameraCFrame * rotationCompensation):ToObjectSpace(Torso.CFrame):Inverse()

	-- Определяем анимацию движения/покоя
	local OffsetCFrame
	
	if Humanoid.MoveDirection.Magnitude > 0 then
		OffsetCFrame = ProceduralAnimations.GetMovementOffset(5, 0.1)
	else
		OffsetCFrame = ProceduralAnimations.GetIdleOffset(3, 0.5)
	end

	-- Применяем силы к пружине
	SwaySpring:shove(
		Vector3.new(
			-MouseDelta.X / (Camera.ViewportSize.X / 2) * 2.5,
			MouseDelta.Y / (Camera.ViewportSize.Y / 1.5) * 2.5,
			0
		)
	)

	-- Обновляем пружину
	local SwayOffset = SwaySpring:update(DeltaTime)

	-- Плавное следование для дополнительного сглаживания
	local lerpAlpha = math.clamp(DeltaTime * 10, 0, 1)
	
	self.PreviousOffset = self.PreviousOffset:Lerp(OffsetCFrame, lerpAlpha)

	-- Коэффициенты для тонкой настройки эффекта
	local verticalFactor = 1.4
	local depthFactor = 0
	local rotationFactor = 1.4

	-- Применяем трансформации с компенсацией поворота
	LeftJoint.C0 = TorsoSpace 
		* LEFT_OFFSET 
		* CFrame.new(
			0, 
			SwayOffset.Y * verticalFactor, 
			SwayOffset.Y * depthFactor - 0.65
		) 
		* CFrame.Angles(
			SwayOffset.X * rotationFactor * 0.5,
			math.rad(90), 
			0
		) 
		* self.PreviousOffset

	RightJoint.C0 = TorsoSpace 
		* RIGHT_OFFSET 
		* CFrame.new(
			0, 
			SwayOffset.Y * verticalFactor, 
			SwayOffset.Y * depthFactor - 0.65
		) 
		* CFrame.Angles(
			SwayOffset.X * rotationFactor * 0.5,
			math.rad(-90), 
			0
		) 
		* self.PreviousOffset
end

function StudentViewmodel.OnConstructClient(self: Component)
	BaseViewmodel.OnConstructClient(self)

	self.PreviousOffset = CFrame.new()
	self.LeftArmJoint = self.Instance:FindFirstChild("LeftUpperArm"):FindFirstChild("LeftShoulder")
	self.RightArmJoint = self.Instance:FindFirstChild("RightUpperArm"):FindFirstChild("RightShoulder")
	self.InitialOffsetLeft = self.LeftArmJoint.C0
	self.InitialOffsetRight = self.RightArmJoint.C0

	self:_BindRenderSteps()
end

--//Returner

return StudentViewmodel