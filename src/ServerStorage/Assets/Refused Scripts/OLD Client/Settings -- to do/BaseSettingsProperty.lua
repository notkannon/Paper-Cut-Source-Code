--// Service

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

--// Imports

local Util = require(ReplicatedStorage.Shared.Util)
local Signal = require(ReplicatedStorage.Package.Signal)

local _ValidTypes = {
	'number',
	'string',
	'boolean',
}

--// Type definition

type Void = nil

export type SettingsPropertyParams = {
	Name: string,
	Type: string,
	Value: any,
	Description: string,
	Validator: <T>(T: any) -> boolean,
}

type BaseSettingsPropertyFields = SettingsPropertyParams & { Changed: Signal.Signal }
type BaseSettingsPropertyImpl = {
	new: (SettingsPropertyParams) -> BaseSettingsProperty,
	Set: <T>(T: any) -> Void,
	Validate: <T>(T: any) -> boolean,
}

export type BaseSettingsProperty = typeof(setmetatable({} :: BaseSettingsPropertyFields, {} :: BaseSettingsPropertyImpl))

--// Initialization

local BaseSettingsProperty = {}
BaseSettingsProperty.__index = BaseSettingsProperty

--// Methods
-- constructor
function BaseSettingsProperty.new(params: SettingsPropertyParams)
	assert(table.find(_ValidTypes, params.Type), `Invalid Type passed ({ params.Type })`)
	
	local self: BaseSettingsProperty = setmetatable(Util.Reconcile(1, params), BaseSettingsProperty)
	self.Changed = Signal.new()
	self.Value = self.Starter
	
	return self
end

-- set current value for setting
function BaseSettingsProperty.Set(self: BaseSettingsProperty, value: any): Void
	if not self:Validate(value) then return end
	self.Changed:Fire(value, self.Value)
	self.Value = value
end

-- returns true if value passed validation and false if not
function BaseSettingsProperty.Validate(self: BaseSettingsProperty, value: any): boolean
	assert(self.Validator, `Validator was not defined for property { self.Name }`)
	return self.Validator( value )
end

--// Returner

return BaseSettingsProperty