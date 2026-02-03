--//Services

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local BaseHoldableSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseHoldableSkill)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local Utility = require(ReplicatedStorage.Shared.Utility)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local HitboxUtility = require(ReplicatedStorage.Shared.Utility.HitboxUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local MatchService = RunService:IsServer() and require(ServerScriptService.Server.Services.MatchService) or nil
local PlayerService = RunService:IsServer() and require(ServerScriptService.Server.Services.PlayerService) or nil

local StunnedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Stunned)
local ModifiedVisibilityStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedVisibility)

local FireExtinguisherExplosionEffect = require(ReplicatedStorage.Shared.Effects.FireExtinguisherExplosion)

--//Variables

local Spray = WCS.RegisterSkill("Spray", BaseHoldableSkill)

--//Types

export type Skill = BaseSkill.BaseSkill

--//Methods

function Spray.OnStartServer(self: Skill)

	--being stopped <-- or exstremely slowed
	--can be damaged during Spraying

	local FilteredCharacterInstances = { self.Character.Instance }
	local Visuals = self.FromRoleData.Visuals :: {
		Gear: BasePart,
		Animation: Animation,
	}

	--gear handling
	local Gear = self.Janitor:Add(self.FromRoleData.Visuals.Gear:Clone()) :: BasePart
	local Grip = Gear:FindFirstChildWhichIsA("Motor6D")
	
	Gear.Parent = self.Character.Instance
	Gear.CollisionGroup = "Items"
	Grip.Part0 = Gear
	Grip.Part1 = self.Character.Instance:FindFirstChild("RightHand")
	Grip.Parent = Grip.Part1
	
	--animation playback
	local AnimationTrack = AnimationUtility.QuickPlay(
		
		self.Character.Humanoid,
		Visuals.Animation, {
			
			Looped = false,
			Priority = Enum.AnimationPriority.Action4,
		}
	)
	
	--returns true if a player has the gear in his fov
	local function IsGearInFOV(player: Player) : boolean
		local CurrentCharacter = player.Character :: PlayerTypes.Character
		if not CurrentCharacter then
			return 
		end
		local Position = Gear.Position
		local CurrentPos = CurrentCharacter.HumanoidRootPart.Position :: Vector3
		local Distance = (Position - CurrentPos).Magnitude
		
		if Distance <= 10 then
			return true -- looking away wont save you
		end

		return CurrentCharacter.HumanoidRootPart.CFrame.LookVector:Dot((Position - CurrentPos).Unit) >= 0
	end
	
	local function ApplyImpulse(strength: number, origin: Vector3, direction: Vector3)

		Gear:PivotTo(CFrame.lookAlong(origin, direction))
		Gear.AssemblyLinearVelocity = Vector3.zero
		Gear.AssemblyAngularVelocity = Vector3.zero

		--print("APPLYING IMPULSE TO", basepart, origin, direction, direction - origin)
		Gear:ApplyImpulse(direction * strength * 80)
	end

	
	local function SnapAngle(x: number) : number
		if x >= 0 then
			return 90
		end
		return -90
	end
	
	local function AfflictCharactersInHitboxWithStatus(hitbox: HitboxUtility.Hitbox, duration: number, incrementAmount: number, modifierOptions: table)
		local Characters = select(1, HitboxUtility.GetCharactersInHitbox(Gear.CFrame, hitbox, {
			ComponentMode = "Exclude",
			StatusesNames = {"Ragdolled", "Downed", "Handled"} -- should i add invincible?
		}))
		
		local ProxyService = Classes.GetSingleton("ProxyService")

		for _, Character: PlayerTypes.Character in ipairs(Characters) do
			local AfflictedPlayer = Players:GetPlayerFromCharacter(Character)

			local WCSCharacter = WCS.Character.GetCharacterFromInstance(Character)

			if not IsGearInFOV(AfflictedPlayer) then
				return
			end

			if not WCSCharacter then
				continue
			end
			
			-- dont interrupt the nerds :D
			if WCSUtility.HasActiveStatusEffectsWithNames(WCSCharacter, {"ObjectiveSolving"}) then
				continue
			end
			
			local Status = ModifiedVisibilityStatus.new(WCSCharacter, "Increment", incrementAmount, modifierOptions)
			
			if incrementAmount >= 0.5 then
				ProxyService:AddProxy("TroublemakerFoamBlinded"):Fire(self.Player, Players:GetPlayerFromCharacter(Character))
			end
			Status:Start(duration)
		end
	end
	
	--sounds
	
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Instances.Items.Throwable.Throw
	).Parent = self.Character.Humanoid.RootPart
	
	self.Janitor:Add(task.delay(0.05, function()
		Gear.Parent = workspace.Temp
		Grip:Destroy()
		
		-- throw physics
		local HeadPosition = self.Character.Instance:FindFirstChild("Head").Position
		local CameraLookVector = self.Character.Instance.HumanoidRootPart.CFrame.LookVector
		ApplyImpulse(0.4, Gear.Position, CameraLookVector)
	end))
	
	-- main part after explosion
	
	self.Janitor:Add(task.delay(self.FromRoleData.DetonationDelay, function()
		
		Gear.Anchored = true
		Gear.CanCollide = false
		Gear.CanTouch = false
		
		for _, Emitter: ParticleEmitter in Gear.Particles:GetChildren() do
			Emitter.Enabled = true
		end
		
		self.Janitor:Add(SoundUtility.CreateSound(SoundUtility.Sounds.Instances.Items.Misc["Explosion Fire Short"])).Parent = Gear
		local FireExtinguisherSound = self.Janitor:Add(SoundUtility.CreateSound(SoundUtility.Sounds.Instances.Items.Misc.FireExtinguisherLoop, true))
		FireExtinguisherSound.Parent = Gear
		FireExtinguisherSound:Play()
		self.Janitor:Add(task.delay(5, function()
			TweenUtility.PlayTween(FireExtinguisherSound, TweenInfo.new(3, Enum.EasingStyle.Linear), {Volume = 0})
		end))
		
		local X, Y, Z = Gear.CFrame:ToEulerAnglesXYZ()
		Gear.CFrame = CFrame.new(Gear.Position - Vector3.new(0, 0.2, 0)) * CFrame.Angles(math.rad(90), 0, 0)
		
		local FrameNumber = -1
		local HitboxEveryFrames = 2
		self.Janitor:Add(RunService.PreSimulation:Connect(function(d)
			-- snapping X and Z rotation, and moving along Y axis
			FrameNumber += 1
			local X, Y, Z = Gear.CFrame:ToEulerAnglesXYZ() -- Why this? its repeat :skull:
			--print(math.deg(X), math.deg(Y), math.deg(Z), "|", d)
			Gear.CFrame *= CFrame.Angles(0, 0, math.rad(180 * d))
			
			local BaseBlindnessTime = self.FromRoleData.FoamBlindnessDuration
			local FadeoutBlindnessTime = self.FromRoleData.FadeoutBlindnessDuration
			
			if FrameNumber % HitboxEveryFrames == 0 or d >= 0.1 then
				AfflictCharactersInHitboxWithStatus(self.FromRoleData.SprayHitbox, BaseBlindnessTime, 0.1, {
					Style = Enum.EasingStyle.Cubic,
					Priority = 7,
					FadeInTime = 0.1,
					FadeOutTime = FadeoutBlindnessTime,
					Tag = "FoamBlinded"
				})
			end
		end))
		
		local Effect = FireExtinguisherExplosionEffect.new(Gear)
		Effect:Start()
		
		local BaseBlindnessTime = self.FromRoleData.DetonationBlindnessDuration
		local FadeoutBlindnessTime = self.FromRoleData.FadeoutBlindnessDuration
		
		AfflictCharactersInHitboxWithStatus(self.FromRoleData.DetonationHitbox, BaseBlindnessTime, 1, {
			Style = Enum.EasingStyle.Cubic,
			Priority = 7,
			FadeInTime = 0,
			FadeOutTime = FadeoutBlindnessTime,
			Tag = "ExplosionBlinded"
		})
	end))
end

function Spray.OnEndServer(self: Skill)
	self:ApplyCooldown(self.FromRoleData.Cooldown)
end

function Spray.ShouldStart(self: Skill)
	return BaseHoldableSkill.ShouldStart(self)
end

function Spray.OnConstruct(self: Skill)
	BaseHoldableSkill.OnConstruct(self)

	--duration should cover animation length
	self:SetMaxHoldTime(self.FromRoleData.DetonationDelay + self.FromRoleData.Duration)

	self.CheckClientState = true
	self.CheckOthersActive = false

	self.ExclusivesSkillNames = {}

	self.ExclusivesStatusNames = {
		-- Generic statuses
		"Downed", "Hidden", "Stunned", "Physics", "HarpoonPierced", "Handled", "HiddenComing", "HiddenLeaving", "ObjectiveSolving", 
		"MarkedForDeath", --in finishers (can be damaged without stopping ability but not on low health)
		
		{"ModifiedSpeed", {"Freezed"}}
	}
	
	self.IgnoreOngoingStatuses = true -- don't destroy skill if exclusive status appears after skill start
end

--//Returner

return Spray