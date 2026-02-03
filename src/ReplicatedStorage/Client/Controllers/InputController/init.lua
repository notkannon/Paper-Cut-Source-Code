--//Services

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Enums = require(ReplicatedStorage.Shared.Enums)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local DefaultKeybinds = require(ReplicatedStorage.Shared.Data.Keybinds)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local ThreadUtility = require(ReplicatedStorage.Shared.Utility.ThreadUtility)
local InterfaceUtility = require(ReplicatedStorage.Client.Utility.InterfaceUtility)

local InputHandler = require(script.InputHandler)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local SettingsController = require(ReplicatedStorage.Client.Controllers.SettingsController)

--//Variables

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local InputController = Classes.CreateSingleton("InputController") :: Impl
InputController.InputTypes = Enums.InputType
InputController.ContextEnded = Signal.new()
InputController.ContextStarted = Signal.new()
InputController.ContextChanged = Signal.new()
InputController.DeviceChanged = Signal.new()

local DEFAULT_BIND_STRING_OPTIONS = {
	MouseFormatStyle = "MNum",
	PrefixPlatform = false,
}

local UIAssets = ReplicatedStorage.Assets.UI
local Binds = UIAssets.Binds

--//Types

export type InputTypes = {
	VR: number,
	Sensor: number,
	Gamepad: number,
	Keyboard: number,
}

export type Bind = Enum.KeyCode | Enum.UserInputType

export type BindStringOptions = {
	MouseFormatStyle: "MNum" | "Abbreviate", -- MNum is either M1, M2 or M3; Abbreviate is LMB, RMB or MMB
	PrefixPlatform: boolean, -- If true, doesn't strip Button from the beginning of console binds
}

export type Impl = {
	__index: Impl,

	IsImpl: (self: Controller) -> boolean,
	GetName: () -> "InputController",
	GetExtendsFrom: () -> nil,
	
	IsVR: (self: Controller) -> boolean,
	IsSensor: (self: Controller) -> boolean,
	IsGamepad: (self: Controller) -> boolean,
	IsKeyboard: (self: Controller) -> boolean,
	GetInputType: (self: Controller) -> Enums.InputType,
	GetInputName: (self: Controller) -> string,
	
	AddHandler: (self: Controller, handler: InputHandler.Object) -> InputHandler.Object,
	
	IsContextActive: (self: Controller, context: string) -> boolean,
	IsContextualInput: (self: Controller, context: string, input: InputObject) -> boolean,
	GetBindsFromSkill: (self: Controller, skill: WCS.Skill) -> Bind?,
	GetContextFromSkill: (self: Controller, skill: WCS.Skill | string) -> string?,
	GetKeybindsFromContext: (self: Controller, context: string) -> Bind?,
	GetHighestContextPriority: (self: Controller, context: string) -> (number?, InputHandler.Object?),
	GetStringFromBind: (self: Controller, bind: Bind, options: BindStringOptions?) -> string,
	GetStringsFromBindings: (self: Controller, bindings: table<string, table<Bind>>, options: BindStringOptions?) -> table<string>,
	GetStringsFromContext: (self: Controller, context: string, options: BindStringOptions?) -> table<string>,
	
	GetImageIdFromString: (self: Controller, keyString: string) -> string?,
	GetImageIdFromSkill: (self: ContentProvider, skill: WCS.Skill | string) -> string?,
	
	new: () -> Controller,
	OnConstruct: (self: Controller) -> (),
	OnConstructServer: (self: Controller) -> (),
	OnConstructClient: (self: Controller) -> (),
	
	_ProcessSkillAdded: (self: Controller, skill: WCS.Skill) -> (),
	_InitInputHandlers: (self: Controller) -> (),
	_InitInputConnections: (self: Controller) -> (),
	_InitComponentConnections: (self: Controller) -> (),
}

export type Fields = {
	InputTypes: InputTypes,
	
	ContextEnded: Signal.Signal<string, InputHandler.Object>,
	ContextStarted: Signal.Signal<string, InputHandler.Object>,
	ContextChanged: Signal.Signal<string>,
	
	_UserBindings: { [string]: {Enum.UserInputType | Enum.KeyCode}? },
	_InputHandlers: { InputHandler.Object },
	_SkillInputHandlerOverrides: { [string]: { Create: (controller: Controller, unknown...) -> InputHandler.Object } }
}

export type Controller = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Methods

function InputController.IsVR(self: Controller)
	return self:GetInputType() == Enums.InputType.VR
end

function InputController.IsSensor(self: Controller)
	return self:GetInputType() == Enums.InputType.Sensor
end

function InputController.IsGamepad(self: Controller)
	return self:GetInputType() == Enums.InputType.Gamepad
end

function InputController.IsKeyboard(self: Controller)
	return self:GetInputType() == Enums.InputType.Keyboard
end

function InputController.GetInputType(self: Controller)
	if UserInputService.GamepadEnabled then
		
		return Enums.InputType.Gamepad
	
	elseif UserInputService.MouseEnabled
		and UserInputService.KeyboardEnabled then
		
		return Enums.InputType.Keyboard

	elseif UserInputService.TouchEnabled then
		
		return Enums.InputType.Sensor

	elseif UserInputService.VREnabled then
		
		return Enums.InputType.VR
	else
		return Enums.InputType.Keyboard
	end
end

function InputController.GetInputName(self: Controller)
	local Name = "Keyboard"
	local DeviceId = self:GetInputType()

	if DeviceId == Enums.InputType.Gamepad then
		Name = "Gamepad"
	elseif DeviceId == Enums.InputType.VR then
		Name = "VR"
	elseif DeviceId == Enums.InputType.Sensor then
		Name = "Sensor"
	else
		Name = "Keyboard"
	end

	return Name
end

function InputController.GetHighestContextPriority(self: Controller, context: string)
	local Priority = -math.huge
	local Handler
	
	for _, InputHandler in ipairs(self._InputHandlers) do
		if InputHandler.Context ~= context then
			continue
		end
		
		if InputHandler.Priority >= Priority then
			Handler = InputHandler
			Priority = InputHandler.Priority
		end
	end
	
	return Priority, Handler
end

function InputController.GetContextFromSkill(self: Controller, skill: WCS.Skill | string)
	local RoleConfig = Classes.GetSingleton("PlayerController"):GetRoleConfig()
	
	if not RoleConfig then
		return
	end
	
	local Context = typeof(skill) == "string" and skill or skill:GetName()
	local SkillsData = RoleConfig.SkillsData[ Context ]
	
	if not SkillsData or
		not SkillsData.Order then
		
		return Context
	end
	
	return `Skill{ SkillsData.Order }`
end

function InputController.IsContextActive(self: Controller, context: string)
	for _, InputHandler in ipairs(self._InputHandlers) do
		if InputHandler.Context ~= context or not InputHandler:IsActive() then
			continue
		end
		
		return true
	end
	
	return false
end

function InputController.IsContextualInput(self: Controller, context: string, input: InputObject)
	local AllowedBindings = self:GetKeybindsFromContext(context)
	local Bindings = AllowedBindings and AllowedBindings[ Enums.InputType:GetEnumFromIndex(self:GetInputType()) ]
	
	if not Bindings then
		return false
	end
	
	local InputAllowed = input.KeyCode == Enum.KeyCode.Unknown and input.UserInputType or input.KeyCode
	
	return table.find(Bindings, InputAllowed) ~= nil
end

function InputController.GetStringFromBind(self: Controller, bind: Bind, options: BindStringOptions?) : string
	-- this function takes 1 singular bind and converts it to string. do not confuse with GetStringFromBindings
	-- this also respects Playstation controller strings
	local String = "Unknown"
	
	options = TableKit.MergeDictionary(DEFAULT_BIND_STRING_OPTIONS, options or {})
	
	local PlaystationMappings = {Square = "□", Triangle = "△", Cross = "X", Circle = "O"}
	local MouseAbbreviationMappings = {"LMB", "RMB", "MMB"}
	
	if bind and bind.EnumType == Enum.KeyCode then
		String = UserInputService:GetStringForKeyCode(bind)
		if String:sub(1, 6) == "Button" and not options.PrefixPlatform then
			String = String:sub(7)
			
			if PlaystationMappings[String] then
				String = PlaystationMappings[String]
			end
		elseif String == " " then -- roblox is kinda stupid, why did they do space like that :sob:
			String = "SPACE"
		end

	elseif bind and bind.EnumType == Enum.UserInputType then
		if bind.Name:sub(1, 5):lower() == "mouse" then
			if options.MouseFormatStyle == "MNum" then
				String = `M{bind.Name:sub(-1) }`
			elseif options.MouseFormatStyle == "Abbreviate" then
				String = MouseAbbreviationMappings[tonumber(bind.Name:sub(-1))]
			end
		end
	end
	return String
end

function InputController.GetStringsFromBindings(self: Controller, bindings: table<string, table<Bind>>, options: BindStringOptions?) : table<string>
	-- this function takes a table of bindings, automatically picks the platform-appropiate ones and gets their strings
	
	local bindmap
	if bindings.Gamepad and self:IsGamepad() then
		bindmap = bindings.Gamepad
	elseif bindings.Keyboard and self:IsKeyboard() then
		bindmap = bindings.Keyboard
	elseif self:IsSensor() then
		print("wtf") -- GOOD QUESTION // Orangish
		-- uhhh... what do we do here?
	else
		-- fallback
		bindmap = bindings.Keyboard
	end
	
	--print(bindmap, bindings, "BINDINGS")
	
	if not bindmap then return {"Unknown"} end
	local Output = {}
	
	for _, bind in pairs(bindmap) do
		table.insert(Output, self:GetStringFromBind(bind, options))
	end
	
	--print(Output, "OUTPUT")
	
	return Output
end

function InputController.GetKeybindsFromContext(self: Controller, context: string)
	local Handler = select(2, self:GetHighestContextPriority(context))
	
	--print(context)
	--print((Handler and Handler.Context or Handler), (Handler and Handler.Keybinds or Handler), SettingsController:GetKeybindSetting(context), SettingsController:GetDefaultSetting(context, true))
	
	if not Handler then
		return SettingsController:GetSetting(context, true) or SettingsController:GetDefaultSetting(context, true)
	end
	
	return Handler.Keybinds
end

function InputController.GetStringsFromContext(self: Controller, context: string, options: BindStringOptions?) : table<string>
	-- a high-level function that returns all platform-appropiate keybinds for provided context
	-- i made it so there's less boilerplate on client UI modules
	local Bindings = self:GetKeybindsFromContext(context)
	if not Bindings then return {"Unknown"} end
	
	return self:GetStringsFromBindings(Bindings, options)
end

function InputController.GetBindsFromSkill(self: Controller, skill: WCS.Skill)
	--print(self:GetKeybindsFromContext(self:GetContextFromSkill(skill)))
	return self:GetKeybindsFromContext(self:GetContextFromSkill(skill))
end

function InputController.GetImageIdFromString(self: Controller, keyString: string) : string?
	-- returns an appropiate image ID (rbxassetid://number) from a given key string
	local Image : string? = ""
	Image = InterfaceUtility.GetInputNameToImage(keyString)

	if Image then
		return Image
	end
end

function InputController.GetImageIdFromSkill(self: Controller, skill: WCS.Skill) : string?
	local Bindings = self:GetBindsFromSkill(skill)
	local String = self:GetStringsFromBindings(Bindings, {PrefixPlatform = true, MouseFormatStyle = "MNum"})[1]
	--print(String)
	local Image = self:GetImageIdFromString(String)
	
	print(skill.Name, Bindings, String, Image)
	
	return Image
end


function InputController.AddHandler(self: Controller, handler: InputHandler.Object)
	handler.Ended:Connect(function()
		self.ContextEnded:Fire(handler.Context, handler)
	end)

	handler.Started:Connect(function()
		self.ContextStarted:Fire(handler.Context, handler)
	end)
	
	handler.Janitor:Add(function()
		local Index = table.find(self._InputHandlers, handler)
		
		if not Index then
			return
		end
		
		table.remove(self._InputHandlers, Index)
		
		self.ContextChanged:Fire(handler.Context)
	end)
	
	-- register
	table.insert(self._InputHandlers, handler)
	
	self.ContextChanged:Fire(handler.Context)
	
	return handler
end

function InputController._InitInputHandlers(self: Controller)
	
	local VaultCtor = require(script.Handlers.Skill.Vault)
	local SprintCtor = require(script.Handlers.Skill.Sprint)

	self:AddHandler(InputHandler.new(self, {Context = "Aim"}))
	self:AddHandler(VaultCtor.Create(self, {Context = "Vault"}))
	self:AddHandler(SprintCtor.Create(self, {Context = "Sprint", RespectGameProcessed = false}))
	
	self:AddHandler(InputHandler.new(self, {Context = "Skill1"})).IgnoreOnEnd = true
	self:AddHandler(InputHandler.new(self, {Context = "Skill2"})).IgnoreOnEnd = true
	self:AddHandler(InputHandler.new(self, {Context = "Skill3"})).IgnoreOnEnd = true
	self:AddHandler(InputHandler.new(self, {Context = "Skill4"})).IgnoreOnEnd = true
	
	self:AddHandler(InputHandler.new(self, {Context = "Interaction"})).IgnoreOnEnd = true
	self:AddHandler(InputHandler.new(self, {Context = "DropItem"})).IgnoreOnEnd = true
	
	
	--skill overrides constructors
	for _, Module in ipairs(script.Handlers.Overrides.Skill:GetChildren()) do
		
		local Source = require(Module)
		
		self._SkillInputHandlerOverrides[Source.SkillName] = Source
	end
end

function InputController._ProcessSkillAdded(self: Controller, skill: WCS.Skill)
	
	local InputContext = self:GetContextFromSkill(skill)
	
	--override initials
	local Override = self._SkillInputHandlerOverrides[ skill:GetName() ]
	local OverrideHandler = Override and self:AddHandler(Override.Create(self, InputContext)) or nil
	
	--print(Override, OverrideHandler, skill.Name, skill, InputContext)
	
	--waiting for skill janitor appear 😋
	while not skill.GenericJanitor do
		task.wait()
	end
	
	if OverrideHandler then
		skill.GenericJanitor:Add(
			OverrideHandler,
			"Destroy"
		)
		
		local Input = select(2, self:GetHighestContextPriority(InputContext))
		
		Input.Keybinds = self:GetKeybindsFromContext(Override.SkillName)
	end
	
	--functions
	local function Start()
		if skill:GetState().IsActive
			or skill:GetState().Debounce then

			return
		end

		skill:Start()
	end
	
	local function Cancel()
		if skill:GetState().IsActive then
			skill:End()
		end
	end
	
	skill.GenericJanitor:Add(
		self.ContextStarted:Connect(function(context, handler)
			if context ~= InputContext then
				return
			end
			
			--print(context, handler.Keybinds)
			
			if handler.StartWhileActive then
				
				handler.OnUpdate = Start
				
				handler.Ended:Once(function()
					
					if skill:IsDestroyed() then
						return
					end
					
					skill.GenericJanitor:Remove("__InputConnectionRemoval")
				end)
				
				skill.GenericJanitor:Add(
					handler.Janitor:Add(function()
						handler.OnUpdate = nil
					end),
					
					nil,
					
					"__InputConnectionRemoval"
				)
				
				return
			end
			
			if skill:GetState().IsActive and skill.FromRoleData.Cancelable then
				Cancel()
			else
				Start()
			end
		end)
	)
	
	skill.GenericJanitor:Add(
		self.ContextEnded:Connect(function(context, handler)
			if context ~= InputContext
				or handler.IgnoreOnEnd then
				
				return
			end
			
			skill:End()
		end)
	)
end

function InputController._ProcessInventoryAdded(self: Controller, inventory: unknown)
	
	local InventoryHandlerConstructor = require(script.Handlers.Inventory)
	local Handler = self:AddHandler(InventoryHandlerConstructor.Create(self, "Inventory"))
	
	local ScrollIndex = 0
	
	--cleanup
	inventory.Janitor:Add(Handler, "Destroy")
	
	--functions
	local function OnScroll(direction: number)
		if #inventory:GetSlotsWithItems() == 0 then
			return
		end

		local NextIndex = ScrollIndex + direction

		if NextIndex < 1 then
			
			NextIndex = #inventory.Slots
			
		elseif NextIndex > #inventory.Slots then
			
			NextIndex = 1
		end

		ScrollIndex = NextIndex

		local Slot = inventory:GetSlotFromIndex(ScrollIndex)

		if not Slot.Instance then
			OnScroll(direction)

			return
		end

		inventory:Equip(Slot)
	end
	
	local function OnSelect(index)
		local Slot = inventory:GetSlotFromIndex(index)
		
		if not Slot then
			return
		end

		if inventory:GetEquippedItem() == Slot.Instance then
			inventory:UnequipAll()
		else
			inventory:Equip(Slot)
		end
	end
	
	local function OnDrop()
		inventory:Drop()
	end
	
	--callbacks
	
	Handler.Selected:Connect(OnSelect)
	Handler.Scrolled:Connect(OnScroll)
	
	--drop callback
	inventory.Janitor:Add(self.ContextStarted:Connect(function(context)
		if context == "DropItem" then
			OnDrop()
		end
	end))
end

function InputController._InitComponentConnections(self: Controller)
	
	local CharacterComponent = PlayerController.CharacterComponent
	local InventoryComponent = PlayerController.InventoryComponent
	
	--character related
	local function OnCharacterAdded(component)
		
		for _, Skill: WCS.Skill in ipairs(component.WCSCharacter:GetSkills()) do
			self:_ProcessSkillAdded(Skill)
		end
		
		component.WCSCharacter.SkillAdded:Connect(function(...)
			self:_ProcessSkillAdded(...)
		end)
	end
	
	--inventory related
	local function OnInventoryAdded(component)
		self:_ProcessInventoryAdded(component)
	end
	
	--initials
	if CharacterComponent then
		OnCharacterAdded(CharacterComponent)
	end
	
	if InventoryComponent then
		OnInventoryAdded(InventoryComponent)
	end
	
	PlayerController.CharacterAdded:Connect(OnCharacterAdded)
	PlayerController.InventoryAdded:Connect(OnInventoryAdded)
end

function InputController._InitInputConnections(self: Controller)
	UserInputService.InputBegan:Connect(function(input, processed)
		for _, Handler in ipairs(self._InputHandlers) do
			if not Handler:ShouldProcessInput(input) then
				continue
			elseif processed and Handler.Options.RespectGameProcessed then
				continue
			end

			ThreadUtility.UseThread(Handler.OnInputBegan, Handler, input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input, processed)

		for _, Handler in ipairs(self._InputHandlers) do
			if not Handler:ShouldProcessInput(input) then
				continue
			elseif processed and Handler.Options.RespectGameProcessed then
				continue
			end

			ThreadUtility.UseThread(Handler.OnInputEnded, Handler, input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input, processed)
		
		for _, Handler in ipairs(self._InputHandlers) do
			if not Handler:ShouldProcessInput(input) then
				continue
			elseif processed and Handler.Options.RespectGameProcessed then
				continue
			end

			ThreadUtility.UseThread(Handler.OnInputChanged, Handler, input)
		end
	end)
	
	SettingsController.SettingChanged:Connect(function(Name)
		if Name ~= "Keybinds" then
			return
		end
		
		print("Saving input controller")
		
		for _, Handler in self._InputHandlers do
			local Setting = SettingsController:GetSetting(Handler.Context, true)
			
			print(Handler.Keybinds, Setting, Handler.Context, Handler.SkillName)
			
			Handler.Keybinds = Setting
		end
	end)
	
	--SettingsController.SettingsLoaded:Once(function(Name)
	--	print("Once loaded config, input controller")		

	--	for _, Handler in self._InputHandlers do
	--		Handler.Keybinds = SettingsController:GetSetting(Handler.Context, true)
	--	end
	--end)
end

function InputController._InitDeviceConnections(self: Controller)
	
	-- looks like roblox can only dynamically detect gamepad connections/disconnections, so for now only connect those events
	
	UserInputService.GamepadConnected:Connect(function()
		self.DeviceChanged:Fire(self:GetInputType())
	end)
	UserInputService.GamepadDisconnected:Connect(function()
		self.DeviceChanged:Fire(self:GetInputType())
	end)
end

function InputController.OnConstructClient(self: Controller)
	self._UserBindings = {}
	self._InputHandlers = {}
	self._SkillInputHandlerOverrides = {}
	
	self:_InitInputHandlers()
	self:_InitInputConnections()
	self:_InitDeviceConnections()
	self:_InitComponentConnections()
end

--//Returner

local Controller = InputController.new()
return Controller :: Controller