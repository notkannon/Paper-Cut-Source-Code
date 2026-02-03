--//Service

local Players = game:GetService("Players")
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

--//Variables

local BaseDestroyable = Classes.CreateClass("BaseDestroyable", true) :: MyImpl

--//Type

export type Fields = {
	
	Janitor: Janitor.Janitor,
	Destroyed: Signal.Signal,
	Destroying: Signal.Signal,
	
	_Destroying: boolean,
	_Destroyed: boolean,
}

export type MyImpl = {
	__index: MyImpl,
	
	IsImpl: (self: Object) -> boolean,
	GetName: () -> "BaseDestroyable",
	GetExtendsFrom: () -> nil,
	
	new: (any...) -> Object,
	
	Destroy: (self: Object) -> (),
	OnDestroy: (self: Object) -> (),
	IsDestroyed: (self: Object) -> boolean,
	IsDestroying: (self: Object) -> boolean,
	
	OnConstruct: (self: Object, any...) -> (),
	OnConstructServer: (self: Object, any...) -> (),
	OnConstructClient: (self: Object, any...) -> (),
}

export type Object = typeof(setmetatable({} :: Fields, {} :: MyImpl))

--//Functions

local function CreateClass(name: string): MyImpl
	
	local Class = Classes.CreateClass(name, false, BaseDestroyable)
	
	--defining constructor function
	function Class.new(...)
		
		local self = setmetatable({}, Class)
		
		return self:_Constructor(...) or self
	end
	
	return Class
end

--//Methods

function BaseDestroyable._Constructor(self: Object, ...: any?)
	
	--initializing janitor
	if not self.Janitor then
		self.Janitor = Janitor.new()
	end
	
	self.Destroyed = Signal.new()
	self.Destroying = Signal.new()
	
	--built-in methods (not related to mt)
	
	function self:Destroy()
		
		self._Destroying = true
		self.Destroying:Fire()
		
		--something that happens on destroy
		self:OnDestroy()
		
		--removing janitor
		self.Janitor:Destroy()

		setmetatable(self, nil)
		
		for k, v in pairs(self) do
			
			--skipping base destroyable methods
			if typeof(v) == "function" and (k == "IsDestroyed" or k == "IsDestroying") then
				continue
				
			elseif k == "Destroyed" or k == "Destroying" then
				--skipping signals
				continue
			end
			
			--cleanup field
			self[k] = nil
		end
		
		--final removal
		self.Destroyed:Destroy()
		self.Destroying:Destroy()
		
		self.Destroyed = nil
		self.Destroying = nil
		self._Destroyed = true

		table.freeze(self)
	end
	
	function self:IsDestroyed()
		return self._Destroyed
	end
	
	function self:IsDestroying()
		return self._Destroying
	end
	
	--finalizing
	
	self:OnConstruct(...)
	
	if RunService:IsServer() then
		self:OnConstructServer(...)
		
	elseif RunService:IsClient() then
		self:OnConstructClient(...)
	end
end

function BaseDestroyable:OnDestroy() end

function BaseDestroyable:OnConstruct() end

function BaseDestroyable:OnConstructServer() end

function BaseDestroyable:OnConstructClient() end

--//Returner

return {
	CreateClass = CreateClass,
}