--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService("RunService")

--//Imports

local WCS = require(ReplicatedStorage.Package.wcs)
local PlayerComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent)
local CameraController = RunService:IsClient() and require(ReplicatedStorage.Client.Camera) or nil
local BaseHoldableSkill = require(script.Parent.Parent.BaseHoldableSkill)

-- status effects
local Stun = require(ReplicatedStorage.Shared.Skill.StatusEffects.Stun)
local Downed = require(ReplicatedStorage.Shared.Skill.StatusEffects.Downed)
local Injured = require(ReplicatedStorage.Shared.Skill.StatusEffects.Injured)
local AffectedHumanoidProps = require(ReplicatedStorage.Shared.Skill.StatusEffects.AffectedHumanoidProps)

--//Variables

local Sprint = WCS.RegisterHoldableSkill("Sprint", BaseHoldableSkill)

--//Methods

function Sprint:OnStartServer()
	-- stopping other states if active
	for _, Skill in ipairs(self.Character:GetAllActiveSkills()) do
		if Skill.Name == 'Crouch' or Skill.Name == 'Taunt' then
			if Skill:GetState().IsActive then Skill:Stop() end
		end
	end
end

function Sprint:OnStartClient()
	local Animations = self.Component.Animator.Animations
	self.AnimationTrack:Play(0.3)
	self.Status:Start()
	
	self.Janitor:Add(RunService.Stepped:Connect(function()
		self.AnimationTrack:AdjustSpeed(self:GetLinearVelocity().Magnitude / self.Character.Humanoid.WalkSpeed * 1.25)
		
		if self.Component.Stamina:Get() == 0
			or self.Character.Humanoid.MoveDirection == Vector3.zero
			or self:GetLinearVelocity().Magnitude < self.Character.Humanoid.WalkSpeed / 3 then
			self:End()
		end
	end))
end

function Sprint:GetLinearVelocity()
	return self.Character.Instance.HumanoidRootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
end

function Sprint:OnEndClient()
	self.Status:Stop()
	self.AnimationTrack:Stop(0.3)
end

function Sprint:OnEndServer()
	self:ApplyCooldown(self.Data.Cooldown)
end

function Sprint:ShouldStart()
	local HideSkill = self.Character:GetSkillFromString('Hide')
	return not HideSkill or not HideSkill:GetState().IsActive
end

function Sprint:ShouldStartClient()
	return self:GetLinearVelocity().Magnitude > 0-- and self.Component:GetStamina() >= 20
end

function Sprint:OnConstruct()
	self.Data = {
		Name = 'Sprint',
		Visible = false,
		Cooldown = 1.5,
		Description = '...',
		DisplayOrder = 0,
	}
end

function Sprint:OnConstructServer()
	self:SetMaxHoldTime( 30 )
	self.CheckOthersActive = false
	self.MutualExclusives = { Stun, Downed }
end

function Sprint:OnConstructClient() 
	self.CleanupJanitorOnDestroy = true
	local Character = shared.Client.Player.Character
	
	self.AnimationTrack = Character.Animator.Animations.Sprinting.Track
	self.Component = Character
	
	self.Status = AffectedHumanoidProps.new(self.Character, {WalkSpeed = {15, "Increment"}})
	self.Status.DestroyOnEnd = false
	
	local to_destroy = {}
	table.insert(to_destroy,
		UserInputService.InputBegan:Connect(function(i, p)
			if p then return end if i.KeyCode == Enum.KeyCode.LeftShift then
				if not self:ShouldStartClient() then return end
				self:Start()
			end
		end)
	)

	table.insert(to_destroy,
		UserInputService.InputEnded:Connect(function(i, p)
			if p then return end if i.KeyCode == Enum.KeyCode.LeftShift then
				self:Stop()
			end
		end)
	)
	
	self.Destroyed:Once(function()
		for _, a: RBXScriptConnection in ipairs(to_destroy) do
			a:Disconnect()
		end
	end)
end

--//Returner

return Sprint