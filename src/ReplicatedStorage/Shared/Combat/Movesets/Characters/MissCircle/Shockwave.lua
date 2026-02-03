--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local BaseHoldableSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseHoldableSkill)

local StunnedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Stunned)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

local ShockwaveEffect = require(ReplicatedStorage.Shared.Effects.Specific.Role.MissCircle.Shockwave)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local HitboxUtility = require(ReplicatedStorage.Shared.Utility.HitboxUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)
local MatchService = RunService:IsServer() and require(ServerScriptService.Server.Services.MatchService)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

--//Constants

local GROUNDED_CHECK_PARAMS = RaycastParams.new()
GROUNDED_CHECK_PARAMS.FilterDescendantsInstances = {workspace.Characters, workspace.Temp}
GROUNDED_CHECK_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
GROUNDED_CHECK_PARAMS.RespectCanCollide = true

--//Variables

local SkillSounds = SoundUtility.Sounds.Players.Skills.Shockwave
local Shockwave = WCS.RegisterHoldableSkill("Shockwave", BaseHoldableSkill)

--//Types

export type Skill = BaseHoldableSkill.BaseHoldableSkill

--//Methods

function Shockwave.OnStartServer(self: Skill)
	
	local HumanoidRootPart = self.Character.Humanoid.RootPart :: BasePart
	HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	
	local Effect = self.Janitor:Add(ShockwaveEffect.new(self.Character.Instance), "Destroy")
	Effect:Start(Players:GetPlayers())
	
	local Sound = self.Janitor:Add(SoundUtility.CreateTemporarySound(SkillSounds.Charge), nil, "ChargeSound")
	Sound.Parent = HumanoidRootPart
	
	--speed sets to 0 during skill usage
	local SpeedModifier = ModifiedSpeedStatus.new(self.Character, "Set", 0, {
		Style = Enum.EasingStyle.Cubic,
		Priority = 10,
		FadeInTime = 0,
		FadeOutTime = 1,
		Tag = "ShockwaveCharging",
	})
	
	SpeedModifier.DestroyOnEnd = false
	SpeedModifier:Start()
	
	local AnimationTrack = AnimationUtility.QuickPlay(
		self.Character.Humanoid,
		self.FromRoleData.Animation,
		{
			Looped = false,
			Priority = Enum.AnimationPriority.Movement,
		}
	)
	
	self.Janitor:Add(SpeedModifier, "Destroy")
	
	self.Janitor:Add(function()
		
		if not self.Character.Instance then
			return
		end
		
		AnimationTrack:Stop(0.5)
	end)
	
	self.Janitor:Add(AnimationTrack:GetMarkerReachedSignal("Impact"):Once(function()
		self.Janitor:Remove("ChargeSound")
		
		--added here cuz circle did impact successfully, and she will be boosted after this
		self.Janitor:Add(function()
			
			--circle boosting
			local SpeedBoost = ModifiedSpeedStatus.new(self.Character, "Multiply", self.FromRoleData.BoostMultiplier, {
				Style = Enum.EasingStyle.Cubic,
				Priority = 7,
				FadeInTime = 0,
				FadeOutTime = self.FromRoleData.BoostFadeOutTIme,
				Tag = "ShockwaveBoost",
			})
			
			SpeedBoost:Start(self.FromRoleData.BoostDuration)

			self.GenericJanitor:Add(SpeedBoost)
		end)
		
		--grounded check
		local Result = workspace:Raycast(HumanoidRootPart.Position, Vector3.new(0, -100, 0), GROUNDED_CHECK_PARAMS)
		
		if not Result then
			return
		end
		
		Effect:Impact(CFrame.lookAlong(Result.Position, Vector3.new(0, 1, 0)))
		
		SoundUtility.CreateTemporarySoundAtPosition(Result.Position, SkillSounds.Drop)
		SoundUtility.CreateTemporarySoundAtPosition(Result.Position, SkillSounds.Explosion)
		SoundUtility.CreateTemporarySoundAtPosition(Result.Position, SkillSounds.Shockwave)
		
		--instance collecting
		local HandledAncestry = {}
		
		local Parts = HitboxUtility.GetPartsInHitbox(HumanoidRootPart.CFrame, self.FromRoleData.Hitbox, {
			
			Mode = Enum.RaycastFilterType.Exclude,
			Instances = { workspace.Characters, workspace.Temp, },
			OverlapParams = { RespectCanCollide = false, },
		})
		
		-- using flags to avoid duplicate calls
		local LK_Flag = false
		local Slowed_Flag = false
		local Closed_Flag = false
		
		for _, Part in ipairs(Parts) do
			
			local Model = Part:FindFirstAncestorWhichIsA("Model")
			
			if Model == workspace or table.find(HandledAncestry, Model) then
				
				--instance has no model in ancestry
				continue
				
			elseif Model:HasTag("Door") then
				
				--handling door component
				local Component = ComponentsManager.GetFirstComponentInstanceOf(Model, "BaseDoor")
				
				if not Component then
					continue
				end
				
				table.insert(HandledAncestry, Model)
				
				-- might reconsider
				--Component:TakeDamage(self:CreateDamageContainer(0))
				--Component:SetOpened(true)
				--Component:OnOpen(self.Player)
				
			elseif Model:HasTag("Vault") then
				
				--handling vault component
				local Component = ComponentsManager.GetFirstComponentInstanceOf(Model, "BaseVault")
				print(Model, Component, Closed_Flag, Component and Component:IsEnabled())
				
				if not Component or not Component:IsEnabled() then
					continue
				end
				
				table.insert(HandledAncestry, Model)
				
				--locking vaults in radius
				Component:SetEnabled(false)
				Closed_Flag = true
			end
		end
		
		--characters detection
		local Characters = select(1, HitboxUtility.RequestCharactersInHitbox(self.Player, self.FromRoleData.Hitbox,	65, nil, {
			ComponentMode = "Exclude",
			StatusesNames = {"Ragdolled", "Invincible", "Downed", "Handled"}
		}))

		for _, Character: PlayerTypes.Character in ipairs(Characters) do
			local AfflictedPlayer = Players:GetPlayerFromCharacter(Character)
			--filtering only Students
			if not RolesManager:IsPlayerStudent(AfflictedPlayer) then
				continue
			end
			
			local WCSCharacter = WCS.Character.GetCharacterFromInstance(Character)
			
			if not WCSCharacter then
				continue
			end
			
			--force remove player from any hideout
			local Hideout = ComponentsUtility.GetHideoutFromCharacter(Character)
			
			if Hideout then
				
				print("KICKING FROM HIDEOUT", Hideout:GetOccupant())
				
				--occupant: nil, force: false, forceAnimation: true
				Hideout:SetOccupant(nil, false, true)
				LK_Flag = true
				
				--player shouldnt get stun after falling out of hideout
				continue
			end
			
			local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
			
			--humanoid state check (if player jumping or FreeFalling then he can dodge attack)
			if table.find({Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Jumping}, Humanoid:GetState()) then
				continue
			end
			
			local BaseSlownessTime = self.FromRoleData.SlownessDuration
			local FadeOutSlownessTime = self.FromRoleData.SlownessFadeOutTime
			
			local Status = ModifiedSpeedStatus.new(WCSCharacter, "Set", 0.45, {
				Style = Enum.EasingStyle.Cubic,
				Priority = 7,
				FadeInTime = 0,
				FadeOutTime = FadeOutSlownessTime,
				Tag = "ShockwaveSlowed"
			})
			
			Slowed_Flag = true
			
			Status:Start(BaseSlownessTime)
			
			--removing slowness on 1st hit with this status
			Status.GenericJanitor:Add(MatchService.PlayerDamaged:Connect(function(player: Player)
				
				print("Damaged with speed modifier")
				
				if player == AfflictedPlayer then
					
					print("Destroying speed modifier")
					Status:Destroy()
				end
			end))
			
			
		end
		
		local ShockwaveLockerKickedProxy = ProxyService:AddProxy("ShockwaveLockerKicked")
		local ShockwaveSlowedProxy = ProxyService:AddProxy("ShockwaveSlowed")
		local ShockwaveClosedProxy = ProxyService:AddProxy("ShockwaveClosed")
		print('flags:', Slowed_Flag, Closed_Flag, LK_Flag)
		if Slowed_Flag then ShockwaveSlowedProxy:Fire(self.Player) end
		if Closed_Flag then ShockwaveClosedProxy:Fire(self.Player) end
		if LK_Flag then ShockwaveLockerKickedProxy:Fire(self.Player) end
	end))
	
	
	
	local Duration = math.max(AnimationUtility.PromiseDuration(AnimationTrack, 2.45, true):expect() - 2.4, 0)
	self.Janitor:Add(task.delay(Duration, self.End, self))
end

function Shockwave.ShouldStart(self: Skill)
	return self.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
end

--function Shockwave.OnStartClient(self: Skill)
--	Classes.GetSingleton("CameraController"):SetActiveCamera("HeadLocked")
--	Classes.GetSingleton("CameraController").Cameras.HeadLocked.IsFlexible = true
--end

--function Shockwave.OnEndClient(self: Skill)
--	Classes.GetSingleton("CameraController"):SetActiveCamera("Default")
--end

function Shockwave.OnEndServer(self: Skill)

	self:ApplyCooldown(self.FromRoleData.Cooldown)
	
	WCSUtility.ApplyGlobalCooldown(self.Character, 1, {
		Mode = "Exclude",
		SkillNames = {self:GetName(), "Sprint"},
		EndActiveSkills = false
	})
end

function Shockwave.OnConstruct(self: Skill)
	BaseHoldableSkill.OnConstruct(self)
	
	self:SetMaxHoldTime(10)
	
	self.CheckClientState = true
	self.CheckOthersActive = false
	self.ExclusivesSkillNames = {"Attack"}
	self.ExclusivesStatusNames = {
		{"ModifiedSpeed", {"Freezed"}}
	}
end

--//Returner

return Shockwave