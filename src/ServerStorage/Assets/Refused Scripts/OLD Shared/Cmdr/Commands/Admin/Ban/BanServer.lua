-- handler initial
return function (_, players: { Player }, length: number, reason: string?)
	local BanService = require(game.ServerStorage.Server.BanService)
	
	-- ban prompt
	for _, player in ipairs(players) do
		BanService:BanUser(
			player.UserId,
			length * 86400,
			reason
		)
	end
	
	-- formatted output
	return `{ #players } players was banned for { length } days for reason: "{ reason }"`
end