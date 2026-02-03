local client = shared.Client

-- requirements
local Util = client._requirements.Util
local enumsModule = client._requirements.Enums
local SkillSlot = require(script.SkillSlot)

local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')
local InterfaceSFX = game:GetService('SoundService').Master.UI
local UserInputService = game:GetService('UserInputService')

-- paths
local MainUI = client._requirements.UI
local GameplayUI = MainUI.gameplay_ui
local reference: Frame? = GameplayUI.reference.SkillPanel
assert( reference, 'No SkillPanel frame exists in super.reference' )


-- SkillUI initial
local Initialized = false
local SkillUI = {}
SkillUI.slots = {}
SkillUI.enabled = true
SkillUI.reference = reference

-- initial method
function SkillUI:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	-- cleans up old created slots
	for _, raw_slot: TextButton? in ipairs(self.reference.Slots:GetChildren()) do
		if not raw_slot:IsA('TextButton') then continue end
		raw_slot:Destroy()
	end

	-- initializing slots for skills further set
	for _i = 1, 4 do
		local newSlot = SkillSlot.new( self, _i )
		newSlot:Init()

		table.insert(
			self.slots,
			newSlot
		)
	end
end


function SkillUI:GetSignForBindInput( bind_input: Enum.KeyCode|Enum.UserInputType )
	if bind_input == Enum.UserInputType.MouseButton1
		or bind_input == Enum.UserInputType.MouseButton2
	then return true, '' -- TODO: draw mouse input icons
		
		-- sensor touch icon
	elseif bind_input == Enum.UserInputType.Touch then
		return true, ''
		
	-- return string key bind
	else return false, UserInputService:GetStringForKeyCode( bind_input ) end
end

-- returns first non-binded slot
function SkillUI:GetBlankSlot()
	for _, slot: SkillSlot in ipairs(self.slots) do
		if not slot:IsClean() then continue end
		return slot
	end
end

-- returns first equal indexed slot
function SkillUI:GetSlotFromSkill( skill: string )
	for _, slot: SkillSlot in ipairs(self.slots) do
		if slot.skill ~= skill then continue end
		return slot
	end
end


function SkillUI:IsEnabled()
	return self.enabled
end


function SkillUI:SetEnabled( enabled: boolean )
	self.enabled = enabled
	self.reference.Visible = enabled
end


function SkillUI:GetActiveSkill()
	for _, slot: SkillSlot in ipairs(self.slots) do
		if slot:IsActive() then continue end
		return slot
	end 
end

-- creates a new slot object to apply visuals from real skill object
function SkillUI:BindSkill( skill_object )
	assert( not self:GetSlotFromSkill( skill_object ), 'Already binded skill' )

	-- getting clean slot to fill it with data
	local blank_slot = self:GetBlankSlot()
	assert( blank_slot, 'Unable to bind skill: Slots out of range' )

	-- filling a new skill to slot object
	blank_slot:SetSkill( skill_object )
end

-- sets all slots to unequipped state
function SkillUI:ResetSlots()
	for _, slot: SkillSlot.SkillSlot in ipairs(self.slots) do
		slot:SetSkill( nil )
	end
end

-- whole slots render update
function SkillUI:Update()
	for _, slot: SkillSlot.SkillSlot in ipairs(self.slots) do
		slot:Update()
	end
end

return SkillUI