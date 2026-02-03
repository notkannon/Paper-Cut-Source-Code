-- service
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local InstanceLabel = ReplicatedStorage.Assets.GUI.Proximities.Label

-- vars
local LABEL_INITIAL_POSES = {
	{Arrow = {'rbxassetid://17544336330', 'rbxassetid://17544336110'}, Pose = UDim2.fromScale(0, .9)},
	{Arrow = {'rbxassetid://17544376449', 'rbxassetid://17544376202'}, Pose = UDim2.fromScale(1, .2)},
	{Arrow = {'rbxassetid://17544432824', 'rbxassetid://17544433013'}, Pose = UDim2.fromScale(.5, .9)},
}

local CONTEXTUAL_ICONS = {
	Default = 'rbxassetid://18190296811',
	Clock = 'rbxassetid://18190243167', -- clock instances (has tag Clock)
	
}

-- type
type ProximityLabelConnections = {
	Changed: RBXScriptConnection,
	Destroyed: RBXScriptConnection,
	PromptHidden: RBXScriptConnection
}

-- class initial
local Label = {}
Label.__index = Label
Label._objects = {}

-- constructor
function Label.new(reference: ProximityPrompt)
	assert(reference:IsA('ProximityPrompt'), 'Prompt must be a "ProximityPrompt" instance')
	
	-- custom style (hiding prompt default)
	reference.Style = Enum.ProximityPromptStyle.Custom
	
	-- meta
	local self = setmetatable({
		reference = reference,
		label = InstanceLabel:Clone(),
		
		active = true,
		visible = false,
		initial_label = nil,
		
		last_arrow = 1,
		connections = {} :: ProximityLabelConnections
	}, Label)
	
	table.insert(
		self._objects,
		self
	)
	
	self:Init()
	return self
end

-- nuuh uh
function Label:Init()
	local connections: ProximityLabelConnections = self.connections
	local prompt = self.reference
	local label = self.label
	
	-- ui
	label.Enabled = false
	label.Parent = prompt.Parent
	
	local initial_label = LABEL_INITIAL_POSES[ math.random(1, #LABEL_INITIAL_POSES) ]
	self.initial_label = initial_label
	label.Arrow.Image = initial_label.Arrow[1]
	label.Sign.Detail.Text = prompt.ObjectText
	
	-- getting icon for a label
	local context = prompt:GetAttribute('Context')
	local icon = context and CONTEXTUAL_ICONS[ context ] or CONTEXTUAL_ICONS.Default
	label.Sign.Image = icon
	
	-- prompt.Shown but once
	self:SetVisible(true)
	
	-- connections
	connections.Destroyed = prompt.Destroying:Once(function() self:Destroy() end)
	connections.Changed = prompt.Changed:Connect(function(...) self:OnChanged(...) end)
	connections.PromptHidden = prompt.PromptHidden:Once(function()
		print("Destroyed")
		self:Destroy() -- destroys prompt wrapper when hidden
	end)
end

-- visuals
function Label:SetVisible(visible: boolean)
	local label: BillboardGui = self.label
	
	if visible then
		label.Enabled = true
		label.Arrow.Size = UDim2.fromScale(0, 0)
		label.Sign.Size = UDim2.fromScale(0, 0)
		label.Arrow.ImageTransparency = .5
		label.Sign.ImageTransparency = 1
		label.Sign.Detail.TextTransparency = 1
		label.Sign.Position = UDim2.fromScale(.5, .5)
		
		label.Arrow:TweenSize(UDim2.fromScale(.9, .9), 'Out', 'Sine', .3, true)
		label.Sign:TweenSize(UDim2.fromScale(1, .2), 'Out', 'Sine', .4, true)
		label.Sign:TweenPosition(self.initial_label.Pose, 'Out', 'Sine', .4, true)
		TweenService:Create(label.Sign, TweenInfo.new(.3), {ImageTransparency = .5}):Play()
		TweenService:Create(label.Sign.Detail, TweenInfo.new(.3), {TextTransparency = 0}):Play()
	else
		TweenService:Create(label.Sign.Detail, TweenInfo.new(.3), {TextTransparency = 1}):Play()
		label.Arrow:TweenSize(UDim2.fromScale(0, 0), 'In', 'Sine', .3, true)
		label.Sign:TweenPosition(UDim2.fromScale(.5, .5), 'In', 'Sine', .4, true)
		label.Sign:TweenSize(UDim2.fromScale(1, 0), 'In', 'Sine', .4, true, function()
			label.Enabled = false
			label:Destroy()
		end)
	end
end

-- calls when prompt instance changes
function Label:OnChanged(property: string)
	if property == 'ObjectText' then
		self.label.Sign.Detail.Text = self.reference.ObjectText
	end
end


function Label:Update()
	local label: BillboardGui = self.label
	local next_arrow = self.last_arrow == 1 and 2 or 1
	
	label.Arrow.Image = self.initial_label.Arrow[next_arrow]
	self.last_arrow = next_arrow
end

-- cleaning up
function Label:Destroy()
	for _, connection: RBXScriptConnection in pairs(self.connections) do
		connection:Disconnect()
	end
	
	self:SetVisible(false)
	
	table.clear(self)
	setmetatable(self, nil)
	table.remove(
		Label._objects,
		table.find(Label._objects, self)
	)
end

return Label