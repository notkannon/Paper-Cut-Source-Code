local Client = shared.Client

-- service
local ContextActionService = game:GetService('ContextActionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

-- requirements
local BaseControls = require(script.Parent.BaseControls)


--// INITIALIZATION
local VRControls = BaseControls.new()
VRControls.Definition = 'VR'
VRControls:Init()

return VRControls