----//Services

--local Players = game:GetService("Players")
--local RunService = game:GetService("RunService")
--local UserInputService = game:GetService("UserInputService")
--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local ServerScriptService = game:GetService("ServerScriptService")

----//Imports

--local WCS = require(ReplicatedStorage.Packages.WCS)
--local TableKit = require(ReplicatedStorage.Packages.TableKit)
--local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
--local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)
--local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--local HideoutLimitedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Survivor.HideoutLimited)

--local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
--local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
--local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

--local MusicUtility = RunService:IsClient() and require(ReplicatedStorage.Client.Utility.MusicUtility) or nil
--local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil
--local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil
--local CameraController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.CameraController) or nil

----//Constants

--local MAX_HIDING_DURATION = 20
--local START_PANICKING_AFTER = 7

----//Variables

--local HideoutSounds = SoundUtility.Sounds.Players.Hideout

--local Hidden = WCS.RegisterStatusEffect("Hidden", BaseStatusEffect) :: Status

----//Types

--type Metadata = {
--	Entered: boolean?,
--	IsLeaving: boolean?,
--}

--export type Status = BaseStatusEffect.BaseStatusEffect & {
--	Hideout: any,
--	IsPanicking: boolean,

--	_StartTimestamp: number,
--	_IsLeaveProcessing: boolean,

--	_OnEnterClient: (self: Status) -> (),
--	_OnLeaveClient: (self: Status, force: boolean?) -> (),
--	_HandleHideoutLeave: (self: Status, force: boolean?, cooldown: number?) -> (),
--}

----//Methods

--function Hidden._HandleHideoutLeave(self: Status, force: boolean?, cooldown: number?)
--	assert(RunService:IsServer())

--	if not self.Hideout
--		or self.Hideout:GetOccupant() ~= self.Player then

--		return
--	end

--	local Metadata: Metadata? = self:GetMetadata()
--	local Character: PlayerTypes.Character = self.Character.Instance
--	local TimePassed = os.clock() - self._StartTimestamp
--	local CooldownDuration = cooldown or math.clamp(TimePassed * 1.5, 3, 60)
--	local CharacterComponent = ComponentsManager.Get(self.Character.Instance, "CharacterComponent")

--	self._IsLeaveProcessing = true

--	CharacterComponent.Appearance:ApplyTransparency(0)

--	if coroutine.running() ~= self.GenericJanitor:Get("PanickingActivator") then
--		self.GenericJanitor:Remove("PanickingActivator")
--	end
	
--	self.GenericJanitor:Remove("IdleAnimation")
--	self.GenericJanitor:Remove("EnterAnimation")
--	self.GenericJanitor:Remove("LockerEnterAnimation")
	
--	local Duration

--	if not force then
		
--		Character:PivotTo(self.Hideout.Instance.Root.SurvivorOriginLeave.WorldCFrame)
		
--		SoundUtility.CreateTemporarySound(
--			SoundUtility.Sounds.Instances.Locker.Leave
--		).Parent = self.Hideout.Instance.Root
		
--		if not self.IsPanicking then
			
--			-- if player is not panicking
			
--			AnimationUtility.QuickPlay(self.Hideout.Instance.AnimationController, self.Hideout.AnimationsSource.Leave)
			
--			Duration = AnimationUtility.QuickPlay(self.Character.Humanoid, self.FromRoleData.Animations.Leave, {
--				Priority = Enum.AnimationPriority.Action4
--			}).Length
			
--		else
			
--			-- if player is panicking
			
--			SoundUtility.CreateTemporarySound(
--				SoundUtility.GetRandomSoundFromDirectory(
--					SoundUtility.Sounds.Players.Gore.FallDamage
--				)
--			).Parent = self.Character.Humanoid.RootPart
			
--			SoundUtility.CreateTemporarySound(
--				SoundUtility.Sounds.Players.Gore.Damage.player_damage1
--			).Parent = self.Character.Humanoid.RootPart
			
--			AnimationUtility.QuickPlay(self.Hideout.Instance.AnimationController, self.Hideout.AnimationsSource.Kicked)

--			Duration = AnimationUtility.QuickPlay(self.Character.Humanoid, self.FromRoleData.Animations.Kicked, {
--				Priority = Enum.AnimationPriority.Action4
--			}).Length
--		end
		
--		self:SetMetadata(TableKit.MergeDictionary(Metadata or {}, {
--			IsLeaving = true
--		} :: Metadata))

--		task.wait(Duration)

--		HideoutLimitedStatus.new(self.Character):Start(CooldownDuration)

--		Character.HumanoidRootPart.Anchored = false

--		if not self.Hideout:IsDestroyed() then
--			self.Hideout.Interaction:ApplyCooldown(self.Hideout.CooldownDuration)
--		end

--	elseif RunService:IsStudio() then
--		warn(`{ self.Player.Name } was forcely removed from hideout`)
--	end

--	self:End()
--end

--function Hidden._OnEnterClient(self: Status)
	
--	MusicUtility.ToggleMuffled(true, TweenInfo.new(2.5))
--	CameraController:ChangeFov(15, "Increment", {Time = 2})
--	CameraController.Cameras.HeadLocked:ChangeLocalOffset(Vector3.new(0, 2, 1), {Time = 3})
--	CameraController.Cameras.HeadLocked.IsFlexible = true

--	local NextSoundTime = os.clock() + 3

--	self.GenericJanitor:Add(RunService.Heartbeat:Connect(function()
--		if os.clock() - NextSoundTime < 0 then
--			return
--		end

--		local Path = self.IsPanicking and HideoutSounds.Panicking or HideoutSounds.Breath
--		local Sound = SoundUtility.GetRandomSoundFromDirectory(Path)

--		Sound:Play()

--		NextSoundTime = os.clock() + Sound.TimeLength + (not self.IsPanicking and math.random(2, 5) or 0)
--	end))

--	-- panicking init
--	self.GenericJanitor:Add(task.delay(START_PANICKING_AFTER, function()
--		self.IsPanicking = true

--		local Duration = MAX_HIDING_DURATION - START_PANICKING_AFTER

--		CameraController:ChangeFov(-15, "Increment", {Time = Duration})

--		HideoutSounds.Heartbeat.PlaybackSpeed = 0.7
--		HideoutSounds.Heartbeat.Volume = 0
--		HideoutSounds.Heartbeat:Play()

--		self.GenericJanitor:Add(
--			TweenUtility.PlayTween(

--				HideoutSounds.Heartbeat,
--				TweenInfo.new(Duration),
--				{
--					Volume = 1.5,
--					PlaybackSpeed = 1.3,
--				}
--			),
--			"Cancel"
--		)

--	end), nil, "ClientPanickingActivator")
--end

--function Hidden._OnLeaveClient(self: Status, force: boolean?)

--	-- restoring camera FoV after panicking
--	if self.IsPanicking then
--		self.GenericJanitor:Remove("ClientPanickingActivator")
--		CameraController:ChangeFov(15, "Increment", not force and {Time = 3} or nil)
--	end

--	HideoutSounds.Heartbeat:Stop()

--	MusicUtility.ToggleMuffled(false, TweenInfo.new(2))
--	CameraController:ChangeFov(-15, "Increment", not force and {Time = 2} or nil)
--	CameraController.Cameras.HeadLocked.IsFlexible = false
--	CameraController.Cameras.HeadLocked:ChangeLocalOffset(Vector3.new(0, 0, 0), not force and {Time = 2} or nil)
--end

--function Hidden.OnStartServer(self: Status)
--	local Character = self.Character.Instance :: PlayerTypes.Character
--	local CharacterComponent = ComponentsManager.Get(self.Character.Instance, "CharacterComponent")

--	Character.HumanoidRootPart.Anchored = true
--	Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
--	Character:PivotTo(self.Hideout.Instance.Root.SurvivorOriginEnter.WorldCFrame)

--	self.GenericJanitor:Add(AnimationUtility.QuickPlay(self.Hideout.Instance.AnimationController, self.Hideout.AnimationsSource.Enter), "Stop", "EnterAnimation")
--	local Duration = self.GenericJanitor:Add(
--			AnimationUtility.QuickPlay(self.Character.Humanoid, self.FromRoleData.Animations.Enter,
--				{
--					Priority = Enum.AnimationPriority.Action4
--				}
--			),
--			"Stop",
--		"LockerEnterAnimation"
--	).Length

--	self.GenericJanitor:Add(AnimationUtility.QuickPlay(self.Character.Humanoid, self.FromRoleData.Animations.Idle, {
--		Looped = true,
--		Priority = Enum.AnimationPriority.Action,
--		PlaybackOptions = { FadeTime = 4 }
--	}), "Stop", "IdleAnimation")

--	self._StartTimestamp = os.clock() + Duration

--	-- hideout cooldown handler thread
--	self.GenericJanitor:Add(task.delay(MAX_HIDING_DURATION, function()
		
--		self.IsPanicking = true
--		self:_HandleHideoutLeave(false, 75)
		
--	end), nil, "PanickingActivator")

--	self.GenericJanitor:Add(task.delay(Duration * 0.7, function()
--		CharacterComponent.Appearance:ApplyTransparency(1)
--		self:SetMetadata({ Entered = true } :: Metadata)
--	end))

--	SoundUtility.CreateTemporarySound(
--		SoundUtility.Sounds.Instances.Locker.Enter
--	).Parent = self.Hideout.Instance.Root
--end

--function Hidden.OnEndServer(self: Status)
--	if self.Hideout and not self.Hideout:IsDestroyed() then
--		self.Hideout:SetOccupant(nil)
--	end
--end

--function Hidden.OnStartClient(self: Status)
--	CameraController:SetActiveCamera("HeadLocked")

--	self.GenericJanitor:Add(UserInputService.InputBegan:Connect(function(input, isProcessed)
--		if not isProcessed and input.KeyCode == Enum.KeyCode.E then
--			ClientRemotes.HideoutLeavePrompt:Fire()
--		end
--	end))
--end

--function Hidden.OnEndClient(self: Status)
--	self.GenericJanitor:Cleanup()

--	CameraController:SetActiveCamera("Default")

--	local Metadata = self:GetMetadata() :: Metadata?
--	if Metadata and Metadata.IsLeaving then
--		return
--	end

--	self:_OnLeaveClient(true)
--end

--function Hidden.OnConstruct(self: Status)
--	BaseStatusEffect.OnConstruct(self)

--	self.DestroyOnEnd = true

--	self:SetHumanoidData({
--		WalkSpeed = { 0, "Set" },
--		JumpPower = { 0, "Set" },
--		AutoRotate = { false, "Set" },
--	})
--end

--function Hidden.OnConstructServer(self: Status, instance: Instance, impl: string)
--	self.Hideout = ComponentsManager.Get(instance, impl)
--	self._IsLeaveProcessing = false

--	self.GenericJanitor:Add(ServerRemotes.HideoutLeavePrompt.On(function(player: Player)
--		if self._IsLeaveProcessing
--			or player ~= self.Player
--			or not self:GetState().IsActive
--			or self.Hideout.Interaction:IsCooldowned() then
			
--			return
--		end

--		self:_HandleHideoutLeave()
--	end))

--	self.Destroyed:Once(function()
--		if self._IsLeaveProcessing then
--			return
--		end

--		self:_HandleHideoutLeave(true)
--	end)
--end

--function Hidden.OnConstructClient(self: Status)
--	self.GenericJanitor:Add(self.MetadataChanged:Connect(function(meta: Metadata, oldMeta: Metadata)
--		if (not oldMeta or not oldMeta.Entered) and meta.Entered then
--			self:_OnEnterClient()

--		elseif (not oldMeta or not oldMeta.IsLeaving) and meta.IsLeaving then
--			self:_OnLeaveClient(false)
--		end
--	end))
--end

----//Returner

--return Hidden
return nil