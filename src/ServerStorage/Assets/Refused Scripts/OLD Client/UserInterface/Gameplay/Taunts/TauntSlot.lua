export type TauntSlot = {
	reference: TextButton,
	selected: boolean,
	taunt: { never }
}

local client = shared.Client

-- requirements
local Util = client._requirements.Util
local MainUI = client._requirements.UI
local enumsModule = client._requirements.Enums

local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')
local InterfaceSFX = game:GetService('SoundService').Master.UI
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- constants
local IS_SENSOR = UserInputService.TouchEnabled


-- class initial
local TauntSlot = {} do
	TauntSlot.__index = TauntSlot
	TauntSlot._objects = {}

	function TauntSlot.new( super, index: number, position: UDim2 )
		local self = setmetatable({
			super = super,
			index = index,

			taunt = nil,
			position = position,
			selected = false,

			reference = nil :: TextButton,
			camera_reference = nil :: Camera,
			render_reference = nil :: WorldModel,
			viewport_reference = nil :: ViewportFrame,
			animation_rig_reference = nil :: Model,

			connections = {
				mouse_enter = nil :: RBXScriptConnection,
				mouse_leave = nil :: RBXScriptConnection,
				mouse_click = nil :: RBXScriptConnection,
				touch = nil :: RBXScriptConnection
			}
		}, TauntSlot)

		self:Init()
		return self
	end

	-- returns true if binded skill is active
	function TauntSlot:IsSelected()
		return self.selected
	end

	-- returns true if no contains skill object reference
	function TauntSlot:IsClean()
		return not self.taunt
	end
end


function TauntSlot:Init()
	local slot_instance: TextButton = ReplicatedStorage.Assets.GUI.Misc.TauntSlot:Clone()
	slot_instance.Parent = self.super.reference.Slots
	slot_instance.Position = self.position
	slot_instance.Size = UDim2.fromScale(0, 0)
	slot_instance.Visible = false
	
	local Rig: Model = ReplicatedStorage.Assets.GUI.AnimationRig:Clone()
	local WorldModel: WorldModel = Instance.new('WorldModel')
	local Camera: Camera = Instance.new('Camera')
	
	WorldModel.Parent = slot_instance.Viewport
	Camera.Parent = WorldModel
	Rig.Parent = WorldModel
	
	-- setting current camera for rendering
	slot_instance.Viewport.CurrentCamera = Camera
	
	-- camera offsetting
	local prim: BasePart = Rig.PrimaryPart
	Camera.CFrame = CFrame.lookAt(prim.Position + prim.CFrame.LookVector * 6, prim.Position)
	
	self.camera_reference = Camera
	self.render_reference = WorldModel
	self.animation_rig_reference = Rig
	self.viewport_reference = slot_instance.Viewport
	self.title_reference = slot_instance.Title
	self.reference = slot_instance
end


function TauntSlot:SetTaunt( taunt_object )
	if not taunt_object then
		self:Cleanup()
		return
	end
	
	local reference: TextButton = self.reference

	self.taunt = taunt_object
	self.referenceLayoutOrder = taunt_object.enum
	self.title_reference.Text = taunt_object.name
end


function TauntSlot:SetVisible( visible )
	local reference: TextButton = self.reference
	
	-- setting visibility to show an animation
	if visible then
		reference.Visible = true
		
		-- connections
		self.connections.mouse_enter = reference.MouseEnter:Connect(function( ... ) self:SetSelected( true ) end)
		self.connections.mouse_leave = reference.MouseLeave:Connect(function( ... ) self:SetSelected( false ) end)
		
		-- interactions
		if not IS_SENSOR then
			self.connections.mouse_click = reference.MouseButton1Click:Connect(function( ... ) self:Click() end)
		else self.connections.touch = reference.TouchTap:Connect(function( ... ) self:Click() end) end
	else
		self:DropConnections()
		self:SetSelected( false )
	end
	
	reference:TweenSize(
		UDim2.fromScale(visible and .45 or 0, visible and .7 or 0),
		visible and 'Out' or 'In',
		visible and 'Back' or 'Sine',
		.45,
		true,
		function()
			reference.Visible = visible
		end
	)
end


function TauntSlot:SetSelected( selected: boolean )
	if self.selected == selected then return end
	self.selected = selected
	
	local viewport: ImageLabel = self.viewport_reference
	viewport:TweenSize(
		UDim2.fromScale(
			selected and 2.3 or 2,
			selected and 2.3 or 2),
		'Out',
		selected and 'Back' or 'Sine',
		.3,
		true
	)
	
	MainUI:ClearTweensForObject( viewport )
	MainUI:AddObjectTween( TweenService:Create(viewport, TweenInfo.new(.3), {
		ImageTransparency = selected and 0 or .7,
		ImageColor3 = Color3.fromHSV(1, 0, selected and 1 or 0)
	})):Play()
	
	local rig: Model = self.animation_rig_reference
	local humanoid: Humanoid = rig:FindFirstChildOfClass('Humanoid')
	local animator: Animator = humanoid:FindFirstChildOfClass('Animator')
	
	-- removing all animation tracks from rig
	for _, animation_track: AnimationTrack in ipairs(animator:GetPlayingAnimationTracks()) do
		animation_track:Stop()
		animation_track:Destroy()
	end
	
	if selected then
		-- playing an animation on the rig (preview)
		local track = animator:LoadAnimation(self.taunt.animation)
		track.Looped = true
		track:Play()
	end
end

-- click effect. Also prompts TauntService to play this taunt
function TauntSlot:Click()
	local button: TextButton = self.reference
	button.Size = UDim2.fromScale(.53, .7)
	button:TweenSize(
		UDim2.fromScale(.45, .7),
		'Out',
		'Sine',
		.2,
		true
	)
	
	client._requirements.TauntService:PlayTaunt( self.taunt.enum )
end


function TauntSlot:DropConnections()
	-- dropping all connections
	for _, connection: RBXScriptConnection in pairs( self.connections ) do
		if connection then connection:Disconnect() end
	end
end


function TauntSlot:Cleanup()
	self.taunt = nil

	-- reset methods
	self:SetSelected( false )
	self:DropConnections()
end

return TauntSlot