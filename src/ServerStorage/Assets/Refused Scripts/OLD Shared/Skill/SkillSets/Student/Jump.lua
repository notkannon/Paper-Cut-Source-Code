--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService("RunService")

--//Imports

local WCS = require(ReplicatedStorage.Package.wcs)
local BaseSkill = require(script.Parent.Parent.BaseSkill)
local PlayerComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent)

local Stun = require(ReplicatedStorage.Shared.Skill.StatusEffects.Stun)
local Downed = require(ReplicatedStorage.Shared.Skill.StatusEffects.Downed)
local Injured = require(ReplicatedStorage.Shared.Skill.StatusEffects.Injured)
local AffectedHumanoidProps = require(ReplicatedStorage.Shared.Skill.StatusEffects.AffectedHumanoidProps)

--//Variables

local Jump = WCS.RegisterSkill("Jump", BaseSkill)

--//Method

function Jump:ShouldStart()
	return not self.Character:GetSkillFromString('Hide'):GetState().IsActive
end

function Jump:OnStartClient()
	self.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end


function Jump:OnEndServer()
	self:ApplyCooldown(1)
end


function Jump:ShouldStartClient()
	return
		os.clock() - self.LastJumpTime > self.Data.Cooldown and
		self.Character.Instance.Humanoid.FloorMaterial ~= Enum.Material.Air
end


function Jump:OnConstruct()
	self.Data = {
		Name = 'Jump',
		Visible = false,
		Cooldown = 1,
		Description = '...',
		DisplayOrder = 0,
	}
end

-- make statuses which will block skill to start
function Jump:OnConstructServer()
	self.MutualExclusives = { Stun, Hidden, Downed, Injured }
end


function Jump:OnConstructClient()
	local Character = shared.Client.Player.Character

	self.LastJumpTime = os.clock()
	self.Component = Character
	
	UserInputService.JumpRequest:Connect(function(i, p)
		if p then return end
		if self:ShouldStartClient() then
			self.LastJumpTime = os.clock()
			self:Start()
		end
	end)
end

--//Returner

return Jump