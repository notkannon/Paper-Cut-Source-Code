--[[
	Creates (temporary) sounds for usage ingame

	Examples: Hit sounds, explosion sounds, death sounds, etc.
--]]

--//Services

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Janitor = require(ReplicatedStorage.Packages.Janitor)

local Utility = require(ReplicatedStorage.Shared.Utility)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local ThreadUtility = require(ReplicatedStorage.Shared.Utility.ThreadUtility)
local FootstepSounds = require(ReplicatedStorage.Shared.Data.FootstepSounds)
local SpatialDebugger = require(ReplicatedStorage.Shared.Utility.SpatialDebugger)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Constants

local DEBUG_MUFFLED_SOUNDS = false
local MUFFLED_SOUND_UPDATE_RATE = 0.5

--//Veriables

local DefaultSoundParams = table.freeze({
	Volume = 1,
	RollOffMode = Enum.RollOffMode.LinearSquare,
	RollOffMinDistance = 7,
	RollOffMaxDistance = 27
} :: {} & Sound)

--//Functions

local function ApplySoundEffect(
	effectName: "EqualizerSoundEffect" | "ChorusSoundEffect" | "CompressorSoundEffect" | "DistortionSoundEffect" | "EchoSoundEffect" | "FlangeSoundEffect" | "PitchShiftSoundEffect" | "ReverbSoundEffect",
	params: {[string]: any},
	config: {FadeInTime: number?, FadeOutTime: number?}?
): () -> ()
	
	local cleanupJanitor = Janitor.new()

	-- Создаем эффекты для всех SoundGroup
	local soundGroup = SoundService.Master

	local effect = Instance.new(effectName)
	cleanupJanitor:LinkToInstance(effect)
	effect.Parent = soundGroup

	-- Применяем параметры
	if params then
		Utility.ApplyParams(effect, params)
	end

	-- Fade In если нужно
	if config and config.FadeInTime and config.FadeInTime > 0 then
		
		local originalParams = TableKit.DeepCopy(params or {})

		for prop, value in pairs(originalParams) do
			if typeof(value) == "number" then
				effect[prop] = 0
			end
		end

		local tweenInfo = TweenInfo.new(
			config.FadeInTime,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.In
		)

		local tween = TweenUtility.PlayTween(effect, tweenInfo, originalParams)
		cleanupJanitor:Add(tween, "Cancel")
	end

	-- Возвращаем функцию для cleanup
	return function()
		-- Fade Out если нужно
		if config and config.FadeOutTime and config.FadeOutTime > 0 then
			
			local tweenGoals = {}
			
			for prop, _ in pairs(params or {}) do
				if typeof(effect[prop]) == "number" then
					tweenGoals[prop] = 0
				end
			end

			local tweenInfo = TweenInfo.new(
				config.FadeOutTime,
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out
			)

			local tween = TweenUtility.PlayTween(effect, tweenInfo, tweenGoals)
			
			task.delay(config.FadeOutTime, function()
				effect:Destroy()
			end)
		else
			-- Немедленное удаление
			cleanupJanitor:Destroy()
		end
	end
end

local function RegisterSoundIDs(soundIDs: {string}, directory: Folder, soundGroup: SoundGroup?, params: ({} & Sound)?)
	for index, SoundId: string in ipairs(soundIDs) do
		local Sound = Instance.new("Sound")
		Sound.Name = directory.Name .. tostring(index)
		Sound.Parent = directory or SoundService
		Sound.SoundId = SoundId
		Sound.SoundGroup = soundGroup
		
		Utility.ApplyParams(Sound, TableKit.MergeDictionary(DefaultSoundParams, params or {}))
	end
end

local function GetRandomSoundFromDirectory(directory: Folder, recursively: boolean)
	local ActualSounds = {}
	
	for _, Sound: Sound in ipairs(recursively and directory:GetDescendants() or directory:GetChildren()) do
		if not Sound:IsA("Sound") then
			continue
		end
		
		table.insert(ActualSounds, Sound)
	end
	
	local Choosen = ActualSounds[math.random(1, #ActualSounds)]
	table.clear(ActualSounds)
	
	return Choosen
end

local function ApplySoundsFromDirectory(instanceToApply: Instance, directory: Folder, recursively: boolean)
	for _, Sound: Sound in ipairs(recursively and directory:GetDescendants() or directory:GetChildren()) do
		if not Sound:IsA("Sound") then
			continue
		end
		
		Sound:Clone().Parent = instanceToApply
	end
end

local function CreateSound(source: Sound, manualPlay: boolean?)
	local Sound = source:Clone()
	Sound.Parent = Sound.Parent or ReplicatedStorage
	
	if not manualPlay then
		Sound:Play()
	end

	return Sound
end

local function CreateTemporarySound(source: Sound, manualPlay: boolean?)
	local Sound = CreateSound(source, manualPlay)

	Sound.Ended:Once(function()
		Sound:Destroy()
	end)
	
	return Sound
end

local function FindTemporarySound(Sound: string)
	if typeof(Sound) ~= "string" then
		return
	end
	
	return SoundService:FindFirstChild(Sound, true)
end

local function CreateTemporarySoundAtPosition(position: Vector3, source: Sound, manualPlay: boolean?): Sound
	local Attachment = Instance.new("Attachment")
	Attachment.Position = position
	Attachment.Parent = workspace.Terrain
	
	local Sound = CreateTemporarySound(source, manualPlay)
	Sound.Parent = Attachment
	
	Sound.Ended:Once(function()
		Attachment:Destroy()
	end)
	
	return Sound
end

local function ScaleSoundRollOff(sound: Sound, factor: number) : Sound
	sound.RollOffMinDistance *= factor
	sound.RollOffMaxDistance *= factor
	return sound
end

local function AdjustSoundForCharacter(sound: Sound, character: Model) : Sound
	-- adjustments for stealther and future rolloff effects
	local Appearance = ComponentsManager.GetFirstComponentInstanceOf(character, "BaseAppearance")
	sound.Volume *= Appearance.Attributes.ActionVolumeScale
	ScaleSoundRollOff(sound, Appearance.Attributes.ActionRollOffScale)
	return sound
end

--//Registery

if RunService:IsClient() then
	
	-- footstep sounds registery
	for Material, SoundIds in pairs(FootstepSounds.Footstep.MaterialMap :: { [Enum.Material]: { string } }) do
		local Directory = Instance.new("Folder")
		Directory.Parent = SoundService.Master.Players.Footsteps
		Directory.Name = Material.Name
		
		ThreadUtility.UseThread(RegisterSoundIDs, SoundIds, Directory, SoundService.Master.Players.Footsteps, {
			RollOffMaxDistance = 30
		} :: {} & Sound)
	end
	
	-- sounds SoundGroup set
	for _, Sound: Sound? in ipairs(SoundService.Master:GetDescendants()) do
		if not Sound:IsA("Sound") then
			continue
		end
		
		Sound.SoundGroup = Sound:FindFirstAncestorWhichIsA("SoundGroup")
	end
end

--//Returner

--if RunService:IsClient() then
	
--	local Camera = workspace.CurrentCamera
--	local MuffledSoundConnections = {} :: { [Sound]: RBXScriptConnection }
	
--	local MuffledSoundEffectReference = Instance.new("EqualizerSoundEffect")
--	MuffledSoundEffectReference.Name = "_Muffled"
--	MuffledSoundEffectReference.Enabled = true
--	MuffledSoundEffectReference.Priority = 2
--	MuffledSoundEffectReference.LowGain = 0
--	MuffledSoundEffectReference.MidGain = 0
--	MuffledSoundEffectReference.HighGain = 0
	
--	local function CheckSoundHasSight(sound: Sound, blacklist: { Instance }?) : boolean
--		local CameraToSource
--		local Source = sound.Parent :: BasePart | Attachment
		
--		local SightRaycastParams = RaycastParams.new()
--		SightRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
--		SightRaycastParams.FilterDescendantsInstances = TableKit.MergeArrays({ workspace.Temp, workspace.Characters }, blacklist or {})
		
--		if Source:IsA("Attachment") then
--			CameraToSource = Source.WorldCFrame.Position - Camera.CFrame.Position
--		else
--			CameraToSource = Source.CFrame.Position - Camera.CFrame.Position
--		end
		
--		local Result = workspace:Raycast(
--			Camera.CFrame.Position,
--			CameraToSource.Unit * (CameraToSource.Magnitude),
--			SightRaycastParams
--		)
		
--		if Result and (Result.Instance.Transparency == 1 or not Result.Instance.CanCollide) then
--			Result = CheckSoundHasSight(sound, TableKit.MergeArrays(SightRaycastParams.FilterDescendantsInstances, { Result.Instance }))
--		end
		
--		if Result and DEBUG_MUFFLED_SOUNDS then
--			SpatialDebugger.Raycast(Camera.CFrame.Position, Result, 1.3)
--		end
		
--		return not Result
--	end
	
--	local function HandleSoundMuffled(sound: Sound)
--		local Source = sound.Parent :: BasePart | Attachment
--		local Effect = MuffledSoundEffectReference:Clone()
--		Effect.Parent = sound
		
--		local HasSight
--		local LastUpdate = 0
		
--		MuffledSoundConnections[sound] = RunService.Heartbeat:Connect(function()
--			if os.clock() - LastUpdate < MUFFLED_SOUND_UPDATE_RATE then
--				return
--			end
			
--			LastUpdate = os.clock()
			
--			local Result = CheckSoundHasSight(sound)
--			if HasSight == Result then
--				return
--			end
			
--			HasSight = Result
			
--			TweenUtility.ClearAllTweens(Effect)
--			TweenUtility.PlayTween(Effect, TweenInfo.new(1), {
--				LowGain = HasSight and 0 or -19.7,
--				MidGain = HasSight and 0 or 6.4,
--				HighGain = HasSight and 0 or -28.9,
--			})
--		end)
		
--		local function Remove()
--			if MuffledSoundConnections[sound] then
--				MuffledSoundConnections[sound]:Disconnect()
--				MuffledSoundConnections[sound] = nil
--			end
--		end
		
--		sound.Ended:Once(Remove)
--		sound.Destroying:Once(Remove)
--	end
	
--	local function HandleSoundAdded(sound: Sound?)
--		local Source = sound.Parent :: BasePart | Attachment
--		if not sound:IsA("Sound") or not (Source:IsA("BasePart") or Source:IsA("Attachment")) then
--			return
--		end
		
--		if not sound.IsPlaying then
--			sound.Played:Wait()
--		end
		
--		if sound.TimeLength > 1.3 then
--			HandleSoundMuffled(sound)
			
--		elseif not CheckSoundHasSight(sound) then
--			Utility.ApplyParams(MuffledSoundEffectReference:Clone(), {
--				Parent = sound,
--				LowGain = -19.7,
--				MidGain = 6.4,
--				HighGain = -28.9,
--			})
--		end
--	end
	
--	workspace.DescendantAdded:Connect(HandleSoundAdded)
--	for _, Descendant in ipairs(workspace:GetDescendants()) do
--		ThreadUtility.UseThread(HandleSoundAdded, Descendant)
--	end
--end

return {
	Sounds = SoundService.Master,
	
	ApplySoundEffect = ApplySoundEffect,
	
	ApplySoundsFromDirectory = ApplySoundsFromDirectory,
	GetRandomSoundFromDirectory = GetRandomSoundFromDirectory,
	
	CreateSound = CreateSound,
	FindTemporarySound = FindTemporarySound,
	CreateTemporarySound = CreateTemporarySound,
	CreateTemporarySoundAtPosition = CreateTemporarySoundAtPosition,
	
	ScaleSoundRollOff = ScaleSoundRollOff,
	AdjustSoundForCharacter = AdjustSoundForCharacter
}