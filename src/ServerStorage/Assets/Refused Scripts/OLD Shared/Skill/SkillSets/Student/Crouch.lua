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
local AffectedHumanoidProps = require(ReplicatedStorage.Shared.Skill.StatusEffects.AffectedHumanoidProps)

--//Variables

local Crouch = WCS.RegisterHoldableSkill("Crouch", BaseHoldableSkill)

--//Methods

-- TODO: should start when HIDE is not active
function Crouch:ShouldStart()
	return not self.Character:GetSkillFromString('Hide'):GetState().IsActive
end

function Crouch:OnStartServer()
	-- stopping other states if active
	for _, Skill in ipairs(self.Character:GetAllActiveSkills()) do
		if Skill.Name == 'Sprint' or Skill.Name == 'Taunt' then
			if Skill:GetState().IsActive then Skill:Stop() end
		end
	end
end

function Crouch:OnStartClient()
	self.Status:Start()
	local Animator = self.Component.Animator
	local Humanoid: Humanoid = self.Character.Instance.Humanoid
	
	local IdlingTrack: AnimationTrack = Animator.Animations.CrouchIdling.Track
	local MovementTrack: AnimationTrack = Animator.Animations.CrouchMovement.Track
	IdlingTrack:Play(.3)
	
	self.Janitor:Add(Humanoid.Changed:Connect(function(property: string)
		if property == 'MoveDirection' then
			local IsMoving = Humanoid.MoveDirection.Magnitude > 0
			
			if IsMoving then
				if MovementTrack.IsPlaying then return end
				MovementTrack:Play(.3)
			else
				MovementTrack:Stop(.3)
			end
		end
	end))
end

function Crouch:OnEndClient()
	local Animator = self.Component.Animator
	local IdlingTrack: AnimationTrack = Animator.Animations.CrouchIdling.Track
	local MovementTrack: AnimationTrack = Animator.Animations.CrouchMovement.Track
	
	MovementTrack:Stop(.3)
	IdlingTrack:Stop(.3)
	self.Status:Stop()
end

function Crouch:OnEndServer()
	self:ApplyCooldown(self.Data.Cooldown)
end

function Crouch:OnConstruct()
	self.Data = {
		Name = 'Crouch',
		Visible = false,
		Cooldown = .3,
		Description = '...',
		DisplayOrder = 0,
	}
end

function Crouch:OnConstructServer()
	self:SetMaxHoldTime(nil)
	self.CheckOthersActive = false
	self.MutualExclusives = { Stun, Downed }
end

function Crouch:OnConstructClient() 
	local Character = shared.Client.Player.Character

	--self.AnimationTrack = Character.Animator.Animations.Crouch.Track
	self.Component = Character
	self.Status = AffectedHumanoidProps.new(self.Character, {WalkSpeed = {-7, "Increment"}})
	self.Status.DestroyOnEnd = false
	
	local to_destroy = {}
	
	table.insert(to_destroy,
		UserInputService.InputBegan:Connect(function(i, p)
			if p then return end
			if i.KeyCode == Enum.KeyCode.LeftControl then
				if self:GetState().IsActive then
					self:Stop()
				elseif self:ShouldStartClient() then
					self:Start()
				end
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

return Crouch