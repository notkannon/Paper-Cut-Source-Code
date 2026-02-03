local client = shared.Client

--requirements
local Util = client._requirements.Util
local PreloaderModule = client:Require(script.PreloaderModule)

-- service
local UserInputService = game:GetService('UserInputService')
local SoundService = game:GetService('SoundService')
local RunService = game:GetService('RunService')
local GuiService = game:GetService('GuiService')
local StarterGui = game:GetService('StarterGui')
local TweenService = game:GetService('TweenService')
local InterfaceSFX = SoundService.Master.UI

-- paths
local MainUI = client._requirements.UI
local imageTextures = MainUI._image_textures
local reference: Frame? = MainUI.reference.Screen.Preloading
assert( reference, 'No preloading frame exists in ScreenGui' )

-- constant
local PRELOADER_ICON_DELAY = .07
local THUMBNAIL_DELAY = 9 -- used to control preloader thumbnails swap rate

local TIP_MESSAGES = {
	'Use the space to your advantage - hide behind objects and in hiding spots to avoid being caught',
	'Explore every nook and cranny of the school to find helpful items and avoid getting caught',
	'Keep a close watch on your stamina - running, jumping and dashing takes a toll on your energy',
	'Do not neglect common items. They are very helpful when you are escaping from the teacher',
	'Use dashes to dodge items thrown at you or from teacher attacks',
	'Use dashes to boost your speed when you are running away or following victim',
	'While running away, try to keep up with opening the door in front of you - it can slow down your speed on impact',
	'When running away, try to close the door behind you - it can prevent the teacher from catching you.',
	'He always watch.'
}


-- initial
local preloaderUI = {}
preloaderUI.__index = preloaderUI
preloaderUI.reference = reference
preloaderUI.assetsText = reference.info.text
preloaderUI.assetsBarGradient = reference.info.bar.fill.UIGradient

preloaderUI.preload_start = 0
preloaderUI.icon_pointer = 1
preloaderUI.icon_direction = 1
preloaderUI.last_swap_time = 0
preloaderUI.last_thumbnail_change = 0
preloaderUI.last_thumbnail = 0
preloaderUI.skip_prompted = false
preloaderUI.completed = false


function preloaderUI:Init()
	reference.Visible = true
	
	TweenService:Create(reference, TweenInfo.new(3), {BackgroundTransparency = 1}):Play()
	task.wait( 5 )
	TweenService:Create(reference, TweenInfo.new(1.5), {BackgroundTransparency = 0}):Play()
	task.wait( 3 )

	reference.InfoMessage.Visible = false
	reference.info.Visible = true
	reference.info.tip.Text = 'TIP: '.. TIP_MESSAGES[ math.random(1, #TIP_MESSAGES) ]

	TweenService:Create(SoundService.Master.Music.Preloading, TweenInfo.new(1.5), {PlaybackSpeed = 1}):Play()
	TweenService:Create(reference, TweenInfo.new(1.5), {BackgroundTransparency = 1}):Play()
end


function preloaderUI:PromptPreload()
	self.preload_start = os.clock()
	
	PreloaderModule:Run(function(preloaded: number)
		self:SetAssetsPreloaded(preloaded, #PreloaderModule.assetsToPreload)
	end)
end


function preloaderUI:PromptSkip()
	reference.info.SKIP.Visible = true
	self.skip_prompted = true
	
	self.skip_input = UserInputService.InputBegan:Connect(function(i, p)
		if p then return end
		if i.KeyCode == Enum.KeyCode.Space then
			PreloaderModule:Skip()
			self.skip_input:Disconnect()
		end
	end)
	
	reference.info.SKIP.MouseButton1Click:Connect(function()
		reference.info.SKIP.Visible = false
		self.skip_input:Disconnect()
		PreloaderModule:Skip()
	end)
end


function preloaderUI:Update()
		--[[if tick() - self.last_thumbnail_change > THUMBNAIL_DELAY then
			self.last_thumbnail_change = tick()
			self:NextThumbnail()
		end]]
		
	if os.clock() - self.preload_start > 3 and not self.skip_prompted then
		self:PromptSkip()
	end
	
	if tick() - self.last_swap_time < PRELOADER_ICON_DELAY then return end
	self.last_swap_time = tick()

	local icon: ImageLabel = reference.info.PreloaderIcon

	-- icon image change looped and reversed at end
	if self.icon_pointer == #imageTextures.PreloaderIcon then
		self.icon_direction = -1
	elseif self.icon_pointer == 1 then
		self.icon_direction = 1
	end

	self.icon_pointer += self.icon_direction
	icon.Image = imageTextures.PreloaderIcon[self.icon_pointer]

	local t = tick() * 1
	reference.thumbnail.Rotation = math.sin(t * .95) * .5
	reference.thumbnail.Size = UDim2.fromScale(
		1.1 + math.sin(t * .97) / 200,
		3
	)

		--[[self.infoMessageOverlay_reference.BackgroundTransparency = NumLerp(
			self.infoMessageOverlay_reference.BackgroundTransparency,
			math.sin(tick() * 2) * .2 + .8 - (self.completed and 1 or 0),
			1/15
		)]]
end


function preloaderUI:NextThumbnail()
	local imageTextures = MainUI._image_textures
	if #imageTextures.PreloaderThumbnails < 2 then return end

	local thumb_id = self.last_thumbnail < #imageTextures.PreloaderThumbnails and self.last_thumbnail + 1 or 1
	self.last_thumbnail = thumb_id

	MainUI:ClearTweensForObject(reference.thumbnail)
	local fadeIn: Tween = MainUI:AddObjectTween(TweenService:Create(reference.thumbnail, TweenInfo.new(1), {ImageColor3 = Color3.new(0, 0, 0)}))
	fadeIn:Play()

	fadeIn.Completed:Once(function()
		reference.thumbnail.Image = imageTextures.PreloaderThumbnails[ thumb_id ]
		MainUI:AddObjectTween(TweenService:Create(reference.thumbnail, TweenInfo.new(1), {ImageColor3 = Color3.new(.15, .15, .15)})):Play()
	end)
end


function preloaderUI:SetAssetsPreloaded(assets_preloaded: number, assets_to_preload: number)
	local assetsText: TextLabel = self.assetsText

	assetsText.Text = `Assets Loaded { assets_preloaded }/{ assets_to_preload }`
	
	-- make assetsText rotation tween reset
	assetsText.Rotation = math.random(-1, 1) * math.random(1, 4)/2
	MainUI:ClearTweensForObject( assetsText )
	MainUI:AddObjectTween( TweenService:Create(assetsText, TweenInfo.new(.2), {Rotation = 0}) ):Play()

		--[[TweenService:Create(
			self.assetsBarGradient_reference,
			TweenInfo.new(.1), {
				Offset = Vector2.new(
					-1 + assets_preloaded/assets_to_preload,
					0
				)
			}
		):Play()]]
end


function preloaderUI:Complete()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
	TweenService:Create(SoundService.Master.Music.Preloading, TweenInfo.new(1.5), {PlaybackSpeed = 0}):Play()

	task.wait(1.5)

	local fade = TweenService:Create(reference, TweenInfo.new(1.5), {BackgroundTransparency = 0})
	fade:Play()

	fade.Completed:Once(function()
		reference.thumbnail.Visible = false
		reference.info.Visible = false
		TweenService:Create(reference, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
		task.wait(1)
		reference.Visible = false
	end)

	self.completed = true
end

return preloaderUI