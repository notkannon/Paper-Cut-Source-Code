--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)

--//Constants

local PRIORITY = 2

--//Variables

local Physics = WCS.RegisterStatusEffect("Physics", BaseStatusEffect)

--//Types

export type Status = BaseStatusEffect.BaseStatusEffect

--//Methods

function Physics.OnConstruct(self: Status)
	BaseStatusEffect.OnConstruct(self)
	self.DestroyOnEnd = true
end

function Physics.OnConstructClient(self: Status)
	self:SetHumanoidData({
		WalkSpeed = { 0, "Set" },
		JumpPower = { 0, "Set" },
		AutoRotate = { false, "Set" },
	}, PRIORITY)
end

--function Physics.OnStartClient(self: Status)
--	self.Character.Humanoid.PlatformStand = true
--end

--function Physics.OnEndClient(self: Status)
--	self.Character.Humanoid.PlatformStand = false
--end

--//Returner

return Physics