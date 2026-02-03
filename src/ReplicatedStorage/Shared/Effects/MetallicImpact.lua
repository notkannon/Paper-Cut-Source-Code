--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local SoundsUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local EffectUtility = require(ReplicatedStorage.Shared.Utility.EffectsUtility)

--//Variables

local MetallicImpact = Refx.CreateEffect("MetallicImpact") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {}

export type Impl = Refx.EffectImpl<MyImpl, CFrame>
export type Effect = Refx.Effect<MyImpl, CFrame>

--//Methods

function MetallicImpact.OnStart(self: Effect, at: CFrame)
	SoundsUtility.CreateTemporarySoundAtPosition(at.Position,
		SoundsUtility.GetRandomSoundFromDirectory(SoundsUtility.Sounds.Environment.Impacts.Metallic)
	)
	
	EffectUtility.EmitParticlesInWorldSpace(at, ReplicatedStorage.Assets.Particles.Impact.Metallic:GetChildren())
end

--//Return

return MetallicImpact