--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)

--//Functions

local function GetPlayerByName(name: string)
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player.Name == name then
			return Player
		end
	end
end

local function BuildRoleConfigMiddleware(producer)
	
	return function(nextDispatch, actionName)
		
		return function(...)
			
			if actionName == "SetRole" then
				
				local playerName, role = ...
				local Player = GetPlayerByName(playerName)
				
				--building role
				Classes.GetSingleton("RolesManager")
					:_BuildPlayerRole(Player, role)
			end
			
			return nextDispatch(...)
		end
	end
end

--//Returner

return {
	BuildRoleConfigMiddleware = BuildRoleConfigMiddleware,
}