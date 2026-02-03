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

local MatchService = RunService:IsServer() and require(ServerScriptService.Server.Services.MatchService) or nil
local HighlightPlayerEffect = require(ReplicatedStorage.Shared.Effects.HighlightPlayer)

local ChaseReplicator = RunService:IsServer() and require(ServerScriptService.Server.Services.ChaseReplicator) or nil

--//Variables

local SpreadTheWordPassive = BaseComponent.CreateComponent("SpreadTheWord", {

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

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "SpreadTheWordPassive", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "SpreadTheWordPassive", PlayerTypes.Character>

--//Methods

function SpreadTheWordPassive.OnEnabledServer(self: Component)
	local Config = self:GetConfig()
	
	--running detection cycle
	self.EnabledJanitor:Add(ChaseReplicator.ChaseStarted:Connect(function(player)
		if player ~= self.Player then
			return
		end

		local SelfEffect = HighlightPlayerEffect.new(self.Player.Character, {
			color = Color3.fromRGB(251, 255, 44),
			lifetime = 999999,
			fadeInTime = 0,
			fadeOutTime = 0,
			transparency = 0.75,
			respectTargetTransparency = false
		})

		local Students = {}

		--getting all students
		for _, Player: Player in ipairs(MatchService:GetAlivePlayers("Survivor")) do
			if Player == self.Player then continue end
			table.insert(Students, Player)
		end

		-- revealing self to teachers
		SelfEffect:Start(Students)
		self.EnabledJanitor:Add(function()
			SelfEffect:Destroy()
		end, true, "EffectClear")
	end))
	
	self.EnabledJanitor:Add(ChaseReplicator.ChaseEnded:Connect(function(player)
		if player == self.Player then
			self.EnabledJanitor:Remove("EffectClear")
		end
	end))
end

function SpreadTheWordPassive.OnConstruct(self: Component, enabled: boolean?)
	BasePassive.OnConstruct(self)
	self.Permanent = true
	--print(self:GetName(), 'has started')
end

--//Returner

return SpreadTheWordPassive