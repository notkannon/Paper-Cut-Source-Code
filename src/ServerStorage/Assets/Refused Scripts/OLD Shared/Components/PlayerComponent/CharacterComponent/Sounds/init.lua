local Client = shared.Client

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SoundService = game:GetService('SoundService')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')

-- refs
local PlayerSoundGroup = SoundService.Master.Players

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local Footsteps = require(script.Footsteps)


-- CharacterSounds initial
local CharacterSounds = {}
CharacterSounds._objects = {}
CharacterSounds.__index = CharacterSounds

-- constructor
function CharacterSounds.new( Character )
	local CharacterModel: Model = Character.Instance
	
	assert(CharacterModel:FindFirstChildWhichIsA('Humanoid'), 'Provided character has no humanoid')
	assert(CharacterModel.PrimaryPart, 'Provided character model has no .PrimaryPart ("HumanoidRootPart" expected)')
	
	-- soundgroup definition
	local SoundGroup: SoundGroup
	if PlayerSoundGroup:FindFirstChild(Character.Instance.Name) then
		SoundGroup = PlayerSoundGroup:FindFirstChild(Character.Instance.Name)
	else
		SoundGroup = Instance.new('SoundGroup')
		SoundGroup.Parent = PlayerSoundGroup
		SoundGroup.Name = CharacterModel.Name
	end
	
	local self = setmetatable({
		SoundGroup = SoundGroup,
		Character = Character,
		SoundGroups = {},
		
		_Connections = {}
	}, CharacterSounds)
	
	table.insert(
		self._objects,
		self)
	return self
end

-- initial method
function CharacterSounds:Init()
	if not Client then return end
	self.Footsteps = Footsteps.new(self.Character)
	self.Footsteps:Init()
end


-- puts copy of sound instance to given place and plays it
function CharacterSounds:PlaySound(name: string, volume: number?)
	local Sound: Sound = PlayerSoundGroup:FindFirstChild(name)
	if not Sound then return end
	
	local sound = Sound:Clone()
	sound.SoundGroup = self.SoundGroup
	sound.Volume = volume or 1
	sound.Parent = self.Character.Instance.HumanoidRootPart
	sound:Play()

	-- cleaning up
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end


function CharacterSounds:Destroy()
	-- child destruction
	if self.Footsteps then
		self.Footsteps:Destroy()
	end
	
	self.SoundGroup:Destroy()
	
	table.remove(CharacterSounds._objects,
		table.find(CharacterSounds._objects,
			self
		)
	)
	
	table.clear(self)
	setmetatable(self, nil)
end


--// UPDATE
if Client then
	RunService:BindToRenderStep('@CharacterSounds', Enum.RenderPriority.Character.Value, function()
		for _, Object in ipairs(CharacterSounds._objects) do
			Object.Footsteps:Update()
		end
	end)
end

return CharacterSounds