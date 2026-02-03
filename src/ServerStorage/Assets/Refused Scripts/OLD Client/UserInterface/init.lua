local client = shared.Client

-- default screen removal
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedFirst = game:GetService('ReplicatedFirst')
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- yuh uh
local reference: ScreenGui = ReplicatedStorage.Assets.GUI.PlayerGui
assert(reference, 'IDIOT, YOU FORGOT TO PUT YOUR SCREEN GUI BACK >:/')

-- requirements
local Util = client._requirements.Util

-- service
local uiSounds = game:GetService('SoundService').Master.UI
local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')


local IMAGE_TEXTURES = {
	BarFill = {
		'rbxassetid://17057846619',
		'rbxassetid://17057846912'
	},
	
	DamageState = {
		'rbxassetid://17351575382',--'rbxassetid://17057846355',--'rbxassetid://17082575428',--'rbxassetid://17057846355',
		'rbxassetid://17057846169',
		'rbxassetid://17057845700',
		'rbxassetid://17057845464'
	},
	
	PreloaderIcon = {
		'rbxassetid://17112135202',
		'rbxassetid://17112135059',
		'rbxassetid://17112134918',
		'rbxassetid://17112134806',
		'rbxassetid://17112134681',
		'rbxassetid://17112134535',
		'rbxassetid://17112134368',
		'rbxassetid://17112134260',
		'rbxassetid://17112134144'
	},
	
	PreloaderThumbnails = {
		--'rbxassetid://17267780942',
		--'rbxassetid://17267780773',
		'rbxassetid://17332191872'
	}
}



-- Initial main ui class
local Initialized = false
local MainGameUI = {}
MainGameUI.object_tweens = {}
MainGameUI._sounds = uiSounds
MainGameUI.reference = reference
MainGameUI.active_image_textures = {}
MainGameUI._image_textures = IMAGE_TEXTURES


function MainGameUI:AddObjectTween(tween: Tween)
	table.insert(self.object_tweens, tween)
	return tween
end


function MainGameUI:ClearTweensForObject(object: GuiBase2d)
	for _i, tween: Tween in ipairs(self.object_tweens) do
		if tween.Instance ~= object then continue end
		tween:Cancel()
		tween:Destroy()
		table.remove(self.object_tweens, _i)
	end
end


function MainGameUI:AddImageTextureToSwap(reference: ImageLabel? | ImageButton?, textures: { string }, index: number?, rate: number)
	for _, tuple in ipairs(self.active_image_textures) do
		if reference == tuple[1] then
			warn('Already exists image swap tuple')
			return
		end
	end
	
	local tuple = {
		reference,
		textures,
		index or 1,
		rate,
		0
	}
	
	table.insert(
		self.active_image_textures,
		tuple
	)
end


function MainGameUI:SwapImageTextures()
	for _, tuple in ipairs(self.active_image_textures) do
		if tick() - tuple[5] < tuple[4] then continue end
		tuple[5] = tick() -- skipping if rate is cooldowned
		
		local reference: ImageLabel | ImageButton = tuple[1]
		local texture_index = tuple[3]
		reference.Image =  tuple[2][texture_index]
		
		-- ordering animation
		tuple[3] = tuple[3] < #tuple[2] and tuple[3] + 1 or 1
	end
end


function MainGameUI:CoreRequest()
	for attempt = 1, 5 do
		local success, message = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
			
			StarterGui:SetCore("BadgesNotificationsActive", false)
			StarterGui:SetCore('ResetButtonCallback', RunService:IsStudio())
			StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
		end)
		
		if success then break end
		task.wait( 1 )
	end
end


function MainGameUI:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	self:CoreRequest()
	
	-- parenting ui to player`s PlayerGui container
	reference.Parent = game.Players.LocalPlayer.PlayerGui
	
	local Gameplay = require( script.Gameplay )
	local Intro = require( script.Intro )
	local Mouse = require( script.Mouse )
	local Menu = require( script.Menu )
	
	self.gameplay_ui = Gameplay
	self.preloader_ui = Intro
	self.menu_ui = Menu
	self.cursor = Mouse
	
	Gameplay:Init()
	Intro:Init()
	Mouse:Init()
	--MenuUI:Init()
	
	-- main UI render connection
	RunService:BindToRenderStep('UserInterface', Enum.RenderPriority.Last.Value, function()
		if self.preloader_ui.completed then
			self.gameplay_ui:Update()
			self.cursor:Update()
		else
			self.preloader_ui:Update()
			self:SwapImageTextures()
		end
		
		-- WHAT THE GOOFY AHH?! TODO: RECODE THIS SHIT
		--[[local rot1 = OST.teacher_round_chase_loop.PlaybackLoudness / 200 * OST.teacher_round_chase_loop.Volume
		local rot2 = OST.student_round_chase_loop.PlaybackLoudness / 200 * OST.student_round_chase_loop.Volume
		local rot3 = OST.student_round_chase_start.PlaybackLoudness / 200 * OST.student_round_chase_start.Volume
		local rot = (rot1 + rot2 + rot3) * 1/3
		
		reference.Screen.Rotation = Util.Lerp(reference.Screen.Rotation, rot, 1/5)]]
	end)
end

return MainGameUI