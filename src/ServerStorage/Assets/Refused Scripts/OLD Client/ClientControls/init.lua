local Client = shared.Client

-- service
local ContextActionService = game:GetService('ContextActionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

-- requirements



--// INITIALIZAATION
local Initialized = false
local ClientControls = {}

-- represents current controls enabled (once per game)
ClientControls.Controls = nil

--[[

Computer	-- represents devices like PCs, Laptops and etc. (Including mouse)
Gamepad 	-- represents devices with gamepad connection (AKA Consoles, but also it may be PCs or something else)
Sensor 		-- represents all sensor devices (AKA mobile, tablet and etc.)
VR 			-- represents VR presence

]]

--// METHODS
-- controls initial mthod
function ClientControls:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	-- Computer (PCs, laptops ...) presence controls
	if UserInputService.MouseEnabled and
		UserInputService.KeyboardEnabled then
		ClientControls.Controls = require(script.Computer)
		
		-- Sensor (mobile/tablet ...) presence cotnrols
	elseif UserInputService.TouchEnabled then
		ClientControls.Controls = require(script.Sensor)
		
		-- Gamepad (console) presence controls
	elseif UserInputService.GamepadEnabled then
		ClientControls.Controls = require(script.Gamepad)
		
		-- VR presence controls
	elseif UserInputService.VREnabled then
		ClientControls.Controls = require(script.VR)
		
		-- another device case
	else ClientControls.Controls = require(script.Computer) end
	
	-- running controls
	ClientControls.Controls:Run()
end


return ClientControls

--[[local client = shared.Client

-- service
local UserInput = game:GetService('UserInputService')
local ContextAction = game:GetService('ContextActionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local ContextActionUtility = client:Require(ReplicatedStorage.Package.ContextActionUtility)
local UI

-- constants
local IS_SENSOR = UserInput.TouchEnabled
local IS_PC = not IS_SENSOR


local NumberToNumpadKeycode = {
	{1, Enum.KeyCode.One},
	{2, Enum.KeyCode.Two},
	{3, Enum.KeyCode.Three},
	{4, Enum.KeyCode.Four},
	{5, Enum.KeyCode.Five},
	{6, Enum.KeyCode.Six},
	{7, Enum.KeyCode.Seven},
	{8, Enum.KeyCode.Eight},
	{9, Enum.KeyCode.Nine},
	{0, Enum.KeyCode.Zero}
}


-- ClientControls initial
local Initialized = false
local ClientControls = {}
ClientControls.sensor_last_tap_time = 0
ClientControls.sensor_sprint_active = false
ClientControls.sensor_sprint_enabled = false

--// functions

local function IsStateReleased(state: Enum.UserInputState)
	return state == Enum.UserInputState.End
		or state == Enum.UserInputState.Cancel
end


-- initial method
function ClientControls:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	if IS_SENSOR then
		self:InitSensorDeviceControls()
	else self:InitPCDeviceControls() end
	
	warn('[client] Controls initialized')
end


function ClientControls:InitCharacterControls()
	-- jump request is universal connection
	UserInput.JumpRequest:Connect(function()
		local Character = client.Player.Character
		Character:_jump()
	end)
end

--[[ binds action (button/input) to given skill object
function ClientControls:BindSkill( skill_object )
	-- getting a string for a context utility bind
	local input_data = skill_object:GetData().input
	local skill_bind_id = '@skill_' .. skill_object.Name
	print('Binded controls for the skill:', skill_object:GetData().name)
	
	if IS_SENSOR then
		--[[ContextActionUtility:BindAction(
			skill_bind_id,
			
			function( ... )
				self:_handleContextAction(...)
			end,
			
			input_data.create_touch_button,
			not input_data.create_touch_button and Enum.UserInputType.Touch or nil
		) --TODO: FIX IT MAN
		
	elseif IS_PC then
		ContextActionUtility:BindAction(
			skill_bind_id,
			
			function( ... )
				self:_handleContextAction(...)
			end,
			
			false,
			table.unpack(input_data.input_objects)
		)
	end
end]]

--[[ inbinds skill from input
function ClientControls:UnbindSkill( skill_name )
	ContextActionUtility:UnbindAction( '@skill_' .. skill_name )
end


function ClientControls:InitPCDeviceControls()
	ContextActionUtility:BindAction(PC_INPUT, function(...) self:_handleContextAction(...) end, false,
		Enum.KeyCode.LeftShift,
		Enum.KeyCode.LeftControl,
		--Enum.KeyCode.F, -- block
		Enum.KeyCode.G -- taunt ui visibility
	)

	-- setup number keypad for quick selection of tools
	local keycode_array = {} do
		for x, tuple in ipairs(NumberToNumpadKeycode) do
			table.insert(keycode_array, tuple[2])
		end
	end
	
	ContextActionUtility:BindAction(PC_BACKPACK, function(...) self:_handleContextAction(...) end, false, table.unpack(keycode_array))
	--[[UserInput.InputChanged:Connect(function(input: InputObject, game_processed: boolean?)
		if game_processed then return end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local backpack = client.Player.Backpack
			local is_up = input.Position.Z > 0
			backpack:Scroll( is_up )
		end
	end)
end


function ClientControls:InitSensorDeviceControls()
	game.Players.LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
	
	ContextActionUtility:BindAction(SENSOR_ACTION_SPRINT, function(...) self:_handleContextAction(...) end, true)
	ContextActionUtility:BindAction(SENSOR_ACTION_CROUCH, function(...) self:_handleContextAction(...) end, true)
	ContextActionUtility:BindAction(SENSOR_ACTION_BLOCK, function(...) self:_handleContextAction(...) end, true)
	
	ContextActionUtility:SetImage(SENSOR_ACTION_SPRINT, SensorActionsIcons.Sprint[1])
	ContextActionUtility:SetImage(SENSOR_ACTION_CROUCH, SensorActionsIcons.Crouch[1])
	ContextActionUtility:SetImage(SENSOR_ACTION_BLOCK, SensorActionsIcons.Block[1])
	
	-- Backpack initials
	
	
	--[[ setup sensor detection to interact with slots
	for _, slot: { reference: TextButton } in ipairs(backpackUI.slots) do
		slot.reference.TouchTap:Connect(function()
			BackpackComponent:EquipSlot(
				slot.slot_id
			)
		end)
	end
	
	-- will update character control every frame
	client:AddConnection(game:GetService('RunService').RenderStepped:Connect(function()
		self:ApplySensorStates()
	end), '@deviceControlsConnection')
end


function ClientControls:ApplySensorStates()
	assert(IS_SENSOR, 'Cannot call method on non-sensor device')
	
	local Character = client.Player.Character
	
	ContextActionUtility:SetImage(SENSOR_ACTION_SPRINT, SensorActionsIcons.Sprint[ Character.States.Sprinting and 2 or 1 ])
	ContextActionUtility:SetImage(SENSOR_ACTION_CROUCH, SensorActionsIcons.Crouch[ Character.States.Crouching and 2 or 1 ])
	ContextActionUtility:SetImage(SENSOR_ACTION_BLOCK, SensorActionsIcons.Block[ Character.States.Block and 2 or 1 ])
	
	self.sensor_sprint_enabled = self.sensor_sprint_enabled
		and Character.staminaValue > 0 -- stop action if stamina is empty
	
	Character:_setSprintEnabled(self.sensor_sprint_enabled)
end


function ClientControls:SetShopControlsEnabled( enabled: boolean )
	if enabled then
		ContextActionUtility:BindAction(SHOP_INPUT, function(...) self:_handleContextAction(...) end, false,
			Enum.UserInputType.MouseButton1)
	else ContextActionUtility:UnbindAction(SHOP_INPUT) end
end


function ClientControls:_handleContextAction(
	action_name: string,
	input_state: Enum.UserInputState,
	input_object: InputObject, ...)
	
	if not client.Player then return end
	local Character = client.Player.Character
	
	--[[ skill handling
	if action_name:sub(1, 7) == '@skill_' then
		local skill_name = action_name:sub(8)
		if self:IsStateReleased(input_state) then return end
		SkillsController:PromptSkill( skill_name )
	end
	
	if IS_SENSOR then
		--[[ << SENSOR DEVICE BINDINGS >>
		if action_name == SENSOR_ACTION_SPRINT then
			if not IsStateReleased(input_state) then return end
			self.sensor_sprint_enabled = not self.sensor_sprint_enabled
			
		elseif action_name == SENSOR_ACTION_CROUCH then
			if not IsStateReleased(input_state) then return end
			self.sensor_sprint_enabled = false
			Character:_setCrouchEnabled(not Character.States.Crouching)
		end
	elseif IS_PC then
		-- << PC DEVICE BINDINGS >>
		if action_name == PC_BACKPACK and IsStateReleased(input_state) then
			local slot_index = 0
			
			for _, tupleKey in ipairs(NumberToNumpadKeycode) do
				if tupleKey[2] ~= input_object.KeyCode then continue end
				
				if tupleKey[2] == Enum.KeyCode.Zero then
					slot_index = 10
					break
				end
				
				slot_index = tupleKey[1]
				break
			end
			
			-- getting target container
			local Backpack = client._requirements.ClientBackpack
			local container = Backpack:GetContainerById( slot_index )
			
			-- trying to set equipped
			if container then
				container:SetEquipped(
					not container.equipped
				)
			end
			
		elseif action_name == SHOP_INPUT then
		--[[	if not IsStateReleased(input_state) then return end
			local shop = client._requirements.ShopService
			shop:Click()
			
			-- taunts ui visibility
		elseif input_object.KeyCode == Enum.KeyCode.G and IsStateReleased(input_state) then
			--[[local TauntsUI = UI.gameplay_ui.taunts_ui
			TauntsUI:SetVisible( not TauntsUI.visible )
			
		elseif input_object.KeyCode == Enum.KeyCode.LeftShift then
			--[[local is_released = IsStateReleased(input_state)
			Character:_setSprintEnabled(not is_released)

		elseif input_object.KeyCode == Enum.KeyCode.LeftControl
			and not IsStateReleased(input_state)
		then --[[Character:_setCrouchEnabled(not Character.States.Crouching)
		end
	end
end

return ClientControls]]