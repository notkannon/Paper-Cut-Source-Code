--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

--//Variables

local Aiming = WCS.RegisterStatusEffect("Aiming", BaseStatusEffect)

--//Methods

function Aiming.OnStartClient(self: BaseStatusEffect.BaseStatusEffect)
	
	self.SpeedModifier:Start()
	
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

function Aiming.OnEndClient(self: BaseStatusEffect.BaseStatusEffect)
	self.SpeedModifier:Stop()
end

function Aiming.OnConstructClient(self: BaseStatusEffect.BaseStatusEffect)
	self.DestroyOnEnd = false

	self.SpeedModifier = self.GenericJanitor:Add(
		ModifiedSpeedStatus.new(
			self.Character,
			"Multiply",
			0.5,
			{
				Priority = 10,
				FadeInTime = 0,
				FadeOutTime = 0,
				Tag = "Aiming",
			}
		),

		"Destroy"
	)

	self.SpeedModifier.DestroyOnFadeOut = false
	
	self.ExclusivesSkillNames = {
		"Harpoon", "Sprint"
	}

	self.ExclusivesStatusNames = {
		-- Generic statuses
		"Downed", "Hidden", "Stunned", "Handled", "Physics", "HarpoonPierced",
		-- Speed modifiers
		{"ModifiedSpeed", {"AttackSlowed", "FallDamageSlowed"}},
	}
end

--//Returner

return Aiming