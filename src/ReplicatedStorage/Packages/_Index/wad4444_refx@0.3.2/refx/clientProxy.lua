local utils = script.Parent.utilities
local client = require(script.Parent.client)
local entries = require(script.Parent.client.entries)
local logger = require(utils.logger)

local allowedIndexes = {
	"Configuration",
	"DisableLeakWarning",
	"IsDestroyed",
	"MaxLifetime",
	"DestroyOnLifecycleEnd",
	"DestroyOnEnd",
	"Destroyed",
}

return function(constructor, ...)
	logger.assert(client.IsInitialized(), `Cannot create an effect locally before client starts.`)

	local proxy = newproxy(true)
	local mt = getmetatable(proxy)

	local effect = setmetatable({}, constructor)
	effect:constructor(...)
	entries.processLocalEntry(effect)

	local reservedFunctions = {
		Destroy = function()
			logger.assert(not effect.IsDestroyed, "Cannot :Destroy() an effect proxy twice.")

			effect:Destroy()
			return proxy
		end,
	}

	function mt.__index(_self, index)
		if reservedFunctions[index] then
			return reservedFunctions[index]
		end
		logger.assert(
			not effect.IsDestroyed or table.find(allowedIndexes, index) ~= nil,
			`Cannot index {index} after effect has been destroyed.`
		)

		return effect[index]
	end

	function mt.__newindex(_self, index)
		logger.error(`Cannot override value of "{index}" from effect proxy!`)
	end

	mt.__metatable = {}

	return proxy
end
