--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseRound = require(ServerScriptService.Server.Classes.BaseRound)
local RoundTypes = require(ServerScriptService.Server.Types.RoundTypes)
local PlayerService = require(ServerScriptService.Server.Services.PlayerService)

local MapsManager = require(ServerScriptService.Server.Services.MapsManager)
local PlayerService = require(ServerScriptService.Server.Services.PlayerService)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

--local FreezeStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Freeze)
local MouseUnlockedEffect = require(ReplicatedStorage.Shared.Combat.Statuses.MouseUnlocked)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)

local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local PlayerRoundStatsComponent = require(ReplicatedStorage.Shared.Components.Matchmaking.PlayerRoundStats)

local ServerRemotes = require(ServerScriptService.Server.ServerRemotes)

--//Variables

local Result = BaseRound.CreateRound("Result")

--//Types

export type Impl = RoundTypes.RoundImpl<nil, nil, "Result">
export type Round = RoundTypes.Round<nil, nil, "Result">

--//Methods

function Result.OnConstruct(self: Round)
	self.NextPhaseName = "Intermission"
	self.PhaseDuration = 20
end

function Result.OnStartServer(self: Round)
	print("Starting Results")
	
	local Components = {} :: {[Player]: any?}
	
	-- dont despawn engaged players! engaged are just those who loaded and not afk, they might've joined midround
	--for _, PlayerComponent in self.Service.GetEngagedPlayerComponents() do
		
	--end
	
	for _, PlayerComponent in self.Service.GetPlayerComponentsWithRoundStats() do
		local RoundStatComponent = ComponentsManager.GetFirstComponentInstanceOf(PlayerComponent.Instance, "PlayerRoundStats")
		
		print(PlayerComponent.Instance, 'has it the stats ', RoundStatComponent._Stats)
		Components[PlayerComponent.Instance] = {Stats = RoundStatComponent._Stats, AwardMap = RoundStatComponent._AwardMap}
		
		task.spawn(PlayerComponent.Despawn, PlayerComponent)
	end
	
	-- only fire results to those who played
	ServerRemotes.RoundStatsComponentReplicator.FireList(
		self.Service.GetPlayersWithRoundStats(),
		Components
	)
end

function Result.OnEndServer(self: Round)
	
	for _, PlayerComponent in self.Service.GetEngagedPlayerComponents() do
		local RoundStatComponent = ComponentsManager.GetFirstComponentInstanceOf(PlayerComponent.Instance, "PlayerRoundStats")
		
		print(PlayerComponent.Instance, 'has roundstats', RoundStatComponent)
		ComponentsManager.Remove(PlayerComponent.Instance, PlayerRoundStatsComponent)
	end

	MapsManager:UnloadMap()
	self.Service:SetPreparing(true)
	
	task.wait(6)
	self.Service:SetPreparing(false)
end

function Result.ShouldStart(self: Round)
	return true
end

--//Returner

return Result