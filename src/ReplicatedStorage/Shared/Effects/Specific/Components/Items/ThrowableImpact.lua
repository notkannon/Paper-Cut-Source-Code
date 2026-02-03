--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local EffectUtility = require(ReplicatedStorage.Shared.Utility.EffectsUtility)

--//Variables

local ThrowableImpact = Refx.CreateEffect("ThrowableImpact") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {}

export type Impl = Refx.EffectImpl<MyImpl, Fields, Model, { [BasePart]: CFrame }>
export type Effect = Refx.Effect<MyImpl, Fields, Model, { [BasePart]: CFrame }>

--//Methods

function ThrowableImpact.OnStart(self: Effect, at: Vector3|CFrame)
	EffectUtility.EmitParticlesInWorldSpace(at, ReplicatedStorage.Assets.Particles.ImpactParticles:GetChildren())
end

--//Return

return ThrowableImpact