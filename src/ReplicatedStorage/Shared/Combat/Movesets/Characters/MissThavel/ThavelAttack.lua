--//Services

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCS = require(ReplicatedStorage.Packages.WCS)
local AttackSkill = require(ReplicatedStorage.Shared.Combat.Movesets.Shared.Attack)

local Utility = require(ReplicatedStorage.Shared.Utility)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

--//Variables

local ThavelAttack = WCS.RegisterSkill("ThavelAttack", AttackSkill)

--//Types

type Skill = WCS.Skill

--//Methods

function ThavelAttack.OnCharacterComponentHitServer(self: Skill, characterComponent: {any})
	
	local Player = characterComponent.Player
	local Damage = self.FromRoleData.Damage
	local ProgressivePunishment = ComponentsManager.Get(self.Character.Instance, "ProgressivePunishmentPassive")
	local PassiveConfig = ProgressivePunishment:GetConfig()
	
	-- setting min damage if targetted exact player
	if ProgressivePunishment.LastHitHumanoid == characterComponent.Humanoid then

		Damage = self.FromRoleData.MinDamage

	elseif ProgressivePunishment:IsMaxCombo() then

		Damage = self.FromRoleData.MaxDamage
	end
	
	-- unsuccess attack (skipping combo if dealt damage is 0)
	if characterComponent.WCSCharacter:TakeDamage(self:CreateDamageContainer(Damage)).Damage == 0 then
		return false
	end
	
	-- handling active combo (ignores inactive combo cuz it starts via dash-damage)
	if ProgressivePunishment:IsComboActive() then
		ProgressivePunishment:OnHit(Player)
	end
	
	--applying calculated cooldown after hit
	WCSUtility.ApplyGlobalCooldown(self.Character,
		self.FromRoleData.MinCooldown + (PassiveConfig.Max - ProgressivePunishment.Amount) / PassiveConfig.Max,
		{
			Mode = "Exclude",
			SkillNames = {"Sprint"},
			EndActiveSkills = true,
			OverrideCooldowned = false
		}
	)
	
	ModifiedSpeedStatus.new(self.Character, "Multiply", 0.5, {

		Tag = "AttackSlowed",

	}):Start(1.5)
	
	return true
end

--//Returner

return ThavelAttack