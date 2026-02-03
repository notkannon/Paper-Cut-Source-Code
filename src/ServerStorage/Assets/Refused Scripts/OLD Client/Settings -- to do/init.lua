local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

--// Imports

local Util = require(ReplicatedStorage.Shared.Util)
local Signal = require(ReplicatedStorage.Package.Signal)
local BaseSettingsProperty = require(script.BaseSettingsProperty)
local PropertyContainer = script.Container

--// Initialization

local Initialized = false
local Settings = setmetatable({}, {ClassName = 'Settings'})
Settings.PropertyChanged = Signal.new()
Settings.Container = {}

--// Methods

function Settings:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	-- idk just initialize
	Settings:RegisterPropertiesIn(PropertyContainer)
end

-- returns first property object with same name
function Settings:GetPropertyFromName(name: string)
	
end

-- adds new property into settings singleton
function Settings:AddProperty(setting)
	
end

-- quick parse all settings in given directory
function Settings:RegisterPropertiesIn(dir: Instance)
	
end

return Settings