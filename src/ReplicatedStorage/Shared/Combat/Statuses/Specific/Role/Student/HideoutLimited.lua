--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)

--//Variables

local HideoutLimited = WCS.RegisterStatusEffect("HideoutLimited", BaseStatusEffect)

--//Types

export type Status = BaseStatusEffect.BaseStatusEffect

--//Methods

function HideoutLimited.OnConstruct(self: Status)
	BaseStatusEffect.OnConstruct(self)
	self.DestroyOnEnd = true
end

--//Returner

return HideoutLimited