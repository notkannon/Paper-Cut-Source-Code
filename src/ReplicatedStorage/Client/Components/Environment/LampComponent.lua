--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Janitor = require(ReplicatedStorage.Packages.Janitor)

local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local ClientLamp = BaseComponent.CreateComponent("ClientLamp") :: Impl

--//Types

type LightData = {} & (PointLight | SpotLight)
type LampInstance = typeof(workspace.Map.Lighting.Lamp)

export type MyImpl = {
	__index: MyImpl,
	
	SetEnabled: (self: Component, enabled: boolean, force: boolean?) -> (),
	ApplyBrighness: (self: Component, brightness: number, tweenInfo: boolean?) -> (),
}

export type Fields = {
	Instance: LampInstance,
	Beam: Beam?,
	Source: BasePart,
	Lights: {[PointLight | SpotLight]: LightData},
	
	Enabled: boolean,
	Janitor: Janitor.Janitor,
	
	_DestinatedBrightness: number,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ClientLamp", LampInstance, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "ClientLamp", LampInstance, {}>

--//Methods

function ClientLamp.ApplyBrighness(self: Component, brightness: number, tweenInfo: boolean?)
	self.Janitor:Cleanup()
	
	for Light, Default in pairs(self.Lights) do
		self._DestinatedBrightness = brightness
		
		if not tweenInfo then
			continue
		end
		
		local DestinatedBrightness = Default.Brightness * brightness
		
		self.Janitor:Add(TweenUtility.TweenStep(tweenInfo, function(value: number)
			Light.Brightness = MathUtility.QuickLerp(Light.Brightness, DestinatedBrightness, value)
		end))
	end
	
	local DestinatedColor = Color3.fromHSV(1, 0, brightness * 0.6)
	TweenUtility.PlayTween(self.Source, tweenInfo or TweenInfo.new(0.1), {Color = DestinatedColor})
end

function ClientLamp.SetEnabled(self: Component, enabled: boolean, force: boolean?)
	for Light, Default in pairs(self.Lights) do
		self.Janitor:Add(TweenUtility.PlayTween(Light, TweenInfo.new(4), {
			Brightness = Default.Brightness * (enabled and 1 or 0)
		} :: PointLight), "Cancel")
	end
	
	if not self.Beam then
		print(self.Instance)
	end
	
	self.Beam.Enabled = enabled
	
	if enabled then
		self.Source.Material = Enum.Material.Neon
		
		if force then
			self.Source.Color = Color3.fromHSV(1, 0, self._DestinatedBrightness * 0.6)
			return
		end
		
		--SoundUtility.CreateTemporarySound(
		--	SoundUtility.Sounds.Instances.Lamps.CeilingLamp.On
		--).Parent = self.Source
		
		self.Source.Color = Color3.fromHSV(1, 0, .3)
		
		TweenUtility.PlayTween(self.Source, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Color = Color3.fromHSV(1, 0, self._DestinatedBrightness * 0.6)
		})
	else
		if force then
			self.Source.Color = Color3.fromHSV(1, 0, 0.6)
			self.Source.Material = Enum.Material.SmoothPlastic
			
			return
		end
		
		--SoundUtility.CreateTemporarySound(
		--	SoundUtility.Sounds.Instances.Lamps.CeilingLamp.On
		--).Parent = self.Source
		
		TweenUtility.PlayTween(self.Source, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Color = Color3.fromHSV(1, 0, 0.1)
		}, function(status)
			if status == Enum.TweenStatus.Canceled then
				return
			end
			
			self.Source.Color = Color3.fromHSV(1, 0, 0.6)
			self.Source.Material = Enum.Material.SmoothPlastic
		end)
	end
end

function ClientLamp.OnConstructClient(self: Component)
	self.Lights = {}
	self.Enabled = false
	self.Janitor = Janitor.new()
	self._DestinatedBrightness = 1
	
	self.Source = self.Instance:FindFirstChild("Source")
	self.Beam = self.Source:FindFirstChildWhichIsA("Beam")
	
	for _, Light in ipairs(self.Source:GetDescendants()) do
		if not (Light:IsA("PointLight") or Light:IsA("SpotLight")) then
			continue
		end
		
		self.Lights[Light] = {
			Range = Light.Range,
			Enabled = Light.Enabled,
			Brightness = Light.Brightness,
		}
	end
end

--//Returner

return ClientLamp