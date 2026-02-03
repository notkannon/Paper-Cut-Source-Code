--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local BaseHoldableSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseHoldableSkill)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local HealingStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Healing)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local HitboxUtility = require(ReplicatedStorage.Shared.Utility.HitboxUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

local MatchService = RunService:IsServer() and require(ServerScriptService.Server.Services.MatchService) or nil
local PlayerService = RunService:IsServer() and require(ServerScriptService.Server.Services.PlayerService) or nil

--//Variables

local PatchUp = WCS.RegisterSkill("PatchUp", BaseHoldableSkill)

--//Types

export type Skill = BaseSkill.BaseSkill

--//Methods

function PatchUp.GetIntendedTarget(self: Skill)
	local HumanoidRootPart = self.Character.Humanoid.RootPart
	local Characters = HitboxUtility.GetCharactersInHitbox(
		
		HumanoidRootPart.CFrame,
		self.FromRoleData.Hitbox, {
			SkillsNames = {},
			StatusesNames = {},
			ComponentMode = "Exclude",
		}
	)

	--both client/server
	local IsObstacle = HitboxUtility.IsCharacterObstacleInFront(self.Character.Instance, 10)
	if IsObstacle then
		print("Obstacle !!!")
		return
	end
	
	if #Characters == 0 then
		return
	end
	

	for _, Character in ipairs(Characters) do

		local Player = Players:GetPlayerFromCharacter(Character)

		--Students only
		if not Player or not RolesManager:IsPlayerStudent(Player) then
			continue
		end

		--getting target player who will be healed
		if Character.Humanoid.Health <= self.FromRoleData.MinHealthRequired then -- вот тут был знак <
			return Player
		end
	end
end

function PatchUp.OnStartServer(self: Skill)
	
	--getting target player
	local Target = self:GetIntendedTarget() :: Player?
	local IsSelfHeal = Target == self.Player
	local TargetWCSCharacter = WCS.Character.GetCharacterFromInstance(Target.Character)
	
	--😪
	if not Target or not TargetWCSCharacter then
		
		self:End()
		
		return
	end
	
	--statuses (mark both players healed/healing)
	
	if not IsSelfHeal then
		self.Janitor:Add(HealingStatus.new(TargetWCSCharacter)):Start()
	end
	
	self.Janitor:Add(HealingStatus.new(self.Character)):Start()
	
	--instance definitions
	local OwnRoot = self.Character.Humanoid.RootPart :: BasePart
	local TargetRoot = TargetWCSCharacter.Humanoid.RootPart :: BasePart
	local TargetHumanoid = TargetWCSCharacter.Humanoid
	local OwnCharacter = self.Character.Instance :: Model
	local TargetCharacter = TargetWCSCharacter.Instance :: Model
	
	local OwnPosition = OwnRoot.Position
	local TargetPosition = TargetRoot.Position
	
	--rig initials
	local Bandage = self.Janitor:Add(ReplicatedStorage.Assets.Skills.PatchUp.Bandage:Clone())
	local BandagePoint = self.Janitor:Add(ReplicatedStorage.Assets.Skills.PatchUp.BandagePoint:Clone())
	
	Bandage.Parent = OwnCharacter
	BandagePoint.Parent = OwnCharacter
	
	local MotorA = self.Janitor:Add(Instance.new("Motor6D"))
	MotorA.Parent = OwnRoot
	MotorA.Part0 = OwnRoot
	MotorA.Part1 = Bandage
	MotorA.Name = "BandageA"
	
	local MotorB = self.Janitor:Add(Instance.new("Motor6D"))
	MotorB.Parent = OwnRoot
	MotorB.Part0 = OwnRoot
	MotorB.Part1 = BandagePoint
	MotorB.Name = "BandageB"
	
	--connections
	local ProxyService = Classes.GetSingleton("ProxyService")
	
	--cancelling
	
	--any damage
	self.Janitor:Add(MatchService.PlayerDamaged:Connect(function(player)
		
		if player == self.Player
			or player == Target then
			
			ProxyService:AddProxy("HealCanceled"):Fire(self.Player, Target)
			self:End()
		end
	end))
	
	--target related
	if not IsSelfHeal then
		
		--death listening
		self.Janitor:Add(MatchService.PlayerDied:Connect(function(player)
			if player == Target then
				ProxyService:AddProxy("HealCanceled"):Fire(self.Player, Target)
				self:End()
			end
		end))

		--character removal listening (also player leaving)
		self.Janitor:Add(PlayerService.CharacterRemoved:Connect(function(_, player)
			if player == Target then
				ProxyService:AddProxy("HealCanceled"):Fire(self.Player, Target)
				self:End()
			end
		end))
	end

	--force physics lock
	OwnRoot.Anchored = true
	
	--dual pointing
	if not IsSelfHeal then
		
		TargetRoot.Anchored = true
		
		--pointing own character
		OwnCharacter:PivotTo(
			CFrame.lookAt(

				OwnPosition,

				Vector3.new(
					TargetPosition.X,
					OwnPosition.Y,
					TargetPosition.Z
				)
			)
		)
		
		--pointing target character
		TargetCharacter:PivotTo(
			CFrame.lookAt(
				OwnPosition + OwnRoot.CFrame.LookVector,
				OwnPosition
			)
		)
	end
	
	--unanchoring
	self.Janitor:Add(function()
		
		if OwnRoot then
			OwnRoot.Anchored = false
		end
		
		if TargetRoot then
			TargetRoot.Anchored = false
		end
	end)
	
	--animations playback
	
	local TargetIntro
	local MedicIntro = self.Janitor:Add(
		
		AnimationUtility.QuickPlay(
			TargetHumanoid,
			self.FromRoleData.Animations.HealerStart, {
				Looped = false,
				Priority = Enum.AnimationPriority.Action4
			}
		),
		"Stop"
	)
	
	if not IsSelfHeal then
		
		TargetIntro = self.Janitor:Add(
			
			AnimationUtility.QuickPlay(
				TargetHumanoid,
				self.FromRoleData.Animations.TargetStart, {
					Looped = false,
					Priority = Enum.AnimationPriority.Action4
				}
			),
			"Stop"
		)
	end
	
	--Target loop
	if not IsSelfHeal then
		
		self.Janitor:Add(
			AnimationUtility.QuickPlay(
				TargetHumanoid,
				self.FromRoleData.Animations.Target, {
					Looped = true,
					Priority = Enum.AnimationPriority.Action3
				}
			),
			"Stop"
		)
	end
	
	--Own loop
	self.Janitor:Add(
		AnimationUtility.QuickPlay(
			self.Character.Humanoid,
			self.FromRoleData.Animations.Healer, {
				Looped = true,
				Priority = Enum.AnimationPriority.Action3
			}
		),
		"Stop"
	)
	
	-- self-heal balancing
	local MaxHeal = self.FromRoleData.MaxHeal
	local HealPerSecond = self.FromRoleData.HealPerSecond
	
	if IsSelfHeal then
		
		--OwnRoot.Parent.Humanoid.AutoRotate = false
		
		MaxHeal *= self.FromRoleData.SelfHealEfficiency
		HealPerSecond *= self.FromRoleData.SelfHealSpeed
	end
	
	local HealAmount = 0
	local PredictedHeal = math.clamp(TargetHumanoid.MaxHealth - TargetHumanoid.Health, 0, MaxHeal)
	
	--both end component creation
	local HealingActComponentInstance = self.Janitor:Add(Instance.new("Folder"))
	HealingActComponentInstance.Parent = workspace.Temp
	HealingActComponentInstance.Name = "@HealingActTemp"
	
	--creating component
	ComponentsManager.Add(HealingActComponentInstance, "HealingAct", {
		
		Healer = self.Player,
		Target = Target,
		Amount = PredictedHeal,
		
	})
	
	--sounds
	
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Players.Skills.PatchUp.Intro
	).Parent = OwnRoot
	
	--delay before heal
	self.Janitor:Add(task.delay(math.max(MedicIntro.Length, TargetIntro and TargetIntro.Length or 0), function()
		
		--loop sound
		self.Janitor:Add(
			SoundUtility.CreateTemporarySound(
				SoundUtility.Sounds.Players.Skills.PatchUp.Bandaging
			)
		).Parent = OwnRoot
		
		--healing
		self.Janitor:Add(RunService.Heartbeat:Connect(function(deltaTime)

			local HealDelta = HealPerSecond * deltaTime

			HealAmount += HealDelta

			--healed max amount or target is full-health
			if TargetHumanoid.Health == TargetHumanoid.MaxHealth
				or HealAmount > MaxHeal then
				
				local ProxyService = Classes.GetSingleton("ProxyService")
				ProxyService:AddProxy("HealCompleted"):Fire(self.Player, Target)
				
				self.Janitor:Remove("HealingSteps")
				self:End()

				return
			end

			TargetHumanoid.Health += HealDelta

		end), 'Disconnect', "HealingSteps")
	end))
end

function PatchUp.OnEndServer(self: Skill)
	self:ApplyCooldown(self.FromRoleData.Cooldown)
end

function PatchUp.ShouldStart(self: Skill)
	
	local IntendedTarget = self:GetIntendedTarget()
	
	--check if player is being member of HealingAct already
	if RunService:IsServer() and ComponentsManager.GetImpl("HealingAct").GetComponentFromPlayer(IntendedTarget) then
		return false
	end
	
	--we have target and base skill check passed
	return IntendedTarget
		and BaseHoldableSkill.ShouldStart(self) and self.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
end

function PatchUp.OnConstruct(self: Skill)
	BaseHoldableSkill.OnConstruct(self)
	
	self:SetMaxHoldTime(15)

	self.CheckClientState = true
	self.CheckOthersActive = false

	self.ExclusivesSkillNames = {}
	self.ExclusivesStatusNames = {
		-- Generic statuses
		"Aiming", "Downed", "Hidden", "Stunned", "Physics", "HarpoonPierced", "HiddenComing", "HiddenLeaving", "ObjectiveSolving", 
		{"ModifiedSpeed", {"FallDamageSlowed", "Freezed"}}
	}
end

--//Returner

return PatchUp