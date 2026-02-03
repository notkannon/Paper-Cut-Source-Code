local server = shared.Server
local client = shared.Client
local IS_CLIENT = client ~= nil

-- declarations
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- getting refx module link
local Refx = require(ReplicatedStorage.Package.refx)
local Flashlight = Refx.CreateEffect('ItemFlashlightDisable')

-- methods
function Flashlight:OnStart()
	local instance: Tool = self.Configuration[1]
	instance.Base.Neon.Material = Enum.Material.SmoothPlastic
	instance.Base.Spotlight.Enabled = false
	instance.Base.Beam.Enabled = false
	instance.Base.Off:Play()
end

return Flashlight