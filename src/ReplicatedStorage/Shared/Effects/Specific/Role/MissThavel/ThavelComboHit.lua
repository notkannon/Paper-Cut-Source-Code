--//Services

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local Utility = require(ReplicatedStorage.Shared.Utility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local EffectUtility = require(ReplicatedStorage.Shared.Utility.EffectsUtility)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local MatchStateClient = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.MatchStateClient) or nil
local HighlightPlayerEffect = require(ReplicatedStorage.Shared.Effects.HighlightPlayer)

--//Variables

local LocalPlayer = Players.LocalPlayer
local ThavelComboHit = Refx.CreateEffect("ThavelComboHit") :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {
}

export type Impl = Refx.EffectImpl<MyImpl, Fields, { PlayerTypes.Character }>
export type Effect = Refx.Effect<MyImpl, Fields, { PlayerTypes.Character }>

--//Methods

function ThavelComboHit.OnConstruct(self: Effect)
	self.DestroyOnEnd = true
end

function ThavelComboHit.OnStart(self: Effect, hit: { PlayerTypes.Character })
	
	-- migrated to Utility.ApplyParams -YSH
	local Correction = Utility.ApplyParams(Instance.new("ColorCorrectionEffect"), {
		Parent = Lighting,
		Contrast = -2,
		Saturation = 0.3,
		Brightness = -0.5,
		TintColor = Color3.fromRGB(255, 70, 70),
	})
	
	--gettin passive component
	local ProgressivePunishment = ComponentsManager.Get(LocalPlayer.Character, "ProgressivePunishmentPassive")

	TweenUtility.PlayTween(Correction, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		
		Contrast = 0,
		Saturation = 0,
		Brightness = 0,

	}, function(state)
		if not Correction then
			return
		end

		Correction:Destroy()
	end)
	
	--players highlighting
	for _, Player in ipairs(Players:GetPlayers()) do

		if not Player.Character
			or table.find(hit, Player.Character)
			or Player.Character == LocalPlayer.Character
			or not RolesManager:IsPlayerStudent(Player) then

			continue
		end

		local HumanoidRootPart = Player.Character:FindFirstChild("HumanoidRootPart") :: BasePart

		if not HumanoidRootPart then
			return
		end
		
		local Distance = (HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

		local EffectProxy = HighlightPlayerEffect.locally(Player.Character, {
				
				mode = "Overlay",
				color = Color3.fromRGB(222, 77, 77),
				lifetime = 15,
				fadeOutTime = 2.5,
				transparency = math.clamp(Distance / 250, 0.25, 0.8),
				respectTargetTransparency = true,
			}
		)
		
		--when combo ends we shall remove all highlights immediately
		EffectProxy.Janitor:Add(ProgressivePunishment.Changed:Connect(function(combo: number)
			if combo == 0 and not EffectProxy.IsDestroyed then
				EffectProxy:Destroy()
			end
		end))
	end
end

--//Return

return ThavelComboHit