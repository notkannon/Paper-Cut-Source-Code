--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local WCS = require(ReplicatedStorage.Packages.WCS)
local Type = require(ReplicatedStorage.Packages.Type)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseDoorProtector = require(ReplicatedStorage.Shared.Components.Abstract.BaseDoorProtector)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)
local ModifiedStaminaGainStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedStaminaGain)
local GumDoorProtectorEffect = require(ReplicatedStorage.Shared.Effects.Specific.Components.Doors.GumDoorProtector)

--//Variables

local LocalPlayer = Players.LocalPlayer
local GumDoorProtector = BaseComponent.CreateComponent("GumDoorProtector", {

	isAbstract = false,

}, BaseDoorProtector) :: Impl

--//Types

export type Fields = {

} & BaseDoorProtector.Fields

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseDoorProtector.MyImpl)),
	
	OnConstruct: (self: Component, doorComponent: unknown, any...) -> (),
	OnConstructServer: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "GumDoorProtector", Instance, any...>
export type Component = BaseComponent.Component<MyImpl, Fields, "GumDoorProtector", Instance, any...>

--//Methods

function GumDoorProtector.TakeDamage(self: Component, damageContainer: WCS.DamageContainer)
	BaseDoorProtector.TakeDamage(self, damageContainer)
	
	--check valid damage container
	if damageContainer.Source and RolesManager:IsPlayerKiller(damageContainer.Source.Player) then
		
		if damageContainer.Source.Name == "Harpoon" then
			return
		end
		
		--getting WCS character valid way
		local WCSCharacter = WCS.Character.GetCharacterFromInstance(damageContainer.Source.Player.Character)
		
		if not WCSCharacter then
			return
		end
		
		--debuffs
		ModifiedSpeedStatus.new(WCSCharacter, "Multiply", 0.3, {Tag = "GumSlowed"}):Start(4)
		ModifiedStaminaGainStatus.new(WCSCharacter, "Multiply", 0, {Tag = "GumStaminaGainBlocked"}):Start(4)
		WCSUtility.ApplyGlobalCooldown(WCSCharacter, 4, {
			EndActiveSkills = true,
		})
		
		--modifying full damage to destroy door on protector remove
		damageContainer.Damage = self.Door.Attributes.MaxHealth
		
		if self.Owner then
			local ProxyService = Classes.GetSingleton("ProxyService")
			ProxyService:AddProxy("GumDestroyed"):Fire(damageContainer.Source.Player, self.Owner) -- who destroyed and who owned
		end
		
		--removing protector
		self:Destroy()
	end
end

function GumDoorProtector.OnConstruct(self: Component, ...: any)
	self.ActionText = "Remove Gum"
	BaseDoorProtector.OnConstruct(self, nil, ...)
	
end

function GumDoorProtector.OnConstructServer(self: Component)
	BaseDoorProtector.OnConstructServer(self)
	
	--applying visuals via effects stuff
	self.Janitor:Add(
		
		GumDoorProtectorEffect.new(self.Instance),
		
		nil,
		"Effect"
		
	):Start(Players:GetPlayers())
end

--//Returner

return GumDoorProtector