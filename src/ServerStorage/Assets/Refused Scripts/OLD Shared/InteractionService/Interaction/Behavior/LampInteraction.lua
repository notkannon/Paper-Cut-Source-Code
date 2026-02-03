--// Service

local ServerStorage = game:GetService('ServerStorage')
local RunService = game:GetService('RunService')
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

--// Imports

local HideoutService = require(game.ReplicatedStorage.Shared.HideoutService)
local PlayerComponent = require(game.ReplicatedStorage.Shared.Components.PlayerComponent)
local LampsHandler = IsServer and require(ServerStorage.Server.Instances.ServerLampsHandler) or nil


return {
	OnInit = function(Interaction)
		if IsServer then
			Interaction.Triggered:Connect(function(player: Player)
				LampsHandler:HandleInteraction(
					Interaction.reference.Parent.Parent, player
				)
			end)
		end
	end,

	IsInteractableFor = function(Interaction, Player: Player)
		return true
	end,
}