-- triggers when player see a prompt to enter in locker
local HideoutService = require(game.ReplicatedStorage.Shared.HideoutService)
local PlayerComponent = require(game.ReplicatedStorage.Shared.Components.PlayerComponent)

local RunService = game:GetService('RunService')
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

return {
	OnInit = function(Interaction)
		if IsServer then
			Interaction.Triggered:Connect(function(player: Player)
				local PlayerObject = PlayerComponent.GetObjectFromInstance(player)
				local Hideout = HideoutService:GetHideoutByInstance(Interaction.reference.Parent.Parent.Parent)
				
				-- prompting player to search other in locker
				if PlayerObject:IsKiller() then
					Hideout:HandlePlayerInteraction(player, 'search')
				else -- prompting player to hide
					local PlayerHideout = HideoutService:GetPlayerHideout(player)
					
					if not PlayerHideout then
						PlayerObject.Character.WcsCharacterObject:GetSkillFromString('Hide'):Start(Hideout)
					else PlayerObject.Character.WcsCharacterObject:GetSkillFromString('Hide'):Stop()
					end
				end
			end)
		end
	end,
	
	IsInteractableFor = function(Interaction, Player: Player)
		local PlauerObject = PlayerComponent.GetObjectFromInstance(Player)
		
		if IsClient and Player == game.Players.LocalPlayer then
			-- very useful, student could see "Hide", teacher - "Search"
			if PlauerObject:IsKiller() then
				Interaction.reference.ActionText = 'Search'
			else
				if not HideoutService:GetPlayerHideout(Player) then
					Interaction.reference.ActionText = 'Hide'
				else Interaction.reference.ActionText = 'Leave'
				end
			end
		end
		
		return true
	end,
}