--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--//Imports

local Utility = require(ReplicatedStorage.Shared.Utility)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local Promise = require(ReplicatedStorage.Packages.Promise)

--//Variables

local AnimationTracks = {} :: { MyAnimationTrack? }

--//Types

type AnimationPlaybackOptions = {
	FadeTime: number?,
	Weight: number?,
	Speed: number?,
	FreezeLastFrame: boolean?
}

type MyObjectReference = Animator | Humanoid | AnimationController

export type MyAnimationTrack = {
	Animator: Animator,
	Instance: AnimationTrack,
	Connection: RBXScriptConnection,
}

--//Functions

local function GetAnimator(object: MyObjectReference)
	
	if object:IsA("Animator") then
		return object
	end
	
	assert(object:IsA("AnimationController") or object:IsA("Humanoid"), "Humanoid, AnimationController and Animator is only supported")
	
	local Animator = object:FindFirstChildWhichIsA("Animator") :: Animator

	if not Animator then
		Animator = Instance.new("Animator")
		Animator.Parent = object
	end
	
	return Animator
end

local function GetLoadedAnimations(object: MyObjectReference) : { AnimationTrack? }
	
	local Animator = GetAnimator(object)
	local LoadedAnimations = {}
	
	for _, MyAnimationTrack in ipairs(AnimationTracks) do
		if MyAnimationTrack.Animator ~= Animator then
			continue
		end
		
		table.insert(LoadedAnimations, MyAnimationTrack.Instance)
	end
	
	return LoadedAnimations
end

local function HasPlayingAnimationsWithNames(object: MyObjectReference, animations: { string }): boolean
	
	local Animator = GetAnimator(object)
	
	for _, AnimationTrack: AnimationTrack in ipairs(Animator:GetPlayingAnimationTracks()) do
		if table.find(animations, AnimationTrack.Animation.Name) then
			return true
		end
	end
end

local function HasPlayingAnimationsWithIds(object: MyObjectReference, ids: { string }): boolean
	
	local Animator = GetAnimator(object)

	for _, AnimationTrack: AnimationTrack in ipairs(Animator:GetPlayingAnimationTracks()) do
		if table.find(ids, AnimationTrack.Animation.AnimationId) then
			return true
		end
	end
end

local function GetFirstAnimationTrack(object: MyObjectReference, animation: Animation): AnimationTrack?
	local Animator = GetAnimator(object)
	
	for _, AnimationTrack in ipairs(GetLoadedAnimations(Animator)) do
		if AnimationTrack.Animation ~= animation then
			continue
		end
		
		return AnimationTrack
	end
end

local function LoadAnimationOnce(object: MyObjectReference, animation: Animation): AnimationTrack
	
	local Animator = GetAnimator(object)
	local AnimationTrack = GetFirstAnimationTrack(Animator, animation)
	
	if AnimationTrack then
		return AnimationTrack
	end
	
	if animation.AnimationId == "" then
		animation.AnimationId = "rbxassetid://18846275307"
	end
	
	AnimationTrack = Animator:LoadAnimation(animation)
	
	table.insert(AnimationTracks, {
		Animator = Animator,
		AnimationTrack = AnimationTrack,
		
		Connection = AnimationTrack.Destroying:Once(function()
			for _, MyAnimationTrack in ipairs(AnimationTracks) do
				if MyAnimationTrack.Instance ~= AnimationTrack then
					continue
				end
				
				table.remove(AnimationTracks, table.find(AnimationTracks, MyAnimationTrack))
				print("Removing animation track", MyAnimationTrack.Instance.Name)
				
				return
			end
		end)
	})
	
	return AnimationTrack
end

local function QuickPlay(object: MyObjectReference, animation: Animation, properties: ({ PlaybackOptions: AnimationPlaybackOptions } & AnimationTrack)?)
	
	local AnimationTrack = LoadAnimationOnce(object, animation)
	local PlaybackOptions = TableKit.MergeDictionary({ FadeTime = 0 }, properties and properties.PlaybackOptions or {}) :: AnimationPlaybackOptions
	
	AnimationTrack:Play(
		PlaybackOptions.FadeTime,
		PlaybackOptions.Weight,
		PlaybackOptions.Speed
	)
	
	if properties then
		
		local Properties = table.clone(properties)
		Properties.PlaybackOptions = nil
		
		Utility.ApplyParams(AnimationTrack, Properties)
	end
	
	if PlaybackOptions.FreezeLastFrame then
		
		-- a bit buggy
		local Connection = AnimationTrack.Stopped:Once(function()
			
			AnimationTrack:Play(0, 1, 0)
			if (PlaybackOptions.Speed or 1) > 0 then
				AnimationTrack.TimePosition = AnimationTrack.Length - 0.000001
			else
				AnimationTrack.TimePosition = 0
			end
		end)
	end
	
	return AnimationTrack
end

local function PromiseDuration(animationTrack: AnimationTrack, timeout: number?, compensateWaiting: boolean?) : Promise.TypedPromise<number>
	-- this function loads an animation, waits for it <={timeout} seconds, and if compensateWaiting is true, subtracts waiting time from the result
	-- if the promise times out, it returns 0 without raising an error
	
	if animationTrack.Length > 0 then
		return Promise.resolve(animationTrack.Length / animationTrack.Speed)
	end
	
	local StartClock = os.clock()
	
	return Promise.fromEvent(RunService.Heartbeat, function(delta) return animationTrack.Length > 0 end)
		:timeout(timeout or 5)
		:andThen(function()
			local EndClock = os.clock()
			local Length = animationTrack.Length
			local Duration = Length / animationTrack.Speed
			--print(`Retrieved duration {Duration}, runtime: {EndClock - StartClock}`)
			if compensateWaiting then
				return math.max(0, Duration - (EndClock - StartClock))
			end
			return Duration
		end, function(e) warn(tostring(e)) return 0 end)
end
		

--//Returner

return {
	QuickPlay = QuickPlay,
	LoadAnimationOnce = LoadAnimationOnce,
	GetLoadedAnimations = GetLoadedAnimations,
	GetFirstAnimationTrack = GetFirstAnimationTrack,
	
	PromiseDuration = PromiseDuration,
	
	HasPlayingAnimationsWithIds = HasPlayingAnimationsWithIds,
	HasPlayingAnimationsWithNames = HasPlayingAnimationsWithNames,
}