--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil
local PlayerService = RunService:IsServer() and require(ServerScriptService.Server.Services.PlayerService) or nil
local MatchStateClient = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.MatchStateClient) or nil

--//Constants

local ClassPropertyTable = {BasePart = "LocalTransparencyModifier", Decal = "Transparency", ImageLabel = "ImageTransparency"}

local PI = math.pi
local BODY_TILT_UPDATE_RATE = 1/60
local BODY_TILT_MAX_DISTANCE = 70
local BODY_TILT_REPLICATE_RATE = 1/60

local BODY_TILT_RAYCAST_PARAMS = RaycastParams.new()
BODY_TILT_RAYCAST_PARAMS.FilterDescendantsInstances = { workspace.Characters, workspace.Temp }
BODY_TILT_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
BODY_TILT_RAYCAST_PARAMS.IgnoreWater = true

local DEFAULT_TRANSPARENT_DESCENDANTS = {
	
}

--//Variables

local Camera = workspace.CurrentCamera
local BaseAppearance = BaseComponent.CreateComponent("BaseAppearance", {
	
	isAbstract = true,
	ancestorWhitelist = {
		workspace
	},
	
	defaults = {
		FootstepVolumeScale = 1,
		DestinatedTransparency = 0,
		ActionVolumeScale = 1,
		ActionRollOffScale = 1
	},
	
	predicate = function(instance)
		return Players:GetPlayerFromCharacter(instance) ~= nil
	end,
	
}, SharedComponent) :: Impl

--//Types

export type TweenConfig = {
	Time: number,
	EasingStyle: Enum.EasingStyle,
	EasingDirection: Enum.EasingDirection,
}

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: SharedComponent.MyImpl)),
	
	CreateEvent: SharedComponent.CreateEvent<Component>,
	
	IsLocalPlayer: (self: Component) -> boolean,
	
	ResetBodyTilt: (self: Component) -> (),
	UpdateBodyTilt: (self: Component) -> (),
	CreateFootstep: (self: Component, value: number?) -> (),
	ApplyTransparency: (self: Component, value: number, tweenConfig: TweenConfig?) -> (),
	IsDescendantTransparent: (self: Component, descendant: Instance) -> boolean,
	
	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
	OnConstructServer: (self: Component) -> (),

	_InitBodyTilt: (self: Component) -> (),
	_InitTransparency: (self: Component) -> (),
	_InitHumanoidEvents: (self: Component) -> (),
}

export type Fields = {
	Player: Player,
	Instance: PlayerTypes.Character,
	
	TransparencyJanitor: Janitor.Janitor,

	Head: PlayerTypes.Head,
	Torso: PlayerTypes.Torso?,
	Humanoid: PlayerTypes.IHumanoid,
	HumanoidRootPart: PlayerTypes.HumanoidRootPart,
	
	_InternalTransparencyEvent: SharedComponent.ServerToClient<number, TweenConfig>,
	
	_InitialCFrames: { [string]: CFrame },
	_DestinatedDirection: Vector3,
	_InitialTransparency: { [BasePart]: number },
	_LastTransparencyTweenConfig: TweenConfig?,
	
} & SharedComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseAppearance", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseAppearance", PlayerTypes.Character>

--//Methods

function BaseAppearance.IsDescendantTransparent(self: Component)
	return false
end

function BaseAppearance.IsLocalPlayer(self: Component)
	return self.Player == Players.LocalPlayer
end

function BaseAppearance.CreateFootstep(self: Component)
	assert(RunService:IsClient())
	
	local MaterialName = self.Humanoid.FloorMaterial.Name
	local MaterialSounds = SoundUtility.Sounds.Players.Footsteps:FindFirstChild(MaterialName)

	if not MaterialSounds then
		return
	end

	local Sound = SoundUtility.CreateTemporarySound(
		SoundUtility.GetRandomSoundFromDirectory(MaterialSounds)
	)

	Sound.Parent = self.HumanoidRootPart
	Sound.Volume *= self.Attributes.FootstepVolumeScale * 0.3
	
	return Sound
end

function BaseAppearance.ApplyTransparency(self: Component, value: number, tweenConfig: TweenConfig?, players: { Player }?)
	--print('applying transparency', value, tweenConfig, players)
	
	self.Attributes.DestinatedTransparency = value
	
	if RunService:IsServer() then
		
		self._InternalTransparencyEvent.FireList(players or Players:GetPlayers(), value, tweenConfig)
		
	elseif RunService:IsClient() then
		
		self.TransparencyJanitor:Cleanup()
		
		for Instance: BasePart | Decal, InitialValue in pairs(self._InitialTransparency) do
			
			--if self:IsDescendantTransparent(Instance) then
			--	TweenUtility.ClearAllTweens(Instance)
			--	Instance.LocalTransparencyModifier = 1
				
			--	continue
			--end
			
			
			TweenUtility.ClearAllTweens(Instance)
			
			local Property
			for k, v in ClassPropertyTable do
				if Instance:IsA(k) then
					Property = v
					break
				end
			end
			
			if Instance[Property] == value then
				continue
			end
			
			if not tweenConfig then
				Instance[Property] = value
				continue
			end
			
			self.TransparencyJanitor:Add(
				TweenUtility.PlayTween(
					Instance,
					TweenInfo.new(
						tweenConfig.Time or 1,
						tweenConfig.EasingStyle or Enum.EasingStyle.Linear,
						tweenConfig.EasingDirection or Enum.EasingDirection.InOut
					),
					{
						[Property] = value,
					}
				),
				"Cancel"
			)
		end
	end
end

function BaseAppearance.UpdateBodyTilt(self: Component)
	assert(RunService:IsClient())
	
	local IsR6 = self.Humanoid.RigType == Enum.HumanoidRigType.R6
	local IsR15 = self.Humanoid.RigType == Enum.HumanoidRigType.R15

	local Neck: Motor6D?
	local Head = self.Head :: BasePart?
	local Torso = self.Instance:FindFirstChild(IsR6 and "Torso" or "UpperTorso") :: BasePart?
	
	--getting neck joint
	if IsR6 then
		Neck = Torso and Torso:FindFirstChild("Neck")
	else
		Neck = Head and Head:FindFirstChild("Neck")
	end
	
	--check if player has required character elements
	if not self.Humanoid
		or self.Humanoid.Health <= 0
		or not Torso
		or not Head
		or not Neck then
		
		return
	end

	local HeadPosition = Head.CFrame.Position
	local TorsoLookVector = Torso.CFrame.LookVector

	local Point: Vector3
	local RaycastResult = workspace:Raycast(Head.Position, self._DestinatedDirection * 1000, BODY_TILT_RAYCAST_PARAMS)

	if RaycastResult then
		Point = RaycastResult.Position
	else
		Point = HeadPosition + self._DestinatedDirection * 1000
	end

	local Distance = (Head.CFrame.p - Point).magnitude
	local Difference = Head.CFrame.Y - Point.Y
	local NeckOriginC0 = self._InitialCFrames.NeckOriginC0
	local WaistOriginC0 = self._InitialCFrames.WaistOriginC0

	if IsR6 then

		local LHip = Torso:FindFirstChild("Left Hip") :: Motor6D?
		local RHip = Torso:FindFirstChild("Right Hip") :: Motor6D?
		local Waist = self.HumanoidRootPart:FindFirstChild("RootJoint") :: Motor6D?

		if not Waist or not RHip or not LHip then
			return
		end

		local RHipOriginC0 = self._InitialCFrames.RHipOriginC0
		local LHipOriginC0 = self._InitialCFrames.LHipOriginC0

		local goalNeckCFrame = CFrame.Angles(-(math.atan(Difference / Distance) * 0.5), (((HeadPosition - Point).Unit):Cross(TorsoLookVector)).Y * 1, 0)

		Neck.C0 = Neck.C0:Lerp(goalNeckCFrame * NeckOriginC0, 0.5 / 2).Rotation + NeckOriginC0.Position

		local xAxisWaistRotation = -(math.atan(Difference / Distance) * 0.5)
		local yAxisWaistRotation = (((HeadPosition - Point).Unit):Cross(TorsoLookVector)).Y * 0.5
		local rotationWaistCFrame = CFrame.Angles(xAxisWaistRotation, yAxisWaistRotation, 0)
		local goalWaistCFrame = rotationWaistCFrame * WaistOriginC0

		Waist.C0 = Waist.C0:Lerp(goalWaistCFrame, 0.5 / 2).Rotation + WaistOriginC0.Position

		local currentLegCounterCFrame = Waist.C0 * WaistOriginC0:Inverse()
		local legsCounterCFrame = currentLegCounterCFrame:Inverse()

		RHip.C0 =  legsCounterCFrame * RHipOriginC0
		LHip.C0 = legsCounterCFrame * LHipOriginC0

	elseif IsR15 then

		local Waist = Torso:FindFirstChild("Waist") :: Motor6D?
		
		if not Waist then
			return
		end

		local HeadPosition = Head.CFrame.Position
		local TorsoLookVector = Torso.CFrame.LookVector

		local Distance = (Head.CFrame.p - Point).magnitude
		local Difference = Head.CFrame.Y - Point.Y

		Neck.C0 = Neck.C0:Lerp(NeckOriginC0 * CFrame.Angles(-(math.atan(Difference / Distance) * 0.5), (((HeadPosition - Point).Unit):Cross(TorsoLookVector)).Y * 1, 0), 0.5 / 2)
		Waist.C0 = Waist.C0:Lerp(WaistOriginC0 * CFrame.Angles(-(math.atan(Difference / Distance) * 0.5), (((HeadPosition - Point).Unit):Cross(TorsoLookVector)).Y * 0.5, 0), 0.5 / 2)
	end
end

function BaseAppearance._InitBodyTilt(self: Component)
	assert(RunService:IsClient())
	
	--used to enable/disable spectator head rotation unlock if local player
	local PlayerController = Classes.GetSingleton("PlayerController")
	local IsSpectator = PlayerController:IsSpectator()
	
	if self:IsLocalPlayer() then
		self.Janitor:Add(PlayerController.RoleConfigChanged:Connect(function()
			IsSpectator = PlayerController:IsSpectator()
		end))
	end
	
	if self.Humanoid.RigType == Enum.HumanoidRigType.R6 then
		
		local Neck = self.Torso:FindFirstChild("Neck") :: Motor6D?
		local LHip = self.Torso:FindFirstChild("Left Hip") :: Motor6D?
		local RHip = self.Torso:FindFirstChild("Right Hip") :: Motor6D?
		local Waist = self.HumanoidRootPart:FindFirstChild("RootJoint") :: Motor6D?

		Neck.MaxVelocity = 1/3

		self._InitialCFrames.RHipOriginC0 = RHip.C0
		self._InitialCFrames.LHipOriginC0 = LHip.C0
		self._InitialCFrames.NeckOriginC0 = Neck.C0
		self._InitialCFrames.WaistOriginC0 = Waist.C0

	elseif self.Humanoid.RigType == Enum.HumanoidRigType.R15 then
		
		local Neck = self.Head:FindFirstChild("Neck") :: Motor6D?
		local Waist = self.Torso:FindFirstChild("Waist") :: Motor6D?

		Neck.MaxVelocity = 1/3

		self._InitialCFrames.NeckOriginC0 = Neck.C0
		self._InitialCFrames.WaistOriginC0 = Waist.C0
	end

	local LastUpdate = os.clock()
	local LastReplicate = os.clock()

	--TODO: uhh death screams is sooo ugly. Improve.
	if not self:IsLocalPlayer() then
		
		self.Janitor:Add(self.Humanoid.Died:Once(function()
			
			local Position = self.HumanoidRootPart.Position
			
			if (Position - Camera.CFrame.Position).Magnitude < 30 then
				return
			end

			local Sound = SoundUtility.CreateTemporarySoundAtPosition(
				Position,
				SoundUtility.GetRandomSoundFromDirectory(
					SoundUtility.Sounds.Players.Gore.Death
				)
			)

			SoundUtility.Sounds.Players.Gore.Death.Reverb:Clone().Parent = Sound
		end))
	end
	
	--runtime update connection
	self.Janitor:Add(RunService.Stepped:Connect(function(timeDelta: number)
		
		if os.clock() - LastUpdate < BODY_TILT_UPDATE_RATE then
			return
		end
		
		if self:IsLocalPlayer() then
			
			self._DestinatedDirection = Camera.CFrame.LookVector
			
			--update locally if spectator
			if IsSpectator then
				LastUpdate = os.clock()
				self:UpdateBodyTilt()
			end
			
			--replication rate limiting
			if os.clock() - LastReplicate < BODY_TILT_REPLICATE_RATE then
				return
			end
			
			LastReplicate = os.clock()
			ClientRemotes.ClientLookVectorChanged.Fire(self._DestinatedDirection)
			
		else
		
			--REPLACE WITH DISTANCE CHECK
			--local PositionOnScreen: Vector3, IsVisible: boolean = Camera:WorldToScreenPoint(self.HumanoidRootPart.Position)

			--if not IsVisible or PositionOnScreen.Z > BODY_TILT_MAX_DISTANCE then
			--	LastUpdate = os.clock()
			--	return
			--end

			LastUpdate = os.clock()
			
			self:UpdateBodyTilt()
		end
	end), nil, "ClientBodyTiltUpdate")
end

function BaseAppearance._InitTransparency(self: Component)
	assert(RunService:IsClient())
	
	local CameraController = Classes.GetSingleton("CameraController")
	
	self._InitialTransparency = {}

	local function HandleTransparencyInit(instance: Instance)
		
		if self:IsLocalPlayer() then
			
			if instance:IsA("BillboardGui")
				or instance:IsA("SurfaceGui") then
				
				(instance :: BillboardGui).Enabled = false
			end
		end
		
		if instance:FindFirstAncestorWhichIsA("Tool") then
			return
		end
		
		local Property
		for k, v in ClassPropertyTable do
			if instance:IsA(k) then
				Property = v
				break
			end
		end
		
		if not Property then
			return
		end
		
		instance[Property] = 0
		
		self._InitialTransparency[instance] = 0
		self:ApplyTransparency(self.Attributes.DestinatedTransparency)
	end

	self.Janitor:Add(self.Instance.DescendantAdded:Connect(function(...)
		HandleTransparencyInit(...)
	end))

	for _, Instance in ipairs(self.Instance:GetDescendants()) do
		HandleTransparencyInit(Instance)
	end
	
	--transparent parts thing
	
	if not self:IsLocalPlayer() then
		return
	end
	
	--applying transparency dependig on current camera mode
	self.Janitor:Add(RunService.RenderStepped:Connect(function()
		
		if not self.Head then
			return
		end
		
		local ActiveCamera = CameraController.ActiveCamera
		if not ActiveCamera then return end
		
		local CameraName = ActiveCamera.GetName():sub(1, -7)
		local Distance = (Camera.CFrame.Position - self.Head.Position).Magnitude
		local IsFirstPersonCamera = CameraName == "Default" or CameraName == "HeadLocked"
		
		for _, Descendant: Instance in (self.Instance:GetDescendants()) do
			
			local Property
			for k, v in ClassPropertyTable do
				if Descendant:IsA(k) then
					Property = v
					break
				end
			end
			
			if not Property then continue end
			if not self:IsDescendantTransparent(Descendant) then continue end
			--print(Descendant, Descendant:FindFirstAncestorWhichIsA("Model"), Property, Distance < 4.5 and IsFirstPersonCamera and 1 or self.Attributes.DestinatedTransparency, self.Attributes.DestinatedTransparency, Distance, IsFirstPersonCamera)
			
			if Distance < 4.5 and IsFirstPersonCamera then
				Descendant[Property] = 1
			else
				Descendant[Property] = self.Attributes.DestinatedTransparency
			end
			
		end
	end))
end

function BaseAppearance._InitHumanoidEvents(self: Component)
	assert(RunService:IsClient())
	
	--animations related
	local TracksListened = {} :: { AnimationTrack }
	
	local function HandleAnimationPlayed(animationTrack: AnimationTrack)
		if table.find(TracksListened, animationTrack) then
			return
		end
		
		table.insert(TracksListened, animationTrack)
		
		self.Janitor:Add(animationTrack:GetMarkerReachedSignal("Footstep"):Connect(function()
			
			local RoleConfig = RolesManager:GetPlayerRoleConfig(self.Player)
			local WalkAnimationExclusivesIds = {
				
				RoleConfig.SkillsData and RoleConfig.SkillsData.Sprint.Animation.AnimationId or nil,
				"rbxassetid://114827009311915", -- injured sprint
			}
			
			if animationTrack.Animation.AnimationId == RoleConfig.CharacterData.Animations.Walk.AnimationId
				and AnimationUtility.HasPlayingAnimationsWithIds(self.Humanoid, WalkAnimationExclusivesIds)
				or self.Humanoid.FloorMaterial == Enum.Material.Air then
				
				return
			end
			
			self:CreateFootstep()
		end))
	end
	
	self.Janitor:Add(self.Humanoid.Animator.AnimationPlayed:Connect(HandleAnimationPlayed))
	
	for _, AnimationTrack in ipairs(self.Humanoid.Animator:GetPlayingAnimationTracks()) do
		HandleAnimationPlayed(AnimationTrack)
	end
	
	-- jump and land camera tilting
	self.Janitor:Add(self.Humanoid.StateChanged:Connect(function(_, newState)
		if table.find({ Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Jumping }, newState) then
			self:CreateFootstep()
		end
	end))

	--health related
	self.Janitor:Add(MatchStateClient.PlayerDamaged:Connect(function(player, damageInfo)
		
		if player ~= self.Player then
			return
		end
		
		if damageInfo.Amount > 0 then
			SoundUtility.CreateTemporarySound(
				SoundUtility.GetRandomSoundFromDirectory(SoundUtility.Sounds.Players.Gore.Damage)
			).Parent = self.HumanoidRootPart
		end
	end))
end

function BaseAppearance.OnConstruct(self: Component)
	SharedComponent.OnConstruct(self)
	
	self.Player = Players:GetPlayerFromCharacter(self.Instance)
	self.Head = self.Instance:WaitForChild("Head") :: PlayerTypes.Head
	self.Torso = (self.Instance:FindFirstChild("Torso") or self.Instance:FindFirstChild("UpperTorso")) :: PlayerTypes.Torso
	self.Humanoid = self.Instance:WaitForChild("Humanoid") :: PlayerTypes.IHumanoid
	self.HumanoidRootPart = self.Instance:WaitForChild("HumanoidRootPart") :: PlayerTypes.HumanoidRootPart
	
	self._InternalTransparencyEvent = self:CreateEvent(
		"Transparency",
		"Reliable",
		
		function(...) return typeof(...) == "number" end,
		function(...) return ... == nil or typeof(...) == "table" end
	)
end

function BaseAppearance.OnConstructClient(self: Component)
	
	self.TransparencyJanitor = Janitor.new()
	
	self._LastStepTick = 0
	self._InitialCFrames = {}
	self._DestinatedDirection = self.Head.CFrame.LookVector
	
	self.Janitor:Add(self._InternalTransparencyEvent.On(function(...)
		self:ApplyTransparency(...)
	end))
	
	self.Instance:WaitForChild("Humanoid")
	
	self:_InitBodyTilt()
	self:_InitTransparency()
	self:_InitHumanoidEvents()
end

function BaseAppearance.OnConstructServer(self: Component)
	
	ComponentReplicator:PromptCreate(self, Players:GetPlayers())
	
	self.Janitor:Add(PlayerService.PlayerLoaded:Connect(function(player)
		
		ComponentReplicator:PromptCreate(self, { player })
	end))
end

function BaseAppearance.OnDestroy(self: Component)
	
	if RunService:IsServer() then
		
		ComponentReplicator:PromptDestroy(self, Players:GetPlayers())
	end
end

--//Remotes

if RunService:IsClient() then
	
	ClientRemotes.ServerLookVectorReplicated.SetCallback(function(args)
		
		local Component = ComponentsManager.Get(args.player.Character, args.componentName) :: Component?
		
		if not Component or Component:IsLocalPlayer() then
			return
		end

		Component._DestinatedDirection = args.lookDirection
	end)
end

--//Returner

return BaseAppearance