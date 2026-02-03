local utils = script.Parent.utilities

local configuration = require(script.Parent.configuration)
local createIdGenerator = require(utils.idGenerator)
local logger = require(utils.logger)
local remotes = require(script.Parent.remotes)

local map = require(script.Parent.effectsMap)
local nextId = createIdGenerator()

local t = require(script.Parent.modules.t)

local Players = game:GetService("Players")

local allowedIndexes = {
	"Configuration",
	"DisableLeakWarning",
	"IsDestroyed",
	"MaxLifetime",
	"DestroyOnLifecycleEnd",
	"DestroyOnEnd",
	"Destroyed",
}

return function(ctorName, ...)
	local params = { ... }
	params[0] = ""

	local id = nextId()

	local proxy = newproxy(true)
	local mt = getmetatable(proxy)

	local constructor = map.get(ctorName)
	logger.assert(constructor ~= nil, `Cannot constructor Proxy for invalid effect.`)

	local initialized = false
	local destroyed = false
	local players: { Player } = {}

	local function omitSelf(...)
		local args = { ... }
		return table.unpack(args, args[1] == proxy and 2 or 1)
	end

	local reservedFunctions = {
		Start = function(...)
			local providedPlayers = omitSelf(...)

			logger.assert(
				t.optional(t.array(t.instance("Player")))(providedPlayers),
				"Provide a valid array of players to :Start()."
			)
			logger.assert(not initialized, "Cannot :Start() effect twice.")

			players = providedPlayers or Players:GetPlayers()
			initialized = true

			remotes.__refx_create:firePlayers(players, ctorName, id, params)
			return proxy
		end,
		GetPlayers = function()
			logger.assert(initialized, "Cannot :GetPlayers() before effect has initialized.")
			return players
		end,
		Destroy = function()
			logger.assert(not destroyed, "Cannot :Destroy() an effect proxy twice.")

			destroyed = true
			remotes.__refx_destroy:firePlayers(players, id)
			return proxy
		end,
	}

	local cachedSenders = {}
	function mt.__index(_self, index)
		if reservedFunctions[index] then
			return reservedFunctions[index]
		end

		logger.assert(initialized, `Cannot index {index} before effect has started.`)
		logger.assert(
			not destroyed or table.find(allowedIndexes, index) ~= nil,
			`Cannot index {index} after effect has been destroyed.`
		)

		if not cachedSenders[index] then
			cachedSenders[index] = function(...)
				local callArgs = { omitSelf(...) }
				callArgs[0] = "" -- If we assign index 0 then Roblox will treat this table as a map and arguments that come after 0 don't disappear.

				local config = configuration.GetConfig(constructor[index])
				if config.Unreliable == true then
					remotes.__refx_communicator_urel:firePlayers(players, id, index, callArgs)
					return
				end
				remotes.__refx_communicator_rel:firePlayers(players, id, index, callArgs)
			end
		end

		return cachedSenders[index]
	end

	function mt.__newindex(_self, index)
		logger.error(`Cannot override value of "{index}" from effect proxy!`)
	end

	function mt.__tostring()
		return ctorName
	end

	mt.__metatable = {}

	return proxy
end
