local server = shared.Server
local requirements = server._requirements

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local Signal = require(ReplicatedStorage.Package.Signal)
local Util = require(ReplicatedStorage.Shared.Util)


-- ItemWrapper initial
local ItemWrapper = {}
ItemWrapper._objects = {}
ItemWrapper.__index = ItemWrapper

-- constructor
function ItemWrapper.new(item: Tool)
	-- assertation
	assert(typeof(item) == 'Instance' and item:IsA('Tool'),
		`Provided object is not tool ({ item })`)
	
	-- attempting to get item data from module
	local data_module: ModuleScript? = item:FindFirstChild('Data')
	assert(data_module and data_module:IsA('ModuleScript'),
		`Unable to get item data for item "{ item }"`
	)
	
	-- construction
	local self = setmetatable({
		data = require(data_module),
		reference = item,
		
		Equipped = Signal.new(),
		Activated = Signal.new(),
		Unequipped = Signal.new(),
		Deactivated = Signal.new(),
		Destroying = Signal.new(),
		
		connections = {}
	}, ItemWrapper)
	
	table.insert(
		self._objects,
		self
	)
	
	self:Init()
	return self
end

-- initial wrapper method
function ItemWrapper:Init()
	local ServerItems = requirements.ServerItems
	local item: Tool = self:GetItem()
	
	-- messaging event creation
	local messaging: RemoteEvent = Instance.new('RemoteEvent')
	messaging.Name = 'Messaging'
	messaging.Parent = item
	
	-- item identity
	item:SetAttribute('Id', Util.GetGUID())
	
	-- messaging event connection
	table.insert(self.connections,	item.Messaging.OnServerEvent:Connect(function(player: Player, ...)
		if not ServerItems:PlayerHasItem(player, self) then
			warn(`Player { player } has no item { self }`)
			return
		end

		-- handling
		self:OnClientMessage(player, ...)
	end))
	
	-- destroying connection  
	table.insert(self.connections, item.Equipped:Connect(function(...) self.Equipped:Fire(...) end))
	table.insert(self.connections, item.Activated:Connect(function(...) if not self:CanUse() then return end self.Activated:Fire(...) end))
	table.insert(self.connections, item.Unequipped:Connect(function(...) self.Unequipped:Fire(...) end))
	table.insert(self.connections, item.Deactivated:Connect(function(...) self.Deactivated:Fire(...) end))
	
	-- wrapper removal
	table.insert(self.connections, item.Destroying:Once(function()
		self.Destroying:Fire()
		self:Destroy()
	end))
end

-- returns current item backpack object
function ItemWrapper:GetBackpack()
	local ServerBackpack = shared.Server._requirements.ServerBackpack
	for _, backpack in ipairs(ServerBackpack._objects) do
		if backpack:IsItemBackpackMember(self) then
			return backpack
		end
	end
end

-- returns true if can be used in current backpack
function ItemWrapper:CanUse()
	return true
	--[[local Backpack = self:GetBackpack()
	if not Backpack then return end
	return Backpack:IsEnabled()]]
end

-- returns item_id
function ItemWrapper:GetId()
	return self:GetItem():GetAttribute('Id')
end

-- returns item reference
function ItemWrapper:GetItem()
	return self.reference
end

-- returns a data table if provided tool has data-module inside
function ItemWrapper:GetData()
	return self.data
end


function ItemWrapper:SetParent(parent)
	self:GetItem().Parent = parent
end

-- sends any data from server to client`s tool worker
function ItemWrapper:SendClientMessage(...)
	local instance: Tool = self:GetItem()
	assert(instance, 'No instance found for item to send client message')
	
	local BackpackObject = self:GetBackpack()
	local messaging: RemoteEvent = instance.Messaging
	
	if not BackpackObject then
		return
	end
	
	messaging:FireClient(
		BackpackObject.Player.Instance,
		... -- sending data to client
	)
end

-- handling messages from client
function ItemWrapper:OnClientMessage(...)
	warn(`:OnClientMessage() has no override. Message wasn't handled: { ... }`)
end

-- full item destruction
function ItemWrapper:Destroy()
	--print('Destroying:', self, getmetatable(self))
	local backpack = self:GetBackpack()
	
	-- remove item from backpack
	if backpack then
		backpack:RemoveItem(self)
	end
	
	-- instance connections removal
	for _, connection: RBXScriptConnection in pairs(self.connections) do
		connection:Disconnect()
	end
	
	-- custom signal kill
	self.Equipped:DisconnectAll()
	self.Activated:DisconnectAll()
	self.Unequipped:DisconnectAll()
	self.Deactivated:DisconnectAll()
	self.Destroying:DisconnectAll()
	
	-- forbidding object
	table.remove(self._objects,
		table.find(self._objects,
			self
		)
	)
	
	-- instance destroying
	if self:GetItem() then
		self:GetItem():Destroy()
	end
	
	-- raw removing
	setmetatable(self, nil)
	table.clear(self)
end

-- complete
return ItemWrapper