--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Utility = require(ReplicatedStorage.Shared.Utility)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local EnumUtility = require(ReplicatedStorage.Shared.Utility.EnumUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local PlayerHighlight = Refx.CreateEffect("PlayerHighlight") :: Impl

--//Types

type HighlightOptions = {
	
	lifetime: number?,
	fadeInTime: number?,
	fadeOutTime: number?,
	
	mode: "Occluded" | "Overlay",
	color: Color3?,
	transparency: number?,
	outlineColor: Color3?,
	outlineTransparency: number?,
	
	-- TODO: разрешить использовать одновременно проверку дистанции и прозрачности (несколько HandleShouldEnable)
	respectTargetTransparency: boolean?,
	
	minDistance: number?,
	maxDistance: number?,
	measureDistanceFrom: Model?
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

--//Methods

function PlayerHighlight.OnConstruct(self: Effect, _, options: HighlightOptions)
	
	self.Janitor = Janitor.new()
	self.DisableLeakWarning = true
	
	self.MaxLifetime = (options.lifetime or 0) + (options.lifetime and options.fadeInTime or 0)
	self.DestroyOnEnd = not options.lifetime and not options.fadeInTime
	self.DestroyOnLifecycleEnd = typeof(options.lifetime) == "number"
	
	--debugging
	if RunService:IsStudio() then
		print(`\n\nMaxLifetime: { self.MaxLifetime }\nDestroyOnEnd: { self.DestroyOnEnd }\nDestroyOnLifecycleEnd: { self.DestroyOnLifecycleEnd }\n\n`)
	end
end

function PlayerHighlight.OnStart(
	self: Effect,
	target: Model,
	options: HighlightOptions?
)
	local Highlight = self.Janitor:Add(Instance.new("Highlight"), nil, "Instance")
	
	local FadeOutDebounce = false
	local function HandleShouldEnable(shouldEnable: boolean)
		if shouldEnable and not self.Instance.Enabled then

			self.Instance.Enabled = true

			if options.fadeInTime then

				Highlight.FillTransparency = 1

				TweenUtility.PlayTween(Highlight, TweenInfo.new(options.fadeInTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
					FillTransparency = options.transparency,
				})

			end

		elseif not shouldEnable and self.Instance.Enabled then

			if options.fadeOutTime  then

				if FadeOutDebounce then
					return
				end

				FadeOutDebounce = true

				TweenUtility.PlayTween(self.Instance, TweenInfo.new(options.fadeOutTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {

					FillTransparency = 1,
					OutlineTransparency = 1,

				} :: Highlight, function()

					if not self.Instance then
						return
					end

					FadeOutDebounce = false
					self.Instance.Enabled = false

				end)
			else
				self.Instance.Enabled = false
			end

		end
	end
	
	self.Instance = Highlight
	
	Utility.ApplyParams(Highlight, {
		
		Parent = target,
		Adornee = target,
		Enabled = true,
		DepthMode = options.mode == "Occluded" and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop,
		FillColor = options.color or Color3.new(1, 1, 1),
		OutlineColor = options.outlineColor or Color3.new(1, 1, 1),
		FillTransparency = options.transparency or 0,
		OutlineTransparency = options.outlineTransparency or 1,
		
	} :: Highlight)
	
	
	
	if options.respectTargetTransparency then
		-- смотрим за изменениями прозрачности
		local TransparencyThreshold = 0.1
		
		Highlight.Enabled = (target:GetAttribute("DestinatedTransparency") or 0) <= TransparencyThreshold
		
		self.Janitor:Add(target:GetAttributeChangedSignal("DestinatedTransparency"):Connect(function()
			
			if not self.Instance then
				return
			end
			
			local ShouldEnable = (target:GetAttribute("DestinatedTransparency") or 0) <= TransparencyThreshold
			HandleShouldEnable(ShouldEnable)
		end))
		
	end
	
	if options.fadeInTime then
		
		Highlight.FillTransparency = 1
		
		TweenUtility.PlayTween(Highlight, TweenInfo.new(options.fadeInTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			FillTransparency = options.transparency,
		})
	end
	
	if options.measureDistanceFrom and (options.minDistance or options.maxDistance) then
		-- следим за измененииями в расстоянии
		local function Update()
			local p1 = target.PrimaryPart
			local p2 = options.measureDistanceFrom.PrimaryPart
			
			if not p1 or not p2 then
				return
			end
			
			local dist = (p2.Position - p1.Position).Magnitude
			local ShouldEnable = true
			
			if options.minDistance and dist < options.minDistance then ShouldEnable = false
			elseif options.maxDistance and dist > options.maxDistance then ShouldEnable = false end
			HandleShouldEnable(ShouldEnable)
		end
		
		self.Janitor:Add(target.PrimaryPart:GetPropertyChangedSignal("Position"):Connect(Update))
		self.Janitor:Add(options.measureDistanceFrom.PrimaryPart:GetPropertyChangedSignal("Position"):Connect(Update))
	end
end

function PlayerHighlight.OnDestroy(self: Effect)

	local options = self.Configuration[2] :: HighlightOptions
	
	if options.fadeOutTime and self.Instance then
		
		self.Janitor:RemoveNoClean("Instance")

		TweenUtility.PlayTween(self.Instance, TweenInfo.new(options.fadeOutTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			
			FillTransparency = 1,
			OutlineTransparency = 1,
			
		} :: Highlight, function()
			
			if not self.Instance then
				return
			end
			
			self.Instance:Destroy()
		end)
	end
	
	self.Janitor:Destroy()
end

--//Returner

return PlayerHighlight