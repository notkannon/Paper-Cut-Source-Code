-- getting WCS module link
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WCS = require(ReplicatedStorage.Package.wcs)
local BaseHoldableSkill = require(script.Parent.Parent.BaseHoldableSkill)

-- initial
local Taunt = WCS.RegisterHoldableSkill("Taunt", BaseHoldableSkill)
local SkillData = {
	cooldown = 3,
	
	input = {
		create_touch_button = true, -- used on sensor devices
		is_holdable = false,
		input_objects = {
		}
	},
	
	name = 'Taunt',
	description = 'Used for player`s custom emotes control!',
	display_order = 1000,
	skill_icon = ''
}

-- overloads
function Taunt:OnStartServer( data )
	self:ApplyCooldown( self:GetData().cooldown )
	print('DATA:', data)
end

-- could use metadata to determine player`s taunt
function Taunt:OnStartClient()
	warn("[CLIENT] Hi, taunt just started!")
	--[[local CharacterObject = client.local_character
	CharacterObject:_apply_taunt( self:GetMetadata() )]]
	--local TauntService = requirements.TauntService
	--TauntService:PlayTaunt( 1 )
end

-- skill data set
function Taunt:OnConstruct()
	self.Data = SkillData
end

return Taunt