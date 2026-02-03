--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)

--//Variables

local AffectedHumanoidProps = WCS.RegisterStatusEffect("AffectedHumanoidProps", BaseStatusEffect)

--//Types

export type Status = WCS.StatusEffect

--//Methods

function AffectedHumanoidProps.OnConstruct(self: Status, humanoidData: WCS.HumanoidDataProps)
	BaseStatusEffect.OnConstruct(self)
	self:SetHumanoidData(humanoidData)
end

--//Returner

return AffectedHumanoidProps
