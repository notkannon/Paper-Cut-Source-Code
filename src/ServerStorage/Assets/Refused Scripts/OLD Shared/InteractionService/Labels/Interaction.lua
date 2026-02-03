local Client = shared.Client
local Requirements = Client._requirements

-- service
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local InstanceLabel = ReplicatedStorage.Assets.GUI.Proximities.Interaction

-- requirements
local UserInterface = Requirements.UI

-- vars
local LABEL_INITIAL_POSES = {
	{Arrow = {'rbxassetid://17544336330', 'rbxassetid://17544336110'}, Pose = UDim2.fromScale(0, .9)},
	{Arrow = {'rbxassetid://17544376449', 'rbxassetid://17544376202'}, Pose = UDim2.fromScale(1, .2)},
	{Arrow = {'rbxassetid://17544432824', 'rbxassetid://17544433013'}, Pose = UDim2.fromScale(.5, .9)},
}

-- type
type ProximityPromptConnections = {
	Changed: RBXScriptConnection,
	Destroyed: RBXScriptConnection,
	Triggered: RBXScriptConnection,
	TriggerEnded: RBXScriptConnection,
	PromptButtonHoldBegan: RBXScriptConnection,
	PromptButtonHoldEnded: RBXScriptConnection,
	PromptHidden: RBXScriptConnection
}

-- class initial
local InteractionLabel = {}
InteractionLabel._objects = {}
InteractionLabel.__index = InteractionLabel

-- constructor
function InteractionLabel.new( interaction )
	local instance: ProximityPrompt = interaction:GetInstance()
	
	-- custom style (hiding prompt default)
	instance.Style = Enum.ProximityPromptStyle.Custom
	
	-- meta
	local self = setmetatable({
		Instance = instance,
		Interaction = interaction,
		Label = UserInterface.cursor.reference.PromptLabel:Clone(), --InstanceLabel:Clone(),
		
		active = true,
		holded = false,
		visible = false,
		triggered = false,
		initial_label = nil,
		
		last_arrow = 1,
		connections = {} :: ProximityPromptConnections
	}, InteractionLabel)
	
	print(self.connections)
	table.insert(
		self._objects,
		self
	)
	
	self:Init()
	return self
end

-- nuuh uh
function InteractionLabel:Init()
	local connections: ProximityPromptConnections = self.connections
	local interaction = self.Interaction
	local prompt = self.Instance
	local label = self.Label
	
	-- ui
	label.Visible = false
	label.Parent = UserInterface.cursor.reference
	
	local initial_label = LABEL_INITIAL_POSES[ math.random(1, #LABEL_INITIAL_POSES) ]
	self.initial_label = initial_label
	label.Arrow.Image = initial_label.Arrow[1]
	label.Sign.Detail.Text = `{ prompt.KeyboardKeyCode.Name } - { prompt.ActionText }`
	
	-- prompt.Shown but once
	self:SetVisible(true)
	
	-- proximity prompt instance change detection
	connections.Changed = prompt.Changed:Connect(function(...) self:OnChanged(...) end)
	
	-- interaction object connection
	connections.Triggered = interaction.Triggered:Connect(function() self:SetTriggered(true) end)
	connections.TriggerEnded = interaction.TriggerEnded:Connect(function() self:SetTriggered(false) end)
	connections.PromptButtonHoldBegan = interaction.PromptButtonHoldBegan:Connect(function() self:SetHolded(true) end)
	connections.PromptButtonHoldEnded = interaction.PromptButtonHoldEnded:Connect(function() self:SetHolded(false) end)
	
	-- cleanup
	connections.Destroyed = interaction.Destroyed:Once(function() self:Destroy() end)
	connections.PromptHidden = interaction.PromptHidden:Once(function()
		self:Destroy() -- destroys prompt wrapper when hidden
	end)
end

-- visuals
function InteractionLabel:SetVisible(visible: boolean)
	local label: BillboardGui = self.Label
	
	if visible then
		label.Visible = true
		label.Arrow.Size = UDim2.fromScale(0, 0)
		label.Sign.Size = UDim2.fromScale(0, 0)
		label.Sign.Fill.Offset = Vector2.new(0, 1)
		label.Arrow.ImageTransparency = .5
		label.Sign.Detail.TextTransparency = 1
		label.Sign.Position = UDim2.fromScale(.5, .5)
		
		label.Arrow:TweenSize(UDim2.fromScale(.9, .9), 'Out', 'Sine', .3, true)
		label.Sign:TweenSize(UDim2.fromScale(1, .2), 'Out', 'Sine', .4, true)
		label.Sign:TweenPosition(self.initial_label.Pose, 'Out', 'Sine', .4, true)
		TweenService:Create(label.Sign.Detail, TweenInfo.new(.3), {TextTransparency = .5}):Play()
	else
		TweenService:Create(label.Sign.Detail, TweenInfo.new(.3), {TextTransparency = 1}):Play()
		label.Arrow:TweenSize(UDim2.fromScale(0, 0), 'In', 'Sine', .3, true)
		label.Sign:TweenPosition(UDim2.fromScale(.5, .5), 'In', 'Sine', .4, true)
		label.Sign:TweenSize(UDim2.fromScale(1, 0), 'In', 'Sine', .4, true, function()
			label.Visible = false
			label:Destroy()
		end)
	end
end

function InteractionLabel:SetHolded(holded: boolean)
	local label: BillboardGui = self.Label
	
	if holded then
		label.Sign.Fill.Offset = Vector2.new(0, 1)
		label.Sign:TweenSize(UDim2.fromScale(1, .15), 'Out', 'Back', .1, true)
		TweenService:Create(label.Sign.Fill, TweenInfo.new(self.Instance.HoldDuration), {Offset = Vector2.new(0, 0)}):Play()
	else
		label.Sign:TweenSize(UDim2.fromScale(1, .2), 'Out', 'Sine', .1, true)
		TweenService:Create(label.Sign.Fill, TweenInfo.new(.3), {Offset = Vector2.new(0, 1)}):Play()
	end
end

function InteractionLabel:SetTriggered(triggered: boolean)
	local label: BillboardGui = self.Label
	
	if triggered then
		label.Arrow.ImageTransparency = 0
		label.Sign.Fill.Offset = Vector2.new(0, 0)
		label.Arrow.Size = UDim2.fromScale(1, 1)
		label.Sign.Size = UDim2.fromScale(1, .3)
		label.Arrow:TweenSize(UDim2.fromScale(.9, .9), 'Out', 'Sine', .3, true)
		label.Sign:TweenSize(UDim2.fromScale(1, .2), 'Out', 'Back', .1, true)
		TweenService:Create(label.Sign.Fill, TweenInfo.new(.1), {Offset = Vector2.new(0, 0)}):Play()
	else
		label.Arrow.ImageTransparency = .5
		label.Sign.Fill.Offset = Vector2.new(0, 0)
		TweenService:Create(label.Sign.Fill, TweenInfo.new(.1), {Offset = Vector2.new(0, 1)}):Play()
	end
end


function InteractionLabel:OnChanged(property: string)
	if property == 'ActionText' then
		local prompt = self.Instance
		self.Label.Sign.Detail.Text = `{ prompt.KeyboardKeyCode.Name } - { prompt.ActionText }`
	end
end


function InteractionLabel:Update()
	local label: BillboardGui = self.Label
	local next_arrow = self.last_arrow == 1 and 2 or 1
	
	label.Arrow.Image = self.initial_label.Arrow[next_arrow]
	self.last_arrow = next_arrow
end

-- cleaning up
function InteractionLabel:Destroy()
	for _, connection: RBXScriptConnection in pairs(self.connections) do
		connection:Disconnect()
	end
	
	table.remove(InteractionLabel._objects,
		table.find(InteractionLabel._objects, self)
	)
	
	self:SetTriggered(false)
	self:SetHolded(false)
	self:SetVisible(false)
	
	table.clear(self)
	setmetatable(self, nil)
end

return InteractionLabel