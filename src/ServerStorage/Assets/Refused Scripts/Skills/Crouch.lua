--[[//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local AffectedHumanoidProps = require(ReplicatedStorage.Shared.Combat.Statuses.AffectedHumanoidProps)
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil
local Hidden = require(ReplicatedStorage.Shared.Combat.Statuses.Hidden)
local PlayerController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.PlayerController) or nil
local Ragdoll = require(ReplicatedStorage.Shared.Combat.Statuses.Ragdoll)
local Stun = require(ReplicatedStorage.Shared.Combat.Statuses.Stunned)
local WCS = require(ReplicatedStorage.Packages.WCS)

--//Variables

local Crouch = WCS.RegisterHoldableSkill("Crouch")

--//Types

export type Skill = WCS.HoldableSkill


--//Methods

function Crouch.AssumeStart(self: Skill)
	local CharacterComponent = PlayerController:GetCharacter()
	assert(CharacterComponent, "CharacterComponent not found.")

	local Config = PlayerController:GetRoleConfig().SkillData.Crouch

	self.IdleTrack = self.Janitor:Add(CharacterComponent.Humanoid.Animator:LoadAnimation(Config.IdleAnimation))
	self.MovementTrack = self.Janitor:Add(CharacterComponent.Humanoid.Animator:LoadAnimation(Config.MovementAnimation))

	self.IdleTrack:Play(0.3)
	self.Status:Start()
	
	print(Config.IdleAnimation.AnimationId)
	print(Config.MovementAnimation.AnimationId)

	self.Janitor:Add(self.Character.Humanoid.Running:Connect(function(speed)
		print(self.Character.Humanoid.WalkSpeed)
		print("MOVED")
		if speed > 0 and not self.MovementTrack.IsPlaying then
			self.MovementTrack:Play(0.3)
			self.IdleTrack:Stop(0.3)
		elseif speed < 1 then
			self.IdleTrack:Play(0.3)
			self.MovementTrack:Stop(0.3)
		end
	end))
end

function Crouch.OnEndServer(self: Skill)
	local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(self.Player :: Player)
	if not PlayerComponent then return end
	--assert(PlayerComponent, "PlayerComponent not found.")


	self:ApplyCooldown(PlayerComponent:GetRoleConfig().SkillData.Crouch.Cooldown)
end

function Crouch.OnEndClient(self: Skill)
	print(self)
	if not (self.IdleTrack or self.MovementTrack) then warn('RETURN') return end
	
	self.IdleTrack:Stop(0.3)
	self.MovementTrack:Stop(0.3)
	
	self.Status:Stop()
end


function Crouch.ShouldStart(self: Skill)
	if self.Character.Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		return false
	end
	
	for _, Skill in ipairs(self.Character:GetAllActiveSkills()) do
		if not table.find({ "Sprint", "Taunt" }, Skill:GetName()) then
			return false
		end
		
		Skill:End()
	end

	return true
end

function Crouch.OnConstruct(self: Skill)
	self:SetMaxHoldTime(nil)
	self.CheckOthersActive = false
	self.CheckClientState = true
	self.MutualExclusives = { Stun, Hidden, Ragdoll }
end

function Crouch.OnConstructClient(self: Skill)
	self.Status = AffectedHumanoidProps.new(self.Character, {
		WalkSpeed = { -7, "Increment" },
		JumpPower = { 0, "Set" },
	})

	self.Status.DestroyOnEnd = false
end

--//Returner

return Crouch
]]

-- IMPORTANT! Removed crouch from release!
return nil