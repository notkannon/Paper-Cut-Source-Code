-- declarations
local replicatedStorage = game:GetService('ReplicatedStorage')
local serverStorage = game:GetService('ServerStorage')
local playerService = game:GetService('Players')
local runService = game:GetService('RunService')

-- vars
local LoadRequest = replicatedStorage.Shared.Network.LoadRequest

-- private fields
local private = {
	requirements = {}
}

-- initial
local Server = {}
shared.Server = Server
Server._requirements = {}

-- requires provided module and puts it inside with name?
function Server:Require(reference: ModuleScript, name: string?)
	local source = require(reference)

	if Server._requirements[name or reference.Name] then
		warn(`Attempted to override requirement "{ name or reference.Name }".`)
		return
	end

	Server._requirements[name or reference.Name] = source
	table.insert(private.requirements, source)
	return Server._requirements[name or reference.Name]
end

-- full server initialize function
local function ServerInitialize()
	Server:Require(serverStorage.Server.ServerPlayer)
	Server:Require(replicatedStorage.Shared.InteractionService)
	Server:Require(replicatedStorage.Shared.TauntService)
	Server:Require(replicatedStorage.Shared.GameService)
	Server:Require(replicatedStorage.Shared.QTEService)
	Server:Require(serverStorage.Server.BanService)
	Server:Require(serverStorage.Server.MonetizationService)
	Server:Require(replicatedStorage.Shared.DoorsService)
	Server:Require(replicatedStorage.Shared.HideoutService)
	Server:Require(serverStorage.Server.Instances.ServerItems)
	Server:Require(replicatedStorage.Shared.Cmdr.Initial)
	
	-- initialization of all required modules
	for _, source in ipairs(private.requirements) do
		if not source.Init then continue end
		if source.construct then continue end
		if source.new then continue end
		
		-- package validation?
		local SourceName: string = 'Unknown'
		for b, a in pairs(Server._requirements) do
			if a == source then
				SourceName = b
			end
		end

		-- already initialized check
		if source._Initialized then
			warn(`[Server] { SourceName }: Already initialized`)
		end

		-- safe call
		local Inited, Traceback = pcall(function() source:Init() end)
		if not Inited then warn(`[Server] { SourceName }: Initialization failed: { Traceback }`) end
	end
	
	-- declarations
	local Enums = require(replicatedStorage.Enums)
	local ServerPlayer = Server._requirements.ServerPlayer -- понеслась
	
	--// REMOTES
	-- player initialization handler
	LoadRequest.OnServerEvent:Connect(function(player: Player)
		if ServerPlayer.GetObjectFromInstance( player ) then
			player:Kick('Already registered player object with same player')
			return
		end

		-- initializing new player wrap
		local PlayerObject = ServerPlayer.new(player)

		-- kick if still not found it
		if not PlayerObject then
			player:Kick('Something went wrong. Please, try to rejoin. If you keep getting this message contact us in our Discord community server!')
			return
		end

		-- player in menu currently
		PlayerObject:SetRole(Enums.GameRolesEnum.Student)
		PlayerObject:Respawn()
	end)
end

-- server initialized
ServerInitialize()
print(`Server inited. { #private.requirements } modules indexed.`)