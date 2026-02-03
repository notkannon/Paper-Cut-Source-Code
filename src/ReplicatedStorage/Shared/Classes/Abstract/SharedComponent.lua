--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Type = require(ReplicatedStorage.Packages.Type)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Promise = require(ReplicatedStorage.Packages.Promise)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil
local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil
local PlayerService = RunService:IsServer() and require(ServerScriptService.Server.Services.PlayerService) or nil

--//Variables

local Player = Players.LocalPlayer

local SharedComponent = BaseComponent.CreateComponent("SharedComponent", {
	tag = "SharedComponent",
	isAbstract = true,
}) :: Impl

--//Types

type Arguments = {
	arguments: { unknown },
	eventName: string,
	instance: Instance,
	name: string,
}

type Callback = (player: Player, ...any) -> ()

type CallbacksHandler = {
	Validators: { Validator },
	Callbacks: { Callback },
}

type Validator = <a>(value: a) -> boolean

export type SharedComponentConstructOptions = {
	Sync: { string }?,
	SyncOnce: boolean?,
	SyncOnCreation: boolean?,
}

export type ServerToClient<Args...> = {
	On: (callback: (Args...) -> ()) -> () -> (),
	Fire: (player: Player, Args...) -> (),
	FireAll: (Args...) -> (),
	FireExcept: (player: Player, Args...) -> (),
	FireList: (players: { Player }, Args...) -> (),
	FireSet: (players: { [Player]: true }, Args...) -> (),
}

export type ClientToServer<Args...> = {
	On: (callback: (player: Player, Args...) -> ()) -> () -> (),
	Fire: (Args...) -> (),
}

export type CreateEvent<EXComponent> = (
	self: EXComponent,
	eventName: string,
	eventType: "Reliable" | "Unreliable",
	...Validator
) -> any

export type MyImpl = {
	__index: MyImpl,

	SyncClient: (self: Component) -> (),
	CreateEvent: CreateEvent<Component>,
	OnConstruct: (self: Component, options: SharedComponentConstructOptions?) -> (),
}

export type Fields = {
	NewPlayersReplicate: boolean,
	
	_ClientSyncing: boolean,
	_ClientSyncedOnce: boolean,
	_SyncArgumentsEvent: ServerToClient,
	_ConstructorOptions: SharedComponentConstructOptions?,
	
	_SharedComponentCallbacks: {
		Reliable: { [string]: CallbacksHandler },
		Unreliable: { [string]: CallbacksHandler },
	},
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, nil, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, string, nil, {}>

--//Methods

function SharedComponent.OnConstruct(self: Component, options: SharedComponentConstructOptions?)
	local options = TableKit.MergeDictionary({
		SyncOnce = false,
		SyncOnCreation = true,
	}, options or {}) :: SharedComponentConstructOptions
	
	self._ConstructorOptions = options or {}
	self._SharedComponentCallbacks = {
		Reliable = {},
		Unreliable = {},
	}

	local function Connection(player: Player, eventType: "Reliable" | "Unreliable", args: Arguments)
		
		if args.name ~= self.GetName() or args.instance ~= self.Instance then
			return
		end

		local Handler = self._SharedComponentCallbacks[eventType][args.eventName] :: CallbacksHandler
		assert(Handler, `No handler registered for SharedComponent { self.GetName() } event "{ args.eventName }"`)
		
		if #Handler.Validators > 0 or #args.arguments > 0 then
			
			local Success, ErrorMessage = Type.strictArray(table.unpack(Handler.Validators))(args.arguments)
			local ActualErrorMessage = `[{self.GetName()}]: Event  {args.eventName } failed argument validation. { ErrorMessage }`

			if not Success and RunService:IsStudio() then
				error(ActualErrorMessage)
				return
					
			elseif not Success then
				player:Kick(ActualErrorMessage)
				return
			end
		end

		for _, Callback in pairs(Handler.Callbacks) do
			if RunService:IsServer() then
				Callback(player, table.unpack(args.arguments))
			else
				Callback(table.unpack(args.arguments))
			end
		end
	end
	
	self._SyncArgumentsEvent = self:CreateEvent("_Sync", "Reliable", function(...) return true end)
	self._InternalDestructionEvent = self:CreateEvent("_InternalDestructionEvent", "Reliable", function(...) return true end)
	
	if RunService:IsServer() then
		self.Janitor:Add(ServerRemotes.ReliableComponentNetworkServer.On(function(player, args)
			Connection(player, "Reliable", args)
		end))
		
		self.Janitor:Add(ServerRemotes.UnreliableComponentNetworkServer.On(function(player, args)
			Connection(player, "Unreliable", args)
		end))
		
		self.Janitor:Add(self._SyncArgumentsEvent.On(function(player: Player)
			
			local Data = {}

			for _, Field in ipairs(self._ConstructorOptions.Sync) do
				assert(typeof(Field) ~= "function", `Field cannot be method ({ Field })`)
				assert(typeof(Field) ~= "table" or not getmetatable(self[Field]), `Field cannot be table or class reference ({ Field })`)

				Data[Field] = self[Field]
			end

			self._SyncArgumentsEvent.Fire(player, Data)
		end))
		
	elseif RunService:IsClient() then
		
		self._ClientSyncing = false
		self._ClientSyncedOnce = false
		
		self.Janitor:Add(ClientRemotes.ReliableComponentNetworkClient.On(function(args)
			Connection(Player, "Reliable", args)
		end))
		
		self.Janitor:Add(ClientRemotes.UnreliableComponentNetworkClient.On(function(args)
			Connection(Player, "Unreliable", args)
		end))
		
		self.Janitor:Add(self._InternalDestructionEvent.On(function()
			self:Destroy()
		end))
		
		if options.SyncOnCreation and options.Sync then
			self:SyncClient()
		end
	end
end

function SharedComponent.SyncClient(self: Component)
	local Options = self._ConstructorOptions
	
	if self._ClientSyncing then
		warn(`{ self.GetName() } already syncing`)
		return
	end
	
	assert(not Options.SyncOnce or not self._ClientSyncedOnce, "Client already synced component " .. self.GetName())
	assert(Options.Sync, `Impossible to sync { self.GetName() } component with server without field list`)
	assert(#Options.Sync > 0, `Empty list of fields to sync provided for { self.GetName() } shared component`)
	
	self._ClientSyncing = true
	
	self.Janitor:Add(task.defer(function()
		self._SyncArgumentsEvent.Fire({ })
	end))

	self.Janitor:AddPromise(Promise.new(function(resolve, reject)
		local disconnected = false

		local disconnect = self._SyncArgumentsEvent.On(function(...)
			if disconnected then return end
			disconnected = true
			self.Janitor:Remove("ClientSyncOnEvent")
			resolve(...)
		end)

		self.Janitor:Add(disconnect, nil, "ClientSyncOnEvent")

		-- Fail-safe: если сервер не ответит — Reject
		self.Janitor:Add(task.delay(25, function()
			if disconnected then return end
			disconnected = true
			reject(`SyncClient timeout for component {self.GetName()}`)
		end))

		self._SyncArgumentsEvent.Fire({})
	end)
		:andThen(function(...)
			--print("syncing time", table.pack(...))
			self._ClientSyncing = false
			self._ClientSyncedOnce = true

			for Field, Value in pairs(...) do
				self[Field] = Value
			end
		end)
		:catch(function(err)
			warn(`[SharedComponent:SyncClient] Failed to sync "{self.GetName()}": {err}`)
		end)
	):await()
end

function SharedComponent.CreateEvent(self: Component, eventName: string, eventType: "Reliable" | "Unreliable", ...: Validator)
	assert(table.find({"Reliable", "Unreilable"}, eventType), `Event type should be Reliable or Unreliable. Got "{ eventType }"`)
	
	local Validators = { ... }
	self._SharedComponentCallbacks[eventType][eventName] = {
		Validators = Validators,
		Callbacks = {},
	}

	local function On(callback: (...any) -> ())
		table.insert(self._SharedComponentCallbacks[eventType][eventName].Callbacks, callback)

		return function()
			table.remove(
				self._SharedComponentCallbacks[eventType][eventName],
				table.find(self._SharedComponentCallbacks[eventType][eventName], callback)
			)
		end
	end

	local function ConstructArguments(...: any)
		return {
			eventName = eventName,
			instance = self.Instance,
			name = self.GetName(),
			arguments = table.pack(...),
		}
	end

	return RunService:IsServer()
			and {
				On = On,
				Fire = function(player: Player, ...)
					ServerRemotes[eventType .. "ComponentNetworkClient"].Fire(player, ConstructArguments(...))
				end,
				FireAll = function(...)
					ServerRemotes[eventType .. "ComponentNetworkClient"].FireAll(ConstructArguments(...))
				end,
				FireExcept = function(player: Player, ...)
					ServerRemotes[eventType .. "ComponentNetworkClient"].FireExcept(player, ConstructArguments(...))
				end,
				FireList = function(players: { Player }, ...)
					ServerRemotes[eventType .. "ComponentNetworkClient"].FireList(players, ConstructArguments(...))
				end,
				FireSet = function(players: { [Player]: true }, ...)
					ServerRemotes[eventType .. "ComponentNetworkClient"].FireSet(players, ConstructArguments(...))
				end,
			}
		or {
			On = On,
			Fire = function(...: any)
				ClientRemotes[eventType .. "ComponentNetworkServer"].Fire(ConstructArguments(...))
			end,
		}
end

function SharedComponent.OnDestroy(self: Component)
	
	if RunService:IsServer() then
		
		self._InternalDestructionEvent.FireAll(true)
		
		Classes.GetSingleton("ComponentReplicator")
			:PromptDestroy(self, PlayerService:GetLoadedPlayerList())
	end
end

--//Main

--void callbacks (to mute output warns)
if RunService:IsClient() then
	
	ClientRemotes.ReliableComponentNetworkClient.On(function()
	end)

	ClientRemotes.UnreliableComponentNetworkClient.On(function()
	end)
end

--//Returner

return SharedComponent