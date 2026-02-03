--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local InvincibleStatusEffect = require(ReplicatedStorage.Shared.Combat.Statuses.Invincible)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

--//Constants

local PRIORITY = 4

--//Variables

local Stunned = WCS.RegisterStatusEffect("Stunned", BaseStatusEffect)

--//Types

export type Status = BaseStatusEffect.BaseStatusEffect

--//Methods

function Stunned.OnEndServer(self: Status)
	if not self.Character.Instance then
		return
	end
	
	if not ComponentsManager.Get(self.Player, "PlayerComponent"):IsKiller() then
		return
	end
	
	InvincibleStatusEffect.new(self.Character):Start(8)
end

function Stunned.OnConstructServer(self: Status)
	self.DestroyOnEnd = true
end

function Stunned.OnStartServer(self: Status)
	local Duration = self:GetActiveDuration()
	
	if Duration == 0 then
		Duration = 1
	end
	
	WCSUtility.ApplyGlobalCooldown(self.Character, Duration, {
		EndActiveSkills = true,
		OverrideCooldowned = false,
	})
end

function Stunned.OnConstructClient(self: Status)
	
	local SpeedModifier = ModifiedSpeedStatus.new(self.Character, "Set", 0, {
		Priority = 15,
		Tag = "Stunned",
	})
	
	SpeedModifier.DestroyOnEnd = false
	SpeedModifier.DestroyOnFadeOut = true
	self.SpeedModifier = SpeedModifier
	
	self:SetHumanoidData({
		JumpPower = { 0, "Set" },
		AutoRotate = { false, "Set" },
	}, PRIORITY)
end

function Stunned.OnStartClient(self: Status)
	if not self.FromRoleData then
		return
	end
	
	self.SpeedModifier:Start(self:GetActiveDuration())
	
	local AnimationTrack = AnimationUtility.QuickPlay(self.Character.Humanoid, self.FromRoleData.Animation, {
		Looped = false,
		Priority = Enum.AnimationPriority.Action4,
	})
	
	self.Janitor:Add(function()
		AnimationTrack:Stop(1)
	end)
end

function Stunned.OnConstruct(self: Status)
	BaseStatusEffect.OnConstruct(self)
	
	self.DisplayData = {
		DisplayIcon = "",
		DisplayName = "Stunned",
	}
end

--//Returner

return Stunned