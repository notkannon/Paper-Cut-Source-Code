--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")

--//Imports

--local BaseDoor = require(ReplicatedStorage.Shared.Classes.Abstract.BaseDoor)
local BaseRound = require(ServerScriptService.Server.Components.Abstract.BaseRound)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)
local RoundTypes = require(ServerScriptService.Server.Types.RoundTypes)

--//Variables

local Round = BaseRound.CreateRound("Round") :: RoundTypes.RoundImpl<nil, nil, "Round">

--//Types

export type Round = RoundTypes.Round<nil, nil, "Round">

--//Methods

function Round.OnConstruct(self: Round)
	self.Requirements = { "Intermediate" }
end

function Round:OnEnd()
	for _, Component in pairs(ComponentsUtility.GetAllPlayerComponents()) do
		if Component:GetRoleConfig().Team == Teams.Student then
			Component:Respawn()
		end
	end
end

function Round:ShouldSpawn()
	return false
end

--//Returner

return Round