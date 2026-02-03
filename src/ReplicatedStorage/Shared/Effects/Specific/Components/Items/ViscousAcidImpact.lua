--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local EffectUtility = require(ReplicatedStorage.Shared.Utility.EffectsUtility)

--//Variables

local ViscousAcidImpact = Refx.CreateEffect("ViscousAcidImpact") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {}

export type Impl = Refx.EffectImpl<MyImpl, Fields, Vector3 | CFrame>
export type Effect = Refx.Effect<MyImpl, Fields, Vector3 | CFrame>

--//Methods

function ViscousAcidImpact.OnStart(self: Effect, at: Vector3|CFrame)
	SoundUtility.CreateTemporarySoundAtPosition(typeof(at) == "Vector3" and at or at.Position, SoundUtility.Sounds.Instances.Items.Throwable.FlaskImpact)
	EffectUtility.EmitParticlesInWorldSpace(at, ReplicatedStorage.Assets.Particles.Impact.ViscousAcid:GetChildren())
end

--//Return

return ViscousAcidImpact