local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GlobalSettings = require(ReplicatedStorage.Shared.Data.GlobalSettings)
local WhitelistIDs = GlobalSettings.Cmdr.PassedUserIds

Players.PlayerAdded:Connect(function(player)
	if RunService:IsStudio() then
		return
	end
	
	if table.find(WhitelistIDs, player.UserId)
		or table.find(GlobalSettings.Whilelist, player.UserId)
		or GlobalSettings.TestersAllowed then
		
		return
	end
	
	player:Kick("Testing closed for a moment.\n\n Shop UI Reworking")
end)