--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseThrowable = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem.BaseThrowable)
local BaseHoldableSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseHoldableSkill)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

--//Variables

local Aim = WCS.RegisterHoldableSkill("Aim", BaseHoldableSkill)

--//Types

export type Skill = BaseHoldableSkill.BaseHoldableSkill & {
	SpeedModifier: ModifiedSpeedStatus.Status,
}

--//Methods

function Aim.ShouldStart(self: Skill)
	local ContextPlayerRelated =
		(RunService:IsServer() and self.Related.PlayerComponent) or
		(RunService:IsClient() and self.Related.PlayerController)
	
	if ContextPlayerRelated:GetRoleConfig().HasInventory then
		
		local Inventory
		
		-- getting inventory component reference both client/server
		if RunService:IsServer() then

			Inventory = ContextPlayerRelated.InventoryComponent

		elseif RunService:IsClient() then

			Inventory = ComponentsManager.Get(self.Player.Backpack, "ClientInventoryComponent")
		end
		
		if not Inventory then
			return false
		end
		
		local Item
		
		if RunService:IsServer() then
			
			Item = Inventory:GetEquippedItem()
			
		elseif RunService:IsClient() then
			
			Item = Inventory:GetEquippedItemComponent()
		end
		
		-- if item is not throwable or not item
		if not Item or not Classes.InstanceOf(Item, BaseThrowable) then
			return false
		end
		
		-- has no skills which requires aiming
	elseif not WCSUtility.HasSkillsWithName(self.Character, {"Harpoon"}) then
		return false
	end
	
	return BaseHoldableSkill.ShouldStart(self)
end

function Aim.OnStartClient(self: Skill)
	self.SpeedModifier:Start()
end

function Aim.OnEndClient(self: Skill)
	self.SpeedModifier:Stop()
end

function Aim.AssumeStart(self: Skill)
	self.Janitor:Add(
		AnimationUtility.QuickPlay(
			self.Character.Humanoid,
			self.FromRoleData.Animations.Start,
			{
				Looped = false,
				Priority = Enum.AnimationPriority.Movement,
			}
		),
		
		"Stop"
	)
	
	local IdleTrack = AnimationUtility.QuickPlay(
		self.Character.Humanoid,
		self.FromRoleData.Animations.Idle,
		{
			Looped = true,
			Priority = Enum.AnimationPriority.Movement,
		}
	)
	
	self.Janitor:Add(function()
		IdleTrack:Stop(0.5)
	end)
end

function Aim.OnConstructClient(self: Skill)
	self.SpeedModifier = self.GenericJanitor:Add(
		ModifiedSpeedStatus.new(
			self.Character,
			"Multiply",
			0.5,
			{
				Priority = 10,
				FadeInTime = 0,
				FadeOutTime = 0,
			}
		),
		
		"Destroy"
	)

	self.SpeedModifier.DestroyOnFadeOut = false
end

function Aim.OnConstruct(self: Skill)
	BaseHoldableSkill.OnConstruct(self)

	self.CheckClientState = true
	self.CheckOthersActive = false
	
	self.ExclusivesSkillNames = {
		"Harpoon", "Sprint"
	}
	
	self.ExclusivesStatusNames = {
		-- Generic statuses
		"Downed", "Hidden", "Stunned", "Handled", "Physics", "HarpoonPierced",
		-- Speed modifiers
		--"AttackSlowed", "FallDamageSlowed",
	}
end

--//Returner

return Aim