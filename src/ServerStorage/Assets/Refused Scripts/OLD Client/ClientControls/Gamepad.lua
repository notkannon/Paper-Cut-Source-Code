local Client = shared.Client

-- service
local ContextActionService = game:GetService('ContextActionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

-- requirements
local BaseControls = require(script.Parent.BaseControls)


--// INITIALIZATION
local GamepadControls = BaseControls.new()
GamepadControls.Definition = 'Gamepad'
GamepadControls:Init()

return GamepadControls