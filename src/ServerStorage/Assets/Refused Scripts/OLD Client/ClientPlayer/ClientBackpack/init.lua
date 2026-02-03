local client = shared.Client
local requirements = client._requirements

-- requirements
local UI
local BackpackUI
local ItemContainer = require(script.ItemContainer)

-- service
local RunService = game:GetService('RunService')
local player = game.Players.LocalPlayer

-- private fields
local private = {
	last_cooldown = 0, -- os.clock()
	cooldown_duration = 0,
	connections = {
		CharacterAdded = nil :: RBXScriptConnection,
		BackpackChildAdded = nil :: RBXScriptConnection,
		BackpackChildRemoved = nil :: RBXScriptConnection,
		HealthChanged = nil :: RBXScriptConnection
	}
}

-- Backpack initial
local Initialized = false
local Backpack = {}
Backpack.locked = false
Backpack.enabled = false
Backpack.reference = nil
Backpack.container = {}

-- initial method
function Backpack:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	UI = requirements.UI
	BackpackUI = UI.gameplay_ui.backpack_ui
	
	client.PlayerAdded:Once(function(Player)
		self:Reset()
		
		Player.CharacterChanged:Connect(function( Character )
			if not Character then
				self:SetEnabled(false)
			else self:Reset() end
		end)
	end)
	
	-- slot initialization
	local slot_count = 10
	
	for x = 1, slot_count do
		local Container = ItemContainer.new(x)
		BackpackUI:CreateSlot( Container )

		table.insert(
			Backpack.container,
			Container
		)
	end
end

-- returns true if backpack is enabled
function Backpack:IsEnabled(): boolean
	return Backpack.enabled
end

-- sets backpack enabled locally
function Backpack:SetEnabled(enabled: boolean)
	if enabled then
		-- enabling
		Backpack.enabled = true
		BackpackUI:SetEnabled( true )
	else
		-- unequipping + lock to equip
		Backpack:UnequipAll()
		Backpack.enabled = false
		BackpackUI:SetEnabled( false )
	end
end

-- returns real backpack instance
function Backpack:GetBackpack(): Backpack?
	return player.Backpack
end

-- returns first container with given item
function Backpack:GetContainerById(id: number)
	for _, container in ipairs(Backpack.container) do
		if container:GetId() == id then
			return container
		end
	end
end

-- returns first container with given item
function Backpack:GetContainerByItem(item: Tool)
	for _, container in ipairs(Backpack.container) do
		if container:GetItem() == item then
			return container
		end
	end
end

-- returns first empty item container
function Backpack:GetBlankContainer()
	for _, container in ipairs(Backpack.container) do
		if not container:GetItem() then
			return container
		end
	end
end

-- returns equipped container if exists
function Backpack:GetEquipped()
	for _, container in ipairs(Backpack.container) do
		if container.equipped then
			return container
		end
	end
end

-- returns true if was cooldowned
function Backpack:IsCooldowned()
	return os.clock() - private.last_cooldown < private.cooldown_duration
end

-- restocks whole slots in backpack
function Backpack:Reorder()
	local temp_reference
	local temp_item_reference

	local function deep( prev_slot, slot )
		if not slot then return end -- break chain

		if not prev_slot:GetItem() then
			prev_slot:SetItem(slot:GetItem())
			slot:SetItem( nil )
		end

		deep( slot, Backpack:GetContainerById( slot:GetId() + 1 ) )
	end

	local slot = Backpack:GetContainerById( 1 )
	deep( slot, Backpack:GetContainerById( 2 ) )
end

-- returns true if item (moved) in character
function Backpack:IsItemEquipped(item: Tool)
	if typeof(item) ~= 'Instance' then return end
	
	local CharacterObject = client.Player.Character
	return item:IsDescendantOf( CharacterObject.Instance )
end

-- attempting to unequip all slots (containers)
function Backpack:UnequipAll(exclude)
	local CharacterObject = client.Player.Character
	if not CharacterObject then return end
	
	local humanoid: Humanoid = CharacterObject:GetHumanoid()
	if not humanoid then return end
	
	for _, container in ipairs(Backpack.container) do
		if container == exclude then continue end
		container:SetEquipped(false)
	end
end

-- reconnect to new? backpack instance
function Backpack:Reset()
	local reference: Backpack = player.Backpack
	Backpack.reference = reference
	
	-- enabling
	Backpack:SetEnabled(true)
	
	-- slot dropping
	self:Clear()
	
	-- cooldown reset
	private.last_cooldown = 0
	private.cooldown_duration = 0
	
	-- connection drop
	for _, connection: RBXScriptConnection in pairs(private.connections) do
		connection:Disconnect()
	end table.clear(private.connections)
	
	-- filling with new tools
	for index, tool: Tool? in ipairs(reference:GetChildren()) do
		Backpack.container[ index ]:SetItem( tool )
	end
	
	-- new item connection
	private.connections.BackpackChildAdded = Backpack:GetBackpack().ChildAdded:Connect(function(new_item: Tool?)
		if self:GetContainerByItem(new_item) then return end -- already has item
		if not new_item:IsA('Tool') then return end

		local blank = Backpack:GetBlankContainer()
		if not blank then return end

		blank:SetItem(new_item)
	end)
	
	-- removing item
	private.connections.BackpackChildRemoved = Backpack:GetBackpack().ChildRemoved:Connect(function(removed: Tool)
		local container = Backpack:GetContainerByItem(removed)
		if not container then return end
		if Backpack:IsItemEquipped(removed) then return end

		-- removing item
		container:SetItem(nil)
		Backpack:Reorder()
	end)
	
	--[[ TODO: handle player damage connection
	private.connections.HealthChanged = client.Player.Character.HealthChanged:Connect(function(old, new)
		self:SetEnabled(new > 5)
	end)
	
	-- disconnect all previous connections if there was any
	client._requirements.HideoutService.PlayerEntered:DisconnectAll()
	client._requirements.HideoutService.PlayerLeft:DisconnectAll()]]
	
	--[[ player entered hideout
	client._requirements.HideoutService.PlayerEntered:Connect(function(player, hideout)
		if player == client.Player.Instance then
			self:SetEnabled(false)
		end
	end)
	
	-- player left hideout
	client._requirements.HideoutService.PlayerLeft:Connect(function(player, hideout)
		if player == client.Player.Instance then
			self:SetEnabled(true)
		end
	end)]]
end

-- sets backpack cooldowned (could not equip other items while true)
function Backpack:Cooldown(duration: number)
	private.last_cooldown = os.clock()
	private.cooldown_duration = duration or .5
end

-- drops all items locally and removes them from UI
function Backpack:Clear()
	for _, slot in ipairs(Backpack.container) do
		slot:SetItem( nil )
	end
end

-- complete
return Backpack