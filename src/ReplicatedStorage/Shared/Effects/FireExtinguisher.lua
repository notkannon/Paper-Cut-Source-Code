--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local FireExtinguisher = Refx.CreateEffect("FireExtinguisher") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {
	Janitor: Janitor.Janitor,
	Instance: Tool,
}

export type Impl = Refx.EffectImpl<MyImpl, Fields, Tool>
export type Effect = Refx.Effect<MyImpl, Fields, Tool>

--//Functions

local function CreateSphereAtPosition(position: number)
	local Sphere = Instance.new("Part")
	Sphere.Parent = workspace.Temp
	Sphere.Color = Color3.new(1, 1, 1)
	Sphere.Position = position
	Sphere.Size = Vector3.one * 6 * math.random(4, 10) / 10
	Sphere.CanTouch = true
	Sphere.CanCollide = false
	Sphere.Transparency = .5
	Sphere.Shape = Enum.PartType.Ball
	
	local Velocity = Instance.new("BodyVelocity")
	Velocity.Parent = Sphere
	
	--make it fall until it touches ground and it anchores then (falls slowly)
	Velocity.Velocity = Vector3.new(0, -2, 0)
	Velocity.MaxForce = Vector3.one * 10000000000000000000000
	
	local IsTouched = false
	Sphere.Touched:Connect(function(hit)
		if IsTouched or not hit.CanCollide or hit.Transparency == 1 then
			return
		end
		
		IsTouched = true
		
		task.wait(1.5)
		
		Sphere.Anchored = true
		
		TweenUtility.WaitForTween(TweenUtility.PlayTween(Sphere, TweenInfo.new(5), {Transparency = 1} :: BasePart, nil, 5))
		
		Sphere:Destroy()
	end)
end

--//Methods

function FireExtinguisher.OnConstruct(self: Effect, instance: Tool)
	self.Janitor = Janitor.new()
	self.Instance = instance
	self.DestroyOnEnd = false
	self.DisableLeakWarning = true
end

function FireExtinguisher.OnStart(self: Effect)
	local LastUpdate = 0
	
	self.Janitor:Add(RunService.Stepped:Connect(function()
		if os.clock() - LastUpdate < 0.05 then
			return
		end
		
		LastUpdate = os.clock()
		
		CreateSphereAtPosition(self.Instance.Handle.Particles.WorldPosition)
	end))
end

function FireExtinguisher.OnDestroy(self: Effect)
	self.Janitor:Destroy()
end

--//Return

return FireExtinguisher