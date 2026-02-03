--//Services

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseSkill)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local InvincibleStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Invincible)
local TableKit = require(ReplicatedStorage.Packages.TableKit)

local BaseVault = require(ReplicatedStorage.Shared.Components.Abstract.BaseVault)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local Animationutility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

--//Constants

local PI = math.pi

--//Variables

local Vault = WCS.RegisterSkill("Vault", BaseSkill)

local DEFAULT_VAULT_PARAMS = {
	Instance = nil,
}

--//Types

export type Skill = BaseSkill.BaseSkill

export type VaultParams = {
	Instance: Instance?, -- force an instance to use
	UseStamina: boolean?, -- whether to spend and require stamina
}

--//Methods

--function Vault.GetVaultOnWay(self: Skill)

--	local RootPart = self.Character.Humanoid.RootPart

--	if not RootPart then
--		return
--	end

--	local Direction = RootPart.AssemblyLinearVelocity.Unit * Vector3.new(1, 0, 1)

--	local Params = RaycastParams.new()
--	Params.CollisionGroup = "Players"
--	Params.RespectCanCollide = false -- CanQuery also
--	Params.FilterType = Enum.RaycastFilterType.Exclude
--	Params.FilterDescendantsInstances = { workspace.Characters, workspace.Temp }
	
--	local Result = workspace:Raycast(

--		RootPart.Position,
--		Direction * self.FromRoleData.DetectDistance,
--		Params
--	)
	
--	local Instance = Result
--		and Result.Instance:HasTag("Vault")
--		and Result.Instance.Parent
	
--	if not Instance then
--		return
--	end
	
--	--extractng component
--	return ComponentsManager.GetFirstComponentInstanceOf(Instance, BaseVault), Result.Normal
--end

function Vault.OnStartClient(self: Skill, params: VaultParams?)
	params = TableKit.MergeDictionary(DEFAULT_VAULT_PARAMS, params or {})

	local CameraController = Classes.GetSingleton("CameraController")
	local Stamina = ComponentsManager.Get(self.Character.Instance, "Stamina")
	
	Stamina:Increment(-self.FromRoleData.StaminaLoss)

	--camera stuff
	
	CameraController:ChangeFov(20, "Increment")
	CameraController:ChangeFov(-20, "Increment", {
		Time = 1.5,
		EasingStyle = Enum.EasingStyle.Quad,
		EasingDirection = Enum.EasingDirection.Out,
	})
end

local function IsObstaclesOnSight(originCharacter: Model, target: BasePart, filter: { Instance }?, iteration: number?) : boolean

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = TableKit.MergeArrays({ workspace.Characters, workspace.Temp }, filter or {})
	
	local Camera = workspace.CurrentCamera
	local CurrentCharacter = originCharacter :: PlayerTypes.Character
	local Position = target.Position :: Vector3
	local CurrentPos = CurrentCharacter.HumanoidRootPart.Position :: Vector3
	local CameraToPos = Position - Camera.CFrame.Position

	local Result = workspace:Raycast(Camera.CFrame.Position - CurrentCharacter.Head.CFrame.LookVector*1, CameraToPos.Unit * (CameraToPos.Magnitude + 1), Params)

	if iteration and iteration == 3 or not Result then
		return false
	end

	local Instance = Result.Instance :: BasePart
	
	if Instance == target then
		return false
	end

	if Instance.Transparency > 0 then
		local Filter = filter or table.clone(Params.FilterDescendantsInstances)
		table.insert(Filter, Instance)

		return IsObstaclesOnSight(originCharacter, target, Filter, (iteration and iteration + 1) or 1)
	end
	return true
end


function Vault.GetIntendedInstance(self: Skill, nocheck: boolean?)
	-- with nocheck=true, you might get outdated/missing vault information!
	if not nocheck then
		self:_VaultDetectionTick()
	end
	return self._IntendedInstance
end

function Vault.SelectInstance(self: Skill, instance: Model)
	self._IntendedInstance = instance
end

function Vault.OnStartServer(self: Skill, params: VaultParams?)
	params = TableKit.MergeDictionary(DEFAULT_VAULT_PARAMS, params or {})

	self:ApplyCooldown(self.FromRoleData.Cooldown)
	
	local Instance = params.Instance or self:GetIntendedInstance()
	local Component = ComponentsManager.GetFirstComponentInstanceOf(Instance, BaseVault) :: BaseVault.Component?
	local Humanoid = self.Character.Humanoid
	local RootPart = Humanoid and Humanoid.RootPart
	local VaultRoot = Instance.Root :: BasePart
	local VaultCF = VaultRoot.CFrame
	
	--disabling vault after usage
	Component:SetEnabled(false)
	
	--sound playback
	
	local HopSound = SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Players.Skills.Vault.Hop, true
	)
	HopSound.Parent = RootPart

	local AdditionalSound = SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Players.Skills.Vault.Additional, true
	)
	AdditionalSound.Parent = RootPart
	
	SoundUtility.AdjustSoundForCharacter(HopSound, self.Character.Instance)
	SoundUtility.AdjustSoundForCharacter(AdditionalSound, self.Character.Instance)
	
	HopSound:Play()
	AdditionalSound:Play()
	
	--invincibility for a bit
	InvincibleStatus.new(self.Character):Start(0.6)
	
	--anim playback
	local AnimationTrack = Animationutility.QuickPlay(
		Humanoid,
		self.FromRoleData.Animation,
		{
			Looped = false,
			Priority = Enum.AnimationPriority.Action4,
		}
	)
	--offset
	local LocalPos = VaultCF:PointToObjectSpace(RootPart.Position)

	--define move direction
	local MoveDirection = if LocalPos.Z < 0 then 1 else -1

	--goal pose
	local NewLocalPos = Vector3.new(0, 0, MoveDirection * 4)

	--to world space
	local GoalWorldPos = VaultCF:PointToWorldSpace(NewLocalPos)
	--GoalWorldPos = Vector3.new(GoalWorldPos.X, RootPart.Position.Y, GoalWorldPos.Z)

	--facing along movement
	local Direction = (GoalWorldPos - RootPart.Position).Unit

	self.Character.Instance:PivotTo(CFrame.lookAlong(GoalWorldPos, Direction))

	--anchor after position applying
	RootPart.Anchored = true

	--restoring things
	self.GenericJanitor:Add(
		task.delay(AnimationTrack.Length or 1, function()
			if RootPart then
				RootPart.Anchored = false
			end
		end)
	)
	
	local ProxyService = Classes.GetSingleton("ProxyService")
	ProxyService:AddProxy("VaultStarted"):Fire(self.Player, Instance)
end

function Vault.ShouldStart(self: Skill)
	
	--client checks
	if RunService:IsClient() then
		
		--humanoid state filtering
		if table.find({

			Enum.HumanoidStateType.PlatformStanding,
			Enum.HumanoidStateType.FallingDown,
			Enum.HumanoidStateType.Freefall,
			Enum.HumanoidStateType.Ragdoll,
			Enum.HumanoidStateType.Jumping,

			}, self.Character.Humanoid:GetState()) then
			return false
		end
		
		local Stamina = ComponentsManager.Get(self.Character.Instance, "Stamina")
		if not Stamina or Stamina:Get() < self.FromRoleData.StaminaLoss then
			return false
		end
	end
	
	local VaultInstance = self:GetIntendedInstance()
	return BaseSkill.ShouldStart(self) and ComponentsManager.GetFirstComponentInstanceOf(VaultInstance, BaseVault)
end

function Vault._VaultDetectionTick(self: Skill)

	--detecting vaults
	if not self.Character or not self.Character.Humanoid  or not self.Character.Humanoid.RootPart then
		return
	end
	
	local Position = self.Character.Humanoid.RootPart.Position
	local NearestDistance = math.huge
	local Vault

	--also exclusives check
	if not WCSUtility.HasActiveStatusEffectsWithNames(self.Character, self.ExclusivesStatusNames) then

		--gettilg all vault components
		for _, Instance: Model in ipairs(CollectionService:GetTagged("Vault")) do

			local Component = ComponentsManager.GetFirstComponentInstanceOf(Instance, "BaseVault")
			
			--no component exists for this one
			if not Component
				or not Component:IsEnabled() then

				continue
			end
			
			if not Instance or not Instance:GetPivot() or not Position then
				continue
			end
			
			--defining distance to vault
			local Distance = (Instance:GetPivot().Position - Position).Magnitude

			--debug reset
			--Instance.Root.Transparency = 1
			
			local ReqDistance = self.FromRoleData.MaxUsageDistance
			if RunService:IsServer() then
				ReqDistance *= 1.2 -- lag accounting
			end

			--storing new nearest vault here
			if Distance < NearestDistance
				and Distance < ReqDistance then
				
				if RunService:IsClient() and (not Instance.Root or IsObstaclesOnSight(self.Character.Instance, Instance.Root)) then
					continue
				end
				
				NearestDistance = Distance
				Vault = Instance
			end
		end
	end

	--if Vault then
	--	Vault.Root.Transparency = 0.5
	--end
	
	--print(Vault, NearestDistance, self:GetIntendedInstance(true))
	
	--selecting new instance
	if self:GetIntendedInstance(true) ~= Vault then
		self:SelectInstance(Vault)
		self._IntendedInstance = Vault
		if self.VaultSelected then
			self.VaultSelected:Fire(Vault)
		end
	end
end

function Vault.OnConstructClient(self: Skill)
	
	--for UI stuff
	self.VaultSelected = self.GenericJanitor:Add(Signal.new())
	
	local LastUpdate = os.clock()
	
	--locating vaults
	self.GenericJanitor:Add(RunService.Stepped:Connect(function()
		if os.clock() - LastUpdate < 0.1 then
			return
		end

		LastUpdate = os.clock()
		
		self:_VaultDetectionTick()
	end))
end

function Vault.OnConstruct(self: Skill)
	BaseSkill.OnConstruct(self)
	
	self.GenericJanitor:Add(function()
		self._IntendedInstance = nil
	end)
	
	self.CheckClientState = true
	self.CheckOthersActive = false
	self._SavedVaultInstance = nil

	self.ExclusivesSkillNames = {"Swing"}
	self.ExclusivesStatusNames = {
		-- Generic statuses
		"Aiming", "Downed", "Hidden", "Handled", "Stunned", "Physics", "HarpoonPierced", "Healing", "ObjectiveSolving", 
		-- Speed modifiers
		{"ModifiedSpeed", {"AttackSlowed", "FallDamageSlowed", "Freezed"}},
	}
end

--//Messages

WCS.DefineMessage(Vault.SelectInstance, {
	
	Type = "Event",
	Unreliable = false,
	Destination = "Server",
	OnlyWhenActive = false,
})

--//Returner

return Vault