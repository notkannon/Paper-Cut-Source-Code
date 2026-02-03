-- service
local CollectionService = game:GetService('CollectionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local LightingService = game:GetService('Lighting')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')

-- paths
local Sounds = game:GetService('SoundService').Master.Environment
local particles = ReplicatedStorage.Assets.Particles

-- requirements
local FurnitureLamp = require(script.FurnitureLamp)
local CeilingLamp = require(script.CeilingLamp)


-- Lighting initial
local Lighting = {}

-- initial method
function Lighting:Init()
	local CeilingLamps = CollectionService:GetTagged('CeilingLamp')
	local FurnitureLamps = CollectionService:GetTagged('FurnitureLamp')
	
	-- ceiling lamp initial
	for _, instance in ipairs(CeilingLamps) do
		CeilingLamp.new(instance)
	end
	
	-- furniture lamp initial
	for _, instance in ipairs(FurnitureLamps) do
		FurnitureLamp.new(instance)
	end
	
	
	--[[
	for _, lamp: Model in ipairs(self._lamps) do
		local off = SFX.Instances.Lamp.off:Clone()
		local on = SFX.Instances.Lamp.on:Clone()
		off.Parent = lamp.PrimaryPart
		on.Parent = lamp.PrimaryPart
		
		local sparks = particles.LampSparks:Clone()
		sparks.Parent = lamp.PrimaryPart
	end]]
end

-- sets all lighting in game to Night time
function Lighting:ApplyNight()
	Sounds.lights_down_add:Play()
	Sounds.lights_down:Play()
	
	--  applying night time
	TweenService:Create(
		LightingService,
		TweenInfo.new( 13 ), {
			ClockTime = 24,
			Brightness = 0,
	}):Play()
	
	task.spawn(function()
		for _, lamp in ipairs(CeilingLamp._objects) do
			lamp:SetEnabled(false)
			task.wait(.07)
		end
	end)
	--[[
	for _, lamp: Model in ipairs(self._lamps) do
		local prom: BasePart = lamp.PrimaryPart
		prom:FindFirstChildOfClass('ParticleEmitter'):Emit(math.random(2, 4))
		prom.off:Play()
		
		TweenService:Create(prom, TweenInfo.new(.3), {Color = Color3.new(.2, .2, .2)}):Play()
		
		task.wait(math.random(0, 2)*.07)
	end]]
end

-- sets all lighting in game to Day time
function Lighting:ApplyDay()
	Sounds.lights_restored:Play()
	
	--  applying day time
	TweenService:Create(
		LightingService,
		TweenInfo.new( 13 ), {
			ClockTime = 15,
			Brightness = 2.5,
	}):Play()
	
	task.spawn(function()
		for _, lamp in ipairs(CeilingLamp._objects) do
			lamp:SetEnabled(true)
			task.wait(.07)
		end
	end)
	--[[
	for _, lamp: Model in ipairs(self._lamps) do
		local prom: BasePart = lamp.PrimaryPart
		prom:FindFirstChildOfClass('ParticleEmitter'):Emit(math.random(2, 4))
		prom.on:Play()
		TweenService:Create(prom, TweenInfo.new(.7), {Color = Color3.fromRGB(165,165,165)}):Play()
		task.wait(math.random(0, 2)*.07)
	end]]
end

-- initialization
Lighting:Init()
return Lighting