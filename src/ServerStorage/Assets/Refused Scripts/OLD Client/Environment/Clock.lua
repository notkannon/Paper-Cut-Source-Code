local CollectionService = game:GetService('CollectionService')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local SFX = game:GetService('SoundService').Master

-- requirements
local Enums = require(game.ReplicatedStorage.Enums)
local Util = require(game.ReplicatedStorage.Shared.Util)

-- const
local PI = math.pi

-- class initial
local Clock = {}
local Instances = CollectionService:GetTagged('Clock')

-- initial
function Clock:Init()
	for _, clock: Model in ipairs(Instances) do
		local sound = SFX.Instances.Clock:Clone()
		sound.Parent = clock.PrimaryPart
	end
end

-- clock editing
function Clock:Apply(countdown: number, phase: number)
	for _, clock: Model in ipairs(Instances) do
		clock.PrimaryPart:FindFirstChildOfClass('Sound'):Play()
		clock.PrimaryPart.minute.C0 *= CFrame.Angles(
			0,
			0,
			-PI / 30
		)
		
		local ProximityPrompt: ProximityPrompt = clock.Border.Label
		local Daytime: string = phase == Enums.GamePhaseEnum.Intermission
			and 'DAY' or 'NIGHT'
		
		-- applying info to proximity prompt as label
		ProximityPrompt.ObjectText = `{ Daytime } - { Util.SecondsToMS(countdown) }`
	end
end

-- initialization
Clock:Init()
return Clock