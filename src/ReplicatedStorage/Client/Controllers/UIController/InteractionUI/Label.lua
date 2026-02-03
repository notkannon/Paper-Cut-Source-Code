--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Interaction = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)

local Utility = require(ReplicatedStorage.Shared.Utility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI

local InteractionLabel = Classes.CreateClass("ScreenInteractionLabel", false) :: Impl
local Objects = {}

--//Types

type ProximityLabel = typeof(UIAssets.Proximities.Label)

export type Impl = {
	__index: Impl,
	
	new: (component: Interaction.Component, label: ProximityLabel?) -> Object,
	Destroy: (self: Object) -> (),
	
	Hide: (self: Object) -> (),
	Show: (self: Object) -> (),
	CancelHide: (self: Object) -> (),
	
	_OnEnd: (self: Object) -> (),
	_OnStart: (self: Object) -> (),
	_OnHoldEnd: (self: Object) -> (),
	_OnHoldStart: (self: Object) -> (),
	_UpdatePosition: (self: Object) -> ()
}

export type Fields = {
	Visible: boolean,
	Janitor: Janitor.Janitor,
	Instance: ProximityLabel,
	Highlight: Highlight,
	Component: Interaction.Component,
	
	_Destroyed: boolean,
}

export type Object = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Functions

local function GetFromComponent(component: Interaction.Component): Object?
	for _, Object in ipairs(Objects) do
		if Object.Component == component then
			return Object
		end
	end
end

local function GetFromInstance(instance: ProximityLabel)
	for _, Object in ipairs(Objects) do
		if Object.Instance == instance then
			return Object
		end
	end
end

local function GetModelAncestry(instance: ProximityPrompt)
	
	local Model = instance:FindFirstAncestorWhichIsA("Model")
	
	--if we have no model instance above proximity then we will find other cases
	if Model:IsA("Workspace") then
		
		return instance:FindFirstAncestorWhichIsA("Tool")
			or instance:FindFirstAncestorWhichIsA("BasePart")
	end
	
	return Model
end

--//Methods

function InteractionLabel._UpdatePosition(self: Object)
	
	if not self.Instance then
		return
	end
	
	local Instance = self.Component
		and self.Component.Instance.Parent :: Attachment | BasePart
	
	if not (Instance:IsA("BasePart") or Instance:IsA("Attachment")) then
		return
	end
	
	local Position = (Instance:IsA("BasePart") and Instance or Instance.WorldCFrame).Position :: Vector3
	local Offset, Visible = Camera:WorldToScreenPoint(Position)
	
	self.Visible = Visible
	self.Instance.Position = self.Instance.Position:Lerp(UDim2.fromOffset(
		Offset.X,
		Offset.Y
	), 0.3)
end

function InteractionLabel._OnStart(self: Object)
	
	TweenUtility.ClearAllTweens(self.Instance)
	TweenUtility.ClearAllTweens(self.Highlight)
	TweenUtility.ClearAllTweens(self.Instance.Value)
	TweenUtility.ClearAllTweens(self.Instance.Action)
	TweenUtility.ClearAllTweens(self.Instance.Details)
	TweenUtility.ClearAllTweens(self.Instance.Progress.Icon)
	TweenUtility.ClearAllTweens(self.Instance.Progress.Icon.Value)
	
	self.Instance.Value.Offset = Vector2.new(0, 0)
	self.Instance.Action.TextTransparency = 0
	self.Instance.Details.TextTransparency = 0.5
	self.Instance.Progress.Icon.Value.Rotation = 90
	
	self.Highlight.FillTransparency = 0.9
	self.Instance.Size = UDim2.fromScale(0.1, 0.03)
	
	TweenUtility.PlayTween(self.Highlight, TweenInfo.new(0.35), {
		
		FillTransparency = 1
		
	} :: Highlight)
	
	TweenUtility.PlayTween(self.Instance, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		
		Size = UDim2.fromScale(0.1, 0.045)
		
	} :: ImageLabel)
end

function InteractionLabel._OnEnd(self: Object)
	
	TweenUtility.ClearAllTweens(self.Instance.Value)
	TweenUtility.ClearAllTweens(self.Instance.Action)
	TweenUtility.ClearAllTweens(self.Instance.Details)
	TweenUtility.ClearAllTweens(self.Instance.Progress.Icon.Value)
	
	self.Instance.Value.Offset = Vector2.new(0, 1)
	
	TweenUtility.PlayTween(self.Instance.Action, TweenInfo.new(0.2), { TextTransparency = 0.7 } :: TextLabel)
	TweenUtility.PlayTween(self.Instance.Details, TweenInfo.new(0.2), { TextTransparency = 0.7 } :: TextLabel)
	TweenUtility.PlayTween(self.Instance.Progress.Icon.Value, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Rotation = -90 } :: UIGradient)
end

function InteractionLabel._OnHoldStart(self: Object)
	
	--TweenUtility.ClearAllTweens(self.Instance.Value)
	TweenUtility.ClearAllTweens(self.Instance)
	TweenUtility.ClearAllTweens(self.Instance.Progress.Icon.Value)
	
	--resetting progress bar filling
	self.Instance.Progress.Icon.Value.Rotation = -90
	
	--press effect
	TweenUtility.PlayTween(self.Instance, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {

		Size = UDim2.fromScale(0.1, 0.03)

	} :: ImageLabel)
	
	--fill animation
	TweenUtility.PlayTween(
		
		self.Instance.Progress.Icon.Value,
		TweenInfo.new(self.Component.Instance.HoldDuration, Enum.EasingStyle.Linear),
		{ Rotation = 90 } :: UIGradient
	)
	
	--self.Instance.Value.Offset = Vector2.new(0, 1)
	
	--TweenUtility.PlayTween(self.Instance.Value, TweenInfo.new(self.Component.Instance.HoldDuration, Enum.EasingStyle.Linear), {
	--	Offset = Vector2.new(0, 0),
	--} :: UIGradient)
end

function InteractionLabel._OnHoldEnd(self: Object)
	
	TweenUtility.ClearAllTweens(self.Instance)
	TweenUtility.ClearAllTweens(self.Instance.Progress.Icon.Value)
	
	--press end effect
	TweenUtility.PlayTween(self.Instance, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {

		Size = UDim2.fromScale(0.1, 0.045)

	} :: ImageLabel)
	
	--progress bar reset
	TweenUtility.PlayTween(
		
		self.Instance.Progress.Icon.Value,
		TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
		{ Rotation = -90 } :: UIGradient
	)
end

function InteractionLabel.Show(self: Object)
	
	--resetting prompt if hidden while holding
	self:_OnHoldEnd()
	
	self.Instance.Visible = true
	
	TweenUtility.ClearAllTweens(self.Instance)
	TweenUtility.PlayTween(self.Instance, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		
		Size = UDim2.fromScale(0.1, 0.045)
		
	} :: ImageLabel)
end

function InteractionLabel.Hide(self: Object)
	
	if not self.Visible then
		
		self:Destroy()
		
		return
	end
	
	--resetting hold state
	self:_OnEnd()
	
	self.Janitor:Add(task.delay(0.5, self.Destroy, self), nil, "RemovalThread")
	self.Janitor:Add(TweenUtility.PlayTween(self.Instance, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
		
		Size = UDim2.fromScale(1, 0)
		
	}, function(status)
		
		if status == Enum.PlaybackState.Cancelled then
			return
		end
		
		self.Instance.Visible = false
		
	end), "Cancel", "RemovalTween")
end

function InteractionLabel.CancelHide(self: Object)
	
	self.Janitor:RemoveList(
		
		"RemovalTween",
		"RemovalThread"
	)
end

function InteractionLabel.OnConstructClient(self: Object, component: Interaction.Component, label: ProximityLabel?)
	
	self.Visible = true
	self.Janitor = Janitor.new()
	self.Instance = label or UIAssets.Proximities.Label:Clone()
	self.Component = component
	self.Highlight = Instance.new("Highlight")
	
	--progress bar shows if we need to hold prompt
	self.Instance.Progress.Visible = component.Instance.HoldDuration > 0
	
	Utility.ApplyParams(self.Highlight, {
		
		Parent = GetModelAncestry(component.Instance),
		DepthMode = Enum.HighlightDepthMode.Occluded,
		FillColor = Color3.new(1, 1, 1),
		FillTransparency = 1,
		OutlineTransparency = 1,
		
	} :: Highlight)
	
	self.Highlight.Adornee = self.Highlight.Parent
	self.Janitor:Add(self.Highlight)
	
	--used to keep updates on label
	local function AnyTextChanged()
		
		self.Instance.Action.Text = component.Instance.ActionText:upper()
		self.Instance.Details.Text = component.Instance.ObjectText
	end
	
	--initial state
	AnyTextChanged()
	
	self.Instance.Size = UDim2.fromScale(0, 0)
	self.Instance.Details.Text = component.Instance.ObjectText
	
	--connections
	
	self.Janitor:Add(component.HoldStarted:Connect(function(player)
		if player ~= Player then
			return
		end
		
		self:_OnHoldStart()
	end))
	
	self.Janitor:Add(component.HoldEnded:Connect(function(player)
		if player ~= Player then
			return
		end

		self:_OnHoldEnd()
	end))
	
	self.Janitor:Add(component.Started:Connect(function(player)
		if player ~= Player then
			return
		end

		self:_OnStart()
		
		if component.Instance.HoldDuration == 0 then
			self:_OnEnd()
		end
	end))
	
	self.Janitor:Add(component.Ended:Connect(function(player)
		if player ~= Player or component.Instance.HoldDuration == 0 then
			return
		end
		
		self:_OnEnd()
	end))
	
	--text changing connections
	self.Janitor:Add(component.Instance:GetPropertyChangedSignal("ActionText"):Connect(AnyTextChanged))
	self.Janitor:Add(component.Instance:GetPropertyChangedSignal("ObjectText"):Connect(AnyTextChanged))
	
	--label rendering
	self.Janitor:Add(RunService.RenderStepped:Connect(function()
		self:_UpdatePosition()
	end))
	
	--memory cleanup
	self.Janitor:Add(function()
		
		local Index = table.find(Objects, self)
		
		if not Index then
			return
		end
		
		table.remove(Objects, Index)
	end)
	
	--destroying label on component removal
	component.Janitor:Add(self, "Destroy")
	
	--storing in memory
	table.insert(Objects, self)
end

function InteractionLabel.Destroy(self: Object)
	
	if self._Destroyed then
		return
	end
	
	self.Janitor:Destroy()
	
	if self.Instance then
		self.Instance.Visible = false
	end
	
	table.clear(self)
	
	self._Destroyed = true
	
	table.freeze(self)
end

--//Returner

return {
	new = InteractionLabel.new,
	
	GetFromInstance = GetFromInstance,
	GetFromComponent = GetFromComponent,
}