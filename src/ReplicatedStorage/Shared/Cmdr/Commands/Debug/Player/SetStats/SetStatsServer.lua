--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)
local ServerProducer = RunService:IsServer() and require(ServerScriptService.Server.ServerProducer) or nil

--//Returner

return function(_, Players: { Player }, StatsType: string, Value: number)
	
	for _, Player in Players do
		local PlayerData = ServerProducer.getState(Selectors.SelectStats(Player.Name))
		if not PlayerData then
			return `No data found on {Player.Name}`
		end
		
		ServerProducer.UpdatePlayerStats(Player.Name, StatsType, Value)
	end
end