--//Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local DefaultKeybinds = require(ReplicatedStorage.Shared.Data.Keybinds)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseMinigame = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local BaseMinigame = require(ReplicatedStorage.Client.Components.UIAssignable.Objectives.BaseMinigame)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)

local MouseUnlockedEffect = require(ReplicatedStorage.Shared.Combat.Statuses.MouseUnlocked)
local WCS = require(ReplicatedStorage.Packages.WCS)

local Janitor = require(ReplicatedStorage.Packages.Janitor)

local Enums = require(ReplicatedStorage.Shared.Enums)

--//Variables

local LocalPlayer = Players.LocalPlayer
local AssetFolder = ReplicatedStorage.Assets.Objectives.Related.ShapeSort
--local UIAssets = ReplicatedStorage.Assets.UI
local ShapeSortTestPaperUI = BaseComponent.CreateComponent("ShapeSortTestPaperUI", { isAbstract = false }, BaseMinigame) :: Impl

--//Constants

--//Types

export type Shape = {
	Instance: ImageLabel,
	Type: string,
	Dragger: UIDragDetector,
	CorrectlyPlaced: boolean
}

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseMinigame.MyImpl) ),
	
	_InitInput: (self: Component) -> (),
	_InitShapes: (self: Component) -> (),
	_UpdateShape: (self: Component, shape: Shape) -> (),
	_SelectShape: (self: Component, shape: Shape) -> (),
	_GetFirstIncorrectShape: (self: Component) -> Shape?,
	GetCorrectlyPlacedAmount: (self: Component) -> number,
	IsComplete: (self: Component) -> boolean
} & BaseMinigame.MyImpl

export type Fields = {

	Shapes: {Shape},
	TotalShapes: number,
	CurrentShape: Shape?,
	RuntimeJanitor: Janitor.Janitor
	
} & BaseMinigame.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ShapeSortTestPaperUI", ImageLabel, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "ShapeSortTestPaperUI", ImageLabel, {}>

--//Methods

function ShapeSortTestPaperUI._SelectShape(self: Component, shape: Shape)
	self.CurrentShape = shape
	self.RuntimeJanitor:Add(task.spawn(function()
		local TI = TweenInfo.new(0.5, Enum.EasingStyle.Quad)
		--print(shape, self.Shapes)
		while true do
			TweenUtility.WaitForTween(TweenUtility.PlayTween(shape.Instance, TI, {ImageColor3 = Color3.new(1, 0.968627, 0)}))
			TweenUtility.WaitForTween(TweenUtility.PlayTween(shape.Instance, TI, {ImageColor3 = Color3.new(1, 0.215686, 0.227451)}))
		end
	end), nil, "HighlightCurrentShape")
end

function ShapeSortTestPaperUI._GetFirstIncorrectShape(self: Component)
	for _, Shape in self.Shapes do
		if not Shape.CorrectlyPlaced then
			return Shape
		end
	end
end

function ShapeSortTestPaperUI.Start(self: Component)
	if not self:ShouldStart() then
		return
	end
	BaseMinigame.Start(self)
	
	local WCSChar = WCS.Character.GetLocalCharacter()
	assert(WCSChar)
	
	self.RuntimeJanitor:Add(MouseUnlockedEffect.new(WCSChar), "End", "MouseUnlockedEffect"):Start()
	
	self:_Init()
	
	if self.CurrentDevice == Enums.InputType.Gamepad then
		local IncorrectShape = self:_GetFirstIncorrectShape()
		if IncorrectShape then
			self:_SelectShape(IncorrectShape)
		else
			print("Should complete minigame")
		end
	end
	print('started')
end

function ShapeSortTestPaperUI._Init(self: Component)
	self.Shapes = {}
	self.CurrentShape = nil

	--clean up stuff
	for _, Child: Instance in ipairs(self.Instance.Content.PieceContainer:GetChildren()) do

		if not Child:IsA("ImageLabel") then
			continue
		end

		Child:Destroy()
	end
	
	self:_InitShapes()
end

function ShapeSortTestPaperUI.Show(self: Component)
	BaseMinigame.Show(self)
	
	self.Instance.Visible = true
	self.Instance.Rotation = (math.random(0, 1) - 0.5) * 25
	self.Instance.UIScale.Scale = 0.8

	TweenUtility.PlayTween(
		self.Instance,
		TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Rotation = 0 } :: ImageLabel
	)
	
	TweenUtility.PlayTween(self.Instance.UIScale, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Scale = 1
	})
	
	local Desc = "Sort shapes in their respective areas."
	
	if self.CurrentDevice == Enums.InputType.Gamepad then
		Desc ..= " Use your thumbstick to move the highlighted shape"
	else
		Desc ..= " Use your mouse to drag & drop the shapes"
	end
	
	self.Instance.Description.Text = Desc
end

function ShapeSortTestPaperUI.GetCorrectlyPlacedAmount(self: Component)
	local CorrectlyPlaced = 0
	for _, Shape: Shape in pairs(self.Shapes) do
		if Shape.CorrectlyPlaced then
			CorrectlyPlaced += 1
		end
	end
	return CorrectlyPlaced
end

function ShapeSortTestPaperUI.IsComplete(self: Component)
	local CorrectlyPlaced = self:GetCorrectlyPlacedAmount()
	return CorrectlyPlaced >= self.TotalShapes
end

function ShapeSortTestPaperUI.Hide(self: Component)
	BaseMinigame.Hide(self)
	
	self.RuntimeJanitor:Cleanup()
	self.Instance.Visible = false
end

function ShapeSortTestPaperUI._UpdateShape(self: Component, shape: Shape, noSound: boolean?)
	local Pos = shape.Instance.Position
	local IsPlacedCorrectly = false
	
	if Pos.X.Scale >= 0.515 then
		IsPlacedCorrectly = if Pos.Y.Scale >= 0.515 then shape.Type == "Circle" else (Pos.Y.Scale <= 0.485 and shape.Type == "Triangle" or false)
	elseif Pos.X.Scale <= 0.485 then
		IsPlacedCorrectly = if Pos.Y.Scale >= 0.515 then shape.Type == "Cross" else (Pos.Y.Scale <= 0.485 and shape.Type == "Square" or false)
	end
	
	if shape.CorrectlyPlaced ~= IsPlacedCorrectly then
		shape.CorrectlyPlaced = IsPlacedCorrectly
		TweenUtility.ClearAllTweens(shape.Instance)
		TweenUtility.PlayTween(shape.Instance, TweenInfo.new(.5), {ImageColor3 = if IsPlacedCorrectly then Color3.fromRGB(10, 200, 70) else Color3.fromRGB(200, 10, 70)})
		
		if not noSound then
			local CorrectlyPlaced = self:GetCorrectlyPlacedAmount()
			local ClickSound = SoundUtility.CreateTemporarySound(SoundUtility.Sounds.UI.Objectives.Click)
			ClickSound.PlaybackSpeed = 0.6 + (CorrectlyPlaced / self.TotalShapes) * 0.3
		end
		
		if self.CurrentDevice == Enums.InputType.Gamepad and IsPlacedCorrectly then
			shape.Dragger:Destroy()
			shape.Dragger = nil
		end
		
		if self:IsComplete() then
			self:PromptComplete("Success")
		elseif IsPlacedCorrectly and self.CurrentDevice == Enums.InputType.Gamepad then
			self:_SelectShape(self:_GetFirstIncorrectShape())
		end
	end
end

function ShapeSortTestPaperUI._InitShapes(self: Component)
	
	for Index = 1, self.TotalShapes do
		
		local ShapeType = self.ShapeNames[math.random(1, #self.ShapeNames)]
		
		local Shape = {
			Instance = nil,
			Type = ShapeType,
			Dragger = nil,
			CorrectlyPlaced = nil
		}
		
		local Instance = AssetFolder:FindFirstChild(ShapeType):Clone() :: ImageLabel
		Instance.ZIndex = 5
		Instance.Position = UDim2.fromScale(math.random(150, 850)/1000, math.random(150, 850)/1000)
		Instance.Parent = self.Instance.Content.PieceContainer
		Shape.Instance = Instance
		
		local UIDragger = AssetFolder:FindFirstChildWhichIsA("UIDragDetector"):Clone()
		UIDragger.BoundingUI = self.Instance.Content.PieceContainer
		UIDragger.Parent = Instance
		Shape.Dragger = UIDragger
		
		self:_UpdateShape(Shape, true)
		
		--shape removal
		self.RuntimeJanitor:Add(function()
			
			table.clear(Shape)
			
			table.remove(self.Shapes,
				table.find(self.Shapes, Shape)
			)
		end)
		
		self.RuntimeJanitor:Add(Instance)
		
		self.RuntimeJanitor:Add(Instance:GetPropertyChangedSignal("Position"):Connect(function()
			self:_UpdateShape(Shape)
		end))
		
		table.insert(self.Shapes, Shape)
	end
end

function ShapeSortTestPaperUI._InitInput(self: Component)
	BaseMinigame._InitInput(self)
	
	-- console
	self.Janitor:Add(UserInputService.InputChanged:Connect(function(input, isProcessed)
		if input.KeyCode ~= Enum.KeyCode.Thumbstick1 or not self._InProgress then
			return
		end
		
		local ThumbstickPosition: Vector2 = Vector2.new(input.Position.X, input.Position.Y)
		local MovementCap: Vector2 = Vector2.new(0.5, 0.5)
		
		local Delta: Vector2 = ThumbstickPosition * MovementCap
		
		--print(ThumbstickPosition, Delta)
		
		
		if self.CurrentShape then
			self.RuntimeJanitor:Add(RunService.RenderStepped:Connect(function(deltaTime)
				local AdjustedDelta: Vector2 = Delta * deltaTime
				local UDim: UDim2 = UDim2.fromScale(
					math.clamp(AdjustedDelta.X + self.CurrentShape.Instance.Position.X.Scale, 0.05, 0.95),
					math.clamp(-AdjustedDelta.Y + self.CurrentShape.Instance.Position.Y.Scale, 0.05, 0.95)
				)
				self.CurrentShape.Instance.Position = UDim
			end), nil, "MoveCurrentShape")
		end
	end))
	
	self.Janitor:Add(UserInputService.InputEnded:Connect(function(input, isProcessed)
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			self.RuntimeJanitor:Remove("MoveCurrentShape")
		end
	end))
end

function ShapeSortTestPaperUI.OnConstructClient(self: Component, controller: any)
	self.RuntimeJanitor = self.Janitor:Add(Janitor.new())
	
	BaseMinigame.OnConstructClient(self, controller)
	
	self.TotalShapes = 12
	
	
	self.Instance.Visible = false
	self._InProgress = false
	
	local ShapeMap = {}
	local ShapeNames = {}
	
	for _, Child in AssetFolder:GetChildren() do
		if Child:IsA("ImageLabel") then
			ShapeMap[Child.Name] = Child.Image
			table.insert(ShapeNames, Child.Name)
		end
	end
	
	self.ShapeMap = ShapeMap
	self.ShapeNames = ShapeNames
	
	--self:_Init() -- happens dynamically on :Show
	--self:_InitInput() -- is in BaseMinigame
	
	print('ShapeSort spawned')
end

--//Returner

return ShapeSortTestPaperUI