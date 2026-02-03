--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseUIComponent = require(ReplicatedStorage.Client.Components.UIAssignable.BaseUI)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local GlobalSettings = require(ReplicatedStorage.Shared.Data.GlobalSettings)
local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Promise = require(ReplicatedStorage.Packages.Promise)
local UIRelated = require(ReplicatedStorage.Shared.Data.UiRelated)

local MusicUtility = require(ReplicatedStorage.Client.Utility.MusicUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

--//Variables

local PreloaderRig

local isLoaded = false
local canSkip = false
local stopped = false
local Player = Players.LocalPlayer
local PreloadingUI = BaseComponent.CreateComponent("PreloadingUI", { isAbstract = false }, BaseUIComponent) :: Impl

--//Constants

local SKIP_LOADING = false

--//Types

export type MyImpl = {
	__index: typeof(setmetatable( {} :: MyImpl, {} :: BaseUIComponent.MyImpl )),

	BindEvents: (self: Component) -> (),
	UponSkip: (self: Component, isFullyLoaded: boolean) -> (),
	
	_PreSetup: (self: Component) -> (),
	_StartPreloading: (self: Component) -> (),
	_StopPreloading: (self: Component, isFullyLoaded: boolean) -> (),
}

export type Fields = {
} & BaseUIComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "PreloadingUI", Frame & {}, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "PreloadingUI", Frame & {}, {}>

--//Methods

function CreateAnimationPreloader(): Instance
	
	local Rig = Instance.new("Model")
	local Humanoid = Instance.new("Humanoid")
	local RootPart = Instance.new("Part")

	RootPart.Parent = Rig
	Rig.PrimaryPart = RootPart
	Humanoid.Parent = Rig

	Rig.Parent = workspace
	Rig:PivotTo(CFrame.new(Vector3.one * 100000))

	return Rig
end

function PreloadingUI.UponSkip(self: Component, isFullyLoaded: boolean)
	
	if isLoaded then
		return
	end
	
	isLoaded = true
	print([[ 
 __        __   _                            _          ____                          ____      _   
 \ \      / /__| | ___ ___  _ __ ___   ___  | |_ ___   |  _ \ __ _ _ __   ___ _ __   / ___|   _| |_ 
  \ \ /\ / / _ \ |/ __/ _ \| '_ ` _ \ / _ \ | __/ _ \  | |_) / _` | '_ \ / _ \ '__| | |  | | | | __|
   \ V  V /  __/ | (_| (_) | | | | | |  __/ | || (_) | |  __/ (_| | |_) |  __/ |    | |__| |_| | |_ 
    \_/\_/ \___|_|\___\___/|_| |_| |_|\___|  \__\___/  |_|   \__,_| .__/ \___|_|     \____\__,_|\__|
                                                                  |_|                               
                                                                 
    ]])
	
	print("Game by: Chelgames Development")
	print("Game Version: "..game.PlaceVersion)
	
	MusicUtility.Music.Misc.Preloading:ChangePlayback(0, TweenInfo.new(1), "Set")
	MusicUtility.Music.Misc.Preloading:ChangeVolume(0, TweenInfo.new(0.5), "Set")
	ClientRemotes.Loaded:Fire()
end

local function GetAssetsToPreload(): { Instance }
	local AssetsToPreload = {}

	for _, Service in ipairs(GlobalSettings.Preloading.AssetsPreloadFrom) do
		for _, Asset in ipairs(Service:GetDescendants()) do
			if not table.find(GlobalSettings.Preloading.AllowedClassNames, Asset.ClassName) then
				continue
			end

			if table.find(AssetsToPreload, Asset) then
				continue
			end

			table.insert(AssetsToPreload, Asset)
		end
	end

	return AssetsToPreload
end

function PreloadingUI.BindEvents(self: Component)
	
	self.Janitor:Add(UserInputService.InputBegan:Connect(function(input: InputObject, isTyping: boolean)
		
		if isTyping or isLoaded then
			return
		end
		
		if not canSkip then
			return
		end
		
		if input.KeyCode ~= Enum.KeyCode.Space
			and input.KeyCode ~= Enum.KeyCode.ButtonB then
			
			return
		end
		
		self:_StopPreloading(false)
	end))
end

function PreloadingUI._PreSetup(self: Component)
	
	local PreloadingFrame = self.Instance :: Frame
	local InfoFrame = self.Instance.Info :: Frame
	local InfoMessageFrame = self.Instance.InfoMessage :: Folder

	--InfoMessage Content

	local InfoMessageTitle = InfoMessageFrame.Content.Title :: TextLabel

	local HeadphonesImage = InfoMessageFrame.Content.Headphones.Image :: ImageLabel
	local HeadphonesContentText = InfoMessageFrame.Content.Headphones.Content :: TextLabel

	local WarningFrame = InfoMessageFrame.Content.Warning :: Frame
	local WarningContentText = WarningFrame.Content :: TextLabel

	--Info Content

	local BarImage = InfoFrame.Bar :: ImageLabel
	local FillGradient = BarImage.fill.UIGradient :: UIGradient

	local IconLoading = InfoFrame.Icon :: ImageLabel
	local TipText = InfoFrame.Tip :: TextLabel
	
	-- Setting Variables
	PreloadingFrame.Visible = true
	PreloadingFrame.BackgroundTransparency = 0
	InfoFrame.Visible = false
	InfoMessageFrame.Visible = true

	InfoMessageTitle.TextTransparency = 1
	HeadphonesImage.ImageTransparency = 1
	HeadphonesContentText.TextTransparency = 1
	WarningContentText.TextTransparency = 1

	BarImage.Visible = true
	FillGradient.Offset = Vector2.new(-1, 0)
	
	-- Start Music
	-- putting it here so we dont listen to 1 second of intermission :skull:
	MusicUtility.Music.Misc.Preloading:PlayQuiet()
	MusicUtility.Music.Misc.Preloading:ChangePlayback(0)
	
	self.Janitor:Add(task.delay(1, self._StartPreloading, self), nil, "PreloadingThread")
end

function PreloadingUI._StartPreloading(self: Component)
	
	local PreloadingFrame = self.Instance :: Frame
	local InfoFrame = self.Instance.Info :: Frame
	local InfoMessageFrame = self.Instance.InfoMessage :: Folder
	local ThumbnailImage = self.Instance.Thumbnail :: ImageLabel

	-- Info Message Content

	local InfoMessageTitle = InfoMessageFrame.Content.Title :: TextLabel

	local HeadphonesImage = InfoMessageFrame.Content.Headphones.Image :: ImageLabel
	local HeadphonesContentText = InfoMessageFrame.Content.Headphones.Content :: TextLabel

	local WarningFrame = InfoMessageFrame.Content.Warning :: Frame
	local WarningContentText = WarningFrame.Content :: TextLabel

	-- Info Content

	local BarImage = InfoFrame.Bar :: ImageLabel
	local FillGradient = BarImage.fill.UIGradient :: UIGradient

	local IconLoading = InfoFrame.Icon :: ImageLabel
	local TipText = InfoFrame.Tip :: TextLabel
	
	-- Random Info
	local TipMessage = math.random(1, #UIRelated.Tips)
	local ThumbnailId = math.random(1, #UIRelated.ImageTextures.PreloaderThumbnails)
	
	-- Preloading the preloading assets :exploding_head: (we have like 6 seconds from the tweens)
	self.Janitor:Add(task.spawn(function()
		for category, assetList in UIRelated.ImageTextures do
			if category == "SelectionThumbnails" then
				continue
			end
			--  print(assetList, UIRelated.ImageTextures, "Loading")
			ContentProvider:PreloadAsync(assetList)
			--	print(`Preloaded {#assetList} vital assets`) -- i hide it because its annoying me if you really want it really bad i'm sorry 😭
		end
	end))
	
	MusicUtility.Music.Misc.Preloading:ChangeVolume(1.1, TweenInfo.new(2.9), "Set")
	MusicUtility.Music.Misc.Preloading:ChangePlayback(1, TweenInfo.new(3.5), "Set")
	
	-- Intro Animation
	TweenUtility.WaitForTween(TweenUtility.PlayTween(PreloadingFrame, TweenInfo.new(2), { BackgroundTransparency = 1}))
	TweenUtility.WaitForTween(TweenUtility.PlayTween(InfoMessageTitle, TweenInfo.new(1), { TextTransparency = 0 }))
	
	TweenUtility.PlayTween(HeadphonesContentText, TweenInfo.new(0.65), { TextTransparency = 0.6 })
	TweenUtility.PlayTween(WarningContentText, TweenInfo.new(1), { TextTransparency = 0 })
	
	TweenUtility.WaitForTween(TweenUtility.PlayTween(HeadphonesImage, TweenInfo.new(0.65), { ImageTransparency = 0.5 }), 4)
	
	TweenUtility.WaitForTween(TweenUtility.PlayTween(PreloadingFrame, TweenInfo.new(2), { BackgroundTransparency = 0 }))
	TweenUtility.PlayTween(PreloadingFrame, TweenInfo.new(1), { BackgroundTransparency = 1 })
	
	InfoFrame.Visible = true
	InfoMessageFrame.Visible = false
	
	MusicUtility.Music.Misc.Preloading:Play()
	
	TipText.Text = "Press SPACE or B on console to skip"
	ThumbnailImage.Image = UIRelated.ImageTextures.PreloaderThumbnails[ThumbnailId]

	TweenUtility.PlayTween(ThumbnailImage, TweenInfo.new(1), { ImageTransparency = 0 })
	
	self.Janitor:Add(task.delay(2, function()
		while true do
			local function UpdateInterface()
				ThumbnailId = (ThumbnailId % #UIRelated.ImageTextures.PreloaderThumbnails) + 1
				TipMessage = (TipMessage % #UIRelated.Tips) + 1
				
				-- Updating Info
				TweenUtility.PlayTween(ThumbnailImage, TweenInfo.new(.5), { ImageTransparency = 1 })
				TweenUtility.WaitForTween(TweenUtility.PlayTween(TipText, TweenInfo.new(.5), { TextTransparency = 1 }))

				TipText.Text = UIRelated.Tips[TipMessage]
				ThumbnailImage.Image = UIRelated.ImageTextures.PreloaderThumbnails[ThumbnailId]
				
				TweenUtility.PlayTween(ThumbnailImage, TweenInfo.new(.5), { ImageTransparency = 0 })
				TweenUtility.WaitForTween(TweenUtility.PlayTween(TipText, TweenInfo.new(.5), { TextTransparency = 0.5 }), 5)
			end
			
			local function AnimateInterface()
				local LastTick = os.clock()
				ThumbnailImage.Rotation = math.sin(LastTick * 0.55) * 0.5
				ThumbnailImage.Size = UDim2.fromScale(1.15 + math.sin(LastTick * 0.97) / 200, 3)
			end
			
			AnimateInterface()
			UpdateInterface()
		end
	end))
	
	self.Janitor:Add(function()
		TweenUtility.ClearAllTweens(ThumbnailImage)
		TweenUtility.ClearAllTweens(PreloadingFrame)
	end)
	
	ComponentsManager.Add(IconLoading, "DummyImageSequenceUI")
	canSkip = true
	
	local AssetsToPreload = GetAssetsToPreload()
	local AmountToPreload = #AssetsToPreload
	local CurrentPreloaded = 0
	FillGradient.Offset = Vector2.new(-1, 0)
	
	PreloaderRig = CreateAnimationPreloader()
	
	-- using promises is much faster than a single-threaded loop
	local function PromisePreload(index: number) : Promise.Promise
		return Promise.new(function(resolve, reject, onCancel)
			local assetToLoad = AssetsToPreload[index]

			ContentProvider:PreloadAsync({assetToLoad}, function(assetId, assetFetchStatus)
				if assetFetchStatus == Enum.AssetFetchStatus.Success then
					
				else
					warn("Failed to load asset:", assetToLoad, assetId, assetFetchStatus)
				end
			end)
			if assetToLoad:IsA("Animation") then
				AnimationUtility.QuickPlay(
					PreloaderRig.Humanoid,
					assetToLoad,
					{
						Looped = false
					}
				)
			end
			CurrentPreloaded += 1

			local Progress = CurrentPreloaded / AmountToPreload
			local Offset = -1 + Progress -- Thats mean the -1 Its the start (0%) and the 0 means the end (100%)
			FillGradient.Offset = Vector2.new(Offset, 0)
			
			return resolve()
		end)
	end
	local Promises = {}
	
	if not SKIP_LOADING then
		for i = 1, AmountToPreload do
			table.insert(Promises, PromisePreload(i))
		end
	end
	
	-- .allSettled means we wait until all promises ended (either succeeded or failed). if we just used .all, preload would fail if at least one promise failed
	self.Janitor:AddPromise(Promise.allSettled(Promises):andThen(function()
		CurrentPreloaded = 0
		self:_StopPreloading(true)
	end))

end

function PreloadingUI._StopPreloading(self: Component, isFullyLoaded: boolean)
	
	if stopped then
		return
	end
	
	stopped = true
	
	local PreloadingFrame = self.Instance :: Frame
	local InfoFrame = self.Instance.Info :: Frame
	local InfoMessageFrame = self.Instance.InfoMessage :: Frame
	local ThumbnailImage = self.Instance.Thumbnail :: ImageLabel
	
	--Info Content
	local BarImage = InfoFrame.Bar :: ImageLabel
	local FillGradient = BarImage.fill.UIGradient :: UIGradient

	local IconLoading = InfoFrame.Icon :: ImageLabel
	local TipText = InfoFrame.Tip :: TextLabel
	
	self.Janitor:Cleanup()
	
	--load request
	self:UponSkip(isFullyLoaded)
	
	TipText.Text = isFullyLoaded and "All assets loaded!" or "Skipped preloading!"
	TweenUtility.PlayTween(TipText, TweenInfo.new(0), {TextTransparency = 0}) -- we're using an instant tween here to cancel all other tweens
	ComponentsManager.Remove(IconLoading, "DummyImageSequenceUI")
	
	TweenUtility.WaitForTween(TweenUtility.PlayTween(PreloadingFrame, TweenInfo.new(.75), { BackgroundTransparency = 0 }), .5)
	InfoFrame.Visible = false
	InfoMessageFrame.Visible = false
	ThumbnailImage.Visible = false
	
	TweenUtility.WaitForTween(TweenUtility.PlayTween(PreloadingFrame, TweenInfo.new(1.5), { BackgroundTransparency = 1 }), 1)
	PreloadingFrame.Visible = false
end

function PreloadingUI.OnConstruct(self: Component, ...)
	BaseUIComponent.OnConstruct(self, ...)
end

function PreloadingUI.OnConstructClient(self: Component, ...)
	BaseUIComponent.OnConstructClient(self, ...)
	
	--no preloading in studioMusicUtility.Music.Misc.Preloading:Reset()
	MusicUtility.Music.Misc.Preloading:Reset()
	MusicUtility.Music.Misc.Preloading:ChangePlayback(0, nil, "Set")
	MusicUtility.Music.Misc.Preloading:ChangeVolume(0, nil, "Set")

	self:BindEvents()
	self:_PreSetup()
	
	--[[
	if not RunService:IsStudio() then
		
		MusicUtility.Music.Misc.Preloading:Reset()
		MusicUtility.Music.Misc.Preloading:ChangePlayback(0, nil, "Set")
		MusicUtility.Music.Misc.Preloading:ChangeVolume(0, nil, "Set")
		
		self:BindEvents()
		self:_PreSetup()
		
	else
		--instantly hiding frame
		task.wait(4)
		self.Instance.Visible = false
		selfUponSkip(false)
	end
	]]--
	
	--if RunService:IsStudio() and false then -- please  don't remove false, skipping preloading causes bugs AA
	--	self:_StopPreloading(false) 
	--else
	--	self:BindEvents()
	--	self:_PreSetup()
	--end
	
end

--//Returner

return PreloadingUI