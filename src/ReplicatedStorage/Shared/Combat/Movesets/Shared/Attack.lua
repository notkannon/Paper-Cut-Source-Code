--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseSkill)
local RaycastHitbox = require(ReplicatedStorage.Packages.RaycastHitbox)
local ThrowablesService = require(ReplicatedStorage.Shared.Services.ThrowablesService)

local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)
local ModifiedStaminaGainStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedStaminaGain)
local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)

local Utility = require(ReplicatedStorage.Shared.Utility)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local HitboxUtility = require(ReplicatedStorage.Shared.Utility.HitboxUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

--//Variables

local Attack = WCS.RegisterSkill("Attack", BaseSkill)

--//Types

type Skill = BaseSkill.BaseSkill

--//Methods

function Attack.OnCharacterComponentHitServer(self: Skill, characterComponent: {any})
	
	if characterComponent.WCSCharacter:TakeDamage(self:CreateDamageContainer(self.FromRoleData.Damage)).Damage <= 0 then
		return
	end

	ModifiedSpeedStatus.new(self.Character, "Multiply", 0.5, {
		
		Tag = "AttackSlowed",
		
	}):Start(1.5)
	
	WCSUtility.ApplyGlobalCooldown(self.Character, 2, {
		Mode = "Exclude",
		SkillNames = { "Sprint" },
		EndActiveSkills = true,
		OverrideCooldowned = false,
	})
	
	return true
end

function Attack._HandleHitboxBasepartHit(self: Skill, hit: BasePart)
	
	if not self.CheckHitActive then
		return
	end
	
	--doors only for a while
	local Component = ComponentsUtility.GetComponentFromDoor(
		hit:FindFirstAncestorWhichIsA("Model")
	)

	if not Component or table.find(self.RegisteredHitComponents, Component) then
		return
	end

	table.insert(self.RegisteredHitComponents, Component)
	
	--door handling
	if not Component:IsProtected() and not Component:IsOpened() then
		
		--dealing 50 damage, opening the door
		Component:TakeDamage(self:CreateDamageContainer(50))
		Component:SetOpened(true)
		Component:OnOpen(self.Player)
		
		-- slowing down the culprit, and halving stamina regen
		local PenaltyDuration = 2 -- TODO: remove hardcode
		
		local ProxyService = Classes.GetSingleton("ProxyService")
		ProxyService:AddProxy("DoorDamaged"):Fire(self.Player, Component)
		
		ModifiedSpeedStatus.new(self.Character, "Multiply", 0.5, {Tag = "DoorDamageSlowed", FadeOutTime = 0.5, FadeInTime = 0.5, Priority = 6}):Start(PenaltyDuration)
		ModifiedStaminaGainStatus.new(self.Character, "Multiply", 0.5, {Tag = "DoorDamageStaminaGainSlowed", Priority = 6}):Start(PenaltyDuration)
		
	elseif Component:IsProtected() then
		
		--TODO
		--damaging locked door.. Probably.
		--We could make something like.. DoorProtector class, so it will have method like :TakeDamage(amount, player)
		Component:TakeDamage(self:CreateDamageContainer(self.FromRoleData.Damage * 1.5))
	end
end

function Attack.OnStartServer(self: Skill)
	
	local Config = self.FromRoleData
	local Character = self.Character.Instance :: PlayerTypes.Character
	local HittedBaseparts = {} :: { BasePart? }
	local HittedCharacters = { Character }
	
	--removing old things
	self.GenericJanitor:RemoveList(
		"HitListener",
		"Hitbox"
	)
	
	--animation playback
	local AnimationTrack = AnimationUtility.QuickPlay(
		
		self.Character.Humanoid.Animator,
		
		Config.Animations[math.random(1, #Config.Animations)], {
			Looped = false,
			Priority = Enum.AnimationPriority.Action3,
			PlaybackOptions = {
				Weight = 1000
			}
		}
	)
	
	--removal hitbox detection
	--self.GenericJanitor:Add(task.delay(0.3, function()
		
	--	self.CheckHitActive = false
	--	self.GenericJanitor:Remove("Hitbox")
	--	table.clear(self.RegisteredHitComponents)
	--end))
	
	--timing
	self.GenericJanitor:Add(
		
		AnimationTrack:GetMarkerReachedSignal("HitStart"):Once(function()
			
			self.CheckHitActive = true
			
			SoundUtility.CreateTemporarySound(
				SoundUtility.GetRandomSoundFromDirectory(SoundUtility.Sounds.Players.Attacks.Attack)
			).Parent = self.Character.Instance.HumanoidRootPart
		end),
		
		"Disconnect",
		"HitListener"
	)
	
	self.GenericJanitor:Add(RunService.Heartbeat:Connect(function()
		
		--pass till active
		if not self.CheckHitActive then
			return
		end
		
		local FoundBaseparts = HitboxUtility.GetPartsInHitbox(
			self.Character.Instance.HumanoidRootPart.CFrame,
			Config.Hitbox,
			{
				Mode = Enum.RaycastFilterType.Exclude,
				Instances = HittedBaseparts,
				OverlapParams = {
					CollisionGroup = "Players"
				},
			}
		)
		
		for _, Basepart: BasePart in ipairs(FoundBaseparts) do
			table.insert(HittedBaseparts, Basepart)
			self:_HandleHitboxBasepartHit(Basepart)
		end
		
		local FoundComponents = select(2, HitboxUtility.RequestCharactersInHitbox(
			self.Player, Config.Hitbox, nil, nil,
			{
				Mode = Enum.RaycastFilterType.Exclude,
				Instances = HittedCharacters,
				ComponentMode = "Exclude",
				StatusesNames = {"Invincible", "Hidden", "Downed", "Handled"},
			}	
		))
		
		for _, FoundComponent in ipairs(FoundComponents) do
			
			if #HittedCharacters > 1 then
				continue
			end
			
			table.insert(HittedCharacters, FoundComponent.Instance)
			
			local PlayerComponent = ComponentsUtility.GetPlayerComponentFromCharacter(FoundComponent.Instance)
			--no friendly fire :sob:
			if not PlayerComponent:IsStudent() then
				continue
			end
			
			--detecting success damage & damaging
			if self:OnCharacterComponentHitServer(FoundComponent) then
				ProxyService:AddProxy("TeacherAttack"):Fire(self.Player)
				break
			end
			
			self.GenericJanitor:Remove("Hitbox")
		end
		
	end), nil, "Hitbox")

	AnimationTrack:GetMarkerReachedSignal("HitEnd"):Once(function()
		
		self.CheckHitActive = false
		self.GenericJanitor:Remove("Hitbox")
		table.clear(self.RegisteredHitComponents)
	end)
	
	--cooldown if not cooldowned
	if not self:GetState().Debounce then
		self:ApplyCooldown(self.FromRoleData.Cooldown)
	end
end

function Attack.OnStartClient(self: Skill)
	Classes.GetSingleton("CameraController"):QuickShake(0.5, 2)
end

function Attack.OnConstructServer(self: Skill)
	self.CheckHitActive = false
	self.RegisteredHitComponents = {}
end

function Attack.OnConstruct(self: Skill)
	BaseSkill.OnConstruct(self)
	
	self.CheckClientState = true
	self.CheckOthersActive = false

	self.ExclusivesSkillNames = {
		"Harpoon", "Shockwave", "Dash"
	}
	
	self.ExclusivesStatusNames = {
		-- Generic statuses
		"Aiming", "Stunned", "Physics", "Handled",
		-- Speed modifiers
		{"ModifiedSpeed", {"AttackSlowed", "Freezed"}}
	}
end

--//Returner

return Attack