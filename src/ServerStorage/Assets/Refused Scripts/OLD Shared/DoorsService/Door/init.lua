local server = shared.Server
local client = shared.Client

local requirements = server
	and server._requirements
	or client._requirements

local MessagingEvent = script.Parent.Messaging

-- requirements
local Util = require(game.ReplicatedStorage.Shared.Util)
local SingleDoorAnimate = require(script.AnimateDoor)
local DoubleDoorAnimate = require(script.AnimateDoubleDoor)

local PlayerComponent = server
	and requirements.ServerPlayer
	or requirements.PlayerComponent

-- const
local Attributes = {
	ID = "Id",
	IMMUNE = "Immune",
	BROKEN = "Broken",
	OPENED = "Opened",
	HEALTH = "DoorHealth",
	SLAMMED = 'Slammed',
	HITDIRECTION = "HitDirection"
}

-- Door initial
local Door = {}
Door._objects = {}
Door.__index = Door

-- type
type DoorConnections = {
	attribute_changed: RBXScriptConnection
}

-- constructor
function Door.new( reference: Model )
	-- ассерты тут и вся хуйня
	assert( reference, 'No door instance provided' )
	assert( reference.PrimaryPart, 'Door has no .PrimaryPart linked:', reference )
	assert( reference:FindFirstChild('Hinge'), 'Door has no Hinge instance inside' )	

	local self = setmetatable({
		reference = reference,
		last_interaction = 0,
		anim_data = nil,
		cooldown = 0,

		action_history = {}, -- {[Player], "Slam" | "Open" | "Break" | "Damage" | "Close"}
		connections = {} :: DoorConnections
	}, Door)
	
	table.insert(
		Door._objects,
		self
	)
	
	self:Init()
	return self
end

-- initial method
function Door:Init()
	local connections = self.connections
	local action_history = self.action_history
	local reference: Model = self:GetInstance()
	local root_part: BasePart = reference.PrimaryPart

	if not PlayerComponent then
		PlayerComponent = server
			and requirements.ServerPlayer
			or requirements.PlayerComponent
	end

	-- attribute initial
	if server then
		reference:SetAttribute(Attributes.HEALTH, 100)
		reference:SetAttribute(Attributes.IMMUNE, false) -- door can`t be damaged, opened, locked and etc
		reference:SetAttribute(Attributes.OPENED, false)
		reference:SetAttribute(Attributes.BROKEN, false)
		reference:SetAttribute(Attributes.SLAMMED, false)
		reference:SetAttribute(Attributes.ID, Util.GetGUID())
		reference:SetAttribute(Attributes.HITDIRECTION, "Front")
	end

	-- animation init
	if client then
		self:LoadSounds()

		-- getting animation data for a door
		if reference:HasTag('Double') then
			self.Animate = DoubleDoorAnimate.Animate
			self.AnimateSlam = DoubleDoorAnimate.AnimateSlam
			self.AnimateDamage = DoubleDoorAnimate.AnimateDamage
			self.AnimateBreak = DoubleDoorAnimate.AnimateBreak
			self.anim_data = DoubleDoorAnimate.GetInitialData(reference)
		else
			self.Animate = SingleDoorAnimate.Animate
			self.AnimateSlam = SingleDoorAnimate.AnimateSlam
			self.AnimateDamage = SingleDoorAnimate.AnimateDamage
			self.AnimateBreak = SingleDoorAnimate.AnimateBreak
			self.anim_data = SingleDoorAnimate.GetInitialData(reference)
		end

		local Lasthealth = 100

		-- connections
		connections.attribute_changed = reference.AttributeChanged:Connect(function( attribute: string )
			if attribute == Attributes.HEALTH then
				local NewHealth = self:GetHealth()
				local Delta = Lasthealth - NewHealth
				Lasthealth = NewHealth

				-- was damaged
				if Delta > 0 then
					self:AnimateDamage()
				end

			elseif attribute == Attributes.BROKEN then
				self:AnimateBreak()
				self:SetCanCollide( false )
				
			elseif attribute == Attributes.OPENED then
				-- door animate
				self:SetCanCollide( not self:GetInstance().Root.CanCollide )
				self:Animate( false )
			end
		end)
	end
end

-- returns "Front"/"Back" from character facing door
function Door:GetOpenDirectionFromPosition( position: Vector3 ): string
	-- make it from dot product
	local door_front_normal = self.reference.Root.CFrame.LookVector
	local door_to_position = (position - self.reference.Root.Position).Unit
	local dot = door_front_normal:Dot(door_to_position)

	return dot > 0 and 'Front' or 'Back'
end

-- applying cooldown for door open/close interaction
function Door:ApplyCooldown(duration: number)
	assert(type(duration) == 'number', `Unable to cast { duration } to number`)

	if duration then
		self.last_interaction = os.clock() + duration
		self.cooldown = duration
	else self.cooldown = 0
	end
end

-- handles player proximity input
function Door:HandlePlayerInteraction( player_obj: Player )
	local wrapper = PlayerComponent.GetObjectFromInstance( player_obj )
	local CharacterObject = wrapper.Character
	local character_model = CharacterObject.Instance

	local Direction = self:GetOpenDirectionFromPosition(
		CharacterObject:GetPosition()
	)

	self:SetForceDir(Direction)
	self:Push( player_obj, true, Direction == "Front" )
end

-- damages door
function Door:TakeDamage(player: Player, amount: number)
	assert(server, 'Attempt to call :TakeDamage() on client')

	if self:IsOpened() then return end
	if self:IsImmuned() then return end -- is door immuned?
	if self:IsBroken() then return end

	local wrapper = PlayerComponent.GetObjectFromInstance( player )
	local CharacterObject = wrapper.Character
	local character_model = CharacterObject.Instance

	local Direction = self:GetOpenDirectionFromPosition(
		CharacterObject:GetPosition()
	)

	self:SetForceDir(Direction)
	self:SetInteractor(player, "Damage")
	self:SetHealth(self:GetHealth() - amount)

	-- Door breaking
	if self:GetHealth() == 0 then
		local Model = self:GetInstance()
		Model.Hinge.CollisionGroup = "Door"
		
		self:SetForceDir(Direction)
		self:SetBroken(true, player)
		
	else -- open on hit?
		self:Push( player )
	end
	-- TODO: REWORK
	--[[if client then
		MessagingEvent:FireServer(
			self:GetId(),
			"Damage",
			dmgType
		)
	elseif server then
		if self:IsOpened() then return end
		if self:IsImmuned() then return end -- is door immuned?
		if self:IsCooldowned() then return end -- is door is on cooldown
		if self:IsBroken() then return end
		if not dmgType or not damage_table[dmgType] then return end
		local player_object = PlayerComponent.GetObjectFromInstance( player )
		if not player_object then return end -- if not player wrapper
		
		local CharacterObject = player_object.Character
		local character_model = CharacterObject.Instance
		if not character_model or CharacterObject:IsDead() then return end -- if character is dead
		
		local open_side = "Front" -- "Front" by default | "Back"
		if not self:GetOpenDirectionFromPosition( CharacterObject:GetPosition() ) then -- check if open side is "Back"
			open_side = "Back"
		end
		self:SetInteractor(player, "Damage")
		self:SetForceDir(open_side)
		self:SetHealth(self:GetHealth() - damage_table[dmgType])
	end]]
end

-- client/server method to prompt door slam
function Door:PromptSlam( player: Player? )
	--[[if client then
		
		MessagingEvent:FireServer(
			self:GetId(),
			"Slam"
		)
	elseif server then
		if self:IsOpened() then return end
		if self:IsImmuned() then return end -- is door immuned?
		if self:IsCooldowned() then return end -- is door is on cooldown
		if self:IsSlammed() then return end -- is door slammed
		if self:IsBroken() then return end
		
		local player_object = PlayerComponent.GetObjectFromInstance( player )
		if not player_object then return end -- if not player wrapper
		
		local CharacterObject = player_object.Character
		local character_model = CharacterObject.Instance
		if not character_model or CharacterObject:IsDead() then return end -- if character is dead
		
		local open_side = "Front" -- "Front" by default | "Back"
		if not self:GetOpenDirectionFromPosition( CharacterObject:GetPosition() ) then -- check if open side is "Back"
			open_side = "Back"
		end
		
		self:SetForceDir(open_side)
		
		self:ApplyCooldown(.5)
		self:SetSlammed(true, player)
		task.delay(3, function()
			self:SetSlammed(false, player)
		end)
		-- обрабатываем
		-- и нужен отдельный метод который на клиенте будет рендерить анимацию и коллизию ставить
	end]]
end

-- CLIENT: prompts server to open/close door (back state)
-- SERVER: checks and applying state
function Door:Push( player: Player)
	if server then
		if self:IsImmuned() then return end -- is door immuned?
		if self:IsCooldowned() then return end -- is door is on cooldown
		if self:IsSlammed() then return end -- is door slammed
		if self:IsBroken() then return end -- is door broken

		local player_object = PlayerComponent.GetObjectFromInstance( player )
		if not player_object then return end -- if not player wrapper

		local CharacterObject = player_object.Character
		local character_model = CharacterObject.Instance
		local Humanoid: Humanoid = CharacterObject:GetHumanoid()
		if not character_model or not Humanoid or Humanoid.Health == 0 then return end

		-- door opening/closing
		self:ApplyCooldown(.5)
		self:SetOpened(
			not self:IsOpened(),
			player
		)

	elseif client then
		MessagingEvent:FireServer(
			self:GetId(),
			"Push" -- request to push door
		)
	end
end

-- GENERIC METHODS
-- getter methods
function Door:GetInstance(): Model		return self.reference end
function Door:GetId(): string			return self:GetInstance():GetAttribute(Attributes.ID) end
function Door:IsImmuned(): boolean		return self:GetInstance():GetAttribute(Attributes.IMMUNE) end
function Door:IsBroken(): boolean		return self:GetInstance():GetAttribute(Attributes.BROKEN) end
function Door:IsOpened(): boolean		return self:GetInstance():GetAttribute(Attributes.OPENED) end
function Door:GetHealth(): number		return self:GetInstance():GetAttribute(Attributes.HEALTH) end
function Door:IsSlammed(): boolean		return self:GetInstance():GetAttribute(Attributes.SLAMMED) end
function Door:GetForceDir(): number 	return self:GetInstance():GetAttribute(Attributes.HITDIRECTION) end
function Door:IsCooldowned(): boolean	return os.clock() - self.last_interaction < self.cooldown end

-- returns last interactor and action
function Door:GetLastInteractor()
	local action_history = self.action_history
	return action_history[ #action_history ]
		and action_history[ #action_history ][1]
end

-- sets door opened
function Door:SetOpened(opened: boolean, interactor: Player?)
	assert(server, 'Attempt to call :SetOpened() on client')

	-- state replication
	self:GetInstance():SetAttribute(Attributes.OPENED, opened)
	self:SetInteractor(
		interactor,
		opened and "Open" or "Close"
	)
end

--[[ slams door (UNRELEASED?)
function Door:SetSlammed(slammed: boolean, interactor: Player?)
	assert(server, 'Attempt to call :SetSlammed() on client')
	self:GetInstance():SetAttribute(Attributes.SLAMMED, slammed)
	
	if slammed then
		self:SetInteractor(
			interactor,
			"Slam"
		)
	end
end]]

-- door is broken (client doing goober animations!)
function Door:SetBroken(broken: boolean, interactor: Player?)
	assert(server, 'Attempt to call :SetBroken() on client')
	self:GetInstance():SetAttribute(Attributes.BROKEN, broken)
	
	for _, Proximity: ProximityPrompt? in ipairs(self:GetInstance():GetDescendants()) do
		if not Proximity:IsA('ProximityPrompt') then continue end
		Proximity:Destroy() -- removing possible interactions
	end

	if broken then
		self:SetInteractor(
			interactor,
			"Break"
		)
	end
end

-- sets ForceDirection attribute on server
function Door:SetForceDir(value: string)
	assert(server, 'Attempt to call :SetForceDir() on client')
	self:GetInstance():SetAttribute(Attributes.HITDIRECTION, value)
end

-- sets Health attribute on server
function Door:SetHealth(value: number)
	assert(server, 'Attempt to call :SetHealth() on client')

	-- constraints
	local value = math.clamp(value, 0, 500)
	self:GetInstance():SetAttribute(Attributes.HEALTH, value)
end

-- sets door CanCollide both on client/server
function Door:SetCanCollide(value: boolean)
	if value then task.delay(.45, function()
			self:GetInstance().Root.CanCollide = true end)
	else self:GetInstance().Root.CanCollide = false end
end

-- sets last door interactor and action applied
function Door:SetInteractor( interactor: Player, action: string )
	assert(action, 'No action provided')
	table.insert(self.action_history, {
		interactor or 0, -- 0 means a server
		action
	})
end

-- loads all sounds in door
function Door:LoadSounds()
	assert(client, 'Attempt to call :LoadSounds() on server')
	local SFX = game:GetService('SoundService').Master.Instances.Door

	-- sound copying
	local sounds = {
		open = SFX.Open:Clone(),
		close = SFX.Close:Clone(),
		destroy = SFX.Break:Clone(),
		damage = {}
	}

	for _, DamageSound: Sound in ipairs(SFX.Damage:GetChildren()) do
		local DamageSound = DamageSound:Clone()
		table.insert(sounds.damage, DamageSound)
		DamageSound.Parent = self:GetInstance().Root
	end

	-- placing sounds into root part
	for _, Sound: Sound? in pairs(sounds) do
		if typeof(Sound) ~= 'Instance' then continue end
		Sound.Parent = self:GetInstance().Root
	end

	-- got it
	self.sounds = sounds
end

-- @overload
function Door:Animate(...) end
function Door:AnimateSlam(...) end
function Door:AnimateDamage(...) end
function Door:AnimateBreak(...) end

-- full object destruction
function Door:Destroy()
	for _, connection: RBXScriptConnection in ipairs(self.connections) do
		connection:Disconnect() -- remove connection
	end
	
	-- prompting clients destroy door locally
	if server then
		MessagingEvent:FireAllClients('destroy',
			self:GetId()
		)
		
		-- instance removal
		self.reference:Destroy()
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
	setmetatable(self, nil)
	table.clear(self)
end

--complete
return Door