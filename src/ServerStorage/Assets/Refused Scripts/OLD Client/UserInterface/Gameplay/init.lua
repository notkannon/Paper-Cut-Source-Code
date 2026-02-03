local client = shared.Client

-- requirements
local BackpackUI
local HideoutUI
local TauntsUI
local SkillUI

local Lighting = game:GetService('Lighting')
local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')
local InterfaceSFX = game:GetService('SoundService').Master.UI
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- requirements
local Util = require(ReplicatedStorage.Shared.Util)
local Enums = require(ReplicatedStorage.Enums)

-- paths
local MainUI = client._requirements.UI
local reference: Frame? = MainUI.reference.Screen.Gameplay
assert( reference, 'No gameplay frame exists in ScreenGui' )


-- class initial
local gameplayUI = {}
gameplayUI.__index = gameplayUI
gameplayUI.reference = reference

gameplayUI.shake_multiply = 0
gameplayUI.old_stamina_value = 1
gameplayUI.target_health_value = 0

gameplayUI.hotbar_reference = reference.Backpack
gameplayUI.playerState_reference = reference.PlayerState
gameplayUI.bloodScreen_reference = reference.Blood
gameplayUI.vignetteScreen_reference = reference.Vignette
gameplayUI.lockerVignetteScreen = reference.LockerVignette
-- could set a link on init
gameplayUI.timer_shaker = nil
gameplayUI.backpack_ui = nil
gameplayUI.skills_ui = nil


function gameplayUI:Init()
	BackpackUI = require(script.Backpack)
	HideoutUI = require(script.Hideout)
	TauntsUI = require(script.Taunts)
	SkillUI = require(script.Skills)
	
	self.backpack_ui = BackpackUI
	self.hideout_ui = HideoutUI
	self.taunts_ui = TauntsUI
	self.skills_ui = SkillUI
	
	BackpackUI:Init()
	HideoutUI:Init()
	TauntsUI:Init()
	SkillUI:Init()
	
	self:OnHealthChanged(100, 100)
	self:OnStaminaCnahged(1, 1)
end

--[[
function gameplayUI:CountdownSetGameState( game_state: number )
	--[[local message_label: TextLabel = reference.Top.Countdown.Message
	if game_state == Enums.GameStateEnum.Intermission then
		message_label.Text = 'INTERMISSION'
	elseif game_state == Enums.GameStateEnum.Round then
		message_label.Text = 'ROUND'
	else message_label.Text = 'WAITING FOR THE PLAYERS' end
end


function gameplayUI:countdownSetTime( countdown: number, game_state: number )
	--[[local countdown_label: TextLabel = reference.Top.Countdown
	
	countdown_label.Text = Util.SecondsToMS(countdown)
	countdown_label.Back.ImageColor3 = countdown > 10
		and Color3.fromRGB(92, 87, 106) -- time is enough
		or Color3.fromRGB(106, 47, 47) -- less time
	countdown_label.TextColor3 = countdown > 10
		and Color3.new(1, 1, 1) -- white
		or Color3.fromRGB(255, 103, 103)

	if countdown <= 10 then
		--.ShakeOnce(Shaker2D, Duration, Intensity, _FadeIn, _FadeOut, WithRotation)
		InterfaceSFX.CountdownTick:Play()

		countdown_label.Rotation = -3
		MainUI:ClearTweensForObject(countdown_label)
		MainUI:AddObjectTween(TweenService:Create(countdown_label, TweenInfo.new(.1), {Rotation = 0})):Play()
	end
end]]


function gameplayUI:OnHealthChanged( new_health: number, old_health: number )
	local blood_screen: ImageLabel = self.bloodScreen_reference
	local vignette: ImageLabel = self.vignetteScreen_reference
	local back_frame: ImageLabel = self.playerState_reference.Back
	local player_health_bar: ImageLabel = self.playerState_reference.Bars.Health
	local player_damage_icon: ImageLabel = self.playerState_reference.StateIcon
	local value_gradient: UIGradient = player_health_bar.Fill.Value
	local health_amount: TextLabel = player_health_bar.Amount

	local value = new_health / 100
	local damaged = old_health > new_health
	local delta = math.abs(new_health - old_health) / 100
	self.target_health_value = value > 0 and (1 - value) or 0

	health_amount.Text = math.round( new_health ) -- avoid floats
	vignette.ImageTransparency = 0
	vignette.ImageColor3 = Color3.fromHSV(damaged and 1 or .3, damaged and 1 or.5, math.clamp(delta * 2, 0, .7))

	TweenService:Create(back_frame, TweenInfo.new(1), {ImageTransparency = 1 - value}):Play()
	TweenService:Create(vignette, TweenInfo.new(delta * 2.5), {ImageColor3 = Color3.new(0, 0, 0)}):Play()
	TweenService:Create(value_gradient, TweenInfo.new(.3), {Offset = Vector2.new(value - 1,0)}):Play()
	TweenService:Create(health_amount.Value, TweenInfo.new(.3), {Offset = Vector2.new(value - 1,0)}):Play()

	-- color flash
	player_health_bar.Fill.ImageColor3 = Color3.new(1, 1, 1)
	TweenService:Create(player_health_bar.Fill, TweenInfo.new(.5), {ImageColor3 = Color3.fromRGB(164, 47, 48)}):Play()

	player_damage_icon.Size = UDim2.fromScale(.2, 1)
	player_damage_icon:TweenSize(UDim2.fromScale(.15, 1), 'Out', 'Sine', .3, true)

		--[[if value <= .25 then player_damage_icon.Image = IMAGE_TEXTURES.DamageState[4]
		elseif value <= .5 then player_damage_icon.Image = IMAGE_TEXTURES.DamageState[3]
		elseif value <= .75 then player_damage_icon.Image = IMAGE_TEXTURES.DamageState[2]
		else player_damage_icon.Image = IMAGE_TEXTURES.DamageState[1] end]]
end


function gameplayUI:OnStaminaCnahged( current: number, max_value: number )
	local player_stamina_bar: ImageLabel = self.playerState_reference.Bars.Stamina
	local value_gradient: UIGradient = player_stamina_bar.Fill.Value

	local old_value = self.old_stamina_value
	local value = current / max_value
	self.old_stamina_value = value

	value_gradient.Offset = Vector2.new(value - 1, 0)

	-- visual effect
	if old_value - value >= .13 then
		local size = UDim2.fromScale(old_value - value, .7)
		local frame = Instance.new('Frame')
		frame.Parent = player_stamina_bar
		frame.AnchorPoint = Vector2.new(0, .5)
		frame.Position = UDim2.fromScale(value, .5)
		frame.Size = size
		frame.BackgroundColor3 = Color3.new(1,1,1)
		frame.BorderSizePixel = 0
		frame.ZIndex = 33

		frame:TweenSize(UDim2.fromScale(size.X.Scale * 1.5, size.Y.Scale * 1.5), 'Out', 'Sine', .2, true)
		TweenService:Create(frame, TweenInfo.new(.2), {BackgroundTransparency = 1}):Play()
	end


		--[[tweenService:Create(value_gradient, TweenInfo.new(.3), {Offset = Vector2.new(
			value - 1,
			0
		)}):Play()]]
end


function gameplayUI:SetStatsTransparency( transparency: number )
	local container: Frame = self.playerState_reference
	local bars = container.Bars
	
	local transparency = transparency or 1
	
	MainUI:ClearTweensForObject(container.StateIcon)
	MainUI:ClearTweensForObject(bars.Health.Fill)
	MainUI:ClearTweensForObject(bars.Health.Amount)
	MainUI:ClearTweensForObject(bars.Stamina.Fill)
	MainUI:AddObjectTween(TweenService:Create(container.StateIcon, TweenInfo.new(.2), {ImageTransparency = transparency})):Play()
	MainUI:AddObjectTween(TweenService:Create(bars.Health.Fill, TweenInfo.new(.2), {ImageTransparency = transparency})):Play()
	MainUI:AddObjectTween(TweenService:Create(bars.Stamina.Fill, TweenInfo.new(.2), {ImageTransparency = transparency})):Play()
	MainUI:AddObjectTween(TweenService:Create(bars.Health.Amount, TweenInfo.new(.2), {TextTransparency = transparency})):Play()
end


function gameplayUI:Update()
	local t = tick()
	
	-- updating backpack ui subinterface
	self.backpack_ui:Update()
	
	local blood_screen: ImageLabel = self.bloodScreen_reference
	local CharacterObject = client.local_character
	local humanoid: Humanoid = CharacterObject and CharacterObject:GetHumanoid()

	self.shake_multiply = Util.Lerp(
		self.shake_multiply,
		self.target_health_value,
		(humanoid and humanoid.Health > 0 and 1/17 or 1/200) or 1/17
	)

	local val_wave = (self.shake_multiply + math.sin(t * 5) * .5 * self.shake_multiply)

	game.Lighting.ColorCorrection.Saturation = -val_wave/2
	game.Lighting.ColorCorrection.TintColor = Color3.fromHSV(1, val_wave/2, 1)

	blood_screen.Rotation = self.shake_multiply * math.random(-20, 20)/10
	reference.Rotation = self.shake_multiply * math.random(-20, 20)/16
	reference.Position = UDim2.new(
		.5, self.shake_multiply * math.random(-5, 5),
		.5, self.shake_multiply * math.random(-5, 5)
	)

	blood_screen.Position = UDim2.new(
		.5, self.shake_multiply * math.random(-20, 20),
		.5, self.shake_multiply * math.random(-20, 20)
	)

	blood_screen.ImageTransparency = Util.Lerp(
		blood_screen.ImageTransparency,
		1 - val_wave, 1/3
	)

--[[	game.SoundService.Master.Sounds.Heartbeat.Volume = (self.shake_multiply/3)^2
	game.SoundService.Master.Sounds.Heartbeat.PlaybackSpeed = math.clamp(self.shake_multiply^2 * 1.57, 0, 1)]]
end


function gameplayUI:ChangePreset( preset_name: string )
	if preset_name == 'shop' then
		self:SetStatsTransparency( .9 )
		TauntsUI:SetEnabled( false )
		
	elseif preset_name == 'game' then
		--game.SoundService.Master.OST.MuteEffect.Enabled = false
		self:SetStatsTransparency( 0 )
		TauntsUI:SetEnabled( true )
		HideoutUI:SetEnabled( false )
		
	elseif preset_name == 'locker' then
		--game.SoundService.Master.OST.MuteEffect.Enabled = true
		self:SetStatsTransparency( .9 )
		TauntsUI:SetEnabled( false )
		HideoutUI:SetEnabled( true )
		
	elseif not preset_name then -- hiding all UIs
		self:SetStatsTransparency( 1 )
		TauntsUI:SetEnabled( false )
		HideoutUI:SetEnabled( false )
	end
end

return gameplayUI