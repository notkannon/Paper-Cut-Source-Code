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
	
	local CharacterComponent = ComponentsManager.Get(context.Executor.Character, "CharacterComponent") :: ComponentTypes.Character
	if not CharacterComponent then
		return
	end
	
	for n = 1, math.clamp(amount, 1, 25) do
		
		local ItemComponent = ItemService:CreateItem(item, true, true)
		ItemService:HandleDropItem(ItemComponent, CharacterComponent.HumanoidRootPart.Position)
		
		success += 1
	end
	
	return `{ success } { item } items created.`
end