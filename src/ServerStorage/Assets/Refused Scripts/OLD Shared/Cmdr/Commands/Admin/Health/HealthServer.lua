return function (_, players, amount)
	for _, player: Player in pairs(players) do
		local character = player.Character
		if not character then continue end
		
		local humanoid: Humanoid = character:FindFirstChildOfClass('Humanoid')
		if not humanoid or humanoid.Health == 0 then continue end
		
		-- setting health
		humanoid.Health = amount
	end

	return ("Health changed for %d players."):format(#players)
end