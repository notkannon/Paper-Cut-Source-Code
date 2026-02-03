--[[
	Responsible for helping in the Lighting handling
--]]

--//Service
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

--//Import
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local Utility = require(script.Parent)

--//Functions
function ApplyLighitEffect(InstanceType: string, params, TimeLife: number)
	local NewEffect = Instance.new(InstanceType, Lighting)
	Utility.ApplyParams(NewEffect, params)
	
	if TimeLife then
		Debris:AddItem(NewEffect, TimeLife)
	end

	return NewEffect
end

function ApplyBlurEffect(params, TimeLife): BlurEffect
	return ApplyLighitEffect("BlurEffect", params, TimeLife)
end

function ApplyColorCorrectionEffect(params, TimeLife): BlurEffect
	return ApplyLighitEffect("ColorCorrectionEffect", params, TimeLife)
end

function ApplyAtmosphereEffect(params, TimeLife): Atmosphere
	return ApplyLighitEffect("Atmosphere", params, TimeLife)
end

function ApplyDepthOfFieldEffect(params, TimeLife): DepthOfFieldEffect
	return ApplyLighitEffect("DepthOfField", params, TimeLife)
end

--//Rturn
return {
	ApplyBlurEffect = ApplyBlurEffect,
	ApplyAtmosphereEffect = ApplyAtmosphereEffect,
	ApplyDepthOfFieldEffect = ApplyDepthOfFieldEffect,
	ApplyColorCorrectionEffect = ApplyColorCorrectionEffect,
}
