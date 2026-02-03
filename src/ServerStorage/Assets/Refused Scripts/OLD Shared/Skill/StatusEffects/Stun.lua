local server = shared.Server
local client = shared.Client
local IS_CLIENT = client ~= nil

-- getting WCS module link
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WCS = require(ReplicatedStorage.Package.wcs)

-- initial
local Stun = WCS.RegisterStatusEffect("Stun")
--[[

Applies when player got stunned.
While stunned, player cant jump and moves very slow

]]

-- overloads
function Stun:OnConstructServer()
	self.DestroyOnEnd = false
	self:SetHumanoidData({
		WalkSpeed = {-13, "Increment"},
		JumpPower = {0, "Set"}
	})
end

return Stun