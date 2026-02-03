--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseHoldableSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseHoldableSkill)

local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)
local InvincibleStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Invincible)

local Utility = require(ReplicatedStorage.Shared.Utility)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local HitboxUtility = require(ReplicatedStorage.Shared.Utility.HitboxUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

local CameraController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.CameraController) or nil
local TerrorController = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.EnvironmentController.TerrorController) or nil

local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)

--//Constants

local DOOR_SLAM_DISTANCE = 4.3
local DOOR_CHECK_RAYCAST_PARAMS = RaycastParams.new()
DOOR_CHECK_RAYCAST_PARAMS.CollisionGroup = "Players"
DOOR_CHECK_RAYCAST_PARAMS.RespectCanCollide = true
DOOR_CHECK_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
DOOR_CHECK_RAYCAST_PARAMS.FilterDescendantsInstances = { workspace.Characters, workspace.Temp }


--//Variables

local Camera = workspace.CurrentCamera

local Evade = WCS.RegisterSkill("Evade", BaseHoldableSkill)

--//Types

type Skill = BaseHoldableSkill.BaseHoldableSkill

--//Methods

--TODO: umm.. Make it more "Globally"?
function Evade.SlamDoorOnWay(self: Skill)
	
	local HumanoidRootPart = self.Character.Instance.HumanoidRootPart :: BasePart

	local Result = workspace:Raycast(
		HumanoidRootPart.Position,
		HumanoidRootPart.AssemblyLinearVelocity.Unit * DOOR_SLAM_DISTANCE,
		DOOR_CHECK_RAYCAST_PARAMS
	)
	

	local DoorModel = Result and Result.Instance:FindFirstAncestorWhichIsA("Model") :: Model?

	if not DoorModel or not DoorModel:HasTag("Door") then
		return
	end

	local DoorComponent = ComponentsManager.GetComponentsFromInstance(DoorModel)[1]

	if not DoorComponent then
		return
	end

	DoorComponent:PromptSlamClient()
end

function Evade.HasObstacleOnWay(self: Skill)
	
	local HumanoidRootPart = self.Character.Humanoid.RootPart
	local Params = RaycastParams.new()
	
	Params.FilterDescendantsInstances = {workspace.Characters, workspace.Temp}
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.CollisionGroup = "Players"
	Params.RespectCanCollide = true
	
	local Result = workspace:Shapecast(HumanoidRootPart, HumanoidRootPart.CFrame.LookVector * 2, Params)
	
	if not Result then
		return false
	end
	
	local Similarity = Vector3.yAxis:Dot(Result.Normal)
	
	--stop if collided with verital obstacle
	return Similarity < 0.3 and Similarity > -0.3
end

function Evade.Ground(self: Skill)
	
	local HumanoidRootPart = self.Character.Humanoid.RootPart
	
	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.Characters, workspace.Temp}
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.CollisionGroup = "Players"
	Params.RespectCanCollide = true
	
	local RaycastResult = workspace:Raycast(HumanoidRootPart.Position, Vector3.new(0, -100, 0), Params)
	
	if not RaycastResult then
		
		self.FallTime = nil
		
		return
	end
	
	local Position = HumanoidRootPart.Position
	
	if RaycastResult.Distance < self.Character.Humanoid.HipHeight then
		
		self.FallTime = nil
		self.Character.Instance:PivotTo(
			CFrame.new(
				Position.X,
				RaycastResult.Position.Y + self.Character.Humanoid.HipHeight,
				Position.Z
			)
		)
	else
		-- Квадратичное падение с учётом гравитации
		local gravityFactor = workspace.Gravity / 196.2 -- 196.2 = стандартная гравитация Roblox
		local fallTime = (self.FallTime or 0) + 0.1
		local fallSpeed = 0.5 * gravityFactor * (fallTime^2) -- s = (gt²)/2 (упрощённая физика)

		self.FallTime = fallTime
		self.Character.Instance:PivotTo(
			HumanoidRootPart.CFrame * CFrame.new(0, -math.min(fallSpeed, 20), 0)
		)
	end
end

function Evade.ShouldStart(self: Skill)
	
	--if RunService:IsClient() then
		
	--	local Stamina = ComponentsManager.Get(self.Character.Instance, "Stamina")
		
	--	if Stamina:Get() < self.FromRoleData.StaminaLoss then
	--		return false
	--	end
	--end
	
	return BaseHoldableSkill.ShouldStart(self) and not self:HasObstacleOnWay()
end

function Evade.OnEndServer(self: Skill)
	self:ApplyCooldown(self.FromRoleData.Cooldown)
end

function Evade.OnStartServer(self: Skill)
	
	--animation stuff
	local AnimationTrack = AnimationUtility.QuickPlay(self.Character.Humanoid, self.FromRoleData.Animation, {
		Looped = false,
		Priority = Enum.AnimationPriority.Action4,
		PlaybackOptions = {
			Weight = 1000
		}
	})
	
	self.Janitor:Add(function()
		AnimationTrack:Stop(0.5)
	end)
	
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Players.Skills.Dash.Dash
	).Parent = self.Character.Humanoid.RootPart
	
	local ProxyService = Classes.GetSingleton("ProxyService")
	ProxyService:AddProxy("RunnerDashed"):Fire(self.Player)

end

--client should handle mo`ve`ment while dash active
function Evade.OnStartClient(self: Skill)
	
	local HumanoidRootPart = self.Character.Humanoid.RootPart
	local CharacterComponent = ComponentsManager.Get(self.Character.Instance, "ClientCharacterComponent")
	
	--direction
	local CameraY = select(2, Camera.CFrame:ToOrientation())
	local Direction = (CFrame.new(HumanoidRootPart.CFrame.Position) * CFrame.Angles(0, CameraY, 0)).LookVector
	Direction = Vector3.new(Direction.X, 0, Direction.Z)
	self.LastDirection = Direction
	--print(Direction)
	
	--character
	self.Character.Instance:PivotTo(CFrame.lookAlong(HumanoidRootPart.Position, Direction))
	CharacterComponent:SetRotationMode("Disabled")

	
	--physics initials
	local Velocity = HumanoidRootPart:FindFirstChild("EvadeVelocity")
	local Alignment = HumanoidRootPart:FindFirstChild("Alignment")

	if not Alignment then
		Alignment = Instance.new("Attachment")
		Alignment.Parent = HumanoidRootPart
	end
	
	if not Velocity then
		Velocity = Instance.new("LinearVelocity")
		Velocity.Parent = HumanoidRootPart
		Velocity.MaxForce = 99999999999
		Velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		Velocity.Attachment0 = Alignment
		Velocity.VectorVelocity = Vector3.zero
		Velocity.ForceLimitsEnabled = false
		Velocity.ForceLimitMode = Enum.ForceLimitMode.Magnitude
		Velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	end
	
	Velocity.Enabled = true
	
	self.Janitor:Add(function()
		if not Velocity then
			return
		end
		
		Velocity.Enabled = false
	end)
	
	
	
	----stamina
	--ComponentsManager.Get(self.Character.Instance, "Stamina")
	--	:Increment(-self.FromRoleData.StaminaLoss)
	
	--speed initials
	self.SpeedModifier:Start()
	self.Janitor:Add(self.SpeedModifier, "End")
	
	self.InvincibilityStatus:Start()
	self.Janitor:Add(self.InvincibilityStatus, "End")
	
	local EndTime = os.clock() + self.FromRoleData.Duration
	
	--physics update
	self.Janitor:Add(RunService.Stepped:Connect(function(deltaTime)
		
		local TimeAlpha = math.max(0, (EndTime - os.clock()) / self.FromRoleData.Duration)
		
		if self:HasObstacleOnWay() or TimeAlpha == 0 then
			
			self.Janitor:Cleanup()
			self:End()
			
			return
		end
		
		self:Ground()
		self:SlamDoorOnWay()
		
		--keeping character orientation right
		self.Character.Instance:PivotTo(CFrame.lookAlong(HumanoidRootPart.Position, Direction))
		
		--speed quadratic slowing
		Velocity.VectorVelocity = Direction * 60 * (0.5 + TimeAlpha^2)
	end))
	
	-- vault homing
	local VaultSkill : WCS.Skill = self.Character:GetSkillFromString("Vault")
	
	self.Janitor:Add(RunService.Stepped:Connect(function(deltaTime)
		--detecting vaults
		local Position = self.Character.Humanoid.RootPart.Position
		local NearestDistance = math.huge
		local Vault
		
		--local StaminaReq = VaultSkill.FromRoleData.StaminaLoss
		--local Stamina = ComponentsManager.Get(self.Character.Instance, "Stamina")

		
		--gettilg all vault components
		for _, Instance: Model in ipairs(CollectionService:GetTagged("Vault")) do

			local Component = ComponentsManager.GetFirstComponentInstanceOf(Instance, "BaseVault")

			--no component exists for this one
			if not Component
				or not Component:IsEnabled() then

				continue
			end

			--defining distance to vault
			local Distance = (Instance:GetPivot().Position - Position).Magnitude

			--storing new nearest vault here
			if Distance < NearestDistance
				and Distance < self.FromRoleData.AutoVaultDistance then

				NearestDistance = Distance
				Vault = Instance
			end
		end
		if not Vault then return end

		self.Janitor:Add(VaultSkill.Started:Once(function()
			self:End()
			self.Janitor:Cleanup()
		end))
		VaultSkill:Start({Instance = Vault})
	end))
end

function Evade.OnEndClient(self: Skill)
	local CharacterComponent = ComponentsManager.Get(self.Character.Instance, "ClientCharacterComponent")
	CharacterComponent:SetRotationMode("Smooth")
end

function Evade.OnConstructClient(self: Skill)
	
	--initializing speed modifier
	self.SpeedModifier = self.GenericJanitor:Add(
		ModifiedSpeedStatus.new(self.Character, "Multiply", 0, {Tag = "Evade"})
	)

	self.SpeedModifier.DestroyOnFadeOut = false
	
	self.InvincibilityStatus = self.GenericJanitor:Add(
		InvincibleStatus.new(self.Character)
	)
	
	self.InvincibilityStatus.DestroyOnEnd = false
	
	self:StartSource("Passive")

	self.GenericJanitor:Add(TerrorController.TerrorEnter:Connect(function()
		self:StartSource("TerrorRadius")
	end))

	self.GenericJanitor:Add(TerrorController.TerrorLeave:Connect(function()
		self:StopSource("TerrorRadius")
	end))
	
	self.GenericJanitor:Add(TerrorController.ChaseStateChanged:Connect(function(isChased: boolean)
		if isChased then
			self:StartSource("Chase")
		else
			self:StopSource("Chase")
		end
	end))
	
	
end

function Evade.OnConstruct(self: Skill)
	BaseHoldableSkill.OnConstruct(self)

	self:SetMaxHoldTime(self.FromRoleData.Duration)
	
	self.CheckClientState = true
	self.CheckOthersActive = false

	self.ExclusivesSkillNames = {}
	self.ExclusivesStatusNames = {
		-- Generic statuses
		"Stunned", "Handled", "Physics", "HarpoonPierced", "Hidden", "HiddenComing", "HiddenLeaving", "ObjectiveSolving", 
		-- Speed modifiers
		{"ModifiedSpeed", {"Slowed", "Freezed", Match = true}}
	}
end

--//Returner

return Evade