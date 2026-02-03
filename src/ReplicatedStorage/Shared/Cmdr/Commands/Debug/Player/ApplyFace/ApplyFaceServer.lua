--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Enums = require(ReplicatedStorage.Shared.Enums)

--//Imports

local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local FaceExpressionsEnum = Enums.FaceExpression

--//Returner

return function(_, players: { Player }, face: string, duration: number)
	
	local Success = 0

	for _, Player: Player in pairs(players) do

		if not Player.Character or not Player.Character:FindFirstChild("Face") then
			continue
		end
		
		local FacialExpressionComponent = ComponentsManager.Get(Player.Character.Face, "FacialExpression")
		
		if not FacialExpressionComponent then
			continue
		end
		

		FacialExpressionComponent:AddFace(FaceExpressionsEnum[face], duration)
		Success += 1
	end

	return `Face "{ face }" was set for { Success } players`
end