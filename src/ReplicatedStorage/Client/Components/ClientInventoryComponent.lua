--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Roles = require(ReplicatedStorage.Shared.Data.Roles)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseItem = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local LocalPlayer = Players.LocalPlayer
local PlayerController

local InventoryComponent = BaseComponent.CreateComponent("ClientInventoryComponent", {
	
	tag = "Inventory",
	
	predicate = function(instance: Backpack)
		return LocalPlayer.Backpack == instance
	end,
	
}) :: Impl

--//Types

type InventorySlot = {
	Index: number,
	Instance: Tool?,
	Component: BaseComponent.Component?,
	Connections: { [string]: RBXScriptConnection? }
}

export type MyImpl = {
	__index: MyImpl,
	
	ToolIsMember: (self: Component, tool: Tool) -> boolean,
	ToolIsParented: (self: Component, tool: Tool) -> boolean,
	
	GetEquippedItem: (self: Component) -> Tool?,
	GetSlotFromIndex: (self: Component, index: number) -> InventorySlot?,
	GetSlotsWithItems: (self: Component) -> { InventorySlot? },
	GetSlotFromInstance: (self: Component, instance: Tool) -> InventorySlot?,
	GetEquippedItemComponent: (self: Component) -> BaseItem.Component?,
	
	Drop: (self: Component, InventorySlot) -> (),
	Equip: (self: Component, InventorySlot) -> (),
	UnequipAll: (self: Component) -> (),

	Add: (self: Component, Tool: Tool) -> (),
	Remove: (self: Component, Tool: Tool) -> (),
	RemoveAll: (self: Component) -> (),
	
	_InitSlots: (self: Component) -> (),
	_InitSignals: (self: Component) -> (),
	_InitEventConnections: (self: Component) -> (),
	_InitBackpackConnections: (self: Component) -> (),
}

export type Fields = {
	
	Enabled: boolean,
	
	Slots: { InventorySlot },
	Instance: Backpack?,
	InputDelay: number,
	
	Toggled: Signal.Signal<boolean>,
	ItemAdded: Signal.Signal<number, Tool, { unknown }?>,
	ItemRemoved: Signal.Signal<number, Tool, { unknown }?>,
	ItemEquipped: Signal.Signal<number, Tool>,
	ItemUnequipped: Signal.Signal<number, Tool>,
	ItemStateChanged: Signal.Signal<number, Tool>,
	
	CharacterComponent: { any },
	
	_Enabled: boolean,
	_LastInputTime: number,
	_LastTimeEquipped: number,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ClientInventoryComponent", Backpack, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "ClientInventoryComponent", Backpack, {}>

--//Methods

function InventoryComponent.GetSlotsWithItems(self: Component)
	local Slots = {}
	
	for _, Slot in ipairs(self.Slots) do
		if Slot.Instance then
			table.insert(Slots, Slot)
		end
	end
	
	return Slots
end

function InventoryComponent.ToolIsParented(self: Component, tool: Tool)
	return tool and (tool:IsDescendantOf(self.Instance)
		or tool:IsDescendantOf(self.CharacterComponent.Instance))
end

function InventoryComponent.ToolIsMember(self: Component, tool: Tool)
	
	for _, Slot in ipairs(self.Slots) do
		if Slot.Instance == tool then
			return true
		end
	end
	
	return false
end

function InventoryComponent.GetEquippedItemComponent(self: Component)
	
	local Tool = self:GetEquippedItem()
	
	if not Tool then
		return
	end
	
	return ComponentsManager.Get(Tool, Tool:GetAttribute("Impl"))
end

function InventoryComponent.GetEquippedItem(self: Component)
	return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool") or nil
end

function InventoryComponent.GetSlotEquipped(self: Component)
	
	local Instance: Tool? = self:GetEquippedItem()
	
	if not Instance then
		return
	end

	for _, Slot: InventorySlot in ipairs(self.Slots) do
		
		if Slot.Instance ~= Instance then
			continue
		end

		return Slot
	end
end

function InventoryComponent.GetSlotFromIndex(self: Component, index: number)
	assert(typeof(index) == "number", "Wrong index type passed")

	for _, Slot: InventorySlot in ipairs(self.Slots) do
		
		if Slot.Index ~= index then
			continue
		end

		return Slot
	end
end

function InventoryComponent.GetSlotFromInstance(self: Component, instance: Tool)
	
	for _, Slot: InventorySlot in ipairs(self.Slots) do
		
		if Slot.Instance ~= instance then
			continue
		end

		return Slot
	end
end

function InventoryComponent.Add(self: Component, instance: Tool)
	
	if self:ToolIsMember(instance) then
		
		warn(`Attempted to add { instance.Name } to inventory, but item is already member of it`)
		
		return
	end
	
	for _, Slot in ipairs(self.Slots) do
		
		if Slot.Instance then
			continue
		end
		
		local Component = ComponentsManager.Await(instance, instance:GetAttribute("Impl")):expect()
		
		Slot.Instance = instance
		Slot.Component = Component
		
		self.ItemAdded:Fire(Slot.Index, Slot.Instance, Component.Data)
		
		Slot.Connections.Equipped = self.Janitor:Add(instance.Equipped:Connect(function()
			self.ItemEquipped:Fire(Slot.Index, Slot.Instance)
		end))
		
		Slot.Connections.Unequipped = self.Janitor:Add(instance.Unequipped:Connect(function()
			self.ItemUnequipped:Fire(Slot.Index, Slot.Instance)
		end))
		
		Slot.Connections.Changed = self.Janitor:Add(Component.StateChanged:Connect(function()
			self.ItemStateChanged:Fire(Slot.Index, Slot.Instance)
		end))
		
		return
	end
end

function InventoryComponent.Remove(self: Component, instance: Tool)
	
	local Slot = self:GetSlotFromInstance(instance)
	
	if not Slot then
		return
	end
	
	self.ItemRemoved:Fire(Slot.Index, Slot.Instance, Slot.Component.Data)
	
	Slot.Instance = nil
	Slot.Component = nil
	
	for _, Connection: RBXScriptConnection in pairs(Slot.Connections) do
		Connection:Disconnect()
	end
	
	table.clear(Slot.Connections)
end

function InventoryComponent.RemoveAll(self: Component)
	
	for _, slot in ipairs(self.Slots) do
		
		if slot.Instance then
			
			self:Remove(slot.Instance)
		end
	end
end

function InventoryComponent.Equip(self: Component, slot: InventorySlot)
	
	if not self._Enabled then
		return
	end
	
	local Tool = slot.Instance :: Tool?
	
	if not Tool or Tool == self:GetEquippedItem() then
		return
	end
	
	if os.clock() - self._LastInputTime < self.InputDelay then
		return
	end
	
	self._LastInputTime = os.clock()
	self._LastTimeEquipped = os.clock()
	
	LocalPlayer.Character
		:FindFirstChildWhichIsA("Humanoid")
		:EquipTool(Tool)
end

function InventoryComponent.UnequipAll(self: Component)
	
	if not self._Enabled then
		return
	end
	
	if os.clock() - self._LastInputTime < self.InputDelay then
		return
	end

	self._LastInputTime = os.clock()
	
	LocalPlayer.Character
		:FindFirstChildWhichIsA("Humanoid")
		:UnequipTools()
end

function InventoryComponent.Drop(self: Component, slot: InventorySlot?)
	
	if not self._Enabled then
		return
	end
	
	local ItemEquipped = slot and slot.Instance or self:GetEquippedItem()
	
	if not ItemEquipped then
		return
	end
	
	if self:GetEquippedItem() == ItemEquipped then
		self:UnequipAll()
	end
	
	ClientRemotes.InventoryComponentDropItemServer.Fire(ItemEquipped)
end

function InventoryComponent._InitSlots(self: Component)
	--TODO: use MaxSlots value further
	for x = 1, 3 do
		table.insert(self.Slots, {
			Index = x,
			Instance = nil,
			Connections = {}
		})
	end
end

function InventoryComponent._InitSignals(self: Component)
	
	self.Toggled = self.Janitor:Add(Signal.new())
	self.ItemAdded = self.Janitor:Add(Signal.new())
	self.ItemRemoved = self.Janitor:Add(Signal.new())
	self.ItemEquipped = self.Janitor:Add(Signal.new())
	self.ItemUnequipped = self.Janitor:Add(Signal.new())
	self.ItemStateChanged = self.Janitor:Add(Signal.new())
end

function InventoryComponent.OnConstructClient(self: Component)
	
	self.Slots = {}
	self.InputDelay = 1/20
	
	self._Enabled = true
	self._LastInputTime = 0
	self._LastTimeEquipped = 0

	self:_InitSlots()
	self:_InitSignals()
	
	--collecting items already placed into inventory
	for _, ItemInstance: Tool? in ipairs(self.Instance:GetChildren()) do

		local ImplString = ItemInstance:GetAttribute("Impl")

		if not ItemInstance:IsA("Tool") or not ImplString then
			continue
		end
		
		--thread thing cuz sometimes dont work
		self.Janitor:Add(task.spawn(function()
			
			if not ComponentsManager.Get(ItemInstance, ImplString) then
				ComponentsManager.Add(ItemInstance, ImplString)
			end

			self:Add(ItemInstance)
		end))
	end
end

function InventoryComponent.OnDestroy(self: Component)
	--yes but this its doesnt execute :skull: BRUH
	--thats why items stay
	self:RemoveAll()
	self.Janitor:Cleanup()
end

--//Main

-- server component toggle connection
ClientRemotes.OnServerInventoryToggle.SetCallback(function(enabled)
	
	local Inventory = ComponentsManager.Get(LocalPlayer.Backpack, InventoryComponent) :: Component?
	
	if not Inventory then
		return
	end
	
	Inventory._Enabled = enabled
	Inventory.Toggled:Fire(enabled)
end)

-- server item component creation/destruction
ComponentsManager.ComponentAdded:Connect(function(component)
	
	local Inventory = ComponentsManager.Get(LocalPlayer.Backpack, InventoryComponent) :: Component?
	
	if not Inventory or not Classes.InstanceOf(component, BaseItem) then
		return
	end
	
	Inventory:Add(component.Instance)
end)

ComponentsManager.ComponentRemoved:Connect(function(component, instance)
	
	local Inventory = ComponentsManager.Get(LocalPlayer.Backpack, InventoryComponent) :: Component?
	
	if not Inventory or not Inventory:GetSlotFromInstance(instance) then
		return
	end

	Inventory:Remove(instance)
end)

--used to fully sync item component existing on client
ClientRemotes.ReplicateItemServer.SetCallback(function(args)
	
	local Inventory = ComponentsManager.Get(LocalPlayer.Backpack, InventoryComponent) :: Component?
	local ItemComponent = ComponentsManager.Get(args.instance, args.constructor)
	
	if args.destroyed then
		
		if not ItemComponent then
			return
		end
		
		ComponentsManager.Remove(args.instance, args.constructor)
		
	elseif not ItemComponent then
		
		ComponentsManager.Add(args.instance, args.constructor)
	end
end)

--//Returner

return InventoryComponent