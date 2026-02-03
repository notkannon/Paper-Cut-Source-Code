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

local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)

--//Variables

local BloomieAttack = WCS.RegisterSkill("BloomieAttack", AttackSkill)

--//Types

type Skill = WCS.Skill

--//Methods

function BloomieAttack.OnCharacterComponentHitServer(self: Skill, characterComponent: {any})
	
	local Player = characterComponent.Player
	local SerratedBlade = ComponentsManager.Get(self.Character.Instance, "SerratedBladePassive")
	local Damage = self.FromRoleData.Damage
	
	-- unsuccess attack (skipping combo if dealt damage is 0)
	if characterComponent.WCSCharacter:TakeDamage(self:CreateDamageContainer(Damage)).Damage == 0 then
		return false
	end
	
	SerratedBlade:OnHit(Player)
	
	WCSUtility.ApplyGlobalCooldown(self.Character, 2, {
		Mode = "Exclude",
		SkillNames = { "Sprint" },
		EndActiveSkills = true,
		OverrideCooldowned = false,
	})
	
	ModifiedSpeedStatus.new(self.Character, "Multiply", 0.5, {

		Tag = "AttackSlowed",

	}):Start(1.5)
	
	local ProxyService = Classes.GetSingleton("ProxyService")
	
	if WCSUtility.HasStatusEffectsWithTags(self.Character, 'ModifiedDamageDealt', {"SneakAttacking"}) then
		
		ProxyService:AddProxy("StealthBloomieSneakAttack"):Fire(self.Player, Player)
	end
	
	ProxyService:AddProxy("BleedingInflicted"):Fire(self.Player, Player)
	
	return true
end

--//Returner

return BloomieAttack