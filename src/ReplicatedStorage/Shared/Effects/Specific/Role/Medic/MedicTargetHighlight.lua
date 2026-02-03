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

local HighlightPlayerEffect = require(ReplicatedStorage.Shared.Effects.HighlightPlayer)

--//Variables

local LocalPlayer = Players.LocalPlayer
local MedicTargetHighlight = Refx.CreateEffect("MedicTargetHighlight") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {
	Player: Player,
	Janitor: Janitor.Janitor,
	Instance: PlayerTypes.Character,
}

export type Impl = Refx.EffectImpl<MyImpl, Fields, PlayerTypes.Character>
export type Effect = Refx.Effect<MyImpl, Fields, PlayerTypes.Character>

--//Methods

function MedicTargetHighlight.OnConstruct(self: Effect, character: PlayerTypes.Character)
	self.DestroyOnEnd = false
	self.DisableLeakWarning = true
	self.DestroyOnLifecycleEnd = false
end

function MedicTargetHighlight.OnStart(self: Effect, character: PlayerTypes.Character)
	
	self.Janitor = Janitor.new()
	self.Player = Players:GetPlayerFromCharacter(character)
	self.Instance = character
	
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Players.Signals.Injure
	).Parent = character.PrimaryPart
	
	local Humanoid = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	local Indicator = ReplicatedStorage.Assets.UI.Billboards.InjureTracker:Clone()
	Indicator.Parent = LocalPlayer.PlayerGui
	Indicator.Adornee = Humanoid.RootPart
	
	local Icon = Indicator:FindFirstChild("Icon")
	local Glow = Indicator:FindFirstChild("Glow")
	
	local IconStarterColor = Icon.ImageColor3
	local GlowStarterColor = Glow.ImageColor3
	
	Glow.ImageColor3 = Color3.new(1, 1, 1)
	Icon.ImageColor3 = Color3.new(1, 1, 1)
	
	TweenUtility.PlayTween(Icon, TweenInfo.new(1), { ImageColor3 = IconStarterColor } :: ImageLabel)
	TweenUtility.PlayTween(Glow, TweenInfo.new(1), { ImageColor3 = GlowStarterColor } :: ImageLabel)
	
	--hiding indicator
	self.Janitor:Add(function()
		
		TweenUtility.PlayTween(Icon, TweenInfo.new(1), { ImageTransparency = 1 } :: ImageLabel)
		TweenUtility.PlayTween(Glow, TweenInfo.new(1), { ImageTransparency = 1 } :: ImageLabel, function()
			
			if not Indicator then
				return
			end
			
			Indicator:Destroy()
		end)
	end)
	
	--shaking & glowing
	self.Janitor:Add(RunService.RenderStepped:Connect(function()
		
		local t = os.clock()
		local alpha = Humanoid.Health / Humanoid.MaxHealth
		
		Glow.ImageTransparency = math.sin(t * 2) * 0.5 + 0.5
		Icon.Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(
			math.random(-10, 10) * alpha * 1.5,
			math.random(- 10, 10) * alpha * 1.5
		)
	end))
	
	--highlighting player
	HighlightPlayerEffect.locally(character, {
		
		lifetime = 0, -- flash
		fadeInTime = 0,
		fadeOutTime = 1,
		
		transparency = 1,
		outlineColor = Color3.fromRGB(255, 92, 92),
		outlineTransparency = 0,
	})
end

function MedicTargetHighlight.OnDestroy(self: Effect)
	
	self.Janitor:Destroy()
	
	self.Player = nil
	self.Instance = nil
end

--//Return

return MedicTargetHighlight