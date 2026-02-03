local client = shared.Client
local Util = client._requirements.Util

local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')
local InterfaceSFX = game:GetService('SoundService').Master.UI

-- class initial
local MenuUI = {} do
	MenuUI.__index = MenuUI

	function MenuUI.new( super )
		local self = setmetatable({
			super = super,
		}, MenuUI)
		return self
	end
end

return MenuUI