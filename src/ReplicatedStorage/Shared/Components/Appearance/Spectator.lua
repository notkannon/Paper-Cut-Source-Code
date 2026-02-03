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
}

local TRANSPARENT_ACCESSORY_TYPES = {
	Enum.AccessoryType.Hat,
	Enum.AccessoryType.Hair,
	Enum.AccessoryType.Face,
	Enum.AccessoryType.Eyebrow,
	Enum.AccessoryType.Eyelash,
	Enum.AccessoryType.Neck,
}

--//Variables

local SpectatorAppearance = BaseComponent.CreateComponent("SpectatorAppearance", {
	isAbstract = false
}, BaseAppearance) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseAppearance.MyImpl)),
	
	Footprints: { {CFrame: CFrame, Timestamp: number} }
}

export type Fields = {
	
	FootprintAdded: Signal.Signal<CFrame>,
	
} & BaseAppearance.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "SpectatorAppearance", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "SpectatorAppearance", PlayerTypes.Character>

--//Methods

function SpectatorAppearance.CreateFootstep(self: Component)
	
	local Sound = BaseAppearance.CreateFootstep(self)
	
	if not Sound then
		return
	end
	
	Sound.PlaybackSpeed *= 2
	
	return Sound
end

function SpectatorAppearance.IsDescendantTransparent(self: Component, descendant: Instance)
	
	--return false always cuz spectators shouldn't have 1st person probably?
	--TODO: I think we can make auto camera distance to head detection)
	return false
	
	--if not self:IsLocalPlayer() then
	--	return false
	--end
	
	--return table.find(TRANSPARENT_NAMES, descendant.Name) or descendant.Parent:IsA("Accessory")
	--	and table.find(TRANSPARENT_ACCESSORY_TYPES, descendant.Parent.AccessoryType)
end

--//Returner

return SpectatorAppearance