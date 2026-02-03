--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Imports

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseConsumable = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem.BaseConsumable)
local PlayerHealEffect = require(ReplicatedStorage.Shared.Effects.PlayerHeal)

--//Variables

local VitaminsItem = BaseComponent.CreateComponent("VitaminsItem", {
	
	isAbstract = false,
	
}, BaseConsumable) :: BaseConsumable.Impl

--//Methods

function VitaminsItem.ShouldStart(self: BaseConsumable.Component)
	return BaseConsumable.ShouldStart(self)
		and self.Character.Humanoid.Health < self.Character.Humanoid.MaxHealth
end

function VitaminsItem.OnUseServer(self: BaseConsumable.Component)
	
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Instances.Items.Food.Drink
	).Parent = self.Character.HumanoidRootPart
	
	self.Character.Humanoid.Health += 25
	
	PlayerHealEffect.new(self.Character, 25):Start(Players:GetPlayers())
end

--//Returner

return VitaminsItem