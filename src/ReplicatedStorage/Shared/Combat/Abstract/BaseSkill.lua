--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Signal = require(ReplicatedStorage.Packages.Signal)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)

--//Variables

local Player = Players.LocalPlayer
local BaseSkill = WCS.RegisterSkill("BaseSkill")

--//Types

export type BaseSkill = WCS.Skill & {
	FromRoleData: { string: any },
	ExclusivesSkillNames: { string },
	--[[ так, тут надо попдробнее остановиться
	1. это может быть просто набор строк {"Stunned", "Aiming"}
	2. некоторые элементы могут быть с указанием тегов {"Stunned", {"Aiming", {"Tag1", "Tag2"}}}
	3. также в список тегов можно добавить Match = true, указывая, что нужно не 100% совпадение, а просто внутри строки
	например местами используется {..., {"ModifiedSpeed", {"Slowed", Match = true}}}
	]]
	ExclusivesStatusNames: { string | {string | {string}} },
	GenericJanitor: Janitor.Janitor,
	
	_TimesUsed: number,
}

--//Methods

function BaseSkill.HasExclusiveStatuses(self: BaseSkill) : boolean
	for _, status in self.ExclusivesStatusNames do
		if typeof(status) == "string"  then
			if WCSUtility.HasActiveStatusEffectsWithNames(self.Character, {status}) then
				--print(self:GetName(), "Has exclusive status:", status)
				return true
			end
		elseif typeof(status) == "table" then
			local Match = status[2].Match
			if WCSUtility.HasStatusEffectsWithTags(self.Character, status[1], status[2], Match) then
				--print(self:GetName(), "Has exclusive tag status:", status[1])
				return true
			end
		else
			error(`Expected string or table, got {status}`)
		end
	end
	
	return false
end

function BaseSkill.ShouldStart(self: BaseSkill) : boolean

	local MaxUses = self.FromRoleData.MaxUses :: number?
	
	--limiting of uses amount
	if RunService:IsClient() and MaxUses and self.CurrentUses <= 0 then
		return false
	end

	if WCSUtility.HasActiveSkillsWithName(self.Character, self.ExclusivesSkillNames) or (self.HasExclusiveStatuses and self:HasExclusiveStatuses()) then
		
		return false
	end

	return true
end

function BaseSkill.OnConstruct(self: BaseSkill)
	self.GenericJanitor = Janitor.new()

	self.Destroyed:Once(function()
		self.GenericJanitor:Destroy()
	end)

	--usage amount
	self.Started:Connect(function()
		if self.CurrentUses then
			self.CurrentUses -= 1
			self.UsesChanged:Fire(self.CurrentUses)
		end
	end)
	
	--role config
	local RoleConfig = RolesManager:GetPlayerRoleConfig(self.Player)

	self.FromRoleData = RoleConfig.SkillsData[self.Name]

	self.Charged = Signal.new()
	self.UsesChanged = Signal.new()
	self.CurrentCharge = 0
	self.OngoingSources = {}
	self.AddCharge = function(self: BaseSkill, amount: number)
		if not self.FromRoleData.Charge or self.CurrentUses >= self.MaxUses then
			return
		end

		self.CurrentCharge += amount
		if self.CurrentCharge >= self.FromRoleData.Charge.MaxCharge then
			self.CurrentCharge = 0
			self.CurrentUses += 1
			self.UsesChanged:Fire(self.CurrentUses)
		end

		self.Charged:Fire(self.CurrentCharge)
	end
	self.IsSourceActive = function(self: BaseSkill, sourceName: string)
		for _, Source in ipairs(self.OngoingSources) do
			if Source.Name == sourceName then
				return true
			end
		end
		return false
	end
	self.StartSource = function(self: BaseSkill, sourceName: string)
		if not self.FromRoleData.Charge then
			return
		end

		local SourceData = self.FromRoleData.Charge.FillSources[sourceName]

		if not SourceData then
			return
		end
		
		SourceData.Name = sourceName
		
		if self:IsSourceActive(sourceName) then
			return
		end

		if SourceData.Type == "OneTime" then
			self:AddCharge(SourceData.Amount)
		elseif SourceData.Type == "PerSecond" then
			table.insert(self.OngoingSources, SourceData)
		else
			error(`Unknown charge type: {SourceData.Type}`)
		end
	end
	self.StopSource = function(self: BaseSkill, sourceName: string)
		for i, Source in ipairs(self.OngoingSources) do
			if Source.Name == sourceName then
				table.remove(self.OngoingSources, i)
				break
			end
		end
	end
	if self.FromRoleData.Charge then
		self.GenericJanitor:Add(RunService.Stepped:Connect(function(_, deltaTime)
			for _, Source in self.OngoingSources do
				self:AddCharge(Source.Amount * deltaTime)
			end
		end))
	end

	self.CurrentUses = self.FromRoleData.StartingUses or self.FromRoleData.MaxUses
	self.MaxUses = self.FromRoleData.MaxUses
	self.CheckOthersActive = false

	self.ExclusivesSkillNames = self.ExclusivesSkillNames or {}
	self.ExclusivesStatusNames = self.ExclusivesStatusNames or {}

	assert(self.FromRoleData, `No Skill { self.Name } data registered in role { RoleConfig.DisplayName }`)
	
	self._Constructed = true
end

--//Returner

return BaseSkill