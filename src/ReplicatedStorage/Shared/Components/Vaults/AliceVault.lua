--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--//Imports

local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local BaseVault = require(ReplicatedStorage.Shared.Components.Abstract.BaseVault)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)

--// Variables

local EyeAnimationDirection = 1
local AliceVault = BaseComponent.CreateComponent("AliceVault", {
	tag = "AliceVault",
	isAbstract = false,
	defaults = {
		OpenHoldDuration = 3,
		CloseHoldDuration = 1.25,
	},
	
}, BaseVault) :: Impl 

--// Constants

local EYES_LIMIT_ROTATION = 3
local EYES_ANIMATION_VELOCITY = 2

--// Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseVault.MyImpl)),

	OnConstruct: (self: Component, options: SharedComponent.SharedComponentConstructOptions?) -> (),
	OnConstructServer: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
}


export type Fields = {
	Attributes: {
		OpenHoldDuration: number,
		CloseHoldDuration: number,
	},

} & BaseVault.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "AliceVault", Instance, any...>
export type Component = BaseComponent.Component<MyImpl, Fields, "AliceVault", Instance, any...>

--// Methods

function AliceVault.SetEnabled(self: Component, value: boolean)
	BaseVault.SetEnabled(self, value)
	
	self.Interaction.Instance.HoldDuration = value
		and self.Attributes.CloseHoldDuration
		or self.Attributes.OpenHoldDuration
	
	local Text = value and "Block" or "Dispel"
	self.Interaction.Instance.ActionText = Text

	if RunService:IsServer() then
		SoundUtility.CreateTemporarySound(
			SoundUtility.Sounds.Instances.Vaults.Alice:FindFirstChild(value and "Open" or "Close")
		).Parent = self.Instance.Root
		
		self.Interaction:SetTeamAccessibility("Killer", not value)
		self.Interaction:SetTeamAccessibility("Student", value)
		
		TweenUtility.PlayTween(self.OngoingSound, TweenInfo.new(0.5), {Volume = value and 0 or 0.5})
		
	end
	
end

function AliceVault.OnConstructClient(self: Component)
	local Root = self.Instance.Root
	local InitialEyePosition = self.Instance.CoverdAlice.Meshes.Eye.Position :: Vector3
	local InitialEyeBallPosition = self.Instance.CoverdAlice.Meshes.EyeBall.Position :: Vector3
	
	--print(InitialEyePosition)
	
	local function HandleStateChanged(Attribute: string, value: boolean)
		if Attribute ~= "Enabled" then
			return
		end
		
		for _, Part in self.Instance.CoverdAlice.Meshes:GetChildren() do

			TweenUtility.TweenStep(TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.In), function(Time)
				-- applying transparency 
				local Transparency = not value and math.lerp(1, 0, Time) or math.lerp(0, 1, Time)
				Part.Transparency = Transparency
			end)
		end
		
		for _, VFXInstance in self.Instance.CoverdAlice.VFX:GetDescendants() do
			if VFXInstance:IsA("PointLight") then
				TweenUtility.TweenStep(TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), function(Time)
					-- applying Color and Range
					local ColorLight = not value and Color3.fromRGB(255, 52, 11) or Color3.fromRGB(255, 183, 82)
					local Light = not value and Color3.fromRGB(255, 52, 11):Lerp(ColorLight, Time) or Color3.fromRGB(255, 183, 82):Lerp(ColorLight, Time)
					local Range = not value and math.lerp(35, 18, Time) or math.lerp(18, 35, Time)
					
					VFXInstance.Color = Light
					VFXInstance.Range = Range

				end)
				
			elseif VFXInstance:IsA("ParticleEmitter") then
				VFXInstance.Enabled = not value
			end
		end
		
		if not value then
			self.Janitor:Add(RunService.RenderStepped:Connect(function(DeltaTime)
				local Orientation = self.Instance.CoverdAlice.Meshes.Eye.Orientation
				local Angle = math.sin(os.clock() * EYES_ANIMATION_VELOCITY) * EYES_LIMIT_ROTATION
				
				self.Instance.CoverdAlice.Meshes.Eye.Position = InitialEyePosition + Vector3.new(0, math.sin(os.clock()) / 4, 0)
				self.Instance.CoverdAlice.Meshes.Eye.Orientation = Vector3.new(Angle, Orientation.Y, Orientation.Z)
				
				self.Instance.CoverdAlice.Meshes.EyeBall.Position = InitialEyeBallPosition + Vector3.new(0, math.sin(os.clock()) / 2, 0)
			end), nil, "EyeRender")
		else
			if not self.Janitor:Get("EyeRender") then
				return
			end
			
			TweenUtility.PlayTween(self.Instance.CoverdAlice.Meshes.Eye, TweenInfo.new(0.2), {Position = InitialEyePosition})
			TweenUtility.PlayTween(self.Instance.CoverdAlice.Meshes.EyeBall, TweenInfo.new(0.2), {Position = InitialEyeBallPosition})
			
			self.Janitor:Remove("EyeRender")
		end
	end
	
	HandleStateChanged("Enabled", self.Attributes.Enabled)
	self.Janitor:Add(self.Attributes.AttributeChanged:Connect(HandleStateChanged))
end

function AliceVault.OnConstruct(self: Component)
	if RunService:IsServer() then
		self.OngoingSound = SoundUtility.CreateTemporarySoundAtPosition(self.Instance.Root.Position,
			SoundUtility.Sounds.Instances.Vaults.Alice.Ambient
		)
	end
	
	BaseVault.OnConstruct(self)

	self.Instance.Root.Transparency = 1
	self.Instance.Root.RootPoint.Visible = false
	
	-- setup Data
	local PointLight = self.Instance.CoverdAlice.VFX.Effect.Lighting:FindFirstChild("PointLight") :: PointLight
	PointLight.Color = Color3.fromRGB(255, 183, 82)
	PointLight.Range = 18
	
	for _, VFXInstance in self.Instance.CoverdAlice:GetDescendants() do
		if VFXInstance:IsA("BasePart") then
			VFXInstance.Transparency = 1
		end
	end
	
	self.Instance.Root.CanCollide = true
	
	
end

--// Returner

return AliceVault