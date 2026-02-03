local Client = shared.Client

-- type
type FootstepSound = {
	Instance: Sound,
	DefaultSpeed: number,
	DefaultVolume: number
}

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local SoundService = game:GetService('SoundService')
local SoundSources = SoundService.Master.Players.Footsteps
local RunService = game:GetService('RunService')

-- requirements
local Util = require(ReplicatedStorage.Shared.Util)

-- FootstepSounds initial
local FootstepSounds = {}
FootstepSounds.__index = FootstepSounds

-- constructor
function FootstepSounds.new( Character )
	local SoundGroup = Instance.new('SoundGroup')
	SoundGroup.Parent = Character.Sounds.SoundGroup
	SoundGroup.Name = 'Footsteps'
	
	local self = setmetatable({
		SoundGroup = SoundGroup,
		Character = Character,
		Current = nil,
		Previous = nil,
		Sounds = {} :: { [ string ]: FootstepSound? },
		
		_Connections = {}
	}, FootstepSounds)
	return self
end

-- initial method
function FootstepSounds:Init()
	assert(Client, 'Attempted to call :Init() of FootstepSounds from server')
	
	local Character = self.Character
	local Humanoid: Humanoid = Character:GetHumanoid()
	
	-- sounds copying
	for _, Source: Sound in ipairs(SoundSources:GetChildren()) do
		if not Source:IsA('Sound') then continue end
		local Copy = Source:Clone()
		
		self.Sounds[ Copy.Name ] = {
			Instance = Copy,
			DefaultSpeed = Copy.PlaybackSpeed,
			DefaultVolume = Copy.Volume
		}
		
		Copy.PlaybackSpeed = 0
		Copy.SoundGroup = self.SoundGroup
		Copy.Playing = true
		Copy.Volume = 0
		Copy.Parent = self.Character.Instance.HumanoidRootPart
	end
	
	-- setting default material from start
	self:SetMaterial()
	self.Previous = self.Current
	
	--// connections
	table.insert(self._Connections,
		Humanoid.Changed:Connect(function(property: string)
			-- new material detection
			if property == 'FloorMaterial' then
				self:SetMaterial(Humanoid.FloorMaterial)
			end
		end)
	)
end

-- sets current material of FootstepSounds
function FootstepSounds:SetMaterial(material: Enum.Material)
	local TargetSound: Sound = self.Sounds[ material and material.Name or 'Default' ] or self.Sounds.Default
	if self.Previous then self.Previous.Instance.Volume = 0 end
	self.Previous = self.Current
	self.Current = TargetSound
end


function FootstepSounds:Update()
	--print(self.Character.Instance.HumanoidRootPart.AssemblyLinearVelocity.Magnitude)
	--TODO: complete
	local Current: FootstepSound = self.Current
	local Previous: FootstepSound = self.Previous
	
	local Force: number = (self.Character:GetVelocity() * Vector3.new(1, 0, 1)).Magnitude / 16
	Previous.Instance.Volume = Util.Lerp(Previous.Instance.Volume, 0, 1/7)
	Current.Instance.Volume = Util.Lerp(Current.Instance.Volume, math.clamp(Force, 0, 1), 1/14)
	Current.Instance.PlaybackSpeed = Util.Lerp(Current.Instance.PlaybackSpeed, Current.DefaultSpeed * Force, 1/14)
end

-- destructor
function FootstepSounds:Destroy()
	for _, connection: RBXScriptConnection in ipairs(self._Connections) do
		connection:Disconnect()
	end
	
	setmetatable(self, nil)
	table.clear(self)
end

return FootstepSounds