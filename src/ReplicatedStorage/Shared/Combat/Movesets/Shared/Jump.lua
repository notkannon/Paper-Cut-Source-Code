----//Services

--local RunService = game:GetService("RunService")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local ServerScriptService = game:GetService("ServerScriptService")

----//Imports

--local WCS = require(ReplicatedStorage.Packages.WCS)
--local Classes = require(ReplicatedStorage.Shared.Classes)
--local BaseSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseSkill)
--local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
--local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
--local AffectedHumanoidProps = require(ReplicatedStorage.Shared.Combat.Statuses.AffectedHumanoidProps)
--local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--local CameraController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.CameraController) or nil

----//Constants

--local PI = math.pi

----//Variables

--local Jump = WCS.RegisterSkill("Jump", BaseSkill)

----//Types

--export type Skill = BaseSkill.BaseSkill

----//Methods

--function Jump.AssumeStart(self: Skill)
--	self.AnimationTracks.Jump:Play()
--	self.AnimationTracks.FreeFall:Play()
	
--	self.HumanoidAffectStatus:Start()
--	self.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
--	self.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	
--	ComponentsManager.Get(self.Character.Instance, "Stamina"):Increment(-self.FromRoleData.StaminaLoss)
	
--	self.HumanoidAffectStatus:End()
--	self.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
--end

--function Jump.OnEndServer(self: Skill)
--	self:ApplyCooldown(self.FromRoleData.Cooldown)
--end

--function Jump.ShouldStart(self: Skill)
--	if table.find({
--		Enum.HumanoidStateType.PlatformStanding,
--		Enum.HumanoidStateType.FallingDown,
--		Enum.HumanoidStateType.Freefall,
--		Enum.HumanoidStateType.Ragdoll,
--		Enum.HumanoidStateType.Jumping,
--		Enum.HumanoidStateType.Dead,
--		}, self.Character.Humanoid:GetState())
--	then
--		return false
--	end
	
--	if RunService:IsClient() then
		
--		local Stamina = ComponentsManager.Get(self.Character.Instance, "Stamina")
		
--		if not Stamina or Stamina:Get() < 20 then
--			return false
--		end
--	end

--	return BaseSkill.ShouldStart(self)
--end

--function Jump.OnConstructClient(self: Skill)
--	self.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	
--	self.HumanoidAffectStatus = AffectedHumanoidProps.new(self.Character, {
--		JumpPower = { self.FromRoleData.JumpPower, "Set" },
--	})
	
--	self.HumanoidAffectStatus.DestroyOnEnd = false
	
--	self.AnimationTracks = {
--		Jump = self.Character.Humanoid.Animator:LoadAnimation(self.FromRoleData.Animations.Jump),
--		Land = self.Character.Humanoid.Animator:LoadAnimation(self.FromRoleData.Animations.Land),
--		FreeFall = self.Character.Humanoid.Animator:LoadAnimation(self.FromRoleData.Animations.FreeFall),
--	}
	
--	self.AnimationTracks.Land.Priority = Enum.AnimationPriority.Action3
--	self.AnimationTracks.Jump.Priority = Enum.AnimationPriority.Action4
--	self.AnimationTracks.FreeFall.Priority = Enum.AnimationPriority.Action3
	
--	self.GenericJanitor:Add(self.Character.Humanoid.StateChanged:Connect(function(_, newState: Enum.HumanoidStateType)
--		if table.find({ Enum.HumanoidStateType.Jumping, Enum.HumanoidStateType.Landed }, newState) then
--			CameraController.Cameras.Default:TiltCamera(CFrame.Angles(-PI/30, 0, 0), false, {
--				Time = 0.05,
--				EasingStyle = Enum.EasingStyle.Sine,
--				EasingDirection = Enum.EasingDirection.Out,
--			})
--		end
		
--		if newState ~= Enum.HumanoidStateType.Landed then
--			return
--		end

--		-- TODO: Landed sound
--		self.AnimationTracks.Land:Play()
--		self.AnimationTracks.FreeFall:Stop()
--	end))
--end

--function Jump.OnConstruct(self: Skill)
--	BaseSkill.OnConstruct(self)

--	self.CheckClientState = true
--	self.CheckOthersActive = false
	
--	self.ExclusivesSkillNames = {}
	
--	self.ExclusivesStatusNames = {
--		-- Generic statuses
--		"Aiming", "Downed", "Hidden", "Handled", "Stunned", "Physics", "HarpoonPierced",
--		-- Speed modifiers
--		"AimDetained", "AttackSlowed", "FallDamageSlowed",
--	}
--end

----//Returner

--return Jump

return nil