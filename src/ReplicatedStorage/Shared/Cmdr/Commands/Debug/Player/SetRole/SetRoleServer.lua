--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil

--//Returner

return function(_, players: { Player }, role: string)

	for _, Player: Player in pairs(players) do

		local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(Player)
		
		if not PlayerComponent then
			continue
		end

		PlayerComponent.Janitor:Add(
			task.spawn(
				PlayerComponent.SetRole,
				PlayerComponent,
				role
			)
		)
	end

	return `Role "{ role }" was set for { #players } players`
end