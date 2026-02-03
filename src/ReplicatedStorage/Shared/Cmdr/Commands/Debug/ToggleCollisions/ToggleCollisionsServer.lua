--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local BaseMap = RunService:IsServer() and require(ServerScriptService.Server.Components.Abstract.BaseMap) or nil

--//Returner

return function(_, Collisions: boolean)
	if not workspace:FindFirstChild("Map") then
		return `Map not founded`
	end
	
	local Map = ComponentsManager.GetFirstComponentInstanceOf(workspace.Map, BaseMap) :: BaseMap.Component
	print(Map)
	
	Map:ToggleDebugCollisions(Collisions)
	
	return `Debug: {Collisions and "Enabled" or "Disabled" }, Showing map collisions`
end