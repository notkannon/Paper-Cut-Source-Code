--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)

--//Variables

local MarkedForDeath = WCS.RegisterStatusEffect("MarkedForDeath", BaseStatusEffect)

--//Methods

function MarkedForDeath.OnStartServer(self: BaseStatusEffect.BaseStatusEffect)
	self.IsDead = false
end

function MarkedForDeath.OnEndServer(self: BaseStatusEffect.BaseStatusEffect)
	if self.IsDead then
		self.Character.Humanoid.Health = 0
	end
end

--//Returner

return MarkedForDeath