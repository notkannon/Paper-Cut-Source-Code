local server = shared.Server
local client = shared.Client
local IS_CLIENT = client ~= nil

-- getting WCS module link
-- getting WCS module link
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WCS = require(ReplicatedStorage.Package.wcs)

-- initial
local Spinner = WCS.RegisterSkill("Stealth")
local SkillData = {
	cooldown = 15,
	create_touch_button = true, -- used on sensor devices

	--[[input = {
		is_holdable = true,

		input_objects = {
			Enum.KeyCode.Three,
			Enum.UserInputType.Gamepad1
		}
	},]]

	name = 'Spinner',
	description = 'Unique Miss Bloomie`s skill. Makes you rotate around yourself with a huge damage. Useful in near distance',
	display_order = 3,
	skill_icon = 'rbxassetid://17607925845'
}

-- overloads
function Spinner:OnStartServer()
	self:ApplyCooldown( self:GetData().cooldown )
end


function Spinner:OnStartClient()
	warn("[CLIENT] Hi, Spinner just started!")
end

-- skill data set
function Spinner:OnConstruct() self.Data = SkillData end
function Spinner:GetData()	return self.Data end

return Spinner