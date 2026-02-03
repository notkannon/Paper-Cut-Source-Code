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
local HitboxUtility = require(ReplicatedStorage.Shared.Utility.HitboxUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local MatchService = RunService:IsServer() and require(ServerScriptService.Server.Services.MatchService) or nil
local PlayerService = RunService:IsServer() and require(ServerScriptService.Server.Services.PlayerService) or nil

local StunnedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Stunned)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

--//Variables

local Swing = WCS.RegisterSkill("Swing", BaseHoldableSkill)

--//Types

export type Skill = BaseSkill.BaseSkill

--//Methods

function Swing.OnStartServer(self: Skill)

	--being stopped <-- or exstremely slowed
	--can be damaged during swinging

	local FilteredCharacterInstances = { self.Character.Instance }
	local Visuals = self.FromRoleData.Visuals :: {
		Gear: BasePart,
		Animation: Animation,
	}

	self.Janitor:Add(ModifiedSpeedStatus.new(self.Character, "Multiply", self.FromRoleData.SpeedModifier, {

		Style = Enum.EasingStyle.Cubic,
		Priority = 11,
		FadeInTime = 0.5,
		FadeOutTime = 2,
		Tag = "Swing",

	})):Start()

	--animation related
	
	--gear handling
	local Gear = self.Janitor:Add(self.FromRoleData.Visuals.Gear:Clone()) :: BasePart
	local Grip = Gear:FindFirstChildWhichIsA("Motor6D")
	
	Gear.Parent = self.Character.Instance
	Grip.Part0 = Gear
	Grip.Part1 = self.Character.Instance:FindFirstChild("RightHand")
	Grip.Parent = Grip.Part1
	
	print(Grip.Name, Grip.Parent.Name, Gear.Name)
	
	--animation playback
	local AnimationTrack = AnimationUtility.QuickPlay(
		
		self.Character.Humanoid,
		Visuals.Animation, {
			
			Looped = false,
			Priority = Enum.AnimationPriority.Action4,
		}
	)
	
	--sounds
	
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Players.Skills.Swing.Start
	).Parent = self.Character.Humanoid.RootPart
	
	--connections
	
	local Registered = false

	--listen for hit start event (can be not reacher if ability cancelled)
	self.Janitor:Add(AnimationTrack
		:GetMarkerReachedSignal("Hitbox")
		:Connect(function()
			
			--no double hitbox tracking!
			if self.Janitor:Get("Hitbox") then
				return
			end
			
			--swing sound playback
			SoundUtility.CreateTemporarySound(
				SoundUtility.Sounds.Players.Skills.Swing.Swing
			).Parent = self.Character.Humanoid.RootPart
			
			--hittbox tracking
			self.Janitor:Add(RunService.Heartbeat:Connect(function()
				
				if Registered then
					return
				end
				
				--hitbox making
				local Characters = HitboxUtility.RequestCharactersInHitbox(

					self.Player,
					self.FromRoleData.Hitbox,
					nil,
					nil, {
						Mode = Enum.RaycastFilterType.Exclude,
						Instances = FilteredCharacterInstances,
						ComponentMode = "Exclude",
						StatusesNames = {"Invincible", "Hidden", "Downed", "Handled"},
					}
				)
				
				--after waiting client hitbox responce
				if Registered then
					return
				end

				for _, Character in ipairs(Characters) do

					local Player = Players:GetPlayerFromCharacter(Character)
					local WCSCharacter = WCS.Character.GetCharacterFromInstance(Character)

					--no friendly fire :sob:
					if not WCSCharacter
						or not Player
						or not RolesManager:IsPlayerKiller(Player) then
						
						continue
					end
					
					--mark as registered
					Registered = true
					
					self.Janitor:Remove("Hitbox")
					
					--stunning victim
					StunnedStatus.new(WCSCharacter)
						:Start(self.FromRoleData.StunDuration)
					
					--boosting our hero 🥰
					ModifiedSpeedStatus.new(self.Character, "Multiply", self.FromRoleData.BoostAfterHit, {

						Style = Enum.EasingStyle.Cubic,
						Priority = 10,
						FadeInTime = 0,
						FadeOutTime = 2,
						Tag = "SwingBoosted",

					}):Start(self.FromRoleData.BoostAfterHitDuration)

					--detecting & damaging
					
					SoundUtility.CreateTemporarySound(
						SoundUtility.Sounds.Players.Skills.Swing.Hit
					).Parent = self.Character.Humanoid.RootPart
					
					return
				end

			end), nil, "Hitbox")
		end)
	)
	
	
	--end skill after track length
	local Duration = AnimationUtility.PromiseDuration(AnimationTrack, 3, true):expect()
	self.Janitor:Add(task.delay(Duration, self.End, self))
end

function Swing.OnEndServer(self: Skill)
	self:ApplyCooldown(self.FromRoleData.Cooldown)
end

function Swing.ShouldStart(self: Skill)
	return BaseHoldableSkill.ShouldStart(self)
end

function Swing.OnConstruct(self: Skill)
	BaseHoldableSkill.OnConstruct(self)

	--duration should cover animation length
	self:SetMaxHoldTime(7)

	self.CheckClientState = true
	self.CheckOthersActive = false

	self.ExclusivesSkillNames = {}

	self.ExclusivesStatusNames = {
		-- Generic statuses
		"Downed", "Hidden", "Stunned", "Physics", "HarpoonPierced", "Handled", "HiddenComing", "HiddenLeaving", "ObjectiveSolving", 
		"MarkedForDeath", --in finishers (can be damaged without stopping ability but not on low health)
		-- Speed modifiers
		{"ModifiedSpeed", {"FallDamageSlowed", "Freezed"}}
	}
end

--//Returner

return Swing