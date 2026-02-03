--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil

local Refx = require(ReplicatedStorage.Packages.Refx)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundsUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local EffectUtility = require(ReplicatedStorage.Shared.Utility.EffectsUtility)

local RefxWrapper = RunService:IsServer() and require(ServerScriptService.Server.Classes.RefxWrapper) or nil

--//Variables

local TestPaper = Refx.CreateEffect("TestPaper") :: Impl

--//Constants

local POINTLIGHT_COLORS = {
	Success = Color3.fromRGB(157, 255, 201),
	Failded = Color3.fromRGB(255, 153, 139)
}

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

local function New(instance: BasePart)
	local Wrapper = RefxWrapper.new(TestPaper, instance)
	Wrapper.CreatesForNewPlayers = true
	return Wrapper
end

--//Methods

function TestPaper.OnConstruct(self: Effect)
	self.DestroyOnEnd = false
	self.DisableLeakWarning = true
	self.DestroyOnLifecycleEnd = false
end

function TestPaper.MarkFailed(self: Effect)
	
	local PointLight = self.Instance:FindFirstChildWhichIsA("PointLight")
	local Label = ReplicatedStorage.Assets.UI.Objectives.FailedTestPaper:Clone()
	PointLight.Color = POINTLIGHT_COLORS.Failded
	Label.Parent = self.Instance
	
	SoundsUtility.CreateTemporarySoundAtPosition(
		self.Instance.Position,
		SoundsUtility.Sounds.UI.Objectives.Failed
	)
	
	TweenUtility.PlayTween(PointLight, TweenInfo.new(5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Color = POINTLIGHT_COLORS.Success}, nil, 1)
	
	for _, ImageLabel: ImageLabel in ipairs(Label:GetDescendants()) do
		
		if not ImageLabel:IsA("ImageLabel") then
			continue
		end
		
		TweenUtility.PlayTween(ImageLabel, TweenInfo.new(7, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {ImageTransparency = 1}, nil, 3)
	end
	
end

function TestPaper.MarkSolved(self: Effect)
	local PointLight = self.Instance:FindFirstChildWhichIsA("PointLight")
	TweenUtility.PlayTween(PointLight, TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Range = 0,
		Brightness = 0
	}, nil, 0.2)
	
	TweenUtility.PlayTween(self.Instance, TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = CFrame.Angles(0, 90, 0),
		Transparency = 1,
	})
	
	for _, PaperDecal: Decal in ipairs(self.Instance:GetChildren()) do
		if not PaperDecal:IsA("Decal") then
			continue
		end
		
		TweenUtility.PlayTween(PaperDecal, TweenInfo.new(3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Transparency = 1
		})
	end
end


function TestPaper.OnStart(self: Effect, instance: BasePart)
	self.Janitor = Janitor.new()
	self.Instance = instance

	local PointLight = Instance.new("PointLight")
	PointLight.Parent = instance
	PointLight.Color = POINTLIGHT_COLORS.Success
	PointLight.Range = 10
	PointLight.Shadows = true
	PointLight.Brightness = 0.35
	
	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.Temp, workspace.Characters, instance}
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.RespectCanCollide = true
	
	local Result = workspace:Raycast(instance.Position, Vector3.new(0, -100, 0), Params)
	local InitialPose = (Result and Result.Position or instance.Position) + Vector3.new(0, 1.7, 0)
	
	self.Janitor:LinkToInstance(instance)
	self.Janitor:Add(RunService.RenderStepped:Connect(function()
		
		instance.Position = InitialPose + Vector3.new(0, math.sin(os.clock()) / 2, 0)
		instance.CFrame *= CFrame.Angles(0, 1/100, 0)
		
	end), nil, "AnimationSteps")
	
	self.Janitor:Add(ClientRemotes.MatchServiceStartLMS.On(function(v)
		self:MarkSolved()
	end))
end

function TestPaper.OnDestroy(self: Effect)
	self.Janitor:Destroy()
end

--//Return

return {
	new = New,
	locally = TestPaper.locally,
}