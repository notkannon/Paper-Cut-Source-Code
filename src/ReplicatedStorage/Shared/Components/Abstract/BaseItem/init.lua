--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)

local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Utility = require(ReplicatedStorage.Shared.Utility)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local ItemsData = require(ReplicatedStorage.Shared.Data.Items)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local Interaction = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)

local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil
local HighlightItem = require(ReplicatedStorage.Shared.Effects.HighlightItem)

--//Variables

local LocalPlayer = Players.LocalPlayer
local BaseItem = BaseComponent.CreateComponent("BaseItem", {
	
	isAbstract = true,
	
	defaults = {
		Cooldowned = false,
		CooldownDuration = 0,
	},
	
	predicate = function(instance)
		if RunService:IsClient()
			and not instance:IsDescendantOf(LocalPlayer)
			and not instance:IsDescendantOf(LocalPlayer.Character) then
			
			return
		end
		
		return instance:IsA("Tool")
	end,
	
}, SharedComponent) :: Impl

--//Types

export type ItemAttributes = {
	Cooldowned: boolean,
	CooldownDuration: number,
	AttributeChanged: Signal.Signal<string, unknown>,
}

export type ItemState = {
	Cooldowned: boolean,
	CooldownDuration: number,
}

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: SharedComponent.MyImpl)),
	
	SetEnabled: (self: Component, enabled: boolean) -> (),
	CreateEvent: SharedComponent.CreateEvent<Component>,
	
	GetOwner: (self: Component) -> Player?,
	GetState: (self: Component) -> ItemState,
	GetInventory: (self: Component) -> unknown?,

	ShouldStart: (self: Component) -> boolean,
	ResetCooldown: (self: Component) -> (),
	ApplyCooldown: (self: Component, cooldown: number) -> (),
	
	OnDrop: (self: Component, origin: Vector3, direction: Vector3) -> (),

	OnEquipServer: (self: Component) -> (),
	OnEquipClient: (self: Component) -> (),

	OnStartServer: (self: Component) -> (),
	OnStartClient: (self: Component) -> (),
	OnAssumeStartClient: (self: Component) -> (),

	OnUnequipServer: (self: Component) -> (),
	OnUnequipClient: (self: Component) -> (),

	OnEndServer: (self: Component) -> (),
	OnEndClient: (self: Component) -> (),
	
	_OnInventoryChanged: (self: Component, inventory: unknown) -> (),
	_InitInstanceConnections: (self: Component) -> (),
	_CheckInventoryCapability: (self: Component, ignoreEnabled: boolean?) -> boolean,
	_AttachEffect: (self: Component) -> HighlightItem.Effect,
}

export type Fields = {
	
	Player: Player,
	Handle: BasePart,
	Character: Model,
	
	Attributes: ItemAttributes,
	
	Interaction: Interaction.Component,
	EquipJanitor: Janitor.Janitor,
	ActiveJanitor: Janitor.Janitor,
	ConstructorData: any,
	
	Data: Types.ItemData,
	Active: boolean,
	Equipped: boolean,
	
	StateChanged: Signal.Signal<ItemState>,
	InventoryChanged: Signal.Signal<unknown>,
	
	_Inventory: unknown, -- component
	_InternalStartEvent: SharedComponent.ServerToClient,
	
} & SharedComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, Tool, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, string, Tool, {}>

--//Methods

--@override
function BaseItem.ShouldStart(self: Component)
	return true
end

--@override
function BaseItem.OnEquipServer(self: Component) end
--@override
function BaseItem.OnUnequipServer(self: Component) end
--@override
function BaseItem.OnStartServer(self: Component) end
--@override
function BaseItem.OnEndServer(self: Component) end

--@override
function BaseItem.OnAssumeStartClient(self: Component) end
--@override
function BaseItem.OnEquipClient(self: Component) end
--@override
function BaseItem.OnUnequipClient(self: Component) end
--@override
function BaseItem.OnStartClient(self: Component) end
--@override
function BaseItem.OnEndClient(self: Component) end


function BaseItem._CheckInventoryCapability(self: Component, ignoreEnabled: boolean?)
	if RunService:IsClient() then
		return true
	end
	
	return self._Inventory and (ignoreEnabled or self._Inventory.Enabled)
end

function BaseItem.GetInventory(self: Component)
	return self._Inventory
end

function BaseItem.ApplyCooldown(self: Component, cooldown: number)
	
	assert(not self.Attributes.Cooldowned, "Cannot apply cooldown for item because its already cooldowned")
	assert(typeof(cooldown) == "number", "Cooldown should be positive number")
	assert(cooldown > 0, "Cooldown should be > 0")
	
	self.Attributes.CooldownDuration = cooldown
	self.Attributes.Cooldowned = true
	
	self:SetEnabled(false)
	
	self.Janitor:Remove("CooldownTask")
	self.Janitor:Add(task.delay(cooldown, function()
		
		self:SetEnabled(true)
		
		self.Attributes.Cooldowned = false
		self.Attributes.CooldownDuration = 0
		
	end), nil, "CooldownTask")
end

function BaseItem.SetEnabled(self: Component, enabled: boolean)
	assert(typeof(enabled) == "boolean")
	self.Instance.Enabled = enabled
end

function BaseItem.GetState(self: Component)
	return {
		Cooldowned = self.Attributes.Cooldowned,
		CooldownDuration = self.Attributes.CooldownDuration,
	} :: ItemState
end

function BaseItem.GetOwner(self: Component)
	return self._Inventory and self._Inventory.Instance.Parent or nil
end

function BaseItem._OnInventoryChanged(self: Component, inventory: unknown, dropped: boolean?)
	assert(RunService:IsServer())
	
	if inventory then
		
		self.Interaction:SetEnabled(false)
		
		self.Instance.Parent = inventory.Instance
		self.Handle.CanCollide = false
		self.Handle.Anchored = false
		
		self.Player = inventory.Player
		self.Character = self.Player.Character
		
		self._Inventory = inventory
		
		--request to create item on client
		ServerRemotes.ReplicateItemServer.Fire(inventory.Player, {
			constructor = self.GetName(),
			destroyed = false,
			instance = self.Instance,
		})
		
		self.Janitor:Remove("HighlightEffect")
	else
		
		--request to remove item from client
		ServerRemotes.ReplicateItemServer.Fire(self.Player, {
			constructor = self.GetName(),
			destroyed = true,
			instance = self.Instance,
		})

		if self:IsDestroying()
			or self:IsDestroyed() then
			
			return
		end

		self.Player = nil
		self.Character = nil
		self._Inventory = nil
		
		self.Handle.CanCollide = true
		self.Instance.Parent = ServerStorage

		self.ActiveJanitor:Cleanup()
		self.EquipJanitor:Cleanup()
		self.Interaction:SetEnabled(true)
		
		if dropped then self:_AttachEffect() end
	end
	
	self.InventoryChanged:Fire(inventory)
end

function BaseItem._AttachEffect(self: Component)
	print(self.Instance, RunService:IsServer(), self.Instance:FindFirstChildWhichIsA("BasePart"), self.Handle)
	local Effect = self.Janitor:Add(HighlightItem.new(self.Instance), "Destroy", "HighlightEffect")
	--print(Effect)
	Effect:Start(Players:GetPlayers())
	return Effect
end

function BaseItem._InitInstanceConnections(self: Component)
	
	local RunContext = 
		(RunService:IsServer() and "Server")
		or (RunService:IsClient() and "Client")
	
	self.Janitor:Add(self.Instance.Equipped:Connect(function()
		
		if not self:_CheckInventoryCapability() then
			
			self.Character.Humanoid:UnequipTools()
			
			return
		end
		
		self.Equipped = true
		self["OnEquip" .. RunContext](self)
	end))

	self.Janitor:Add(self.Instance.Unequipped:Connect(function()
		
		if not self:_CheckInventoryCapability(true) then
			return
		end
		
		if self.Active then
			self.Active = false
			
			self.ActiveJanitor:Cleanup()
			self["OnEnd" .. RunContext](self)
		end
		
		self.Equipped = false
		self["OnUnequip" .. RunContext](self)
		self.EquipJanitor:Cleanup()
	end))
	
	self.Janitor:Add(self.Instance.Activated:Connect(function()
		
		if self.Active
			or self.Attributes.Cooldowned
			or not self:_CheckInventoryCapability()
			or not self:ShouldStart() then

			self.Instance:Deactivate()
			
			return
		end
		
		self.Active = true

		if RunService:IsServer() then
			
			self._InternalStartEvent.Fire(self:GetOwner())
			self:OnStartServer()
			
		elseif RunService:IsClient() then
			
			--waiting for server started event
			self.ActiveJanitor:Add(
				self._InternalStartEvent.On(function()

					self.ActiveJanitor:Remove("StartEventListener")
					
					if self.Active then
						return
					end
					
					self.Active = true
					self:OnStartClient()
				end),
				
				nil,
				"StartEventListener"
			)
			
			self:OnAssumeStartClient()
		end
	end))

	self.Janitor:Add(self.Instance.Deactivated:Connect(function()
		
		if not self.Active or not self:_CheckInventoryCapability(true) then
			return
		end
		
		self.Active = false
		self.ActiveJanitor:Cleanup()
		self["OnEnd" .. RunContext](self)
	end))
	
	self.Janitor:Add(self.Attributes.AttributeChanged:Connect(function(attribute, value)
		if attribute == "Cooldowned" then
			self.StateChanged:Fire(self:GetState())
		end
	end))
end

function BaseItem.OnConstruct(self: Component, ... )
	local Args = table.pack(...)
	SharedComponent.OnConstruct(self)
	local doEffect: boolean? = Args[1]
	
	if RunService:IsServer() then
		self.Instance.Parent = ServerStorage
	end
	
	local Handle: BasePart? = self.Instance:FindFirstChildWhichIsA("BasePart")
	assert(Handle, `Handle part doesn't exist in item { self:GetName() }`)
	
	local DataKeyFromConstructor = self.GetName():sub(1, -5)
	
	getmetatable(self).ConstructorData = ItemsData[ DataKeyFromConstructor ]
	assert(self.ConstructorData, `Data doesn't exists for item { self:GetName() }. Register data with "{ DataKeyFromConstructor }" key`)
	
	self.Data = table.clone(self.ConstructorData)
	self.Handle = Handle
	self.Active = false
	self.Equipped = false
	self.EquipJanitor = self.Janitor:Add(Janitor.new())
	self.ActiveJanitor = self.Janitor:Add(Janitor.new())
	self.StateChanged = self.Janitor:Add(Signal.new())
	self.InventoryChanged = self.Janitor:Add(Signal.new())
	
	self._InternalStartEvent = self:CreateEvent("Started", "Reliable")
	
	self:_InitInstanceConnections()
	
	-- interaction initials
	if RunService:IsServer() then
		
		Handle.CanTouch = false
		Handle.CanCollide = true
		Handle.CollisionGroup = "Items"
		
		for _, BasePart in ipairs(self.Instance:GetDescendants()) do
			
			if not BasePart:IsA("BasePart") or BasePart == Handle then
				continue
			end

			BasePart.CanCollide = false
			Handle.CollisionGroup = "Items"
		end
		
		if Handle:FindFirstChildOfClass("ProximityPrompt") then
			Handle:FindFirstChildOfClass("ProximityPrompt"):Destroy()
		end
		
		local ProximityPrompt = Instance.new("ProximityPrompt")
		
		Utility.ApplyParams(ProximityPrompt, {
			Name = "Interaction",
			Parent = Handle,
			ActionText = "Pick Up",
			HoldDuration = 0,
			KeyboardKeyCode = Enum.KeyCode.E,
			MaxActivationDistance = 7,
			RequiresLineOfSight = false
		} :: ProximityPrompt)
		
		ProximityPrompt:AddTag("Interaction")
		
		print(self.Instance, Args, doEffect)
		--if doEffect then self.Janitor:Add(task.delay(.2, function() self:_AttachEffect() end)) end -- doesnt work without delay HELP
		
		if doEffect then
			print("Effect")
			self.Janitor:Add(task.spawn(function()
				task.wait(0.21)
				self:_AttachEffect()
			end))
		end
	end
	
	local ProximityPrompt = Handle:FindFirstChildOfClass("ProximityPrompt")
	self.Interaction = self.Janitor:AddPromise(ComponentsManager.Await(ProximityPrompt, "Interaction")):expect()
end

function BaseItem.OnConstructClient(self: Component)
	
	self.Player = LocalPlayer
	self.Character = LocalPlayer.Character
end

function BaseItem.OnConstructServer(self: Component)
	
	self.Handle.CollisionGroup = "Items"
	
	self.Interaction:SetFilteringType("Include")
	self.Interaction:SetTeamAccessibility("Student", true)
end

function BaseItem.OnDestroy(self: Component)
	
	self.Janitor:Cleanup()
	
	if self._Inventory then
		self._Inventory:UnequipAll()
		self._Inventory:Remove(self)
	end
	
	if not RunService:IsServer() then
		return
	end
	
	if self.Interaction then
		self.Interaction:Destroy()
		self.Interaction = nil
	end
	
	if self.Instance then
		self.Instance:Destroy()
	end
end

--//Returner

return BaseItem