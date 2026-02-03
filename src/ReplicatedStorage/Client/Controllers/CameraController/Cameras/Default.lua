--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCamera = require(ReplicatedStorage.Client.Classes.BaseCamera)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local TerrorController = require(ReplicatedStorage.Client.Controllers.EnvironmentController.TerrorController)

--//Constants

local PI = math.pi

local CAMERA_MAX_TILT = PI / 40
local SWAY_TILT_SLOWNESS = 40

local DEFAULT_TWEEN_CONFIG = {
	Time = 0.3,
	EasingStyle = Enum.EasingStyle.Linear,
	EasingDirection = Enum.EasingDirection.In,
}

--//Variables

local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

local DefaultCamera = BaseCamera.CreateCamera("DefaultCamera") :: Impl

--//Types

export type Impl = {
	__index: typeof(setmetatable({} :: Impl, {} :: BaseCamera.Impl)),

	new: (controller: {any}) -> Singleton,
	TiltCamera: (self: Singleton, cframe: CFrame, set: boolean?, tweenConfig: TweenConfig?) -> (),
	
	_ConnectCharacterEvents: (self: Singleton) -> (),
}

export type Fields = {
	_SwayTilt: number,
	_OffsetTick: number,
	_BobbingLerp: number,
	_CameraTiltOffset: CFrame,	
	
} & BaseCamera.Fields

export type Singleton = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Methods

function DefaultCamera._ConnectCharacterEvents(self: Singleton)

end

function DefaultCamera.TiltCamera(self: Singleton, cframe: CFrame, set: boolean?, tweenConfig: TweenConfig?)
	local LastTilt = self._CameraTiltOffset
	local NewTilt = set and cframe or (self._CameraTiltOffset * cframe)

	if not tweenConfig then
		self._CameraTiltOffset = NewTilt
		
		return
	end

	local LastTime = 0
	local TweenConfig: DefaultTweenConfig = TableKit.Reconcile(tweenConfig, DEFAULT_TWEEN_CONFIG)

	TweenUtility.TweenStep(TweenInfo.new(TweenConfig.Time, TweenConfig.EasingStyle, TweenConfig.EasingDirection), function(time)
		self._CameraTiltOffset *= LastTilt:ToObjectSpace(LastTilt:Lerp(NewTilt, time - LastTime))
		LastTime = time
	end)
end

function DefaultCamera.OnConstruct(self: Singleton)
	self.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function DefaultCamera.OnStart(self: Singleton)
	
	self._SwayTilt = 0
	self._BobbingLerp = 0
	
	self._OffsetTick = os.clock()
	self._TerrorTiltValue = 0
	self._CameraTiltOffset = CFrame.identity
	
	Player.CameraMode = Enum.CameraMode.LockFirstPerson
	Player.CameraMaxZoomDistance = 0.5
	Player.CameraMinZoomDistance = 0.5
	
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = Player.Character:FindFirstChildWhichIsA("Humanoid")
end

function DefaultCamera.PreUpdate(self: Singleton, deltaTime: number)
	
	local Character = Player.Character :: PlayerTypes.Character
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(Character)
	local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart") or nil :: BasePart

	if not Character
		or not WCSCharacter
		or not HumanoidRootPart then
		
		return
	end
	
	local Speed = Character.Humanoid.WalkSpeed / WCSCharacter:GetDefaultProps().WalkSpeed
	local FallVelocity = math.clamp(HumanoidRootPart.AssemblyLinearVelocity.Y * 0.03, -30, 0)

	self.Controller._SpeedFovScale = math.max(1, 
		MathUtility.QuickLerp(self.Controller._SpeedFovScale, MathUtility.QuickLerp(Speed + FallVelocity, 1, 0.8), math.min(deltaTime * 2.4, 1))
	)

	Camera.FieldOfView = self.Controller.CurrentFov * self.Controller._SpeedFovScale + self.Controller.IncrementFov
	--print('setting fov to', Camera.FieldOfView, 'due to:', self.Controller.CurrentFov, self.Controller._SpeedFovScale, self.Controller.IncrementFov)

	Character.Humanoid.CameraOffset = Character.Humanoid.CameraOffset:Lerp(
		HumanoidRootPart.CFrame:ToObjectSpace(Character.Head.CFrame).Position
		- Vector3.yAxis * 1.75
		- Vector3.zAxis * 1,
		math.min(deltaTime * 6, 1)
	)

	Camera.CFrame = self.Controller._LastCameraCFrame
end

function DefaultCamera.AfterUpdate(self: Singleton, deltaTime: number)
	
	local Character = Player.Character :: PlayerTypes.Character
	local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart") or nil
	
	if not HumanoidRootPart then
		return
	end
	
	local YDiff = select(2, self.Controller._LastCameraCFrame:ToObjectSpace(Camera.CFrame):ToOrientation())
	
	self.Controller._LastCameraCFrame = Camera.CFrame
	
	self._SwayTilt = math.clamp(self._SwayTilt + YDiff / PI, -CAMERA_MAX_TILT, CAMERA_MAX_TILT)

	local Velocity = HumanoidRootPart.AssemblyLinearVelocity
	local Speed = (Velocity * Vector3.new(1, 0, 1)).Magnitude
	local TrueSpeed = Speed / 16

	self._OffsetTick += TrueSpeed * deltaTime * 12
	self._BobbingLerp = MathUtility.QuickLerp(self._BobbingLerp, math.min(Speed, 1) * math.rad(0.5), math.min(deltaTime * 5, 1))

	Camera.CFrame *= CFrame.Angles(0, 0, self._SwayTilt) * self._CameraTiltOffset * CFrame.Angles(
		-math.rad(math.tanh(Velocity.Y / 100) * 10) + (math.sin(self._OffsetTick) * self._BobbingLerp),
		(math.cos(self._OffsetTick / 2) * self._BobbingLerp),
		0
	)
	
	--WHAT
	local TerrorLayer = TerrorController:GetCurrentLayer()
	local LayerId = TerrorController:GetCurrentLayerId()
	
	if TerrorLayer then
		
		local Sound = TerrorLayer.Instance :: Sound
		self._TerrorTiltValue = MathUtility.QuickLerp(self._TerrorTiltValue, Sound.PlaybackLoudness / 700, math.min(deltaTime * 2 * LayerId, 1))
		
		Camera.FieldOfView += self._TerrorTiltValue * 1.2
	else
		self._TerrorTiltValue = MathUtility.QuickLerp(self._TerrorTiltValue, 0, math.min(deltaTime * 3, 1))
	end

	self._SwayTilt = MathUtility.QuickLerp(self._SwayTilt, 0, math.min(deltaTime * (SWAY_TILT_SLOWNESS / math.clamp(Speed * 2, 1, 5)), 1))
	self._CameraTiltOffset = self._CameraTiltOffset:Lerp(CFrame.identity, deltaTime * 30)
end

--//Returner

return DefaultCamera