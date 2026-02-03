local client = shared.Client

-- requirements
local Util = client._requirements.Util
local enumsModule = client._requirements.Enums
local MainUI = client._requirements.UI

local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')
local InterfaceSFX = game:GetService('SoundService').Master.UI
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')


-- BackpackSlot initial
local BackpackSlot = {}
BackpackSlot.__index = BackpackSlot
BackpackSlot._objects = {}

function BackpackSlot.new( super, container )
	local self = setmetatable({
		super = super,
		container = container,
		
		reference = nil :: TextButton,
		icon_reference = nil :: ImageLabel,
		bind_reference = nil :: TextLabel,
		indicator_reference = nil :: ImageLabel?,
		indicator_value = nil :: UIGradient,
		
		connections = {
			item_changed = nil :: RBXScriptConnection,
			unequipped = nil :: RBXScriptConnection,
			equipped = nil :: RBXScriptConnection,
		}
	}, BackpackSlot)
	
	table.insert(
		self._objects,
		self
	)
	
	self:Init()
	return self
end


function BackpackSlot:Init()
	local item_container = self.container
	
	-- creating a slot from template
	local slot_instance: TextButton = ReplicatedStorage.Assets.GUI.Misc.BackpackSlot:Clone()
	slot_instance.Parent = MainUI.gameplay_ui.backpack_ui.reference.Slots
	
	self.reference = slot_instance
	self.icon_reference = slot_instance.Icon
	self.bind_reference = slot_instance.Bind
	slot_instance.Bind.Text = item_container:GetId()
	
	-- connections
	self.connections.item_changed = item_container.ItemChanged:Connect(function() self:UpdateItem() end)
	self.connections.unequipped = item_container.Unequipped:Connect(function() self:SetEquipped( false ) end)
	self.connections.equipped = item_container.Equipped:Connect(function() self:SetEquipped( true ) end)
	
	self:SetVisible(false)
end

-- makes slot visible
function BackpackSlot:SetVisible(visible: boolean)
	self.reference.Visible = visible
end

-- sets current slot icon
function BackpackSlot:SetIcon(icon: string)
	local button: TextButton = self.reference
	local Icon = button:FindFirstChild('Icon')
	
	MainUI:ClearTweensForObject(Icon)
	local tween: Tween = MainUI:AddObjectTween(
		TweenService:Create(
			Icon,
			TweenInfo.new(.3),
			{ImageTransparency = icon and .5 or 1})
	)
	
	tween:Play()
	
	-- smooth icon remove
	if not icon then
		tween.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then
				Icon.Image = ''
			end
		end)
	else
		Icon.ImageTransparency = 1
		Icon.Image = icon
	end
	
	Icon.Size = UDim2.fromScale(1.1, 1.1)
	Icon:TweenSize(UDim2.fromScale(.9, .9), 'Out', 'Sine', .23, true)
end

-- sets current item from container
function BackpackSlot:UpdateItem()
	local data = self.container:GetData()
	
	-- handling data
	self:SetIcon( data and data.icon )
	self:SetVisible( data ~= nil )

	MainUI:ClearTweensForObject(self.reference.Icon.Shadow)
	MainUI:AddObjectTween(TweenService:Create(
		self.reference.Icon.Shadow,
		TweenInfo.new(.3),
		{ImageTransparency = data and 1 or .9}
	)):Play()
end

-- sets slot equipped/unequipped
function BackpackSlot:SetEquipped(equipped: boolean)
	local super = self.super
	local reference = super.reference
	local item_data = self.container
	local button = self.reference
	
	local Icon = button:FindFirstChild('Icon')
	local Bind = button:FindFirstChild('Bind')
	
	-- some on equipped event handling
	if equipped	then
		local itemNameFrame: TextLabel = reference.ItemName
		itemNameFrame.Text = item_data and item_data.name or ''

		itemNameFrame.Rotation = -5
		MainUI:ClearTweensForObject(itemNameFrame)
		MainUI:AddObjectTween(TweenService:Create(itemNameFrame, TweenInfo.new(.2), {Rotation = 0})):Play()

		super.last_equipped_time = tick()
		reference.ItemName.TextTransparency = 0
		InterfaceSFX.BackpackSlotEquip:Play()
	end

	-- nuuh uh
	MainUI:ClearTweensForObject(Icon)
	MainUI:ClearTweensForObject(Bind)
	--mainGameUI:ClearTweensForObject(slot.button.Background)
	--mainGameUI:ClearTweensForObject(slot.button.Background.Shadow)

	MainUI:AddObjectTween(TweenService:Create(Bind, TweenInfo.new(.2), {TextColor3 = equipped and Color3.new(1, 1, 1) or Color3.new(0, 0, 0), TextTransparency = equipped and 0 or .7})):Play()
	MainUI:AddObjectTween(TweenService:Create(Icon, TweenInfo.new(.2), {ImageTransparency = equipped and 0 or .5})):Play()
	--mainGameUI:AddObjectTween(tweenService:Create(slot.button.Background, TweenInfo.new(.2), {ImageTransparency = equipped and 0 or .7})):Play()
	--mainGameUI:AddObjectTween(tweenService:Create(slot.button.Background.Shadow, TweenInfo.new(.2), {ImageTransparency = equipped and .5 or 1})):Play()
	Icon:TweenSize(UDim2.fromScale(equipped and 1.15 or .9, equipped and 1.15 or .9), 'Out', equipped and 'Back' or 'Sine', .2, true)
	Bind:TweenPosition(UDim2.fromScale(0, equipped and -.15 or 0), 'Out', equipped and 'Back' or 'Sine', .2, true)
end

-- complete
return BackpackSlot