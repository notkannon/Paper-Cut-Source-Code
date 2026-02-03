--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local ServerProducer = RunService:IsServer() and require(ServerScriptService.Server.ServerProducer) or nil
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil
local Characters = require(ReplicatedStorage.Shared.Data.Characters)

--//Returner

return function(_, players: { Player }, characterName: "None" | string, skinName: "None" | "Default" | string?)
	
	if skinName == nil then
		skinName = "Default"
	end
	
	if characterName == nil then
		characterName = "None"
	end
	
	--filtering names (if None then empty string)
	skinName = (skinName == "None" and "") or skinName
	characterName = (characterName == "None" and "") or characterName

	for _, Player: Player in ipairs(players) do

		local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(Player)
		
		if not PlayerComponent then
			continue
		end
		
		warn(characterName, skinName)
		
		local intendedRole
		
		if characterName == "" then
			intendedRole = "Spectator" -- edge case для спектатора
		else
			-- если не указано, какая роль должна быть, считаем, что это выживший и просто закидываем его в рандомный класс выживших
			-- ура тех. долг 🗣🔥
			local AvailableClasses = {"Stealther", "Medic", "Troublemaker", "Runner"}
			intendedRole = Characters[characterName].IntendedRole or AvailableClasses[math.random(1, #AvailableClasses)]
		end
		
		--respawning player
		PlayerComponent.Janitor:Add(
			
			task.spawn(function()
				
				--updating mock data
				ServerProducer.SetMockData(Player.Name, "MockSkin", skinName)
				ServerProducer.SetMockData(Player.Name, "MockCharacter", characterName)
				print(skinName, characterName)
				
				PlayerComponent:SetRole(intendedRole)
				PlayerComponent:ApplyRoleConfig(true)
			end)
		)
	end

	return `Config was applied for { #players } players`
end