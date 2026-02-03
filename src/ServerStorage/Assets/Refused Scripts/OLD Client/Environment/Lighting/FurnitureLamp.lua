local SoundService = game:GetService('SoundService')
local TweenService = game:GetService('TweenService')
local LightingService = game:GetService('Lighting')

-- paths
local Sounds = SoundService.Master.Instances.Lamps.FurnitureLamp

-- FurnitureLamp initial
local FurnitureLamp = {}
FurnitureLamp._objects = {}
FurnitureLamp.__index = FurnitureLamp

-- constructor
function FurnitureLamp.new(reference: Model)
	assert(reference:HasTag('FurnitureLamp'), `Instance have no tag "FurnitureLamp" ({ reference })`)
	
	-- object initialize
	local self = setmetatable({
		reference = reference,
		connections = {}
	}, FurnitureLamp)
	
	table.insert(
		self._objects,
		self
	)
	
	self:Init()
	return self
end

-- initial method
function FurnitureLamp:Init()
	for _, sound: Sound in ipairs(Sounds:GetChildren()) do
		sound:Clone().Parent = self:GetInstance().Source
	end
	
	-- lamp changed connection
	self.connections.changed = self.reference.AttributeChanged:Connect(function( attribute: string )
		if attribute == 'Enabled' then
			local enabled: boolean = self
				:GetInstance()
				:GetAttribute('Enabled')
			
			-- enabling / disabling
			self:SetEnabled(enabled)
		end
	end)
end

-- returns instance reference
function FurnitureLamp:GetInstance()
	return self.reference
end

-- applies light state to instance
function FurnitureLamp:SetEnabled(enabled: boolean)
	local instance: Model = self:GetInstance()
	local source: BasePart = instance:FindFirstChild('Source')
	
	source.Material = Enum.Material[enabled and 'Neon' or 'SmoothPlastic']
	source:FindFirstChildOfClass('PointLight').Enabled = enabled
	source:FindFirstChild(enabled and 'On' or 'Off'):Play()
	
	source.Color = enabled
		and Color3.fromRGB(238, 211, 227)
		or Color3.fromRGB(175, 146, 130)
	
	TweenService:Create(source, TweenInfo.new(
			.3,
			Enum.EasingStyle[ enabled and 'Back' or 'Sine' ],
			Enum.EasingDirection.Out
		), {Color = Color3.fromRGB(175, 146, 130)}
	):Play()
end

-- complete
return FurnitureLamp