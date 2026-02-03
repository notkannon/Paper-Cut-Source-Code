--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local BaseRound = require(ServerScriptService.Server.Classes.BaseRound)
local RoundTypes = require(ServerScriptService.Server.Types.RoundTypes)
local PlayerService = require(ServerScriptService.Server.Services.PlayerService)
local MapsManager = require(ServerScriptService.Server.Services.MapsManager)

local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

--//Variables

local Intermission = BaseRound.CreateRound("Intermission")

--//Types

export type Impl = RoundTypes.RoundImpl<nil, nil, "Intermission">
export type Round = RoundTypes.Round<nil, nil, "Intermission">

--//Methods

function Intermission.OnConstruct(self: Round)
	self.NextPhaseName = "Round"
	self.PhaseDuration = 90
end

function Intermission.OnStartServer(self: Round)
	local Map = MapsManager.Map
	if Map then
		MapsManager:UnloadMap()
		self.Service:SetPreparing(true)
		task.wait(5)
		
		self.Service:SetPreparing(false)
	end
	
	for _, PlayerComponent in ipairs(ComponentsUtility.GetAllPlayerComponents()) do
		if not PlayerComponent:IsLoaded() then
			continue
		end
		
		PlayerComponent:SetRole("Spectator")
		PlayerComponent:ResetCharacterMockData()
		PlayerComponent:ApplyRoleConfig(false)
		
		local HaveRoundStats = self.Service.HasPlayerRoundStats(PlayerComponent.Instance)
		if HaveRoundStats then
			local RoundStatComponent = ComponentsManager.GetFirstComponentInstanceOf(PlayerComponent.Instance, "PlayerRoundStats")
			RoundStatComponent:ProcessRoundEnd()
			RoundStatComponent:Destroy()
		end
		
		task.wait(2)

		local success, message = pcall(function() 
			return PlayerComponent:Respawn()  -- game once crashed cuz someone left midrespawn
		end)

		if not success then
			warn(`Failed to respawn {PlayerComponent.Instance}: {message}`) -- .Instance could be nil
		end

	end
end

function Intermission.ShouldStart(self: Round)
	return true
end

--//Returner

return Intermission