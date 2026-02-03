--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Types = require(ReplicatedStorage.Shared.Types)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local ItemsData = require(ReplicatedStorage.Shared.Data.Items)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseItem = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

local StunnedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Stunned)

local ThrowableImpactEffect = require(ReplicatedStorage.Shared.Effects.Specific.Components.Items.ThrowableImpact)

local Utility = require(ReplicatedStorage.Shared.Utility)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

--//Variables

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local BaseThrowable = BaseComponent.CreateComponent("BaseThrowable", {
	
	isAbstract = true,
	
	defaults = {
		Released = false,
	},
	
	predicate = function(instance: Tool)
		return instance:IsA("Tool") and instance:HasTag("Throwable")
	end,
	
}, BaseItem) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseItem.Impl)),
	
	OnHit: (self: Component, raycastResult: RaycastResult, userData: { any }) -> (),
	OnFlightStart: (instance: BasePart, janitor: Janitor.Janitor, userData: { any }) -> (),
	
	_CancelAiming: (self: Component) -> (),
}

export type Fields = {
	Aiming: boolean,
	ThrowEvent: SharedComponent.ServerToClient | SharedComponent.ClientToServer,
	
	_AimStrength: number,
	_AimConnection: RBXScriptConnection?,
	
} & BaseItem.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, Tool, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, string, Tool, {}>

--//Functions

local function SerializeVector3(vec: Vector3) : { number }
	return { vec.X, vec.Y, vec.Z }
end

local function DeserializeVector3(array: { number }) : Vector3
	return Vector3.new(table.unpack(array))
end

--//Methods

--@override
function BaseThrowable.OnFlightStart(self, _, __, userData)
	SoundUtility.CreateTemporarySoundAtPosition(
		userData.Origin,
		SoundUtility.Sounds.Instances.Items.Throwable.Throw
	)
end
--@override
function BaseThrowable.OnHit(self, raycastResult: RaycastResult, playerHit: Player?)
	
	if RunService:IsServer() then
		
		ThrowableImpactEffect.new(raycastResult.Position):Start(Players:GetPlayers())

		local PlayerComponent = ComponentsManager.Get(playerHit, "PlayerComponent")
		
		--hit only killers
		if not PlayerComponent or not PlayerComponent:IsKiller() then
			return
		end

		local CharacterComponent = PlayerComponent.CharacterComponent
		local WCSCharacter = CharacterComponent and CharacterComponent.WCSCharacter :: WCS.Character?

		if not WCSCharacter then
			return
		end

		if WCSUtility.HasActiveStatusEffectsWithNames(WCSCharacter, {"Invincible", "Handled", "Stunned"}) then
			return
		end

		SoundUtility.CreateTemporarySound(
			SoundUtility.Sounds.Players.Replicas.Ouch
		).Parent = CharacterComponent.HumanoidRootPart

		SoundUtility.CreateTemporarySound(
			SoundUtility.Sounds.Players.Gore.Impact
		).Parent = CharacterComponent.HumanoidRootPart
		
		StunnedStatus.new(WCSCharacter):Start(3)
	end
end


function BaseThrowable._CancelAiming(self: Component)
	assert(RunService:IsClient())
	
	local AimHandler = ComponentsManager.Get(self.Character, "AimHandler")
	
	if not AimHandler then
		return
	end
	
	AimHandler:End()
end

function BaseThrowable.OnUnequipClient(self: Component)
	self:_CancelAiming()
end

function BaseThrowable.OnStartClient(self: Component)
	self:_CancelAiming()
end

function BaseThrowable.OnAssumeStartClient(self: Component)
	
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Character)
	
	if not WCSUtility.HasActiveStatusEffectsWithNames(WCSCharacter, {"Aiming"}) then
		return
	end
	
	local HeadPosition = self.Character:FindFirstChild("Head").Position
	local CameraLookVector = Camera.CFrame.LookVector
	
	local RoleConfig = RolesManager:GetPlayerRoleConfig(self.Player)
	local Strength = RoleConfig.CharacterData.UniqueProperties and RoleConfig.CharacterData.UniqueProperties.ThrowStrength or 1
	
	
	self.ThrowEvent.Fire(
		Strength,
		SerializeVector3(HeadPosition),
		SerializeVector3(CameraLookVector)
	)
end

function BaseThrowable.OnConstruct(self: Component, ...)
	BaseItem.OnConstruct(self, ...)
	
	self.DestroyOnHit = true
	
	self.ThrowEvent = self:CreateEvent(
		"Throw",
		"Reliable",
		
		function(strength: number) return typeof(strength) == "number" end,
		function(origin: { number }) return typeof(origin) == "table" end,
		function(direction: { number }) return typeof(direction) == "table" end
	)
end

function BaseThrowable.HandleAssumeStartServer(self: Component, player: Player?, strength: number, origin: { number }, direction: { number }, castData : {})
	--print('hello world', player, strength, origin, direction)
	if player then
		local InventoryComponent = ComponentsManager.Get(player.Backpack, "InventoryComponent")

		if self.Attributes.Released
			or not InventoryComponent
			or not InventoryComponent:IsMember(self) then

			return
		end
	end

	local strength = math.max(strength, 0) -- no longer capped at 1
	local origin = DeserializeVector3(origin)
	local direction = DeserializeVector3(direction)

	self.Attributes.Released = true
	self.Janitor:Remove("ThrowEventConnection")

	--animation depends on instances hierarchy, not taken from config :sob:
	if player then
		AnimationUtility.QuickPlay(

			self.Character:FindFirstChildWhichIsA("Humanoid"),
			ReplicatedStorage.Assets.Animations.Student.Skills.Aim.Release, {
				Looped = false,
				Priority = Enum.AnimationPriority.Action2,
			}
		)
	end

	Classes.GetSingleton("ThrowablesService"):Create(self, {
		Performer = player,
		Origin = origin,
		Strength = strength,
		Direction = direction,
	}, castData)	
end

function BaseThrowable.OnConstructServer(self: Component)
	BaseItem.OnConstructServer(self)
	
	self.Janitor:Add(self.ThrowEvent.On(function(...)
		self:HandleAssumeStartServer(...)
	end), nil, "ThrowEventConnection")
end

--//Returner

return BaseThrowable