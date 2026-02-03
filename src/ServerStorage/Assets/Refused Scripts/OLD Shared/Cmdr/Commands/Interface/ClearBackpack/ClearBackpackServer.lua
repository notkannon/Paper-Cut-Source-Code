-- handler complete
return function(_, players)
	local server = shared.Server
	local PlayersModule = server._requirements.ServerPlayer

	for _, player: Player in pairs(players) do
		-- getting player`s wrap object
		local wrap = PlayersModule.GetObjectFromInstance(player)
		if not wrap then continue end

		-- clearing backpack
		wrap.Backpack:Clear()
	end

	-- formatted output
	return ("Backpack cleared for %d players."):format(#players)
end
