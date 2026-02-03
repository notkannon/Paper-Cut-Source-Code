--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

--//Variables

local HarpoonEffect = Refx.CreateEffect("HarpoonEffect") :: Impl

--//Types

type Morph = typeof(ReplicatedStorage.Assets.Morphs.MissCircle)

export type MyImpl = {
	__index: MyImpl,
	
	Pierce: (self: Effect, character: PlayerTypes.Character) -> (),
}

export type Fields = {
	Player: Player,
	Janitor: Janitor.Janitor,
	Instance: Morph,
	WinchSound: Sound,
	Projectile: BasePart,
	PiercedPlayer: Player?,
	PiercedCharacter: PlayerTypes.Character?,
}

export type Impl = Refx.EffectImpl<MyImpl, Fields, Morph>
export type Effect = Refx.Effect<MyImpl, Fields, Morph>

--//Methods

function HarpoonEffect.OnConstruct(self: Effect, character: Morph)
	self.Janitor = Janitor.new()
	self.DestroyOnEnd = false
	self.DisableLeakWarning = true
	self.DestroyOnLifecycleEnd = false
end

function HarpoonEffect.Pierce(self: Effect, character: PlayerTypes.Character)
	self.PiercedPlayer = Players:GetPlayerFromCharacter(character)
	self.PiercedCharacter = character
	
	self.Janitor:Remove("ProjectilePhysics")
	self.Janitor:Remove("ProjectileSound")
	self.Janitor:Remove("Velocity")
	
	local Projectile = self.Janitor:Get("Projectile") :: BasePart
	local AttachTo = character:FindFirstChild("UpperTorso") :: BasePart
	local Weld = Instance.new("WeldConstraint")
	
	Projectile.CFrame = AttachTo.CFrame * CFrame.Angles(math.rad(90), 0, 0)
	Weld.Parent = Projectile
	Weld.Part0 = AttachTo
	Weld.Part1 = Projectile
end

function HarpoonEffect.OnStart(self: Effect, character: Morph, origin: Vector3, direction: Vector3)
	
	self.Player = Players:GetPlayerFromCharacter(character)
	self.Instance = character
	
	character.CompassArmDown.Spike.Transparency = 1
	
	local Beam = character.CompassArmDown.Line:Clone() :: Beam
	local Projectile = character.CompassArmDown.Spike:Clone()
	
	Projectile.Parent = workspace.Temp
	Projectile.Position = origin
	Projectile.Transparency = 0
	
	self.Janitor:Add(SoundUtility.CreateTemporarySound(SoundUtility.Sounds.Players.Skills.Harpoon.Loop), nil, "ProjectileSound").Parent = Projectile
	SoundUtility.CreateTemporarySound(SoundUtility.Sounds.Players.Skills.Harpoon.Release).Parent = character.HumanoidRootPart
	
	local WinchSfx = SoundUtility.CreateTemporarySound(SoundUtility.Sounds.Players.Skills.Harpoon.Rope)
	WinchSfx.Parent = character.HumanoidRootPart
	self.WinchSound = WinchSfx

	local SoundTween = TweenUtility.PlayTween(WinchSfx, TweenInfo.new(3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Volume = 0,
		PlaybackSpeed = 0,
	})
	
	self.Janitor:Add(SoundTween, "Cancel")
	
	print(character.CompassArmDown:FindFirstChild("Socket") or character.CompassArmDown:FindFirstChild("Base").Socket)
	
	Beam.Parent = Projectile
	Beam.Enabled = true
	Beam.CurveSize0 = 7
	Beam.Attachment1 = Projectile.Point
	Beam.Attachment0 = character.CompassArmDown:FindFirstChild("Socket") or character.CompassArmDown:FindFirstChild("Base").Socket
	
	self.Janitor:Add(Beam, nil, "Beam")
	self.Janitor:Add(TweenUtility.PlayTween(Beam, TweenInfo.new(2.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		CurveSize0 = 0
	}), "Cancel", "BeamTween")
	
	--Forces initialization
	local Alignment = Projectile:FindFirstChild("Alignment")
	if not Alignment then
		Alignment = Instance.new("Attachment")
		Alignment.Parent = Projectile
		Alignment.Name = "Alignment"
	end

	local Velocity = Projectile:FindFirstChildWhichIsA("LinearVelocity") :: LinearVelocity?
	local SkillData = RolesManager:GetPlayerRoleConfig(self.Player).SkillsData
	
	if not Velocity and SkillData then
		Velocity = Instance.new("LinearVelocity")
		Velocity.Parent = Projectile
		Velocity.Enabled = true
		Velocity.MaxForce = 2000
		Velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		Velocity.Attachment0 = Alignment
		Velocity.VectorVelocity = direction * SkillData.Harpoon.Velocity
		Velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude
		Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	end
	
	self.Janitor:Add(Velocity, nil, "Velocity")
	self.Janitor:Add(Projectile, nil, "Projectile")
	
	--physics initializaton
	self.Janitor:Add(RunService.Stepped:Connect(function()
		if not Projectile then
			return
		end
		
		Projectile.CFrame = CFrame.lookAlong(Projectile.CFrame.Position, Velocity.VectorVelocity) * CFrame.Angles(0, math.rad(-90), math.rad(90))

		Velocity.VectorVelocity = Vector3.new(
			Velocity.VectorVelocity.X,
			Velocity.VectorVelocity.Y - 0.05,
			Velocity.VectorVelocity.Z
		)
	end), nil, "ProjectilePhysics")
end

function HarpoonEffect.OnDestroy(self: Effect)
	self.Janitor:Destroy()
	
	if self.Instance then
		TweenUtility.PlayTween(self.WinchSound, TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
			Volume = 0,
			PlaybackSpeed = 3,
			
		}, function()
			if self.WinchSound then
				self.WinchSound:Destroy()
			end
		end)
		
		self.Instance.CompassArmDown.Spike.Transparency = 0
	end
end

--//Return

return HarpoonEffect