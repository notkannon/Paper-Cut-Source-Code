--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)
local Characters = RunService:IsServer() and require(ReplicatedStorage.Shared.Data.Characters) or nil
local ServerProducer = RunService:IsServer() and require(ServerScriptService.Server.ServerProducer) or nil
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil

--//Returner

return function(_, players: { Player }, characterName: "None" | string, skinName: "None" | "Default" | string?)
	if skinName == nil then skinName = "Default" end
	warn(characterName, skinName)
	
	--filtering names (if None then empty string)
	characterName = (characterName == "None" and "") or characterName
	skinName = (skinName == "None" and "") or skinName
	
	for _, Player: Player in pairs(players) do
		
		--updating mock data
		ServerProducer.SetMockData(Player.Name, "MockCharacter", characterName)
		ServerProducer.SetMockData(Player.Name, "MockSkin", skinName)
	end

	return `Character { characterName } with skin { skinName } was set as equipped for { #players } players`
end