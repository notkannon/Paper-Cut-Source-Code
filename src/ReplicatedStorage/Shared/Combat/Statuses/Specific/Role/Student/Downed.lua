--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Interaction = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)
local WeaknessStatusEffect = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Student.Weakness)
--local AffectedHumanoidProps = require(ReplicatedStorage.Shared.Combat.Statuses.AffectedHumanoidProps)

local Random = require(ReplicatedStorage.Shared.Utility.Random)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local LightingUtility = require(ReplicatedStorage.Shared.Utility.LightingUtility)

local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes)
local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes)

--//Variables

local UIController
local StatusLightingBlur
local StatusColorCorrection

local DownedStatusTheme = SoundService.Master.Music.Misc.DownedStatusEffect

local Downed = WCS.RegisterStatusEffect("Downed", BaseStatusEffect)

--//Types

export type Status = BaseStatusEffect.BaseStatusEffect & {
	ReviveInteraction: Interaction.Component,
}

--//Functions

local function GetAmbientForStatus(): { Blur: BlurEffect, ColorCorrection: ColorCorrectionEffect }
	local Blur = Lighting:FindFirstChild("DownedStatusEffectBlur")
	local ColorCorrection = Lighting:FindFirstChild("DownedStatusEffectColorCorrection")

	if not (Blur and ColorCorrection) then
		
		ColorCorrection = LightingUtility.ApplyColorCorrectionEffect({Name = "DownedStatusEffectColorCorrection"})
		Blur = LightingUtility.ApplyBlurEffect({Name = "DownedStatusEffectBlur", Size = 0})
	end

	return {
		Blur = Blur,
		ColorCorrection = ColorCorrection
	}
end

--//Methods

function Downed.GetLinearVelocity(self: Status)
	return (self.Character.Instance :: PlayerTypes.Character).HumanoidRootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
end

function Downed.OnStartClient(self: Status)
	TweenUtility.ClearAllTweens(DownedStatusTheme)
	
	--Classes.GetSingleton("CameraController").LockedToHead = true
	
	self.Character.Humanoid.HipHeight = .1
	
	DownedStatusTheme:Play()
	DownedStatusTheme.Volume = 1
	DownedStatusTheme.PlaybackSpeed = 1

	-- visuals
	local AnimationTracks: { string: AnimationTrack } = self.AnimationTracks
	local GameplayFrame: Frame = UIController.Instance.Screen.Gameplay
	local DangerImage: ImageLabel = GameplayFrame.Danger
	local BloodImage: ImageLabel = GameplayFrame.Blood
	
	TweenUtility.PlayTween(DangerImage, TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {ImageTransparency = .5})
	TweenUtility.PlayTween(BloodImage, TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {ImageTransparency = 0})
	TweenUtility.PlayTween(StatusColorCorrection, TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {
		TintColor = StatusColorCorrection.TintColor:lerp(Color3.fromRGB(165, 46, 46), 1),
		Saturation = -.5,
		Contrast = -.3
	})
	
	self.GenericJanitor:Add(RunService.Heartbeat:Connect(function(_, delta)
		local Magnitude = self:GetLinearVelocity().Magnitude
		local WalkSpeed = self.Character.Humanoid.WalkSpeed

		if self.Character.Humanoid.MoveDirection.Magnitude == 0 and not AnimationTracks.Idle.IsPlaying then

			AnimationTracks.Idle:Play(.5)
			AnimationTracks.Movement:Stop(.5)

		elseif self.Character.Humanoid.MoveDirection.Magnitude > 0 and not AnimationTracks.Movement.IsPlaying then

			AnimationTracks.Movement:Play(.5)
			AnimationTracks.Idle:Stop(.5)
		end
		
		AnimationTracks.Movement:AdjustSpeed(Magnitude / WalkSpeed * .7)
	end))
	
	-- screen shake connection
	self.GenericJanitor:Add(RunService.RenderStepped:Connect(function()
		DangerImage.ImageTransparency = MathUtility.QuickLerp(DangerImage.ImageTransparency, math.sin(os.clock() * 2.5), 1/3) 
		DangerImage.Rotation = Random:NextNumber(-3, 3)
		DangerImage.Position = UDim2.fromScale(.5, .5) + UDim2.fromOffset(
			Random:NextNumber() * 15,
			Random:NextNumber() * 15
		)
		
		GameplayFrame.Rotation = Random:NextNumber(-3, 3)
		GameplayFrame.Position = UDim2.fromScale(.5, .5) + UDim2.fromOffset(
			Random:NextNumber() * 15,
			Random:NextNumber() * 15
		)
	end))
end

function Downed.OnEndClient(self: Status)    
	self.GenericJanitor:Cleanup()
	
	self.Character.Humanoid.HipHeight = 0
	
	--Classes.GetSingleton("CameraController").LockedToHead = false
	
	for _, AnimationTrack: AnimationTrack in pairs(self.AnimationTracks) do
		AnimationTrack:Stop(.5)
	end
	
	-- visuals
	local GameplayFrame: Frame = UIController.Instance.Screen.Gameplay -- replaced temporary
	local DangerImage: ImageLabel = GameplayFrame.Danger
	local BloodImage: ImageLabel = GameplayFrame.Blood

	TweenUtility.PlayTween(DownedStatusTheme, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Volume = 0})

	GameplayFrame:TweenPosition(UDim2.fromScale(.5, .5), "Out", "Sine", .3, true)
	TweenUtility.PlayTween(GameplayFrame, TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Rotation = 0})
	TweenUtility.PlayTween(DangerImage, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {ImageTransparency = 1})
	TweenUtility.PlayTween(BloodImage, TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {ImageTransparency = 1})
	TweenUtility.PlayTween(StatusColorCorrection, TweenInfo.new(3, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {
		TintColor = Color3.fromRGB(255, 255, 255),
		Saturation = 0,
		Contrast = 0
	})
end

function Downed.OnConstructClient(self: Status)
	BaseStatusEffect.OnConstructClient(self)
	
	self.ReviveInteraction = ComponentsManager.Await(self.Character.Instance.HumanoidRootPart:WaitForChild("ReviveInteraction"), Interaction)
	
	UIController = Classes.GetSingleton("UIController")
	
	local Ambient = GetAmbientForStatus()
	StatusLightingBlur = Ambient.Blur
	StatusColorCorrection = Ambient.ColorCorrection
	
	local Animator: Animator = self.Character.Humanoid:FindFirstChildOfClass('Animator')
	
	self.AnimationTracks = {
		Idle = Animator:LoadAnimation(self.FromRoleData.Animations.Idle),
		Movement = Animator:LoadAnimation(self.FromRoleData.Animations.Movement)
	}
end

function Downed.OnStartServer(self: Status)
	self.HumanoidAffectStatus:Start()
	self.ReviveInteraction:SetEnabled(true)
end

function Downed.OnEndServer(self: Status)
	self.HumanoidAffectStatus:End()
	self.ReviveInteraction:SetEnabled(false)
	
	local Weakness = self.Character:GetAllStatusEffectsOfType(WeaknessStatusEffect)[1]
	if not Weakness then
		return
	end
	
	Weakness:Start()
end

function Downed.OnConstructServer(self: Status)
	self.HumanoidAffectStatus = AffectedHumanoidProps.new(self.Character, {
		WalkSpeed = { 3.6, "Set" },
		AutoRotate = { false, "Set" },
	})
	
	self.HumanoidAffectStatus.DestroyOnEnd = false
	
	self.GenericJanitor:Add(self.Character.Humanoid.HealthChanged:Connect(function(health: number)
		if health > 15 then
			self:End()

		elseif health > 0 then
			if WCSUtility.HasActiveStatusEffectsWithNames(self.Character, {"Weakness"}) then
				return
			end
			
			self:Start()
		end
	end))
	
	-- revive interaction initial
	local ProximityPrompt = Instance.new("ProximityPrompt")
	ProximityPrompt.Name = "ReviveInteraction"
	ProximityPrompt.Parent = self.Character.Instance.HumanoidRootPart
	ProximityPrompt.Enabled = false
	ProximityPrompt.ActionText = "Revive"
	ProximityPrompt.ObjectText = "Revive this player"
	ProximityPrompt.HoldDuration = 10

	self.ReviveInteraction = ComponentsManager.Add(ProximityPrompt, Interaction)
	self.ReviveInteraction:SetEnabled(false)
	self.ReviveInteraction:SetFilteringType("Include")
	self.ReviveInteraction:SetTeamAccessibility("Student", true)

	self.GenericJanitor:Add(self.ReviveInteraction, "Destroy")
	self.GenericJanitor:Add(self.ReviveInteraction.Started:Connect(function(playerWhoRevived: Player)
		if not self:GetState().IsActive then
			return
		end
		
		self:End()
	end))
end

function Downed.OnConstruct(self: Status)
	BaseStatusEffect.OnConstruct(self)
	
	self.DestroyOnEnd = false
end

--//Returner

return Downed