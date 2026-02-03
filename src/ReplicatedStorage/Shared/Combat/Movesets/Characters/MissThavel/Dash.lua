--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseHoldableSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseHoldableSkill)

local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

local Utility = require(ReplicatedStorage.Shared.Utility)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local HitboxUtility = require(ReplicatedStorage.Shared.Utility.HitboxUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

--//Constants

local DOOR_SLAM_DISTANCE = 4.3
local DOOR_CHECK_RAYCAST_PARAMS = RaycastParams.new()
DOOR_CHECK_RAYCAST_PARAMS.CollisionGroup = "Players"
DOOR_CHECK_RAYCAST_PARAMS.RespectCanCollide = true
DOOR_CHECK_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
DOOR_CHECK_RAYCAST_PARAMS.FilterDescendantsInstances = { workspace.Characters, workspace.Temp }


--//Variables

local Camera = workspace.CurrentCamera

local Dash = WCS.RegisterSkill("Dash", BaseHoldableSkill)

--//Types

type Skill = BaseHoldableSkill.BaseHoldableSkill

--//Methods

--TODO: umm.. Make it more "Globally"?
function Dash.SlamDoorOnWay(self: Skill)
	
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

function Dash.HasObstacleOnWay(self: Skill)
	
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

function Dash.Ground(self: Skill)
	
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
	
	if RaycastResult.Distance < self.Character.Humanoid.HipHeight + 1 then
		
		self.FallTime = nil
		self.Character.Instance:PivotTo(
			CFrame.new(
				Position.X,
				RaycastResult.Position.Y + self.Character.Humanoid.HipHeight + 1.6,
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

function Dash.ShouldStart(self: Skill)
	
	if RunService:IsClient() then
		
		local Stamina = ComponentsManager.Get(self.Character.Instance, "Stamina")
		
		if Stamina:Get() < self.FromRoleData.StaminaLoss then
			return false
		end
	end
	
	return BaseHoldableSkill.ShouldStart(self) and not self:HasObstacleOnWay()
end

function Dash.OnEndServer(self: Skill)
	
	self:ApplyCooldown(self.FromRoleData.Cooldown)
	
	WCSUtility.ApplyGlobalCooldown(self.Character, self.FromRoleData.Duration + 0.5, {
		Mode = "Include",
		SkillNames = {"ThavelAttack"},
	})
end

function Dash.OnStartServer(self: Skill)
	
	local HittedCharacters = { self.Character.Instance } :: {PlayerTypes.Character?}
	local ProgressivePunishment = ComponentsManager.Get(self.Character.Instance, "ProgressivePunishmentPassive")
	
	--animation stuff
	local AnimationTrack = AnimationUtility.QuickPlay(self.Character.Humanoid, self.FromRoleData.Animation, {
		Looped = false,
		Priority = Enum.AnimationPriority.Action4,
	})
	
	self.Janitor:Add(function()
		AnimationTrack:Stop(0.5)
	end)
	
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Players.Skills.Dash.Dash
	).Parent = self.Character.Humanoid.RootPart
	
	self.Janitor:Add(RunService.Stepped:Connect(function(deltaTime)
		
		local CharacterComponents = select(2, HitboxUtility.RequestCharactersInHitbox(self.Player, self.FromRoleData.Hitbox, 15, nil,
			{
				Mode = Enum.RaycastFilterType.Exclude,
				Instances = HittedCharacters,
				ComponentMode = "Exclude",
				StatusesNames = {"Invincible", "Hidden", "Downed", "Handled"},
			}
		))
		
		for _, CharacterComponent: { WCSCharacter: WCS.Character } in ipairs(CharacterComponents) do
			
			local Player = Players:GetPlayerFromCharacter(CharacterComponent.Instance)
			local PlayerComponent = ComponentsManager.Get(Player, "PlayerComponent")
			
			if not PlayerComponent
				or not PlayerComponent:IsStudent() then
				
				continue
			end
			
			table.insert(HittedCharacters, CharacterComponent.Instance)
			
			local Damage = self.FromRoleData.Damage
			
			--lower damage for targetted player
			if ProgressivePunishment.LastHitHumanoid == CharacterComponent.Humanoid then
				
				Damage = self.FromRoleData.MinDamage
				
			elseif ProgressivePunishment:IsMaxCombo() then
				
				Damage = self.FromRoleData.MaxDamage
			end
			
			--dealing damage
			local DamageDealed = CharacterComponent.WCSCharacter:TakeDamage(
				self:CreateDamageContainer(Damage)
			)
			
			if DamageDealed == 0 then
				continue
			end
			
			-- increase? combo cuz hit Student
			ProgressivePunishment:OnHit(Player)
		end
	end))
end

--client should handle movement while dash active
function Dash.OnStartClient(self: Skill)
	
	local HumanoidRootPart = self.Character.Humanoid.RootPart
	local CharacterComponent = ComponentsManager.Get(self.Character.Instance, "ClientCharacterComponent")
	
	--direction
	local CameraY = select(2, Camera.CFrame:ToOrientation())
	local Direction = (CFrame.new(HumanoidRootPart.CFrame.Position) * CFrame.Angles(0, CameraY, 0)).LookVector
	Direction = Vector3.new(Direction.X, 0, Direction.Z)
	self.LastDirection = Direction
	
	--character
	CharacterComponent:SetRotationMode("Disabled")
	
	--physics initials
	local Velocity = HumanoidRootPart:FindFirstChild("DashVelocity")
	local Alignment = HumanoidRootPart:FindFirstChild("Alignment")

	if not Alignment then
		Alignment = Instance.new("Attachment")
		Alignment.Parent = HumanoidRootPart
	end
	
	if not Velocity then
		Velocity = Instance.new("LinearVelocity")
		Velocity.Parent = HumanoidRootPart
		Velocity.MaxForce = 99999999
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
	
	--stamina
	ComponentsManager.Get(self.Character.Instance, "Stamina")
		:Increment(-self.FromRoleData.StaminaLoss)
	
	--speed initials
	self.SpeedModifier:Start()
	self.Janitor:Add(self.SpeedModifier, "End")
	
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
end

function Dash.OnEndClient(self: Skill)
	local CharacterComponent = ComponentsManager.Get(self.Character.Instance, "ClientCharacterComponent")
	CharacterComponent:SetRotationMode("Smooth")
end

function Dash.OnConstructClient(self: Skill)
	
	--initializing speed modifier
	self.SpeedModifier = self.GenericJanitor:Add(
		ModifiedSpeedStatus.new(self.Character, "Multiply", 0, {Tag = "Dash"})
	)

	self.SpeedModifier.DestroyOnFadeOut = false
end

function Dash.OnConstruct(self: Skill)
	BaseHoldableSkill.OnConstruct(self)

	self:SetMaxHoldTime(self.FromRoleData.Duration)
	
	self.CheckClientState = true
	self.CheckOthersActive = false

	self.ExclusivesSkillNames = {}
	self.ExclusivesStatusNames = {
		-- Generic statuses
		"Stunned", "Handled", "Physics", "HarpoonPierced", "HiddenComing",
		-- Speed modifiers
		{"ModifiedSpeed", {"AttackSlowed", "Freezed"}}
	}
end

--//Returner

return Dash