--[[
	ProxyService - a service for simplified global signals
	If you want to easily to create a bindable signal available from all scripts, use this service
	If you want additional functionality beyond the signals, consider making a new service

	Usage:
		Binding:
			function Component.DoStuff(...)
				local ProxyService = Classes.GetSingleton("ProxyService")
				
				ProxyService:AddProxy("ProxyName"):Fire(123, "args")
				
				or, if you want to reuse the signal:
				
				local Signal = ProxyService:AddProxy("ProxyName")
				Signal:Fire(123)
				Signal:Fire(456)
			end
		
		Connecting:
			function Component.DoStuff(...)
				local ProxyService = Classes.GetSingleton("ProxyService")
				
				ProxyService:AwaitProxyAndConnect("ProxyName", function(yourArg1, yourArg2)
					-- your code
				end)
			end
]]

--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Interaction = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)
local BaseInteraction = require(ReplicatedStorage.Shared.Components.Abstract.BaseInteraction)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local InputController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.InputController) or nil
local Promise = require(ReplicatedStorage.Packages.Promise)

--//Variables

local ProxyService = Classes.CreateSingleton("ProxyService") :: Impl

--//Types

export type Impl = {
	__index: Impl,

	IsImpl: (self: Service) -> boolean,
	GetName: () -> "ProxyService",
	GetExtendsFrom: () -> nil,
	
	new: () -> Service,
	OnConstruct: (self: Service) -> (),
	
	AddProxy: (self: Service, name: string, overwrite: boolean?) -> Signal.Signal,
	RemoveProxy: (self: Service, name: string, ignoreIfNotExists: boolean) -> (),
	GetProxy: (self: Service, name: string) -> Signal.Signal?,
	FireProxy: (self: Service, name: string, args: unknown) -> (),
	AwaitProxy: (self: Service, name: string) -> Promise.TypedPromise<Signal.Signal>,
	AwaitProxyAndConnect: (self: Service, name: string, callback: (args: unknown) -> ()) -> () -> ()
}

export type Fields = {
	ProxyJanitor: Janitor.Janitor,
	ProxyAdded: Signal.Signal<Signal.Signal, string>,
	ProxyRemoved: Signal.Signal<string>,
	Janitor: Janitor.Janitor
}

export type Service = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Methods

function ProxyService.OnConstruct(self: Service)
	self.Janitor = Janitor.new()
	self.ProxyJanitor = self.Janitor:Add(Janitor.new())
	self.ProxyAdded = self.Janitor:Add(Signal.new())
	self.ProxyRemoved = self.Janitor:Add(Signal.new())
end

function ProxyService.AddProxy(self: Service, name: string, overwrite: boolean?)
	local ExistingProxy = self:GetProxy(name)
	
	if ExistingProxy and not overwrite then
		return ExistingProxy
	end
	
	if ExistingProxy and overwrite then
		self:RemoveProxy(name)
	end
	
	local NewProxy = self.ProxyJanitor:Add(Signal.new(), "Destroy", name)
	
	if (ExistingProxy and overwrite) or not ExistingProxy then
		self.ProxyAdded:Fire(NewProxy, name)
	end
	
	return NewProxy
end

function ProxyService.RemoveProxy(self: Service, name: string, ignoreIfNotExists: boolean)
	assert(self:GetProxy(name) and not ignoreIfNotExists, "Provided proxy doesnt exist:", name)
	
	self.Janitor:Remove(name)
	self.ProxyRemoved:Fire(name)
end

function ProxyService.FireProxy(self: Service, name: string, ...)
	return self:GetProxy(name):Fire(...)
end

function ProxyService.GetProxy(self: Service, name: string)
	return self.ProxyJanitor:Get(name)
end

function ProxyService.AwaitProxy(self: Service, name: string)
	local ExistingProxy = self:GetProxy(name)
	
	if ExistingProxy then
		return Promise.resolve(ExistingProxy)
	end
	
	return Promise.fromEvent(self.ProxyAdded, function(ProxySignal, ProxyName)
		return ProxyName == name
	end)
end

function ProxyService.AwaitProxyAndConnect(self: Service, name: string, callback: (args: unknown) -> ())
	local Connection
	local Promise = self:AwaitProxy(name):andThen(function(Proxy: Signal.Signal)
		Connection = Proxy:Connect(callback)
	end)
	
	local function DisconnectFunction()
		if Connection then
			Connection:Disconnect()
		end
		if Promise then
			Promise:cancel()
		end
	end
	
	self.Janitor:Add(DisconnectFunction)
	
	-- returns function to disconnect from this proxy
	return DisconnectFunction
end

--//Returner

local Singleton = ProxyService.new()
return Singleton :: Service