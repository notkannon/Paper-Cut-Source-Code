export type RawAnimation = {
	Instance: Animation,
	Speed: number,
	Looped: boolean,
	Priority: Enum,
	Name: string?
}

export type LoadedAnimation = RawAnimation & {
	Active: boolean,
	Track: AnimationTrack,
	_Connections: { RBXScriptConnection? }
}

local Client = shared.Client
local Server = shared.Server

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Animations = ReplicatedStorage.Assets.Animations.Student

-- requirements
local Util = require(ReplicatedStorage.Shared.Util)
local Enums = require(ReplicatedStorage.Enums)
local Signal = require(ReplicatedStorage.Package.Signal)


-- Animator initial
local Animator = {}
Animator._objects = {}
Animator.__index = Animator

-- constructor
function Animator.new( CharacterObject )
	local self = setmetatable({
		Animations = setmetatable({}, {__index = function(self, key: string) warn(`No animation "{ key }" exists in Animator`) end}),
		PlayingAnimations = {},
		
		Instance = CharacterObject:GetHumanoid():FindFirstChildWhichIsA('Animator') or Instance.new('Animator', CharacterObject:GetHumanoid()),
		Character = CharacterObject,
		
		_connections = {}
	}, Animator)
	
	-- raw
	table.insert(
		self._objects,
		self)
	return self
end

-- Initial method
function Animator:Init(animations: { RawAnimation })
	assert(animations, 'No animation packet provided')
	
	local Animations: {[string]: LoadedAnimation} = self.Animations
	local Humanoid: Humanoid = self.Character:GetHumanoid()
	
	-- default animations loading
	for _, animation in ipairs(animations) do
		self:LoadAnimation(animation)
	end
end

-- returns first animation with same instance
function Animator:GetAnimationFromInstance(instance: Animation): LoadedAnimation
	for _, animation: LoadedAnimation in pairs(self.Animations) do
		if animation.Instance == instance then return animation end
	end
end

-- creates a copy of animation table and puts it in current animator
function Animator:LoadAnimation(input: Animation|RawAnimation, override: boolean?): LoadedAnimation
	local animation: RawAnimation = input
	
	-- creating new animation from instance
	if typeof(input) == 'Instance' then
		assert(input:IsA('Animation'), `Passed non-Animation instance type ({ input })`)
		
		animation = {
			Speed = 1,
			Looped = false,
			Instance = input,
			Priority = Enum.AnimationPriority.Action,
		}
	end
	
	local SameInstanceLoaded: LoadedAnimation? = self:GetAnimationFromInstance(animation.Instance)
	
	-- already loaded
	if SameInstanceLoaded then
		return SameInstanceLoaded
	end
	
	-- could be overriden?
	local Name = animation.Name
	local SameNameLoaded: LoadedAnimation? = rawget(self.Animations, Name or animation.Instance.Name)
	
	-- replacing old animation
	if SameNameLoaded and override then
		
		local WasPlaying: boolean = SameNameLoaded.Track.IsPlaying
		SameNameLoaded.Track:Stop()
		SameNameLoaded.Track:Destroy()
		SameNameLoaded.Track = nil
		
		-- setting RawAnimation settings
		for _k, _v in pairs(animation) do
			SameNameLoaded[_k] = _v
		end
		
		-- replacing track with same parameters (playing, looped, priority and etc.)
		-- also we will play track looped if it was looped at start, we don't want to play short animations many times
		if SameNameLoaded.Track.IsPlaying and animation.Looped then
			
			SameNameLoaded.Track = self.Instance:LoadAnimation(animation.Instance)
			SameNameLoaded.Track:AdjustSpeed(SameNameLoaded.Speed)
			SameNameLoaded.Track.Priority = SameNameLoaded.Priority
			SameNameLoaded.Track.Looped = SameNameLoaded.Looped
			SameNameLoaded.Track:Play()
		end
		
	elseif SameNameLoaded and not override then
		warn(`Attempted to load animation ("{ Name or animation.Instance.Name }") with same name without overriding.`)
		return
	end
	
	-- getting end animation
	local Animation: LoadedAnimation = SameNameLoaded or Util.DeepCopy(animation)
	
	-- animation track loading
	Animation.Active = true
	Animation._Connections = {}
	
	-- loading new track to animator instance
	if not Animation.Track then
		Animation.Track = self.Instance:LoadAnimation(Animation.Instance)
	end
	
	-- setting
	Animation.Track:AdjustSpeed(Animation.Speed)
	Animation.Track.Priority = Animation.Priority
	Animation.Track.Looped = Animation.Looped
	
	-- putting new animation to local storage
	rawset(self.Animations, Name or Animation.Instance.Name, Animation)
	return Animation
end

-- plays provided LoadedAnimation object (if exists)
function Animator:PlayAnimation(input: string|Animation|LoadedAnimation, restart_if_playing: boolean?)
	if not input then return end
	local Source: string =
		(typeof(input) == 'string' and input) or
		(typeof(input) == 'table' and input.Instance.Name) or
		(typeof(input) == 'Instance' and input.Name)
	
	assert(Source, `Wrong animation source given (Animation, LoadedAnimation or string expected, got { input })`)
	local Animation: LoadedAnimation = self.Animations[ Source ]
	
	-- no animation found
	if not Animation then
		return
	end
	
	-- animations is inactive
	if not Animation.Active then return end
	
	-- playback (restarts if second passed true)
	if (Animation.Track.IsPlaying and restart_if_playing)
		or not Animation.Track.IsPlaying then
		Animation.Track:Play()
	end
end

-- stops LoadedAnimation (if exists)
function Animator:StopAnimation(input: string|Animation|LoadedAnimation, fade_out: number?)
	if not input then return end
	local Source: string =
		(typeof(input) == 'string' and input) or
		(typeof(input) == 'table' and input.Instance.Name) or
		(typeof(input) == 'Instance' and input.Name)

	assert(Source, `Wrong animation source given (Animation, LoadedAnimation or string expected, got { input })`)
	local Animation: LoadedAnimation = self.Animations[ Source ]
	
	-- no animation found
	if not Animation then
		return
	end

	-- stopping
	Animation.Track:Stop(fade_out)
end

-- Animator destruction
function Animator:Destroy()
	for _, connection: RBXScriptConnection in ipairs(self._connections) do
		connection:Disconnect()
	end

	table.remove(Animator._objects,
		table.find(Animator._objects,
			self
		)
	)
	
	-- stopping all animations from animator
	for _, animation in pairs(self.Animations) do
		self:StopAnimation(animation)
	end
	
	setmetatable(self.Animations, nil)
	setmetatable(self, nil)
	table.clear(self)
end

return Animator