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

local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local CameraController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.CameraController) or nil
local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil

--//Variables

local Hidden = WCS.RegisterStatusEffect("Hidden", BaseStatusEffect)

--//Types

export type Status = BaseStatusEffect.BaseStatusEffect

--//Methods

function Hidden.OnConstruct(self: Status, hideoutInstance: Instance)
	BaseStatusEffect.OnConstruct(self)
	
	self.DestroyOnEnd = true
	self.HideoutInstance = hideoutInstance
	
	self:SetHumanoidData({
		WalkSpeed = { 0, "Set" },
		JumpPower = { 0, "Set" },
		AutoRotate = { false, "Set" },
	})
end

function Hidden.OnEndServer(self: Status)
	
	--making player visible
	ComponentsManager
		.GetFirstComponentInstanceOf(self.Character.Instance, "BaseAppearance")
		:ApplyTransparency(0)
end

function Hidden.OnStartServer(self: Status)
	
	--getting component from stored reference
	local Hideout = ComponentsManager.GetFirstComponentInstanceOf(self.HideoutInstance, "BaseHideout")
	
	--fixed player's position
	self.Character.Instance.HumanoidRootPart.Anchored = true
	self.Character.Instance.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	self.Character.Instance:PivotTo(Hideout.Instance.Root.StudentOriginEnter.WorldCFrame)
	
	--making player invisible
	ComponentsManager
		.GetFirstComponentInstanceOf(self.Character.Instance, "BaseAppearance")
		:ApplyTransparency(1)
	
	--animation playback
	self.Janitor:Add(
		
		AnimationUtility.QuickPlay(
			
			self.Character.Humanoid,
			self.FromRoleData.Animation,
			{
				Looped = true,
				Priority = Enum.AnimationPriority.Action,
				PlaybackOptions = { FadeTime = 4 },
			}
		), "Stop", "AnimationTrack"
	)
end

function Hidden.OnStartClient(self: Status)
	
	local DefaultKeybinds = require(ReplicatedStorage.Shared.Data.Keybinds)
	
	--binding leave requests
	self.GenericJanitor:Add(UserInputService.InputBegan:Connect(function(input, isProcessed)
		
		--TODO: "Interact" input handler
		if not isProcessed and (input.KeyCode == DefaultKeybinds.Interaction.Gamepad[1] or input.KeyCode == DefaultKeybinds.Interaction.Keyboard[1]) then
			
			ClientRemotes.HideoutLeavePrompt:Fire()
		end
	end))
	
	--camera handling
	CameraController:SetActiveCamera("HeadLocked")
	CameraController:ChangeFov(15, "Increment", {Time = 2})
	CameraController.Cameras.HeadLocked.IsFlexible = true
	CameraController.Cameras.HeadLocked:ChangeLocalOffset(Vector3.new(0, 0.5, 1), {Time = 3})
end

function Hidden.OnEndClient(self: Status)
	
	--reverting camera
	CameraController:SetActiveCamera("Default")
end

--//Returner

return Hidden