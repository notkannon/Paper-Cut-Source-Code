--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseImageSequences = require(ReplicatedStorage.Client.Components.UIAssignable.BaseImageSequences)

--//Constants

local SEQUENCE = {
	"rbxassetid://127220156461225",
	"rbxassetid://126606377508979",
	"rbxassetid://111546151134985",
	"rbxassetid://96103524826798",
	"rbxassetid://92913927749612",
	"rbxassetid://88043215632531",
	"rbxassetid://138646183228157",
	"rbxassetid://139616783314654",
	"rbxassetid://71015009167957",
}

--//Variables

local ViscousAcidImageSequenceUI = BaseComponent.CreateComponent("ViscousAcidImageSequenceUI", {

	isAbstract = false

}, BaseImageSequences) :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,

	OnConstructClient: (self: Component) -> (),
}

export type Fields = {
} & BaseImageSequences.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ViscousAcidImageSequenceUI", ImageLabel>
export type Component = BaseComponent.Component<MyImpl, Fields, "ViscousAcidImageSequenceUI", ImageLabel> 

--//Methods

function ViscousAcidImageSequenceUI.OnConstruct(self: Component)
	self.SequenceObject = SEQUENCE
	self.Delay = 0.065
	self.reverseOnFinished = false
end

function ViscousAcidImageSequenceUI.OnConstructClient(self: Component, ...)
	BaseImageSequences.OnConstructClient(self, ...)
end

--//Returner

return ViscousAcidImageSequenceUI