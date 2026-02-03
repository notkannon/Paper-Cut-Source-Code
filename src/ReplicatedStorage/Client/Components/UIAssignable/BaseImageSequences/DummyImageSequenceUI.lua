--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseImageSequences = require(ReplicatedStorage.Client.Components.UIAssignable.BaseImageSequences)

local UiRelated = require(ReplicatedStorage.Shared.Data.UiRelated)

--//Constants

local SEQUENCE = UiRelated.ImageTextures.PreloaderIcon

--//Variables

local DummyImageSequenceUI = BaseComponent.CreateComponent("DummyImageSequenceUI", {

	isAbstract = false

}, BaseImageSequences) :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,

	OnConstructClient: (self: Component) -> (),
}

export type Fields = {
} & BaseImageSequences.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "DummyImageSequenceUI", ImageLabel>
export type Component = BaseComponent.Component<MyImpl, Fields, "DummyImageSequenceUI", ImageLabel> 

--//Methods

function DummyImageSequenceUI.OnConstruct(self: Component)
	self.SequenceObject = SEQUENCE
	self.Delay = 0.07
	self.reverseOnFinished = true
end

function DummyImageSequenceUI.OnConstructClient(self: Component, ...)
	BaseImageSequences.OnConstructClient(self, ...)
end

--//Returner

return DummyImageSequenceUI