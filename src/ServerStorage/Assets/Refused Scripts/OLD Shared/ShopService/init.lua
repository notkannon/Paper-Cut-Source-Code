export type ShopItem = {
	data: {},
	visual: BasePart?,
	hitbox: BasePart?,
	starterSize: Vector3,
	selected: boolean?,
	offset: Attachment,
	index: number
}

local client = shared.Client

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ContextAction = game:GetService('ContextActionService')
local SoundService = game:GetService('SoundService')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local UISounds = SoundService.Master.UI

local ENTER_DISTANCE = 15
local LERP_SMOOTHNESS = 10

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local Util = require(ReplicatedStorage.Shared.Util)
local UI = client._requirements.UI

local CannonSellerModule = require( script.Cannon )
local IkeSellerModule = require( script.Ike )
local CameraModeEnum = Enums.CameraModeEnum

-- ShopService initial
local Initialized = false
local ShopService = {}
ShopService.__index = ShopService

function ShopService.new()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	local self = setmetatable({
		player_entered = false,
		is_closed = false,
		
		shop_items = {},
		sellers = {},
		
		instance = workspace:WaitForChild('Map'):WaitForChild('Shop'),
		theme = SoundService.Master.OST.lobby_shop_theme,
		sound_close = SoundService.Master.Instances.Shop.shop_close,
		sound_open = SoundService.Master.Instances.Shop.shop_open,
		info_label = script.Info,
		
		last_distance_check_time = 0,
		distance_listener_connection = nil :: RBXScriptConnection
	}, ShopService)
	
	self:Init()
	return self
end


function ShopService:Init()
	self.theme:Play()
	self.theme.Volume = 0
	self.theme.Parent = self.instance.Hitbox

	self.sound_close.Parent = self.instance.Hitbox
	self.sound_open.Parent = self.instance.Hitbox
	self:PlaceItems()
	self:ListenToDistance()
	self:Leave()
end


function ShopService:SetItemLabelAdornee( item: ShopItem )
	local label: BillboardGui = self.info_label
	
	if item then
		label.Body.item_name.Text = item.data.name or ''
		label.Body.description.Text = item.data.description or ''
		label.Parent = item.offset
		label.Adornee = item.offset
	end
	
	label.Body.Size = label.Body.Size:Lerp(UDim2.fromScale(1, item and 4 or 0), 1/LERP_SMOOTHNESS)
end


function ShopService:Click()
	for _, item: ShopItem in ipairs(self.shop_items) do
		if item.selected then
			item.visual.Size = item.starterSize * 1.2
			item.visual.CFrame *= CFrame.Angles(math.rad(10), math.rad(10), math.rad(-10))
			
			UISounds.ui_click:Play()
			print('Purchasing', item.data.name, item.data.cost)
			break
		end
	end
end

-- initial func for place every item to shop
function ShopService:PlaceItems()
	local offset_attachments: { Attachment } = self.instance.Items
	local game_item_instances = game.ReplicatedStorage.Assets.Item:GetChildren()
	
	for _i, item: Tool? in ipairs(game_item_instances) do
		local item_data = require(item:FindFirstChild('Data'))
		local visual: BasePart = item_data.reference:FindFirstChild('Handle'):Clone()
		local offset = offset_attachments:FindFirstChild(_i)
		
		if not offset then continue end
		
		local hitbox: BasePart = Instance.new('Part', visual)
		hitbox.Anchored = true
		hitbox.Position = offset.WorldPosition
		hitbox.Size = Vector3.one * 1.5
		hitbox.Transparency = 1
		hitbox.Color = Color3.new(1, 0, 0)
		hitbox.CanCollide = false
		
		local item: ShopItem = {
			data = item_data,
			visual = visual,
			starterSize = visual.Size,
			hitbox = hitbox,
			selected = false,
			offset = offset,
			index = _i
		}
		
		visual.Parent = workspace.Map.Shop.ItemModels
		visual.CFrame = offset.WorldCFrame
		visual.Anchored = true
		visual.CanCollide = false
		visual.CanTouch = false
		visual.CanQuery = false
		
		table.insert(
			self.shop_items,
			item
		)
	end
end


function ShopService:RenderItems()
	-- get nearest instance
	local mouse_hit = client._requirements.CameraComponent:GetMouseHit( 100, true )
	
	for _, item: ShopItem in ipairs(self.shop_items) do
		local visual: BasePart = item.visual
		local offset_attachment: Attachment = item.offset
		
		local t = tick() + item.index / 5
		local selected = mouse_hit == item.hitbox
		
		self:SetItemLabelAdornee( selected and item )
		
		-- selection
		if item.selected ~= selected then
			item.selected = selected
			if selected then UISounds.ui_hover:Play() end
		end
		
		local goal = selected and offset_attachment.WorldCFrame * CFrame.new(0, math.sin(t * 2)/10, 0)
			or offset_attachment.WorldCFrame * CFrame.new(0, math.sin(t * 2)/5, 0)
		
		visual.Size = Util.Lerp(visual.Size, item.starterSize * (selected and 1 or .5), 1/LERP_SMOOTHNESS)
		visual.CFrame = visual.CFrame:Lerp(goal, 1/LERP_SMOOTHNESS)
		
		if selected then
			offset_attachment.WorldCFrame = CFrame.new(offset_attachment.WorldPosition)
		else offset_attachment.WorldCFrame *= CFrame.Angles(0, math.rad(1), 0) end
	end
end


function ShopService:AnimateDoor( closed: boolean )
	if closed then
		self.sound_close:Play()

		local pos = Vector3.new(75.133, 5.95, 4.1)
		TweenService:Create(self.instance.Door, TweenInfo.new(
			.45,
			Enum.EasingStyle.Bounce,
			Enum.EasingDirection.Out), {
				Position = pos
			}
		):Play()
	else
		self.sound_open:Play()

		local pos = Vector3.new(75.133, 10.95, 4.1)
		TweenService:Create(self.instance.Door, TweenInfo.new(
			1,
			Enum.EasingStyle.Bounce,
			Enum.EasingDirection.Out), {
				Position = pos
			}
		):Play()
	end
end


function ShopService:SetClosed( closed: boolean )
	if self.is_closed == closed then return end
	self.is_closed = closed
	
	if closed then
		self:Leave()
		CannonSellerModule:PlayTrack('closed')
		IkeSellerModule:PlayTrack('closed')
	else
		CannonSellerModule:PlayTrack('opened')
		IkeSellerModule:PlayTrack('idling')
		self:AnimateDoor( false )
	end
end


function ShopService:Enter()
	self.player_entered = true
	self.info_label.Enabled = true
	
	CannonSellerModule:SetFollowTarget( client.local_character.Instance.Head )
	--shared.Client._requirements.BackpackComponent:SetEnabled( false )
	UI.gameplay_ui:ChangePreset('shop')
	client._requirements.ControlsModule:SetShopControlsEnabled( true )
	--client._requirements.CameraComponent:SetActiveCameraMode( CameraModeEnum.CharacterBinded, false )
	--client._requirements.CameraComponent:SetActiveCameraMode( CameraModeEnum.Headlocked, true )
	
	TweenService:Create(self.theme, TweenInfo.new(1), {Volume = 1}):Play()
	TweenService:Create(SoundService.Master.OST.paper_cut_intermission, TweenInfo.new(1), {Volume = 0}):Play()
	
	for _, item: ShopItem in ipairs(self.shop_items) do
		item.visual.LocalTransparencyModifier = 0
	end
end


function ShopService:Leave()
	self.player_entered = false
	self.info_label.Enabled = false
	
	CannonSellerModule:SetFollowTarget( nil )
	UI.gameplay_ui:ChangePreset('game')
	--shared.Client._requirements.BackpackComponent:SetEnabled( true )
	client._requirements.ControlsModule:SetShopControlsEnabled( false )
	--client._requirements.CameraComponent:SetActiveCameraMode( CameraModeEnum.ShopBinded, false )
	--client._requirements.CameraComponent:SetActiveCameraMode( CameraModeEnum.CharacterBinded, true )
	
	TweenService:Create(SoundService.Master.OST.paper_cut_intermission, TweenInfo.new(1), {Volume = 1}):Play()
	TweenService:Create(self.theme, TweenInfo.new(1), {Volume = 0}):Play()
	
	for _, item: ShopItem in ipairs(self.shop_items) do
		item.visual.LocalTransparencyModifier = 1
	end
end


function ShopService:ListenToDistance()
	if self.distance_listener_connection then
		self.distance_listener_connection:Disconect()
	end
	
	self.distance_listener_connection = RunService.RenderStepped:Connect(function()
		--if self.player_entered then self:RenderItems() end
		if self.is_closed then return end
		CannonSellerModule:Update()
		
		if tick() - self.last_distance_check_time < .3 then return end
		self.last_distance_check_time = tick()
		
		if not client.local_character then return end
		local plr_pos: Vector3 = client.local_character:GetPosition()
		if not plr_pos then return end
		
		local is_entered = (plr_pos - self.instance.Hitbox.Position).Magnitude <= ENTER_DISTANCE
		if is_entered == self.player_entered then return end
		
		if is_entered then
			self:Enter()
		else self:Leave() end
	end)
end

return ShopService