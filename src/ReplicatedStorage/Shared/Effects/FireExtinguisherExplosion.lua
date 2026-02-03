--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local CameraController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.CameraController) or nil

--//Variables

local Player = Players.LocalPlayer
local FireExtinguisherExplosion = Refx.CreateEffect("FireExtinguisherExplosion") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {
	Janitor: Janitor.Janitor,
	Instance: BasePart,
}

export type Impl = Refx.EffectImpl<MyImpl, Fields, BasePart>
export type Effect = Refx.Effect<MyImpl, Fields, BasePart>

--//Functions

function FireExtinguisherExplosion.CreateSphereAtPosition(self: Effect, position: Vector3, options: { InitialVelocity: Vector3?, TweenSize: boolean?, SizeFactor: number?, InitialSizeFactor: number?,
																	EnableGravity: boolean?, FadeoutDelay: number?, FadeoutTime: number?, TouchTimeout: number? }?) : BasePart
																				
	if options == nil then options = {} end	
	if options.EnableGravity == nil then options.EnableGravity = true end
	
	local Sphere = self.Janitor:Add(Instance.new("Part"))
	local DefaultSize = Vector3.one * 7 * math.random(8, 12) / 10
	Sphere.Parent = workspace.Temp
	Sphere.Color = Color3.new(1, 1, 1)
	Sphere.Position = position
	Sphere.Size = DefaultSize * (options.SizeFactor or 1)
	Sphere.CanTouch = true
	Sphere.CanCollide = false
	Sphere.Transparency = 0
	Sphere.Shape = Enum.PartType.Ball
	Sphere.Material = Enum.Material.SmoothPlastic
	Sphere.CollisionGroup = "Items"

	local Velocity = self.Janitor:Add(Instance.new("BodyVelocity"))
	Velocity.Parent = Sphere

	--make it fall until it touches ground and it anchores then (falls slowly)
	Velocity.Velocity = options.InitialVelocity or Vector3.new(0, -2, 0)
	Velocity.MaxForce = Vector3.one * 10000000000000000000000
	
	if options.EnableGravity then
		local GravityFactor = math.random(400, 600) / 100
		local t = os.clock()
		local UniqueJanitorID = `GravityEffect{GravityFactor}{t}`
		self.Janitor:Add(RunService.PreSimulation:Connect(function(d)
			if Sphere and not Sphere.Anchored then
				Velocity.Velocity = Vector3.new(Velocity.Velocity.X, Velocity.Velocity.Y - GravityFactor * d, Velocity.Velocity.Z)
			else
				self.Janitor:Remove(UniqueJanitorID)
			end
		end), nil, UniqueJanitorID)
	end

	if options.TweenSize and options.InitialSize then
		local DestinationSize = Sphere.Size
		Sphere.Size = DefaultSize * (options.InitialSizeFactor or 0.2)
		TweenUtility.PlayTween(Sphere, TweenInfo.new(1, Enum.EasingStyle.Quad), {Size = DestinationSize})
	end

	local IsTouched = false
	local Start = os.clock()
	
	local function OnTouch(hit)
		if hit ~= true and (IsTouched or not hit.CanCollide or hit.Transparency >= 0.8) then
			return
		end

		if hit ~= true and os.clock() - Start <= 0.02 then
			return -- brief hit immunity on spawn
		end

		IsTouched = true

		local WaitTime = 0.5 * Sphere.Size.X / Velocity.Velocity.Magnitude
		if WaitTime == math.huge then WaitTime = 0.01 end
		WaitTime = math.min(WaitTime, 1)
		task.wait(WaitTime)

		Sphere.Anchored = true

		task.wait(options.FadeoutDelay or 0)
		if Sphere:FindFirstChildWhichIsA("ParticleEmitter") then
			Sphere:FindFirstChildWhichIsA("ParticleEmitter").Enabled = false
		end
		TweenUtility.WaitForTween(TweenUtility.PlayTween(Sphere, TweenInfo.new(options.FadeoutTime or math.random(8, 14), Enum.EasingStyle.Quint), {Transparency = 1} :: BasePart, nil, 5))

		Sphere:Destroy()
	end
	
	self.Janitor:Add(Sphere.Touched:Connect(OnTouch))
	
	if options.TouchTimeout then
		self.Janitor:Add(task.delay(options.TouchTimeout, function() OnTouch(true) end))
	end
	
	return Sphere
end

function FireExtinguisherExplosion.BurstSpheresFromPosition(self: Effect, position: Vector3, amount: number)
	for i = 1, amount do
		local RandomVelocity = (Vector3.new(math.random()-0.5, math.random()/5, math.random()-0.5).Unit + Vector3.new(0, 0.1, 0)).Unit
		RandomVelocity *= 80
		self:CreateSphereAtPosition(position, { InitialVelocity = RandomVelocity, TweenSize = true, FadeoutDelay = 5 })
	end
end

--//Methods

function FireExtinguisherExplosion.OnConstruct(self: Effect, instance: BasePart)
	self.Janitor = Janitor.new()
	self.Instance = instance
	self.DestroyOnEnd = true
	self.MaxLifetime = 30
	self.DisableLeakWarning = false
end

function FireExtinguisherExplosion.OnStart(self: Effect)
	local LastUpdate = 0
	math.randomseed(os.time())
	
	self.Janitor:Add(task.spawn(function()
		local Character = Player.Character :: PlayerTypes.Character
		if Character then
			local Distance = (Character.HumanoidRootPart.Position - self.Instance.Position).Magnitude
			local Strength = (1 - math.clamp(Distance / 80, 0, 1)) ^ 2

			CameraController:QuickShake(1.5, Strength * 5, "Bump")
		end
	end))
	local CentralSphere = self:CreateSphereAtPosition(self.Instance.Position + Vector3.new(0, 1.5, 0), { InitialVelocity = Vector3.zero, SizeFactor = 4, TweenSize = true, InitialSizeFactor = 3,
		EnableGravity = false, FadeoutTime = 12, FadeoutDelay = 5, TouchTimeout = 0.05})

	local SmokeParticles = self.Instance.Alignment.ParticleEmitter:Clone()
	SmokeParticles.Parent = CentralSphere
	SmokeParticles.Enabled = true
	
	self:BurstSpheresFromPosition(self.Instance.Position, 25)

	self.Janitor:Add(task.spawn(function()
		while task.wait(0.035) do
			if not self.Instance then
				return -- prints  50000 errors :skull:
			end
			
			if not self.Instance:FindFirstChild("Particles") then
				return -- prints 50000 more errors :skull:
			end

			local AttachmentCFrame : CFrame = self.Instance.Particles.WorldCFrame 
			local InitialVelocity = AttachmentCFrame.YVector.Unit + Vector3.new(0, math.random(75, 100)/1000, 0)
			InitialVelocity += Vector3.new(math.random(), math.random(), math.random()) / 10 -- random noise
			InitialVelocity = InitialVelocity.Unit * 20
			self:CreateSphereAtPosition(AttachmentCFrame.Position, { InitialVelocity = InitialVelocity, TweenSize = true, SizeFactor = 0.25, InitialSizeFactor = 0.05 })
		end
	end))
	task.wait(self.MaxLifetime)
end

function FireExtinguisherExplosion.OnDestroy(self: Effect)
	self.Janitor:Destroy()
end

--//Return

return FireExtinguisherExplosion