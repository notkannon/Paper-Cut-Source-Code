-- service
local ProximityPromptService = game:GetService('ProximityPromptService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local MessagingEvent = script.Messaging

-- requirements
local Signal = require(game.ReplicatedStorage.Package.Signal)
local Interaction = require(script.Interaction)
local GlobalSettings = require(game.ReplicatedStorage.GlobalSettings)
local InteractionLabel = RunService:IsClient() and require(script.Labels.Interaction) or nil
local LabelProximity = RunService:IsClient() and require(script.Labels.Label) or nil

-- InteractionService initial
local Initialized = false
local InteractionService = {}
InteractionService.InteractionShown = Signal.new()
InteractionService.InteractionHidden = Signal.new()
InteractionService.InteractionHoldBegan = Signal.new()
InteractionService.InteractionHoldEnded = Signal.new()
InteractionService.InteractionTriggered = Signal.new()
InteractionService.InteractionTriggerEnded = Signal.new()

-- service initial method
function InteractionService:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true

	if RunService:IsClient() then

		-- client proximity prompt handling
		ProximityPromptService.PromptShown:Connect(function(instance)
			instance.Style = Enum.ProximityPromptStyle.Custom

			if instance:HasTag('Label') then
				-- creating UI wrap for label proximity prompt
				LabelProximity.new(instance)

			else
				-- creating client UI wrap for interaction
				local Interaction = InteractionService:GetInteraction(instance, true)
				if not Interaction:IsInteractableFor(game.Players.LocalPlayer) then return end
				InteractionLabel.new(Interaction)
			end
		end)

	elseif RunService:IsServer() then
		ProximityPromptService.PromptTriggered:Connect(function(instance, player)
			
			-- if proximity prompt is not registered as interaction
			if not InteractionService:GetInteraction(instance) then
				
				-- customly triggering proximity prompt
				local Interaction = InteractionService:GetInteraction(instance, true)
				if not Interaction:IsInteractableFor(player) then return end
				Interaction.Triggered:Fire( player )
			end
		end)
	end
end


-- returns table of whitelisted roles for peoximity prompt
--function InteractionService:GetWhitelistForInstance(proximity_prompt: ProximityPrompt)
--	local raw: string = proximity_prompt:GetAttribute('RoleWhitelist')
--	local whitelist = {}

--	-- parsing
--	if raw then
--		for _, role: string in ipairs(raw:split(',')) do
--			-- error if we found invalid role (save ourselves from unexpected behavior) (pass @Teacher as metatag)
--			assert(GlobalSettings.Roles[ role ] or role == '@Teacher', `Role "{ role }" doest't exists`)
--			table.insert(whitelist, role)
--		end
--	end

--	return whitelist
--end

-- returns Interaction object if exist, or creates new
function InteractionService:GetInteraction(proximity_prompt: ProximityPrompt, create_if_not_exists: boolean?)
	-- getting from valid objects
	for _, Interaction in ipairs(Interaction._objects) do
		if Interaction:GetInstance() ~= proximity_prompt then continue end
		return Interaction
	end

	-- passing if we shouldn`t create new
	if not create_if_not_exists then return end

	-- creating new Interaction
	return Interaction.new( proximity_prompt )
end

-- complete
return InteractionService