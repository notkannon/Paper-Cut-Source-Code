--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)
local ModifiedStaminaGainStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedStaminaGain)
local ThavelComboHitEffect = require(ReplicatedStorage.Shared.Effects.Specific.Role.MissThavel.ThavelComboHit)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseComboPassive = require(ReplicatedStorage.Shared.Combat.Passives.Abstract.BaseCombo)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)

local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)

--//Variables

local ProgressivePunishmentPassive = BaseComponent.CreateComponent("ProgressivePunishmentPassive", {

	isAbstract = false,
	
}, BaseComboPassive) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseComboPassive.MyImpl)),

	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component, enabled: boolean?) -> (),
	OnConstructServer: (self: Component) -> (),
}

export type Fields = {
	
	LastHitHumanoid: Humanoid?,

	_InternalHitListener: SharedComponent.ServerToClient,
	
} & BaseComboPassive.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ProgressivePunishmentPassive", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "ProgressivePunishmentPassive", PlayerTypes.Character>

--//Methods

function ProgressivePunishmentPassive.IncreaseCombo(self: Component)
	
	local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)
	
	-- idk why there wasn't a check for this -Provitia
	if self:IsMaxCombo() then
		self:ResetCombo()
		ProxyService:AddProxy("ThavelProgressivePunishmentMax"):Fire(self.Player)
		return
	end
	
	if self:IsComboActive() then
		ProxyService:AddProxy("ThavelProgressivePunishmentIncrease"):Fire(self.Player)
	else
		ProxyService:AddProxy("ThavelProgressivePunishmentStart"):Fire(self.Player)
	end
	
	
	BaseComboPassive.IncreaseCombo(self)

	--removing speed modifier
	self.Janitor:Remove("SpeedModifier")

	local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Instance)

	--speed handling
	local SpeedModifier = self.Janitor:Add(

		ModifiedSpeedStatus.new(

			WCSCharacter,
			"Increment",

			self:GetConfig().ProgressiveWalkSpeedIncrement * self.Amount + self:GetConfig().BaseWalkSpeedIncrement,

			{
				Priority = 5,
				FadeInTime = 1,
				FadeOutTime = 2,
				Style = Enum.EasingStyle.Cubic,
				Tag = "ProgressivePunishment"
			}
		),

		"End",
		"SpeedModifier"

	) :: ModifiedSpeedStatus.Status

	SpeedModifier.DestroyOnFadeOut = true
	SpeedModifier.DestroyOnEnd = false
	SpeedModifier:Start()
end

function ProgressivePunishmentPassive.ResetCombo(self: Component)

	--cooldown stuff
	if self:IsMaxCombo() then

		local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Instance)

		WCSUtility.ApplyGlobalCooldown(WCSCharacter, 3, {
			
			Mode = "Include",
			SkillNames = { "ThavelAttack", "Dash", "Sprint" },
			EndActiveSkills = true,
			OverrideCooldowned = false,
		})
	end

	--reset combo internally
	BaseComboPassive.ResetCombo(self)

	self.Janitor:Remove("SpeedModifier")
	self.LastHitHumanoid = nil
end

function ProgressivePunishmentPassive.OnHit(self: Component, target: Player)

	if RunService:IsServer() then

		local Humanoid = target.Character and target.Character:FindFirstChildWhichIsA("Humanoid")

		--skip if we hit same player, but not increase it
		if not target
			or not Humanoid
			or Humanoid == self.LastHitHumanoid then
			
			-- наказание за туннель
			local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Instance)
			local PunishmentDuration = self:GetConfig().TunnelingPunishmentDuration
			ModifiedStaminaGainStatus.new(WCSCharacter, "Multiply", 0, {Tag = "TunnelingStaminaGainBlocked"}):Start(PunishmentDuration)
			ModifiedSpeedStatus.new(WCSCharacter, "Multiply", 0.5, {Tag = "TunnelingSlowed"}):Start(PunishmentDuration)
			
			return
		end


		--playing effect on player hit locally for role owner
		ThavelComboHitEffect.new({ target.Character }, self:GetConfig().MaxHighlightDistanceOnHit):Start({ self.Player })

		self.LastHitHumanoid = Humanoid
		self._InternalHitListener.Fire(self.Player, target)

		self:IncreaseCombo()

	else

		local Stamina = ComponentsManager.Get(self.Instance, "Stamina")

		if not Stamina then
			return
		end

		--incrementing stamina on susccess hit
		Stamina:Increment(self:GetConfig().StaminaIncrement)
	end
end

function ProgressivePunishmentPassive.OnConstructClient(self: Component)
	BaseComboPassive.OnConstructClient(self)

	self.Janitor:Add(self._InternalHitListener.On(function(...)
		self:OnHit(...)
	end))
end

function ProgressivePunishmentPassive.OnConstruct(self: Component)
	BaseComboPassive.OnConstruct(self)

	self.LastHitHumanoid = nil

	self._InternalHitListener = self:CreateEvent(
		"HitReplicator",
		"Reliable",

		function(...) return typeof(...) == "Instance" end
	)
end

--//Returner

return ProgressivePunishmentPassive