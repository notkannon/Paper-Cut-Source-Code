--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local WCS = require(ReplicatedStorage.Packages.WCS)

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

--//Variables

local SlowingArea = BaseComponent.CreateComponent("SlowingArea", {

	tag = "SlowingArea",
	isAbstract = false,

	defaults = {
		FadeOutTime = 1,
		SpeedMultiplier = 0.8,
		TeacherBoost = 0
	},

}) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseComponent.MyImpl)),

	OnConstruct: (self: Component, options: BaseComponent.SharedComponentConstructOptions?) -> (),
	OnConstructServer: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
}

export type Fields = {
	Entities: { Model & { Humanoid: Humanoid } },
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "SlowingArea", BasePart>
export type Component = BaseComponent.Component<MyImpl, Fields, "SlowingArea", BasePart>

--//Methods

function SlowingArea.OnEntityLeave(self: Component, entity: Instance)
	
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(entity)
	
	if not WCSCharacter then
		return
	end
	
	for _, Status in ipairs(WCSUtility.GetAllStatusEffectsWithTags(WCSCharacter, "ModifiedSpeed", {"AreaSlowed", "AreaTeacherBoosted"})) do
		Status:End()
	end
end

function SlowingArea.OnEntityEnter(self: Component, entity: Instance)
	
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(entity)
	
	if not WCSCharacter then
		return
	end

	ModifiedSpeedStatus.new(WCSCharacter, "Multiply", self.Attributes.SpeedMultiplier, {
		
		Tag = "AreaSlowed",
		Priority = 10,
		FadeInTime = 0,
		FadeOutTime = self.Attributes.FadeOutTime,
		
	}):Start()
	
	if self.Attributes.TeacherBoost and self.Attributes.TeacherBoost ~= 0 and WCSCharacter.Player and RolesManager:IsPlayerKiller(WCSCharacter.Player) then
		ModifiedSpeedStatus.new(WCSCharacter, "Increment", self.Attributes.TeacherBoost, {
			Tag = "AreaTeacherBoosted",
			Priority = 11,
			FadeInTime = 0,
			FadeOutTime = self.Attributes.FadeOutTime
		}):Start()
	end
end

function SlowingArea.GetEntitiesIn(self: Component)
	
	local OverlapParams = OverlapParams.new()
	OverlapParams.FilterType = Enum.RaycastFilterType.Include
	OverlapParams.FilterDescendantsInstances = { workspace.Characters }

	local Entities = {}

	for _, Part in ipairs(workspace:GetPartsInPart(self.Instance, OverlapParams)) do
		
		local Model = Part:FindFirstAncestorWhichIsA("Model")
		
		if Model == workspace then
			continue
		end

		local Humanoid = Model:FindFirstChildWhichIsA("Humanoid")
		
		if not Humanoid or not Humanoid.RootPart then
			continue
		end

		if not table.find(Entities, Model) then
			table.insert(Entities, Model)
		end
	end

	return Entities
end

function SlowingArea.OnPhysics(self: Component)
	
	local CurrentEntities = self:GetEntitiesIn()
	local NewEntities = {}

	-- Добавление новых
	for _, Entity in ipairs(CurrentEntities) do
		
		table.insert(NewEntities, Entity)

		if not table.find(self.Entities, Entity) then
			self:OnEntityEnter(Entity)
		end
	end

	-- Проверка на выход
	for Index, Entity in ipairs(self.Entities) do
		
		if not table.find(CurrentEntities, Entity) then
			
			self:OnEntityLeave(Entity)
			
			table.remove(self.Entities, Index)
		end
	end

	self.Entities = NewEntities
end

function SlowingArea.OnConstructServer(self: Component)
	self.Entities = {}
end

function SlowingArea.OnDestroy(self: Component)
	
	--removing all statises related to this area
	for _, Entity in ipairs(self.Entities) do
		
		local WCSCharacter = WCS.Character.GetCharacterFromInstance(Entity)

		if not WCSCharacter then
			return
		end

		for _, Status in ipairs(WCSUtility.GetAllStatusEffectsWithTags(WCSCharacter, "ModifiedSpeed", {"AreaSlowed", "AreaTeacherBoosted"})) do
			Status:End()
		end
	end
end

--//Returner

return SlowingArea