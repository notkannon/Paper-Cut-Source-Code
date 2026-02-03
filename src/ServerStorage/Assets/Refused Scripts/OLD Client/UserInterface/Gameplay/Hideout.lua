local client = shared.Client

-- requirements
local requirements = client._requirements
local enumsModule = requirements.Enums
local Util = requirements.Util

local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')
local InterfaceSFX = game:GetService('SoundService').Master.UI
local ContextActionService = game:GetService('ContextActionService')

-- paths
local MainUI = client._requirements.UI
local GameplayUI = MainUI.gameplay_ui
local reference: Frame? = GameplayUI.reference.Hideout
assert( reference, 'No taunts frame exists in super.reference' )


-- HideoutUI initial
local Initialized = false
local HideoutUI = {}
HideoutUI.enabled = false
HideoutUI.visible = true
HideoutUI.reference = reference
HideoutUI.modal = reference.Modal -- mouse lock option

-- initial method
function HideoutUI:Init()
	if Initialized then return end
	HideoutUI._Initialized = true
	Initialized = true
	
	self:SetVisible( false )
end

-- boolean
function HideoutUI:IsEnabled()
	return self.enabled
end

-- enabling (connection setting)
function HideoutUI:SetEnabled( enabled: boolean )
	if self.enabled == enabled then return end
	self.enabled = enabled
	
	-- handling
	HideoutUI:SetVisible(enabled)
end


function HideoutUI:SetVisible(visible: boolean)
	local vignette: ImageLabel = GameplayUI.reference:FindFirstChild('LockerVignette')
	local transparency = visible and .7 or 1
	
	reference.Visible = visible
	MainUI:ClearTweensForObject(vignette)
	MainUI:AddObjectTween(TweenService:Create(vignette, TweenInfo.new(.5), {ImageTransparency = transparency})):Play()
end

--[[function HideoutUI:SetVisible( visible: boolean )
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
end]]


-- complete
return HideoutUI