--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil

--//Returner

return function(_, players: { Player }, shouldRespawn: boolean?)
	if shouldRespawn == nil then shouldRespawn = true end
	
	for _, Player: Player in pairs(players) do

		local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(Player)
		
		if not PlayerComponent then
			continue
		end

		PlayerComponent.Janitor:Add(
			task.spawn(
				PlayerComponent.ApplyRoleConfig,
				PlayerComponent,
				shouldRespawn
			)
		)
	end

	return `Config was applied for { #players } players`
end