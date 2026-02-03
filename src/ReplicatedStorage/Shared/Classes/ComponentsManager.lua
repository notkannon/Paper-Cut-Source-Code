--//Services

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local ThreadUtility = require(ReplicatedStorage.Shared.Utility.ThreadUtility)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)

--//Variables

local Started = false
local StartedSignal = Signal.new()

local ComponentsManager: Impl = {} :: Impl

local InstanceComponents: { [Instance]: { [string]: BaseComponent.BaseComponent } } = {}

ComponentsManager.ComponentAdded = Signal.new()
ComponentsManager.ComponentRemoved = Signal.new()

--//Types

type Impl = {
	
	ComponentAdded: Signal.Signal<BaseComponent.BaseComponent, BaseComponent.BaseImpl, Instance>,
	ComponentRemoved: Signal.Signal<BaseComponent.BaseComponent, Instance>,

	OnStart: () -> Promise.TypedPromise<nil>,
	Start: () -> Promise.TypedPromise<nil>,
	
	Get: (instance: Instance, searchForImpl: BaseComponent.BaseImpl | string) -> BaseComponent.BaseComponent?,
	GetImpl: (componentName: BaseComponent.BaseImpl | string) -> BaseComponent.BaseImpl?,
	GetFirstComponentInstanceOf: (instance: Instance, searchForImpl: BaseComponent.BaseImpl | string) -> BaseComponent.BaseComponent?,
	
	GetAllTagged: (tag: string, useMatch: boolean, searchForImpls: { BaseComponent.BaseImpl }?) -> { [Instance]: { BaseComponent.BaseComponent } },
	GetFirstTagged: (tag: string, useMatch: boolean, searchForImpls: { BaseComponent.BaseImpl }?) -> BaseComponent.Component?,
	GetAllTaggedList: (tag: string, useMatch: boolean, searchForImpls: { BaseComponent.BaseImpl }?) -> { BaseComponent.Component? },
	
	GetAll: (instance: Instance, searchForImpls: { BaseComponent.BaseImpl }?) -> { BaseComponent.BaseComponent },
	ListAll: () -> { BaseComponent.BaseComponent? },
	GetInstances: (searchForImpl: BaseComponent.BaseComponent? | string) -> { Instance? }, 
	GetAllExtendsFrom: (componentImpl: BaseComponent.BaseImpl) -> { string? },
	GetAllComponentsOfType: (searchForImpl: BaseComponent.BaseImpl | string) -> { BaseComponent.BaseComponent? },
	GetComponentsFromInstance: (instance: Instance) -> { BaseComponent.BaseComponent? },
	
	Await: (
		instance: Instance,
		awaitImpl: BaseComponent.BaseImpl | string
	) -> Promise.TypedPromise<BaseComponent.BaseComponent, BaseComponent.BaseImpl, Instance>,
	
	Add: (instance: Instance, componentImpl: BaseComponent.BaseImpl | string, ...any) -> BaseComponent.BaseComponent,
	Remove: (instance: Instance, componentImpl: BaseComponent.BaseImpl | string) -> (),

	_RegisteryComponent: (componentImpl: BaseComponent.BaseImpl, options: BaseComponent.Options) -> (),
	_ApplyChecks: (instance: Instance, options: BaseComponent.Options) -> boolean,
}

--//Functions

function ComponentsManager.OnStart()
	if Started then
		return Promise.resolve()
	end

	return Promise.fromEvent(StartedSignal)
end

function ComponentsManager.Start()
	assert(not Started, "ComponentsManager has already been started")

	for Component, Option in pairs(BaseComponent.GetComponentOptions()) do
		ThreadUtility.UseThread(ComponentsManager._RegisteryComponent, Component, Option)
	end

	Started = true
	StartedSignal:Fire()

	task.defer(StartedSignal.Destroy, StartedSignal)
end

function ComponentsManager.GetAllTagged(tag: string, useMatch: boolean, searchForImpls: { BaseComponent.BaseImpl }?)
	local Found = {}

	for _, Tag in ipairs(CollectionService:GetAllTags()) do
		if not useMatch and Tag ~= tag or Tag:match(tag) then
			continue
		end
		
		for _, Tagged in ipairs(CollectionService:GetTagged(tag)) do
			Found[Tagged] = ComponentsManager.GetAll(Tagged, searchForImpls)
		end
	end

	return Found
end

function ComponentsManager.GetAllTaggedList(tag: string, useMatch: boolean, searchForImpls: { BaseComponent.BaseImpl }?)
	local tagged = ComponentsManager.GetAllTagged(tag, useMatch, searchForImpls)
	local list = {}
	
	for _, Components in pairs(tagged) do
		for _, Component in ipairs(Components) do
			table.insert(list, Component)
		end
	end
	
	return list
end

function ComponentsManager.GetFirstTagged(tag: string, useMatch: boolean, searchForImpls: { BaseComponent.BaseImpl }?)
	return ComponentsManager.GetAllTaggedList(tag, useMatch, searchForImpls)[1]
end

function ComponentsManager.GetAll(instance: Instance, searchForImpls: { BaseComponent.BaseImpl }?)	
	
	if not InstanceComponents[instance] then
		return {}
	end

	if not searchForImpls then
		return InstanceComponents[instance]
	end

	local FoundComponents = {}

	local function Search(componentImpl)
		
		if table.find(searchForImpls, componentImpl) then
			return true
		end
		
		local Extends = componentImpl.GetExtendsFrom()

		if Extends and Extends ~= BaseComponent then
			return Search(Extends)
		end

		return false
	end

	for _, FoundComponent in pairs(InstanceComponents[instance]) do
		for _, ComponentImpl in ipairs(searchForImpls) do
			if getmetatable(FoundComponent) == ComponentImpl then
				table.insert(FoundComponents, FoundComponent)
				continue
			end

			local Found = Search(FoundComponent)
			if not Found then
				continue
			end

			table.insert(FoundComponents, FoundComponent)
		end
	end

	return FoundComponents
end

function ComponentsManager.GetAllExtendsFrom(componentImpl: BaseComponent.BaseImpl)
	
	local ExtendsFrom = {}
	local Impl = componentImpl
	
	while true do
		
		local Extension = Impl:GetExtendsFrom()
		
		if not Extension then
			break
		end
		
		table.insert(ExtendsFrom, Extension:GetName())
		
		Impl = Extension
	end
	
	return ExtendsFrom
end

function ComponentsManager.GetComponentsFromInstance(instance: Instance)
	if not InstanceComponents[instance] then
		return {}
	end
	
	local Components = {}
	
	for _, Component in pairs(InstanceComponents[instance]) do
		table.insert(Components, Component)
	end
	
	return Components
end

function ComponentsManager.ListAll()
	
	local Components = {}
	
	for _, InstanceComponentList in pairs(InstanceComponents) do
		for _, Component in pairs(InstanceComponentList) do

			table.insert(Components, Component)
		end
	end
	
	return Components
end

function ComponentsManager.GetInstances(searchForImpl: BaseComponent.BaseComponent | string)
	
	local ComponentName = tostring(searchForImpl)
	if not ComponentName then
		return
	end
	
	local FoundInstances = {}
	
	for Instance, Components in pairs(InstanceComponents) do
		
		for _, Component in pairs(Components) do
			
			if Component.GetName() == ComponentName then
				table.insert(FoundInstances, Instance)
			end
		end
	end

	return FoundInstances
end

function ComponentsManager.GetAllComponentsOfType(searchForImpl: BaseComponent.BaseImpl | string)
	
	local ComponentName = tostring(searchForImpl)
	if not ComponentName then
		return
	end

	local FoundComponents = {}

	for _, Components in pairs(InstanceComponents) do
		
		for _, Component in pairs(Components) do
			
			if Component.GetName() == ComponentName then
				table.insert(FoundComponents, Component)
			end
		end
	end

	return FoundComponents
end

function ComponentsManager.Get(instance: Instance, searchForImpl: BaseComponent.BaseImpl | string)
	
	local ComponentName = tostring(searchForImpl)
	if not ComponentName then
		return
	end
	
	local Instance = InstanceComponents[instance]
	--print(searchForImpl, Instance)
	if not Instance then
		return
	end

	return Instance[ComponentName]
end

function ComponentsManager.GetImpl(componentName: BaseComponent.BaseImpl | string)
	return BaseComponent.GetNameComponents()[typeof(componentName) == "string" and componentName or tostring(componentName)]
end

--returns first component which is intance of provided class. Recommended to rarely use
function ComponentsManager.GetFirstComponentInstanceOf(instance: Instance, searchForImpl: BaseComponent.BaseImpl | string)
	
	debug.profilebegin("GetFirstComponentInstanceOf")
	
	if not instance then
		return
	end
	
	local ComponentName = tostring(searchForImpl)
	local Impl = ComponentName and ComponentsManager.GetImpl(ComponentName)
	
	if not Impl then
		return
	end
	
	local CurrentInstanceComponents = InstanceComponents[instance]
	
	if not CurrentInstanceComponents then
		return
	end
	
	--searching for first descendant of provided class impl
	for _, Component in pairs(CurrentInstanceComponents) do
		
		if Classes.InstanceOf(Component, Impl) then
			
			debug.profileend()
			
			return Component
		end
	end
	
	debug.profileend()
end

function ComponentsManager.AwaitFirstComponentInstanceOf(instance: Instance, searchForImpl: BaseComponent.BaseImpl | string)
	if not instance then
		return Promise.reject("No instance provided!")
	end
	
	local ComponentName = tostring(searchForImpl)
	local Impl = ComponentName and ComponentsManager.GetImpl(ComponentName)
	
	if not Impl then
		return Promise.reject(`No implementation found for component {ComponentName}!`)
	end
	
	local FoundComponent = ComponentsManager.GetFirstComponentInstanceOf(instance, searchForImpl)
	if FoundComponent then
		return Promise.resolve(FoundComponent)
	end
	
	return Promise.fromEvent(ComponentsManager.ComponentAdded, function(addedComponent, addedComponentImpl, addedInstance)
		return Classes.InstanceOf(addedComponent, Impl) and addedInstance == instance
	end)
end

function ComponentsManager.Await(instance: Instance, awaitImpl: BaseComponent.BaseImpl | string)
	local ComponentName = tostring(awaitImpl)
	if not ComponentName then
		--print('didnt get it', ComponentName)
		return Promise.reject("No component name provided!")
	end

	local FoundComponent = ComponentsManager.Get(instance, awaitImpl)
	if FoundComponent then
		--print('found it!', ComponentName)
		return Promise.resolve(FoundComponent)
	end
	
	--print('trying the event', ComponentName)
	return Promise.fromEvent(ComponentsManager.ComponentAdded, function(_, addedComponentImpl, addedInstance)
		return tostring(addedComponentImpl) == ComponentName and addedInstance == instance
	end)
end

function ComponentsManager.Add(instance: Instance, componentImpl: BaseComponent.BaseImpl | string, ...)
	
	local ComponentName = tostring(componentImpl)
	if not ComponentName then
		
		return
	end
	
	local ComponentImpl = typeof(componentImpl) ~= "string" and componentImpl or BaseComponent.GetNameComponents()[ComponentName]
	if not ComponentImpl then
		--print(instance, componentImpl, 'failed cuz no componenttimpl :skull:')
		return
	end
	
	local Options = BaseComponent.GetComponentOptions()[ComponentImpl]
	if not Options then
		print(instance, componentImpl, 'failed cuz no component options')
		return
	end
	
	--getting a dictionary of components or a blank table if wasnt created yet
	InstanceComponents[instance] = InstanceComponents[instance] or {}
	local IntendedInstanceTable = InstanceComponents[instance]
	
	assert(not IntendedInstanceTable[ComponentName], `Component {ComponentName} already exists`)

	local NewComponent = ComponentImpl['new'] and ComponentImpl.new(instance, ...) or ...
	
	IntendedInstanceTable[ComponentName] = NewComponent
	
	ComponentsManager.ComponentAdded:Fire(NewComponent, ComponentImpl, instance)
	
	--auto removal if component being destroyed without ComponentsManager.Remove
	NewComponent.Destroyed:Once(function()
		if ComponentsManager.Get(instance, componentImpl) then
			ComponentsManager.Remove(instance, componentImpl)
		end
	end)
	
	return NewComponent
end


function ComponentsManager.Remove(instance: Instance, componentImpl: BaseComponent.BaseImpl | string)
	
	local FoundComponent = ComponentsManager.Get(instance, componentImpl)
	local IntendedInstanceTable = InstanceComponents[instance]
	
	if not FoundComponent then
		return
	end
	
	--removing component from instance table
	IntendedInstanceTable[FoundComponent:GetName()] = nil
	
	if not FoundComponent:IsDestroyed() then
		FoundComponent:Destroy()
	end
	
	--remove instance without components from memory
	if IntendedInstanceTable and not next(IntendedInstanceTable) then
		InstanceComponents[instance] = nil
	end

	ComponentsManager.ComponentRemoved:Fire(FoundComponent, instance)
end

function ComponentsManager._RegisteryComponent(componentImpl: BaseComponent.BaseImpl, options: BaseComponent.Options)
	
	if not options.tag or options.isAbstract then
		return
	end
	
	local function InstanceAdded(instance: Instance)
		if ComponentsManager._ApplyChecks(instance, options) then
			ComponentsManager.Add(instance, componentImpl)
		end
	end

	CollectionService:GetInstanceAddedSignal(options.tag):Connect(InstanceAdded)
	CollectionService:GetInstanceRemovedSignal(options.tag):Connect(function(instance)
		ComponentsManager.Remove(instance, componentImpl)
	end)

	for _, instance in CollectionService:GetTagged(options.tag) do
		
		if instance:IsDescendantOf(ReplicatedStorage)
			or instance:IsDescendantOf(ServerStorage) then
			
			continue
		end
		
		ThreadUtility.UseThread(InstanceAdded, instance)
	end
end

function ComponentsManager._ApplyChecks(instance: Instance, options: BaseComponent.Options)
	if options.predicate and not options.predicate(instance) then
		return false
	end
	
	local IsWhitelisted = if options.ancestorWhitelist
		then TableKit.Some(options.ancestorWhitelist, function(ancestor)
			return instance:IsDescendantOf(ancestor)
		end)
		
		else nil
	
	if IsWhitelisted == false then
		return false
	end
	
	local IsBlacklisted = if options.ancestorBlacklist
		then TableKit.Some(options.ancestorBlacklist, function(ancestor)
			return instance:IsDescendantOf(ancestor)
		end)
		
		else false

	if IsBlacklisted and IsWhitelisted == nil then
		return false
	end
	
	return true
end

--//Returner

return ComponentsManager