--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)

local Signal = require(ReplicatedStorage.Packages.Signal)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Classes = require(ReplicatedStorage.Shared.Classes)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

local CameraShaker = require(ReplicatedStorage.Packages.CameraShaker)
local PlayerController = require(ReplicatedStorage.Client.Controllers.PlayerController)
local SettingsController = require(ReplicatedStorage.Client.Controllers.SettingsController)
local CameraShakerPresets = require(ReplicatedStorage.Packages.CameraShaker.CameraShakePresets)

local DefaultCamera = require(script.Cameras.Default)
local HeadLockedCamera = require(script.Cameras.HeadLocked)
local ForceLockedCamera = require(script.Cameras.ForceLocked)
local FreeAttachedCamera = require(script.Cameras.FreeAttached)
local ShopAttachedCamera = require(script.Cameras.ShopAttached)
local ResultAttachedCamera = require(script.Cameras.ResultAttached)

--//Constants

local BASE_FOV = 70

local DEFAULT_TWEEN_CONFIG = {
	Time = 0.3,
	EasingStyle = Enum.EasingStyle.Sine,
	EasingDirection = Enum.EasingDirection.Out,
}

--//Variables

local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local CameraController = Classes.CreateSingleton("CameraController") :: Impl

--//Types

type AnyCamera = DefaultCamera.Singleton | HeadLockedCamera.Singleton | ForceLockedCamera.Singleton | ShopAttachedCamera.Singleton | ResultAttachedCamera.Singleton
type AnyCameraName = "Default" | "ForceLocked" | "FreeAttached" | "HeadLocked" | "ShopAttached" | "ResultAttached"

type TweenConfig = {
	Time: number?,
	EasingStyle: Enum.EasingStyle?,
	EasingDirection: Enum.EasingDirection?,
}

type DefaultTweenConfig = {
	Time: number,
	EasingStyle: Enum.EasingStyle,
	EasingDirection: Enum.EasingDirection,
}

export type Impl = {
	__index: Impl,

	IsImpl: (self: Controller) -> boolean,
	GetName: () -> "CameraController",
	GetExtendsFrom: () -> nil,
	
	ChangeBaseFov: (self: Controller, value: number) -> (),

	GetCurrentFov: (self: Controller) -> number,
	GetDestinedFov: (self: Controller) -> number,

	ChangeFov: (self: Controller, value: number, method: "Set" | "Increment", tweenConfig: TweenConfig) -> (),
	QuickShake: (self: Controller, duration: number?, scale: number?, presetName: string?) -> (),
	SetActiveCamera: (self: Controller, mode: AnyCameraName) -> (),
	ToggleCameraHandler: (self: Controller, enabled: boolean) -> (),

	new: () -> Controller,
	OnConstruct: (self: Controller) -> (),
	OnConstructClient: (self: Controller) -> (),
	
	_InitCameras: (self: Controller) -> (),
	_ConnectEvents: (self: Controller) -> (),
	_InitRenderSteps: (self: Controller) -> (),
}

export type Fields = {
	Instance: Camera,

	CurrentFov: number,
	DestinedFov: number,
	IncrementFov: number,
	
	Janitor: Janitor.Janitor,
	ActiveCamera: AnyCamera,
	
	CameraChanged: Signal.Signal<unknown>,
	
	Cameras: {
		Default: DefaultCamera.Singleton,
		HeadLocked: HeadLockedCamera.Singleton,
		ForceLocked: ForceLockedCamera.Singleton,
		ShopAttached: ShopAttachedCamera.Singleton,
		FreeAttached: FreeAttachedCamera.Singleton,
		ResultAttached: ResultAttachedCamera.Singleton,
	},

	_Shaker: typeof(CameraShaker),
	_SpeedFovScale: number,
	_LastCameraCFrame: CFrame,
	
	_RenderStepLocked: boolean,
	_RenderStepEnabled: boolean,
	_FirstPersonEnabled: boolean,
}

export type Controller = typeof(setmetatable({} :: Fields, CameraController :: Impl))

--//Methods

function CameraController.GetDestinedFov(self: Controller)
	return self.DestinedFov
end

function CameraController.GetCurrentFov(self: Controller)
	return self.CurrentFov
end

function CameraController.ToggleCameraHandler(self: Controller, enabled: boolean)
	self._RenderStepEnabled = enabled
end

function CameraController.ChangeBaseFov(self: Controller, value: number)
	BASE_FOV = value
end

function CameraController.SetActiveCamera(self: Controller, camera: AnyCameraName)
	
	local Camera = nil
	
	if camera then
		Camera = self.Cameras[camera]
		assert(Camera, `Camera "{ camera }" doesn't exist`)
	end
	
	if Camera == self.ActiveCamera then
		warn("Attempted to use already active Camera mode", Camera)
		return
	end
	
	if self.ActiveCamera then
		self.ActiveCamera.Active = false
		--print(Camera, self.ActiveCamera)
		if self.ActiveCamera.OnEnd then
			self.Janitor:Add(task.spawn(self.ActiveCamera.OnEnd, self.ActiveCamera))
		end
	end
	
	self.ActiveCamera = Camera
	self.ActiveCamera.Active = true
	self.Janitor:Add(task.spawn(self.ActiveCamera.OnStart, self.ActiveCamera), nil, "ActiveCameraOnStartThread")
	
	self.CameraChanged:Fire(Camera)
end

function CameraController.ChangeFov(self: Controller, value: number, method: "Set" | "Increment", tweenConfig: TweenConfig?)
	print('fov set to', BASE_FOV, 'method', method, 'tinfo', tweenConfig)
	self.Janitor:Remove("FovTween")
	self.DestinedFov = ((method == "Increment") and self.DestinedFov + value) or (method == "Set" and value)

	if not tweenConfig then
		self.CurrentFov = self.DestinedFov
		return
	end

	local LastFov = self.CurrentFov
	local TimeLerp = MathUtility.Lerp(LastFov, self.DestinedFov)
	local TweenConfig: DefaultTweenConfig = TableKit.Reconcile(tweenConfig, DEFAULT_TWEEN_CONFIG)

	self.Janitor:Add(
		TweenUtility.TweenStep(
			TweenInfo.new(TweenConfig.Time, TweenConfig.EasingStyle, TweenConfig.EasingDirection),
			function(time)
				self.CurrentFov = TimeLerp(time)
			end),
		nil,
		"FovTween"
	)
end

function CameraController.QuickShake(self: Controller, duration: number?, scale: number?, presetName: string?)
	
	local ShakerInstance = self._Shaker.Presets[ presetName or "Bump" ]
	ShakerInstance.fadeOutDuration = duration / 2 or ShakerInstance.fadeOutDuration
	ShakerInstance.fadeInDuration = duration / 2
	ShakerInstance.Magnitude *= scale or 1

	self._Shaker:Shake(ShakerInstance)
end

function CameraController._ConnectEvents(self: Controller)
	
	local function OnCharacterAdded(component)
		--resetting FOV
		self:ChangeFov(BASE_FOV, "Set")
		
		--spectator camera handling
		if PlayerController:IsSpectator() then
			
			self:ChangeFov(BASE_FOV, "Set")
			self:SetActiveCamera("FreeAttached")
			
			return
		end
		
		--if we're NOT spectator
		self:SetActiveCamera("Default")
		
		--if player NOT spectator and died, he will have camera attached to head forcely
		component.Janitor:Add(component.Humanoid.Died:Connect(function()
			self:SetActiveCamera("HeadLocked")
		end))
		
		component.Janitor:Add(component.HealthChanged:Connect(function(newHealth, lastHealth)
			if newHealth >= lastHealth then
				return
			end
			
			local Alpha = math.abs(lastHealth - newHealth) / component.Humanoid.MaxHealth
			
			self:ChangeFov(Alpha * -10, "Increment")
			self:ChangeFov(Alpha * 10, "Increment", {
				Time = 0.5,
				EasingStyle = Enum.EasingStyle.Quad,
				EasingDirection = Enum.EasingDirection.Out,
			})
		end))
	end
	
	--initials
	
	PlayerController.CharacterAdded:Connect(OnCharacterAdded)
	
	if PlayerController.CharacterComponent then
		OnCharacterAdded(PlayerController.CharacterComponent)
	end
end

function CameraController._InitRenderSteps(self: Controller)
	
	self._SpeedFovScale = 0
	self._RenderStepLocked = false
	self._RenderStepEnabled = true
	self._LastCameraCFrame = CFrame.identity

	RunService:BindToRenderStep("ClientCameraStepBefore", Enum.RenderPriority.Camera.Value - 1, function(...)
		
		if self._RenderStepBlocked or not self._RenderStepEnabled then
			return
		end

		if self.ActiveCamera then
			self.ActiveCamera:PreUpdate(...)
			
			UserInputService.MouseBehavior = self.ActiveCamera.MouseBehavior
		end
	end)

	RunService:BindToRenderStep("ClientCameraStepAfter", Enum.RenderPriority.Camera.Value + 1, function(...)
		
		if self._RenderStepBlocked or not self._RenderStepEnabled then
			return
		end
		
		if self.ActiveCamera then
			self.ActiveCamera:AfterUpdate(...)
		end
	end)
end

function CameraController._InitCameras(self: Controller)
	
	for _, Module in ipairs(script.Cameras:GetChildren()) do
		
		local CameraSingleton = require(Module)
		local Name = CameraSingleton.GetName():sub(1, -7)
		
		self.Cameras[Name] = CameraSingleton.new(self)
	end
end

function CameraController.OnConstructClient(self: Controller)
	
	--SettingsController.SettingChanged:Connect(function(setting: string, value: number)
	--	if setting == "FieldOfViewIncrement" then
	--		self.IncrementFov = value or 0
	--	end
	--end)

	self._Shaker = CameraShaker.new(Enum.RenderPriority.Camera.Value + 2, function(resultCFrame: CFrame)
		self.Instance.CFrame *= resultCFrame
	end)
	
	self.CameraChanged = Signal.new()
	self.LockedToHead = false
	self.IncrementFov = 0
	self.DestinedFov = Camera.FieldOfView
	self.CurrentFov = Camera.FieldOfView
	self.Instance = Camera
	self.Janitor = Janitor.new()
	self.Cameras = {}
	
	self._Shaker:Start()
	
	self:_InitCameras()
	self:_InitRenderSteps()
	self:_ConnectEvents()
end

--//Returner

local Controller = CameraController.new()
return Controller