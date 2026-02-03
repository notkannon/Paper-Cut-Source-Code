--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local ItemService = RunService:IsServer() and require(ServerScriptService.Server.Services.ItemService) or nil
local ComponentTypes = RunService:IsServer() and require(ServerScriptService.Server.Types.ComponentTypes) or nil
local ComponentsManager = RunService:IsServer() and require(ReplicatedStorage.Shared.Classes.ComponentsManager) or nil

--//Returner

return function(context, item: string, amount: number)
	local success = 0
	
	for _, ItemComponent in ipairs(ItemService:GetAllItemsDropped()) do
		ItemComponent:Destroy()
		success += 1
	end
	
	return `{ success } { item } items cleared.`
end