--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)

local WCS = require(ReplicatedStorage.Packages.WCS)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local ServerRemotes = require(ServerScriptService.Server.ServerRemotes)
local ComponentTypes = require(ServerScriptService.Server.Types.ComponentTypes)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local MatchService = require(ServerScriptService.Server.Services.MatchService)
local FinisherHandler = require(ServerScriptService.Server.Classes.FinisherHandler)
local PlayerDamageEffect = require(ReplicatedStorage.Shared.Effects.PlayerDamage)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local InvincibleStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Invincible)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)
local ModifiedDamageTakenStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedDamageTaken)
local ModifiedDamageDealtStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedDamageDealt)

local PatchUp = require(ReplicatedStorage.Shared.Combat.Movesets.Roles.Medic.PatchUp) -- specific

local MAX_BOOST = 1

--//Returner

return {
	
	IsActive = true,
	EventName = "Damage",
	
	Handler = function(self: ComponentTypes.CharacterComponent, container: WCS.DamageContainer)
		local Source = container.Source
		local ResultDamage = container.Damage
		
		--defining damage data from player
		local RoleConfig = RolesManager:GetPlayerRoleConfig(self.Player)
		local ConfigCharacterData = (RoleConfig and RoleConfig.CharacterData) :: { InvincibleDurationAfterDamage: number? }
		local ConfigPassivesData = (RoleConfig and RoleConfig.PassivesData)
		
		local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Instance)
		local ModifiedDamageTakenStatuses = WCSUtility.GetAllActiveStatusEffectsFromString(WCSCharacter, "ModifiedDamageTaken")
		
		ResultDamage = ModifiedDamageTakenStatus.ResolveModifiers(ModifiedDamageTakenStatuses, ResultDamage)
		
		--applying damage multiplier
		ResultDamage *= (ConfigCharacterData and ConfigCharacterData.UniqueProperties and ConfigCharacterData.UniqueProperties.DamageTakenMultiplier or 1)
		
		print(`Intended damage: { container.Damage } ; result damage: { ResultDamage }`)
		
		if container.Source then
			
			local CharacterDealt = container.Source.Character.Instance :: PlayerTypes.Character
			local ModifiedDamageDealtStatuses = WCSUtility.GetAllActiveStatusEffectsFromString(container.Source.Character, "ModifiedDamageDealt")
			
			ResultDamage = ModifiedDamageDealtStatus.ResolveModifiers(ModifiedDamageDealtStatuses, ResultDamage)
			
			--umhmh.. Should we count modified damage as taken damage to boost player? -- yes
			local BoostMultiplier = 1 + ResultDamage / self.Instance.Humanoid.MaxHealth * MAX_BOOST
			
			local BoostDuration = 3
			
			if ConfigPassivesData.MinOnHitDurationBoost and ConfigPassivesData.MaxOnHitDurationBoost then
				local RemainingHealth = math.clamp(self.Humanoid.Health - ResultDamage, 0, self.Humanoid.MaxHealth - 1)
				local LerpCoefficient = 1 - RemainingHealth / self.Humanoid.MaxHealth
				BoostDuration += ConfigPassivesData.MinOnHitDurationBoost + LerpCoefficient * (ConfigPassivesData.MaxOnHitDurationBoost - ConfigPassivesData.MinOnHitDurationBoost)
			end
			
			print(`Boost duration: { BoostDuration }`)
			
			local AttackBoosted = ModifiedSpeedStatus.new(self.WCSCharacter, "Multiply", BoostMultiplier, {
				Tag = "AttackBoosted",
				Priority = 8,
				FadeOutTime = 3.5,
			})
			
			AttackBoosted:Start(BoostDuration)
			
			local PotentialHealingAct = ComponentsUtility.FindFirstTemporaryComponent(function(name: string, component: ComponentTypes.BaseComponent)
				print(name, component)
				if name ~= "HealingAct" then
					return false
				end
				
				return component.Healer == WCSCharacter.Player or component.Target == WCSCharacter.Player
			end)
			
			if PotentialHealingAct then
				local ProxyService = Classes.GetSingleton("ProxyService")
				ProxyService:AddProxy("HealerDamaged"):Fire(container.Source.Player, WCSCharacter.Player)
			end
		end
		
		local CharacterDealt = Source and Source.Character.Instance :: PlayerTypes.Character
		local RemainingHealth = math.clamp(self.Humanoid.Health - ResultDamage, 0, self.Humanoid.MaxHealth - 1)
		local TempAlive = WCSUtility.GetAllActiveStatusEffectsFromString(self.WCSCharacter, "MarkedForDeath")[1]
		
		--telling this thing to handle damage
		MatchService:_HandleDamageTaken({
			
			origin = CharacterDealt and CharacterDealt.HumanoidRootPart.Position or nil,
			player = self.Player,
			damager = Source and Source.Player or nil,
			damage = container.Damage,
			source = type(Source) == "table" and Source:GetName() or tostring(Source)
			
		})
		
		--invincible IFrames applies
		if ConfigCharacterData and ConfigCharacterData.InvincibleDurationAfterDamage then
			
			self.Janitor:Add(InvincibleStatus.new(self.WCSCharacter))
				:Start(ConfigCharacterData.InvincibleDurationAfterDamage)
		end
		
		--keeps player alive until MarkedForDeath removed (useful in cutscenes like finishers)
		if TempAlive and RemainingHealth == 0 then -- this clause is temporarily removed
			
			RemainingHealth = 1
			TempAlive.IsDead = true
			
		elseif RemainingHealth == 0 and Source.Player and (Source.Name:match("Attack") or Source.Name == "Dash") then
			
			--finisher initials
			
			--[[FinisherHandler.new(
				Source.Player,
				self.Player
			):Run()]]
			--[[if not self.Janitor:Get("VictimTempAlive") then
				return
			end

			TempAlive.IsDead = true
			TempAlive:Destroy()  -- killing Student]] -- я не проверял что это, и работает ли оно (нургамент ливает постоянг!2гн52г523н5)
			
			--pass setting 0 health
			--return
				
		elseif RemainingHealth > 0 and Source then

			local Amount = self.Humanoid.Health - RemainingHealth
			local Animations = ReplicatedStorage.Assets.Animations.Student.Damage:GetChildren()
			
			AnimationUtility.QuickPlay(self.Humanoid, Animations[math.random(1, #Animations)], {
				Looped = false,
				Priority = Enum.AnimationPriority.Action3,
			})
			
			--TODO: Rework damage effect
			PlayerDamageEffect.new(self.Instance, Amount):Start(Players:GetPlayers())
		end
		
		--applying health
		self.Humanoid.Health = RemainingHealth
	end,
	
} :: ComponentTypes.DamageHandler