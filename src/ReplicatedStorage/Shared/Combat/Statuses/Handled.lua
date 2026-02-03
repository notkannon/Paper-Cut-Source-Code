--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)

--//Variables

local Camera = workspace.CurrentCamera
local Handling = WCS.RegisterStatusEffect("Handled", BaseStatusEffect)

--//Types

export type Status = BaseStatusEffect.BaseStatusEffect

--//Methods

function Handling.OnConstruct(self: Status, cameraMode: string?)
	BaseStatusEffect.OnConstruct(self)
	
	self.DestroyOnEnd = true
	self.CameraMode = cameraMode
end

function Handling.OnConstructServer(self: Status)
	
	self:SetHumanoidData({
		WalkSpeed = { 0, "Set" },
		JumpPower = { 0, "Set" },
		AutoRotate = { false, "Set" },
	})
	
	self:Start()
end

function Handling.OnStartClient(self: Status)
	
	local CameraController = Classes.GetSingleton("CameraController")
	
	self.StoredCameraMode = CameraController.ActiveCamera.GetName():sub(1, -7)
	CameraController:SetActiveCamera(self.CameraMode or "HeadLocked")
	
	--attaching camera to current player
	if self.CameraMode == "FreeAttached" then
		Camera.CameraSubject = self.Character.Humanoid
	end
end

function Handling.OnEndClient(self: Status)
	
	--restoring camera
	if self.Character.Humanoid.Health > 0 then
		Classes.GetSingleton("CameraController")
			:SetActiveCamera(self.StoredCameraMode)
	end
end

--//Returner

return Handling