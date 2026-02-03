local server = shared.Server
local requirements = server._requirements

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local ItemTypeEnum = Enums.ItemTypeEnum
local ItemWrapper = require(script.ItemWrapper)
local ServerPlayer = requirements.ServerPlayer
local ItemThrowService = server:Require(game.ReplicatedStorage.Shared.ItemThrowService)


-- ServerItems initial
local Initialized = false
local ServerItems = {}
ServerItems.constructors = {}
ServerItems.enums = ItemTypeEnum
ServerItems.items = ItemWrapper._objects

-- finds all of existing game items and brings them into container
function ServerItems:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	for _, constructor: ModuleScript in ipairs(script.ItemWrapper:GetChildren()) do
		table.insert(
			ServerItems.constructors,
			require(constructor)
		)
	end
end

-- returns first item with given enum
local function GetConstructorFromEnum( item_enum: number )
	for _, constructor in ipairs(ServerItems.constructors) do
		if constructor.enum == item_enum then return constructor end
	end
	
	warn(`No constructor with enum "{ item_enum }" exists`)
end

-- returns first item with given enum
function ServerItems:GetReferenceItemByEnum( item_enum: number )
	for _, item in ipairs(ServerItems.reference_items) do
		if item:GetData().enum == item_enum then return item end
	end
	
	warn(`No item with enum "{ item_enum }" exists`)
end

-- returns first item with given id
function ServerItems:GetItemFromId( item_id: number )
	for _, item in ipairs(ServerItems.items) do
		if item:GetId() == item_id then return item end
	end
end

-- returns first item with given instance
function ServerItems:GetItemFromInstance( instance: Tool )
	for _, object: ItemWrapper in ipairs(ServerItems.items) do
		if object:GetItem() == instance then return object end
	end
end

-- returns true if player has item (in backpack or character)
function ServerItems:PlayerHasItem( player: Player, item_wrapper )
	local player_obj = ServerPlayer.GetObjectFromInstance(player)
	
	-- warns if player has no wrapper object
	if not player_obj then
		warn(`Player is not member of a game ({ player })`)
		return
	end
	
	local backpack_obj = player_obj.Backpack
	
	-- warns if player has no backpack
	if not backpack_obj then
		warn(`Could not find backpack object for player ({ player })`)
		return
	end
	
	-- backpack check if item is member
	return backpack_obj:IsItemBackpackMember(item_wrapper)
end

-- returns wrapped tool
function ServerItems:NewItem( source: number | string )
	local enum: number? = source
	
	-- finding item reference
	if type(source) == 'string' then
		-- finds item by name
		enum = ItemTypeEnum[ source ]
	end
	
	-- creating a new wrapper
	local constructor = GetConstructorFromEnum(enum)
	local new_item = constructor.new()
	
	-- new item wrap initialization
	return new_item
end

--[[ ITEM MESSAGING
MessagingEvent.OnServerEvent:Connect(function(player: Player, item_id: string, ...)
	-- validation
	local ItemObject = ServerItems:GetItemFromId(item_id)
	if not ServerItems:PlayerHasItem(player, ItemObject) then return end
	
	-- handling
	ItemObject:OnClientMessage(player, ...)
end)]]

-- complete

--ServerItems:Init()
return ServerItems