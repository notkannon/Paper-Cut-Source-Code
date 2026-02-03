local server = shared.Server
local client = shared.Client

local requirements = server
	and server._requirements
	or client._requirements

-- paths
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Animations = ReplicatedStorage.Assets.Animations.Locker
local MessagingEvent = script.Parent.Messaging

-- requirements
local Util = require(ReplicatedStorage.Shared.Util)

-- const
local Attributes = {
	ID = "Id",
	BROKEN = "Broken",
	LOCKED = "Locked",
	OCCUPANT_NAME = "Occupant",
	LAST_OCCUPANT_NAME = "LastOccupant"
}

-- nuh uh we need to rewrite this one..
-- TODO: put this function inside a character module
local function set_character_transparency(value: boolean, character: Model)
	for i,v in ipairs(character:GetDescendants()) do
		if v:IsA("BasePart") then
			if value then
				v:SetAttribute("OriginalTransparency", v.Transparency)
				v.Transparency = 1
			else
				v.Transparency = v:GetAttribute("OriginalTransparency")
				v:SetAttribute("OriginalTransparency", nil)
			end
		end
	end
end

-- BaseHideout initial
local Locker = {}
Locker._objects = {}
Locker.__index = Locker

-- constructor
function Locker.new( reference: Model )
	assert( reference, 'No locker instance provided' )
	assert( reference.PrimaryPart, 'locker has no .PrimaryPart linked' )
	assert( not requirements.HideoutService:GetHideoutByInstance(reference), `Attempt to dupplicate object for model { reference }` )
	
	local self = setmetatable({
		reference = reference,
		last_interaction = 0,
		anim_data = nil,
		cooldown = 0,
		sounds = nil,
		
		animations = {},
		action_history = {}, -- {[Player], "Hide" | "Leave"}
		connections = {
			attribute_changed = nil :: RBXScriptConnection,
		}
	}, Locker)
	
	table.insert(
		self._objects,
		self
	)
	
	self:Init()
	return self
end

-- initial object method
function Locker:Init()
	local PlayerComponent = server
		and requirements.ServerPlayer
		or requirements.ClientPlayer
	
	local connections = self.connections
	local reference: Model = self.reference
	local action_history = self.action_history
	local root_part: BasePart? = reference.PrimaryPart
	--local prompt: ProximityPrompt = reference.Root.Interaction.Enter
	
	-- attribute initial
	if server then
		reference:SetAttribute(Attributes.ID, Util.GetGUID())
		reference:SetAttribute(Attributes.BROKEN, false)
		reference:SetAttribute(Attributes.LOCKED, false)
		reference:SetAttribute(Attributes.OCCUPANT_NAME, "")
		reference:SetAttribute(Attributes.LAST_OCCUPANT_NAME, "")
		
	elseif client then
		-- assets initial
		self:LoadSounds()
		self:LoadAnimations()
		
		-- attribute connection
		connections.attribute_changed = reference.AttributeChanged:Connect(function(attribute)
			-- occupant changed handling
			if attribute == Attributes.OCCUPANT_NAME then			
				local FirstPersonModule = requirements.CharacterView
				local CameraComponent = requirements.Camera
				local ClientPlayer = requirements.ClientPlayer
				local Character = client.Player.Character
				
				-- occupant definition
				local last_occupant: Player? = self:GetLastOccupant()
				local occupant: Player? = self:GetOccupant()
				
				local wrapper = ClientPlayer.GetObjectFromInstance(occupant)
				if not wrapper then
					wrapper = ClientPlayer.GetObjectFromInstance(last_occupant)
				end
				
				-- player entered
				if occupant then
					self:PlayAnimation('Enter')
					self.sounds.enter:Play(.2)
					requirements.HideoutService.PlayerEntered:Fire( client.Player.Instance, self:GetId() )
					
				-- player left
				elseif last_occupant == client.Player.Instance then
					self.sounds.leave:Play(.5)
					self:PlayAnimation('Leave')
					requirements.HideoutService.PlayerLeft:Fire( client.Player.Instance, self:GetId() )
				end
				
			elseif attribute == Attributes.BROKEN then
				if self:IsBroken() then
					self:OnTeacherSearch( client.Player.Instance )
				end
			end
		end)
	end
end

-- handles player proximity input
function Locker:HandlePlayerInteraction( player: Player, interaction: string? )
	local HideoutService = requirements.HideoutService
	local PlayerComponent = server
		and requirements.ServerPlayer
		or requirements.ClientPlayer
	
	local wrapper = PlayerComponent.GetObjectFromInstance( player )
	local CharacterObject = wrapper.Character
	local character = CharacterObject.Instance
	local occupant: Player? = self:GetOccupant()
	
	if self:IsCooldowned()
		or self:IsBroken()
	then return end
	
	if not wrapper:IsKiller() then
		-- handling student interaction
		
		if interaction == 'leave' and player == occupant then
			-- player prompts to exit from locker
			--wrapper.Backpack:SetUsable(true)
			self:ApplyCooldown(1.5)
			self:SetOccupant(nil)
			
		elseif interaction == 'enter' then
			if occupant then return end
			if HideoutService:GetPlayerHideout( player ) then return end
			
			-- applying player to hideout
			self:ApplyCooldown(1.5)
			self:SetOccupant(player)
			wrapper.Backpack:UnequipAll()
			--wrapper.Backpack:SetUsable(false)-- TODO: make backpack usable in some cases
		end
	else
		-- handling teacher interaction
		-- teacher is checking locker
		if interaction == "search" then
			self:OnTeacherSearch( player )
		end
	end
end


function Locker:OnTeacherSearch(teacher: Player)
	local victim: Player? = self:GetOccupant()
	
	if client then -- client is getting called when attribute `Broken` is changed to true
		-- TODO:animations
		if victim then
			-- teacher found player 'victim'
		else
			-- teacher didnt found anyone
			
		end
	elseif server then
		-- TODO:logic
		if victim then
			print(`teacher "{teacher.Name}" found "{victim.Name}" in locker.`)
		else
			print(`teacher "{teacher.Name}" didnt found anyone in locker.`)
		end
		self:SetBroken(true) -- call client ^^^^
		self:SetOccupant(nil) -- remove student from locker BUT make this after client call, so client can get info about victim
		
	end
end

-- applying cooldown for door open/close interaction
function Locker:ApplyCooldown(duration: number)
	assert(type(duration) == 'number', `Unable to cast { duration } to number`)
	
	if duration then
		self.last_interaction = os.clock() + duration
		self.cooldown = duration
	else self.cooldown = 0
	end
end

-- GENERIC METHODS
-- getter methods
function Locker:GetId(): string 	  	return self:GetInstance():GetAttribute(Attributes.ID) end
function Locker:IsBroken(): boolean		return self:GetInstance():GetAttribute(Attributes.BROKEN) end
function Locker:GetInstance(): Model  	return self.reference end
function Locker:IsCooldowned(): boolean return os.clock() - self.last_interaction < self.cooldown end

-- returns player? if locker being occuped
function Locker:GetOccupant(): Player?
	local player_name: string = self:GetInstance():GetAttribute(Attributes.OCCUPANT_NAME)
	if not player_name then return end
	return game:GetService('Players'):FindFirstChild(player_name)
end

-- returns player? locker was occuped by
function Locker:GetLastOccupant(): Player?
	local player_name: string = self:GetInstance():GetAttribute(Attributes.LAST_OCCUPANT_NAME)
	if not player_name then return end
	return game:GetService('Players'):FindFirstChild(player_name)
end

-- returns last interactor and action
function Locker:GetLastInteractor()
	local action_history = self.action_history
	return action_history[ #action_history ]
		and action_history[ #action_history ][1]
end

-- setter methods
-- sets locker enabled/disabled to earn interactions
function Locker:SetLocked( value: boolean )
	assert(server, 'Attempt to call :SetLocked() on client')
	self:GetInstance():SetAttribute(Attributes.LOCKED, value)
end

function Locker:SetBroken( value: boolean )
	assert(server, 'Attempt to call :SetLocked() on client')
	self:GetInstance():SetAttribute(Attributes.BROKEN, value)
end

-- sets current and last occupant values
function Locker:SetOccupant( player: Player )
	assert(server, 'Attempt to call :SetOccupant() on client')
	
	-- attribute changing
	local current_occupant = self:GetOccupant()
	local last_occupant = self:GetLastOccupant()
	self:GetInstance():SetAttribute(Attributes.LAST_OCCUPANT_NAME, (current_occupant and current_occupant.Name) or self:GetInstance():GetAttribute(Attributes.LAST_OCCUPANT_NAME))
	self:GetInstance():SetAttribute(Attributes.OCCUPANT_NAME, player and player.Name or '')
	
	if player then
		-- service .PlayerEntered signal firing
		requirements.HideoutService.PlayerEntered:Fire( player, self:GetId() )
		
	elseif current_occupant then
		-- service .PlayerLeft signal firing
		requirements.HideoutService.PlayerLeft:Fire( current_occupant, self:GetId() )
	end
end

-- adds interaction for current locker
function Locker:SetInteractor( interactor: Player, action: string )
	assert(typeof(interactor) == 'Instance' and interactor:IsA('Player'), `Wrong player interactor provided ({ interactor })`)
	assert(action, 'No action provided')
	
	table.insert(self.action_history, {
		interactor,
		action
	})
end

-- loads all animations in locker
function Locker:LoadAnimations()
	assert(client, 'Attempt to call :LoadAnimations() on server')
	
	-- animation initial
	local animator: Animator = self:GetInstance()
		:FindFirstChildOfClass('AnimationController')
		:FindFirstChildOfClass('Animator')
	
	table.insert(self.animations, {'Enter', animator:LoadAnimation(Animations.LockerEnter), Animations.LockerEnter})
	table.insert(self.animations, {'Leave', animator:LoadAnimation(Animations.LockerLeave), Animations.LockerLeave})
	table.insert(self.animations, {'ClosedLoop', animator:LoadAnimation(Animations.LockerClosed), Animations.LockerClosed})
	table.insert(self.animations, {'UnlockedLoop', animator:LoadAnimation(Animations.LockerrUnlocked), Animations.LockerrUnlocked})
	
	-- shitcode
	for _, track: AnimationTrack in ipairs(self.animations) do
		track[2].Looped = (track[2].Name == 'Enter'or track[2].Name == 'Leave') and false
	end
end

-- loads all sounds in locker
function Locker:LoadSounds()
	assert(client, 'Attempt to call :LoadSounds() on server')
	
	-- sound copying
	self.sounds = {
		enter = game:GetService("SoundService").Master.Instances.Locker.Enter:Clone(),
		leave = game:GetService("SoundService").Master.Instances.Locker.Leave:Clone()}
	
	-- placing sounds into root part
	for i,v in pairs(self.sounds) do v.Parent = self:GetInstance().Root end
end

-- plays animation for locker
function Locker:PlayAnimation(name: string)
	assert(client, 'Attempt to call :PlayAnimation() on server')
	
	local tuple: AnimationTrack
	local animator: Animator = self:GetInstance()
		:FindFirstChildOfClass('AnimationController')
		:FindFirstChildOfClass('Animator')
	
	-- finding animation
	for _, animation in ipairs(self.animations) do
		if animation[1] ~= name then continue end
		tuple = animation
		break
	end
	
	-- removing already playing tracks
	for _, track: AnimationTrack in ipairs(animator:GetPlayingAnimationTracks()) do
		if track.Animation == tuple[3] then track:Stop() end
	end
	
	-- playback
	assert(tuple, `Could not find AnimationTrack in locker with name "{ name }"`)
	tuple[2]:Play()
end

-- destruction
function Locker:Destroy()
	for _, connection: RBXScriptConnection in ipairs(self.connections) do
		connection:Disconnect() -- remove connection
	end
	
	-- raw removing
	table.remove(
		self._objects,
		table.find(
			self._objects,
			self
		)
	)
	
	-- cleaning up
	self.reference:Destroy()
	setmetatable(self, nil)
	table.clear(self)
end

-- complete
return Locker