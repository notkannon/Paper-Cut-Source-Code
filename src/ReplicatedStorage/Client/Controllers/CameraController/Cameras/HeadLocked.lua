--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCamera = require(ReplicatedStorage.Client.Classes.BaseCamera)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Constants

local DEFAULT_TWEEN_CONFIG = {
	Time = 0.3,
	EasingStyle = Enum.EasingStyle.Sine,
	EasingDirection = Enum.EasingDirection.Out,
}
--//Variables

local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local HeadLockedCamera = BaseCamera.CreateCamera("HeadLockedCamera") :: Impl

--//Types

export type Impl = {
	__index: typeof(setmetatable({} :: Impl, {} :: BaseCamera.Impl)),
	
	new: (controller: {any}) -> Singleton,
	ChangeLocalOffset: (self: Singleton, offset: Vector3 | CFrame, tweenConfig: TweenConfig?) -> (),
}

export type Fields = {
	
	IsFlexible: boolean,
	FlexibilityScale: number,

	_CameraLocalOffset: CFrame,
	_LastHeadlockRotation: CFrame,
	
} & BaseCamera.Fields

export type Singleton = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Methods

function HeadLockedCamera.ChangeLocalOffset(self: Singleton, offset: Vector3 | CFrame, tweenConfig: TweenConfig?)
	
	self.Janitor:Remove("OffsetTween")

	local Offset = typeof(offset) == "Vector3" and CFrame.new(offset) or offset

	if not tweenConfig then
		self._CameraLocalOffset = Offset
		
		return
	end

	local LastOffset = self._CameraLocalOffset
	local TweenConfig = TableKit.Reconcile(tweenConfig, DEFAULT_TWEEN_CONFIG) :: DefaultTweenConfig

	self.Janitor:Add(
		TweenUtility.TweenStep(
			TweenInfo.new(TweenConfig.Time, TweenConfig.EasingStyle, TweenConfig.EasingDirection),
			function(value)
				self._CameraLocalOffset = LastOffset:Lerp(Offset, value)
			end),
		nil,
		"OffsetTween"
	)
end

function HeadLockedCamera.OnConstruct(self: Singleton)
	self.MouseBehavior = Enum.MouseBehavior.Default
	self.FlexibilityScale = 1
end

function HeadLockedCamera.OnStart(self: Singleton)
	
	Player.CameraMode = Enum.CameraMode.LockFirstPerson
	Player.CameraMaxZoomDistance = 0.5
	Player.CameraMinZoomDistance = 0.5
	
	self.FlexibilityScale = 4 -- resetting
	self._CameraLocalOffset = CFrame.identity
	self._LastHeadlockRotation = CFrame.identity
end

function HeadLockedCamera.AfterUpdate(self: Singleton, deltaTime: number)
	
	local Character = Player.Character :: PlayerTypes.Character
	local Head = Character and Character:FindFirstChild("Head") :: BasePart?

	if not Head then
		return
	end
	
	local Offset = Head.CFrame * CFrame.new(0, 0.2, -Head.Size.Z / 2) * self._CameraLocalOffset
	
	if self.IsFlexible then
		
		local Rotation = self._LastHeadlockRotation:Lerp(
			CFrame.Angles(
				math.rad( ( ((Mouse.Y - Mouse.ViewSizeY / 2) / Mouse.ViewSizeY) ) * -13 * self.FlexibilityScale ),
				math.rad( ( ((Mouse.X - Mouse.ViewSizeX / 2) / Mouse.ViewSizeX) ) * -13 * self.FlexibilityScale ),
				0
			),
			1/10
		)

		Camera.CFrame = Offset * Rotation
		
		self._LastHeadlockRotation = Rotation
		
	else
		Camera.CFrame = Offset
	end
	
	self.Controller._LastCameraCFrame = Camera.CFrame
end

--//Returner

return HeadLockedCamera