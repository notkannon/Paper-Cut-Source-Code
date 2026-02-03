--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local ServerRemotes = require(ServerScriptService.Server.ServerRemotes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local ChaseReplicator = Classes.CreateSingleton("ChaseReplicator") :: Impl

--//Types

export type ChaseData = {
	EndTimestamp: number,
	StartTimestamp: number,
}

export type TRData = {
	EndTimestamp: number,
	StartTimestamp: number,
	CurrentLayer: number
}

export type Impl = {
	__index: Impl,

	new: () -> Service,
	IsImpl: (self: Service) -> boolean,
	GetName: () -> "ChaseReplicator",
	GetExtendsFrom: () -> nil,
	
	Reset: (self: Service) -> (),
	IsPlayerInChase: (self: Service, player: Player) -> boolean,
	GetPlayerOutOfChaseTime: (self: Service, player: Player) -> number,
	
	GetTerrorRadiusFromPlayer: (self: Service, player: Player) -> number,
}

export type Fields = {
	
	ActiveTerrorRadiuses: { [Player]: TRData },
	ActiveChases: { [Player]: ChaseData? },
	
	TerrorRadiusChanged: Signal.Signal<Player>,
	
	ChaseEnded: Signal.Signal<Player>,
	ChaseStarted: Signal.Signal<Player>,
}

export type Service = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Methods

function ChaseReplicator.Reset(self: Service)
	
	--mark all players out of chase
	for Player, _ in ipairs(self.ActiveChases) do
		
		if not self:IsPlayerInChase(Player) then
			continue
		end
		
		self.ChaseEnded:Fire(Player)
	end
	
	table.clear(self.ActiveChases)
	table.clear(self.ActiveTerrorRadiuses)
end

function ChaseReplicator.GetPlayerOutOfChaseTime(self: Service, player: Player)
	
	local MatchService = Classes.GetSingleton("MatchService")
	local Data = self.ActiveChases[player]

	if not Data or not Data.StartTimestamp then
		return MatchService:GetPhaseRealTimePassed()
	end

	if self:IsPlayerInChase(player) then
		return 0
	end

	return math.max(0, os.clock() - (Data.EndTimestamp or 0))
end

function ChaseReplicator.IsPlayerInChase(self: Service, player: Player)
	
	local Data = self.ActiveChases[player]
	
	if not Data then
		return false
	end
	
	return Data.StartTimestamp > (Data.EndTimestamp or 0) or false
end

function ChaseReplicator.GetTerrorRadiusFromPlayer(self: Service, player: Player)
	
	local Data = self.ActiveTerrorRadiuses[player]
	if not Data then
		return {
			StartTimestamp = 0,
			EndTimestamp = 0,
			CurrentLayer = 0,
		}
	end
	
	return Data
end

function ChaseReplicator.OnConstructServer(self: Service)
	
	local MatchService = Classes.GetSingleton("MatchService")
	
	self.ActiveChases = {}
	self.ActiveTerrorRadiuses = {}
	self.TerrorRadiusChanged = Signal.new()
	self.ChaseEnded = Signal.new()
	self.ChaseStarted = Signal.new()
	
	--refreshing on round changing
	MatchService.MatchEnded:Connect(function()
		
		--chase replicator reset
		self:Reset()
	end)
	
	--cleaning up some data
	Players.PlayerRemoving:Connect(function(player)
		
		local ChaseData = self.ActiveChases[player]
		local TRData = self.ActiveTerrorRadiuses[player]
		
		if ChaseData then
			
			table.clear(ChaseData)
			self.ActiveChases[player] = nil
			
		elseif TRData then
			
			table.clear(TRData)
			self.ActiveTerrorRadiuses[player] = nil
			
		end
	end)
	
	--handling client requests
	ServerRemotes.ClientChaseStateChanged.SetCallback(function(player, active)
		
		--phase validation
		if not MatchService:IsRound() then
			return
		end
		
		local InChase = self:IsPlayerInChase(player)
		
		--initializing player's data
		if not self.ActiveChases[player] then
			
			self.ActiveChases[player] = {
				
				StartTimestamp = 0,
				EndTimestamp = 0,
				
			} :: ChaseData
		end
		
		if not active and InChase then
			
			--ending chase
			self.ActiveChases[player].EndTimestamp = os.clock()
			self.ChaseEnded:Fire(player)
			
		elseif active and not InChase then
			
			--starting chase
			self.ActiveChases[player].StartTimestamp = os.clock()
			self.ChaseStarted:Fire(player)
		end
	end)
	
	ServerRemotes.ClientTRStateChanged.SetCallback(function(player, layer)
		
		--phase validation
		if not MatchService:IsRound() then
			return
		end
		
		-- adding from data
		if not self.ActiveTerrorRadiuses[player] then
			self.ActiveTerrorRadiuses[player] = {
				StartTimestamp = 0,
				EndTimestamp = 0,
				CurrentLayer = 0,
			} :: TRData
		end
		
		print(player, layer)
		
		if layer == 0 then
			-- layer is 0 that means person left the TR , ig
			self.ActiveTerrorRadiuses[player].CurrentLayer = 0
			self.ActiveTerrorRadiuses[player].EndTimestamp = os.clock()
		else
			if self.ActiveTerrorRadiuses[player].CurrentLayer == 0 then
				self.ActiveTerrorRadiuses[player].StartTimestamp = os.clock()
			end
			self.ActiveTerrorRadiuses[player].CurrentLayer = layer
		end
		
		self.TerrorRadiusChanged:Fire(player)
	end)
end

--//Returner

local Singleton = ChaseReplicator.new()
return Singleton :: Service