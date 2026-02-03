--//Services

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Promise = require(ReplicatedStorage.Packages.Promise)
local BaseItem = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local ItemsData = require(ReplicatedStorage.Shared.Data.Items)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local CreatedItems = {} :: { BaseItem.Component? }
local ItemConstructors = {}
local ConstructorInstances = {}

local DroppedItemInstancesFolder
local BufferedItemsInstancesFolder

local ItemService: Impl = Classes.CreateSingleton("ItemService") :: Impl
ItemService.ItemCreated = Signal.new()
ItemService.ItemDropped = Signal.new()
ItemService.ItemPickedUp = Signal.new()
ItemService.ItemInventoryChanged = Signal.new()

--//Types

export type Impl = {
	__index: Impl,

	IsImpl: (self: Service) -> boolean,
	GetName: () -> "ItemService",
	GetExtendsFrom: () -> nil,
	
	Cleanup: (self: Service, droppedOnly: boolean?) -> (),
	CreateItem: (self: Service, itemConstructorName: string) -> BaseItem.Component,
	GetAllPlayerItems: (self: Service, player: Player) -> { [number]: Tool? },
	GetAllItemsDropped: (self: Service) -> { BaseItem.Component? },
	
	new: () -> Service,
	OnConstruct: (self: Service) -> (),
	OnConstructServer: (self: Service) -> (),
	OnConstructClient: (self: Service) -> (),

	_InitConstructors: (self: Service) -> (),
}

export type Fields = {
	ItemCreated: Signal.Signal<BaseItem.Component>,
	ItemDropped: Signal.Signal<BaseItem.Component>,
	ItemPickedUp: Signal.Signal<BaseItem.Component>,
	ItemInventoryChanged: Signal.Signal<BaseItem.Component, any>,
}

export type Service = typeof(setmetatable({} :: Fields, ItemService :: Impl))

--//Functions

local function GetItemConstructorFromString(itemName: string, useMatch: boolean?)
	
	for _, ItemConstructor in ipairs(ItemConstructors) do
		
		local ConstructorName = ItemConstructor:GetName() :: string
		
		if useMatch
			and ConstructorName:match(itemName)
			or ConstructorName == itemName then
			
			return ItemConstructor
		end
	end
end

--//Methods

function ItemService.Cleanup(self: Service, droppedOnly: boolean?)
	
	local List = CreatedItems
	
	if droppedOnly then
		List = self:GetAllItemsDropped()
	end
	
	--removal
	for _, ItemComponent in ipairs(List) do
		ItemComponent:Destroy()
	end
end

function ItemService.GetAllPlayerItems(self: Service, player: Player)
	
	local OwnedItems = {}
	local InventoryComponent = ComponentsManager.Get(player.Backpack, "InventoryComponent")
	local SavedInventoryFolder = player:FindFirstChild("SavedInventory") :: Folder?
	
	--parsing saved items
	if SavedInventoryFolder then
		
		for _, Tool in ipairs(SavedInventoryFolder:GetChildren()) do
			
			if not Tool:IsA("Tool") then
				continue
			end
			
			local ItemComponent = ComponentsManager.GetFirstComponentInstanceOf(Tool, BaseItem) :: BaseItem.Component
			
			if not ItemComponent
				or ItemComponent:IsDestroying()
				or ItemComponent:IsDestroyed() then
				
				continue
			end
			
			table.insert(OwnedItems, {
				ItemId = ItemComponent.Data.ItemId,
				Instance = ItemComponent.Instance,
				ClassName = ItemComponent.Data.Constructor,
			})
		end
	end
	
	--parsing inventory
	if InventoryComponent then
		
		for _, ItemComponent: BaseItem.Component in ipairs(InventoryComponent.Items) do
			
			if ItemComponent:IsDestroying()
				or ItemComponent:IsDestroyed() then
				
				continue
			end
			
			table.insert(OwnedItems, {
				ItemId = ItemComponent.Data.ItemId,
				Instance = ItemComponent.Instance,
				ClassName = ItemComponent.Data.Constructor,
			})
		end
	end
	
	return OwnedItems
end

function ItemService.GetAllItemsDropped(self: Service)
	
	local DroppedItems = {}
	
	for _, ItemComponent in ipairs(CreatedItems) do
		
		if not ItemComponent.Instance
			or ItemComponent:GetOwner()
			or ItemComponent.Instance.Parent ~= DroppedItemInstancesFolder then
			
			continue
		end
		
		table.insert(DroppedItems, ItemComponent)
	end
	
	return DroppedItems
end

function ItemService.HandleDropItem(self: Service, item: BaseItem.Component, position: Vector3)
	item.Instance.Parent = DroppedItemInstancesFolder
	item.Handle:SetNetworkOwner(nil)
	item.Handle.AssemblyLinearVelocity = Vector3.zero
	item.Handle:PivotTo(CFrame.new(position))
end

function ItemService.CreateItem(self: Service, itemConstructorName: string, useMatch: boolean?, doEffect: boolean?)
	
	local ItemConstructor = GetItemConstructorFromString(itemConstructorName, useMatch)
	assert(ItemConstructor, `ItemConstructor "{ itemConstructorName }" doesn't exist`)
	
	--updating variable with existing constructor name
	itemConstructorName	= ItemConstructor.GetName()

	local ConstructorData = ItemsData[itemConstructorName:sub(1, -5)]
	assert(ConstructorData, `Constructor data doesn't exist for constructor { itemConstructorName }`)
	print('creating item ', itemConstructorName, 'with doEffect', doEffect)
	local ItemComponent = ComponentsManager.Add(ConstructorData.Instance:Clone(), ItemConstructor, doEffect) :: BaseItem.Component
	ItemComponent.Instance.Parent = BufferedItemsInstancesFolder
	ItemComponent.Instance:SetAttribute("Impl", itemConstructorName)
	
	table.insert(CreatedItems, ItemComponent)
	
	ItemComponent.Janitor:Add(function()
		
		local Index = table.find(CreatedItems, ItemComponent)
		
		if not Index then
			return
		end
		
		table.remove(CreatedItems, Index)
	end)
	
	--item picking up
	ItemComponent.Janitor:Add(ItemComponent.Interaction.Started:Connect(function(player: Player)

		if ItemComponent._Inventory then
			return
		end

		local InventoryComponent = ComponentsManager.Get(player.Backpack, "InventoryComponent")

		if not InventoryComponent then
			return
		end

		InventoryComponent:Add(ItemComponent)
	end))
	
	return ItemComponent
end

function ItemService.OnConstruct(self: Service)
	
	self:_InitConstructors()

	DroppedItemInstancesFolder = Instance.new("Folder", workspace)
	DroppedItemInstancesFolder.Name = "DroppedItems"

	BufferedItemsInstancesFolder = Instance.new("Folder", ServerStorage)
	BufferedItemsInstancesFolder.Name = "BufferedItems"
end

function ItemService._InitConstructors(self: Service)
	
	for _, ItemConstructorModule: ModuleScript? in ipairs(ReplicatedStorage.Shared.Components.Items:GetDescendants()) do
		
		if not ItemConstructorModule:IsA("ModuleScript") then
			continue
		end

		local Constructor = require(ItemConstructorModule)
		ConstructorInstances[ItemConstructorModule.Name] = ItemConstructorModule
		table.insert(ItemConstructors, Constructor)
	end
end

--//Returner

local Singleton = ItemService.new()
return Singleton :: Service