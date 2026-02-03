--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)

--//Variables

local Healing = WCS.RegisterStatusEffect("Healing", BaseStatusEffect)

--//Functions

function Healing.OnConstruct(self: BaseStatusEffect.BaseStatusEffect)
	self:SetHumanoidData({
		AutoRotate = { false, "Set" } -- fixing the auto rotate bug
	})
end

--//Returner

return Healing