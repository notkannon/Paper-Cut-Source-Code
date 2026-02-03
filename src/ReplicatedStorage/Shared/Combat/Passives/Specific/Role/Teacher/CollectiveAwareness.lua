--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BasePassive = require(ReplicatedStorage.Shared.Components.Abstract.BasePassive)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local SFX = SoundUtility.Sounds.Players.Skills.EyeForTrouble.Trigger

local MatchService = RunService:IsServer() and require(ServerScriptService.Server.Services.MatchService) or nil
local HighlightPlayerEffect = require(ReplicatedStorage.Shared.Effects.HighlightPlayer)

--//Variables

local CollectiveAwareness = BaseComponent.CreateComponent("CollectiveAwareness", {

	isAbstract = false,

}, BasePassive) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BasePassive.MyImpl)),

	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component, enabled: boolean?) -> (),
	OnConstructServer: (self: Component) -> (),
}

export type Fields = {

} & BasePassive.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "CollectiveAwareness", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "CollectiveAwareness", PlayerTypes.Character>

--//Methods

function CollectiveAwareness.MutualTag(self: Component, otherPlayer: Player)
	local Config = self:GetConfig()
	
	local SelfEffect = HighlightPlayerEffect.new(self.Player.Character, {
		color = Color3.fromRGB(204, 204, 204),
		lifetime = 999999,
		fadeInTime = 0.5,
		fadeOutTime = 0.5,
		transparency = 0.75,
		respectTargetTransparency = false,
		minDistance = Config.MinDistance,
		measureDistanceFrom = otherPlayer.Character,
	})
	
	local Effect = HighlightPlayerEffect.new(otherPlayer.Character, {
		color = Color3.fromRGB(204, 204, 204),
		lifetime = 999999,
		fadeInTime = 0.5,
		fadeOutTime = 0.5,
		transparency = 0.75,
		respectTargetTransparency = false,
		minDistance = Config.MinDistance,
		measureDistanceFrom = self.Player.Character
	})
	
	SelfEffect:Start({otherPlayer})
	Effect:Start({self.Player})
	
	self.EnabledJanitor:Add(function()
		--if not SelfEffect.IsDestroyed then
			SelfEffect:Destroy()
		--end
		--if not Effect.IsDestroyed then
			Effect:Destroy()
		--end
	end)
end

function CollectiveAwareness.OnEnabledServer(self: Component)
	--getting all teachers
	for _, Player: Player in ipairs(MatchService:GetAlivePlayers("Killer")) do
		if Player == self.Player and not RunService:IsStudio() then continue end
		self:MutualTag(Player)
	end
end

function CollectiveAwareness.OnConstruct(self: Component, enabled: boolean?)
	BasePassive.OnConstruct(self)
	self.Permanent = true
end

--//Returner

return CollectiveAwareness