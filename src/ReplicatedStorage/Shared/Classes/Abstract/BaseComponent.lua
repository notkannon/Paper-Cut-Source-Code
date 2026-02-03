--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(script.Parent.Parent)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local GlobalSettings = require(ReplicatedStorage.Shared.Data.GlobalSettings)

--//Constants

local LOGGING_ENABLED = GlobalSettings.Classes.ToggleComponentsConstructionLogging

--//Variables

local NameComponents: { [string]: { BaseImpl } } = {}
local ComponentOptions: ComponentOptions = {}
local BaseComponent = Classes.CreateClass("BaseComponent", true) :: BaseImpl

--//Types

export type Options = {
	tag: string?,
	isAbstract: boolean?,
	defaults: { [string]: any }?,
	ancestorWhitelist: { Instance }?,
	ancestorBlacklist: { Instance }?,
	predicate: ((Instance) -> boolean)?,
}

export type ComponentOptions = { [BaseImpl]: Options }

export type ComponentImpl<EXImpl, EXFields, Name, InstanceType, Defaults, Args...> = {
	__index: ComponentImpl<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>,

	IsImpl: (self: Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>) -> boolean,
	GetName: () -> Name,
	GetOptions: () -> Options,
	GetExtendsFrom: () -> BaseImpl?,
	
	Destroy: (self: Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>) -> (),
	IsDestroyed: (self: Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>) -> boolean,
	IsDestroying: (self: Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>) -> boolean,

	new: (instance: Instance, Args...) -> Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>,
	OnConstruct: (self: Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>, Args...) -> (),
	OnConstructServer: (self: Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>, Args...) -> (),
	OnConstructClient: (self: Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>, Args...) -> (),
	OnTick: (self: Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>, delta: number) -> (),
	OnPhysics: (self: Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>, time: number, delta: number) -> (),
	OnRender: (self: Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>, delta: number) -> (),
	OnDestroy: (self: Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>) -> (),
}

export type ComponentFields<Name, InstanceType, Defaults> = {
	Janitor: Janitor.Janitor,
	Instance: InstanceType,
	Destroyed: Signal.Signal,
	
	Attributes: Defaults & {
		SetAttribute: (string, unknown) -> (),
		AttributeChanged: Signal.Signal<string, any>,
	},
	
	_Destroying: boolean,
	_Destroyed: boolean,
}

export type Component<EXImpl, EXFields, Name, InstanceType, Defaults, Args...> =
	typeof(setmetatable(
		{} :: ComponentFields<Name, InstanceType, Defaults>,
		BaseComponent :: ComponentImpl<EXImpl, EXFields, Name, InstanceType, Defaults, Args...>
	))
	& typeof(setmetatable({}, ({} :: any) :: EXImpl))
	& EXFields

export type BaseImpl = ComponentImpl<any, any, string, any, { [string]: any }, ...any>
export type BaseComponent = Component<any, any, string, any, { [string]: any }, ...any>

--//Functions

local function GetNameComponents(): { [string]: { unknown } }
	return table.clone(NameComponents)
end

local function GetComponentOptions(): ComponentOptions
	return table.clone(ComponentOptions)
end

local function CreateComponent(
	name: string,
	options: Options?,
	extendsFrom: { unknown }?
): ComponentImpl<unknown, unknown, unknown, unknown, { [string]: unknown }, ...unknown>
	
	if extendsFrom then
		assert(ComponentOptions[extendsFrom], `Invalid extendable component for {name}.`)
	end

	local Options = options or {} :: Options

	if Options.isAbstract == nil then
		Options.isAbstract = false
	end

	if extendsFrom then
		Options = TableKit.MergeDictionary(ComponentOptions[extendsFrom], Options)
		Options.defaults = TableKit.MergeDictionary(ComponentOptions[extendsFrom].defaults or {}, Options.defaults or {})
	end

	local Super = extendsFrom or BaseComponent
	local Component = Classes.Create(NameComponents, "Component", name, true, Super)
	
	--we can create component only if that not abstract
	if not Options.isAbstract then
		
		function Component.new(instance: Instance, ...)
			local self = setmetatable({}, Component)
			return self:_Constructor(instance, TableKit.DeepCopy(Options), ...) or self
		end
	end

	function Component.GetOptions()
		return Options
	end
	
	ComponentOptions[Component] = Options
	return Component
end

--//Methods

function BaseComponent._Constructor(self: BaseComponent, instance: Instance, options: Options, ...: any)
	
	self.Instance = instance
	self.Janitor = Janitor.new()
	
	local InternalRemovalJanitor = Janitor.new()
	InternalRemovalJanitor:LinkToInstance(instance, true)
	InternalRemovalJanitor:Add(function()

		if self:IsDestroying()
			or self:IsDestroyed() then

			return
		end

		--we add this cuz not always we can expect eisting instance when calling ComponentsManager.Remove()
		self:Destroy()
	end)
	
	--listening for instance removal, cleanup default janitor on instance destroy
	self.Janitor:LinkToInstance(instance, true)
	
	self.Attributes = setmetatable({}, {
		__newindex = function()
			return error(`Attributes requires .defaults table on { self:GetName() } component definition`)
		end
	})
	
	self.Destroyed = Signal.new()
	self._Destroyed = false
	self._Destroying = false
	
	--initializing attributes
	if options.defaults then
		
		setmetatable(self.Attributes, nil)
		
		local AfterAttributeChanged = self.Janitor:Add(Signal.new())
		
		self.Attributes = setmetatable({}, {
			
			__index = function(_, index)
				if index == "AttributeChanged" then
					return AfterAttributeChanged
				end

				return options.defaults[index]
			end,
			
			__newindex = function(table, index, value)
				if
					options.defaults[index] == nil
					or value == options.defaults[index]
					or type(value) ~= type(options.defaults[index])
				then
					return
				end
				
				options.defaults[index] = value
				
				AfterAttributeChanged:Fire(index, value)
				instance:SetAttribute(index, value)
			end,
		})

		for AttributeName, Value in pairs(options.defaults) do
			
			local Attribute = instance:GetAttribute(AttributeName)

			if Attribute ~= nil then
				options.defaults[AttributeName] = Attribute
			else
				instance:SetAttribute(AttributeName, Value)
			end
		end

		self.Janitor:Add(instance.AttributeChanged:Connect(function(attribute)
			local Value = instance:GetAttribute(attribute)
			local ClassAttribute = options.defaults[attribute]

			if Value == ClassAttribute or ClassAttribute == nil then
				return
			end

			if type(Value) ~= type(ClassAttribute) then
				instance:SetAttribute(attribute, ClassAttribute)
				return
			end

			options.defaults[attribute] = Value
			AfterAttributeChanged:Fire(attribute, Value)
		end))
	end
	
	--local Marker = os.clock()
	
	self:OnConstruct(...)
	
	if RunService:IsServer() then
		self:OnConstructServer(...)
		
	elseif RunService:IsClient() then
		self:OnConstructClient(...)
	end
	
	--if LOGGING_ENABLED then
	--	print(`Constructed component: { os.clock() - Marker }s { self.GetName() }`)
	--end
	
	if self.OnTick then
		self.Janitor:Add(RunService.Heartbeat:Connect(function(delta)
			self:OnTick(delta)
		end))
	end

	if self.OnPhysics then
		self.Janitor:Add(RunService.Stepped:Connect(function(time, delta)
			self:OnPhysics(time, delta)
		end))
	end

	if self.OnRender then
		assert(RunService:IsClient(), "Client only method. Use 'OnTick' instead.")

		self.Janitor:Add(RunService.RenderStepped:Connect(function(delta)
			self:OnRender(delta)
		end))
	end
end

function BaseComponent.IsDestroying(self: BaseComponent)
	return self._Destroying
end

function BaseComponent.IsDestroyed(self: BaseComponent)
	return self._Destroyed
end

function BaseComponent.Destroy(self: BaseComponent)
	if self._Destroyed or self._Destroying then
		return
	end
	
	self._Destroying = true
	
	self:OnDestroy()
	
	if self.Janitor then
		self.Janitor:Destroy()
	end
	
	if self.Attributes.AttributeChanged then
		
		setmetatable(self.Attributes, nil)
		table.clear(self.Attributes)
	end
	
	self.Destroyed:Fire()
	self.Destroyed:Destroy()
	
	--cleaning all links
	table.clear(self)
	
	self._Destroyed = true
	
	table.freeze(self)
end

function BaseComponent:OnConstruct() end

function BaseComponent:OnConstructServer() end

function BaseComponent:OnConstructClient() end

function BaseComponent:OnDestroy() end

--//Returner

return {
	GetNameComponents = GetNameComponents,
	GetComponentOptions = GetComponentOptions,
	CreateComponent = CreateComponent,
}