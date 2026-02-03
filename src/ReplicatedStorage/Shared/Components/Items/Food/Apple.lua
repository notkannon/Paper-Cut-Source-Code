--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Imports

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseFood = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem.BaseConsumable.BaseFood)
local PlayerHealEffect = require(ReplicatedStorage.Shared.Effects.PlayerHeal)

--//Variables

local AppleItem = BaseComponent.CreateComponent("AppleItem", {
	isAbstract = false,
}, BaseFood) :: BaseConsumable.Impl

--//Methods

function AppleItem.OnConstructServer(self: BaseFood.Component)
	BaseFood.OnConstructServer(self)
	self.HealthBonus = 7
end

--//Returner

return AppleItem