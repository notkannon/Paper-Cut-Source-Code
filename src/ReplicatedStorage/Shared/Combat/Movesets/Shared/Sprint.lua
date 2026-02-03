--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local TerrorController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.EnvironmentController.TerrorController) or nil

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseHoldableSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseHoldableSkill)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)
local ModifiedStaminaGain = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedStaminaGain)
local ModifiedStaminaLoss = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedStaminaLoss)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)

--//Constants

local DOOR_SLAM_DISTANCE = 3
local DOOR_CHECK_RAYCAST_PARAMS = RaycastParams.new()
DOOR_CHECK_RAYCAST_PARAMS.CollisionGroup = "Players"
DOOR_CHECK_RAYCAST_PARAMS.RespectCanCollide = true
DOOR_CHECK_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
DOOR_CHECK_RAYCAST_PARAMS.FilterDescendantsInstances = { workspace.Characters, workspace.Temp }

--//Variables

local RunningSound = SoundUtility.Sounds.Players.Running :: Sound
local Sprint = WCS.RegisterHoldableSkill("Sprint", BaseHoldableSkill)

--//Types

export type Skill = BaseHoldableSkill.BaseHoldableSkill & {
	SpeedModifier: ModifiedSpeedStatus.Status,
}

--//Methods

--Overriden skill behavior used to stop client sprint anyhow
function Sprint.End(self: Skill)
	if RunService:IsClient() then
		self.Janitor:Cleanup()
	end
	
	WCS.Skill.End(self)
end

function Sprint.GetLinearVelocity(self: Skill)
	local HumanoidRootPart = self.Character.Instance.HumanoidRootPart :: BasePart
	
	if HumanoidRootPart.Anchored then
		return Vector3.zero
	end
	
	return HumanoidRootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
end

function Sprint._CheckDoorOnWay(self: Skill)
	
	local HumanoidRootPart = self.Character.Instance.HumanoidRootPart :: BasePart
	
	local Result = workspace:Shapecast(
		HumanoidRootPart,
		HumanoidRootPart.AssemblyLinearVelocity.Unit * DOOR_SLAM_DISTANCE,
		DOOR_CHECK_RAYCAST_PARAMS
	)

	local DoorModel = Result and Result.Instance:FindFirstAncestorWhichIsA("Model") :: Model?
	
	if not DoorModel or not DoorModel:HasTag("Door") then
		return
	end
	
	local DoorComponent = ComponentsManager.GetComponentsFromInstance(DoorModel)[1]
	
	if not DoorComponent then
		return
	end
	
	DoorComponent:PromptSlamClient()
end

-- fix bug when sprint NOT ends sometimes when stamina is empty and input is ended. So weird
--UPD: fixed with _AssumeStarted handling
function Sprint.AssumeStart(self: Skill)
	
	if not self:ShouldStart() then
		return
	end
	
	local Stamina = ComponentsManager.Get(self.Character.Instance, "Stamina")
	local PlayerController = Classes.GetSingleton("PlayerController")
	local AnimationSpeedScale = self.FromRoleData.AnimationSpeedScale
	
	self._AssumeRunning = true
	self.AnimationTrack:Play()
	self.SpeedModifier:Start()
	
	self.Janitor:Add(function()
		
		self._AssumeRunning = false
		self.SpeedModifier:Stop()
		self.AnimationTrack:Stop(0.3)
		
	end)
	
	if self.AnimationInjuredTrack then
		
		self.Janitor:Add(function()
			if self.AnimationInjuredTrack.IsPlaying then
				self.AnimationInjuredTrack:Stop(0.3)
			end
		end)
		
		self.Janitor:Add(RunService.RenderStepped:Connect(function(delta)
			--print(self._AssumeRunning, self.AnimationTrack.IsPlaying, self.AnimationInjuredTrack.IsPlaying)
			if not self._AssumeRunning then

				if self.AnimationInjuredTrack.IsPlaying then
					self.AnimationInjuredTrack:Stop(0.3)
				end

				return 
			end

			local HPPercentage = self.Character.Humanoid.Health / self.Character.Humanoid.MaxHealth

			if HPPercentage >= 0.5 then

				if self.AnimationInjuredTrack.IsPlaying then
					self.AnimationInjuredTrack:Stop()
				end

			else

				if not self.AnimationInjuredTrack.IsPlaying then

					self.AnimationInjuredTrack:Play()
					self.AnimationTrack:Stop()

				end

			end
		end))
		
	end
	
	if Classes.GetSingleton("PlayerController"):IsStudent() then
		
		self.Janitor:Add(task.delay(RunningSound.Volume > 0 and 0.5 or 5, function()
			
			if not RunningSound.IsPlaying then
				RunningSound:Play()
				RunningSound.Volume = 0
			end
			
			TweenUtility.ClearAllTweens(RunningSound)
			TweenUtility.PlayTween(RunningSound, TweenInfo.new(3), {
				Volume = 0.4
			})
		end))
		
		self.Janitor:Add(function()
			TweenUtility.ClearAllTweens(RunningSound)
			TweenUtility.PlayTween(RunningSound, TweenInfo.new(7), {
				Volume = 0
			})
		end)
	end

	self.Janitor:Add(RunService.Stepped:Connect(function(_, delta)
		
		local InTerror = TerrorController:GetCurrentLayerId() ~= nil
		local IsKiller = PlayerController:IsKiller()
		local Magnitude = self:GetLinearVelocity().Magnitude
		local WalkSpeed = self.Character:GetDefaultProps().WalkSpeed
		
		self:_CheckDoorOnWay()
		
		-- not much affection for player speed
		local AnimationSpeed = MathUtility.QuickLerp(1, Magnitude / WalkSpeed / 1.5, 0.75)
		local StaminaLoss = -self.FromRoleData.StaminaLossPerSecond * delta
		local StaminaLossEffects = WCSUtility.GetAllStatusEffectsInstanceOf(self.Character, ModifiedStaminaLoss, true)
		
		StaminaLoss = ModifiedStaminaLoss.ResolveModifiers(StaminaLossEffects, StaminaLoss)
		
		local SpeedMult = AnimationSpeed * (AnimationSpeedScale or 1)
		
		self.AnimationTrack:AdjustSpeed(SpeedMult)
		
		if self.AnimationInjuredTrack then
			self.AnimationInjuredTrack:AdjustSpeed(SpeedMult * 1.3) -- speed multiplier is extra setting for exact anim currently
		end
		
		--stamina drains only when killer in Terror radius
		--print(InTerror, IsKiller, self.Janitor:Get("SprintReducedStaminaGain"))
		if IsKiller then
			
			if InTerror then
				Stamina:Increment(StaminaLoss)
				self.Janitor:Remove("SprintReducedStaminaGain")
			else
				if RunService:IsClient() then
					local Effect = self.Janitor:Add(ModifiedStaminaGain.new(self.Character, "Multiply", 0.5, {Tag = "SprintReducedStaminaGain"}), "End", "SprintReducedStaminaGain")
					Effect:Start()
				end
			end
		else
			Stamina:Increment(StaminaLoss)
		end

		if not self:ShouldContinue() then
			self:End()
		end
		
	end), nil, "StepsConnection")
end

function Sprint.ShouldContinue(self: Skill)
	
	if self:GetLinearVelocity().Magnitude < self.Character:GetDefaultProps().WalkSpeed / 3 then
		return false
	end

	local Stamina = ComponentsManager.Get(self.Character.Instance, "Stamina")
	
	if not Stamina or Stamina:Get() == 0 then
		
		--no restoring until skill ends
		if Stamina and not self.Janitor:Get("SprintReducedStaminaGain") then
			Stamina:UseNoIncrement()
		end
		
		return false
	end
	
	--also check abstraction limits
	return BaseHoldableSkill.ShouldStart(self)
end

function Sprint.ShouldStart(self: Skill)
	
	if self:GetLinearVelocity().Magnitude < self.Character:GetDefaultProps().WalkSpeed / 3 then
		return false
	end
	
	if RunService:IsClient() then
		
		local Stamina = ComponentsManager.Get(self.Character.Instance, "Stamina")
		
		if self._AssumeRunning
			or not Stamina
			or Stamina:Get() == 0 then
			
			--no restoring until skill ends
			if Stamina and not self.Janitor:Get("SprintReducedStaminaGain") then
				Stamina:UseNoIncrement()
			end
			
			return false
		end
	end
	
	return BaseHoldableSkill.ShouldStart(self)
end

function Sprint.OnConstructClient(self: Skill)
	
	self.SpeedModifier = ModifiedSpeedStatus.new(self.Character, "Set", self.FromRoleData.WalkSpeed, {
		
		Priority = 1,
		FadeInTime = 0.5,
		FadeOutTime = 1,
		Tag = "Sprint",
		
	} :: ModifiedSpeedStatus.SpeedModifierOptions)
	
	self.SpeedModifier.DestroyOnFadeOut = false
	
	RunningSound.Volume = 0
	RunningSound:Stop()
	
	local Animation = self.FromRoleData.Animation	
	self.AnimationTrack = self.Character.Humanoid.Animator:LoadAnimation(Animation)
	
	if self.FromRoleData.AnimationInjured then
		self.AnimationInjuredTrack = self.Character.Humanoid.Animator:LoadAnimation(self.FromRoleData.AnimationInjured)
	end
end

function Sprint.OnConstruct(self: Skill)
	BaseHoldableSkill.OnConstruct(self)
	
	self:SetMaxHoldTime(nil)
	
	self.CheckClientState = true
	self.CheckOthersActive = false
	
	self.ExclusivesSkillNames = {
		--circle
		"Harpoon", "Shockwave", "Stealth",
		
		"Swing", --troublemaker
		"ConcealedPresence", --stealther
	}
	
	self.ExclusivesStatusNames = {
		-- Generic statuses
		"Aiming", "Downed", "Hidden", "Stunned", "Handled", "Physics", "HarpoonPierced", "ObjectiveSolving", 
		-- Speed modifiers
		{"ModifiedSpeed", {"Slowed", Match = true}},
	}
end

--//Returner

return Sprint