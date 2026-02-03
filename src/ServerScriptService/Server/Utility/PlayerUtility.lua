--[[
	Responsible for (sanitizing) Player-related data
--]]

--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Types = require(ReplicatedStorage.Shared.Types)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ServerRemotes = require(ServerScriptService.Server.ServerRemotes)

--//Functions

local function GetPlayersExclude(player: Player)
	local List = {}
	
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player == player then
			continue
		end
		
		table.insert(List, Player)
	end
	
	return List
end

--local function GetPlayerCFrames(): { [Player]: CFrame? }
--	local CFrames = {}
	
--	for _, Player in ipairs(Players:GetPlayers()) do
--		if not Player.Character then
--			continue
--		end
		
--		local HumanoidRootPart = Player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
--		if not HumanoidRootPart then
--			continue
--		end
		
--		CFrames[Player] = HumanoidRootPart.CFrame
--	end
	
--	return CFrames
--end

--//Returner

return {
	GetPlayersExclude = GetPlayersExclude,
}