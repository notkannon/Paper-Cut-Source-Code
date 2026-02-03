--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)

--//Variables

local Invincible = WCS.RegisterStatusEffect("Invincible", BaseStatusEffect)

--//Methods

function Invincible.OnConstructServer(self: BaseStatusEffect.BaseStatusEffect)
	self.DestroyOnEnd = true
end

--//Returner

return Invincible