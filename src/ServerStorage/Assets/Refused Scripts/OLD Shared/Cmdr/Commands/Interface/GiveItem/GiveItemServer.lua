-- handler initial
return function(_, players: { Player }, item_enum)
	local server = shared.Server
	local ServerItems = server._requirements.ServerItems
	local PlayersModule = server._requirements.ServerPlayer
	
	-- getting player`s wrap object
	for _, player: Player in pairs(players) do
		local wrap = PlayersModule.GetObjectFromInstance(player)
		if not wrap then continue end
		
		-- item handling
		local item = ServerItems:NewItem( item_enum )
		wrap.Backpack:AddItem( item )
	end
	
	-- formatted output
	return `Item "{ item_enum }" was given for { #players } players.`
end