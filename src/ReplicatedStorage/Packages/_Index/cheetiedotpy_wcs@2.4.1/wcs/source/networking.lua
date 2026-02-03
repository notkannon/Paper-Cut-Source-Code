-- Compiled with roblox-ts v3.0.0
local TS = require(script.Parent.Parent.include.RuntimeLib)
local t = TS.import(script, script.Parent.Parent, "include", "node_modules", "@rbxts", "t", "lib", "ts").t
local Networking = TS.import(script, script.Parent.Parent, "include", "node_modules", "@flamework", "networking", "out").Networking
local GlobalFunctions = Networking.createFunction("@rbxts/wcs:source/networking@GlobalFunctions")
local ServerFunctions = GlobalFunctions:createServer({}, {
	incomingIds = { "messageToServer" },
	incoming = {
		messageToServer = { { t.interface({
			buffer = t.typeof("buffer"),
			blobs = t.array(t.any),
		}) }, nil },
	},
	outgoingIds = { "messageToClient" },
	outgoing = {
		messageToClient = t.union(t.any, t.none),
	},
	namespaceIds = {},
	namespaces = {},
})
local ClientFunctions = GlobalFunctions:createClient({}, {
	incomingIds = { "messageToClient" },
	incoming = {
		messageToClient = { { t.interface({
			buffer = t.typeof("buffer"),
			blobs = t.array(t.any),
		}) }, nil },
	},
	outgoingIds = { "messageToServer" },
	outgoing = {
		messageToServer = t.union(t.any, t.none),
	},
	namespaceIds = {},
	namespaces = {},
})
local GlobalEvents = Networking.createEvent("@rbxts/wcs:source/networking@GlobalEvents")
local ServerEvents = GlobalEvents:createServer({}, {
	incomingIds = { "messageToServer", "start", "requestSkill", "messageToServer_urel" },
	incoming = {
		messageToServer = { { t.interface({
			buffer = t.typeof("buffer"),
			blobs = t.array(t.any),
		}) }, nil },
		start = { {}, nil },
		requestSkill = { { t.interface({
			buffer = t.typeof("buffer"),
			blobs = t.array(t.any),
		}) }, nil },
		messageToServer_urel = { { t.interface({
			buffer = t.typeof("buffer"),
			blobs = t.array(t.any),
		}) }, nil },
	},
	incomingUnreliable = {
		messageToServer_urel = true,
	},
	outgoingIds = { "messageToClient", "sync", "messageToClient_urel", "damageTaken", "damageDealt" },
	outgoingUnreliable = {
		messageToClient_urel = true,
	},
	namespaceIds = {},
	namespaces = {},
})
local ClientEvents = GlobalEvents:createClient({}, {
	incomingIds = { "messageToClient", "sync", "messageToClient_urel", "damageTaken", "damageDealt" },
	incoming = {
		messageToClient = { { t.interface({
			buffer = t.typeof("buffer"),
			blobs = t.array(t.any),
		}) }, nil },
		sync = { { t.interface({
			buffer = t.typeof("buffer"),
			blobs = t.array(t.any),
		}) }, nil },
		messageToClient_urel = { { t.interface({
			buffer = t.typeof("buffer"),
			blobs = t.array(t.any),
		}) }, nil },
		damageTaken = { { t.number }, nil },
		damageDealt = { { t.string, t.literal("Skill", "Status"), t.number }, nil },
	},
	incomingUnreliable = {
		messageToClient_urel = true,
	},
	outgoingIds = { "messageToServer", "start", "requestSkill", "messageToServer_urel" },
	outgoingUnreliable = {
		messageToServer_urel = true,
	},
	namespaceIds = {},
	namespaces = {},
})
return {
	GlobalFunctions = GlobalFunctions,
	ServerFunctions = ServerFunctions,
	ClientFunctions = ClientFunctions,
	GlobalEvents = GlobalEvents,
	ServerEvents = ServerEvents,
	ClientEvents = ClientEvents,
}
