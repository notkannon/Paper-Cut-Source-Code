--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local BaseCamera = require(ReplicatedStorage.Client.Classes.BaseCamera)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Types

export type Impl = {
	__index: typeof(setmetatable({} :: Impl, {} :: BaseCamera.Impl)),

	new: (controller: {any}) -> Singleton,
}

export type Fields = {
	InitialPosition: CFrame,
} & BaseCamera.Fields

export type Singleton = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Variables

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ShopCamera = workspace.Lobby.Shop.ShopCamera
local Camera = workspace.CurrentCamera
local ShopAttachedCamera = BaseCamera.CreateCamera("ShopAttachedCamera") :: Impl

--//Methods

function ShopAttachedCamera.OnConstruct(self: Singleton)
	self.InitialPosition = ShopCamera.Position
	self.FlexibilityScale = 3 --how much camera will be rotated along mouse offset on screen
end

function ShopAttachedCamera.OnStart(self: Singleton)

	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.CameraSubject = ShopCamera
	Camera.CFrame = ShopCamera.CFrame
	
	self._LastMouseRotation = CFrame.identity
end

function ShopAttachedCamera.AfterUpdate(self: Singleton, Deltatime: number)
	
	local t = os.clock()
	local Offset = CFrame.new(
		math.sin(t * 1.5) * 0.005,
		math.cos(t * 1.46) * 0.005,
		0
	)
	
	local Tilt = CFrame.Angles(
		math.sin(t * 1.51) * 0.01,
		math.cos(t * 1.48) * 0.013,
		math.cos(t * 1.45) * 0.01
	)
	
	-- Calculate desired rotation based on mouse position
	local TargetRotation = CFrame.Angles(
		math.rad( ( ((Mouse.Y - Mouse.ViewSizeY / 2) / Mouse.ViewSizeY) ) * -13 * self.FlexibilityScale ),
		math.rad( ( ((Mouse.X - Mouse.ViewSizeX / 2) / Mouse.ViewSizeX) ) * -13 * self.FlexibilityScale ),
		0
	)
	
	-- Smoothly interpolate rotation
	local Rotation = self._LastMouseRotation:Lerp(TargetRotation, 1/10)
	
	-- Compose the target camera CFrame from ShopCamera.CFrame, Offset, Tilt, and Rotation
	local TargetCFrame = ShopCamera.CFrame * Offset * Tilt * Rotation
	
	-- Smoothly interpolate the camera's CFrame towards the target
	Camera.CFrame = Camera.CFrame:Lerp(TargetCFrame, Deltatime * 10)
	
	self._LastMouseRotation = Rotation
end

--//Returner

return ShopAttachedCamera