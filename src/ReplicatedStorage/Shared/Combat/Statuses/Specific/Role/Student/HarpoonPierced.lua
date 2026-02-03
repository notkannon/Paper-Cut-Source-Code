--[[
	This status applies to a player which was pierced by Miss Circle's harpoon.
	It's responsible for use couple skill
]]

--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

local ComponentTypes = RunService:IsServer() and require(ServerScriptService.Server.Types.ComponentTypes) or nil
local CameraController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.CameraController) or nil

--//Variables

local Animations = ReplicatedStorage.Assets.Animations.Student.Statuses.HarpoonPierced

local HarpoonPierced = WCS.RegisterStatusEffect("HarpoonPierced", BaseStatusEffect)

--//Types

export type Status = BaseStatusEffect.BaseStatusEffect & {
	Opponent: ComponentTypes.PlayerComponent,
	OpponentPlayer: Player,
	SpeedModifier: ModifiedSpeedStatus.Status,
}

--//Methods

function HarpoonPierced.OnConstruct(self: Status, piercer: Player)
	BaseStatusEffect.OnConstruct(self)
	
	self.DestroyOnEnd = false
	self.OpponentPlayer = piercer
end

function HarpoonPierced.OnConstructServer(self: Status, piercer: Player)
	local PlayerComponent = ComponentsManager.Get(piercer, "PlayerComponent")
	
	self.Opponent = PlayerComponent
	
	self.SpeedModifier = self.GenericJanitor:Add(ModifiedSpeedStatus.new(self.Character, "Set", 0, {Tag = "HarpoonPierced", Priority = 20, FadeOutTime = 0.4}), "End", "SpeedModifier")
	self.SpeedModifier.DestroyOnEnd = false
end

function HarpoonPierced.OnStartServer(self: Status)
	
	local CharacterComponent = ComponentsManager.Get(self.Character.Instance, "CharacterComponent")
	
	--CharacterComponent:ApplyRagdoll()
	CharacterComponent.Appearance.Attributes.FootstepVolumeScale = 0
	
	self.SpeedModifier:Start()
end

function HarpoonPierced.OnStartClient(self: Status)
	
	local CharacterComponent = ComponentsManager.Get(self.Character.Instance, "ClientCharacterComponent")
	local HumanoidRootPart = self.Character.Humanoid.RootPart :: BasePart
	local OpponentRootPart = self.OpponentPlayer.Character.HumanoidRootPart :: BasePart
	local Sub = (HumanoidRootPart.Position - OpponentRootPart.Position)
	
	-- camera initials
	--CameraController:SetActiveCamera("HeadLocked")
	--CameraController.Cameras.HeadLocked.IsFlexible = true
	
	local Alignment = HumanoidRootPart:FindFirstChild("Alignment")
	
	if not Alignment then
		Alignment = Instance.new("Attachment")
		Alignment.Parent = HumanoidRootPart
	end
	
	--resetting player velocity
	HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	
	local Velocity = Instance.new("LinearVelocity") :: LinearVelocity
	Velocity.Parent = HumanoidRootPart
	Velocity.Enabled = true
	Velocity.MaxForce = 80500
	Velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	Velocity.Attachment0 = Alignment
	Velocity.VectorVelocity = Vector3.zero
	Velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	
	self.GenericJanitor:Add(AnimationUtility.QuickPlay(self.Character.Humanoid, Animations.Loop, {
		Looped = true,
		Priority = Enum.AnimationPriority.Action3,
	}), "Stop")
	
	local AnimationTrack = AnimationUtility.QuickPlay(self.Character.Humanoid, Animations.Pierce, {
		Looped = false,
		Priority = Enum.AnimationPriority.Action4,
		PlaybackOptions = {
			Weight = 1000
		}
	})
	
	CharacterComponent:SetRotationMode("Disabled")
	
	self.Character.Instance:PivotTo(CFrame.lookAlong(HumanoidRootPart.Position, -Sub.Unit))
	self.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
	
	--janitor initials
	self.GenericJanitor:Add(function()
		if self._CameraAffected then
			CameraController:ChangeFov(-17, "Increment", {
				Time = 1,
				EasingStyle = Enum.EasingStyle.Cubic,
				EasingDirection = Enum.EasingDirection.Out
			})
		end

		--CameraController:SetActiveCamera("Default")
	end)
	
	self.GenericJanitor:Add(Velocity)
	self.GenericJanitor:Add(task.delay(AnimationTrack.Length, function()
		
		local Start = os.clock()
		
		self._CameraAffected = true
		
		CameraController:ChangeFov(17, "Increment", {
			Time = 1,
			EasingStyle = Enum.EasingStyle.Cubic,
			EasingDirection = Enum.EasingDirection.In
		})
		
		self.GenericJanitor:Add(RunService.Stepped:Connect(function()
			
			local Sub = (HumanoidRootPart.Position - OpponentRootPart.Position)
			local Acceleration = math.clamp( ((os.clock() - Start) / 1)^2, 0, 1)
			
			if Sub.Magnitude < 11 then
				
				self.Character.Humanoid.RootPart.AssemblyLinearVelocity = Vector3.zero
				self.GenericJanitor:Remove("VelocitySteps")
				
				return
			end
			
			Velocity.VectorVelocity = -Sub.Unit * 60 * Acceleration + (self.Character.Humanoid.MoveDirection * 8)
			HumanoidRootPart.CFrame = CFrame.lookAlong(HumanoidRootPart.Position, Velocity.VectorVelocity.Unit)
			
		end))
		
	end), nil, "VelocitySteps")
end

function HarpoonPierced.OnEndServer(self: Status)
	
	local CharacterComponent = ComponentsManager.Get(self.Character.Instance, "CharacterComponent")
	
	--CharacterComponent:RemoveRagdoll()
	CharacterComponent.Appearance.Attributes.FootstepVolumeScale = 1
end

function HarpoonPierced.OnEndClient(self: Status)
	
	local CharacterComponent = ComponentsManager.Get(self.Character.Instance, "ClientCharacterComponent")
	
	if CharacterComponent:IsDestroyed() then
		return
	end
	
	CharacterComponent:SetRotationMode("Smooth")
	
	self.Character.Humanoid.RootPart.AssemblyLinearVelocity = Vector3.zero
	self.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
end

--//Returner

return HarpoonPierced