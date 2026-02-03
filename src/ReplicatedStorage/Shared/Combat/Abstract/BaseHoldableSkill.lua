--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil

local BaseSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseSkill)

--//Variables

local Player = Players.LocalPlayer
local BaseHoldableSkill = WCS.RegisterHoldableSkill("BaseHoldableSkill")

--//Types

export type BaseHoldableSkill = WCS.HoldableSkill & {
	ExclusivesSkillNames: { string },
	--[[ так, тут надо попдробнее остановиться
	1. это может быть просто набор строк {"Stunned", "Aiming"}
	2. некоторые элементы могут быть с указанием тегов {"Stunned", {"Aiming", {"Tag1", "Tag2"}}}
	3. также в список тегов можно добавить Match = true, указывая, что нужно не 100% совпадение, а просто внутри строки
	например местами используется {..., {"ModifiedSpeed", {"Slowed", Match = true}}}
	]]
	ExclusivesStatusNames: { string | {string | {string}} },
	FromRoleData: { string: any },

	GenericJanitor: Janitor.Janitor,

	_TimesUsed: number,
	_Interrupted: boolean -- used sometimes, ask provitia
}

--//Methods

function BaseHoldableSkill.HasExclusiveStatuses(self: BaseHoldableSkill)
	return BaseSkill.HasExclusiveStatuses(self)
end

function BaseHoldableSkill.ShouldStart(self: BaseHoldableSkill)
	return BaseSkill.ShouldStart(self)
end


function BaseHoldableSkill.OnConstruct(self: BaseHoldableSkill)
	BaseSkill.OnConstruct(self)

	self.GenericJanitor:Add(self.Character.SkillStarted:Connect(function(skill: WCS.HoldableSkill)
		if table.find(self.ExclusivesSkillNames, skill:GetName()) then
			if self:GetState().IsActive then
				self:End()
			end
		end
	end))

	self.GenericJanitor:Add(self.Character.StatusEffectStarted:Connect(function(statusEffect: WCS.StatusEffect)
		if self:HasExclusiveStatuses() and not self.IgnoreOngoingStatuses then
			if self:GetState().IsActive then
				self:End()
			end
		end
	end))
end

--//Returner

return BaseHoldableSkill