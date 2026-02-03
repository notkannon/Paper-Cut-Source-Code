--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DefaultData = require(ReplicatedStorage.Shared.Data.DefaultPlayerData)

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)
local ServerProducer = RunService:IsServer() and require(ServerScriptService.Server.ServerProducer) or nil

--//Functions

-- we dont actually remove it, we return to default values
function RemoveDataField(Data: {[string]: unknown}, Field: string)
	print(Data, Field)
	local Split = Field:split(".")
	local DefaultOperatingData = DefaultData.Save
	
	while #Split > 1 do
		local Subfield = Split[1]
		Data = Data[Subfield]
		DefaultOperatingData = DefaultOperatingData[Subfield]
		table.remove(Split, 1)
	end

	local Subfield = Split[1]
	
	if Data[Subfield] then
		local Val = DefaultOperatingData[Subfield]
		Data[Subfield] = if typeof(Val) == "table" then TableKit.DeepCopy(Val) else Val -- copying tables so no reference bugs happen and change default data
	else
		warn("Field does not exist", Field)
	end
end

--//Returner

return function(context, Players: { Player }, StatsType: string)
	for _, Player in Players do
		local PlayerData = ServerProducer.getState().Data[Player.Name]
		if not PlayerData then
			return `No data found on {Player.Name}`
		end
		
		RemoveDataField(PlayerData.Save, StatsType)
		
		ServerProducer.SetPlayerData(Player.Name, PlayerData)
	end
end