--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseImageSequences = require(ReplicatedStorage.Client.Components.UIAssignable.BaseImageSequences)

--//Constants

local SEQUENCE = {
	"rbxassetid://87367001678941",
	"rbxassetid://95151143155216",
	"rbxassetid://124804447506007",
	"rbxassetid://79234479476940",
}

--//Variables

local ClockImageSequenceUI = BaseComponent.CreateComponent("ClockImageSequenceUI", {

	isAbstract = false

}, BaseImageSequences) :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,

	OnConstructClient: (self: Component) -> (),
}

export type Fields = {
} & BaseImageSequences.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ClockImageSequenceUI", ImageLabel>
export type Component = BaseComponent.Component<MyImpl, Fields, "ClockImageSequenceUI", ImageLabel> 

--//Methods

function ClockImageSequenceUI.OnConstruct(self: Component)
	self.SequenceObject = SEQUENCE
	self.Delay = 0.07
	self.reverseOnFinished = false
end

function ClockImageSequenceUI.OnConstructClient(self: Component, ...)
	BaseImageSequences.OnConstructClient(self, ...)
end

--//Returner

return ClockImageSequenceUI