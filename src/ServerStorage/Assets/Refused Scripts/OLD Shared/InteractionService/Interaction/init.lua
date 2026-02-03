-- type
type InteractionCallback = {
	OnInit: <Interaction>(interaction: Interaction) -> nil,
	IsInteractableFor: <Interaction>(interaction: Interaction, player: Player) -> boolean?,
}

type InteractionConnections = {
	Destroyed: RBXScriptConnection,
	Triggered: RBXScriptConnection,
	PromptShown: RBXScriptConnection,
	PromptHidden: RBXScriptConnection,
	TriggerEnded: RBXScriptConnection,
	PromptButtonHoldBegan: RBXScriptConnection,
	PromptButtonHoldEnded: RBXScriptConnection,
}

-- side
local Server = shared.Server
local Client = shared.Client
local Shared = Server or Client
local Requirements = Shared._requirements

-- Requirements
local Signal = require(game.ReplicatedStorage.Package.Signal)
local PlayerComponent = require(game.ReplicatedStorage.Shared.Components.PlayerComponent)
local InteractionCallbacks = {}


-- Interaction initial
local Interaction = {}
Interaction._objects = {}
Interaction.__index = Interaction

-- constructor
function Interaction.new( reference: ProximityPrompt )
	-- assertation
	assert(typeof(reference) == 'Instance' and reference:IsA('ProximityPrompt'), `Wrong reference provided. ProximityPrompt expected, got { reference }`)
	assert(not Requirements.InteractionService:GetInteraction(reference), 'Attempted to create Interaction with same ProximityPrompt')
	
	-- initialization
	local self = setmetatable({
		reference = reference,
		
		Destroyed = Signal.new(),
		Triggered = Signal.new(),
		PromptShown = Signal.new(),
		PromptHidden = Signal.new(),
		TriggerEnded = Signal.new(),
		PromptButtonHoldBegan = Signal.new(),
		PromptButtonHoldEnded = Signal.new(),
		
		connections = {} :: InteractionConnections,
		_behavior_list = {} :: { InteractionCallback? }
	}, Interaction)
	
	-- getting all behavior modules from tags
	for _, Tag: string in ipairs(reference:GetTags()) do
		if InteractionCallbacks[Tag] then
			table.insert(
				self._behavior_list,
				InteractionCallbacks[Tag]
			)
		end
	end
	
	table.insert(self._objects, self)
	self:Init()
	return self
end

-- initial method
function Interaction:Init()
	local instance: ProximityPrompt = self:GetInstance()
	local connections: InteractionConnections = self.connections
	
	-- client signals
	if Client then
		
		-- check if prompt isnt available for current player (local)
		connections.PromptShown = instance.PromptShown:Connect(function(...)
			print('1')

			if not self:IsInteractableFor(Client.Player.Instance) then return end
			Requirements.InteractionService.InteractionShown:Fire(self, ...)
			self.PromptShown:Fire(...)
		end)

		connections.PromptHidden = instance.PromptHidden:Connect(function()
			print('1')
			Requirements.InteractionService.InteractionHidden:Fire(self)
			self.PromptHidden:Fire()
		end)
	end
	
	-- shared signals
	connections.Triggered = instance.Triggered:Connect(function(player: Player)
		if not self:IsInteractableFor(player) then return end -- wow
		Requirements.InteractionService.InteractionTriggered:Fire(self, player)
		self.Triggered:Fire( player )
	end)
	
	connections.TriggerEnded = instance.TriggerEnded:Connect(function(player: Player)
		if not self:IsInteractableFor(player) then return end
		Requirements.InteractionService.InteractionTriggerEnded:Fire(self, player)
		self.TriggerEnded:Fire( player )
	end)
	
	connections.PromptButtonHoldBegan = instance.PromptButtonHoldBegan:Connect(function(player: Player)
		if not self:IsInteractableFor(player) then return end
		Requirements.InteractionService.InteractionHoldBegan:Fire(self, player)
		self.PromptButtonHoldBegan:Fire( player )
	end)
	
	connections.PromptButtonHoldEnded = instance.PromptButtonHoldEnded:Connect(function(player: Player)
		if not self:IsInteractableFor(player) then return end
		Requirements.InteractionService.InteractionHoldEnded:Fire(self, player)
		self.PromptButtonHoldEnded:Fire( player )
	end)
	
	-- cleanup
	connections.Destroyed = instance.Destroying:Connect(function()
		self:Destroy()
	end)
	
	-- initiallizing every behavior
	for _, Callback in ipairs(self._behavior_list) do
		Callback.OnInit( self )
	end
end

-- returns ProximityPrompt instance
function Interaction:GetInstance(): ProximityPrompt
	return self.reference
end

-- @override
function Interaction:OnInit() warn(':OnInit() wasnt overriden') end

-- returns true if ALL of interaction behavior connected available for player to interact
function Interaction:IsInteractableFor(player: Player)
	local Interactable: boolean = true
	
	for _, Check: InteractionCallback in ipairs(self._behavior_list) do
		Interactable = Interactable and Check.IsInteractableFor(self, player)
	end
	
	return Interactable
end

-- object destruction
function Interaction:Destroy()
	for _, connection: RBXScriptConnection in pairs(self.connections) do
		connection:Disconnect() -- remove connection
	end
	
	-- trigger destroyed event
	self.Destroyed:Fire()
	
	-- signal destroying
	self.Destroyed:DisconnectAll()
	self.Triggered:DisconnectAll()
	self.PromptShown:DisconnectAll()
	self.PromptHidden:DisconnectAll()
	self.TriggerEnded:DisconnectAll()
	self.PromptButtonHoldBegan:DisconnectAll()
	self.PromptButtonHoldEnded:DisconnectAll()

	-- raw removing
	table.remove(Interaction._objects,
		table.find(Interaction._objects,
			self
		)
	)
	
	-- instance removal
	if self:GetInstance() then
		self:GetInstance():Destroy()
	end
	
	-- cleaning up
	setmetatable(self, nil)
	table.clear(self)
end


--// Callback collecting

for _, Module: ModuleScript in ipairs(script.Behavior:GetChildren()) do
	InteractionCallbacks[ Module.Name ] = require(Module)
end

return Interaction