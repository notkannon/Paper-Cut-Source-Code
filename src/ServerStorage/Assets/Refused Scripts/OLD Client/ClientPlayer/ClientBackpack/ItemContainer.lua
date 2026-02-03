local Client = shared.Client
local requirements = Client._requirements

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local Signal = require(ReplicatedStorage.Package.Signal)


-- Item container initial
local ItemContainer = {}
ItemContainer.__index = ItemContainer
ItemContainer._objects = {}

-- constructor
function ItemContainer.new(container_id: number)
	assert(type(container_id) == 'number', 'ItemContainer id should be number')
	
	local self = setmetatable({
		container_id = container_id :: number,
		reference = nil,
		equipped = false ,
		data = nil,
		
		ItemChanged = Signal.new(),
		Unequipped = Signal.new(),
		Equipped = Signal.new(),
		
		cleanup = nil, -- used to locally cleanup item
		connections = {}
	}, ItemContainer)
	
	table.insert(
		self._objects,
		self)
	return self
end

-- returns container id
function ItemContainer:GetId()
	return self.container_id
end

-- returns item reference
function ItemContainer:GetItem()
	return self.reference
end

-- returns a data table if provided tool has data-module inside
function ItemContainer:GetData()
	return self.data
end

-- sets current container equipped
function ItemContainer:SetEquipped(equipped: boolean)
	local Backpack = requirements.ClientBackpack
	
	if equipped and not self:GetItem() then return end
	if not Backpack:IsEnabled() then return end
	if Backpack:IsCooldowned() then return end
	if equipped == self.equipped then return end -- dont repeat calls
	
	-- checks
	local Character = Client.Player.Character
	
	-- clear slot
	if not Character then
		warn('Cannot interact with nil or died character')
		self:SetItem( nil )
		return
	end
	
	local humanoid: Humanoid? = Character:GetHumanoid()
	
	-- unequip all exclude this osne
	Backpack:UnequipAll(self)
	
	-- event handling
	if not equipped then
		humanoid:UnequipTools()
	else
		-- cooldown backpack equip to .5 sec
		Backpack:Cooldown(.5)
		humanoid:EquipTool(
			self:GetItem()
		)
	end
	
	-- setting
	self.equipped = equipped
end

-- sets current item reference
function ItemContainer:SetItem(item: Tool)
	if item then
		assert(typeof(item) == 'Instance' and item:IsA('Tool'),
			`Provided object is not tool ({ item })`)
		
		-- attempting to get item data from module
		local data_module: ModuleScript? = item:FindFirstChild('Data')
		
		-- passing if no data module found
		if not data_module or not data_module:IsA('ModuleScript') then
			warn(`Unable to get item data for { item }`)
			return
		end
		
		self.data = require(data_module) -- setting data
	else self.data = nil end -- removing item data
	
	-- event prompting and setting
	self.ItemChanged:Fire(self.reference, item)
	self.reference = item
	
	-- connection resetting
	for _, connection: RBXScriptConnection in pairs(self.connections) do
		connection:Disconnect()
	end table.clear(self.connections)
	
	if item then
		-- used to detect unexpected item movement (like server changes item location by itself, not Client)
		self.connections.tool_equipped = item.Equipped:Connect(function() self.Equipped:Fire() end)
		self.connections.tool_unequipped = item.Unequipped:Connect(function() self.Unequipped:Fire() end)
		
		local cleanup_module: ModuleScript? = item:FindFirstChild('Cleanup')
		self.cleanup = cleanup_module and require(cleanup_module)
	end
	
	-- we`re should unequip slot if there no item
	if not item then
		self:Cleanup()
		self.Unequipped:Fire()
	end
end

-- tries to call .cleanup function to remove item leaks locally
function ItemContainer:Cleanup()
	if not self.cleanup then return end
	
	-- calling and forbidding
	self.cleanup()
	self.cleanup = nil
end

-- full object destruction
function ItemContainer:Destroy()
	for _, connection: RBXScriptConnection in ipairs(self.connections) do
		connection:Disconnect() -- droppin it
	end
	
	-- Signal removal
	self.ItemChanged:DisconnectAll()
	self.Unequipped:DisconnectAll()
	self.Equipped:DisconnectAll()
	
	-- clearing connection stuff
	table.clear(self.connections)
	
	-- forbidding object
	table.remove(
		self._objects,
		table.find(
			self._objects,
			self
		)
	)
	
	-- raw removal
	table.clear(self)
	setmetatable(self, nil)
end

return ItemContainer