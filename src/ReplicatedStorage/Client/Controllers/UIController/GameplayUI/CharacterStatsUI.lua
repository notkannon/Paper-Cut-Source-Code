--//Services

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local StatusEffectDisplayData = require(ReplicatedStorage.Shared.Data.StatusEffectDisplayData)

local Utility = require(ReplicatedStorage.Shared.Utility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local MatchStateClient = require(ReplicatedStorage.Client.Controllers.MatchStateClient)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

--//Variables

local LocalPlayer = Players.LocalPlayer
local UIAssets = ReplicatedStorage.Assets.UI
local CharacterStatsUI = BaseComponent.CreateComponent("CharacterStatsUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseUIComponent.MyImpl) ),
	
	OnHealthChanged: (self: Component, new: number, old: number, component: unknown) -> (),
	OnStaminaChanged: (self: Component, new: number, old: number, component: unknown) -> (),
	
	_ConnectCharacterEvents: (self: Component) -> (),
}

export type Fields = {

} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "CharacterStatsUI", Frame & any, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "CharacterStatsUI", Frame & any, {}>

--//Methods

function CharacterStatsUI.OnHealthChanged(self: Component, new: number, old: number, component: unknown)
	
	local Alpha = math.abs(old - new) / component.Humanoid.MaxHealth
	local IsLost = new < old
	local HealthBar = self.Instance.Bars.Health :: ImageLabel
	local HealthLabel = HealthBar:FindFirstChild("Label") :: TextLabel
	local HealthVignette = self.Instance.Parent:FindFirstChild("Health") :: ImageLabel
	local ColorCorrection = Lighting:FindFirstChild("PlayerDamageColorCorrection") :: ColorCorrectionEffect
	
	TweenUtility.ClearAllTweens(HealthBar)
	TweenUtility.ClearAllTweens(HealthVignette)
	TweenUtility.ClearAllTweens(HealthBar.Value)
	TweenUtility.ClearAllTweens(HealthLabel.Value)
	
	HealthBar.ImageColor3 = Color3.new(1, 1, 1)
	HealthBar.ImageTransparency = 0
	HealthLabel.Text = `{ math.round(new) }`
	
	TweenUtility.PlayTween(HealthVignette, TweenInfo.new(0), {
		
		ImageColor3 = Color3.fromHSV(IsLost and 1 or 0.3, math.clamp(Alpha / 2, 0, 1), 0.5),
		ImageTransparency = 0.8 - Alpha ^ 2,
		
	} :: ImageLabel, function(status)
		
		if status == Enum.TweenStatus.Canceled then
			return
		end
		
		TweenUtility.PlayTween(HealthVignette, TweenInfo.new(math.clamp(Alpha * 5, 0.5, 5)), {

			ImageTransparency = 1

		} :: ImageLabel)
	end)

	if IsLost then
		
		TweenUtility.ClearAllTweens(ColorCorrection)

		Utility.ApplyParams(ColorCorrection, {
			Saturation = math.clamp(Alpha * 3, -2, 0),
			TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(255, 32, 32), math.clamp(Alpha * 3, 0.1, 1)),
		})

		TweenUtility.PlayTween(ColorCorrection, TweenInfo.new(math.abs(old - new) / 30), {
			Saturation = 0,
			TintColor = Color3.new(1, 1, 1),
		})
	end
	
	--local blood_screen: ImageLabel = self.bloodScreen_reference
	--local vignette: ImageLabel = self.vignetteScreen_reference
	--local back_frame: ImageLabel = self.playerState_reference.Back
	--local player_health_bar: ImageLabel = self.playerState_reference.Bars.Health
	--local player_damage_icon: ImageLabel = self.playerState_reference.StateIcon
	--local value_gradient: UIGradient = player_health_bar.Fill.Value
	--local health_amount: TextLabel = player_health_bar.Amount

	--local value = new_health / 100
	--local damaged = old_health > new_health
	--local delta = math.abs(new_health - old_health) / 100

	--self.target_health_value = value > 0 and (1 - value) or 0

	--health_amount.Text = math.round( new_health ) -- avoid floats
	--vignette.ImageTransparency = 0
	--vignette.ImageColor3 = Color3.fromHSV(damaged and 1 or .3, damaged and 1 or.5, math.clamp(delta * 2, 0, .7))

	--TweenService:Create(back_frame, TweenInfo.new(1), {ImageTransparency = 1 - value}):Play()
	--TweenService:Create(vignette, TweenInfo.new(delta * 2.5), {ImageColor3 = Color3.new(0, 0, 0)}):Play()
	--TweenService:Create(value_gradient, TweenInfo.new(.3), {Offset = Vector2.new(value - 1,0)}):Play()
	--TweenService:Create(health_amount.Value, TweenInfo.new(.3), {Offset = Vector2.new(value - 1,0)}):Play()
	
	TweenUtility.PlayTween(
		HealthBar,
		TweenInfo.new(.3), {
			ImageColor3 = Color3.fromRGB(140, 46, 46),
			ImageTransparency = 0.3,
		}
	)

	TweenUtility.PlayTween(
		HealthBar.Value,
		TweenInfo.new( math.abs(old - new) / 70, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out ),
		{ Offset = Vector2.new(new / component.Humanoid.MaxHealth - 1, 0) }
	)
	
	TweenUtility.PlayTween(
		HealthLabel.Value,
		TweenInfo.new( math.abs(old - new) / 70, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out ),
		{ Offset = Vector2.new(new / component.Humanoid.MaxHealth - 1, 0) }
	)
	
	local HPPercentage = component.Humanoid.Health / component.Humanoid.MaxHealth
	local Config = RolesManager:GetPlayerRoleConfig(LocalPlayer)
	
	if HPPercentage <= 0.25 and Config.AltIcons.Critical then
		self.Instance.Avatar.Image = Config.AltIcons.Critical
	elseif HPPercentage <= 0.5 and Config.AltIcons.Injured then
		self.Instance.Avatar.Image = Config.AltIcons.Injured
	else
		self.Instance.Avatar.Image = Config.Icon
	end
end

function CharacterStatsUI.OnStaminaChanged(self: Component, new: number, old: number, component: unknown)
	
	local Stamina = ComponentsManager.Get(component.Instance, "Stamina")
	local StaminaBar = self.Instance.Bars.Stamina :: Frame
	local StaminaLabel = StaminaBar:FindFirstChild("Label") :: TextLabel
	
	StaminaLabel.Text = math.round(new)
	
	TweenUtility.ClearAllTweens(StaminaBar.Value)

	if math.abs(old - new) <= 1 then
		
		StaminaBar.Value.Offset = Vector2.new(new / 100 - 1, 0)

		return
	end

	TweenUtility.PlayTween(
		StaminaBar.Value,
		TweenInfo.new( math.abs(old - new) / 50 ),
		{ Offset = Vector2.new(new / Stamina.Max - 1, 0) }
	)
	
	TweenUtility.PlayTween(
		StaminaLabel.Value,
		TweenInfo.new( math.abs(old - new) / 50 ),
		{ Offset = Vector2.new(new / Stamina.Max - 1, 0) }
	)
end

function CharacterStatsUI._ConnectCharacterEvents(self: Component)
	
	PlayerController.CharacterAdded:Connect(function(component)
		
		--doing nothing cuz spectators shouldn't have this section
		if PlayerController:IsSpectator() then
			return
		end
		
		self.CharacterComponent = component

		local OldHealth = component.Humanoid.Health
		local Stamina = ComponentsManager.Get(component.Instance, "Stamina")

		component.Janitor:Add(Stamina.Changed:Connect(function(newStamina: number, oldStamina: number)
			self:OnStaminaChanged(newStamina, oldStamina, component)
		end))

		component.Janitor:Add(component.Humanoid.HealthChanged:Connect(function(newHealth: number)
			
			self:OnHealthChanged(newHealth, OldHealth, component)
			
			OldHealth = newHealth
		end))

		component.Janitor:Add(function()
			self.CharacterComponent = nil
		end)

		self:OnHealthChanged(OldHealth, OldHealth, component)
		self:OnStaminaChanged(Stamina:Get(), Stamina:Get(), component)
	end)
end

function CharacterStatsUI._ConnectRoleEvents(self: Component)
	
	MatchStateClient.MatchStarted:Connect(function(Match)
		if Match ~= "Result" then
			return
		end
		
		self:SetEnabled(false)
	end)
	
	PlayerController.RoleConfigChanged:Connect(function(config)
		
		self:SetEnabled(not PlayerController:IsSpectator())
		
		self.Instance.Avatar.Image = config.Icon or "" 
		self.Instance.Avatar.ImageColor3 =  config.Icon and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
		self.Instance.Avatar.ImageTransparency = config.Icon and 0.3 or 0.7
		--print(config)
		local CharName = config.CharacterDisplayName or config.CharacterName
		--local FullName =  (`{ config.SkinName and (config.SkinName .. " "):upper() or "" }{ (config.CharacterName or "unknown"):upper() } <font transparency="0.85">{ (config.Name or ""):upper() }</font>`)
		local FullName =  (`{ (CharName or "unknown"):upper() } <font transparency="0.85">{ (config.Name or ""):upper() }</font>`)
		self.Instance.PlayerName.Text = FullName
	end)
	
	self:SetEnabled(false)
end

function CharacterStatsUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	--misc
	
	--thumbnail applying
	--self.Controller:GetUserThumbnailCallback(LocalPlayer, function(imageId: string)
		
	--end)
	
	self.Instance.PlayerName.RichText = true
	
	local DamageColorCorrection = Instance.new("ColorCorrectionEffect")
	DamageColorCorrection.Name = "PlayerDamageColorCorrection"
	DamageColorCorrection.Parent = Lighting
	DamageColorCorrection.Enabled = true
	
	self:_ConnectRoleEvents()
	self:_ConnectCharacterEvents()
end

--//Returner

return CharacterStatsUI