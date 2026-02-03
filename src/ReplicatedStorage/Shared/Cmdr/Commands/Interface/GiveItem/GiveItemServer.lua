--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local GlobalSettings = require(ReplicatedStorage.Shared.Data.GlobalSettings)
local ItemService = RunService:IsServer() and require(ServerScriptService.Server.Services.ItemService) or nil
local ComponentTypes = RunService:IsServer() and require(ServerScriptService.Server.Types.ComponentTypes) or nil
local ComponentsManager = RunService:IsServer() and require(ReplicatedStorage.Shared.Classes.ComponentsManager) or nil
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil

--//Returner

return function(_, players: { Player }, item: string, amount: number?, overstack: boolean?)
	if amount == nil then
		amount = 1
	end
	if amount > 25 then
		amount = 25
	end
	local minSuccess = 999
	local maxSuccess = 0
	for i = 1, amount do
		local success = 0
		
		for _, player: Player in ipairs(players) do
			
			local Find = table.find(GlobalSettings.Whilelist, player.UserId)
			local ItemFind = table.find(GlobalSettings.TestersBlackListItems, item)
			
			if not Find and ItemFind then
				return "Nop, You cannot get "..item.. " Item"
			end

			local InventoryComponent = ComponentsUtility.GetInventoryComponentFromPlayer(player)
			
			if not InventoryComponent or (InventoryComponent:IsMaxSlots() and not overstack) then
				continue
			end
			
			InventoryComponent:Add(ItemService:CreateItem(item, true), overstack)
			
			success += 1
		end
		if success > maxSuccess then maxSuccess = success end
		if success < minSuccess then minSuccess = success end
	end
	
	if minSuccess == maxSuccess then
		return `Item "{ item }" was given to { minSuccess } players`
	else
		return `Item "{ item }" was given to {minSuccess}-{maxSuccess} players`
	end
end