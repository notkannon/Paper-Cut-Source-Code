--//Services

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Promise = require(ReplicatedStorage.Packages.Promise)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil
local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil
local PlayersService = RunService:IsServer() and require(ServerScriptService.Server.Services.PlayerService) or nil

--//Variables

local ComponentReplicator: Impl = Classes.CreateSingleton("ComponentReplicator") :: Impl

--//Types

export type Impl = {
	__index: Impl,

	IsImpl: (self: Service) -> boolean,
	GetName: () -> "ComponentReplicator",
	GetExtendsFrom: () -> nil,
	
	PromptCreate: (self: Service, component: SharedComponent.Component, players: { Player }, ...any) -> (),
	PromptDestroy: (self: Service, component: SharedComponent.Component, players: { Player }) -> (),
	
	new: () -> Service,
	OnConstruct: (self: Service) -> (),
	OnConstructServer: (self: Service) -> (),
	OnConstructClient: (self: Service) -> (),
}

export type Fields = {
	Components: { SharedComponent.Component? }
}

export type Service = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Function

local function GetPlayersSet(source: { Player })
	
	local PlayersSet = {}

	for _, Player in ipairs(source) do

		if table.find(PlayersSet, Player) then
			continue
		end

		table.insert(PlayersSet, Player)
	end
	
	return PlayersSet
end

--//Methods

function ComponentReplicator.PromptCreate(self: Service, component: SharedComponent.Component, players: { Player }, ...: any?)
	assert(RunService:IsServer())
	
	ServerRemotes.ComponentReplicatorClient.FireList(
		
		GetPlayersSet(players), {
			
			name = component.GetName(),
			instance = component.Instance,
			destroyed = false,
			constructorArgs = {...},
		}
	)
end

function ComponentReplicator.PromptDestroy(self: Service, component: SharedComponent.Component, players: { Player })
	assert(RunService:IsServer())
	
	--we're already destroyed instance on server, so we can stop car about client destruction
	if not component.Instance then
		return
	end
	
	ServerRemotes.ComponentReplicatorClient.FireList(
		
		GetPlayersSet(players), {
			
			name = component.GetName(),
			instance = component.Instance,
			destroyed = true
		}
	)
end

function ComponentReplicator.OnConstructClient(self: Service)
	
	ClientRemotes.ComponentReplicatorClient.SetCallback(function(args)
		
		local Existing = ComponentsManager.Get(args.instance, args.name)

		if args.destroyed then
			
			if Existing then
				ComponentsManager.Remove(args.instance, args.name)
			end
			
		else
			
			if Existing then
				warn(`Shared component "{ Existing.GetName() }" already exists on client`)
				return
			end

			assert(args.instance, `Tried to create a client shared component "{ args.name }" without access to Instance`)

			ComponentsManager.Add(args.instance, args.name, table.unpack(args.constructorArgs))
		end
	end)
end

--[[
function ComponentReplicator.OnConstruct(self: Service)
	self.Components = {}
end

function ComponentReplicator.OnConstructServer(self: Service)
	local function HandleSharedComponentCreated(component: SharedComponent.Component)
		if not table.find(ComponentsManager.GetAllExtendsFrom(component), "SharedComponent") then
			return
		end
		
		table.insert(self.Components, component)
		
		-- sending to existing players who already synced objects
		ServerRemotes.ComponentReplicatorClient.FireList(PlayersService:GetLoadedPlayerList(), {
			name = component:GetName(),
			instance = component.Instance
		})
	end
	
	-- getting request to get info about already created components
	ServerRemotes.ComponentReplicatorServer.SetCallback(function(player: Player)
		for _, Component in ipairs(self.Components) do
			ServerRemotes.ComponentReplicatorClient.Fire(player, {
				name = Component:GetName(),
				instance = Component.Instance
			})
		end
	end)
	
	ComponentsManager.ComponentAdded:Connect(function(component)
		HandleSharedComponentCreated(component)
	end)
	
	ComponentsManager.ComponentRemoved:Connect(function(component)
		local Index = table.find(self.Components, component)
		
		if not Index then
			return
		end
		
		table.remove(self.Components, Index)
	end)
	
	for _, component in ipairs(ComponentsManager.ListAll()) do
		HandleSharedComponentCreated(component)
	end
end]]

--//Returner

local Singleton = ComponentReplicator.new()
return Singleton