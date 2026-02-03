--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local HideoutLimitedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Student.HideoutLimited)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

--//Variables

local HideoutPanicking = WCS.RegisterStatusEffect("HideoutPanicking", BaseStatusEffect)

--//Types

export type Status = BaseStatusEffect.BaseStatusEffect & {
	ShouldLeaveOnEnd: boolean
}

--//Methods

function HideoutPanicking.OnConstruct(self: Status)
	BaseStatusEffect.OnConstruct(self)
	
	self.DestroyOnEnd = true
	self.ShouldLeaveOnEnd = true
end

function HideoutPanicking.OnStartServer(self: Status)
	
	local HiddenStatus = WCSUtility.GetAllActiveStatusEffectsFromString(self.Character, "Hidden")[1]
	
	--removing silently
	if not HiddenStatus then
		
		self.ShouldLeaveOnEnd = false
		self:End()
	end
	
	self.StartTime = os.clock()
end

function HideoutPanicking.OnEndServer(self: Status)
	--limiting player from hiding
	task.delay(1, function()
		if WCSUtility.HasActiveStatusEffectsWithNames(self.Character, {"HideoutLimited"}) then
			return
		end
		
		local HideoutLimitedDuration = (os.clock() - self.StartTime) * 2
		local RoleConfig = RolesManager:GetPlayerRoleConfig(self.Player)
		local DurationMultiplier = RoleConfig.CharacterData.UniqueProperties and RoleConfig.CharacterData.UniqueProperties.PanickedDurationMultiplier or 1
		HideoutLimitedDuration *= DurationMultiplier

		HideoutLimitedStatus.new(self.Character):Start(HideoutLimitedDuration)
	end)
	
	
	--getting status
	local HiddenStatus = WCSUtility.GetAllActiveStatusEffectsFromString(self.Character, "Hidden")[1]
	
	if not HiddenStatus then
		return
	end
	
	--getting component from stored instance reference
	local Hideout = ComponentsManager.GetFirstComponentInstanceOf(HiddenStatus.HideoutInstance, "BaseHideout")
	if not Hideout
		or Hideout:GetOccupant() ~= self.Player then
		
		return
	end
	
	
	
	--skip if set to false
	if not self.ShouldLeaveOnEnd then
		return
	end

	--when status ends we shall remove player from hideout
	Hideout:SetOccupant(nil, false, true)
end

--//Returner

return HideoutPanicking