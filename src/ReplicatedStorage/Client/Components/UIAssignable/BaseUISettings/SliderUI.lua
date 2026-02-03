--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local BaseUISettingsComponent = require(script.Parent)

--//Variables

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local SliderUI = BaseComponent.CreateComponent("SliderUI", { isAbstract = false }, BaseUISettingsComponent) :: Impl

--//Types
export type SettingOptions = BaseUISettingsComponent.SettingOptions

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseUISettingsComponent.MyImpl)),
	
	GetValue: (self: Component, Alpha: boolean) -> number,
	OnUpdate: (self: Component) -> (),
}

export type Fields = BaseUISettingsComponent.Fields & {
	_IsDragging: boolean
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "SliderUI", Frame & {}, SettingOptions>
export type Component = BaseComponent.Component<MyImpl, Fields, "SliderUI", Frame & {}, SettingOptions> 

--//Functions

local function Snap(value, Snapvalue)
	return value - (value % Snapvalue)
end

--//Methods

--@override
function SliderUI.OnSettingChanged(self: Component, Value: boolean) 
	BaseUISettingsComponent.OnSettingChanged(self, Value)
	
	local SettingsConstructor = self.SettingOptions.SettingConstructor
	local Alpha = Value

	if SettingsConstructor.ValueRange then
		Alpha = (Value - SettingsConstructor.ValueRange.Min) / (SettingsConstructor.ValueRange.Max - SettingsConstructor.ValueRange.Min)
	end

	print(Value, Alpha)

	local SliderBase = self.Instance.Content.Slider :: Frame
	local SliderIcon = SliderBase.Icon :: ImageLabel
	local SliderLine = SliderBase.Line :: ImageLabel

	SliderIcon.Position = UDim2.fromScale(Alpha, SliderIcon.Position.Y.Scale)
	SliderLine.UIGradient.Offset = Vector2.new(Alpha-1, 0)

	local Rounded = math.round(Value * 100) / 100 
	SliderIcon.ValueLabel.Text = tostring(Rounded)
end

function SliderUI.GetValue(self: Component, Alpha: boolean)
	local SettingsConstructor = self.SettingOptions.SettingConstructor
	local ValueRange = SettingsConstructor.ValueRange
	local SnapValue = SettingsConstructor.ValueStep
	
	if SnapValue and ValueRange then
		local ValueLenght = ValueRange.Max - ValueRange.Min
		SnapValue /= ValueLenght
	else
		SnapValue = 0.01
	end
	
	local SliderBase = self.Instance.Content.Slider :: Frame
	local SliderPos = SliderBase.AbsolutePosition.X
	local SliderSize = SliderBase.AbsoluteSize.X

	local SliderValue = Snap(math.clamp((Mouse.X - SliderPos)/SliderSize, 0, 1), SnapValue)

	if SettingsConstructor.ValueRange and not Alpha then
		SliderValue = math.lerp(SettingsConstructor.ValueRange.Min, SettingsConstructor.ValueRange.Max, SliderValue)
	end

	return SliderValue
end

function SliderUI.OnRender(self: Component, DeltaTime: number)
	if not self._IsDragging then
		return
	end
	
	local Alpha = self:GetValue(true)
	local Slider = self:GetValue(false)
	self:OnSettingChanged(Slider)
end

function SliderUI.OnConstruct(self: Component, uiController: unknown, SettingOption: SettingOptions)
	BaseUISettingsComponent.OnConstruct(self, uiController, SettingOption)
	
	-- DONT CALL :GETVALUE IN ONCONSTRUCT
	
	self._IsDragging = false
	self:OnSettingChanged(self._LastValue)
end


function SliderUI.OnConstructClient(self: Component, uiController: unknown)
	BaseUISettingsComponent.OnConstructClient(self, uiController)
	
	local SliderBase = self.Instance.Content.Slider :: Frame
	self.Janitor:Add(SliderBase.InputBegan:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		self._IsDragging = true
	end))

	self.Janitor:Add(SliderBase.InputEnded:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		local SliderPos = SliderBase.AbsolutePosition.X
		local SliderSize = SliderBase.AbsoluteSize.X
		
		local SliderValue = self:GetValue(false)

		self._IsDragging = false
		self:OnSettingChanged(SliderValue)
		self.OnChanged:Fire(SliderValue)
	end))
end

--//Returner

return SliderUI