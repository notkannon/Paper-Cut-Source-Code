
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
local BaseModifierStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseModifierStatusEffect)

--//Types

export type MyImpl = {
	__index: MyImpl,
	
	OnConstructClient: (self: Component, characterComponent: {any}) -> (),
	
	_InitSteps: (self: Component) -> (),
	_InitStatusesEvents: (self: Component) -> (),
	
	HandleProcessedValue: (self: Component, value: number) -> (),
	GetBaseValue: (self: Component) -> number,
}

export type Fields = {
	Janitor: Janitor.Janitor,
	
	ActiveModifiers: { ModifiedSpeedStatus.Status },
	CharacterComponent: {any},
	ModifierClass: BaseModifierStatusEffect.BaseModifierStatusEffect,
	
	_Active: boolean,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseModifierHandler", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseModifierHandler", PlayerTypes.Character>

--//Variables

local Player = Players.LocalPlayer

local BaseModifierHandler = BaseComponent.CreateComponent("BaseModifierHandler", {
	isAbstract = true,
	predicate = function(instance)
		return instance == Player.Character
	end,
}) :: Impl

--//Methods


-- @override
function BaseModifierHandler.HandleProcessedValue(self: Component, value: number)
	
end

-- @override
function BaseModifierHandler.GetBaseValue(self: Component)
	
end


function BaseModifierHandler._InitSteps(self: Component)
	
	self.Janitor:Add(RunService.Stepped:Connect(function()
		
		if not self._Active then
			return
		end
		
		debug.profilebegin(`{self:GetName()}HandlerUpdate`)
		
		local BaseValue = self:GetBaseValue()
		
		if not BaseValue then
			return
		end
		
		local ProcessedValue = self.ModifierClass.ResolveModifiers(self.ActiveModifiers, BaseValue)
		
		self:HandleProcessedValue(ProcessedValue)
		
		debug.profileend()
		
	end), nil, "StepsConnection")
end

function BaseModifierHandler._InitStatusesEvents(self: Component)
	local WCSCharacter = self.CharacterComponent.WCSCharacter :: WCS.Character
	
	local function ApplyModifierFromStatus(status: WCS.StatusEffect)
		
		if not Classes.InstanceOf(status, self.ModifierClass) or table.find(self.ActiveModifiers, status) then
			return
		end
		
		status.GenericJanitor:Add(function()
			local Index = self.ActiveModifiers and table.find(self.ActiveModifiers, status)
			
			if not Index then
				return
			end
			
			table.remove(self.ActiveModifiers, Index)
		end)
		
		table.insert(self.ActiveModifiers, status)
	end
	
	local ModifiedSpeedStatuses = WCSUtility.GetAllStatusEffectsInstanceOf(WCSCharacter, self.ModifierClass, true)
	
	if #ModifiedSpeedStatuses > 0 then
		for _, Status in ipairs(ModifiedSpeedStatuses) do
			ApplyModifierFromStatus(Status)
		end
	end
	
	self.Janitor:Add(WCSCharacter.StatusEffectStarted:Connect(ApplyModifierFromStatus))
end

function BaseModifierHandler.Start(self: Component)
	assert(not self._Active, `{self:GetName()} already running`)
	
	self._Active = true
	
	self:_InitSteps()
	self:_InitStatusesEvents()
end

function BaseModifierHandler.OnConstructClient(self: Component, characterComponent: {any})
	characterComponent.Janitor:Add(self, "Destroy")
	
	self.ActiveModifiers = {}
	self.CharacterComponent = characterComponent
	
	assert(self.ModifierClass, `Initialised {self:GetName()} without a proper ModifierClass`)
end

--//Returner

return BaseModifierHandler