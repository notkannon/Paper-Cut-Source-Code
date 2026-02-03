 --//Services

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Roles = require(ReplicatedStorage.Shared.Data.Roles)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Utility = require(ReplicatedStorage.Shared.Utility)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local ClientRemotes = require(script.Parent.Parent.ClientRemotes)

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseAppearance = require(ReplicatedStorage.Shared.Components.Abstract.BaseAppearance)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local StaminaComponent = require(script.Stamina)
local SpeedHandlerComponent = require(script.SpeedHandler)
local BlindnessHandlerComponent = require(script.BlindnessHandler)

--//Constants

local WALK_ANIMATION_UPDATE_RATE = 0.3

--//Variables

local Camera = workspace.CurrentCamera

local CharacterComponent = BaseComponent.CreateComponent("ClientCharacterComponent") :: Impl

--//Types

type CharacterRotationMode = "Default" | "Smooth" | "Disabled"

export type MyImpl = {
	__index: MyImpl,
	
	SetRotationMode: (self: Component, mode: CharacterRotationMode) -> (),
	
	_InitStamina: (self: Component) -> (),
	_InitAnimations: (self: Component) -> (),
	_InitAppearance: (self: Component) -> (),
	_ConnectHumanoidEvents: (self: Component) -> (),
}

export type Fields = {
	Head: PlayerTypes.Head,
	Torso: PlayerTypes.Torso,
	Humanoid: PlayerTypes.IHumanoid,
	RotationMode: CharacterRotationMode,
	HumanoidRootPart: PlayerTypes.HumanoidRootPart,
	
	WCSCharacter: WCS.Character,
	
	Stamina: StaminaComponent.Component,
	Appearance: BaseAppearance.Component,
	SpeedHandler: CharacterSpeedHandler.Component,
	
	HealthChanged: Signal.Signal<number, number>,
	StaminaChanged: Signal.Signal<number, number>,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ClientCharacterComponent", PlayerTypes.Character, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "ClientCharacterComponent", PlayerTypes.Character, {}>

--//Functions

local function lerp(nstart : number, nend : number, phase : number)
	return nstart + (nend - nstart) * phase
end

local function LoadAnimation(humanoid: Humanoid, animation: Animation, params: ({ } & AnimationTrack)? ) : AnimationTrack
	local Animator = humanoid:FindFirstChildWhichIsA("Animator")
	
	if not Animator then
		Animator = Instance.new("Animator")
		Animator.Parent = humanoid
	end
	
	local Track = Animator:LoadAnimation(animation)
	
	if params then
		Utility.ApplyParams(Track, params)
	end
	
	return Track
end

--//Methods

function CharacterComponent.SetRotationMode(self: Component, mode: CharacterRotationMode)
	self.RotationMode = mode
end

function CharacterComponent._InitAppearance(self: Component)
	
	local ImplString = Classes.GetSingleton("PlayerController"):GetRoleString() .. "Appearance"
	
	--TODO: make :GetAppearance() to remove components dependencies
	self.Appearance = ComponentsManager.Get(self.Instance, ImplString)
	
	if self.Appearance then
		return
	end
	
	self.Janitor:Add(ComponentsManager.ComponentAdded:Connect(function(component)
		
		if component.GetName() ~= ImplString
			or component.Instance ~= component.Instance then
			
			return
		end
		
		self.Janitor:Remove("AppearanceGetter")
		self.Appearance = component
		
	end), nil, "AppearanceGetter")
end

--TODO: Animation controller component
function CharacterComponent._InitAnimations(self: Component)
	
	local AnimationFade = 0.35
	local BaseCharacterSpeed = 13
	
	local RoleConfig = Classes.GetSingleton("PlayerController"):GetRoleConfig() :: Roles.Role
	
	local IdleAnimation = LoadAnimation(self.Humanoid, RoleConfig.CharacterData.Animations.Idle, {Looped = true, Priority = Enum.AnimationPriority.Idle})
	local WalkAnimation = LoadAnimation(self.Humanoid, RoleConfig.CharacterData.Animations.Walk, {Looped = true, Priority = Enum.AnimationPriority.Movement})
	
	local IdleInjuredAnimation
	local WalkInjuredAnimation
	
	if RoleConfig.CharacterData.Animations.IdleInjured then
		IdleInjuredAnimation = LoadAnimation(self.Humanoid, RoleConfig.CharacterData.Animations.IdleInjured, {Looped = true, Priority = Enum.AnimationPriority.Idle})
	end
	
	if RoleConfig.CharacterData.Animations.WalkInjured then
		WalkInjuredAnimation = LoadAnimation(self.Humanoid, RoleConfig.CharacterData.Animations.WalkInjured, {Looped = true, Priority = Enum.AnimationPriority.Movement})
	end
	
	self.Janitor:Add(IdleAnimation)
	self.Janitor:Add(WalkAnimation)
	
	if IdleInjuredAnimation then self.Janitor:Add(IdleInjuredAnimation) end
	if WalkInjuredAnimation then self.Janitor:Add(WalkInjuredAnimation) end
	
	IdleAnimation:Play()
	
	local LastSpeedUpdate = 0
	
	self.Janitor:Add(RunService.Stepped:Connect(function()
		
		local LinearVelocity = self.HumanoidRootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
		local MovementMagnitude = math.round(LinearVelocity.Magnitude * 100) / 100
		
		local HPPercentage = self.Humanoid.Health / self.Humanoid.MaxHealth
		
		if IdleInjuredAnimation then
			if HPPercentage <= 0.5 then
				if IdleAnimation.IsPlaying then IdleAnimation:Stop(AnimationFade) end
				if not IdleInjuredAnimation.IsPlaying then IdleInjuredAnimation:Play(AnimationFade) end
			else
				if IdleInjuredAnimation.IsPlaying then IdleInjuredAnimation:Stop(AnimationFade) end
				if not IdleAnimation.IsPlaying then IdleAnimation:Play(AnimationFade) end
			end
		end
		
		local IsWalking = WalkAnimation.IsPlaying or (WalkInjuredAnimation and WalkInjuredAnimation.IsPlaying)
		--print(IdleAnimation, IdleInjuredAnimation, WalkAnimation, WalkInjuredAnimation, IsWalking)
		--print(HPPercentage, IdleAnimation.IsPlaying, IdleInjuredAnimation.IsPlaying, WalkAnimation.IsPlaying, WalkInjuredAnimation.IsPlaying, IsWalking)
		
		if MovementMagnitude == 0 and IsWalking then
			
			if WalkInjuredAnimation then
				WalkInjuredAnimation:Stop(AnimationFade)
			end
			
			WalkAnimation:Stop(AnimationFade)

		elseif MovementMagnitude > 0 and not IsWalking then
			
			if WalkInjuredAnimation and HPPercentage <= 0.5 then
				WalkInjuredAnimation:Play(AnimationFade)
			else
				WalkAnimation:Play(AnimationFade)
			end
			
		end
		
		if os.clock() - LastSpeedUpdate < WALK_ANIMATION_UPDATE_RATE then
			return
		end
		
		LastSpeedUpdate = os.clock()
		
		local GoalSpeed = MathUtility.QuickLerp(WalkAnimation.Speed, MovementMagnitude / BaseCharacterSpeed, 0.5)
		
		WalkAnimation:AdjustSpeed(GoalSpeed)
		
		if WalkInjuredAnimation then
			WalkInjuredAnimation:AdjustSpeed(GoalSpeed * 1.43)
		end
	end))
end

function CharacterComponent._ConnectHumanoidEvents(self: Component)
	
	self.HealthChanged = self.Janitor:Add(Signal.new())
	
	local OldHealth = self.Humanoid.Health
	
	self.Janitor:Add(self.Humanoid.HealthChanged:Connect(function(newHealth)
		
		if OldHealth == newHealth then
			return
		end
		
		self.HealthChanged:Fire(newHealth, OldHealth)
		
		OldHealth = newHealth
	end))
end

--function CharacterComponent.OnPhysics(self: Component, deltaTime: number)
	
--	local HumanoidState = self.Humanoid:GetState()
	
--	if not self.HumanoidRootPart
--		or self.HumanoidRootPart.Anchored
--		or HumanoidState ~= Enum.HumanoidStateType.Running then
		
--		return
--	end
	
--	local CurrentCFrame = self.HumanoidRootPart.CFrame
--	local Y = select(2, CurrentCFrame:ToOrientation())
	
--	print("Works", Y)
--	self.HumanoidRootPart.CFrame = CFrame.new(CurrentCFrame.Position) * CFrame.Angles(0, Y, 0)
--end

function CharacterComponent.OnRender(self: Component, deltaTime: number)
	
	local HumanoidState = self.Humanoid:GetState()
	
	if self.HumanoidRootPart.Anchored
		or HumanoidState == Enum.HumanoidStateType.Ragdoll
		or HumanoidState == Enum.HumanoidStateType.PlatformStanding then
		
		return
	end
	
	if self.RotationMode == "Default" then
		self.Humanoid.AutoRotate = true
		
	else
		self.Humanoid.AutoRotate = false
		
		if self.RotationMode == "Disabled" then
			return
		end
		
		local CameraOrientY = select(2, Camera.CFrame:ToOrientation())
		
		self.HumanoidRootPart.CFrame = CFrame.new(self.HumanoidRootPart.CFrame.Position) 
			* self.HumanoidRootPart.CFrame.Rotation:Lerp(CFrame.Angles(0, CameraOrientY, 0), 1 / 5)
	end
end

function CharacterComponent.OnConstructClient(self: Component)
	
	local PlayerController = Classes.GetSingleton("PlayerController")
	
	self.RotationMode = PlayerController:IsSpectator() and "Default" or "Smooth"
	
	self.Head = self.Instance:FindFirstChild("Head") :: PlayerTypes.Head
	self.Torso = (self.Instance:FindFirstChild("Torso") or self.Instance:FindFirstChild("UpperTorso")) :: PlayerTypes.Torso
	self.Humanoid = self.Instance:WaitForChild("Humanoid") :: PlayerTypes.IHumanoid
	self.HumanoidRootPart = self.Instance:WaitForChild("HumanoidRootPart") :: PlayerTypes.HumanoidRootPart

	self.Humanoid.JumpPower = 0
	self.Humanoid.JumpHeight = 0
	
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	
	--removing face expression
	--local Face = self.Instance:FindFirstChild("Face") :: BasePart
	
	--if Face then
	--	Face:Destroy()
	--end
	
	self.WCSCharacter = self.Janitor:AddPromise(WCSUtility.PromiseCharacterAdded(self.Instance)):timeout(35):expect()
	
	self:_InitAnimations()
	self:_InitAppearance()
	self:_ConnectHumanoidEvents()
	
	--adding speed handler
	ComponentsManager.Add(self.Instance, SpeedHandlerComponent, self):Start()
	
	--adding blindness handler
	ComponentsManager.Add(self.Instance, BlindnessHandlerComponent, self):Start()

	--adding stamina component
	ComponentsManager.Add(self.Instance, StaminaComponent, self)
end

--//Returner

return CharacterComponent