--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ProximityLabelComponent = require(ReplicatedStorage.Shared.Components.Interactions.ProximityLabel)

--//Constants

local PI = math.pi
local ANIMATION_MAX_DISTANCE = 40

--//Variables

local Camera = workspace.CurrentCamera

local ClientClock = BaseComponent.CreateComponent("ClientClock", {

	tag = "Clock",
	isAbstract = false,

}) :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
	
	Step: (self: Component) -> (),
	ApplyTime: (self: Component, current: number, entire: number) -> (),
}

export type Fields = {
	Instance: Model,
	
	Sound: Sound,
	HourHand: BasePart?,
	MinuteHand: BasePart,
	
	HourInitial: CFrame,
	MinuteInitial: CFrame,
	
	TweenJanitor: Janitor.Janitor,
	ProximityLabel: ProximityLabelComponent.Component,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ClientClock", Model>
export type Component = BaseComponent.Component<MyImpl, Fields, "ClientClock", Model>

--//Methods

function ClientClock.Step(self: Component)
	
	self.Janitor:Remove("Tween")
	
	local Start = self.MinuteHand:GetPivot()
	local Goal = Start * CFrame.Angles(0, 0, PI / 180 * 6)
	local Distance = (Camera.CFrame.Position - self.Instance.PrimaryPart.CFrame.Position).Magnitude
	
	self.Sound:Play()
	
	if Distance > ANIMATION_MAX_DISTANCE then
		
		self.MinuteHand:PivotTo(Goal)
		
		return
	end
	
	self.Janitor:Add(TweenUtility.TweenStep(TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), function(value)
		self.MinuteHand:PivotTo(Start:Lerp(Goal, value * 1.7))
	end), true, "Tween")
end

function ClientClock.ApplyTime(self: Component, current: number, entire: number)
	
	if self.HourHand then
		
		local angle = (current / entire) * 360
		
		self.HourHand:PivotTo(self.HourInitial * CFrame.Angles(0, 0, math.rad(-angle)))
	end
	
	self:Step()
end

function ClientClock.OnConstructClient(self: Component)
	
	self.HourHand = self.Instance:WaitForChild("hour", 15)
	self.MinuteHand = self.Instance:WaitForChild("minute", 15)
	
	self.HourInitial = self.HourHand:GetPivot()
	self.MinuteInitial = self.MinuteHand:GetPivot()
	
	self.Sound = self.Instance.PrimaryPart:FindFirstChildWhichIsA("Sound")
		or SoundUtility.CreateSound(SoundUtility.Sounds.Instances.Clock)
	
	self.Sound.Parent = self.MinuteHand
	
	for _, Instance in ipairs(self.Instance:GetDescendants()) do
		if Instance:IsA("ProximityPrompt") then
			Instance:Destroy()
		end
	end
end

--//Returner

return ClientClock