--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Imports

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseConsumable = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem.BaseConsumable)
local PlayerHealEffect = require(ReplicatedStorage.Shared.Effects.PlayerHeal)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

--//Variables

local BaseFood = BaseComponent.CreateComponent("BaseFood", {
	isAbstract = true,
}, BaseConsumable) :: BaseConsumable.Impl

--//Methods

function BaseFood.OnUseServer(self: BaseConsumable.Component)
	
	local HealthBonus = self.HealthBonus
	local RoleConfig = RolesManager:GetPlayerRoleConfig(self.Player)
	local HealthMultiplier = RoleConfig.CharacterData.UniqueProperties and RoleConfig.CharacterData.UniqueProperties.FoodHealingMultiplier or 1
	HealthBonus *= HealthMultiplier
	
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Instances.Items.Food.Chew
	).Parent = self.Character.HumanoidRootPart

	self.Character.Humanoid.Health += HealthBonus

	PlayerHealEffect.new(self.Character, HealthBonus):Start(Players:GetPlayers())
end

--//Returner

return BaseFood