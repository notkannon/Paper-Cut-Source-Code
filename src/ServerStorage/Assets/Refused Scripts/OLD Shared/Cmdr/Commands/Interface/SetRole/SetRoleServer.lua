-- handler initial
return function(_, players: { Player }, role)
	local server = shared.Server
	local PlayersModule = server._requirements.ServerPlayer
	
	-- getting player`s wrap object
	for _, player: Player in pairs(players) do
		local wrap = PlayersModule.GetObjectFromInstance(player)
		if not wrap then continue end
		
		-- role handling
		wrap:SetRole( role )
		wrap:Respawn()
	end
	
	-- formatted output
	return `Role "{ role }" was set for { #players } players.`
end