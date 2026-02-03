-- global vars
local server = shared.Server

local requirements = server._requirements
local PlayerComponent = requirements.ServerPlayer

local Gamepass = {}
Gamepass.asset = 825125726

function Gamepass:Handle( player: Player )
	--[[ this function will run every time when player will:
		1. Spawn and they have this gamepass
		2. Call from server (maybe if boolean in data is true then call it?)
		3. They bought this gamepass
	]]
	
	-- here you can make your callback whenever player gets it from this ^^^
	local wrapper = PlayerComponent.GetObjectFromInstance( player )
	wrapper.Backpack:SetMaxItems(9)
end

return Gamepass