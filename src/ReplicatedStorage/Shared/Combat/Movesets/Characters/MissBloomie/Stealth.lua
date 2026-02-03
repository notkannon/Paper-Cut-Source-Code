--//Services

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local StealthEffect = require(ReplicatedStorage.Shared.Effects.Specific.Role.MissBloomie.Stealth)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local Utility = require(ReplicatedStorage.Shared.Utility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local MusicUtility = RunService:IsClient() and require(ReplicatedStorage.Client.Utility.MusicUtility) or nil

local BaseHoldableSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseHoldableSkill)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)
local SneakAttackingStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.MissBloomie.SneakAttacking)
local ModifiedStaminaGainStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedStaminaGain)
--local AffectedHumanoidProps = require(ReplicatedStorage.Shared.Combat.Statuses.AffectedHumanoidProps)

--//Variables

local ColorCorrection
local SkillAssets = ReplicatedStorage.Assets.Skills.Stealth
local Stealth = WCS.RegisterHoldableSkill("Stealth", BaseHoldableSkill)

--//Types

export type Skill = BaseHoldableSkill.BaseHoldableSkill

--//Functions

local function InitColorCorrection() : ColorCorrectionEffect
	
	local ColorCorrection = Lighting:FindFirstChild("_StealthColorCorrection")
	
	if not ColorCorrection then
		
		-- migrated to Utility.ApplyParams as YSH recommended -Provitia
		ColorCorrection = Utility.ApplyParams(SkillAssets.StealthColorCorrection:Clone() :: ColorCorrectionEffect, {
			Parent = Lighting,
			Name = "_StealthColorCorrection",
		
			Contrast = 0,
			Brightness = 0,
			Saturation = 0
		})
	end
	
	return ColorCorrection
end

--//Methods

function Stealth.OnStartServer(self: Skill)
	
	local Appearance = ComponentsManager.GetFirstComponentInstanceOf(self.Character.Instance, "BaseAppearance")
	
	self.Janitor:Add(StealthEffect.new(self.Character.Instance), "Destroy", "Effect")
	self.Janitor:Get("Effect"):Start(Players:GetPlayers())
	
	Appearance:ApplyTransparency(0.97)
	Appearance.Attributes.FootstepVolumeScale = 0.02
	
	self.Janitor:Add(task.delay(self.FromRoleData.SneakAttackDelay, self.Status.Start, self.Status))
	
	self.StartTimestamp = os.clock()

end

function Stealth.OnEndServer(self: Skill)
	
	if self.Status:GetState().IsActive then
		self.Status:End()
		
		
	end
	
	local Appearance = ComponentsManager.GetFirstComponentInstanceOf(self.Character.Instance, "BaseAppearance")
	
	Appearance:ApplyTransparency(0)
	Appearance.Attributes.FootstepVolumeScale = 1
	
	ModifiedSpeedStatus.new(self.Character, "Multiply", self.FromRoleData.EndSpeedMultiplier, {
		
		Style = Enum.EasingStyle.Cubic,
		Priority = 5,
		FadeOutTime = 3,
		Tag = "StealthBoost",
		
	}):Start(self.FromRoleData.EndBoostDuration)
	
	self:ApplyCooldown(self.FromRoleData.Cooldown)
	
	if (os.clock() - self.StartTimestamp) >= (0.95 * self.FromRoleData.Duration) then
		local ProxyService = Classes.GetSingleton("ProxyService")
		ProxyService:AddProxy("StealthBloomieNaturalEnd"):Fire(self.Player)
	end
end

function Stealth.OnStartClient(self: Skill)
	
	local UIController = Classes.GetSingleton("UIController")
	self.StealthStatus = ModifiedSpeedStatus.new(self.Character, "Set", self.FromRoleData.WalkSpeed, {Tag = "Stealth", Priority = 5})
	self.StealthStatus:Start()
	
	self.StaminaGainStatus = ModifiedStaminaGainStatus.new(self.Character, "Multiply", self.FromRoleData.StaminaGainMultiplier, {Tag = "StealthReducedStaminaGain"})
	self.StaminaGainStatus:Start()
	
	MusicUtility.Music.Misc.StealthLoop:Play()
	
	TweenUtility.ClearAllTweens(ColorCorrection)
	TweenUtility.ClearAllTweens(UIController.Instance.Screen.Gameplay.OtherVignette)
	TweenUtility.PlayTween(UIController.Instance.Screen.Gameplay.OtherVignette, TweenInfo.new(2), {
		ImageTransparency = 0.7
	})
	
	TweenUtility.PlayTween(ColorCorrection, TweenInfo.new(2, Enum.EasingStyle.Back), {
		Contrast = -3,
		Brightness = -1,
		Saturation =  -2,
	})
end

function Stealth.OnEndClient(self: Skill)
	
	local UIController = Classes.GetSingleton("UIController")
	
	self.StealthStatus:Stop()
	self.StaminaGainStatus:Stop()
	
	MusicUtility.Music.Misc.StealthLoop:ChangeVolume(0, TweenInfo.new(1), "Set")

	TweenUtility.ClearAllTweens(ColorCorrection)
	TweenUtility.ClearAllTweens(UIController.Instance.Screen.Gameplay.OtherVignette)
	TweenUtility.PlayTween(UIController.Instance.Screen.Gameplay.OtherVignette, TweenInfo.new(2), {
		ImageColor3 = Color3.new(1, 1, 1),
		ImageTransparency = 1
	})
	
	TweenUtility.PlayTween(ColorCorrection, TweenInfo.new(1, Enum.EasingStyle.Back), {
		Contrast = 0,
		Brightness = 0,
		Saturation =  0,
	})
end

function Stealth.OnConstructServer(self: Skill)
	self.Status = self.GenericJanitor:Add(SneakAttackingStatus.new(self.Character))
end

function Stealth.OnConstructClient(self: Skill)
	
	ColorCorrection = InitColorCorrection()
end

function Stealth.OnConstruct(self: Skill)
	BaseHoldableSkill.OnConstruct(self)

	self:SetMaxHoldTime(self.FromRoleData.Duration)

	self.ExclusivesStatusNames = {"Downed", "Hidden", "Stunned", "Handled"}
	self.ExclusivesSkillNames = {"BloomieAttack", "Sprint"}
	self.CheckOthersActive = false
	self.CheckClientState = true
end

--//Returner

return Stealth