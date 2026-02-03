--//Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)

local InputController = require(ReplicatedStorage.Client.Controllers.InputController)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseMinigame = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local BaseMinigame = require(ReplicatedStorage.Client.Components.UIAssignable.Objectives.BaseMinigame)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)

local Enums = require(ReplicatedStorage.Shared.Enums)

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local MouseUnlockedEffect = require(ReplicatedStorage.Shared.Combat.Statuses.MouseUnlocked)
local WCS = require(ReplicatedStorage.Packages.WCS)

--//Variables

local LocalPlayer = Players.LocalPlayer
local AssetFolder = ReplicatedStorage.Assets.Objectives.Related.ShapeSort
local MemoryTestPaperUI = BaseComponent.CreateComponent("MemoryTestPaperUI", { isAbstract = false }, BaseMinigame) :: Impl

--//Constants

--//Types

export type Shape = {
	Instance: ImageLabel,
	Type: string,
	Color: Color3
}

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseMinigame.MyImpl) ),
	
	StartRound: (self: Component) -> (),
	_HandleAnswer: (self: Component) -> (),
	GetColors: (self: Component) -> {Color3}
} & BaseMinigame.MyImpl

export type Fields = {

	Shapes: {Shape},
	ShapesPerRound: number,
	Rounds: number,
	RoundsCompleted: number,
	ShapeDelay: number,
	
	RuntimeJanitor: Janitor.Janitor
	
} & BaseMinigame.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "MemoryTestPaperUI", ImageLabel, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "MemoryTestPaperUI", ImageLabel, {}>

--//Methods

function MemoryTestPaperUI.Start(self: Component)
	if not self:ShouldStart() then
		return
	end
	BaseMinigame.Start(self)
	
	self:_Init()
	print('started')
	
	self.Instance.Content.Question.Text = "Get ready!"
	self.Instance.Content.Question.Visible = true
	self.Janitor:Add(task.delay(1.5, self.StartRound, self), nil, "RoundThread")
end

function MemoryTestPaperUI.GetColors(self: Component)
	return {Color3.new(1, 0, 0), Color3.new(0, 1, 0), Color3.new(0, 0, 1), Color3.new(1, 1, 0), Color3.new(1, 0, 1), Color3.new(0, 1, 1), Color3.new(1, 1, 1)}
end

function MemoryTestPaperUI.StartRound(self: Component)
	self.RuntimeJanitor:Cleanup()
	self.Shapes = {}
	self.Instance.Content.Question.Visible = false
	
	local AvailableIndices = {}
	
	-- harder legacy version
	--local AvailableColors = {}
	
	--for _, Name in self.ShapeNames do
	--	AvailableColors[Name] = self:GetColors()
	--end
	
	local AvailableColors = self:GetColors()
	
	for Index = 1, self.ShapesPerRound do
		
		if self.Shapes[Index - 1] then
			self.Shapes[Index - 1].Instance.Visible = false
		end

		local ShapeType = self.ShapeNames[math.random(1, #self.ShapeNames)]
		
		-- legacy
		--local AvailableColorsForType = AvailableColors[ShapeType]
		--local _index = math.random(1, #AvailableColorsForType)
		--local Color = AvailableColorsForType[_index]
		--table.remove(AvailableColorsForType, _index)
		local _index = math.random(1, #AvailableColors)
		local Color = AvailableColors[_index]
		table.remove(AvailableColors, _index)

		local Shape = {
			Instance = nil,
			Type = ShapeType,
			Color = Color
		}

		local Instance = AssetFolder:FindFirstChild(ShapeType):Clone() :: ImageLabel
		Instance.ZIndex = 5
		Instance.Position = UDim2.fromScale(math.random(200, 800)/1000, math.random(200, 800)/1000)
		Instance.ImageColor3 = Color
		Instance.Size = UDim2.fromScale(0.4, 0.4)
		Instance.Parent = self.Instance.Content.PieceContainer
		Shape.Instance = Instance
		

		--shape removal
		self.RuntimeJanitor:Add(function()

			table.clear(Shape)

			table.remove(self.Shapes,
				table.find(self.Shapes, Shape)
			)
		end)

		self.RuntimeJanitor:Add(Instance)

		table.insert(self.Shapes, Shape)
		table.insert(AvailableIndices, Index)
		
		local Tick = SoundUtility.CreateTemporarySound(SoundUtility.Sounds.UI.Objectives.Click)
		Tick.PlaybackSpeed = 0.6 + ((Index - 1) / (self.ShapesPerRound - 1)) * 0.3
		
		task.wait(self.ShapeDelay)
	end
	
	local function NumberToOrdinal(x: number)
		local Suffix
		
		if x == 11 or x == 12 or x == 13 then
			Suffix = "th"
		elseif x % 10 == 1 then
			Suffix = "st"
		elseif x % 10 == 2 then
			Suffix = "nd"
		elseif x % 10 == 3 then
			Suffix = "rd"
		else
			Suffix = "th"
		end
		
		return tostring(x) .. Suffix
	end
	
	self.Shapes[#self.Shapes].Instance.Visible = false
	
	local IndexToAsk = math.random(1, self.ShapesPerRound)
	local CorrectAnswer = math.random(1, 4)
	table.remove(AvailableIndices, table.find(AvailableIndices, IndexToAsk))
	
	local Tick = SoundUtility.CreateTemporarySound(SoundUtility.Sounds.UI.Objectives.Click)
	Tick.PlaybackSpeed = 1
	
	self.Instance.Content.Question.Text = `What was the {NumberToOrdinal(IndexToAsk)} shape?`
	self.Instance.Content.Question.Visible = true
	
	local WCSChar = WCS.Character.GetLocalCharacter()
	assert(WCSChar)
	
	--print("IndexToAsk:", IndexToAsk, "CorrectAnswer:", CorrectAnswer, "Shapes:", self.Shapes)
	
	self.RuntimeJanitor:Add(MouseUnlockedEffect.new(WCSChar), "End", "MouseUnlockedEffect"):Start()
	
	for _, Frame: Frame in self.Instance.Content.Sections:GetChildren() do
		if not Frame:IsA("Frame") then
			continue
		end
		
		local ChoiceButton : TextButton = Frame.ChoiceButton
		local FrameIndex = tonumber(Frame.Name:sub(-1, -1))
		local IsCorrect = FrameIndex == CorrectAnswer
		ChoiceButton:ClearAllChildren()
		
		--print("Pool Before:", AvailableIndices, "IsCorrect:", IsCorrect, "More info line below")
		
		local AllowedIndex
		if IsCorrect then
			AllowedIndex = IndexToAsk
		else
			local _index = math.random(1, #AvailableIndices)
			AllowedIndex = AvailableIndices[_index]
			table.remove(AvailableIndices, _index)
		end
		
		--print("FrameIndex:", FrameIndex, "RealIndex:", AllowedIndex, "Pool:", AvailableIndices)
		
		local CopiedInstance = self.Shapes[AllowedIndex].Instance:Clone()
		
		CopiedInstance.Size = UDim2.fromScale(0.7, 0.7)
		CopiedInstance.AnchorPoint = Vector2.new(0.5, 0.5)
		CopiedInstance.Position = UDim2.fromScale(0.5, 0.5)
		CopiedInstance.Visible = true
		CopiedInstance.Parent = ChoiceButton
		
		ChoiceButton.Visible = true
		
		self.RuntimeJanitor:Add(ChoiceButton.MouseButton1Click:Connect(function()
			self:_HandleAnswer(FrameIndex == CorrectAnswer)
		end))
	end
end

function MemoryTestPaperUI._HandleAnswer(self: Component, correct: boolean)
	self.RuntimeJanitor:Cleanup()
	if not correct then
		self:PromptComplete("Failed")
	else
		self.RoundsCompleted += 1
		if self.RoundsCompleted >= self.Rounds then
			self:PromptComplete("Success")
		else
			self:_Init()
			SoundUtility.CreateTemporarySound(SoundUtility.Sounds.UI.Objectives.CorrectAnswer)
			self.Instance.Content.Question.Text = `Correct! {self.Rounds - self.RoundsCompleted} more`
			self.Janitor:Add(task.delay(1, self.StartRound, self), nil, "RoundThread")
		end
	end
end

function MemoryTestPaperUI._Init(self: Component)
	--clean up stuff
	for _, Child: Instance in ipairs(self.Instance.Content:GetDescendants()) do

		if Child:IsA("ImageLabel") then
			Child:Destroy()
		elseif Child:IsA("TextButton") then
			Child.Visible = false
		end
	end
end

function MemoryTestPaperUI.Show(self: Component)
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
end

function MemoryTestPaperUI.Hide(self: Component)
	BaseMinigame.Hide(self)
	self.Janitor:Remove("RoundThread")
	self.RoundsCompleted = 0
	self.RuntimeJanitor:Cleanup()
	self.Instance.Visible = false
end

function MemoryTestPaperUI.OnConstructClient(self: Component, controller: any)
	
	self.RuntimeJanitor = self.Janitor:Add(Janitor.new())
	BaseMinigame.OnConstructClient(self, controller)
	
	self.ShapesPerRound = 4
	self.Rounds = 2
	self.RoundsCompleted = 0
	self.ShapeDelay = 0.75
	
	
	
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
	
	print('Memory spawned')
end

--//Returner

return MemoryTestPaperUI