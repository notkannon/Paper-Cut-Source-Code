type SkillState = {
	Debounce: boolean,
	IsActive: boolean,
	TimerEndTimestamp: number,
	_isActive_counter: number
}

local client = shared.Client

-- requirements
local Util = client._requirements.Util
local enumsModule = client._requirements.Enums
local MainUI = client._requirements.UI

export type SkillSlot = {
	active: boolean,
	locked: boolean,
	skill: {},
	bind: Enum.KeyCode|Enum.UserInputType,
}

local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')
local InterfaceSFX = game:GetService('SoundService').Master.UI
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')


-- private fields
local function GetSignForBindInput( bind_input: Enum.KeyCode|Enum.UserInputType )
	if bind_input == Enum.UserInputType.MouseButton1
		or bind_input == Enum.UserInputType.MouseButton2
	then return true, '' -- TODO: draw mouse input icons

		-- sensor touch icon
	elseif bind_input == Enum.UserInputType.Touch then
		return true, ''

		-- return string key bind
	else return false, UserInputService:GetStringForKeyCode( bind_input ) end
end


-- class initial
local SkillSlot = {} do
	SkillSlot.__index = SkillSlot
	SkillSlot._objects = {}
	
	function SkillSlot.new( super, index )
		local self = setmetatable({
			super = super,
			index = index,
			
			skill = nil,
			active = false,
			locked = false,
			
			reference = nil :: TextButton,
			icon_reference = nil :: ImageLabel,
			bind_reference = nil :: TextLabel,
			indicator_reference = nil :: ImageLabel?,
			indicator_value = nil :: UIGradient,
			
			connections = {
				state_changed = nil :: RBXScriptConnection,
				started = nil :: RBXScriptConnection,
				ended = nil :: RBXScriptConnection,
				destroyed = nil :: RBXScriptConnection
			}
		}, SkillSlot)
		return self
	end
	
	-- returns true if binded skill is active
	function SkillSlot:IsActive()
		return self.active
	end
	
	-- returns true if no contains skill object reference
	function SkillSlot:IsClean()
		return not self.skill
	end
end


function SkillSlot:Init()
	local slot_instance: TextButton = ReplicatedStorage.Assets.GUI.Misc.SkillSlot:Clone()
	slot_instance.Parent = MainUI.gameplay_ui.skills_ui.reference.Slots
	
	self.reference = slot_instance
	self.icon_reference = slot_instance.Icon
	self.bind_reference = slot_instance.Bind
	self.indicator_reference = slot_instance.Icon.Indicator
	self.indicator_value = self.indicator_reference.Value
end


function SkillSlot:SetSkill( skill_object )
	if not skill_object or not skill_object.Data.Visible then
		self:Cleanup()
		return
	end
	
	local data = skill_object.Data
	self.skill = skill_object
	self.reference.Visible = true
	self.reference.Bind.Text = data.Name
	self.referenceLayoutOrder = data.DisplayOrder
	
	--TODO: make it beauty, bro (skill icons, effects, animations and etc.)
	
	-- setting new slot skill
	self:_OnSkillChanged( skill_object )
	
	-- connections
	self.connections.started = skill_object.Started:Connect(function( ... ) self:_OnStarted() end)
	self.connections.ended = skill_object.Ended:Connect(function( ... ) self:_OnEnded() end)
	self.connections.state_changed = skill_object.StateChanged:Connect(function( ... )
		self:_OnStateChanged( ... )
	end)
	
	self.connections.destroying = skill_object.Destroyed:Connect(function( ... )
		self:Cleanup()
	end)
end

-- triggers when slot skill changes
function SkillSlot:_OnSkillChanged( skill_object )
	local icon: ImageLabel = self.icon_reference	
	local bind: TextLabel = self.bind_reference
	local value: UIGradient = self.indicator_value
	local indicator: ImageLabel = self.indicator_reference
	
	icon.Image = skill_object and skill_object:GetData().skill_icon or ''
	
	MainUI:ClearTweensForObject( indicator )
	MainUI:AddObjectTween( TweenService:Create(
		indicator,
		TweenInfo.new(1), {
			BackgroundColor3 = skill_object
				and Color3.new(1, 1, 1)
				or Color3.new(0, 0, 0)
		})
	):Play()
end


function SkillSlot:_OnStarted()
	local icon: ImageLabel = self.icon_reference
	local value: UIGradient = self.indicator_value
	
	icon.Size = UDim2.fromScale(.8, .8)
	icon:TweenSize(UDim2.fromScale(.9, .9), 'Out', 'Sine', .25, true)
	MainUI:ClearTweensForObject( value )
end

function SkillSlot:_OnEnded()
	local data = self.skill.Data
	local value: UIGradient = self.indicator_value
	
	local charge_time = data.Cooldown
	local charge_info = TweenInfo.new(
		charge_time,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.InOut
	)

	value.Offset = Vector2.new(0, 1)
	MainUI:ClearTweensForObject( value )
	MainUI:AddObjectTween( TweenService:Create(value, charge_info, {Offset = Vector2.new(0, 0)}) ):Play()
end

function SkillSlot:_OnStateChanged( skill_state: SkillState )
	local icon: ImageLabel = self.icon_reference	
	local bind: TextLabel = self.bind_reference
	local value: UIGradient = self.indicator_value
	local indicator: ImageLabel = self.indicator_reference
	
	-- applying debounce effect (charging)
	if not skill_state.Debounce then
		MainUI:ClearTweensForObject( value )
		value.Offset = Vector2.new(0, 0)
		icon.BackgroundTransparency = 0
		
		MainUI:ClearTweensForObject( icon )
		MainUI:AddObjectTween( TweenService:Create(icon, TweenInfo.new(.2), {BackgroundTransparency = 1}) ):Play()
	end
end


function SkillSlot:Cleanup()
	self.reference.Visible = false
	self.skill = nil
	
	-- reset methods
	self:_OnSkillChanged( nil )
	
	-- dropping all connections
	for _, connection: RBXScriptConnection in pairs( self.connections ) do
		if connection then connection:Disconnect() end
	end
end

return SkillSlot