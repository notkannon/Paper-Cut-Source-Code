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

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local MatchStateClient = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.MatchStateClient) or nil
local MedicTargetEffect = require(ReplicatedStorage.Shared.Effects.Specific.Role.Medic.MedicTargetHighlight)

--//Variables

local EmpathicConnection = BaseComponent.CreateComponent("EmpathicConnection", {

	isAbstract = false,

}, BasePassive) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BasePassive.MyImpl)),
	
	TrackedPlayers: { [Player]: Janitor.Janitor },
	
	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component, enabled: boolean?) -> (),
	OnConstructServer: (self: Component) -> (),
}

export type Fields = {
	
} & BasePassive.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "EmpathicConnection", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "EmpathicConnection", PlayerTypes.Character>

--//Methods

function EmpathicConnection.TrackPlayer(self: Component, player: Player)
	
	--config definition
	local Config = self:GetConfig()
	
	--removing old things
	if self.TrackedPlayers[player] then
		
		self.TrackedPlayers[player]:Destroy()
		self.TrackedPlayers[player] = nil
	end
	
	local PlayerJanitor = self.EnabledJanitor:Add(Janitor.new())
	local Character = player.Character :: PlayerTypes.Character
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	
	--state tracking
	local function OnHealthChanged()
		
		--no effect found, creating it instead
		if Humanoid.Health <= Config.MaxHealthDetect and not PlayerJanitor:Get("Effect") then
			
			local Effect = MedicTargetEffect.locally(Character)
			
			PlayerJanitor:Add(
				
				function()
					pcall(Effect.Destroy, Effect)
				end,
				
				true,
				"Effect"
			)
			
		elseif Humanoid.Health > Config.MaxHealthDetect and PlayerJanitor:Get("Effect") then
			
			--removing effect when player's health is restored
			PlayerJanitor:Remove("Effect")
		end
	end
	
	PlayerJanitor:Add(Humanoid.HealthChanged:Connect(OnHealthChanged))
	
	OnHealthChanged()
	
	--memorize
	self.TrackedPlayers[player] = PlayerJanitor
end

function EmpathicConnection.OnEnabledClient(self: Component)
	
	--tracking new characters
	self.EnabledJanitor:Add(MatchStateClient.PlayerSpawned:Connect(function(player)
		
		if player == self.Player then
			if not RunService:IsStudio() then
				return
			end
		end
		
		self:TrackPlayer(player)
	end))
	
	--collecting already exist characters
	for _, Player: Player in ipairs(MatchStateClient:GetAlivePlayers("Student")) do
		
		if Player == self.Player then
			if not RunService:IsStudio() then
				continue
			end
		end
		
		self:TrackPlayer(Player)
	end
end

function EmpathicConnection.OnConstructClient(self: Component, ...)
	
	self.TrackedPlayers = {}
	
	BasePassive.OnConstructClient(self, ...)
	
	--cleanup
	self.Janitor:Add(Players.PlayerRemoving:Connect(function(player)
		
		if self.TrackedPlayers[player] then
			
			self.TrackedPlayers[player]:Destroy()
			self.TrackedPlayers[player] = nil
		end
	end))
end

function EmpathicConnection.OnConstruct(self: Component, enabled: boolean?)
	BasePassive.OnConstruct(self)
	
	self.Permanent = true
end

--//Returner

return EmpathicConnection