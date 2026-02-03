--// Service

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

--// Imports

local DoorsService = require(ReplicatedStorage.Shared.DoorsService)
local PlayerComponent = require(game.ReplicatedStorage.Shared.Components.PlayerComponent)


return {
	OnInit = function(Interaction)
		Interaction.Triggered:Connect(function(player: Player)
			local Door = DoorsService:GetDoorByInstance(Interaction.reference.Parent.Parent.Parent)
			
			if IsServer then
				Door:HandlePlayerInteraction(player)
				
			elseif IsClient then
				Interaction.reference.ActionText = not Door:IsOpened() and 'Close' or 'Open'
			end
		end)
	end,

	IsInteractableFor = function(Interaction, Player: Player)
		return true
	end,
}