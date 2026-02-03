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
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

local MatchService = RunService:IsServer() and require(ServerScriptService.Server.Services.MatchService) or nil
local PlayerService = RunService:IsServer() and require(ServerScriptService.Server.Services.PlayerService) or nil
local FallDamageService = require(ReplicatedStorage.Shared.Services.FallDamageService)

local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

--//Variables

local ConcealedPresence = WCS.RegisterSkill("ConcealedPresence", BaseHoldableSkill)

--//Types

export type Skill = BaseHoldableSkill.BaseHoldableSkill

--/Fucntions

local function GetColorCorrection()
	
	local cr = Lighting:FindFirstChild("ConcealedPresenceCR")
	
	if not cr then
		cr = Instance.new("ColorCorrectionEffect")
		cr.Parent = Lighting
		cr.Name = "ConcealedPresenceCR"
	end
	
	return cr
end

--//Methods

function ConcealedPresence.OnStartClient(self: Skill)
	
	local Animations = self.FromRoleData.Animations :: {
		Idle: Animation,
		Intro: Animation,
		Movement: Animation
	}
	
	local Correction = GetColorCorrection()
	
	TweenUtility.PlayTween(Correction, TweenInfo.new(1), {

		Contrast = -2,
		Saturation = -1.5,
		Brightness = -.4,

	} :: ColorCorrectionEffect)
	
	self.Janitor:Add(function()
		
		TweenUtility.PlayTween(Correction, TweenInfo.new(1), {

			Contrast = 0,
			Saturation = 0,
			Brightness = 0,

		} :: ColorCorrectionEffect)
	end)
	
	local IsMoving: boolean
	local Humanoid = self.Character.Humanoid
	local RootPart = Humanoid.RootPart :: BasePart
	
	--temporary effect
	self.Janitor:Add(SoundUtility.ApplySoundEffect("EqualizerSoundEffect", {
		
		HighGain = -12,
		MidGain = -10,
		LowGain = 4,
		
	} :: EqualizerSoundEffect, {
		
		FadeInTime = 1,
		FadeOutTime = 1,
	}))
	
	--intro cut
	self.Janitor:Add(AnimationUtility.QuickPlay(Humanoid, Animations.Intro, {
		
		Looped = false,
		Priority = Enum.AnimationPriority.Action3,
		
	}), "Stop"):AdjustSpeed(0.6)
	
	--idle loop
	self.Janitor:Add(AnimationUtility.QuickPlay(Humanoid, Animations.Idle, {
		
		Looped = true,
		Priority = Enum.AnimationPriority.Action2,
		
	}), "Stop")
	
	--movement track load
	local MovementTrack = AnimationUtility.LoadAnimationOnce(Humanoid, Animations.Movement)
	MovementTrack.Looped = true
	MovementTrack.Priority = Enum.AnimationPriority.Action3
	
	-- Variables for smooth animation transition
	local targetWeight = 0
	local currentWeight = 0
	local SMOOTHNESS_FACTOR = 0.1 -- Adjust for smoother/rougher transitions

	self.Janitor:Add(RunService.Heartbeat:Connect(function(deltaTime)
		
		-- Update movement state
		IsMoving = RootPart.AssemblyLinearVelocity.Magnitude > 1 or Humanoid.MoveDirection.Magnitude > 0

		-- Update target weight based on movement state
		targetWeight = IsMoving and 1 or 0

		-- Smoothly interpolate to target weight
		currentWeight = currentWeight + (targetWeight - currentWeight) * SMOOTHNESS_FACTOR

		-- Apply weight to animation track
		MovementTrack:AdjustSpeed(RootPart.AssemblyLinearVelocity.Magnitude / self.Character:GetDefaultProps().WalkSpeed * 2)
		MovementTrack:AdjustWeight(currentWeight)

		-- Play/stop animation based on weight
		if currentWeight > 0.01 then
			if not MovementTrack.IsPlaying then
				MovementTrack:Play()
			end
		else
			if MovementTrack.IsPlaying then
				MovementTrack:Stop()
			end
		end
	end))

	-- Clean up animation track
	self.Janitor:Add(MovementTrack, "Stop")
end

function ConcealedPresence.OnStartServer(self: Skill)
	
	--being invisible
	--being slow
	--listening for any affections (damage/fall/etc.)
	
	local Inventory = ComponentsManager.Get(self.Player.Backpack, "InventoryComponent")
	local Appearance = ComponentsManager.GetFirstComponentInstanceOf(self.Character.Instance, "BaseAppearance")
	
	self._Interrupted = false
	
	self.Janitor:Add(ModifiedSpeedStatus.new(self.Character, "Multiply", self.FromRoleData.SpeedModifier, {
		
		Style = Enum.EasingStyle.Cubic,
		Priority = 10,
		FadeInTime = 0.5,
		FadeOutTime = 1,
		Tag = "Stealth",
		
	})):Start()
	-- boo.png
	--almost quiet steps
	Appearance.Attributes.FootstepVolumeScale = 0.02
	
	
	Appearance:ApplyTransparency(self.FromRoleData.Transparency, {
		Time = 0.5,
	})
	
	--restoring transparency
	self.Janitor:Add(function()
		
		if not Appearance:IsDestroyed() then
			
			--restoring volume
			Appearance.Attributes.FootstepVolumeScale = 1
			
			Appearance:ApplyTransparency(0, {
				Time = 0.5,
			})
		end
	end)
	
	--connections

	--cancelling

	--any damage
	self.Janitor:Add(MatchService.PlayerDamaged:Connect(function(player)
		if player == self.Player then
			self._Interrupted = true
			self:End()
		end
	end))
	
	--fall damage
	self.Janitor:Add(FallDamageService.Landed:Connect(function(player)
		if player == self.Player then
			self._Interrupted = true
			self:End()
		end
	end))
	
	--any item activate (probably not any)
	self.Janitor:Add(Inventory.ItemActivated:Connect(function()
		self._Interrupted = true
		self:End()
	end))
	
	local ProxyService = Classes.GetSingleton("ProxyService")
	ProxyService:AddProxy("Stealthed"):Fire(self.Player)
	
	self.StartTimestamp = os.clock()
end

function ConcealedPresence.OnEndServer(self: Skill)
	local ProxyService = Classes.GetSingleton("ProxyService")
	
	-- why are we checking for time? cuz Stealth is a cancelable skill and canceling is client sided so we cant know if he canceled :sob:
	if not self._Interrupted and (os.clock() - self.StartTimestamp) >= (0.8 * self.FromRoleData.Duration) then
		ProxyService:AddProxy("StealthStealtherNaturalEnd"):Fire(self.Player)
	else
		ProxyService:AddProxy("StealthStealtherInterrupted"):Fire(self.Player)
	end
	self:ApplyCooldown(self.FromRoleData.Cooldown)
end

--function ConcealedPresence.ShouldStart(self: Skill)
--	return BaseHoldableSkill.ShouldStart(self)
--end

function ConcealedPresence.OnConstruct(self: Skill)
	BaseHoldableSkill.OnConstruct(self)

	self:SetMaxHoldTime(self.FromRoleData.Duration)

	self.CheckClientState = true
	self.CheckOthersActive = false

	self.ExclusivesSkillNames = {
		"Vault", --vaulting
	}
	
	self.ExclusivesStatusNames = {
		-- Generic statuses
		"Downed", "Hidden", "Stunned", "Physics", "HarpoonPierced", "HiddenComing", "HiddenLeaving", "ObjectiveSolving", 
		-- Speed modifiers
		{"ModifiedSpeed", {"FallDamageSlowed", "Freezed"}}
	}
end

--//Returner

return ConcealedPresence