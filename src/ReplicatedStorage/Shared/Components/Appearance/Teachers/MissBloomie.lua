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
	"BackHair",
	"LeftEar",
	"RightEar",
	"eye",
	"Handle"
}

--//Variables

local MissBloomieAppearance = BaseComponent.CreateComponent("MissBloomieAppearance", {
	isAbstract = false
}, BaseAppearance) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseAppearance.MyImpl)),
}

export type Fields = {

} & BaseAppearance.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "MissBloomieAppearance", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "MissBloomieAppearance", PlayerTypes.Character>

--//Methods

function MissBloomieAppearance.CreateFootstep(self: Component)
	local Sound = BaseAppearance.CreateFootstep(self)

	if not Sound then
		return
	end

	Sound.Volume *= 0.6
	Sound.PlaybackSpeed *= 3

	return Sound
end

function MissBloomieAppearance.IsDescendantTransparent(self: Component, descendant: Instance)
	return self:IsLocalPlayer()
		and table.find(TRANSPARENT_NAMES, descendant.Name)
end

--//Returner

return MissBloomieAppearance