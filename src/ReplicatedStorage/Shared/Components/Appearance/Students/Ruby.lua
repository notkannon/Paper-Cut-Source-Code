--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local StudentAppearance = require(ReplicatedStorage.Shared.Components.Appearance.Student)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Variables

local RubyAppearance = BaseComponent.CreateComponent("RubyAppearance", {

	isAbstract = false

}, StudentAppearance) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: RubyAppearance.MyImpl)),
}

export type Fields = {

} & RubyAppearance.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "RubyAppearance", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "RubyAppearance", PlayerTypes.Character>

--//Methods

function RubyAppearance.CreateFootstep(self: Component)

	local Sound = StudentAppearance.CreateFootstep(self)

	if not Sound then
		return
	end
	
	Sound.PlaybackSpeed *= 0.85

	local Impact = SoundUtility.CreateTemporarySound(SoundUtility.GetRandomSoundFromDirectory(SoundUtility.Sounds.Players.Footsteps.Robotic))
	Impact.Volume = math.clamp((self.HumanoidRootPart.AssemblyLinearVelocity * Vector3.new(1, 0 ,1)).Magnitude / 24, 0, 1) * 0.5
	Impact.Parent = self.HumanoidRootPart

	return Sound
end

function RubyAppearance.OnConstructServer(self: Component, ...)
	StudentAppearance.OnConstructServer(self, ...)
	
	--blue face on death
	self.Janitor:Add(self.Humanoid.Died:Once(function()
		
		local Face =  self.Instance:FindFirstChild("Face") :: BasePart
		local Light = Face:FindFirstChild("Light"):FindFirstChild("Source") :: PointLight
		local Display = Face:FindFirstChild("Render") :: SurfaceGui
		
		--hiding on original body
		Light.Enabled = false
		Display.Enabled = false
		
		Light.Color = Color3.fromRGB(37, 66, 255)
		
		for _, ImageLabel in ipairs(Display:GetChildren()) do
			
			if not ImageLabel:IsA("ImageLabel") then
				continue
			end
			
			ImageLabel.ImageColor3 = Color3.new(1,1,1)
		end
	end))
end

--//Returner

return RubyAppearance