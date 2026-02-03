-- getting WCS module link
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WCS = require(ReplicatedStorage.Package.wcs)

-- initial
local Downed = WCS.RegisterStatusEffect("Downed")
--[[

Applies when player got downed (<15 HP).
While DOwned, player cant jump and moves veryy slow

]]

-- overloads
function Downed:OnConstructServer()
	self.DestroyOnEnd = false
	self:SetHumanoidData({
		WalkSpeed = {5, "Set"},
		JumpPower = {0, "Set"}
	})
end


function Downed:OnStartServer()
	print('Downed!')
end


function Downed:OnEndServer()
	print('Not Downed!')
end

return Downed