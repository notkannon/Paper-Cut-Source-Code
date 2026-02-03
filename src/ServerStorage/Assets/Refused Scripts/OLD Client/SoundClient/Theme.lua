-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local SoundService = game:GetService('SoundService')
local ThemeSoundGroup = SoundService.Master.Music

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local Signal = require(ReplicatedStorage.Package.Signal)

-- SoundTheme initial
local SoundTheme = {}
SoundTheme._objects = {}
SoundTheme.__index = SoundTheme

-- constructor
function SoundTheme.new(source: Sound)
	assert(typeof(source) == 'Instance' and source:IsA('Sound'), `Provided source is not sound`)
	
	-- object creation
	local self = setmetatable({
		source = source,
		volume = 1,
		active_tweens = {}
	}, SoundTheme)
	
	table.insert(
		self._objects,
		self
	)
	
	self:Init()
	return self
end

-- initial method
function SoundTheme:Init()
end

-- returns theme sound reference
function SoundTheme:GetSound(): Sound
	return self.source
end

-- creates new tween and inserts it in current table
function SoundTheme:NewTween(name, ...): Tween
	local tween: Tween = TweenService:Create(...)
	
	if self.active_tweens[ name ] then
		self.active_tweens[ name ]:Cancel()
		self.active_tweens[ name ]:Destroy()
		self.active_tweens[ name ] = nil
	end
	
	self.active_tweens[ name ] = tween
	return tween
end

--[[ removes first tween with same name
function SoundTheme:RemoveTween(name: string)
	for _, tween: Tween in ipairs(self.active_tweens) do
		if tween.Name == name then
			
			tween:Cancel()
			tween:Destroy()
			return
		end
	end
end]]

-- cancels ALL of playing tweens
function SoundTheme:ClearTweens()
	for _, tween: Tween in pairs(self.active_tweens) do
		tween:Cancel()
		tween:Destroy()
	end
	
	-- raw removal
	table.clear(self.active_tweens)
end

-- returns true if sound is playing
function SoundTheme:IsPlaying(): boolean
	return self:GetSound().IsPlaying
end

-- returns native theme loudness (including volume mul)
function SoundTheme:GetLoudnessValue(): number
	if not self:IsPlaying() then return 0 end
	
	local volume: number = self:GetVolume()
	local loudness: number = self:GetSound().PlaybackLoudness
	return loudness * .001 * volume
end

-- returns current volume from sound
function SoundTheme:GetVolume(): number
	return self:GetSound().Volume
end

-- smoothly sets volume of a sound
function SoundTheme:VolumeFade(duration: number, volume: number)
	self:NewTween('Volume',
		self:GetSound(),
		TweenInfo.new( duration ),
		{Volume = volume}
	):Play()
end

-- smoothly sets playback speed of a sound
function SoundTheme:PlaybackFade(duration: number, playback: number)
	self:NewTween('PlaybackSpeed',
		self:GetSound(),
		TweenInfo.new( duration ),
		{PlaybackSpeed = playback}
	):Play()
end

-- fades both of volume and playback
function SoundTheme:FadeVolumeAndPlayback(duration: number, volume: number, playback: number)
	self:VolumeFade(duration, volume)
	self:PlaybackFade(duration, playback)
end

-- sets current sound.looped
function SoundTheme:SetLooped(looped: boolean)
	self:GetSound().Looped = looped
end

-- starts or stops source sound playback
function SoundTheme:SetPlaying(playing: boolean)
	if playing then
		self:GetSound():Play()
	else self:GetSound():Stop() end
end

-- sets source sound playback speed
function SoundTheme:SetSpeed(speed: number)
	self:GetSound().PlaybackSpeed = speed
end

-- sets source sound volume
function SoundTheme:SetVolume(volume: number)
	self:GetSound().Volume = volume
end

return SoundTheme