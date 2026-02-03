-- handler complete
return function(_, players)
	local server = shared.Server
	local PlayersModule = server._requirements.ServerPlayer

	for _, player: Player in pairs(players) do
		-- getting player`s wrap object
		local wrap = PlayersModule.GetObjectFromInstance(player)
		if not wrap then continue end
		
		-- call wrap :Respawn() method
		wrap:Respawn()
	end
	
	-- formatted output
	return ("Respawned %d players."):format(#players)
end
