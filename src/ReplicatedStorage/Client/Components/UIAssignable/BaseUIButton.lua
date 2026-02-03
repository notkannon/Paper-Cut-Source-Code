--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local BaseUIButton = BaseComponent.CreateComponent("BaseUIButton", {
	
	tag = "UIButton",
	isAbstract = false
	
}) :: Impl

--//Types

export type UIConstructorOptions = {

}

export type MyImpl = {
	__index: MyImpl,
	
	IsImageButton: (self: Component) -> boolean,
	OnMouseEnter: (self: Component) -> (),
	OnMouseLeave: (self: Component) -> (),
	OnMouseClick: (self: Component) -> (),
	
	OnConstructClient: (self: Component) -> (),
	
	_InitSideEffects: (self: Component) -> (),
}

export type Fields = {
	
	InitialSize: UDim2,
	InitialRotation: number,
	InitialPosition: UDim2,
	InitialImageColor: Color3?,
	InitialImageTransparency: number?,
	
	ClickSound: Sound?,
	HoverEnterSound: Sound?,
	HoverLeaveSound: Sound?,
	HoverEventsEnabled: boolean,
	ImageEffectsEnabled: boolean,
	
	OnButtonClicked: Signal.Signal,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseUIButton", TextButton | ImageButton>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseUIButton", TextButton | ImageButton> 

--//Functions

local function MultiplyUDim2(udim2: UDim2, mul: number): UDim2
	return UDim2.new(
		udim2.X.Scale * mul,
		udim2.X.Offset * mul,
		udim2.Y.Scale * mul,
		udim2.Y.Offset * mul
	)
end

--//Methods

function BaseUIButton.IsImageButton(self: Component)
	return self.Instance:IsA("ImageButton")
end

function BaseUIButton.OnMouseEnter(self: Component)
	
	if not self.HoverEnterSound then
		return
	end
	
	SoundUtility.CreateTemporarySound(self.HoverEnterSound)
end

function BaseUIButton.OnMouseLeave(self: Component)
	
	if not self.HoverLeaveSound then
		return
	end

	SoundUtility.CreateTemporarySound(self.HoverLeaveSound)
end

function BaseUIButton.OnMouseClick(self: Component)
	SoundUtility.CreateTemporarySound(self.ClickSound)
	
	if not self.Instance:HasTag("CustomUIAnimation") then
		self.Instance.Size = MultiplyUDim2(self.InitialSize, 1.25)

		TweenUtility.PlayTween(self.Instance, TweenInfo.new(0.23, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			Size = self.InitialSize
		})
	end
	
	if not self:IsImageButton() or not self.ImageEffectsEnabled then
		return
	end
	
	self.Instance.Rotation += 15
	self.Instance.ImageColor3 = Color3.new(1, 1, 1)
	self.Instance.ImageTransparency = 0
	
	TweenUtility.PlayTween(self.Instance, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		
		Rotation = self.InitialRotation,
		ImageColor3 = self.InitialImageColor,
		ImageTransparency = self.InitialImageTransparency
	})
end

function BaseUIButton._InitSideEffects(self: Component)
	
	--hover events things	

	self.Janitor:Add(self.Instance.MouseEnter:Connect(function()
		
		if not self.HoverEventsEnabled then
			return
		end
		
		self:OnMouseEnter()
	end))
	
	self.Janitor:Add(self.Instance.MouseLeave:Connect(function()

		if not self.HoverEventsEnabled then
			return
		end

		self:OnMouseLeave()
	end))
	
	--clicking sounds
	self.Janitor:Add(self.Instance.MouseButton1Click:Connect(function()
		
		if not self.ClickSound then
			return
		end
		
		self:OnMouseClick()
		self.OnButtonClicked:Fire()
	end))
end

function BaseUIButton.OnConstructClient(self: Component)
	
	self.InitialSize = self.Instance.Size
	self.InitialRotation = self.Instance.Rotation
	self.InitialPosition = self.Instance.Position
	self.InitialImageColor = self:IsImageButton() and self.Instance.ImageColor3 or nil
	self.InitialImageTransparency = self:IsImageButton() and self.Instance.ImageTransparency or nil
	
	self.ClickSound = SoundUtility.Sounds.UI.ButtonClick
	self.HoverEnterSound = SoundUtility.Sounds.UI.ButtonHover
	self.HoverLeaveSound = nil
	self.HoverEventsEnabled = true
	self.ImageEffectsEnabled = true
	
	self.OnButtonClicked = Signal.new() -- because here, detect when its clicked
	
	self:_InitSideEffects()
end

--//Returner

return BaseUIButton