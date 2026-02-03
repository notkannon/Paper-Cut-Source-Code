-- getting WCS module link
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WCS = require(ReplicatedStorage.Package.wcs)

-- initial
local Injured = WCS.RegisterStatusEffect("Injured")
--[[

Applies when player got damaged (<50 HP).
While Injured, player cant jump and moves slower

]]

-- overloads
function Injured:OnConstructServer()
	self.DestroyOnEnd = false
	self:SetHumanoidData({
		WalkSpeed = {-7, "Increment"},
		JumpPower = {0, "Set"}
	})
end


function Injured:OnStartServer()
	print('Injured!')
end


function Injured:OnEndServer()
	print('Not Injured!')
end

return Injured