--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Imports

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseFood = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem.BaseConsumable.BaseFood)
local PlayerHealEffect = require(ReplicatedStorage.Shared.Effects.PlayerHeal)

--//Variables

local BananaItem = BaseComponent.CreateComponent("BananaItem", {
	isAbstract = false,
}, BaseFood) :: BaseConsumable.Impl

--//Methods

function BananaItem.OnConstructServer(self: BaseFood.Component)
	BaseFood.OnConstructServer(self)
	self.HealthBonus = 11
end


--//Returner

return BananaItem