local client = shared.Client

-- requirements
local Util = client._requirements.Util
local enumsModule = client._requirements.Enums
local TauntSlot = require(script.TauntSlot)

local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')
local InterfaceSFX = game:GetService('SoundService').Master.UI
local UserInputService = game:GetService('UserInputService')

-- paths
local MainUI = client._requirements.UI
local GameplayUI = MainUI.gameplay_ui
local reference: Frame? = GameplayUI.reference.Taunts
assert( reference, 'No taunts frame exists in super.reference' )

-- const
local PLACEMENT_RADIUS = .85
local PLACEMENT_OFFSET = .5


-- class initial
local Initialized = false
local TauntUI = {}
TauntUI.slots = {}
TauntUI.visible = true
TauntUI.enabled = true
TauntUI.modal = reference.Modal -- mouse lock option
TauntUI.reference = reference

-- initial method
function TauntUI:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	-- cleans up old created slots
	for _, raw_slot: TextButton? in ipairs(reference.Slots:GetChildren()) do
		if not raw_slot:IsA('TextButton') then continue end
		raw_slot:Destroy()
	end
	
	-- initializing slots for taunts further set
	for _i = 1, 5 do
		local position = UDim2.fromScale(
			math.cos( math.pi * 2 * (1 - _i) * .2 ) * PLACEMENT_RADIUS + PLACEMENT_OFFSET,
			math.sin( math.pi * 2 * (1 - _i) * .2 ) * PLACEMENT_RADIUS + PLACEMENT_OFFSET
		)
		
		table.insert(
			self.slots,
			TauntSlot.new(
				self,
				_i,
				position
			)
		)
	end
	
	-- lol
	self:SetVisible( false )
end

-- returns first equal indexed slot
function TauntUI:GetSlotByTauntEnum( taunt_enum: number )
	for _, slot: TauntSlot.TauntSlot in ipairs(self.slots) do
		if slot.taunt.enum ~= taunt_enum then continue end
		return slot
	end
end


function TauntUI:IsEnabled()
	return self.enabled
end


function TauntUI:SetEnabled( enabled: boolean )
	if self.enabled == enabled then return end
	self.enabled = enabled
	
	if not enabled then
		self:SetVisible( false )
	end
end


function TauntUI:SetVisible( visible: boolean )
	if visible and not self:IsEnabled() then return end
	if self.visible == visible then return end
	
	self.visible = visible
	self.modal.Visible = visible
	
	MainUI:ClearTweensForObject( reference.Back )
	MainUI:AddObjectTween(TweenService:Create(
		reference.Back,
		TweenInfo.new(.5),
		{ImageTransparency = visible and .5 or 1}
		)
	):Play()
	
	for _, slot: TauntSlot.TauntSlot in ipairs(self.slots) do
		slot:SetVisible( visible )
		task.wait( .05 )
	end
end


function TauntUI:GetSelectedSlot()
	for _, slot: SkillSlot in ipairs(self.slots) do
		if not slot:IsSelected() then continue end
		return slot
	end 
end



-- sets all slots to unequipped state
function TauntUI:ResetSlots()
	for _, slot: TauntSlot.TauntSlot in ipairs(self.slots) do
		slot:SetTaunt( nil )
	end
end

return TauntUI