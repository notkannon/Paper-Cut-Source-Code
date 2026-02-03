--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseAppearance = require(ReplicatedStorage.Shared.Components.Abstract.BaseAppearance)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Constants

local TRANSPARENT_NAMES = {
	"Head",
	"face",
	"Hair",
	"eye",
	"Handle",
	"LeftHorn",
	"RightHorn"
}

--//Variables

local MissCircleAppearance = BaseComponent.CreateComponent("MissCircleAppearance", {
	isAbstract = false
}, BaseAppearance) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseAppearance.MyImpl)),
}

export type Fields = {

} & BaseAppearance.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "MissCircleAppearance", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "MissCircleAppearance", PlayerTypes.Character>

--//Methods

function MissCircleAppearance.CreateFootstep(self: Component)
	local Sound = BaseAppearance.CreateFootstep(self)
	
	if not Sound then
		return
	end

	Sound.PlaybackSpeed *= 0.85
	
	local Impact = SoundUtility.CreateTemporarySound(SoundUtility.Sounds.Players.Footsteps.Heavy)
	Impact.Volume = math.clamp((self.HumanoidRootPart.AssemblyLinearVelocity * Vector3.new(1, 0 ,1)).Magnitude / 24, 0, 1) * 0.02
	Impact.Parent = self.HumanoidRootPart

	return Sound
end

function MissCircleAppearance.IsDescendantTransparent(self: Component, descendant: Instance)
	return self:IsLocalPlayer()
		and table.find(TRANSPARENT_NAMES, descendant.Name)
end

--//Returner

return MissCircleAppearance