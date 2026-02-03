--//Services

local RunService = game:GetService("RunService")
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

--//Variables

local HiddenLeaving = WCS.RegisterStatusEffect("HiddenLeaving", BaseStatusEffect)

--//Types

export type Status = BaseStatusEffect.BaseStatusEffect

--//Methods

function HiddenLeaving.OnConstruct(self: Status, hideoutInstance: Instance, force: boolean?, forceAnimation: boolean?)
	BaseStatusEffect.OnConstruct(self)
	
	self.DestroyOnEnd = true
	self.ForceLeave = force
	self.ForceAnimation = forceAnimation
	self.HideoutInstance = hideoutInstance
	
	self:SetHumanoidData({
		WalkSpeed = { 0, "Set" },
		JumpPower = { 0, "Set" },
		AutoRotate = { false, "Set" },
	})
end

function HiddenLeaving.OnEndServer(self: Status)
	
	--posing to entry point
	self.Character.Instance.HumanoidRootPart.Anchored = false
end

function HiddenLeaving.OnStartServer(self: Status)
	
	--getting component from stored instance reference
	local Hideout = ComponentsManager.GetFirstComponentInstanceOf(self.HideoutInstance, "BaseHideout")
	
	--posing Student out of hideout
	self.Character.Instance.HumanoidRootPart.Anchored = true
	self.Character.Instance.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	self.Character.Instance:PivotTo(Hideout.Instance.Root.StudentOriginLeave.WorldCFrame)
	
	--forcely removing status
	if self.ForceLeave then
		
		self:End()
		
		return
	end
	
	--sound playback
	local LeaveSound = SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Instances.Locker.Leave, true
	)

	LeaveSound.Parent = Hideout.Instance.Root
	SoundUtility.AdjustSoundForCharacter(LeaveSound, self.Character.Instance)
	LeaveSound:Play()
	
	--normal animation by default
	local Animation = self.FromRoleData.Animations.Normal
	
	--changing animation type
	if self.ForceAnimation then
		
		SoundUtility.CreateTemporarySound(
			SoundUtility.GetRandomSoundFromDirectory(
				SoundUtility.Sounds.Players.Gore.FallDamage
			)
		).Parent = self.Character.Humanoid.RootPart

		SoundUtility.CreateTemporarySound(
			SoundUtility.Sounds.Players.Gore.Damage.player_damage1
		).Parent = self.Character.Humanoid.RootPart
		
		--hawk tuah
		AnimationUtility.QuickPlay(
			Hideout.Instance.AnimationController,
			Hideout.AnimationsSource.Kicked
		)
		
		--replacing
		Animation = self.FromRoleData.Animations.Forced
	
	
	else
		
		-- hawk threeuh
		AnimationUtility.QuickPlay(
			Hideout.Instance.AnimationController,
			Hideout.AnimationsSource.Leave
		)
		
	end
	
	--animation playback
	local AnimationTrack = self.Janitor:Add(
		
		AnimationUtility.QuickPlay(
			
			self.Character.Humanoid,
			Animation,
			{ Priority = Enum.AnimationPriority.Action4 }
			
		), "Stop", "AnimationTrack"
		
	)
	local Duration = AnimationUtility.PromiseDuration(AnimationTrack, 2.5, true):andThen(function(Duration)
		print('hiddenleaving speaking', Duration)
		
		--ending status after animation completes
		self.Janitor:Add(task.delay(Duration, self.End, self))
	end)
end

function HiddenLeaving.OnStartClient(self: Status)
	
	--camera handling
	CameraController:SetActiveCamera("HeadLocked")
	CameraController:ChangeFov(-15, "Increment", not self.ForceLeave and {Time = 2} or nil)
	CameraController.Cameras.HeadLocked:ChangeLocalOffset(Vector3.new(0, 0, 0), not self.ForceLeave and {Time = 2} or nil)
	CameraController.Cameras.HeadLocked.IsFlexible = false
end

function HiddenLeaving.OnEndClient(self: Status)
	
	--reverting camera
	CameraController:SetActiveCamera("Default")
end

--//Returner

return HiddenLeaving