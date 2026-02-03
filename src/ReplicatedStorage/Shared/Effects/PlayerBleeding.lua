--//Services

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local RaycastHitbox = require(ReplicatedStorage.Packages.RaycastHitbox)

local Utility = require(ReplicatedStorage.Shared.Utility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local EffectsUtility = require(ReplicatedStorage.Shared.Utility.EffectsUtility)

--//Constants

local PI = math.pi
local DEBUG = false

--//Variables

local TempContainer = workspace.Temp
local PlayerBleeding = Refx.CreateEffect("PlayerBleeding") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {}

export type Impl = Refx.EffectImpl<MyImpl, Fields, PlayerTypes.Character, number>
export type Effect = Refx.Effect<MyImpl, Fields, PlayerTypes.Character, number>

--//Functions

function CreateParams(...)	
	local Params = RaycastParams.new()
	Params.CollisionGroup = "Players"
	Params.FilterDescendantsInstances = {workspace.Characters, ...} 
	Params.FilterType = Enum.RaycastFilterType.Exclude

	return Params
end

function CreateHitBox(Object: Object, Params)
	local Hitbox = RaycastHitbox.new(Object)

	Hitbox.DetectionMode = RaycastHitbox.DetectionMode.PartMode
	Hitbox.RaycastParams = Params
	Hitbox.Visualizer = DEBUG

	Hitbox:HitStart() 

	return Hitbox
end

local function ScaleNumberSequence(oldSequence: NumberSequenceKeypoint, factor: number)
	local NewKeypoints = {}

	for i, OldKeypoint in ipairs(oldSequence.Keypoints) do
		table.insert(NewKeypoints, NumberSequenceKeypoint.new(OldKeypoint.Time, OldKeypoint.Value * factor))
	end

	local NewSequence = NumberSequence.new(NewKeypoints)
	
	return NewSequence
end

local function CreateBlood(character: Model)
	local MainBase = character.HumanoidRootPart :: BasePart
	local InitialPos = MainBase.Position

	local Direction = Vector3.new(0, 7, 0)
	local reverseDirection = Vector3.new(math.random(-15 ,15), math.random(-15,15), math.random(-15,15))

	if InitialPos then
		reverseDirection = Direction + reverseDirection
	end

	local NewTrail = ReplicatedStorage.Assets.Particles.Blood.Trail:Clone()
	NewTrail.Parent = TempContainer
	NewTrail.Position = MainBase.Position
	NewTrail.CollisionGroup = "Players"
	NewTrail.AssemblyLinearVelocity = Vector3.zero
	NewTrail:ApplyImpulse(reverseDirection * .01)

	--Creat Info HitBox
	local Params = CreateParams()

	--Creating Hitbox
	local Hitbox = CreateHitBox(NewTrail, Params)

	Hitbox:HitStart()

	--It's getting hit by Object
	Hitbox.OnHit:Connect(function(hit: BasePart, _, raycastResult: RaycastResult?)
		NewTrail.Anchored = true

		local NewBlood = Instance.new("Attachment")
		NewBlood.Parent = workspace.Terrain
		NewBlood.WorldCFrame = CFrame.lookAt(
			raycastResult.Position + raycastResult.Normal * .1,
			raycastResult.Position + raycastResult.Normal
		) * CFrame.Angles(PI/2, 0, 0)

		for _, Particle : ParticleEmitter in ipairs(ReplicatedStorage.Assets.Particles.Blood.Puddle:GetChildren()) do
			local ParticleClone = Particle:Clone()
			ParticleClone.Parent = NewBlood
			ParticleClone.Size = ScaleNumberSequence(ParticleClone.Size, 0.5)
			
			if ParticleClone.Name == "1" then
				ParticleClone.Lifetime = NumberRange.new(ParticleClone.Lifetime.Min * 10, ParticleClone.Lifetime.Max * 10)
			end
			
		end

		EffectsUtility.EmitDescendants(NewBlood, true)

		Debris:AddItem(NewTrail, 5)
		Debris:AddItem(NewBlood, 10)

		Hitbox:HitStop()
		Hitbox:Destroy()
	end)
end

--//Methods

function PlayerBleeding.OnStart(self: Effect, character: Instance)
	local Humanoid = character:FindFirstChildWhichIsA("Humanoid")

	if not Humanoid then
		return
	end

	local Sound = SoundUtility.CreateTemporarySound(
		SoundUtility.GetRandomSoundFromDirectory(
			SoundUtility.Sounds.Players.Gore.BloodSplat
		)
	)

	Sound.Parent = character.HumanoidRootPart
	Sound.Volume = .25

	for i = 1, math.random(2, 3) do
		CreateBlood(character)
	end
end

--//Return

return PlayerBleeding