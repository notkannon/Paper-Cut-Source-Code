local server = shared.Server
local client = shared.Client

local requirements = server
	and server._requirements
	or client._requirements

return function()
	-- a function to cleanup tool when destroyinh/unequipping (both client or server)
	if client then
		-- client cleanup
	elseif server then
		-- server cleanup
	end
end