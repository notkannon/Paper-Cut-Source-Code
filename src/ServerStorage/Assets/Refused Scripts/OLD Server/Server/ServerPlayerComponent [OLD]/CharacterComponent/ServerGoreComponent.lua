local Enums = require(game.ReplicatedStorage.Enums)
local characterBodyStatesEnum = Enums.CharacterBodyStatesEnum
local GoreSettings = require(game.ReplicatedStorage.GoreSettings)

local bodyStateStringToEnum = {
	['Right Arm'] = characterBodyStatesEnum.RightArm,
	['Left Arm'] = characterBodyStatesEnum.LeftArm,
	['Right Leg'] = characterBodyStatesEnum.RightLeg,
	['Left Leg'] = characterBodyStatesEnum.LeftLeg,
	Torso = characterBodyStatesEnum.Torso,
	
	RightUpperArm = characterBodyStatesEnum.RightUpperArm,
	LeftUpperArm = characterBodyStatesEnum.LeftUpperArm,
	RightLowerArm = characterBodyStatesEnum.RightLowerArm,
	LeftLowerArm = characterBodyStatesEnum.LeftLowerArm,
	RightHand = characterBodyStatesEnum.RightHand,
	LeftHand = characterBodyStatesEnum.LeftHand,
	RightUpperLeg = characterBodyStatesEnum.RightUpperLeg,
	RightLowerLeg = characterBodyStatesEnum.RightLowerLeg,
	LeftUpperLeg = characterBodyStatesEnum.LeftUpperLeg,
	LeftLowerLeg = characterBodyStatesEnum.LeftLowerLeg,
	RightFoot = characterBodyStatesEnum.RightFoot,
	LeftFoot = characterBodyStatesEnum.LeftFoot,
	UpperTorso = characterBodyStatesEnum.UpperTorso,
	LowerTorso = characterBodyStatesEnum.LowerTorso,
	
	Head = characterBodyStatesEnum.Head
}

local bodyStateEnumToString = {
	[characterBodyStatesEnum.RightArm] = 'Right Arm',
	[characterBodyStatesEnum.LeftArm ] = 'Left Arm',
	[characterBodyStatesEnum.RightLeg] = 'Right Leg',
	[characterBodyStatesEnum.LeftLeg ] = 'Left Leg',
	[characterBodyStatesEnum.Torso	 ] = 'Torso',
	
	[characterBodyStatesEnum.RightUpperArm	] = 'RightUpperArm',
	[characterBodyStatesEnum.LeftUpperArm	] = 'LeftUpperArm',
	[characterBodyStatesEnum.RightLowerArm	] = 'RightLowerArm',
	[characterBodyStatesEnum.LeftLowerArm	] = 'LeftLowerArm',
	[characterBodyStatesEnum.RightHand		] = 'RightHand',
	[characterBodyStatesEnum.LeftHand		] = 'LeftHand',
	[characterBodyStatesEnum.RightUpperLeg	] = 'RightUpperLeg',
	[characterBodyStatesEnum.RightLowerLeg	] = 'RightLowerLeg',
	[characterBodyStatesEnum.LeftUpperLeg	] = 'LeftUpperLeg',
	[characterBodyStatesEnum.LeftLowerLeg	] = 'LeftLowerLeg',
	[characterBodyStatesEnum.RightFoot		] = 'RightFoot',
	[characterBodyStatesEnum.LeftFoot		] = 'LeftFoot',
	[characterBodyStatesEnum.UpperTorso		] = 'UpperTorso',
	[characterBodyStatesEnum.LowerTorso		] = 'LowerTorso',
	
	[characterBodyStatesEnum.Head] = 'Head'
}

local ServerCharacterGore = {} do
	ServerCharacterGore.__index = ServerCharacterGore
	ServerCharacterGore._objects = {}
	
	function ServerCharacterGore.new( CharacterObject )
		local self = setmetatable({
			CharacterObject = CharacterObject,
			last_damager = nil, -- could use to track who killed who.
			
			body_parts_health = {
				[characterBodyStatesEnum.RightArm	] = 100,
				[characterBodyStatesEnum.LeftArm	] = 100,
				[characterBodyStatesEnum.RightLeg	] = 100,
				[characterBodyStatesEnum.LeftLeg	] = 100,
				[characterBodyStatesEnum.Torso		] = 100,
				
				[characterBodyStatesEnum.RightUpperArm	] = 100,
				[characterBodyStatesEnum.LeftUpperArm	] = 100,
				[characterBodyStatesEnum.RightLowerArm	] = 100,
				[characterBodyStatesEnum.LeftLowerArm	] = 100,
				[characterBodyStatesEnum.RightHand		] = 100,
				[characterBodyStatesEnum.LeftHand		] = 100,
				[characterBodyStatesEnum.RightUpperLeg	] = 100,
				[characterBodyStatesEnum.RightLowerLeg	] = 100,
				[characterBodyStatesEnum.LeftUpperLeg	] = 100,
				[characterBodyStatesEnum.LeftLowerLeg	] = 100,
				[characterBodyStatesEnum.RightFoot		] = 100,
				[characterBodyStatesEnum.LeftFoot		] = 100,
				[characterBodyStatesEnum.UpperTorso		] = 100,
				[characterBodyStatesEnum.LowerTorso		] = 100,
				
				[characterBodyStatesEnum.Head		] = 100
			}
		}, ServerCharacterGore)
		
		table.insert(
			self._objects,
			self
		)
		
		return self
	end
	
	
	function ServerCharacterGore:GetLastDamager()
		return self.last_damager
	end
end


function ServerCharacterGore:Reset()
	local characterObject = self.Character
	local playerReplica = characterObject.Player.playerReplica
	
	for _index, _ in pairs(self.body_parts_health) do
		playerReplica:ArraySet('Character.body_parts_health', _index, 100)
	end
end


function ServerCharacterGore:GetHealthForHumanoid()
	local max_health = 600
	local health_amount = 0
	
	for _, health in pairs(self.body_parts_health) do
		health_amount += health
	end
	
	return (health_amount / max_health) * 100
end


function ServerCharacterGore:RegisterDamage(player_who_damaged: Player, damaged_bodypart_name: string, amount: number)
	self.last_damager = player_who_damaged or self.last_damager -- player can die without hitting, but will be killed by last damager
	
	local characterObject = self.Character
	local humanoid: Humanoid = characterObject:GetHumanoid()
	local playerReplica = characterObject.Player.playerReplica
	local indexBodypart = bodyStateStringToEnum[damaged_bodypart_name]
	
	if not indexBodypart then return end
	if not humanoid then return end
	--if characterObject:GetHideout() then return end
	
	local bodypart_settings = GoreSettings[ damaged_bodypart_name ]
	local currentBodyPartHealth = playerReplica.Data.Character.body_parts_health[indexBodypart]
	
	-- getting a current gore phase of damaged bodypart
	local bodypart_gore_phase = nil
	local _parse_phase = #bodypart_settings.Phases
	while _parse_phase > 1 do
		local phase = bodypart_settings.Phases[ _parse_phase ]

		if currentBodyPartHealth <= phase[1] then
			bodypart_gore_phase = phase
			break
		end

		_parse_phase -= 1
	end
	
	local bodypart_damage = math.clamp(humanoid.Health - self:GetHealthForHumanoid(), 0, humanoid.Health)
	humanoid:TakeDamage(amount + bodypart_damage)
	
	playerReplica:ArraySet(
		'Character.body_parts_health',
		indexBodypart,
		math.clamp(currentBodyPartHealth - (bodypart_gore_phase and bodypart_gore_phase[3] or 10), 0, 100)
	)
end

return ServerCharacterGore