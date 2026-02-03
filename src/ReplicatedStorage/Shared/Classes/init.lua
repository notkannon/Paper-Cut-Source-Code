--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local GlobalSettings = require(ReplicatedStorage.Shared.Data.GlobalSettings)

--//Constants

local LOGGING_ENABLED = GlobalSettings.Classes.ToggleClassesConstructionLogging

--//Variables

local Classes = {}
local Singletons = {}
local SingletonConstructors = {}

local SingletonConstructed = Signal.new() :: Signal.Signal<{ any }>

--//Functions

local function Create(
	classTable: { [string]: unknown }?,
	className: string,
	name: string,
	isAbstract: boolean?,
	extendsFrom: { unknown }?
)
	if classTable then
		assert(classTable[name] == nil, `{ className } already exists: { name }`)
	end

	if extendsFrom then
		assert(tostring(extendsFrom), `Invalid extendable { className }: { extendsFrom } `)
	end

	local Super = extendsFrom or {}
	local Class = setmetatable({}, {
		__tostring = function()
			return name
		end,
		__index = Super,
	})
	
	Class.__index = Class

	if not isAbstract and not extendsFrom then
		function Class.new(...: any)
			local self = setmetatable({}, Class)
			
			if className == "Singleton" then
				assert(not Singletons[name], `Singleton { name } already has object`)
				Singletons[name] = self
			end
			
			local Marker = os.clock()
			
			self:OnConstruct(...)

			if RunService:IsServer() then
				
				self:OnConstructServer(...)
				
			elseif RunService:IsClient() then
				
				self:OnConstructClient(...)
			end
			
			if className == "Singleton" then
				SingletonConstructed:Fire(self)
			end
			
			if LOGGING_ENABLED then
				print(`Constructed new Object from: { os.clock() - Marker }s { className } { name }`)
			end
			
			return self
		end

		function Class:OnConstruct() end

		function Class:OnConstructServer() end

		function Class:OnConstructClient() end
	end

	function Class.GetName()
		return name
	end

	function Class:IsImpl()
		return getmetatable(self) ~= Class
	end

	function Class.GetExtendsFrom()
		return extendsFrom
	end

	if classTable then
		classTable[name] = Class
	end

	return Class
end

-- спизжено с roblox-TS, не обессудьте 🤗
local function InstanceOf(obj, class)
	-- custom Class.instanceof() check
	if type(class) == "table" and type(class.instanceof) == "function" then
		return class.instanceof(obj)
	end

	-- metatable check
	if type(obj) == "table" then
		obj = getmetatable(obj)
		while obj ~= nil do
			if obj == class then
				return true
			end
			local mt = getmetatable(obj)
			if mt then
				obj = mt.__index
			else
				obj = nil
			end
		end
	end

	return false
end

local function CreateClass(name: string, isAbstract: boolean?, extendsFrom: { unknown }?)
	return Create(Classes, "Class", name, isAbstract, extendsFrom)
end

local function CreateSingleton(name: string, isAbstract: boolean?, extendsFrom: { unknown }?)
	return Create(SingletonConstructors, "Singleton", name, isAbstract, extendsFrom)
end

local function GetClass(name: string)
	return Classes[name]
end

local function GetSingletonConstructor(name: string)
	return SingletonConstructors[name]
end

local function GetAllSingletonConstructors()
	local Constructors = {}
	
	for _, Impl in pairs(SingletonConstructors) do
		table.insert(Constructors, Impl)
	end
	
	return Constructors
end

local function GetSingleton(name: string)
	return Singletons[name]
end

local function GetAllClasses()
	local List = {}
	
	for _, Class in pairs(Classes) do
		table.insert(List, Class)
	end
	
	return List
end

local function GetAllSingletons()
	local List = {}

	for _, Singleton in pairs(Singletons) do
		table.insert(List, Singleton)
	end

	return List
end

-- Attempt to cleanup (destroy) provided object table
local function CleanupObject(obj, tableToRemoveFrom: { unknown }?)
	assert(typeof(obj) == "table", "Passed non-table object type")
	assert(getmetatable(obj), "Passed non-instance object of any class")
	
	if tableToRemoveFrom then
		for k, v in pairs(tableToRemoveFrom) do
			if v == obj then
				tableToRemoveFrom[k] = nil
			end
		end
	end
	
	table.clear(obj)
	setmetatable(obj, nil)
	
	obj._Destroyed = true
	
	function obj.IsDestroyed()
		return true
	end
	
	table.freeze(obj)
end

-- Returns true if provided object has ._Destroyed field
local function IsDestroyed(obj)
	assert(typeof(obj) ~= "table", "Passed non-table object type")
	return obj._Destroyed == true
end

--//Returner
return {
	ClassTables = {
		Classes = Classes,
		Singletons = Singletons,
		SingletonConstructors = SingletonConstructors,
	},
	
	SingletonConstructed = SingletonConstructed,
	
	InstanceOf = InstanceOf,
	IsDestroyed = IsDestroyed,
	CleanupObject = CleanupObject,
	
	Create = Create,
	CreateClass = CreateClass,
	CreateSingleton = CreateSingleton,
	
	GetClass = GetClass,
	GetSingleton = GetSingleton,
	GetAllClasses = GetAllClasses,
	GetAllSingletons = GetAllSingletons,
	
	GetSingletonConstructor = GetSingletonConstructor,
	GetAllSingletonConstructors = GetAllSingletonConstructors,
}