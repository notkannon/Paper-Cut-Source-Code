--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Utility = require(ReplicatedStorage.Shared.Utility)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local EnumUtility = require(ReplicatedStorage.Shared.Utility.EnumUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local TableKit = require(ReplicatedStorage.Packages.TableKit)

local RefxWrapper = RunService:IsServer() and require(ServerScriptService.Server.Classes.RefxWrapper) or nil

--//Variables

local ItemHighlight = Refx.CreateEffect("ItemHighlight") :: Impl
local Player = Players.LocalPlayer

local ParticleEmitter = ReplicatedStorage.Assets.Items.Related.ItemHighlight.ParticleEmitter


local DefaultOptions : HighlightOptions = {
	--mode = "Occluded",
	--outlineColor = Color3.new(1, 1, 1),
	--outlineTransparency = 0.75,
	--maxDistance = 50,
	--minDistance = 10,
	--fadeInTime = 0.5,
	--fadeOutTime = 0.5,
	--transparency = 1,
	
	pointlightRange = 5,
	pointlightBrightness = 0.5,
	pointlightColor = Color3.new(0.25098, 0.54902, 1)
}

--//Types

type HighlightOptions = {
	
	--lifetime: number?,
	--fadeInTime: number?,
	--fadeOutTime: number?,
	
	--mode: "Occluded" | "Overlay",
	--color: Color3?,
	--transparency: number?,
	--outlineColor: Color3?,
	--outlineTransparency: number?,
	
	--minDistance: number?,
	--maxDistance: number?,
	--measureDistanceFrom: Model?,
	
	pointlightBrightness: number?,
	pointlightRange: number?,
	pointlightColor: Color3?
}

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {
	Janitor: Janitor.Janitor,
	Instance: Highlight,
}

export type Impl = Refx.EffectImpl<MyImpl, Fields, Model, HighlightOptions>
export type Effect = Refx.Effect<MyImpl, Fields, Model, HighlightOptions>

--//Functions

local function New(instance: BasePart)
	local Wrapper = RefxWrapper.new(ItemHighlight, instance)
	Wrapper.CreatesForNewPlayers = true
	return Wrapper
end

--//Methods

function ItemHighlight.OnConstruct(self: Effect, target: Tool, options: HighlightOptions)

	if not options then
		options = TableKit.DeepCopy(DefaultOptions) :: HighlightOptions
	end
	self.Janitor = Janitor.new()
	self.DisableLeakWarning = true
	self.Instance = target
	self.MaxLifetime = 999999
	self.DestroyOnEnd = false
	self.DestroyOnLifecycleEnd = false
	self.Options = options
end

function ItemHighlight.OnStart(self: Effect, ...)
	local PointLight = self.Janitor:Add(Instance.new("PointLight"), nil, "PointLight")

	local target = self.Instance:FindFirstChildWhichIsA("BasePart")
	local options = self.Options

	self.PointLight = PointLight
	
	Utility.ApplyParams(PointLight, {
		Parent = target,
		Color = options.pointlightColor or Color3.new(1, 1, 1),
		Range = options.pointlightRange or 0,
		Brightness = options.pointlightBrightness or 0
	})
	
	local Emitter : ParticleEmitter = self.Janitor:Add(ParticleEmitter:Clone())
	Emitter.Parent = target
end

function ItemHighlight.OnDestroy(self: Effect)

	local options = self.Configuration[2] :: HighlightOptions

	self.Janitor:Destroy()
end

--//Returner

return {
	new = New,
	locally = ItemHighlight.locally
}