
--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)
local BaseModifierHandler = require(ReplicatedStorage.Shared.Components.Abstract.BaseModifierHandler)

--//Types

export type MyImpl = { } & BaseModifierHandler.MyImpl

export type Fields = { } & BaseModifierHandler.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "SpeedHandler", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "SpeedHandler", PlayerTypes.Character>

--//Variables

local Player = Players.LocalPlayer

local SpeedHandler = BaseComponent.CreateComponent("SpeedHandler", {
	isAbstract = false,
	predicate = function(instance)
		return instance == Player.Character
	end,
}, BaseModifierHandler) :: Impl

--//Methods

function SpeedHandler.GetBaseValue(self: Component)
	local Humanoid = self.CharacterComponent.Humanoid :: Humanoid
	
	if not Humanoid then
		return
	end
	
	local WCSCharacter = self.CharacterComponent.WCSCharacter :: WCS.Character
	
	local RealWalkSpeed = Humanoid.WalkSpeed
	local DestinatedWalkSpeed = WCSCharacter:GetAppliedProps().WalkSpeed
	
	return DestinatedWalkSpeed
end

function SpeedHandler.HandleProcessedValue(self: Component, value: number)
	local Humanoid = self.CharacterComponent.Humanoid :: Humanoid

	if not Humanoid then
		return
	end
	
	Humanoid.WalkSpeed = value
end

function SpeedHandler.OnConstructClient(self: Component, ...)
	self.ModifierClass = ModifiedSpeedStatus
	BaseModifierHandler.OnConstructClient(self, ...)
end

--//Returner

return SpeedHandler