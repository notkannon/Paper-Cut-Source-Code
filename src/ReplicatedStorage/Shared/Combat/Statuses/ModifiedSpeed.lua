--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseModifierStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseModifierStatusEffect)

--//Variables

local ModifiedSpeed = WCS.RegisterStatusEffect("ModifiedSpeed", BaseModifierStatusEffect) :: Status

--//Types

export type Status = {

} & BaseModifierStatusEffect.BaseModifierStatusEffect

--//Methods


--//Returner

return ModifiedSpeed