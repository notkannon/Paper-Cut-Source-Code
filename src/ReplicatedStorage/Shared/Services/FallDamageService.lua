--//Services

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Promise = require(ReplicatedStorage.Packages.Promise)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil
local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil
local PlayerController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.PlayerController) or nil
local CameraController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.CameraController) or nil
local ClientCharacterComponent = RunService:IsClient() and require(ReplicatedStorage.Client.Components.ClientCharacterComponent) or nil

--//Constants

local PI = math.pi
local HEIGHT_TRESHOLD = 10
local ALLOWED_HUMANOID_STATES = {
	Enum.HumanoidStateType.Ragdoll,
	Enum.HumanoidStateType.Freefall,
	Enum.HumanoidStateType.FallingDown,
	Enum.HumanoidStateType.PlatformStanding,
}

--//Variables

local FreeFallSound = SoundUtility.Sounds.Players.FreeFall :: Sound
local ClientCharacter: ClientCharacterComponent.Component?

local FallDamageService: Impl = Classes.CreateSingleton("FallDamageService") :: Impl
FallDamageService.FallStarted = Signal.new()
FallDamageService.Landed = Signal.new()

--//Types

export type Impl = {
	__index: Impl,

	IsImpl: (self: Service) -> boolean,
	GetName: () -> "FallDamageService",
	GetExtendsFrom: () -> nil,

	TrackFalling: (self: Service) -> (),
	CalculateFallDamage: (self: Service, startHeight: number, endHeight: number) -> number,

	new: () -> Service,
	OnConstruct: (self: Service) -> (),
	OnConstructServer: (self: Service) -> (),
	OnConstructClient: (self: Service) -> (),

	_ConnectCharacterEvents: (self: Service) -> (),
}

export type Fields = {
	Janitor: Janitor.Janitor,

	Landed: Signal.Signal<Player, number, number>,
	FallStarted: Signal.Signal<Player, number>,

	_IsTracking: boolean,
	_CurrentHeight: number,
	_FallStartHeight: number,
}

export type Service = typeof(setmetatable({} :: Fields, FallDamageService :: Impl))

--//Methods

function FallDamageService.CalculateFallDamage(self: Service, startHeight: number, endHeight: number)
	if startHeight - endHeight <= HEIGHT_TRESHOLD then
		return 0
	end
	
	return math.clamp(math.abs(startHeight - endHeight), 7, 100)
end

function FallDamageService.TrackFalling(self: Service)
	assert(not self._IsTracking, "Already tracking player falling")

	local StartHeight = ClientCharacter.HumanoidRootPart.Position.Y
	self._FallStartHeight = StartHeight
	self._IsTracking = true
	
	FreeFallSound:Play()
	FreeFallSound.Volume = 0
	FreeFallSound.PlaybackSpeed = 1
	
	self.Janitor:Add(
		task.delay(0.5, function()
			
			self.Janitor:Add(
				TweenUtility.PlayTween(
					FreeFallSound,
					TweenInfo.new(2),
					{ Volume = 1 }
				), "Cancel")
		end)
	)

	self.Janitor:Add(function()
		FreeFallSound:Stop()
		self._IsTracking = false
	end)

	self.Janitor:Add(RunService.Stepped:Connect(function()
		if not ClientCharacter then
			self.Janitor:Cleanup()
			return
		end

		if ClientCharacter.HumanoidRootPart.AssemblyLinearVelocity.Y >= 0 then
			return
		end
		
		local CurrentHeight = ClientCharacter.HumanoidRootPart.Position.Y
		self._CurrentHeight = CurrentHeight
		
		if table.find(ALLOWED_HUMANOID_STATES, ClientCharacter.Humanoid:GetState()) then
			return
		end
		
		
		if self:CalculateFallDamage(StartHeight, CurrentHeight) > 0 then
			
			TweenUtility.ClearAllTweens(SoundUtility.Sounds.Players.Running)
			SoundUtility.Sounds.Players.Running.Volume = 0
			
			CameraController.Cameras.Default:TiltCamera(CFrame.Angles(-PI/math.clamp((StartHeight - CurrentHeight) * 2, 10, 40), 0, 0), false, {
				Time = 0.05,
				EasingStyle = Enum.EasingStyle.Sine,
				EasingDirection = Enum.EasingDirection.Out,
			})

			ClientRemotes.ClientLanded.Fire({
				EndHeight = CurrentHeight,
				StarterHeight = StartHeight,
			})
		end
		
		self.Janitor:Cleanup()
	end))
end

function FallDamageService._ConnectCharacterEvents(self: Service)
	
	local function HandleCharacterAdded(component)
		
		if not PlayerController:IsStudent() then
			return
		end
		
		ClientCharacter = component
		ClientCharacter.Janitor:Add(ClientCharacter.Humanoid.StateChanged:Connect(function(_, state)
			if not table.find(ALLOWED_HUMANOID_STATES, state) then
				return
			end

			if self._IsTracking then
				return
			end

			self.Janitor:Cleanup()
			self:TrackFalling()
		end))
	end
	
	PlayerController.CharacterAdded:Connect(HandleCharacterAdded)
	PlayerController.CharacterRemoved:Connect(function()
		ClientCharacter = nil
		self.Janitor:Cleanup()
	end)
	
	if PlayerController.CharacterComponent then
		HandleCharacterAdded(PlayerController.CharacterComponent)
	end
end

function FallDamageService.OnConstruct(self: Service)
	self.Janitor = Janitor.new()
	self._IsTracking = false
end

function FallDamageService.OnConstructServer(self: Service)
	
	self.Landed = Signal.new()
	self.FallStarted = Signal.new()
	
	ServerRemotes.ClientLanded.SetCallback(function(player, args)
		
		local CharacterComponent = ComponentsManager.Get(player.Character, "CharacterComponent")
		
		if not CharacterComponent then
			return
		end
		
		local Damage = self:CalculateFallDamage(args.StarterHeight, args.EndHeight)
		
		if Damage == 0 then
			return
		end
		
		self.Landed:Fire(player, args.StarterHeight, args.EndHeight)
		
		--temporary removed
		--CharacterComponent.WCSCharacter:TakeDamage({Damage = Damage})
		
		AnimationUtility.QuickPlay(CharacterComponent.Humanoid, ReplicatedStorage.Assets.Animations.Student.HardLand, {
			Looped = false,
			Priority = Enum.AnimationPriority.Movement,
		})
		
		local Sound = SoundUtility.CreateTemporarySound(
			SoundUtility.GetRandomSoundFromDirectory(
				SoundUtility.Sounds.Players.Gore.FallDamage
			)
		)
		
		local SpeedModifier = ModifiedSpeedStatus.new(CharacterComponent.WCSCharacter, "Multiply", 0.4, {Tag = "FallDamageSlowed", FadeOutTime = 2})
		SpeedModifier:Start(math.clamp(Damage / 10, 1, 5))
		
		Sound.Volume = math.clamp(Damage / 20, 0.05, 0.5)
		Sound.Parent = CharacterComponent.HumanoidRootPart
	end)
end

function FallDamageService.OnConstructClient(self: Service)
	self._CurrentHeight = 0
	self._FallStartHeight = 0

	self:_ConnectCharacterEvents()
end

--//Returner

local Singleton = FallDamageService.new() :: Service
return Singleton