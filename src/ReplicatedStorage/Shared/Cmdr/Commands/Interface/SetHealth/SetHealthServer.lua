--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil

--//Returner

return function(_, players: { Player }, health: number)
	for _, Component in pairs(ComponentsUtility.GetAllCharacterComponents()) do
		if not table.find(players, Component.PlayerComponent.Instance) then
			continue
		end
		
		Component.Humanoid.Health = health
	end

	return `Health was set for {#players} players to {health}.`
end