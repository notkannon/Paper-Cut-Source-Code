local server = shared.Server
local requirements = server._requirements

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local PlayerActionType = Enums.PlayerActionType


-- ActionTracker initial
local ActionTracker = {}
ActionTracker._objects = {}
ActionTracker.__index = ActionTracker

-- constructor
function ActionTracker.new( player_object )
	local self = setmetatable({
		player_object = player_object,
		default_multiplier = 1,
		player_multiplier = 1,
		
		actions = {}, -- whitelisted actions for player (role-based)
		history = {
			-- {Type = PlayerActionType.., Data = ...},
			-- {Type = PlayerActionType.., Data = ...},
			-- {Type = PlayerActionType.., Data = ...},
			-- {Type = PlayerActionType.., Data = ...}, ...
		}, -- action history (further calcs)
	}, ActionTracker)
	
	table.insert(
		self._objects,
		self
	)
	
	return self
end

-- inits all actions for the tracker
function ActionTracker:Init()
	local PlayerObject = self:GetPlayerObject()
	local actions = self.actions

	-- role-based handling
	if PlayerObject:IsKiller() then
		-- teachers has different actions?
		table.insert(actions, PlayerActionType.Kills)
		table.insert(actions, PlayerActionType.Deaths)
		table.insert(actions, PlayerActionType.Assists)
		table.insert(actions, PlayerActionType.Rampage)
		table.insert(actions, PlayerActionType.SuccessQTEs)
	else
		-- students
		table.insert(actions, PlayerActionType.Deaths)
		table.insert(actions, PlayerActionType.Assists)
		table.insert(actions, PlayerActionType.SuccessQTEs)
		table.insert(actions, PlayerActionType.ThrowablesHits)
	end
end

-- returns current player_object
function ActionTracker:GetPlayerObject()
	return self.Player
end

-- returns true if has.
function ActionTracker:HasActionType(action_type: number)
	return table.find(self.actions, action_type)
end

-- registers new action for player (points award?)
function ActionTracker:Register(action_type: number, data)
	-- validation
	assert(self:HasActionType( action_type ),
		`Provided action type wasn't registered ({ action_type })`
	)
	
	-- action handling (registering)
	table.insert(self.history, {
		Timestamp = os.clock(),
		Type = action_type,
		Data = data,
	})
end

-- calcs whole points amoint whisch could be awarded to player
function ActionTracker:GetAwardsTable()
	local points = 0
	local history = self.history
	
	for _, a in ipairs(history) do
		print('ACTION:', a)
	end
end

-- object destruction
function ActionTracker:Destroy()
	table.remove(
		self._objects,
		table.find(
			self._objects,
			self
		)
	)
	
	-- raw removal
	setmetatable(self, nil)
	table.clear(self)
end

return ActionTracker