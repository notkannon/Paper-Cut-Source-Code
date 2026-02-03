--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
--local RaycastHitbox = require(ReplicatedStorage.Packages.RaycastHitbox)
local ShapecastHitbox = require(ReplicatedStorage.Packages.ShapecastHitbox)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local BaseHoldableSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseHoldableSkill)

local Utility = require(ReplicatedStorage.Shared.Utility)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil

local HarpoonSkillEffect = require(ReplicatedStorage.Shared.Effects.Specific.Role.MissCircle.Harpoon)
local MetallicImpactEffect = require(ReplicatedStorage.Shared.Effects.MetallicImpact)

local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)
local HarpoonPiercedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Student.HarpoonPierced)

--//Constants

local DEBUG = false
local CLIENT_OFFSET_THRESHOLD_DISTANCE = 10

--//Variables

local Sfx = SoundUtility.Sounds.Players.Skills.Harpoon
local Camera = workspace.CurrentCamera
local Harpoon = WCS.RegisterHoldableSkill("Harpoon", BaseHoldableSkill)

--//Types

export type Skill = BaseHoldableSkill.BaseHoldableSkill & {
	
	_HitTimestamp: number,
	_ShotTimestamp: number,
	_PiercedCharacter: PlayerTypes.Character?,
	
	Instances: {
		Projectile: BasePart,
		Velocity: LinearVelocity
	}
}

--//Functions

local function GetHitPoint(offset: Vector3, direction: Vector3, ignoreList: { Instance }?)
	
	local Params = RaycastParams.new()
	
	Utility.ApplyParams(Params, {
		
		FilterType = Enum.RaycastFilterType.Exclude,
		IgnoreWater = true,
		CollisionGroup = "Projectiles",
		RespectCanCollide = true,
		FilterDescendantsInstances = TableKit.MergeArrays({workspace.Temp, workspace:FindFirstChild("DroppedItems"), workspace.Characters}, ignoreList or {}),
		
	} :: RaycastParams)
	
	local Raycast = workspace:Raycast(offset, direction * 100000, Params)
	
	if not Raycast then
		return offset + direction * 1000
	else
		return Raycast.Position, Raycast
	end
end

local function DebugPoint(origin: Vector3, hit: Vector3)
	
	if not DEBUG then
		return
	end
	
	local Wire = Instance.new("Part")
	Wire.Parent = workspace.Temp
	Wire.Material = Enum.Material.Neon
	Wire.Color = RunService:IsServer() and Color3.fromRGB(172, 255, 116) or Color3.fromRGB(146, 202, 255)
	Wire.Transparency = 0.3
	Wire.Size = Vector3.new(0.05, 0.05, (origin - hit).Magnitude )
	Wire.CFrame = CFrame.lookAt(origin:Lerp(hit, 0.5), hit)
	Wire.Anchored = true
	Wire.CanQuery = false
	Wire.CanCollide = false
	
	--local Wire = Instance.new("WireframeHandleAdornment")
	--Wire.Parent = workspace.Temp
	--Wire.Adornee = workspace
	----Wire.Scale = Vector3.new(1, 1, (origin - hit).Magnitude )
	----Wire.CFrame = CFrame.new(origin:Lerp(hit, 0.5))
	--Wire.AlwaysOnTop = true
	--Wire.AdornCullingMode = Enum.AdornCullingMode.Never
	--Wire.Thickness = 1
	--Wire.Color3 = RunService:IsServer() and Color3.fromRGB(172, 255, 116) or Color3.fromRGB(146, 202, 255)
	
	--print(origin,hit)
	
	--Wire:AddLine(origin, hit)
	
	game:GetService("Debris"):AddItem(Wire, 10)
end

local function DebugDirection(offset, direction)
	
	if not DEBUG then
		return
	end
	
	local Line = Instance.new("ConeHandleAdornment")
	Line.Parent = workspace.Temp
	Line.Adornee = workspace.Terrain
	Line.CFrame = CFrame.lookAlong(offset, direction)
	Line.AdornCullingMode = Enum.AdornCullingMode.Never
	Line.Transparency = 0.45
	Line.AlwaysOnTop = true
	Line.Radius = 0.4
	Line.Height = 2
	Line.Color3 = RunService:IsServer() and Color3.fromRGB(172, 255, 116) or Color3.fromRGB(146, 202, 255)

	game:GetService("Debris"):AddItem(Line, 10)
end

--//Methods

function Harpoon.Start(self: Skill, origin: Vector3, hit: Vector3)
	
	--auto-completing
	if RunService:IsClient() then
		
		local Offset = Camera.CFrame.Position
		local Direction = Camera.CFrame.LookVector
		
		--start time on client
		hit = GetHitPoint(Offset, Direction, { self.Character.Instance })
		origin = Offset
		
		--debugging
		DebugPoint(Offset, hit)
		DebugDirection(Offset, Direction)
	end
	
	WCS.Skill.Start(self, origin, hit)
end

function Harpoon.SnapHarpoon(self: Skill, player: Player)
	if self._SnappedFlag then
		return
	end
	
	self._SnappedFlag = true
	
	local CharacterComponent = ComponentsUtility.GetComponentFromCharacter(player.Character)
	
	CharacterComponent.WCSCharacter:TakeDamage(
		self:CreateDamageContainer(
			self.FromRoleData.SnapDamage
		)
	)
	self:End()
	SoundUtility.CreateTemporarySoundAtPosition(player.Character.Humanoid.RootPart.Position, Sfx.Equip).Parent = player.Character
	
	
end

function Harpoon.HandlePlayerPierce(self: Skill, player: Player)
	
	local CharacterComponent = ComponentsUtility.GetComponentFromCharacter(player.Character)
	local HasStatuses = CharacterComponent and WCSUtility.HasActiveStatusEffectsWithNames(
		CharacterComponent.WCSCharacter,
		{
			"Hidden",
			"Handled",
			"Invincible",
		}
	)
	
	if not CharacterComponent or HasStatuses then
		
		self:End()
		
		return
	end
	
	self.Janitor:Remove("HitboxOnHit")
	self.Janitor:Remove("AimingAnimation")
	
	local AttractTrack = AnimationUtility.QuickPlay(self.Character.Humanoid, self.FromRoleData.Animations.Attract, {
		Looped = true,
		Priority = Enum.AnimationPriority.Action3,
	})
	
	self.Janitor:Add(function()
		AttractTrack:Stop(1)
	end)
	
	SoundUtility.CreateTemporarySoundAtPosition(self.Character.Humanoid.RootPart.Position, Sfx.Stretch).Parent = self.Character.Humanoid.RootPart
	--SoundUtility.CreateTemporarySound(Sfx.Stretch).Parent = self.Character.Humanoid.RootPart
	
	--dealing damage to player we hit
	CharacterComponent.WCSCharacter:TakeDamage(
		self:CreateDamageContainer(
			self.FromRoleData.Damage
		)
	)
	
	self.Janitor:Remove("MissDurationWatchThread")
	
	
	self._PiercedCharacter = player.Character
	
	local KillerRootPart = self.Character.Humanoid.RootPart :: BasePart
	local StudentHumanoid = self._PiercedCharacter:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	
	if not self:ShouldAttract() then
		
		-- we ended early! snap the harpoon
		if (KillerRootPart.Position - StudentHumanoid.RootPart.Position).Magnitude > 10 then
			self:SnapHarpoon(player)
		else
			self:End()
		end
		
		return
	end
	
	self.Janitor:Get("Effect"):Pierce(player.Character)
	self.Janitor:Add(HarpoonPiercedStatus.new(CharacterComponent.WCSCharacter, self.Player), "Destroy", "VictimStatus"):Start()
	self.Janitor:Add(RunService.Stepped:Connect(function()
		local Sound = SoundUtility.CreateTemporarySoundAtPosition(KillerRootPart.Position, SoundUtility.Sounds.Players.Skills.Harpoon.Rope)
		Sound.Parent = KillerRootPart
		
		self.Janitor:Add(Sound, nil, "StretchingSound")
		
		
		if self:ShouldAttract() then
			return
		end
		
		-- we ended early! snap the harpoon
		if (KillerRootPart.Position - StudentHumanoid.RootPart.Position).Magnitude > 10 then
			self:SnapHarpoon(player)
		else
			self:End()
		end
		
		
		
		-- Experimental (понадеемся что остановит инерцию)
		--[[warn(player.Character.Humanoid, player.Character.Humanoid.RootPart, self.Instances.Velocity)
		if player.Character.Humanoid.RootPart then
			player.Character.Humanoid.RootPart.AssemblyLinearVelocity *= -1 -- было на 0 (но что если...)
		end]]
		
	end), nil, "StretchingUpdate")
end

function Harpoon.ShouldAttract(self: Skill)
	
	--no component exists for victim
	if not ComponentsUtility.GetComponentFromCharacter(self._PiercedCharacter) then
		return false
	end
	
	local StudentHumanoid = self._PiercedCharacter:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	
	--attracted player is dead or has no humanoid
	if not StudentHumanoid or StudentHumanoid.Health == 0 then
		return false
	end
	
	local KillerRootPart = self.Character.Humanoid.RootPart :: BasePart
	local StudentRootPart = StudentHumanoid.RootPart :: BasePar
	local Sub: Vector3 = StudentRootPart.Position - KillerRootPart.Position
	
	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.Temp, workspace.Characters, workspace.ThrownItems}
	Params.RespectCanCollide = true
	Params.CollisionGroup = "Players"
	Params.FilterType = Enum.RaycastFilterType.Exclude
	
	return 10 < Sub.Magnitude and workspace:Raycast(KillerRootPart.Position, Sub.Unit * Sub.Magnitude, Params) == nil
end

function Harpoon.ShouldStart(self: Skill)
	
	if RunService:IsClient() and not WCSUtility.HasActiveStatusEffectsWithNames(self.Character, {"Aiming"}) then
		return false
	end
	
	return BaseHoldableSkill.ShouldStart(self)
end

function Harpoon.OnStartServer(self: Skill, origin: Vector3, hit: Vector3)
	self._SnappedFlag = false
	--initials
	
	--calculating goals on server
	local Origin = origin --self.Character.Instance.Head.Position :: Vector3
	local Hit = GetHitPoint(Origin, -(Origin - hit).Unit, { self.Character.Instance })
	local Direction = -(Origin - Hit).Unit
	
	local Model = self.Character.Instance :: PlayerTypes.Character
	local Weapon = Model:FindFirstChild("CompassArmDown") :: BasePart
	local Spike = Weapon:FindFirstChild("Spike") :: BasePart
	local HeadPosition = Model.Head.Position
	
	--debugging
	DebugPoint(Origin, Hit)
	
	--validating local player's shot offset
	--if (HeadPosition - Origin).Magnitude > CLIENT_OFFSET_THRESHOLD_DISTANCE then
	--	Origin = HeadPosition
	--end

	--projectile instance
	local Projectile = Spike:Clone()
	--print(Projectile, Spike)
	Projectile.Transparency = 1
	Projectile.Parent = workspace.Temp
	Projectile.CFrame = CFrame.lookAlong(Origin, Direction)

	--Speed slowing
	self.Janitor:Add(ModifiedSpeedStatus.new(self.Character, "Multiply", 0.4, { Priority = 2, Tag = "HarpoonLaunched"}), "Destroy", "SpeedModifier")
	self.Janitor:Get("SpeedModifier").DestroyOnEnd = false
	self.Janitor:Get("SpeedModifier"):Start()
	
	self.Janitor:Add(task.delay(self.FromRoleData.MissDuration, function()
		print("CANCELING HARPOON")
		self:End()
	end), nil, "MissDurationWatchThread")

	--Effect initialization
	self.Janitor:Add(HarpoonSkillEffect.new(self.Character.Instance, Origin, Direction), "Destroy", "Effect"):Start(Players:GetPlayers())

	--animations
	self.Janitor:Add(AnimationUtility.QuickPlay(self.Character.Humanoid, self.FromRoleData.Animations.Release, {
		Looped = false,
		Priority = Enum.AnimationPriority.Action4,
		PlaybackOptions = {
			Weight = 1000
		}
	}), "Stop", "ReleaseAnimation")

	local AimingTrack = AnimationUtility.QuickPlay(self.Character.Humanoid, self.FromRoleData.Animations.Aiming, {
		Looped = true,
		Priority = Enum.AnimationPriority.Action3,
	})

	self.Janitor:Add(function()
		AimingTrack:Stop(1)
	end, nil, "AimingAnimation")

	--sounds
	SoundUtility.CreateTemporarySound(Sfx.Equip).Parent = self.Character.Humanoid.RootPart

	--Forces initialization
	local Alignment = Projectile:FindFirstChild("Alignment")
	
	if not Alignment then
		Alignment = Instance.new("Attachment")
		Alignment.Parent = Projectile
		Alignment.Name = "Alignment"
	end

	local Velocity = Projectile:FindFirstChildWhichIsA("LinearVelocity") :: LinearVelocity?
	
	if not Velocity then
		Velocity = Instance.new("LinearVelocity")
		Velocity.Parent = Projectile
		Velocity.Enabled = false
		Velocity.MaxForce = 2000
		Velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		Velocity.Attachment0 = Alignment
		Velocity.VectorVelocity = Direction * self.FromRoleData.Velocity
		Velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude
		Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	end

	self.Instances.Velocity = Velocity
	self.Instances.Projectile = Projectile

	--Hitbox initialization
	local Hitbox = ShapecastHitbox.new(Projectile)
	local Params = RaycastParams.new()

	Utility.ApplyParams(Params, {
		FilterType = Enum.RaycastFilterType.Exclude,
		CollisionGroup = "Projectiles",
		FilterDescendantsInstances = { Model, Projectile, workspace.Temp },
	} :: RaycastParams)

	--Hitbox.DetectionMode = RaycasttHitbox.DetectionMode.Bypass
	Hitbox.RaycastParams = Params
	ShapecastHitbox.Settings.Debug_Visible = DEBUG
	Hitbox:SetCastData({ CastType = "Raycast" })
	

	self.Janitor:Add(function()
		Projectile:Destroy()
		Hitbox:HitStop():Destroy()

		self.Instances.Velocity = nil
		self.Instances.Projectile = nil

	end, nil, "ProjectileReset")

	Velocity.Enabled = true

	--physics initializaton
	self.Janitor:Add(RunService.Stepped:Connect(function()
		
		Projectile.CFrame =
			CFrame.lookAlong(Projectile.CFrame.Position, Velocity.VectorVelocity)
			* CFrame.Angles(0, math.rad(-90), math.rad(90))

		Velocity.VectorVelocity = Vector3.new(
			Velocity.VectorVelocity.X,
			Velocity.VectorVelocity.Y - 0.05,
			Velocity.VectorVelocity.Z
		)
	end), nil, "ProjectilePhysics")

	self._ShotTimestamp = os.clock()

	local InstanceHit = false
	local PlayerHit = false

	Hitbox:HitStart():OnHit(function(raycastResult: RaycastResult, segmentHit: ShapecastHitbox.Segment)
		local basepart = raycastResult.Instance
		local ShouldPass = not basepart.CanCollide
		local Instance = basepart:FindFirstAncestorWhichIsA("Model")
		local Player = Players:GetPlayerFromCharacter(Instance)

		self._HitTimestamp = os.clock()
		
		if PlayerHit then
			return
		end

		if Player and ComponentsManager.Get(Player, "PlayerComponent"):IsStudent() then
			PlayerHit = true
			Hitbox:HitStop()
			
			self.Janitor:Remove("ProjectileReset")
			self:HandlePlayerPierce(Player)
			

			return

		elseif Instance:HasTag("Door") and not InstanceHit then
			
			--extracting door component from instance hit
			local DoorComponent = ComponentsManager.GetFirstComponentInstanceOf(Instance, "BaseDoor")
			
			if not DoorComponent then
				return
			end

			ShouldPass = false

			if DoorComponent:IsOpened() or DoorComponent:IsBroken() then
				
				ShouldPass = true
				
				return
					
			elseif math.max(0, DoorComponent.Attributes.Health - self.FromRoleData.DoorDamage) == 0 then
				
				--predicting if door will break after harpoon hit, then pierce if so
				ShouldPass = true
			end

			InstanceHit = true
			
			--dealing damage for door we hit
			DoorComponent:TakeDamage(
				self:CreateDamageContainer(
					self.FromRoleData.DoorDamage
				)
			)
			
			local ProxyService = Classes.GetSingleton("ProxyService")
			ProxyService:AddProxy("DoorHarpooned"):Fire(self.Player, DoorComponent)
		end
		
		--cancelling harpoon via hitting surface with VFX
		if not ShouldPass and not PlayerHit then
			PlayerHit = true
			MetallicImpactEffect.new(
				
				CFrame.lookAlong(
					raycastResult.Position,
					raycastResult.Normal
				)
			):Start(Players:GetPlayers())
			Hitbox:HitStop()
			self:End()
			
		end
	end)
	
	--start time on server
	DebugDirection(Origin, Direction)
end

function Harpoon.OnEndServer(self: Skill)
	self:ApplyCooldown(self.FromRoleData.Cooldown)
end

function Harpoon.OnStartClient(self: Skill)
	
	--some client visual stuff
	--Classes.GetSingleton("CameraController"):QuickShake(0.2, 2)
end

function Harpoon.OnConstruct(self: Skill)
	BaseHoldableSkill.OnConstruct(self)
	
	self:SetMaxHoldTime(self.FromRoleData.Duration)
	
	self.Instances = {}
	
	self.CheckOthersActive = false
	self.ExclusivesSkillNames = {"Shockwave"}
	self.ExclusivesStatusNames = {
		{"ModifiedSpeed", {"Freezed"}}
	}
end

--//Returner

return Harpoon