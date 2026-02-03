local server = shared.Server

-- requirements
local Enums = server._requirements.Enums
local GoreModule = require(script.ServerGoreComponent)

-- class initial
local ServerCharacter = {}
ServerCharacter.__index = ServerCharacter
ServerCharacter._objects = {}

-- constructor
function ServerCharacter.new(player_object)
	local self = setmetatable({
		player_object = player_object,
		ragdoll_rig = {},
		connections = {},
		
		replicated = { -- should be replicated to other players
			player = player_object.reference,
			character = player_object.reference.character, -- used to detect morphs/character loads from local player
			--currentHideout = false, -- used to reference to objecvt which being hideout for the player (school locker and etc.)
			ragdollEnabled = false,
			blockEnabled = false,
			stunned = false,
			dead = false
	}}, ServerCharacter)
	
	table.insert(
		self._objects,
		self
	)
	
	self.Gore = GoreModule.new(self)
	self.replicated.body_parts_health = self.Gore.body_parts_health
	
	return self
end

function ServerCharacter:AddConnection(signal: RBXScriptConnection)
	table.insert(self.connections, signal)
end

function ServerCharacter:ResetConnection()
	for _, signal: RBXScriptConnection in ipairs(self.connections) do
		signal:Disconnect()
	end
end


--function ServerCharacter:IsDead() return self.replicated.dead end
function ServerCharacter:GetPlayer() return self.Player.reference end
function ServerCharacter.Instance() return self.replicated.player.Character end
function ServerCharacter:GetPlayerObject() return self.Player end

-- returns humanoid instance if exists
function ServerCharacter:GetHumanoid(): Humanoid
	local character: Model = self.Instance
	return character and character:FindFirstChildOfClass('Humanoid')
end

-- returns a character position (Vec3)
function ServerCharacter:GetPosition()
	local character: Model = self.Instance
	if not character then return end
	local primaryPart: BasePart = character:FindFirstChild('HumanoidRootPart')
	if not primaryPart then return end
	return primaryPart.Position
end


function ServerCharacter.GetObjectFromPlayerInstance(owner: Player?)
	for _, object in ipairs(ServerCharacter._objects) do
		if object.Player.reference ~= owner then continue end
		return object
	end
end


function ServerCharacter.GetObjectByHitpart( hitpart: BasePart? )
	for _, object in ipairs(ServerCharacter._objects) do
		local character: Model = object.Instance
		if not hitpart:IsDescendantOf(character) then continue end
		return object
	end
end

-- rebinds current object`s instance to new character
-- TODO: Full player/character recode (its SHIT)
function ServerCharacter:Reset( morph: Model? )
	if morph then -- binding player`s character to morph
		assert( morph.PrimaryPart, 'No morph primary part exists' )
		assert( morph:FindFirstChildOfClass('Humanoid'), 'No humanoid exists in morph provided' )
		
		morph.Parent = workspace
		morph.Name = self.Player.reference.Name
		self.Player.reference.Character = morph
		
		-- enabling client
		morph.Client.Enabled = true
	else
		-- loading player`s character default
		self.Player.reference:LoadCharacter()
	end
	
	-- getting new character
	local character: Model = self.Instance
	assert(character, 'Something went wrong when attempted to get character instance reference')
	
	-- parenting character to players folder
	character.Parent = workspace.Players
		
	-- replica state resets
	local playerReplica = self.Player.playerReplica
	playerReplica:SetValue('Character.character', character)
	playerReplica:SetValue('Character.dead', false)
	
	-- creating new WCS character object
	self.Player:DestroyWCSCharacter()
	self.Player:CreateWCSCharacter()
	
	-- erase old connection memory
	self.Gore:Reset()
	self:ResetConnection()
	self:BuildRagdollRig()
	self:SetWholeNetworkOwner()
	self:SetRagdollEnabled(false)
	
	-- humanoid setting up
	local humanoid = character:FindFirstChildOfClass('Humanoid')
	humanoid.BreakJointsOnDeath = false
	
	-- collision group setting
	for _, descendant: Instance in ipairs(character:GetDescendants()) do
		if descendant:IsA('BasePart') then
			descendant.CollisionGroup = 'Player'
		end
	end
	
	-- tool handle motor6d creation
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local Motor = Instance.new('Motor6D')
		Motor.Parent = character:FindFirstChild('Right Arm')
		Motor.Part0 = character:FindFirstChild('Right Arm')
		Motor.Name = 'Handle'
	end
	
	self:AddConnection(humanoid.HealthChanged:Connect(function(new_health: number)
		if new_health > 0 or self.replicated.dead then return end
		
		-- replicate to others about player is dead
		playerReplica:SetValue('Character.dead', true)
		
		-- removing  WCS character object
		self.Player:DestroyWCSCharacter()
		self.Player.Backpack:Clear()
		
		self:SetRagdollEnabled(true)
		
		--[[ killer award
		local last_damager: Player = self.Gore:GetLastDamager()
		local damager_object = server._requirements.ServerPlayer.GetObjectFromInstance( last_damager )
		
		self.Player:RegisterAction(
			Enums.PlayerActionType.Deaths,
			damager_object
		)]]
	end))
end


function ServerCharacter:BuildRagdollRig()
	local character: Model = self.Instance

end


function ServerCharacter:Stun()
	local playerReplica = self.Player.playerReplica
	local player: Player = self.Player.reference
	if not playerReplica then return end
	
	playerReplica:FireClient(player, 'character_stunned')
end


--[[function ServerCharacter:ResetHideout()
	local hideout = server._requirements.ServerLockersModule:GetLockerByReference( self.replicated.currentHideout )
	local character: Model = self.Instance
	
	if character then -- unanchoring HumanoidRootPart to able to ragdoll
		character.HumanoidRootPart.Anchored = false
		character.HumanoidRootPart.CFrame = hideout
			and hideout.replicated.reference.Root.LeaveWeld.WorldCFrame
			or character.HumanoidRootPart.CFrame
	end
	
	-- we could remove out character from occuped hideout
	self:SetHideout( nil )
	
	if hideout then
		hideout:ForceLeave()
	end
end]]


--[[function ServerCharacter:SetHideout( hideout_reference: Instance )
	local playerReplica = self.Player.playerReplica
	playerReplica:SetValue('Character.currentHideout', hideout_reference)
	--self.Player.Backpack:SetLocked( hideout_reference and true or false )
end]]


function ServerCharacter:SetRagdollEnabled(value: boolean)
	self:SetWholeNetworkOwner()
	local character: Model = self.Instance

	--assert(self.replicated.ragdollEnabled ~= value, 'Already has value for ragdollEnabled')
	assert(character, 'Attempt to enable Ragdoll for nil character')
	
	local playerReplica = self.Player.playerReplica
	playerReplica:SetValue('Character.ragdollEnabled', value)
	local humanoid: Humanoid = character:FindFirstChildOfClass('Humanoid')
	
	for _, bis: BallSocketConstraint in ipairs(self.ragdoll_rig) do
		bis[1].Enabled = value		-- BallInSocket
		bis[2].Enabled = not value	-- Motor6D
	end
end


function ServerCharacter:SetWholeNetworkOwner(owner: Player?)
	for _, a: BasePart in ipairs(self.Instance:GetDescendants()) do
		if not a:IsA('BasePart') then continue end
		a:SetNetworkOwner(owner or self.Player.reference)
	end
end


function ServerCharacter:Destroy()
	self:ResetConnection()
	
	-- raw removal
	table.remove(
		self._objects,
		table.find(
			self._objects,
			self
		)
	)
	
	-- lock current meta
	setmetatable(self, nil)
	table.clear(self)
end

return ServerCharacter