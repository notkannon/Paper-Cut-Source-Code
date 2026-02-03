return function (_, players, reason: string)
	reason = reason or 'No reason.'
	
	for _, player in pairs(players) do
		player:Kick( reason )
	end

	return ("Kicked %d players."):format(#players)
end