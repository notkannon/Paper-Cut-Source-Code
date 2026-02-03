--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

--//Types

type Sequence = {
	
	Track: AnimationTrack?, -- currently selected/active track
	Tracks: { string: AnimationTrack },
	
}

export type MyImpl = {
	__index: MyImpl,

	AddSequence: (self: Component, name: string, animations: { string: Animation }) -> (),
	SelectSequenceTrack: (self: Component, name: string, trackName: string) -> (), -- changes current sequence animation to provided one (kinda :SelectSequenceTrack("Walk", "Injured" or "Normal"))

	OnConstructClient: (self: Component) -> (),
}

export type Fields = {
	Sequences: { string: Sequence }
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "Animator", Animator>
export type Component = BaseComponent.Component<MyImpl, Fields, "Animator", Animator>

--//Variables

local LocalPlayer = Players.LocalPlayer
local Animator = BaseComponent.CreateComponent("Animator", {
	
	isAbstract = false,
	
}) :: Impl

--//Methods

function AddSequence(self: Component, name: string, animations: { string: Animation })
	
	local Sequence = {
		
		Tracks = {},
		
	} :: Sequence
	
	--loading all provided tracks
	for Name, Animation in pairs(animations) do
		Sequence.Tracks[Name] = AnimationUtility.LoadAnimationOnce(self.Instance, Animation)
	end
	
	self.Sequences[name] = Sequence
end

function SelectSequenceTrack(self: Component, name: string, trackName: string)
	
end

function Animator.OnConstructClient(self: Component)
	
	print("Animator added!")
	
	self.Sequences = {}
end

--//Returner

return Animator