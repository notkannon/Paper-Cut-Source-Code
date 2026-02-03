local SoundService = game:GetService('SoundService')
local TweenService = game:GetService('TweenService')
local LightingService = game:GetService('Lighting')

-- paths
local Sounds = SoundService.Master.Instances.Lamps.CeilingLamp

-- CeilingLamp initial
local CeilingLamp = {}
CeilingLamp._objects = {}
CeilingLamp.__index = CeilingLamp

-- constructor
function CeilingLamp.new(reference: Model)
	assert(reference:HasTag('CeilingLamp'), `Instance have no tag "CeilingLamp" ({ reference })`)

	-- object initialize
	local self = setmetatable({
		reference = reference,
		connections = {}
	}, CeilingLamp)

	table.insert(
		self._objects,
		self
	)

	self:Init()
	return self
end

-- initial method
function CeilingLamp:Init()
	for _, sound: Sound in ipairs(Sounds:GetChildren()) do
		sound:Clone().Parent = self:GetInstance().Source
	end
end

-- returns instance reference
function CeilingLamp:GetInstance()
	return self.reference
end

-- applies light state to instance
function CeilingLamp:SetEnabled(enabled: boolean)
	local instance: Model = self:GetInstance()
	local source: BasePart = instance:FindFirstChild('Source')
	local light: SpotLight = source:FindFirstChildOfClass('SpotLight')
	
	local style = {'Back', 'Bounce', 'Sine'}
	source:FindFirstChild(enabled and 'On' or 'Off'):Play()
	source.Material = Enum.Material.Neon

	local Color = enabled
		and Color3.fromRGB(156, 146, 156)
		or Color3.fromRGB(68, 68, 68)
	
	source.Color = Color3.fromRGB(244, 229, 244)
	light.Enabled = true
	light.Color = Color

	TweenService:Create(source, TweenInfo.new(
		math.random(3, 5)/3,
		Enum.EasingStyle[style[math.random(1, #style)]],
		Enum.EasingDirection.Out
		), {Color = Color}
	):Play()
end

-- complete
return CeilingLamp