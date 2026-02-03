-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SoundService = game:GetService('SoundService')
local TweenService = game:GetService('TweenService')
local MusicGroup = SoundService.Master.Music

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local Theme = require(script.Theme)


-- SoundClient initial
local SoundClient = {}
SoundClient.themes = Theme._objects
SoundClient.Path = SoundService.Master

-- initial method
function SoundClient:Init()
	-- theme registering
	self:RegisterThemesIn(MusicGroup)
end

-- recursively registers every sound as new theme in provided dir
function SoundClient:RegisterThemesIn(dir: Instance)
	for _, source: Sound? in ipairs(dir:GetChildren()) do
		if source:IsA('Folder') then
			-- deep parsing
			SoundClient:RegisterThemesIn(source)
			
		elseif source:IsA('Sound') then
			-- new theme setting up
			local theme = Theme.new(source)
			theme:SetPlaying( false )
			theme:SetVolume( 0 )
		end
	end
	
	-- logging
	assert(#SoundClient.themes > 0, `No sounds detected in dir ({ dir:GetFullName() })`)
end

-- puts copy of sound instance to given place and plays it
function SoundClient:PlaySoundIn(sound: Sound, source: Instance)
	assert(sound:IsA('Sound'), 'Provided non-sound instance')
	
	-- finding already created sound instance (if looped)
	for _, a: Sound in ipairs(source:GetChildren()) do
		if not a:IsA('Sound') then continue end
		if a.SoundId == sound.SoundId and a.Looped then
			a:Play()
			return
		end
	end
	
	sound.Parent = source
	sound:Play()
	
	-- cleaning up
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

-- returns first theme object with same named source
function SoundClient:GetThemeFromName(theme_name)
	for _, theme in ipairs(SoundClient.themes) do
		if theme:GetSound().Name == theme_name then return theme end
	end
end

-- sets current theme presence
function SoundClient:SetThemePresence(presence_enum: number)
	-- PRELOADING & MENU <?>
	local PreloadingTheme = SoundClient:GetThemeFromName('Preloading')
	local MenuTheme = SoundClient:GetThemeFromName('Menu')
	
	-- non-game presences
	if presence_enum == Enums.ThemesPresence.Preloading then
		-- preloading theme loop
		PreloadingTheme:SetPlaying(true)
		PreloadingTheme:SetVolume(0)
		PreloadingTheme:SetSpeed(1)
		PreloadingTheme:VolumeFade(15, 1)
		
		-- menu theme starting but quiet
		MenuTheme:SetPlaying(true)
		MenuTheme:SetVolume(0)
		MenuTheme:SetSpeed(1)
		
	elseif presence_enum == Enums.ThemesPresence.Menu then
		-- menu theme loop
		MenuTheme:VolumeFade(1, 1)
		PreloadingTheme:VolumeFade(1, 0)
		
	elseif presence_enum == Enums.ThemesPresence.Game then
		-- transition to other non-menu presence
		MenuTheme:VolumeFade(2, 0)
		PreloadingTheme:VolumeFade(2, 0)
	end
end

-- initialize
return SoundClient