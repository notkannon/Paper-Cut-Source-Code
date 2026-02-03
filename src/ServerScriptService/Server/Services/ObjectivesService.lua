--//Services

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseObjective = require(ReplicatedStorage.Shared.Components.Abstract.BaseObjective)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local Utility = require(ReplicatedStorage.Shared.Utility)

--//Variables

local ObjectivesService: Impl = Classes.CreateSingleton("ObjectivesService") :: Impl

--//Types

export type ObjectivesState = {
	Objectives: { Instance }, -- we can exctract components from instances via ComponentsManager
	SolvedCount: number,
	EntireCount: number,
}

export type Impl = {
	__index: Impl,

	new: () -> Service,
	IsImpl: (self: Service) -> boolean,
	GetName: () -> "ObjectivesService",
	GetExtendsFrom: () -> nil,
	
	AddObjective: (self: Service, objective: BaseObjective.Component) -> (),
	PlayerHasObjective: (self: Service, player: Player) -> boolean,
	
	_GraceDestroy: (self: Service, objective: BaseObjective.Component) -> (),
	
	OnConstructServer: (self: Service) -> (),
}

export type Fields = {
	
	Objectives: { BaseObjective.Component },
	
	ObjectivesChanged: Signal.Signal<ObjectivesState>,
	ObjectiveStarted: Signal.Signal<BaseObjective.Component, Player, Player>,
	ObjectiveCompleted: Signal.Signal<BaseObjective.Component, Player, BaseObjective.ObjectiveCompletionState>,
}

export type Service = typeof(setmetatable({} :: Fields, ObjectivesService :: Impl))

--//Methods

function ObjectivesService.PlayerHasObjective(self: Service, player: Player)
	
	for _, Objective in ipairs(self.Objectives) do
		
		if Objective:HasPlayer(player) then
			return true
		end
	end
	
	return false
end

function ObjectivesService.AddObjective(self: Service, objective: BaseObjective.Component)
	
	--removal stuff
	objective.Janitor:Add(function()
		
		table.remove(self.Objectives,
			table.find(self.Objectives, objective)
		)
	end)
	
	--handling objective events
	objective.Janitor:Add(objective.Completed:Connect(function(player, state)
		
		self.ObjectiveCompleted:Fire(objective, player, state)
		
		if state ~= "Success" then
			return
		end
		
		self.SolvedAmount += 1
		
		--destruction
		if objective.DestroyOnComplete then
			self:_GraceDestroy(objective)
		end
	end))
	
	--caching
	table.insert(self.Objectives, objective)
end

function ObjectivesService._GraceDestroy(self: Service, objective: BaseObjective.Component)
	objective:RemoveAll()
	objective.Interaction:Destroy()

	task.delay(objective.DestroyDelay or 0, function()
		objective:Destroy()
		table.remove(self.Objectives,
			table.find(self.Objectives, objective)
		)
	end)
end

function ObjectivesService.OnConstructServer(self: Service)
	
	self.Objectives = {}
	self.SolvedAmount = 0
	self.StarterAmount = 0
	
	self.ObjectiveStarted = Signal.new()
	self.ObjectivesChanged = Signal.new()
	self.ObjectiveCompleted = Signal.new()
end

--//Returner

local Singleton = ObjectivesService.new()
return Singleton