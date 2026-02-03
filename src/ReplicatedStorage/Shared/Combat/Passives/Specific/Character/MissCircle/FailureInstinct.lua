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
local ChaseReplicator = RunService:IsServer() and require(ServerScriptService.Server.Services.ChaseReplicator) or nil
local HighlightPlayerEffect = require(ReplicatedStorage.Shared.Effects.HighlightPlayer)

--//Variables

local FailureInstinctPassive = BaseComponent.CreateComponent("FailureInstinctPassive", {

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

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "FailureInstinctPassive", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "FailureInstinctPassive", PlayerTypes.Character>

--//Methods

function FailureInstinctPassive.OnEnabledServer(self: Component)
	
	local Config = self:GetConfig()
	local LastUpdate = os.clock()
	local StudentHighlights = {} :: { [Player]: Refx.ServerProxy }
	
	--literally
	local function RemoveHighlight(player: Player)
		
		if StudentHighlights[player] then
			
			local Effect = StudentHighlights[player]
			
			pcall(Effect.Destroy, Effect)
			
			StudentHighlights[player] = nil
		end
	end
	
	--memory clean
	self.EnabledJanitor:Add(Players.PlayerRemoving:Connect(RemoveHighlight))
	self.EnabledJanitor:Add(ChaseReplicator.ChaseStarted:Connect(RemoveHighlight))
	
	--running detection cycle
	self.EnabledJanitor:Add(RunService.Heartbeat:Connect(function()
		
		--limiting update rate
		if os.clock() - LastUpdate < 1 then
			return
		end
		
		LastUpdate = os.clock()
		
		--getting players not chased
		for _, Player: Player in ipairs(MatchService:GetAlivePlayers("Student")) do
			
			local OutOfChaseTimePassed = ChaseReplicator:GetPlayerOutOfChaseTime(Player)
			
			if OutOfChaseTimePassed > Config.OutOfChaseTime then
				
				--check if player already highlighted
				if StudentHighlights[Player] then
					continue
				end
				
				local Effect = HighlightPlayerEffect.new(Player.Character, {
					color = Color3.fromRGB(255, 57, 57),
					lifetime = 10000,
					fadeInTime = 10,
					transparency = 0.7,
					respectTargetTransparency = true,
				})
				
				--creating effect only for player owner
				Effect:Start({ self.Player })
				
				StudentHighlights[Player] = Effect
				
				--removing on passive disabling/destroying
				self.EnabledJanitor:Add(function()
					--if not Effect.IsDestroyed then
						Effect:Destroy()
					--end
				end)
			end
		end
	end))
end

function FailureInstinctPassive.OnConstruct(self: Component, enabled: boolean?)
	BasePassive.OnConstruct(self)
	
	self.Permanent = true
end

--//Returner

return FailureInstinctPassive