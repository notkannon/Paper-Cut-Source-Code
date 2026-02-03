--//Service

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility)


local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)

local Hidden = require(ReplicatedStorage.Shared.Combat.Statuses.Hidden)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local WCS = require(ReplicatedStorage.Packages.WCS)

local Interactable = BaseComponent.GetNameComponents().Interactable

--//Variables
local Animations = ReplicatedStorage.Assets.Animations.Locker
local TeacherAnimations = ReplicatedStorage.Assets.Animations.Teacher
local LockerAssets = ReplicatedStorage.Assets.Locker
local LockerMaster = SoundService.Master.Instances.Locker

local BaseSoundEffect = {
	Enter = LockerMaster.Enter.SoundId,
	Leave = LockerMaster.Leave.SoundId
}

local Locker = BaseComponent.CreateComponent("Locker", {
	tag = "Locker",

	predicate = function(Object: Instance)
		if not Object:IsA("ProximityPrompt") then
			return false
		end

		local CurrentLocker = Object:FindFirstAncestorWhichIsA("Model")

		if not CurrentLocker then
			return false
		end


		local DefaultModel = LockerAssets:FindFirstChild(CurrentLocker.Name)

		if not DefaultModel then
			return false
		end

		return true
	end,
}) :: Impl

--//Type
export type LockerModel = Model & {
	Door: BasePart,
	Root: BasePart & {
		EnterWeld: Attachment,
		LeaveWeld: Attachment,
		TeacherWeld: Attachment,
	},
	AnimationController: AnimationController & {
		Animator: Animator,
	},
}

export type Fields = {
	CurrentPlayer: Player?,

	MemorizedTransparency: { [BasePart]: number },
	LockerAnimator: Animator,
	LockerModel: LockerModel,
	_DefaultModel: LockerModel,
}

export type Impl = BaseComponent.ComponentImpl<nil, Fields, "Locker", ProximityPrompt, {}>
export type Component =
	BaseComponent.Component<nil, Fields, "Locker", ProximityPrompt, {}>
& typeof(setmetatable({} :: Interactable.Fields, {} :: Interactable.MyImpl))

--//Methods
function Locker.OnConstruct(self: Component)
	self.LockerModel = self.Instance:FindFirstAncestorOfClass("Model") :: LockerModel
	self._DefaultModel = ReplicatedStorage.Assets.Locker.Locker

	self.MemorizedTransparency = {}
	self.LockerAnimator = self.LockerModel.AnimationController.Animator

	Interactable.OnConstruct(self)
end

function Locker.OnConstructClient(self: Component)
	Interactable.OnConstructClient(self)

	local StudentInteraction = Interactable.CreateInteraction(self, "Student", "Role")
	
	function StudentInteraction.OnStartClient()

		if self.Instance.ObjectText == "Hide" then
			Interactable.ApplyParamsRole(self, "Student", "Role", {
				ObjectText = "Leave",
				HoldDuration = 0
			})
		else
			Interactable.ApplyParamsRole(self, "Student", "Role", {
				ObjectText = "Hide",
				HoldDuration = 1
			})
		end
	end
	
	Interactable.ApplyParamsRole(self, "Student", "Role", {ObjectText = "Hide",HoldDuration = 1})
	Interactable.ApplyParamsRole(self, "Teacher", "Team", {ObjectText = "Search",HoldDuration = 0})
end

function Locker.OnConstructServer(self: Component)
	Interactable.OnConstructServer(self)
	
	local StudentInteraction = Interactable.CreateInteraction(self, "Student", "Role")
	local TeacherInteraction = Interactable.CreateInteraction(self, "Teacher", "Team")

	--//Teacher Server
	function TeacherInteraction.OnStartServer(player: Player)
		--//Teacher
		local TeacherChar = player.Character
		local WCSTeacher = WCS.Character.GetCharacterFromInstance(TeacherChar)
		
		local Humanoid = TeacherChar.Humanoid
		local HumanoidRootPart = TeacherChar.HumanoidRootPart
		
		local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(player)
		assert(PlayerComponent, "PlayerComponent not found.")

		local Role = PlayerComponent:GetRole()

		local TeacherAnimLocker = TeacherAnimations:FindFirstChild("MissBloomie").Locker
		
		if not TeacherAnimLocker then
			return
		end
		
		--//Student
		local StudentChar: PlayerTypes.Character = self.CurrentPlayer and self.CurrentPlayer.Character
		local StudentRoot = self.CurrentPlayer and StudentChar.HumanoidRootPart
		local StudentHumanoid = self.CurrentPlayer and StudentChar.Humanoid

		local WCSCharacter = self.CurrentPlayer and WCS.Character.GetCharacterFromInstance(StudentChar)
		Interactable.ApplyFreeze(self, true)

		--//Animations
		local LockerAnim: AnimationTrack = self.Janitor:Add(self.LockerAnimator:LoadAnimation(self.CurrentPlayer and TeacherAnimLocker.LockerFound or TeacherAnimLocker.LockerNotFound),nil,"LockerAnimationTrack")
		local TeacherAnim: AnimationTrack = self.Janitor:Add(Humanoid.Animator:LoadAnimation(self.CurrentPlayer and TeacherAnimLocker.TeacherFound or TeacherAnimLocker.TeacherNotFound),nil,"TeacherAnimationTrack")
		local StudentAnim: AnimationTrack = self.CurrentPlayer and self.Janitor:Add(StudentHumanoid.Animator:LoadAnimation(TeacherAnimLocker.StudentFound),nil,"StudentAnimationTrack")
		
		HumanoidRootPart.CFrame = self.LockerModel.Root.TeacherWeld.WorldCFrame
		
		--//Student
		if self.CurrentPlayer then
			StudentRoot.CFrame = self.LockerModel.Root.KickWeld.WorldCFrame
			Interactable.ClearPermissions(self)

			StudentAnim:Play()
			
			self:Clearfromation()
			for _, AnimationTrack in ipairs(StudentHumanoid.Animator:GetPlayingAnimationTracks()) do
				if AnimationTrack.Animation ~= Animations.PlayerIdle then
					continue
				end

				AnimationTrack:Stop()
				AnimationTrack:Destroy()
				break
			end
			
			for Instance, Transparency in pairs(self.MemorizedTransparency) do
				Instance.Transparency = Transparency
			end
			
			task.delay(TeacherAnim.Length, function()
				StudentRoot.Anchored = false

				for _, Status in ipairs(WCSCharacter:GetAllActiveStatusEffectsOfType(Hidden)) do
					Status:Destroy()
				end

				self.CurrentPlayer = nil
				table.clear(self.MemorizedTransparency)
			end)
		end
		
		LockerAnim:Play()
		TeacherAnim:Play()

		Hidden.new(WCSTeacher):Start()
		HumanoidRootPart.Anchored = true
		
		task.wait(TeacherAnim.Length)
		
		HumanoidRootPart.Anchored = false

		for _, Status in ipairs(WCSTeacher:GetAllActiveStatusEffectsOfType(Hidden)) do
			Status:Destroy()
		end
		
		Interactable.ApplyFreeze(self, false)
	end

	--//Student Server
	function StudentInteraction.OnStartServer(player: Player)
		local Character = player.Character
		local WCSCharacter = WCS.Character.GetCharacterFromInstance(Character)

		local Humanoid = Character.Humanoid
		local HumanoidRootPart = Character.HumanoidRootPart

		local StudentAnimation: AnimationTrack = self.Janitor:Add(Humanoid.Animator:LoadAnimation(self.CurrentPlayer and Animations.PlayerLeave or Animations.PlayerEnter),nil,"StudentAnimationTrack")
		local LockerAnimation: AnimationTrack = self.Janitor:Add(self.LockerAnimator:LoadAnimation(self.CurrentPlayer and Animations.LockerLeave or Animations.LockerEnter),nil,"LockerAnimationTrack")

		if self.CurrentPlayer and self.CurrentPlayer ~= player then
			return
		end

		if not self.CurrentPlayer then	
			self.CurrentPlayer = player
			
			self.Janitor:Add(
				player.CharacterRemoving:Connect(function()
					Interactable.ClearPermissions(self)
					self.CurrentPlayer = nil

					table.clear(self.MemorizedTransparency)
				end),
				nil,
				"CharacterRemovingConnection"
			)

			Interactable.AddPermissionRole(self, "Student", "Role", {player.UserId})
			Hidden.new(WCSCharacter):Start()	
			
			SoundUtility.CreateTemporarySoundAtPosition(self.LockerModel.Root.Position, {
				SoundId = BaseSoundEffect.Enter,
				Volume = 0.5,
			})

			HumanoidRootPart.Anchored = true

			HumanoidRootPart.CFrame = self.LockerModel.Root.EnterWeld.WorldCFrame
			StudentAnimation:Play()
			LockerAnimation:Play()

			task.wait(StudentAnimation.Length)
			
			for _, Instance in ipairs(Character:GetChildren()) do
				if not Instance:IsA("BasePart") or Instance.Name == "Head" then
					continue
				end

				self.MemorizedTransparency[Instance] = Instance.Transparency
				Instance.Transparency = 1
			end

			self.Janitor:Add(Humanoid.Animator:LoadAnimation(Animations.PlayerIdle)):Play()
		else
			self.Janitor:Remove("CharacterRemovingConnection")		
			Interactable.ClearPermissions(self)

			SoundUtility.CreateTemporarySoundAtPosition(self.LockerModel.Root.Position, {
				SoundId = BaseSoundEffect.Leave,
				Volume = 0.5,
			})

			for Instance, Transparency in pairs(self.MemorizedTransparency) do
				Instance.Transparency = Transparency
			end

			self:Clearfromation()
			for _, AnimationTrack in ipairs(Humanoid.Animator:GetPlayingAnimationTracks()) do
				if AnimationTrack.Animation ~= Animations.PlayerIdle then
					continue
				end

				AnimationTrack:Stop()
				AnimationTrack:Destroy()
				break
			end


			StudentAnimation:Play(0)
			LockerAnimation:Play()
			HumanoidRootPart.CFrame = self.LockerModel.Root.LeaveWeld.WorldCFrame
			
			task.wait(StudentAnimation.Length) --StudentAnimation.Stopped:Wait() i'm not gonna use that cuz sometimes the Length will be zero so the player will be stuck in the locker it's better to just add time
			
			for _, Status in ipairs(WCSCharacter:GetAllActiveStatusEffectsOfType(Hidden)) do
				Status:Destroy()
			end

			HumanoidRootPart.Anchored = false
			table.clear(self.MemorizedTransparency)
		end

	end
end

function Locker.Clearfromation(self: Component)
	if not self.CurrentPlayer then
		return
	end

	self.CurrentPlayer = nil
end

--//Return
return Locker