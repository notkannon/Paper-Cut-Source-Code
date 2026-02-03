local Client = shared.Client

-- service
local ContextActionService = game:GetService('ContextActionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

-- requirements
local BaseControls = require(script.Parent.BaseControls)


--// INITIALIZATION
local SensorControls = BaseControls.new()
SensorControls.Definition = 'Sensor'
SensorControls:Init()

return SensorControls