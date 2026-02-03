--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerSciptService = game:GetService("ServerScriptService")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local tweenutility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local EffectUtility = require(ReplicatedStorage.Shared.Utility.EffectsUtility)

local RefxWrapper = RunService:IsServer() and require(ServerSciptService.Server.Classes.RefxWrapper) or nil

--//Variables

local PuddleAsset = ReplicatedStorage.Assets.Items.Related.ViscousAcid.Puddle
local ViscousAcidPuddle = Refx.CreateEffect("ViscousAcidPuddle") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {}

export type Impl = Refx.EffectImpl<MyImpl, Fields, CFrame>
export type Effect = Refx.Effect<MyImpl, Fields, CFrame>

--//Functions

local function New(at: CFrame)
	local Wrapper = RefxWrapper.new(ViscousAcidPuddle, at)
	Wrapper.CreatesForNewPlayers = true
	return Wrapper
end

--//Methods

function ViscousAcidPuddle.OnConstruct(self: Effect)
	self.MaxLifetime = 15
	self.DestroyOnEnd = false
	self.DestroyOnLifecycleEnd = true
end

function ViscousAcidPuddle.OnStart(self: Effect, at: CFrame, ...)
	
	local Puddle = PuddleAsset:Clone()
	
	self.Puddle = Puddle
	
	Puddle.Parent = workspace.Temp
	Puddle:PivotTo(at * CFrame.new(0, 0, 1))
	
	SoundUtility.CreateTemporarySoundAtPosition(
		Puddle.PrimaryPart.Position,
		SoundUtility.Sounds.Instances.Items.Throwable.ViscousAcidPuddle
	)
	
	local StarterPivot = Puddle:GetPivot()
	
	for _, Basepart in ipairs(Puddle:GetDescendants()) do
		
		if Basepart:IsA("PointLight") or Basepart:IsA("SpotLight") then
			
			Basepart.Brightness = 0
			tweenutility.PlayTween(Basepart, TweenInfo.new(1.5), {Brightness = 1.5})
		end
	end
	
	tweenutility.TweenStep(TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), function(time: number)
		
		if not Puddle then
			return
		end
		
		Puddle:PivotTo(StarterPivot:Lerp(at, time))
	end)
end

function ViscousAcidPuddle.OnDestroy(self: Effect)
	
	local Puddle = self.Puddle :: Model
	
	for _, Basepart in ipairs(Puddle:GetDescendants()) do
		
		if not Basepart:IsA("BasePart") then
			
			if Basepart:IsA("PointLight") or Basepart:IsA("SpotLight") then
				tweenutility.PlayTween(Basepart, TweenInfo.new(2), {Brightness = 0})
			
			elseif Basepart:IsA("ParticleEmitter") then
				Basepart.Enabled = false
			end
			
			continue
		end
		
		tweenutility.PlayTween(
			Basepart,
			TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{Transparency = 1, Size = Vector3.zero},
			function()
				if Basepart then
					Basepart:Destroy()
				end
			end
		)
	end
end

--//Return

return {
	new = New,
	locally = ViscousAcidPuddle.locally,
}