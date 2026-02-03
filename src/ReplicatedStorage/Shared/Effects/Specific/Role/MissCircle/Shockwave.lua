--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local EffectUtility = require(ReplicatedStorage.Shared.Utility.EffectsUtility)

local CameraController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.CameraController) or nil

--//Variables

local Player = Players.LocalPlayer
local Shockwave = Refx.CreateEffect("Shockwave") :: Impl

--//Types

type Morph = typeof(ReplicatedStorage.Assets.Morphs.MissCircle)

export type MyImpl = {
	__index: MyImpl,
	
	Impact: (self: Effect, cframe: CFrame) -> (),
}

export type Fields = {
	Player: Player,
	Instance: Morph,
}

export type Impl = Refx.EffectImpl<MyImpl, Fields, Morph>
export type Effect = Refx.Effect<MyImpl, Fields, Morph>

--//Methods

function Shockwave.OnConstruct(self: Effect, character: Morph)
	self.DestroyOnEnd = false
	self.DisableLeakWarning = true
	self.DestroyOnLifecycleEnd = false
end

function Shockwave.Impact(self: Effect, cframe: CFrame)
	EffectUtility.EmitParticlesInWorldSpace(cframe, ReplicatedStorage.Assets.Particles.Impact.Shockwave:GetChildren())
	
	local Character = Player.Character :: PlayerTypes.Character
	if not Character then
		return
	end
	
	local Distance = (Character.HumanoidRootPart.Position - self.Instance.HumanoidRootPart.Position).Magnitude
	local Strength = (1 - math.clamp(Distance / 100, 0, 1)) ^ 2
	
	CameraController:QuickShake(2.3, Strength * 2)
	
	local Wave = ReplicatedStorage.Assets.Skills.Shockwave.Shockwave:Clone()
	Wave.Parent = workspace.Temp
	Wave.Position = self.Instance.HumanoidRootPart.Position + Vector3.new(0, -1.5, 0)
	
	TweenUtility.PlayTween(Wave, TweenInfo.new(4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Size = Vector3.new(500, 0.2, 500)
	})
	
	for _, ImageLabel: ImageLabel in ipairs(Wave:GetDescendants()) do
		if not ImageLabel:IsA("ImageLabel") then
			continue
		end
		
		TweenUtility.PlayTween(ImageLabel, TweenInfo.new(4), {
			ImageTransparency = 1
		})
	end
	
	game:GetService("Debris"):AddItem(Wave, 5)
end

function Shockwave.OnStart(self: Effect, character: Morph)
	self.Player = Players:GetPlayerFromCharacter(character)
	self.Instance = character
end

--//Return

return Shockwave