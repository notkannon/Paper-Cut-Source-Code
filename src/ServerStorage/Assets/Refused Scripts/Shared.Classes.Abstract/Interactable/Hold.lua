--//Service

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--//Import

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)

local Interaction = BaseComponent.GetNameComponents().Interaction
local Interactable = BaseComponent.GetNameComponents().Interactable

local Hold = BaseComponent.CreateComponent("Hold", {
	tag = "Hold",
	isAbstract = true
})

--//Type
export type Fields = {
	Proximities: Interactable.BaseInteractionState,
	Instance: ProximityPrompt,
}

export type MyImps = {
	__Index: MyImps,
	
	Start: (self: Component) -> (),
	End: (self: Component) -> (),
	
	OnConstruct: (self: Component) -> (),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, ProximityPrompt, {}>
export type Component = 
	BaseComponent.Component<MyImpl, Fields, ProximityPrompt, {}> 

--//Variables

function Hold.Start(self: Component)
	TweenService:Create(self.Proximities.Sign.Scale, TweenInfo.new(.1), {Scale = .8}):Play()
	
	local Tween: Tween = TweenService:Create(self.Proximities.Sign.Fill, TweenInfo.new(self.Instance.HoldDuration), {Offset = Vector2.new(0, 0)})
	Tween:Play()
	
	self.Tween = Tween
end

function Hold.End(self: Component)
	if self.Tween then
		self.Tween:Cancel()
		self.Tween = nil
	end
	
	TweenService:Create(self.Proximities.Sign.Scale, TweenInfo.new(.1), {Scale = 1}):Play()
	TweenService:Create(self.Proximities.Sign.Fill, TweenInfo.new(.1), {Offset = Vector2.new(0, 1)}):Play()
end

--//Return
return Hold