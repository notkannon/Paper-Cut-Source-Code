--//Service

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Utility = require(ReplicatedStorage.Shared.Utility)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Types
export type Fields = {

	GetRealDestinatedVolume: (self: MusicWrapper) -> number,
	IsAudible: (self: MusicWrapper) -> boolean,

	Reset: (self: MusicWrapper) -> (),
	PlayQuiet: (self: MusicWrapper) -> (),
	Play: (self: MusicWrapper) -> (),

	ChangeVolume: (self: MusicWrapper, value: number, tweenInfo: TweenInfo?, method: "Increment" | "Set", raw: boolean?) -> (),
	ChangePlayback: (self: MusicWrapper, value: number, tweenInfo: TweenInfo?, method: "Increment" | "Set") -> ()
} 

--//Constants

local AUDIBLE_UPDATE_RATE = 0.25

local MUFFLED_EFFECT_DISABLED_OPTIONS = {
	HighGain = 0,
	LowGain = 0,
	MidGain = 0,
} :: EqualizerSoundEffect

local MUFFLED_EFFECT_ENABLED_OPTIONS = {
	HighGain = -49.4,
	LowGain = -1.7,
	MidGain = -42.2,
} :: EqualizerSoundEffect

local DEFAULT_PROPS = {
	Volume = 0,
	Looped = true,
	Playing = false,
	PlaybackSpeed = 1,
} :: SoundProps

--//Variables

local MusicFolder = SoundUtility.Sounds.Music
local MuffledEffect = MusicFolder.MuffledEffect :: EqualizerSoundEffect

local Objects = {} :: { MusicWrapper }
local TrackEnded = Signal.new() :: Signal.Signal<MusicWrapper>
local TrackPlayed = Signal.new() :: Signal.Signal<MusicWrapper>
local TrackDidLoop = Signal.new() :: Signal.Signal<MusicWrapper>
local TrackVolumeChanged = Signal.new() :: Signal.Signal<MusicWrapper, number, number>
local TrackAudibleChanged = Signal.new() :: Signal.Signal<MusicWrapper, boolean>

local MusicWrapper = {}
MusicWrapper.__index = MusicWrapper

--//Types

export type MusicWrapper = typeof(setmetatable({} :: Fields, {} :: MyImpl))

--//Functions

local function ToggleMuffled(enabled: boolean, tweenInfo: TweenInfo?)

	local Params = enabled and MUFFLED_EFFECT_ENABLED_OPTIONS or MUFFLED_EFFECT_DISABLED_OPTIONS
	TweenUtility.ClearAllTweens(MuffledEffect)

	if not tweenInfo then
		Utility.ApplyParams(MuffledEffect, Params)
		return
	end

	TweenUtility.PlayTween(MuffledEffect, tweenInfo, Params)
end

local function InitPriorityCheck(self: MusicWrapper)

	local function OnUpdate()

		local Affectable = 0

		for _, Wrapper in ipairs(Objects) do
			if Wrapper == self or Wrapper._DestinatedVolume <= 0 then continue end
			if Wrapper.Priority > self.Priority then
				Affectable += 1
			end
		end

		self._PriorityVolumeIncrement = -Affectable
		self:ChangeVolume(0, TweenInfo.new(1), "Increment", true)
	end

	local function HandleAudible(track: MusicWrapper)

		if track ~= self then return end

		local Audible = self:IsAudible()

		TrackAudibleChanged:Fire(self, Audible)
	end

	self.PriorityJanitor:Add(TrackEnded:Connect(HandleAudible))
	self.PriorityJanitor:Add(TrackPlayed:Connect(HandleAudible))
	self.PriorityJanitor:Add(TrackDidLoop:Connect(HandleAudible))
	self.PriorityJanitor:Add(TrackVolumeChanged:Connect(HandleAudible))
	self.PriorityJanitor:Add(TrackAudibleChanged:Connect(OnUpdate))
end

local function Create(source: Sound, priority: number, defaultProps: SoundProps?) : MusicWrapper
	local self = setmetatable({}, MusicWrapper) :: MusicWrapper

	self.Instance = source
	self._HasEnded = true
	self._DestinatedVolume = 0
	self._PriorityVolumeIncrement = 0
	self.Priority = priority or 0
	self.VolumeScale = defaultProps.VolumeScale or 1
	self.DefaultProps = defaultProps and TableKit.MergeDictionary(DEFAULT_PROPS, defaultProps) or DEFAULT_PROPS
	self.VolumeJanitor = Janitor.new()
	self.PriorityJanitor = Janitor.new()
	self.PlaybackJanitor = Janitor.new()

	self.DefaultProps.VolumeScale = nil

	local function SetupEnded()
		self._HasEnded = true
		TrackEnded:Fire(self)
	end

	self.Instance.Ended:Connect(SetupEnded)
	self.Instance.Stopped:Connect(SetupEnded)
	self.Instance.Paused:Connect(SetupEnded)
	self.Instance.Played:Connect(function()
		self._HasEnded = false
		TrackPlayed:Fire(self)
	end)
	self.Instance.Resumed:Connect(function()
		self._HasEnded = false
		TrackPlayed:Fire(self)
	end)
	self.Instance.DidLoop:Connect(function()
		TrackDidLoop:Fire(self)
	end)

	self:Reset()
	table.insert(Objects, self)
	return self
end

local function GetWrapperFromSound(sound: Sound) : MusicWrapper?
	for _, Wrapper in ipairs(Objects) do
		if Wrapper.Instance == sound then
			return Wrapper
		end
	end
end

--//Methods

function MusicWrapper.GetRealDestinatedVolume(self: MusicWrapper)
	return self._DestinatedVolume + self._PriorityVolumeIncrement
end

function MusicWrapper.IsAudible(self: MusicWrapper)
	return self.Instance.Playing and not self._HasEnded and self.Instance.PlaybackSpeed > 0 and self:GetRealDestinatedVolume() > 0
end

function MusicWrapper.Reset(self: MusicWrapper)

	self._DestinatedVolume = self.DefaultProps.Volume or 0
	self._DestinatedPlaybackSpeed = self.DefaultProps.PlaybackSpeed or 1
	self._PriorityVolumeIncrement = 0

	self.VolumeJanitor:Cleanup()
	self.PlaybackJanitor:Cleanup()
	self.PriorityJanitor:Cleanup()

	self.Instance:Stop()
	self.Instance.Volume = 0
	self.Instance.PlaybackSpeed = 1

	InitPriorityCheck(self)
	Utility.ApplyParams(self.Instance, self.DefaultProps)

	self.Instance.Volume *= self.VolumeScale
end

function MusicWrapper.PlayQuiet(self: MusicWrapper)
	self:Reset()
	self.Instance:Play()
	self:ChangeVolume(0)
end

function MusicWrapper.Play(self: MusicWrapper)
	self:PlayQuiet()
	self:ChangeVolume(1)
end

function MusicWrapper.ChangeVolume(self: MusicWrapper, value: number, tweenInfo: TweenInfo?, method: "Increment" | "Set", raw: boolean?)

	self.VolumeJanitor:Cleanup()
	local OldVolume = self._DestinatedVolume

	if method == "Increment" then
		self._DestinatedVolume += value
	else
		self._DestinatedVolume = value
	end

	local AffectedVolume = self:GetRealDestinatedVolume()
	local InstanceVolume = math.clamp(AffectedVolume, 0, 1)

	if not raw then
		TrackVolumeChanged:Fire(self, AffectedVolume, OldVolume)
	end

	if not tweenInfo then
		self.Instance.Volume = InstanceVolume * self.VolumeScale
	else
		self.VolumeJanitor:Add(TweenUtility.TweenStep(tweenInfo, function(step)
			self.Instance.Volume = math.lerp(self.Instance.Volume, InstanceVolume, step) * self.VolumeScale
		end))
	end
end

function MusicWrapper.ChangePlayback(self: MusicWrapper, value: number, tweenInfo: TweenInfo?, method: "Increment" | "Set")

	self.PlaybackJanitor:Cleanup()

	local OldPlaybackSpeed = self.Instance.PlaybackSpeed

	if method == "Increment" then
		self._DestinatedPlaybackSpeed += value
	else
		self._DestinatedPlaybackSpeed = value
	end

	if not tweenInfo then
		self.Instance.PlaybackSpeed = self._DestinatedPlaybackSpeed
	else
		self.PlaybackJanitor:Add(TweenUtility.TweenStep(tweenInfo, function(step)
			self.Instance.PlaybackSpeed = math.lerp(OldPlaybackSpeed, self._DestinatedPlaybackSpeed, step)
		end))
	end
end

--//Returner

local Music = {

	Misc = {
		RoundLast30Sec = Create(MusicFolder.RoundLast30Sec, 2, { Looped = false }),
		StealthLoop = Create(MusicFolder.Misc.MissBloomieStealth, 7, { Looped = true }),
		Spectating = Create(MusicFolder.Spectating, 1, { Looped = true }),
		DayTime = Create(MusicFolder.DayTime, 0, { Looped = true, PlaybackSpeed = 1 }),
		Preloading = Create(MusicFolder.Preloading, 5, { Looped = true, PlaybackSpeed = 1 }),
		Shop = Create(MusicFolder.Shop, 5, { Looped = true, PlaybackSpeed = 0 })
	},

	Round = {
		StudentSchool = Create(MusicFolder.NightTimeSchool, 0, { Looped = true }),
		StudentCamping = Create(MusicFolder.NightTimeCamping, 0, { Looped = true }),
		Killer = Create(MusicFolder.KillerNightTime, 0, { Looped = true }),
	},

	Transition = {
		Night = Create(MusicFolder.Transition.Night, 0, { Looped = false }),
	},

	LastStand = {
		["1v3"] = Create(MusicFolder.LastStand.Teacher["1v3"], 8, { Looped = false }),
		["1v2"] = Create(MusicFolder.LastStand.Teacher["1v2"], 8, { Looped = false }),
		["1v1"] = Create(MusicFolder.LastStand.Teacher["1v1"], 8, { Looped = false })
	},

	Terror = {
		Layer1 = Create(MusicFolder.Terror.Layer1, 3, { Looped = true }),
		Layer2 = Create(MusicFolder.Terror.Layer2, 4, { Looped = true }),
		Layer3 = Create(MusicFolder.Terror.Layer3, 5, { Looped = true }),
		Layer4 = Create(MusicFolder.Terror.Layer4, 6, { Looped = true }),
	},
}

if RunService:IsClient() then

	local LastUpdate = 0
	local AudibleMap = {} :: { [Sound]: boolean }

	RunService.Heartbeat:Connect(function(dt)

		LastUpdate += dt

		if LastUpdate < AUDIBLE_UPDATE_RATE then
			return
		end

		LastUpdate = 0

		for _, Wrapper in ipairs(Objects) do

			local IsAudible = Wrapper:IsAudible()

			if AudibleMap[Wrapper.Instance] ~= IsAudible then

				AudibleMap[Wrapper.Instance] = IsAudible
				TrackAudibleChanged:Fire(Wrapper, IsAudible)
			end
		end
	end)
end

return {
	Music = Music,
	Create = Create,
	ToggleMuffled = ToggleMuffled,
	GetWrapperFromSound = GetWrapperFromSound,
	TrackEnded = TrackEnded,
	TrackPlayed = TrackPlayed,
	TrackDidLoop = TrackDidLoop,
	TrackVolumeChanged = TrackVolumeChanged,
}