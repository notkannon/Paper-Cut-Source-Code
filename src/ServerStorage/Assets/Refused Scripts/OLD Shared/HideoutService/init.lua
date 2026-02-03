local server = shared.Server
local client = shared.Client

-- declarations
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local CollectionService = game:GetService('CollectionService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local MessagingEvent = script.Messaging

-- requirements
local Locker = require(script.Locker)
local Signal = require(ReplicatedStorage.Package.Signal)
local PlayerComponent = require(ReplicatedStorage.Shared.Components.PlayerComponent)


-- HideoutService initial
local Initialized = false
local HideoutService = {}
HideoutService.hideouts = Locker._objects
HideoutService.PlayerEntered = Signal.new() -- Player<Player>, HideoutID<string>
HideoutService.PlayerLeft = Signal.new() -- Player<Player>, HideoutID<string>

-- service initial method
function HideoutService:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	for _, instance in ipairs(CollectionService:GetTagged('Locker')) do
		HideoutService:NewHideout(instance)
	end
end

-- returns 1st hideout object with same id
function HideoutService:GetHideoutById( id: string )
	for _, locker_obj in ipairs(HideoutService.hideouts) do
		if locker_obj:GetId() ~= id then continue end
		return locker_obj
	end
end

-- returns 1st hideout object with same instance
function HideoutService:GetHideoutByInstance( instance: Instance )
	for _, locker_obj in ipairs(HideoutService.hideouts) do
		if locker_obj:GetInstance() ~= instance then continue end
		return locker_obj
	end
end

-- returns hideout object if player occuped it
function HideoutService:GetPlayerHideout( player: Player )
	for _, locker_obj in ipairs(HideoutService.hideouts) do
		if locker_obj:GetOccupant() ~= player then continue end
		return locker_obj
	end
end

-- initialize new hideout from instance (by tags)
function HideoutService:NewHideout( reference: Model )
	if reference:HasTag('Locker') then
		-- locker class
		return Locker.new( reference )
	end
end

-- requests server to player leave current locker
function HideoutService:PromptClientLeave()
	assert(client, 'Attempted to call :PromptClientLeave() on server')
	MessagingEvent:FireServer(nil, 'leave')
end

-- MESSAGING
if client then
	MessagingEvent.OnClientEvent:Connect(function( id: string, ctx: string, ... )
		-- client code
	end)
elseif server then
	--[[ handling player`s status effects
	HideoutService.PlayerEntered:Connect(function(player: Player, hideout_id: string)
		local PlayerObject = PlayerComponent.GetObjectFromInstance(player)
		if not PlayerObject then return end
		
		-- applying "hidden" status effect
		local WcsCharacter = PlayerObject.Character.WcsCharacterObject
		local AppliedStatuses = WcsCharacter:GetAllActiveStatusEffectsOfType(HiddenStatusEffect)
		
		assert(#AppliedStatuses == 0, 'Player already has "Hidden" status effect applied: ', player.Name)
		WcsCharacter:GetAllStatusEffectsOfType( HiddenStatusEffect )[ 1 ]:Start()
	end)
	
	-- handling player`s status effects
	HideoutService.PlayerLeft:Connect(function(player: Player, hideout_id: string)
		local PlayerObject = PlayerComponent.GetObjectFromInstance(player)
		if not PlayerObject then return end
		
		-- applying "hidden" status effect
		local WcsCharacter = PlayerObject.Character.WcsCharacterObject
		local AppliedStatuses = WcsCharacter:GetAllActiveStatusEffectsOfType(HiddenStatusEffect)
		
		-- removing "hidden" status effect
		if #AppliedStatuses > 0 then
			AppliedStatuses[ 1 ]:Stop()
		end
	end)]]
	
	-- server messaging handling
	MessagingEvent.OnServerEvent:Connect(function( player: Player, id: string, ctx: string, ... )
		-- server code
		if not id then
			if ctx == 'leave' then
				local Hideout = HideoutService:GetPlayerHideout(player)
				if not Hideout then return end
				
				-- prompting locker object to remove current occupant
				Hideout:HandlePlayerInteraction(player, 'leave')
			end
		end
	end)
end

-- complete
return HideoutService