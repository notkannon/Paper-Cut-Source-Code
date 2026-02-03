-- TODO: remove Hidden status effect and replace it with holdable skill
--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService("RunService")

--//Imports

local WCS = require(ReplicatedStorage.Package.wcs)
local HideoutService = require(ReplicatedStorage.Shared.HideoutService)
local PlayerComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent)
local BaseHoldableSkill = require(script.Parent.Parent.BaseHoldableSkill)

-- status effects
local Stun = require(ReplicatedStorage.Shared.Skill.StatusEffects.Stun)
local Downed = require(ReplicatedStorage.Shared.Skill.StatusEffects.Downed)
local AffectedHumanoidProps = require(ReplicatedStorage.Shared.Skill.StatusEffects.AffectedHumanoidProps)

--//Variables

local Hide = WCS.RegisterHoldableSkill("Hide", BaseHoldableSkill)

--//Methods

function Hide:ShouldStart()
	return not HideoutService:GetPlayerHideout(self.Player)
end

function Hide:OnStartServer( hideout )
	hideout:HandlePlayerInteraction(self.Player, 'enter')
	
	for _, ActiveSkill in ipairs(self.Character:GetAllActiveSkills()) do
		ActiveSkill:Stop()
	end
	
	-- anchoring current player
	local character: Model = self.Character.Instance
	local HumanoidRootPart: BasePart = character:FindFirstChild('HumanoidRootPart')
	HumanoidRootPart.CFrame = hideout.reference.PrimaryPart.EnterWeld.WorldCFrame
	HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	HumanoidRootPart.Anchored = true
end

function Hide:OnStartClient()
	local hideout = HideoutService:GetPlayerHideout(self.Player)
	self.Hideout = hideout
	self.Status:Start()
	
	-- player animations
	local Animator = self.Component.Animator
	Animator:LoadAnimation(ReplicatedStorage.Assets.Animations.Locker.PlayerIdle)
	Animator:LoadAnimation(ReplicatedStorage.Assets.Animations.Locker.PlayerEnter)
	Animator:LoadAnimation(ReplicatedStorage.Assets.Animations.Locker.PlayerLeave)
	Animator:PlayAnimation(Animator.Animations.PlayerIdle)
	Animator:PlayAnimation(Animator.Animations.PlayerEnter)

	self.Character.Instance.HumanoidRootPart.CFrame = hideout.reference.PrimaryPart.EnterWeld.WorldCFrame
	shared.Client._requirements.CharacterView:SetAutorotateEnabled( false )
	shared.Client._requirements.Camera.Modes.Headlocked:SetActive( true )
	shared.Client._requirements.UI.gameplay_ui:ChangePreset('locker')
	shared.Client._requirements.ClientBackpack:SetEnabled( false )
end
-- TODO: FIX CLIET LEAVES AFTER ENTERING LCOKER!!
function Hide:OnEndClient()
	self.Status:Stop()
	
	self.Character.Instance.HumanoidRootPart.CFrame = self.Hideout.reference.PrimaryPart.LeaveWeld.WorldCFrame
	self.Hideout = nil

	local Animator = self.Component.Animator
	Animator:StopAnimation(Animator.Animations.PlayerIdle)
	Animator:PlayAnimation(Animator.Animations.PlayerLeave)

	task.wait(2.5)
	
	-- default client bring back
	self.Character.Instance.HumanoidRootPart.Anchored = false
	shared.Client._requirements.CharacterView:SetAutorotateEnabled( true )
	shared.Client._requirements.Camera.Modes.Character:SetActive( true )
	shared.Client._requirements.UI.gameplay_ui:ChangePreset('game')
	shared.Client._requirements.ClientBackpack:SetEnabled( true )
end

function Hide:OnEndServer()
	local hideout = HideoutService:GetPlayerHideout(self.Player)
	hideout:HandlePlayerInteraction(self.Player, 'leave')
	
	-- unanchoring previous player
	local character: Model = self.Character.Instance
	local HumanoidRootPart: BasePart = character:FindFirstChild('HumanoidRootPart')
	HumanoidRootPart.CFrame = hideout.reference.PrimaryPart.LeaveWeld.WorldCFrame
	HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	HumanoidRootPart.Anchored = false
	
	self:ApplyCooldown(self.Data.Cooldown)
end

function Hide:OnConstructServer()
	self:SetMaxHoldTime( nil )
	self.CheckOthersActive = false
	self.MutualExclusives = { Stun, Downed }
end

function Hide:OnConstructClient() 
	self.Status = AffectedHumanoidProps.new(self.Character, {
		WalkSpeed = {0, "Set"},
		JumpPower = {0, "Set"}})
	
	self.Status.DestroyOnEnd = false
	self.Component = shared.Client.Player.Character
end

function Hide:OnConstruct()
	self.Data = {
		Name = 'Hide',
		Visible = false,
		Cooldown = 5,
		Description = '...',
		DisplayOrder = 0,
	}
end

--//Returner

return Hide