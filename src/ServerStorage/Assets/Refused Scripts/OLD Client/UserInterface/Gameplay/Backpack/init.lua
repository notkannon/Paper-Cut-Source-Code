type BackpackSlot = {
	index: number,
	button: TextButton,
	equipped: boolean?,
	item_container: {},
	connections: { RBXScriptConnection }
}

local client = shared.Client

-- objects
local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')
local InterfaceSFX = game:GetService('SoundService').Master.UI
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--requiremens
local Util = require(ReplicatedStorage.Shared.Util)
local Enums = require(ReplicatedStorage.Enums)
local BackpackSlot = require(script.BackpackSlot)

-- paths
local MainUI = client._requirements.UI
local GameplayUI = MainUI.gameplay_ui
local reference: Frame? = GameplayUI.reference.Backpack
assert( reference, 'No backpack frame exists in super.reference' )

-- << CUSTOM BACKPACK CLASS >>
-- could be managed by BackpackComponent? -- YES FCK IT
-- NO IT SHOULD BE MANAGED LOCALLY. >:(
-- works like roblox original backpack
local Initialized = false
local BackpackUI = {}
BackpackUI.slots = {}
BackpackUI.enabled = true
BackpackUI.reference = reference
BackpackUI.last_equipped_time = 0

-- creates a new backpack object on client
function BackpackUI:Init( slots_amount: number )
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	-- cleans up old created slots
	for _, raw_slot: TextButton? in ipairs(reference.Slots:GetChildren()) do
		if not raw_slot:IsA('TextButton') then continue end
		raw_slot:Destroy()
	end
	
	-- nuuuuh uhhh
	self:SetEnabled( true )
end

-- returns true if enabled
function BackpackUI:IsEnabled()
	return self.enabled
end

-- creates a new slot state-table to interact with real backpack
function BackpackUI:CreateSlot( item_container )
	table.insert(self.slots, BackpackSlot.new(self, item_container))
end

--[[ makes a prompt to change current frame equipped forward or backward
function BackpackUI:Scroll(up_direction: boolean)
	if not self:IsEnabled() then return end
	local current_slot = self:GetSlotEquipped()
	if not current_slot then return end
	
	local last_item_slot = nil
	for _, slot: BackpackSlot in ipairs(self.slots) do
		if not slot.item_reference then break end
		last_item_slot = slot
	end
	
	-- we may scroll only among itemed frames, and skip empty
	if not last_item_slot then return end
	local add = up_direction and 1 or -1
	local target_index = current_slot.index + add
	
	-- direction getting
	if add < 0 then target_index = target_index > 0 and target_index or last_item_slot.index
	else target_index = target_index <= last_item_slot.index and target_index or 1 end
	self:SetSlotEquipped(target_index, true)
end]]

-- setc UI backpack visibility (with animation)
function BackpackUI:SetEnabled( enabled: boolean )
	if self.enabled == enabled then return end
	self.enabled = enabled
	
	MainUI:ClearTweensForObject(reference)
	local tw: Tween = MainUI:AddObjectTween(TweenService:Create(reference, TweenInfo.new(.1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Rotation = enabled and 7 or -7}))
	tw:Play()
	tw.Completed:Once(function()
		MainUI:AddObjectTween(TweenService:Create(reference, TweenInfo.new(.5, Enum.EasingStyle.Back, Enum.EasingDirection[enabled and 'Out' or 'In']), {Rotation = 0})):Play()
	end)
	
	reference:TweenPosition(
		UDim2.new(0.5, 0, enabled and 1 or 1.3, -10),
		enabled and 'Out' or 'In',
		enabled and 'Back' or 'Sine',
		.5,
		true
	)
end

-- frame update ig :p
function BackpackUI:Update()
	-- disappearing item name text after inactive backpack input
	if tick() - self.last_equipped_time < 3 then return end
	reference.ItemName.TextTransparency += 1/30
end

return BackpackUI