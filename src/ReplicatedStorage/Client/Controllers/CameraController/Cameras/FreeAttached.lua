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

--//Variables

local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local FreeAttachedCamera = BaseCamera.CreateCamera("FreeAttachedCamera") :: Impl

--//Types

export type Impl = {
	__index: typeof(setmetatable({} :: Impl, {} :: BaseCamera.Impl)),
	
	new: (controller: {any}) -> Singleton,
}

export type Fields = {
} & BaseCamera.Fields

export type Singleton = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Methods

function FreeAttachedCamera.OnConstruct(self: Singleton)
	self.MouseBehavior = Enum.MouseBehavior.Default
end

function FreeAttachedCamera.OnStart(self: Singleton)
	Player.CameraMode = Enum.CameraMode.Classic
	Player.CameraMaxZoomDistance = 10
	Player.CameraMinZoomDistance = 5
	
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = Player.Character.Humanoid
end

--//Returner

return FreeAttachedCamera