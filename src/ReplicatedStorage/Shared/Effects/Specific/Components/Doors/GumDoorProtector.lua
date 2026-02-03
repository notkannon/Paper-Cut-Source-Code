--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local EffectUtility = require(ReplicatedStorage.Shared.Utility.EffectsUtility)

local RefxWrapper = RunService:IsServer() and require(ServerScriptService.Server.Classes.RefxWrapper) or nil

--//Variables

local GumCellAsset = ReplicatedStorage.Assets.Doors.Protectors.GumCell
local DoorGumBarrier = Refx.CreateEffect("DoorGumBarrier") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {
	Janitor: Janitor.Janitor,
	Instance: BasePart?,
}

export type Impl = Refx.EffectImpl<MyImpl, Fields, BasePart>
export type Effect = Refx.Effect<MyImpl, Fields, BasePart>

--//Functions

local function New(instance: BasePart): Effect
	local Wrapper = RefxWrapper.new(DoorGumBarrier, instance)
	Wrapper.CreatesForNewPlayers = true
	return Wrapper
end

--//Methods

function DoorGumBarrier.OnConstruct(self: Effect)
	self.DestroyOnEnd = false
	self.DisableLeakWarning = true
	self.DestroyOnLifecycleEnd = false
end

function DoorGumBarrier.OnStart(self: Effect, instance: BasePart)
	self.Janitor = Janitor.new()
	self.Instance = instance
	
	local Cell = self.Janitor:Add(GumCellAsset:Clone())
	Cell.Parent = workspace.Temp
	Cell:PivotTo(instance:GetPivot())
	
	SoundUtility.CreateTemporarySoundAtPosition(
		instance:GetPivot().Position,
		SoundUtility.Sounds.Instances.Items.Misc.Gum.Use
	)
	
	SoundUtility.CreateTemporarySoundAtPosition(
		instance:GetPivot().Position,
		SoundUtility.Sounds.Instances.Items.Misc.Gum.Use2
	)
	
	for _, Part in ipairs(Cell:GetChildren()) do
		
		if not Part:IsA("BasePart") then
			continue
		end
		
		--resizing
		Part.Size = Vector3.new(
			instance:FindFirstChild("Root").Size.X,
			Part.Size.Y,
			Part.Size.Z	
		)
		
		if Part:IsA("MeshPart") then
			
			local StarterSize = Part.Size
			Part.Size *= Vector3.new(1, 1, 1.5)
			Part.Transparency = 1
			
			TweenUtility.PlayTween(Part, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
				Transparency = 0,
			})
			
			TweenUtility.PlayTween(Part, TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
				Size = StarterSize,
			})
		end
	end
end

function DoorGumBarrier.OnDestroy(self: Effect)
	self.Janitor:Destroy()
end

--//Return

return {
	new = New,
	locally = DoorGumBarrier.locally,
}