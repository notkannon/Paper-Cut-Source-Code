--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

--//Variables

local Freeze = WCS.RegisterStatusEffect("Freeze", BaseStatusEffect)

--//Type

export type Status = BaseStatusEffect.BaseStatusEffect

--//Methods

function Freeze.OnConstructServer(self: Status)
	self.DestroyOnEnd = true
end

function Freeze.OnConstructClient(self: Status)
	local Speedmodifier = ModifiedSpeedStatus.new(self.Character, "Set", 0, {
		Priority = 50,
		Tag = "Freezed"
	})
	
	self.SpeedModifier = Speedmodifier
end

function Freeze.OnStartClient(self: Status)
	self.SpeedModifier:Start(self:GetActiveDuration())
end

--//Returner

return Freeze :: typeof(Freeze)