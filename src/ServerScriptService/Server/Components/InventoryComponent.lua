--TODO: BaseInventory component

--//Services

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseItem = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local ItemService = require(ServerScriptService.Server.Services.ItemService)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ServerRemotes = require(ServerScriptService.Server.ServerRemotes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

--//Constants

local RESTRICTED_STATUS_EFFECT_NAMES = {
	
	"Hidden",
	"HidddenComing",
	"HiddenLeaving",
	
	--medic specific
	"Healing",
	
	--misc
	"Downed",
	"Stunned",
	"Handled",
	"Ragdolled",
	"HarpoonPierced",
	"MarkedForDeath",
	"FallDamageSlowed",
}

local RESTRICTED_SKILL_NAMES = {
	
	--Student
	
	--troublemaker specific
	"Swing",
}

--//Variables

local Inventory = BaseComponent.CreateComponent("InventoryComponent") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
	
	GetEquippedItem: (self: Component) -> BaseItem.Component?,
	
	IsMember: (self: Component, item: Tool? | BaseItem.Component) -> boolean,
	IsMaxSlots: (self: Component) -> boolean,
	
	_SetEnabled: (self: Component, enabled: boolean) -> (),
	SetMaxSlots: (self: Component, maxSlots: number) -> (),

	Add: (self: Component, item: Tool? | BaseItem.Component, overstack: boolean?) -> (),
	Drop: (self: Component, item: Tool? | BaseItem.Component) -> (),
	Equip: (self: Component, item: Tool? | BaseItem.Component) -> (),
	Remove: (self: Component, item: Tool? | BaseItem.Component) -> (),
	RemoveAll: (self: Component) -> (),
	
	DropAll: (self: Component) -> (),
	UnequipAll: (self: Component) -> (),
	
	Cleanup: (self: Component) -> (),
	OnDestroy: (self: Component) -> (),
	OnConstructServer: (self: Component) -> (),
	
	_InitKeptInventoryItems: (self: Component) -> (),
	_InitBackpackConnections: (self: Component) -> (),
	_InitToggleConnections: (self: Component) -> (),
}

export type Fields = {
	
	Enabled: boolean,
	
	Player: Player,
	Character: Model,
	
	Items: { BaseItem.Component? },
	MaxSlots: number,
	Instance: Backpack,
	KeepInventory: boolean,
	SavedInventoryFolder: Folder,
	
	Toggled: Signal.Signal<boolean>,
	ItemAdded: Signal.Signal<Tool>,
	ItemRemoved: Signal.Signal<Tool>,
	ItemEquipped: Signal.Signal<Tool>,
	ItemUnequipped: Signal.Signal<Tool>,
	ItemDeactivated: Signal.Signal<Tool>,
	ItemActivated: Signal.Signal<Tool>,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "InventoryComponent", Backpack, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "InventoryComponent", Backpack, {}>

--//Functions

local function GetComponentFromItem(item: Tool? | BaseItem.Component): BaseItem.Component?
	
	if typeof(item) == "Instance" and item:IsA("Tool") then
		return ComponentsManager.GetFirstComponentInstanceOf(item, BaseItem) :: BaseItem.Component
		
	elseif typeof(item) == "table" and Classes.InstanceOf(item, BaseItem) then
		return item :: BaseItem.Component
	end
end

local function StrictCheckItemComponent(item: Tool? | BaseItem.Component)
	
	if typeof(item) == "Instance" then
		
		assert(item:IsA("Tool"), `Passed non-Tool Instance (Tool expected, got { item })`)
		
	elseif typeof(item) == "table" then
		
		assert(Classes.InstanceOf(item, BaseItem), `Passed non-Item component (BaseItem component nest required, got { tostring(item) or typeof(item) })`)
	end
	
	return GetComponentFromItem(item)
end

--//Methods

function Inventory._SetEnabled(self: Component, value: boolean)
	
	if self.Enabled == value then
		return
	end
	
	ServerRemotes.OnServerInventoryToggle.Fire(self.Player, value)
	
	if not value then
		self:UnequipAll()
	end
	
	self.Enabled = value
	self.Toggled:Fire(value)
end

function Inventory.GetEquippedItem(self: Component)
	for _, ItemComponent: BaseItem.Component in ipairs(self.Items) do
		if ItemComponent.Instance.Parent == self.Character then
			return ItemComponent
		end
	end
end

function Inventory.IsMember(self: Component, item: Tool? | BaseItem.Component)
	local item = GetComponentFromItem(item)
	return table.find(self.Items, item) and true or false
end

function Inventory.IsMaxSlots(self: Component)
	return #self.Items >= self.MaxSlots
end

function Inventory.SetMaxSlots(self: Component, maxSlots: number)
	self.MaxSlots = maxSlots
end

function Inventory.Equip(self: Component, item: Tool? | BaseItem.Component)
	
	local item = StrictCheckItemComponent(item)
	
	assert(self:IsMember(item), `Item { item } is not valid member of { self.Player }'s' Inventory`)

	local Humanoid = self.Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid?
	
	assert(Humanoid, `Humanoid doesn't exist for { self.Player.Name }'s character. Tool cannot be equipped.`)
	
	Humanoid:EquipTool(item.Instance)
end

function Inventory.UnequipAll(self: Component)
	if not self.Character then
		warn(`Character doesn't exist for { self.Player.Name }'s character. Tools cannot be unequipped.`)
		return
	end
	
	local Humanoid = self.Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid?
	
	assert(Humanoid, `Humanoid doesn't exist for { self.Player.Name }'s character. Tools cannot be unequipped.`)
	
	Humanoid:UnequipTools()
end

function Inventory.Drop(self: Component, item: Tool? | BaseItem.Component)
	
	local item = StrictCheckItemComponent(item)
	
	self:Remove(item, true)
	
	ItemService:HandleDropItem(item, self.Character.HumanoidRootPart.Position)
end

function Inventory.DropAll(self: Component)
	while #self.Items ~= 0 do
		self:Drop(self.Items[#self.Items])
	end
end

function Inventory.Add(self: Component, item: Tool? | BaseItem.Component, overstack: boolean?)
	
	local ItemComponent = StrictCheckItemComponent(item)
	
	if self:IsMaxSlots() then
		if not overstack then
			warn(`Attempted to add item { item.GetName() } to full { self.Player }'s' Inventory`)
		else
			ItemService:HandleDropItem(ItemComponent, self.Character.HumanoidRootPart.Position)
			ItemComponent:_AttachEffect()
			print('dropping overstacked item', ItemComponent.Instance)
		end
		return
	end
	
	local IsMember = self:IsMember(ItemComponent)
	
	if IsMember then
		warn(`Attempted to add item { ItemComponent.GetName() } that already was member of { self.Player.Name }'s' Inventory`)
		return
	end
	
	table.insert(self.Items, ItemComponent)
	
	ItemComponent:_OnInventoryChanged(self)
	
	self.ItemAdded:Fire(ItemComponent.Instance)
	
	--item connections
	
	local EquipConnection = self.Janitor:Add(
		ItemComponent.Janitor:Add(
			ItemComponent.Instance.Equipped:Connect(function()
				self.ItemEquipped:Fire(ItemComponent.Instance)
			end
			)
		)
	)
	
	local UnequipConnection = self.Janitor:Add(
		ItemComponent.Janitor:Add(
			ItemComponent.Instance.Unequipped:Connect(function()
				self.ItemUnequipped:Fire(ItemComponent.Instance)
			end
			)
		)
	)
	
	local ActivateConnection = self.Janitor:Add(
		ItemComponent.Janitor:Add(
			ItemComponent.Instance.Activated:Connect(function()
				self.ItemActivated:Fire(ItemComponent.Instance)
			end
			)
		)
	)
	
	local DeactivateConnection = self.Janitor:Add(
		ItemComponent.Janitor:Add(
			ItemComponent.Instance.Deactivated:Connect(function()
				self.ItemDeactivated:Fire(ItemComponent.Instance)
			end
			)
		)
	)
	
	local RemovedConnection: RBXScriptConnection
	
	--listening on item remove from inventory
	RemovedConnection = self.Janitor:Add(self.ItemRemoved:Connect(function(tool)
		
		if tool ~= ItemComponent.Instance then
			return
		end
		
		EquipConnection:Disconnect()
		UnequipConnection:Disconnect()
		RemovedConnection:Disconnect()
		ActivateConnection:Disconnect()
		DeactivateConnection:Disconnect()
		
		RemovedConnection = nil
		EquipConnection = nil
		UnequipConnection = nil
		ActivateConnection = nil
		DeactivateConnection = nil
	end))
end

function Inventory.Remove(self: Component, item: Tool? | BaseItem.Component, dropped: boolean?)
	
	local ItemComponent = StrictCheckItemComponent(item)
	local Index = self:IsMember(ItemComponent) and table.find(self.Items, ItemComponent)
	
	assert(Index, `Item { item } is not valid member of { self.Player }'s' Inventory`)
	
	table.remove(self.Items, Index)
	
	ItemComponent:_OnInventoryChanged(nil, dropped)
	
	self.ItemRemoved:Fire(ItemComponent.Instance)
end

function Inventory.RemoveAll(self: Component)
	while #self.Items ~= 0 do
		self:Remove(self.Items[#self.Items])
	end
end

function Inventory.Cleanup(self: Component)
	self:UnequipAll()
	
	for _, Item in ipairs(self.Items) do
		Item:Destroy()
	end
	
	table.clear(self.Items)
end

function Inventory._InitToggleConnections(self: Component)

	local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Character) :: WCS.Character

	local function HandleBackpackToggle()
		
		self:_SetEnabled(
			
			not WCSUtility.HasActiveStatusEffectsWithNames(WCSCharacter, RESTRICTED_STATUS_EFFECT_NAMES)
			and not WCSUtility.HasActiveSkillsWithName(WCSCharacter, RESTRICTED_SKILL_NAMES)
		)
	end
	
	self.Janitor:Add(WCSCharacter.SkillStarted:Connect(HandleBackpackToggle))
	self.Janitor:Add(WCSCharacter.SkillEnded:Connect(HandleBackpackToggle))
	
	self.Janitor:Add(WCSCharacter.StatusEffectStarted:Connect(HandleBackpackToggle))
	self.Janitor:Add(WCSCharacter.StatusEffectEnded:Connect(HandleBackpackToggle))
end

function Inventory._InitKeptInventoryItems(self: Component)

	local Folder = self.Player:FindFirstChild("SavedInventory") :: Folder?

	if not Folder then

		Folder = Instance.new("Folder")
		Folder.Parent = self.Player
		Folder.Name = "SavedInventory"
	end

	self.SavedInventoryFolder = Folder

	-- restoring items if exists
	for _, Tool: Tool? in ipairs(Folder:GetChildren()) do

		local ItemComponent = GetComponentFromItem(Tool) :: BaseItem.Component?

		if not ItemComponent then
			continue
		end

		self:Add(ItemComponent)
	end
end

function Inventory.OnConstructServer(self: Component)
	
	self.Player = self.Instance.Parent
	self.Character = self.Player.Character
	
	self.Items = {}
	self.MaxSlots = 3
	self.Enabled = true
	self.KeepInventory = true
	
	self.Toggled = self.Janitor:Add(Signal.new())
	self.ItemAdded = self.Janitor:Add(Signal.new())
	self.ItemRemoved = self.Janitor:Add(Signal.new())
	self.ItemEquipped = self.Janitor:Add(Signal.new())
	self.ItemUnequipped = self.Janitor:Add(Signal.new())
	self.ItemDeactivated = self.Janitor:Add(Signal.new())
	self.ItemActivated = self.Janitor:Add(Signal.new())
	
	self:_InitKeptInventoryItems()
	self:_InitToggleConnections()
	
	-- prompt client inventory component create 
	self.Instance:AddTag("Inventory")
	
	self.Janitor:Add(function()
		if self.Instance then
			self.Instance:RemoveTag("Inventory")
		end
	end)
	
	self.Janitor:Add(RolesManager.PlayerRoleChanged:Connect(function(player, role)
		if player == self.Player and RolesManager:IsPlayerSpectator(player) then
			self:DestroySavedItems()
		end
	end))
end

function Inventory.DestroySavedItems(self: Component)
	local Folder = self.Player:FindFirstChild("SavedInventory") :: Folder?
	if Folder then
		Folder:Destroy()
	end	
end

function Inventory.OnDestroy(self: Component)
	
	if self.KeepInventory then
		
		local ItemsToKeep = table.clone(self.Items)
		
		for _, ItemComponent: BaseItem.Component in ipairs(ItemsToKeep) do
			ItemComponent.Instance.Parent = self.SavedInventoryFolder
		end
		
		self:RemoveAll()
		
		table.clear(ItemsToKeep)
	end
	
	self.Janitor:Cleanup()
	self:Cleanup()
end

--//Connections

ServerRemotes.InventoryComponentDropItemServer.SetCallback(function(player: Player, instance: Tool)
	
	local Inventory = ComponentsManager.Get(player.Backpack, "InventoryComponent")
	local ItemComponent = GetComponentFromItem(instance)

	if not ItemComponent
		or not Inventory
		or not Inventory:IsMember(ItemComponent) then
		
		return
	end

	Inventory:Drop(ItemComponent)
end)

--//Returner

return Inventory