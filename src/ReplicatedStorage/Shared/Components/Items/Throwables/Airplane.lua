--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Imports

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseItem = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local BaseThrowable = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem.BaseThrowable)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local ThrowableAirplaneItem = BaseComponent.CreateComponent("ThrowablePaperAirplaneItem", {
	isAbstract = false,
}, BaseThrowable) :: BaseThrowable.Impl

--//Methods

function ThrowableAirplaneItem.OnFlightStart(self, instance: BasePart, janitor: any, userData: { any })
	BaseThrowable:OnFlightStart(instance, janitor, userData)
	local Alignment = instance:FindFirstChild("Alignment")
	
	if not Alignment then
		Alignment = Instance.new("Attachment")
		Alignment.Parent = instance
		Alignment.Name = "Alignment"
	end

	local Velocity = instance:FindFirstChildWhichIsA("LinearVelocity") :: LinearVelocity?
	
	if not Velocity then
		Velocity = Instance.new("LinearVelocity")
		Velocity.Parent = instance
		Velocity.MaxForce = 2000
		Velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		Velocity.Attachment0 = Alignment
		Velocity.VectorVelocity = userData.Direction * math.max(.3, userData.Strength) * 110 + Vector3.new(0, 0.3, 0)
		Velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude
		Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	end

	local Gravity = math.clamp(1 - userData.Strength, 0.1, 0.3) + 0.003

	janitor:Add(RunService.Stepped:Connect(function(_, deltaTime)
		
		instance.AssemblyAngularVelocity = Vector3.zero
		instance.CFrame = CFrame.lookAlong(instance.CFrame.Position, Velocity.VectorVelocity)

		Velocity.VectorVelocity = Vector3.new(
			Velocity.VectorVelocity.X,
			Velocity.VectorVelocity.Y - Gravity * deltaTime,
			Velocity.VectorVelocity.Z
		)
	end))
end

--//Returner

return ThrowableAirplaneItem