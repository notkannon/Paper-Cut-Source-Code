return function(_, players)
	
	local ComponentsManager = require(game.ReplicatedStorage.Shared.Classes.ComponentsManager)
	
	for _, Player: Player in pairs(players) do
		
		local PlayerComponent = ComponentsManager.Get(Player, "PlayerComponent")
		
		if not PlayerComponent then
			continue
		end
		
		PlayerComponent.Janitor:Add(
			task.spawn(
				PlayerComponent.Respawn,
				PlayerComponent
			)
		)
	end
	
	return ("Respawned %d players."):format(#players)
end