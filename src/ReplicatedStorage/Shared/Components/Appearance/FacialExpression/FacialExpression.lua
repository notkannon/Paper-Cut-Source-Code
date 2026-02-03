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

local Enums = require(ReplicatedStorage.Shared.Enums)
local BaseFacePack = require(ReplicatedStorage.Shared.Data.Appearance.BaseFacePack)

local ChaseReplicator = RunService:IsServer() and require(ServerScriptService.Server.Services.ChaseReplicator) or nil

local RandomUtility = require(ReplicatedStorage.Shared.Utility.Random)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

--//Variables

local INJURED_HEALTH_THRESHOLD = 50

local LocalPlayer = Players.LocalPlayer
local FacePacksFolder = ReplicatedStorage.Shared.Data.Appearance.FacePacks
local FaceExpressionsEnum = Enums.FaceExpression
local FacialExpression = BaseComponent.CreateComponent("FacialExpression", {
	
	tag = "FacialExpression",
	isAbstract = false,
	ancestorWhitelist = {
		workspace
	},
	
	--players only feature
	predicate = function(instance)
		
		local Player = Players:GetPlayerFromCharacter(instance.Parent)
		
		--restricted to create expression component on client
		if Player == LocalPlayer then
			return false
		end
		
		return Player ~= nil
	end,
	
}, SharedComponent) :: Impl

--//Types

export type ActiveFace = {
	Timestamp: number?,
} & BaseFacePack.FaceData

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: SharedComponent.MyImpl)),
	
	CreateEvent: SharedComponent.CreateEvent<Component>,
	
	AddFace:(self: Component, context: number, duration: number?) -> (),
	ApplyFace:(self: Component, context: number) -> (),
	RemoveFace:(self: Component, context: number) -> (),
	
	OnConstruct: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
	OnConstructServer: (self: Component) -> (),
	
	_ConnectEvents: (self: Component) -> (),
}

export type Fields = {
	
	FacePack: { [number]: BaseFacePack.FaceData },
	ActiveFaces: { [number]: ActiveFace? },
	IsSurfaceUI: boolean,
	
	FaceAdded: Signal.Signal<string>,
	FaceApplied: Signal.Signal<string>,
	FaceRemoved: Signal.Signal<string, boolean>,
	
	SideDecal: Decal,
	EyesDecal: Decal,
	MouthDecal: Decal,
	
	Head: BasePart,
	Player: Player,
	Humanoid: Humanoid,
	Character: PlayerTypes.Character,
	HumanoidRootPart: PlayerTypes.HumanoidRootPart,
	
} & SharedComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "FacialExpression", BasePart>
export type Component = BaseComponent.Component<MyImpl, Fields, "FacialExpression", BasePart>

--//Methods

--//Methods

function FacialExpression.ApplyFace(self: Component, context: number)
	
	local faceData = self.ActiveFaces[context]
	
	if not faceData then
		return
	end
	
	local Property = self.IsSurfaceUI and "Image" or "Texture"
	
	self.EyesDecal[Property] = faceData.Textures.Eyes or self.EyesDecal[Property]
	self.SideDecal[Property] = faceData.Textures.Side or self.SideDecal[Property]
	self.MouthDecal[Property] = faceData.Textures.Mouth or self.MouthDecal[Property]
	
	self.FaceApplied:Fire(context)
end

function FacialExpression.RemoveFace(self: Component, context: number)
	
	if not self.ActiveFaces[context] then
		return
	end

	self.ActiveFaces[context] = nil
	self.FaceRemoved:Fire(context, true)

	local highestContext = self:_GetMostPrioritizedFace()
	
	if highestContext then
		self:ApplyFace(highestContext)
	else
		self:ApplyFace(FaceExpressionsEnum.Default)
	end
end

function FacialExpression.AddFace(self: Component, context: number, duration: number?)
	
	local faceData = self.FacePack[context]
	
	if not faceData then
		return
	end
	
	local ValidTextures = 0
	if not faceData.Textures then
		return
	end
	
	for k, v in faceData.Textures do
		if v and v ~= "" then
			ValidTextures += 1
		end
	end
	
	if ValidTextures == 0 then
		return
	end
	
	--print(faceData)

	local now = os.clock()
	
	self.ActiveFaces[context] = {
		Timestamp = duration and (now + duration) or nil,
		Duration = faceData.Duration,
		Priority = faceData.Priority,
		Textures = faceData.Textures,
	}

	self.FaceAdded:Fire(context)

	local highestContext = self:_GetMostPrioritizedFace()
	
	if highestContext == context then
		self:ApplyFace(context)
	end
end

function FacialExpression._GetMostPrioritizedFace(self: Component): number?
	
	local maxPriority = -math.huge
	local topContext = nil

	for context, faceData in pairs(self.ActiveFaces) do
		
		local priority = faceData.Priority or 0
		
		if priority > maxPriority then
			maxPriority = priority
			topContext = context
		end
	end

	return topContext
end

function FacialExpression._ConnectEvents(self: Component)
	
	--blinking things
	
	local LastBlinkTime = os.clock()
	local BlinkDelay = 1
	
	local function TryBlink()
		
		if os.clock() - LastBlinkTime < BlinkDelay then
			return
		end
		
		LastBlinkTime = os.clock()
		BlinkDelay = math.random(10, 50) / 10
		if self.Humanoid.Health <= INJURED_HEALTH_THRESHOLD and self.FacePack[FaceExpressionsEnum.InjuredBlink] then
			self:AddFace(FaceExpressionsEnum.InjuredBlink, 0.1)
		else
			self:AddFace(FaceExpressionsEnum.Blink, 0.1)
		end
	end
	
	--updating loop
	self.Janitor:Add(RunService.Heartbeat:Connect(function()
		
		local now = os.clock()
		local changed = false
		
		--trying to blink lol :d
		TryBlink()
		
		for context, faceData in pairs(self.ActiveFaces) do

			if faceData.Timestamp and now >= faceData.Timestamp then
				
				self.ActiveFaces[context] = nil
				self.FaceRemoved:Fire(context, false)

				changed = true
			end
		end

		if changed then

			local topContext = self:_GetMostPrioritizedFace()

			if topContext then
				self:ApplyFace(topContext)
			else
				self:ApplyFace(FaceExpressionsEnum.Default)
			end
		end
	end))
	
	local IsInjured = false
	local OldHealth = self.Humanoid.Health
	
	self.Janitor:Add(self.Humanoid.HealthChanged:Connect(function(newHealth)
		local DAMAGE_THRESHOLD = 5 -- with the addition of bleeding, we've decided small damage shouldn't proc  OnDamage face
		--applying on damage thing
		if OldHealth - newHealth >= DAMAGE_THRESHOLD then
			
			local FaceData = self.FacePack[FaceExpressionsEnum.OnDamage]
			local Duration = 0.75
			
			self:AddFace(FaceExpressionsEnum.OnDamage, Duration)
		end
		
		--injured status
		if IsInjured and newHealth > INJURED_HEALTH_THRESHOLD then
			
			IsInjured = false
			
			self:RemoveFace(FaceExpressionsEnum.Injured)
			
		elseif not IsInjured and newHealth <= INJURED_HEALTH_THRESHOLD then
			
			IsInjured = true
			
			self:AddFace(FaceExpressionsEnum.Injured)
		end
		
		OldHealth = newHealth
	end))
	
	--death connection
	self.Janitor:Add(self.Humanoid.Died:Once(function()
		self:AddFace(FaceExpressionsEnum.Died)
	end))
	
	self.Janitor:Add(ChaseReplicator.ChaseStarted:Connect(function(player)
		if self.Player == player and self.FacePack[FaceExpressionsEnum.InChase]  then
			self:AddFace(FaceExpressionsEnum.InChase)
		end
	end))
	
	self.Janitor:Add(ChaseReplicator.ChaseEnded:Connect(function(player)
		if self.Player == player and self.FacePack[FaceExpressionsEnum.InChase] then
			self:RemoveFace(FaceExpressionsEnum.InChase)
		end
	end))
end

function FacialExpression.OnConstructServer(self: Component)
	
	local Character = self.Instance.Parent :: PlayerTypes.Character
	local SurfaceGui = self.Instance:FindFirstChildWhichIsA("SurfaceGui")
	
	self.IsSurfaceUI = SurfaceGui ~= nil
	
	local Path = self.IsSurfaceUI and SurfaceGui or self.Instance
	
	self.EyesDecal = Path:FindFirstChild("Eyes")
	self.SideDecal = Path:FindFirstChild("Side")
	self.MouthDecal = Path:FindFirstChild("Mouth")
	
	self.Player = Players:GetPlayerFromCharacter(Character)
	self.Head = Character:WaitForChild("Head") :: PlayerTypes.Head
	self.Humanoid = Character:WaitForChild("Humanoid") :: PlayerTypes.IHumanoid
	self.HumanoidRootPart = Character:WaitForChild("HumanoidRootPart") :: PlayerTypes.HumanoidRootPart
	
	self.ActiveFaces = {}
	
	self.FaceAdded = self.Janitor:Add(Signal.new())
	self.FaceApplied = self.Janitor:Add(Signal.new())
	self.FaceRemoved = self.Janitor:Add(Signal.new())
	
	local RoleConfig = RolesManager:GetPlayerRoleConfig(self.Player)
	
	--defining face pack
	self.FacePack = RoleConfig.FacePack or BaseFacePack
	
	self:_ConnectEvents()
	self:AddFace(FaceExpressionsEnum.Default)
end

--//Returner

return FacialExpression