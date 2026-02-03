local client = shared.Client

-- requirements
local Util = client._requirements.Util
local Camera = workspace.CurrentCamera
local playerMouse = game.Players.LocalPlayer:GetMouse()

-- service
local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')
local InterfaceSFX = game:GetService('SoundService').Master.UI

-- paths
local MainUI = client._requirements.UI
local reference: Frame? = MainUI.reference.Screen.Cursor
assert( reference, 'No cursor frame exists in ScreenGui' )

-- class initial
local Mouse = {}
Mouse.__index = Mouse
Mouse.reference = reference
Mouse.action_charge_reference = reference.ActionCharge
Mouse.ProximityScreenOffset = nil
Mouse.LastProximity = nil


function Mouse:Init()
	game:GetService('UserInputService').MouseIconEnabled = false
	self:ActionChargeSetVisible( false )
	
	-- proximity prompt connection
	--client._requirements.ProximityPrompt.PromptShown:Connect(function(ClientPrompt)
	--	local Reference: ProximityPrompt = ClientPrompt.reference
	--	Mouse.LastProximity = Reference
		
	--	-- getting world position to project it to screen
	--	if Reference.Parent:IsA('Attachment') then
	--		Mouse.ProximityScreenOffset = Reference.Parent.WorldPosition
	--	else Mouse.ProximityScreenOffset = Reference.Parent.Position end
		
	--	Reference.PromptHidden:Wait()
		
	--	-- if prompt just hidden without overrides of others
	--	if Mouse.LastProximity == Reference then
	--		Mouse.ProximityScreenOffset = nil
	--	end
	--end)
end


function Mouse:SetLocked(locked: boolean)
end


function Mouse:Update()
	local Width = Camera.ViewportSize.X
	local Height = Camera.ViewportSize.Y
	local CenterX = Width * .5
	local CenterY = Height * .5
	
	local Offset = UDim2.fromOffset(CenterX, CenterY)
	
	-- defomation for proximities
	if Mouse.ProximityScreenOffset then
		local OnScreen: Vector3 = workspace.CurrentCamera:WorldToViewportPoint(Mouse.ProximityScreenOffset)
		Offset = Offset:Lerp( UDim2.fromOffset(OnScreen.X, OnScreen.Y), .7 )
	end
	
	-- smooth changing
	reference.Position = reference.Position:Lerp(Offset, 1/5)
end


function Mouse:ActionChargeSetVisible( visible: bool )
	TweenService:Create(self.action_charge_reference, TweenInfo.new(.5), {BackgroundTransparency = visible and 0 or 1}):Play()
	self.action_charge_reference.Visible = visible
end


function Mouse:ActionChargeSetValue( value: number )
	self.action_charge_reference.BackgroundColor3 = Color3.fromHSV(value * .3, .7, 1)
	self.action_charge_reference.Value.Offset = Vector2.new(0, 1- value)
end

return Mouse