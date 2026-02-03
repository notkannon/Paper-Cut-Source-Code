local client = shared.Client

-- services
--

-- abstraction initials
local BaseTaunt = {}
BaseTaunt.__index = BaseTaunt
BaseTaunt._objects = {}

-- construct
-- abstraction class
-- Used to control client-sided taunt events easily and faster
-- DO NOT FORGET TO DESTROY AFTER COMPLETED!
function BaseTaunt.new( target_player_object, taunt_data )
	assert( target_player_object, 'No target PlayerObject provided' )
	assert( taunt_data, 'No taunt data provided' )
	
	local self = setmetatable({
		enum = taunt_data.enum,
		name = taunt_data.name,
		cost = taunt_data.cost,
		looped = taunt_data.looped,
		animation = taunt_data.animation,
		reference = taunt_data.reference,
		description = taunt_data.description,
		stuff = {},
		
		-- locked to overriding polls
		playing = false,
		connections = {},
		initial_data = taunt_data,
		player_object = target_player_object,
		raw_character = target_player_object.Character.Instance
	}, BaseTaunt)
	
	table.insert(
		self._objects,
		self
	)
	
	self:Init()
	return self
end


function BaseTaunt:Init()
	-- overridig some polls and polls
	for poll, val in pairs(self.initial_data) do
		
		-- keep from unpredictable behavior
		if poll == 'connections'
			or poll == 'Destroy'
			or poll == 'playing'
			or poll == 'initial_data'
			or poll == 'raw_character'
			or poll == 'player_object' then
			warn('Cannot override TAUNT poll:', poll)
			continue
		end
		
		-- overriding
		self[ poll ] = val
	end
end

-- methods that could be overriden
-- returns true if all of condition are true
function BaseTaunt:CanContinue(): boolean
	local CharacterObject = self.Player.Character
	if not CharacterObject then return end -- can`t continue without character :(
	
	local currentCharacter = CharacterObject.Instance
	if currentCharacter ~= self.raw_character then return end -- our character now is not one that has taunt played
	
	-- base check for available of taunt state
	return not CharacterObject:_isStateLockedToSet('Taunt')
end

function BaseTaunt:Play() warn(`Taunt { self.name } now playing!`) end
function BaseTaunt:Stop() warn(`Taunt { self.name } now stopped!`) end	

-- frame-update method (main)
function BaseTaunt:Update()
	if not self:CanContinue() then
		self:Destroy()
	end
end

-- appends stuff Instance to the table
function BaseTaunt:AddStuff( stuff: Instance, name: string? )
	assert( typeof(stuff) == 'Instance', 'Provided stuff is no Instance' )
	self.stuff[ name or stuff.Name ] = stuff
end

-- destroys all instances kept inside stuff table
function BaseTaunt:ClearStuff()
	for _, stuff in pairs(self.stuff) do
		if typeof(stuff) ~= 'Instance' then continue end
		stuff:Destroy()
	end
end

-- permanently destroys taunt object
function BaseTaunt:Destroy()
	print('Destroying taunt:', self.name)
	self:Stop()
	
	-- forbidding object for a class
	table.remove(
		self._objects,
		table.find(
			self._objects, 
			self
		)
	)
	
	-- connections dropping
	for _, connection: RBXScriptConnection in pairs(self.connections) do
		connection:Disconnect()
	end
	
	-- removing all polls from the object
	for poll: string?, val in pairs(self) do
		self[ poll ] = nil
	end
	
	-- unbinding meta-methods from current taunt object
	setmetatable(self, nil)
end

return BaseTaunt