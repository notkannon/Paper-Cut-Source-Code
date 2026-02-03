--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local Utility = require(ReplicatedStorage.Shared.Utility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local EffectsUtility = require(ReplicatedStorage.Shared.Utility.EffectsUtility)

--//Variables

local PlayerEffects = Refx.CreateEffect("PlayerHeal") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {}

export type Impl = Refx.EffectImpl<MyImpl, Fields, PlayerTypes.Character>
export type Effect = Refx.Effect<MyImpl, Fields, PlayerTypes.Character>

--//Methods

function PlayerEffects.OnStart(self: Effect, character: Instance, amount: number)
	
	local Highlight = Instance.new("Highlight", character)

	Utility.ApplyParams(Highlight, {
		DepthMode = Enum.HighlightDepthMode.Occluded,
		FillColor = Color3.fromRGB(100, 145, 71),

		OutlineTransparency = 1,
		FillTransparency = 0.35
	})

	SoundUtility.CreateTemporarySound(
		SoundUtility.GetRandomSoundFromDirectory(SoundUtility.Sounds.Players.Replicas.Breath)
	).Parent = character.HumanoidRootPart

	local HealParticles : ParticleEmitter
	HealParticles = character.HumanoidRootPart:FindFirstChild("_HealingParticles")

	if not HealParticles then
		HealParticles = ReplicatedStorage.Assets.Particles.HealingParticles:Clone()
		HealParticles.Parent = character.HumanoidRootPart
		HealParticles.Name = "_HealingParticles"
		HealParticles.Enabled = false
	end

	HealParticles:Emit(amount * .6)

	TweenUtility.PlayTween(Highlight, TweenInfo.new(0.5), {
		FillTransparency = 1
	})

	task.delay(0.5, Highlight.Destroy, Highlight)
end

--//Return

return PlayerEffects