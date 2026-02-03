--//Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local DefaultKeybinds = require(ReplicatedStorage.Shared.Data.Keybinds)

local InputController = require(ReplicatedStorage.Client.Controllers.InputController)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseMinigame = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local BaseMinigame = require(ReplicatedStorage.Client.Components.UIAssignable.Objectives.BaseMinigame)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)

--//Variables

local UIAssets = ReplicatedStorage.Assets.UI
local ReflexTestPaperUI = BaseComponent.CreateComponent("ReflexTestPaperUI", { isAbstract = false }, BaseMinigame) :: Impl

--//Types

type Stripe = {
	Hit: boolean,
	Length: number,
	Offset: number,
	Instance: ImageLabel,
}

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseMinigame.MyImpl) ),
	
	Hit: (self: Component) -> (),

	ProcessStripe: (self: Component, stripe: Stripe) -> (),
	GetCurrentStripe: (self: Component) -> Stripe?,
	
	_InitInput: (self: Component) -> (),
	_InitStripes: (self: Component) -> (),
} & BaseMinigame.MyImpl

export type Fields = {

	Stripes: {},
	StripeIndex: number,
	StripeProgress: number,
	Rounds: number,
	RoundsCompleted: number?
	
} & BaseMinigame.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ReflexTestPaperUI", ImageLabel, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "ReflexTestPaperUI", ImageLabel, {}>

--//Methods

function ReflexTestPaperUI.GetCurrentStripe(self: Component)
	return self.StripeIndex and self.Stripes[self.StripeIndex]
end

function ReflexTestPaperUI.Hit(self: Component)
	
	-- no longer hit activatable
	--if not self._InProgress then
		
	--	self:Start()
	--	return
	--end
	
	--some code that will register any hit on active stripe
	local ActiveStripe = self:GetCurrentStripe()

	if not ActiveStripe then
		return
	end

	local IndicatorOffset = ActiveStripe.Instance.Indicator.Position.X.Scale

	--check if player hit green zone (AnchorPoint IS MATTER)
	if IndicatorOffset >= ActiveStripe.Offset - ActiveStripe.Length
		and IndicatorOffset <= ActiveStripe.Offset then

		self.Instance.UIScale.Scale = 1.05

		TweenUtility.PlayTween(
			self.Instance.UIScale,
			TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)

		TweenUtility.PlayTween(
			ActiveStripe.Instance,
			TweenInfo.new(0.3),
			{ ImageTransparency = 0.5 } :: ImageLabel
		)

		TweenUtility.PlayTween(
			ActiveStripe.Instance.Border,
			TweenInfo.new(0.3),
			{ ImageTransparency = 0.5 } :: ImageLabel
		)

		self.Instance.Rotation = (math.random(0, 1) - 0.5) * 25

		TweenUtility.PlayTween(
			self.Instance,
			TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Rotation = 0 } :: ImageLabel
		)

		local HitSound = SoundUtility.CreateTemporarySound(
			SoundUtility.Sounds.UI.Objectives.Click
		)

		HitSound.PlaybackSpeed = 0.6 + 0.1 * self.StripeIndex

		--complete if player hit all right
		if self.StripeIndex == #self.Stripes then

			--self:PromptComplete("Success")
			self:_HandleRoundCompletion()

			return
		end

		self:ProcessStripe(self.Stripes[ self.StripeIndex + 1 ])

	else
		-- WE MISSED

		self.Janitor:Remove("StripeRenderSteps")
		self:PromptComplete("Failed")
	end
end

function ReflexTestPaperUI.ProcessStripe(self: Component, stripe: Stripe)

	--resetting stuff
	self.Janitor:Remove("StripeRenderSteps")
	self.StripeIndex = table.find(self.Stripes, stripe)
	self.StripeProgress = 0

	self.Janitor:Add(RunService.RenderStepped:Connect(function(deltaTime)

		--when strip reaches the end
		if self.StripeProgress >= 1
			or self.StripeProgress >= stripe.Offset then

			--we failed 😭
			self.Janitor:Remove("StripeRenderSteps")
			self:PromptComplete("Failed")

			return
		end
		
		local StripeProgressDelta = math.min(1/30, deltaTime / 1.5)
		StripeProgressDelta *= (1 + 0.15 * self.StripeIndex)
		self.StripeProgress += StripeProgressDelta
		
		stripe.Instance.Indicator.Position = UDim2.fromScale(self.StripeProgress, 0.5)
		stripe.Instance.UIGradient.Offset = Vector2.new(-(1 - self.StripeProgress), 0)
		stripe.Instance.Border.UIGradient.Offset = Vector2.new(self.StripeProgress, 0)

	end), nil, "StripeRenderSteps")
end

function ReflexTestPaperUI.Start(self: Component)
	if not self:ShouldStart() then
		return
	end
	BaseMinigame.Start(self)
	
	print('started')
	
	self.RoundsCompleted = 0
	self:_ToggleStripes(true)
	self.Instance.QuestionPad.Question.Visible = false
	
	--start from 1st one
	self.Janitor:Add(task.delay(1, self.ProcessStripe, self, self.Stripes[1]))
end

function ReflexTestPaperUI._HandleRoundCompletion(self: Component)
	self.RoundsCompleted += 1
	self.Janitor:Remove("StripeRenderSteps")
	self:_ToggleStripes(false)
	self.Instance.QuestionPad.Question.Visible = true
	
	if self.RoundsCompleted >= self.Rounds then
		self:PromptComplete("Success")
	else
		SoundUtility.CreateTemporarySound(SoundUtility.Sounds.UI.Objectives.CorrectAnswer)
		self.Instance.QuestionPad.Question.Text = `Good job! {self.Rounds - self.RoundsCompleted} more`
		self.Janitor:Add(task.delay(1, function()
			self:_Init()
			--self:_ToggleStripes(true)
			self.Instance.QuestionPad.Question.Visible = false
			self.Janitor:Add(task.delay(1, self.ProcessStripe, self, self.Stripes[1]))
		end, nil, "RoundThread"))
	end
end

function ReflexTestPaperUI._ToggleStripes(self: Component, val: boolean)
	for _, Child: Instance in self.Instance.Content:GetChildren() do
		if Child:IsA("ImageLabel") then
			Child.Visible = val
		end
	end
end

function ReflexTestPaperUI._Init(self: Component)
	self.Stripes = {}
	self.StripeIndex = nil
	self.StripeProgress = 0

	--clean up stuff
	for _, Child: Instance in ipairs(self.Instance.Content:GetChildren()) do

		if not Child:IsA("ImageLabel") then
			continue
		end

		Child:Destroy()
	end
	
	self:_InitStripes()
end

function ReflexTestPaperUI.Show(self: Component)
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
	
	local InputController = Classes.GetSingleton("InputController")

	local function UpdateKeyString()
		-- ?
		local String = InputController:GetStringsFromContext("Interaction")[1]
		self.Instance.Keybind.Text = string.format("PRESS %s", String)
	end

	UpdateKeyString()

	self.Janitor:Add(InputController.DeviceChanged:Connect(UpdateKeyString), nil, "KeyStringUpdater")
	
	self:_Init()
end

function ReflexTestPaperUI.Hide(self: Component)
	BaseMinigame.Hide(self)
	
	self.Janitor:RemoveList({"RoundThread", "KeyStringUpdater"})
	
	self.Instance.Visible = false
end

function ReflexTestPaperUI._InitStripes(self: Component)
	
	for Index = 1, 5 do
		
		local Stripe = {
			
			--length around green zone offset
			Length = math.random(15, 20)/100,
			
			--determines offset of the green zone
			Offset = math.clamp(math.random(1, 100)/100 + 0.05, 0.4, 1),
			Instance = UIAssets.Objectives.TestPapers.ReflexStripe:Clone(),
			
		} :: Stripe
		
		
		local GreenZoneFrame = Stripe.Instance:FindFirstChild("GreenZone") :: Frame
		GreenZoneFrame.Position = UDim2.fromScale(Stripe.Offset, 0.5)
		GreenZoneFrame.Size = UDim2.fromScale(Stripe.Length, GreenZoneFrame.Size.Y.Scale)
		
		Stripe.Instance.Parent = self.Instance.Content
		
		--stripe removal
		self.Janitor:Add(function()
			
			table.clear(Stripe)
			
			table.remove(self.Stripes,
				table.find(self.Stripes, Stripe)
			)
		end)
		
		table.insert(self.Stripes, Stripe)
	end
end

function ReflexTestPaperUI._InitInput(self: Component)
	BaseMinigame._InitInput(self)
	
	self.Janitor:Add(InputController.ContextStarted:Connect(function(context, Handler)
		if context ~= "Interaction" or 
			not InputController:IsContextActive("Interaction") then
			
			return
		end
		
		self:Hit()
	end))
	
end

function ReflexTestPaperUI.OnConstructClient(self: Component, controller: any)
	BaseMinigame.OnConstructClient(self, controller)
	
	self.Instance.Visible = false
	self._InProgress = false
	
	self.Rounds = 2
	
	--self:_Init() -- happens dynamically on :Show
	--self:_InitInput() -- is in BaseMinigame
	
	print('reflex spawned')
end

--//Returner

return ReflexTestPaperUI