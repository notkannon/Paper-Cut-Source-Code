--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Promise = require(ReplicatedStorage.Packages.Promise)

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseItem = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local FallDamageService = require(ReplicatedStorage.Shared.Services.FallDamageService)

--//Variables

local BaseConsumable = BaseComponent.CreateComponent("BaseConsumable", {
	
	isAbstract = true,
	
	defaults = {
		Used = false,
		InUse = false,
	},
	
}, BaseItem) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseItem.MyImpl)),
	
	Cancel: (self: Component) -> (),
	OnUseServer: (self: Component) -> (),
	OnUseClient: (self: Component) -> (),
	OnCancelServer: (self: Component) -> (),
	BeforeUseServer: (self: Component) -> (),
}

export type Fields = {
	
	LimitHealth: number,
	UseDelay: number,
	DestroyOnUse: boolean,
	IgnoreClientUsage: boolean,
	RespectExternaInfluences: boolean,
	
	Attributes: {
		Used: boolean,
		InUse: boolean,
		UseDelay: number,
		AttributeChanged: Signal.Signal<string, unknown>,
	},
	
	UseServerRequest: SharedComponent.ServerToClient,
	UsageCancelRequest: SharedComponent.ClientToServer,
	UseClientCallbackEvent: SharedComponent.ClientToServer,
	
} & BaseItem.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, Tool, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, string, Tool, {}>

--//Methods

function BaseConsumable.ShouldStart(self: Component)
	return not self.Attributes.Used
		and not self.Attributes.InUse
end

--@override
function BaseConsumable.OnUseServer(self: Component) end
--@override
function BaseConsumable.OnUseClient(self: Component) end
--@override
function BaseConsumable.BeforeUseServer(self: Component) end
--@override
function BaseConsumable.OnCancelServer(self: Component) end


function BaseConsumable.Cancel(self: Component)
	
	--oop :D
	if not self.Attributes.InUse
		or self.Attributes.Used then
		
		return
	end
	
	if RunService:IsClient() then
		
		self.UsageCancelRequest.Fire()
		
	elseif RunService:IsServer() then

		self.EquipJanitor:RemoveList(
			"UseThread",
			"DamageListener",
			"FallListener"
		)

		self.Attributes.InUse = false
		
		self:OnCancelServer()
	end
end

function BaseConsumable.OnStartServer(self: Component)
	
	--imports
	local MatchService = Classes.GetSingleton("MatchService")

	--already using
	if self.Attributes.InUse then
		return
	end
	
	--debounce
	self.Attributes.InUse = true
	
	--restoring debounce
	self.EquipJanitor:Add(function()
		self.Attributes.InUse = false
	end)

	--syntax sugar
	local function Use()
		
		--notify client about usage start on sever
		self.Attributes.Used = true
		self.UseServerRequest.Fire(self.Player)
		
		self:OnUseServer()
		
		--if callback wasnt received
		if not self.IgnoreClientUsage then
			
			--stop listening client callback and yielding code for it
			self.Janitor:Remove("ClientCallbackPromise")
			self.Janitor:AddPromise(
				
				Promise.new(function(resolve)
					
					local Disconnect
					
					Disconnect = self.UseClientCallbackEvent.On(function(player)
						Disconnect()
						resolve()
					end)
					
				end)
					:timeout(0.1)
					:catch(function()
						if self.DestroyOnUse then
							self:Destroy()
						end
					end),
				
				nil,
				
				"ClientCallbackPromise"
				
			):await()
		end
		
		if self.DestroyOnUse then
			self:Destroy()
			return
		end
		
		--reset state of usage
		self.Attributes.Used = false
		
		--removing promise
		self.EquipJanitor:Remove("ClientCallbackPromise")
	end

	--usage
	
	self:BeforeUseServer()
	
	--delay handling
	if self.UseDelay > 0 then

		--if item will be unequipped then usage will be cancelled

		--if any interaction can affect character during usage
		if self.RespectExternaInfluences then

			--any dealed damage
			self.EquipJanitor:Add(MatchService.PlayerDamaged:Connect(function(player)
				if player == self.Player then
					self:Cancel()
				end
			end), nil, "DamageListener")

			--when player falls
			self.EquipJanitor:Add(FallDamageService.FallStarted:Connect(function(player)
				if player == self.Player then
					self:Cancel()
				end
			end), nil, "FallListener")
		end
		
		--delayed usage
		self.EquipJanitor:Add(
			task.delay(self.UseDelay, Use),
			nil,
			"UseThread"
		)
	else
		Use()
	end
end

function BaseConsumable.OnConstructServer(self: Component)
	BaseItem.OnConstructServer(self)
	
	--cancellation callback handler
	self.Janitor:Add(self.UsageCancelRequest.On(function(player)
		self:Cancel()
	end))
end

function BaseConsumable.OnConstructClient(self: Component)
	BaseItem.OnConstructClient(self)
	
	--usage on client
	self.Janitor:Add(self.UseServerRequest.On(function()
		
		--notify server about success usage
		self.UseClientCallbackEvent.Fire()
		
		self:OnUseClient()
	end))
end

function BaseConsumable.OnConstruct(self: Component, ...)
	BaseItem.OnConstruct(self, ...)
	
	self.LimitHealth = false
	self.UseDelay = 0 --determines delay before use
	self.DestroyOnUse = true
	self.IgnoreClientUsage = false
	self.RespectExternaInfluences = true --kinda cancel InUse state on player damage or etc.
	
	--when item being Used, server notify client he can locally use the item.
	self.UseServerRequest = self:CreateEvent("UseServerRequest", "Reliable")
	
	--used from client to try to cancel usage (somehow)
	self.UsageCancelRequest = self:CreateEvent("UsageCancelRequest", "Reliable")
	
	--when client done using his item then he notify server about usge is finished (should be promised with timeout)
	self.UseClientCallbackEvent = self:CreateEvent("UseClientCallbackEvent", "Reliable")
end

--//Returner

return BaseConsumable