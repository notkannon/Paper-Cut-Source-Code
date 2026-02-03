--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)

--//Variables

local CameraModeEnforced = WCS.RegisterStatusEffect("CameraModeEnforced", BaseStatusEffect)

--//Types

export type Status = WCS.StatusEffect

--//Methods

function CameraModeEnforced.OnConstructClient(self: Status, cameraMode: string)
	BaseStatusEffect.OnConstruct(self)
	self:SetHumanoidData(humanoidData)
end

--//Returner

return CameraModeEnforced