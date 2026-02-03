--local Server = shared.Server
--local requirements = Server._requirements

---- service
--local Players = game:GetService('Players')
--local RunService = game:GetService('RunService')
--local ReplicatedStorage = game:GetService('ReplicatedStorage')

---- requirements
--local Enums = require(ReplicatedStorage.Enums)
--local GlobalSettings = require(ReplicatedStorage.GlobalSettings)


---- class initial
--local ServerBackpack = {}
--ServerBackpack.__index = ServerBackpack
--ServerBackpack._objects = {}

---- constructor
--function ServerBackpack.new(Player)
--	local self = setmetatable({
--		Instance = Player.Instance.Backpack, -- a Instance to player`s backpack object
--		Player = Player, -- a Instance to owner player object
--		Enabled = true,
--		MaxItems = 5,
		
--		Container = {}, -- all existing items
--		_deferred = {}, -- items which was moved to "recycle bin" to be possible to be brought back
--		_connections = {}
--	}, ServerBackpack)
	
--	table.insert(
--		self._objects,
--		self
--	)
	
--	return self
--end

---- sets a new value to change possible items count inside backpack
--function ServerBackpack:SetMaxItems(value: number)
--	self.MaxItems = value
--end


--function ServerBackpack:SetEnabled( value: boolean )
--	self.Enabled = value
--end


--function ServerBackpack:CanAddItem()
--	return (#self.Container < self.MaxItems and self.Enabled)
--end

---- returns true if given item is member of current backpack (equipped or unequipped is not checked)
--function ServerBackpack:IsItemBackpackMember(wrapper)
--	for _, item_wrapper in ipairs(self.Container) do
--		if item_wrapper == wrapper then
--			return true
--		end
--	end
--end

---- returns true if item parented to player`s character
--function ServerBackpack:IsItemEquipped(wrapper)
--	local BackpackInstance: Tool? = wrapper:GetItem()
--	if not BackpackInstance then return end
	
--	local character: Model? = self.Player.Character.Instance
--	if not character then return end
--	return BackpackInstance:IsDescendantOf( character )
--end

---- initial method
--function ServerBackpack:Init()
--	--print('[Server] Backpack inited for player', self.Player.Instance)
--end


--function ServerBackpack:RemoveItem(wrapper)
--	if not self:IsItemBackpackMember(wrapper) then
--		warn(`Attempted to remove item ({ wrapper }) which is not valid member of backpack: {self}`)
--		return
--	end
	
--	if not self.Enabled then return end
	
--	-- prompt to backpack child remove connection
--	if self:IsItemEquipped(wrapper) then
--		self:UnequipAll()
--	end
	
--	-- removes item from _deferred or Container (both)
--	local deferred_index = table.find(self._deferred, wrapper)
--	local container_index = table.find(self.Container, wrapper)
	
--	if deferred_index then
--		table.remove(self._deferred, deferred_index)
--	elseif container_index then
--		table.remove(self.Container, container_index)
--	end
--end

---- TEST
--function ServerBackpack:RemoveFirstItem()
--	local wrapper = self.Container[1]
--	if not wrapper then return end
--	if not self.Enabled then return end
	
--	if self:IsItemEquipped(wrapper) then
--		self:UnequipAll()
--	end
	
--	wrapper:SetParent(nil)
--	table.remove(self.Container, 1)
--end

---- adds a new item to player`s backpack
--function ServerBackpack:AddItem(item_wrapper)
--	if not self:CanAddItem() then
--		return
--	end
		
--	--e
--	table.insert(
--		self.Container,
--		item_wrapper
--	)
	
--	-- parenting item to backpack
--	item_wrapper:SetParent(self.Instance)
--end

---- reconnects to new backpack instance
--function ServerBackpack:Reset()
--	self.Instance = self.Player.Instance.Backpack
--end

---- defers all items which was in player`s backpack
--function ServerBackpack:Defer()
--	self:UnequipAll()
	
--	for _, item in ipairs(self.Container) do
--		table.insert(self._deferred, item)
--		item:SetParent(game:GetService('ServerStorage'))
--	end
	
--	table.clear(self.Container)
--end

---- attempts to restore all _deferred items back to player`s backpack
--function ServerBackpack:Restore()
--	for _, item in ipairs(self._deferred) do
--		self:AddItem(item)
--	end
	
--	table.clear(self._deferred)
--end

---- attempts to unequip all items from humanoid
--function ServerBackpack:UnequipAll()
--	local Character = self.Player.Character
--	local humanoid: Humanoid? = Character:GetHumanoid()
	
--	if not humanoid then
--		--warn('Attempted to call :UnequipTools() on nil humanoid')
--		return
--	end
	
--	-- unequipping all items from humanoid
--	humanoid:UnequipTools()
--end

---- attempts to equip given tool (if parented to backpack and exists)
--function ServerBackpack:Equip( item_enum: number )
--end

---- removes all items from player
--function ServerBackpack:Clear()
--	self:UnequipAll()
--	local raw = {}
	
--	-- collecting all items
--	for _, item in ipairs(self.Container) do table.insert(raw, item) end
--	for _, item in ipairs(self._deferred) do table.insert(raw, item) end
	
--	-- clearing cached items
--	table.clear(self.Container)
--	table.clear(self._deferred)
	
--	-- avoid skipping some items when removing them from Container
--	for _, item in ipairs(raw) do
--		item:Destroy()
--	end
	
--	-- no leaks
--	table.clear(raw)
--end

---- fully removes backpack object
--function ServerBackpack:Destroy()
--	for _, connection: RBXScriptConnection in ipairs(self._connections) do
--		connection:Disconnect()
--	end

--	table.remove(self._objects,
--		table.find(self._objects,
--			self
--		)
--	)
	
--	table.clear(self)
--	setmetatable(self, nil)
--end

--return ServerBackpack


local ServerBackpack = {}
ServerBackpack.__index = ServerBackpack
ServerBackpack.object = {}

ServerBackpack.ClassName = "Backpack"

local Functions = {
	ItemsPlayer = {}, -- functions (Add/Remove) new tool
}

function ServerBackpack.new(Player)
	local self = setmetatable({
		Instance = Player.Instance.Backpack, -- a Instance to player`s backpack object
		Player = Player, -- a Instance to owner player object
		Enabled = true,
		MaxItems = 4,

		Container = {}, -- all existing items
		_deferred = {}, -- items which was moved to "recycle bin" to be possible to be brought back
		_connections = {}
	}, ServerBackpack)

	table.insert(
		self._objects,
		self
	)

	return self
end

function ServerBackpack:Reset()
	
end


function ServerBackpack:GetPlayerBackpack()
	return self.Container
end

function ServerBackpack:Defer()
	
end


function ServerBackpack:Restore()
	
end

function ServerBackpack:RemoveFirstItem()
	table.remove(
		self.Container[1],
		1
	)
	
	return self
end

function ServerBackpack:SetEnabled( value: boolean )
	self.Enabled = value
	
	return self
end


function ServerBackpack:CanAddItem()
	return #self.Container < self.MaxItems
end

function ServerBackpack:IsItemEquipped(wrapper)
	local BackpackInstance: Tool? = wrapper:GetItem()
	if not BackpackInstance then return end

	local character: Model? = self.Player.Character.Instance
	if not character then return end
	return BackpackInstance:IsDescendantOf( character )
end

function ServerBackpack:Clear()
	
end

function ServerBackpack:UnequipAll()
	
end

function ServerBackpack:Equip( item_enum: number )
	if not self:CanAddItem() then return end
	
	
	table.insert(
		self.Container,
		item_enum
	)
	
	return self
end

function ServerBackpack:Destroy()
	
	setmetatable(self, nil)
end

return {
	ServerBackpack = ServerBackpack,
	Functions = Functions,
}