--//Service

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Import

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local Hold = require(script.Parent.Hold)

local Interactable = BaseComponent.GetNameComponents().Interactable

--//Variables
local UIProximities = ReplicatedStorage.Assets.UI.Proximities
local LABEL_INITIAL_POSES = table.freeze({
	{Arrow = {'rbxassetid://17544336330', 'rbxassetid://17544336110'}, Pose = UDim2.fromScale(0, .9)},
	{Arrow = {'rbxassetid://17544376449', 'rbxassetid://17544376202'}, Pose = UDim2.fromScale(1, .2)},
	{Arrow = {'rbxassetid://17544432824', 'rbxassetid://17544433013'}, Pose = UDim2.fromScale(.5, .9)},
})

local Interaction = BaseComponent.CreateComponent("Interaction", {
	tag = "Interaction",
	isAbstract = true,
}, Interactable) :: Impl

--//Type

export type Fields = {
	Proximities: BillboardGui & Interactable.BaseInteractionState,
	
	Instance: ProximityPrompt,
	Root: BasePart,
	
	Cooldown: number,
}

export type MyImpl = {
	__Index: MyImpl,
	
	OnConstruct: (self: Component) -> (),
	
	DeleteInteraction: (self: Component) -> (),
	CreateInteraction: (self: Component, Root: BasePart) -> ProximityPrompt,
	
	AnimationPromptDetail: (self: Component, PoseArrow: {string}) -> (),
	TogglePropertyChangesObject: (self: Component) -> (),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, ProximityPrompt, {}>
export type Component = 
	BaseComponent.Component<MyImpl, Fields, ProximityPrompt, {}> 

--//Methods

function Interaction.OnConstruct(self: Component)
	for index, functions in pairs(Interaction) do
		if typeof(functions) ~= "function" then
			continue
		end

		self[index] = functions
	end
	
	self.Proximities = nil
	
	self.Cooldown = .5
	self.IndexArrow = 1
end


function Interaction.CreateInteraction(self: Component)
	local Tags = self.Instance:GetTags()
	
	local Proximities = table.find(Tags, "Interact") and UIProximities.Interaction:Clone() or table.find(Tags, "Label") and UIProximities.Label:Clone()
	local DetailText = self.Instance.KeyboardKeyCode == Enum.KeyCode.BackSlash and tostring(self.Instance.ObjectText) or tostring(self.Instance.KeyboardKeyCode.Name).. " - "..tostring(self.Instance.ObjectText)
	
	local Arrow, Pose = self:GetlabelPose()
	
	assert(Proximities, "Information prompt is insufficient or missing, ".. tostring(self.Instance.Name))
	
	Proximities.Sign.Detail.Text = DetailText

	Proximities.Arrow.Image = Arrow[1]
	Proximities.Sign.Position = Pose
	Proximities.Parent = self.Root	
	
	self.Proximities = Proximities
	
	self:AnimationPromptDetail(Arrow)
	self:TogglePropertyChangesObject()
	
	return Proximities
end

function Interaction.DeleteInteraction(self: Component)
	if not self.Proximities then
		return
	end
	
	self.Proximities:Destroy()
	self.Proximities = nil
	
	RunService:UnbindFromRenderStep("AnimationPrompt")
end

function Interaction.GetProxmities(self: Component)
	return self.Proximities
end

function Interaction.GetlabelPose(self: Component)
	local RandomIndex = LABEL_INITIAL_POSES[math.random(1, #LABEL_INITIAL_POSES)]

	return RandomIndex.Arrow, RandomIndex.Pose
end

function Interaction.TogglePropertyChangesObject(self: Component)
	self.Janitor:Add(self.Instance.PromptButtonHoldBegan:Connect(function() Hold.Start(self) end))
	self.Janitor:Add(self.Instance.PromptButtonHoldEnded:Connect(function() Hold.End(self) end))
	
	self.Janitor:Add(self.Instance:GetPropertyChangedSignal("ObjectText"):Connect(function()		
		if not self.Proximities then return	end
		
		local DetailText = self.Instance.KeyboardKeyCode == Enum.KeyCode.BackSlash and tostring(self.Instance.ObjectText) or tostring(self.Instance.KeyboardKeyCode.Name).. " - "..tostring(self.Instance.ObjectText)
		
		self.Proximities.Sign.Detail.Text = DetailText
	end))
end

function Interaction.AnimationPromptDetail(self: Component, PoseArrow: {string})
	local CurrectDown = os.clock()

	RunService:BindToRenderStep("AnimationPrompt", Enum.RenderPriority.Input.Value + 1, function()
		if (os.clock() - CurrectDown) < self.Cooldown then
			return
		end

		self.IndexArrow = self.IndexArrow == 1 and 2 or 1

		self.Proximities.Arrow.Image = PoseArrow[self.IndexArrow]
		self.Proximities.Sign.Rotation = self.IndexArrow == 1 and 10 or -10

		CurrectDown = os.clock()
	end)
end

--//Return
return Interaction