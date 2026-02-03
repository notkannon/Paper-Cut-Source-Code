--[[TODO:
So, we could use this service to handle player`s prompts to play taunts both client/server and purchasing them
]]

local server = shared.Server
local client = shared.Client
local requirements = server
	and server._requirements
	or client._requirements

-- declarations
local RunService = game:GetService('RunService')
local tauntInstances = script.BaseTaunt:GetChildren()
local TauntsReplica

-- requirements
local enumsModule = requirements.Enums
local BaseTaunt = require(script.BaseTaunt)


-- service initial
local Initialized = false
local TauntService = {}
TauntService._taunts = {}
TauntService._player_state = {}
TauntService.local_player_active = false


function TauntService:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	-- initing every taunt
	for _, taunt: ModuleScript in ipairs( tauntInstances ) do
		local taunt_data = require( taunt )
		
		assert( not self:GetTauntByEnum(taunt_data.enum), `Taunt with enum "{ taunt_data.enum }" already registered` )
		assert( not self:GetTauntByName(taunt_data.name), `Taunt with name "{ taunt_data.name }" already registered` )
		
		table.insert(self._taunts, taunt_data)
	end
	
	-- replica connections
	if client then
		--[[TauntsReplica:ListenToNewKey('', function( taunt_enum, player_key )
			local player: Player? = self:GetPlayerByKey(player_key)
			self:PlayTaunt( taunt_enum, player )
			
			-- listening to new taunt play/taunt removing of the player
			TauntsReplica:ListenToChange( player_key, function( old_taunt, new_taunt )
				if not new_taunt then
					self:ClearTauntsForPlayer( player )
				else self:PlayTaunt( new_taunt, player ) end
			end)
		end)]]
		
		client._requirements.UI.gameplay_ui.taunts_ui:Init()
		for _i, slot in ipairs(client._requirements.UI.gameplay_ui.taunts_ui.slots) do
			slot:SetTaunt( self:GetTauntByEnum(_i+6) )
		end
		
		--[[TauntsReplica:ConnectOnClientEvent(function()
			--
		end)]]
	elseif server then
		--[[TauntsReplica:ConnectOnServerEvent(function(player: Player, taunt_id: number, playing: boolean)
			
		end)]]
	end
end


function TauntService:GetPlayerObjectByPlayer( player: Player )
	if client then
		local playerObject = requirements.PlayerComponent.GetObjectFromInstance( player )
		return playerObject
		--[[if not playerObject then return end
		
		local characterObject = playerObject.Character
		return characterObject]]
		
	elseif server then
		local playerObject = requirements.ServerPlayer.GetObjectFromInstance( player )
		return playerObject
		--[[if not playerObject then return end

		local characterObject = playerObject.Character
		return characterObject]]
	end
end


function TauntService:GetPlayerByKey( player_key: string )
	for _, player: Player in ipairs(game.Players:GetPlayers()) do
		if player.Name ~= player_key then continue end
		return player
	end
end


function TauntService:GetTauntByEnum( taunt_enum: number )
	for _, taunt in ipairs(self._taunts) do
		if taunt.enum ~= taunt_enum then continue end
		return taunt
	end
end


function TauntService:GetTauntByName( taunt_name: string )
	for _, taunt in ipairs(self._taunts) do
		if taunt.name ~= taunt_name then continue end
		return taunt
	end
end

-- returns a taunt object from provided player object
function TauntService:GetPlayerActiveTaunt( player_object )
	for _, taunt_object in ipairs(BaseTaunt._objects) do
		if taunt_object.Player ~= player_object then continue end
		return taunt_object
	end
end


function TauntService:PlayTaunt( taunt_enum: number, player: Player? )
	local taunt = self:GetTauntByEnum( taunt_enum )
	assert( taunt, `No taunt with provided enum { taunt_enum } exists` )
	
	if client then
		
		-- SHOULD BE CALLED WITHOUT player ARG. It could cancel function if will be passed local player instance
		if player == client.Player.Instance then return
		elseif player then return -- some code to init taunt visual to other player
		end
		
		local client_character = client.local_character
		
		-- some checks
		if client_character:_isStateLockedToSet('Taunt') then
			warn('Unable to play taunt.')
			return
		end
		
		-- getting player object and providing it to the taunt worker object to start itself
		local player_object = self:GetPlayerObjectByPlayer( player )
		local active_taunt = self:GetPlayerActiveTaunt( player_object )
		
		-- removing old taunt (if exists)
		if active_taunt then
			warn('Stopping taunt because new is required:', active_taunt.name)
			active_taunt:Destroy()
		end
		
		-- creating a new taunt object and running it
		local taunt_worker = BaseTaunt.new( player_object, taunt )
		taunt_worker:Play()
		
	elseif server then
		assert( player, 'No player instance provided' )
		-- some server code that handles player`s taunt to other players
	end
end


function TauntService:ClearTauntsForPlayer( player: Player? )
	local current_taunt = self._player_state[ player.Name ]
	if not current_taunt then return end
	
	-- getting character object and providing it to taunt object to stop itself (if playing?)
	local taunt = self:GetTauntByEnum( current_taunt )
	local player_object = self:GetPlayerObjectByPlayer( player )
	--TODO: make a getter that returns current player`s taunt object
	--taunt:CleanupForCharacter( CharacterObject )
end

-- NETWORKING / UPDATING
if client then
	local ReplicaController = require(game.ReplicatedStorage.Package.ReplicaService.ReplicaController)
	-- some client replica code handling
	
	--[[ Replica connection
	ReplicaController.ReplicaOfClassCreated('Taunts', function( TauntsReplicaObject )
		TauntsReplica = TauntsReplicaObject

		-- client taunts initialiation
		TauntService:Init()
	end)]]
	
	--[[ client taunt objects frame update listener
	RunService:BindToRenderStep('@taunts_listener', Enum.RenderPriority.Character.Value, function()
		for _, taunt_object in ipairs(BaseTaunt._objects) do
			taunt_object:Update()
		end
	end)]]
	
elseif server then
	local ReplicaService = require(game.ServerStorage.Server.ReplicaService)
	--[[ some server replica code handling
	
	TauntsReplica = ReplicaService.NewReplica({
		ClassToken = ReplicaService.NewClassToken('Taunts'),
		Data = TauntService._player_state,
		Replication = 'All'
	})]]
end

return TauntService