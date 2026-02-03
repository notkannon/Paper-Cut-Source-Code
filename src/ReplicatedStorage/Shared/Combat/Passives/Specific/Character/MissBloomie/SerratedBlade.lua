--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BleedingStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Bleeding)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BasePassive = require(ReplicatedStorage.Shared.Components.Abstract.BasePassive)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)

--//Variables

local SerratedBladePassive = BaseComponent.CreateComponent("SerratedBladePassive", {

	isAbstract = false,
	
}, BasePassive) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BasePassive.MyImpl)),

	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component, enabled: boolean?) -> (),
	OnConstructServer: (self: Component) -> (),
}

export type Fields = {
	
	LastHitHumanoid: Humanoid?,

	_InternalHitListener: SharedComponent.ServerToClient,
	
} & BasePassive.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "SerratedBladePassive", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "SerratedBladePassive", PlayerTypes.Character>

--//Methods

function SerratedBladePassive.OnHit(self: Component, target: Player)
	
	if RunService:IsServer() then

		local Humanoid = target.Character and target.Character:FindFirstChildWhichIsA("Humanoid")

		if not target
			or not Humanoid then
			
			return
		end

		local config = self:GetConfig()
		
		local WCSCharacter = WCS.Character.GetCharacterFromInstance(target.Character)
		BleedingStatus.new(WCSCharacter, config.BleedInterval, config.BleedDamage):Start(config.BleedDuration)
	
	else
		
		warn("NOT ON SERVER SOMEHOW")
		
	end
end

return SerratedBladePassive