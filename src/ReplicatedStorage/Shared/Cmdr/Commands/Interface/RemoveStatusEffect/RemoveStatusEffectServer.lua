--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Returner

return function(context, players: { Player }, statusName: string)
	local success = 0
	
	for _, Player in ipairs(players) do
		local CharacterComponent = ComponentsManager.Get(Player.Character, "CharacterComponent")
		if not CharacterComponent then
			continue
		end
		
		for _, Status in ipairs(WCSUtility.GetAllStatusEffectsFromString(CharacterComponent.WCSCharacter, statusName)) do
			Status:Destroy()
			success += 1
		end
	end
	
	return `{ success } { statusName } statuses cleared.`
end