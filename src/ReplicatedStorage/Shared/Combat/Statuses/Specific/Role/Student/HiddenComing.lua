--//Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local CameraController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.CameraController) or nil
local InputController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.InputController) or nil
local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil

--//Variables

local HiddenComing = WCS.RegisterStatusEffect("HiddenComing", BaseStatusEffect)

--//Types

export type Status = BaseStatusEffect.BaseStatusEffect

--//Methods

function HiddenComing.OnConstruct(self: Status, hideoutInstance: Instance)
	BaseStatusEffect.OnConstruct(self)
	
	--print(hideoutInstance)
	
	self.DestroyOnEnd = true
	self.HideoutInstance = hideoutInstance
	
	self:SetHumanoidData({
		WalkSpeed = { 0, "Set" },
		JumpPower = { 0, "Set" },
		AutoRotate = { false, "Set" },
	})
end

function HiddenComing.OnEndServer(self: Status)
	
	local Hideout = ComponentsManager.GetFirstComponentInstanceOf(self.HideoutInstance, "BaseHideout")
	
	--posing to entry point
	self.Character.Instance:PivotTo(Hideout.Instance.Root.StudentOriginLeave.WorldCFrame)
	self.Character.Instance.HumanoidRootPart.Anchored = false
end

function HiddenComing.OnStartServer(self: Status)
	
	--getting component from stored instance reference
	local Hideout = ComponentsManager.GetFirstComponentInstanceOf(self.HideoutInstance, "BaseHideout")
	
	--entry sound playback
	local EntrySound = SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Instances.Locker.Enter, true
	)
	
	EntrySound.Parent = Hideout.Instance.Root
	
	SoundUtility.AdjustSoundForCharacter(EntrySound, self.Character.Instance)
	EntrySound:Play()
	
	--posing Student inside hideout
	self.Character.Instance.HumanoidRootPart.Anchored = true
	self.Character.Instance.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	self.Character.Instance:PivotTo(Hideout.Instance.Root.StudentOriginEnter.WorldCFrame)
	
	--animation playback
	self.Janitor:Add(
		
		AnimationUtility.QuickPlay(
			
			self.Character.Humanoid,
			self.FromRoleData.Animation,
			{ Priority = Enum.AnimationPriority.Action4 }
			
		), "Stop", "AnimationTrack"
	)
end

function HiddenComing.OnStartClient(self: Status)
	
	--we can cancel entering into hideout
	self.Janitor:Add(UserInputService.JumpRequest:Connect(function()
		
		--tracking Space press imitation
		ClientRemotes.HideoutLeavePrompt:Fire()
	end))

	--camera handling
	CameraController:SetActiveCamera("HeadLocked")
	CameraController.Cameras.HeadLocked.IsFlexible = false
end

function HiddenComing.OnEndClient(self: Status)
	
	--reverting camera
	CameraController:SetActiveCamera("Default")
end

--//Returner

return HiddenComing