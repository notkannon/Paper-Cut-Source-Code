--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)

local Utility = require(ReplicatedStorage.Shared.Utility)
local ItemsData = require(ReplicatedStorage.Shared.Data.Items)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
--local RaycastHitbox = require(ReplicatedStorage.Packages.RaycastHitbox)
local ShapecastHitbox = require(ReplicatedStorage.Packages.ShapecastHitbox)

local BaseThrowable = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem.BaseThrowable)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil
local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil
local PlayersService = RunService:IsServer() and require(ServerScriptService.Server.Services.PlayerService) or nil

--//Constants

local GRAVITY_MUL = 1.4
local STRENGTH_MUL = 50
local MINIMAL_STRENGTH = 37
local PROJECTILE_COLLISION_GROUP = "Projectiles"


--//Variables

local ActiveThrowables = {} :: { ActiveThrowable }
local ThrowablesContainer

local ThrowablesService: Impl = Classes.CreateSingleton("ThrowablesService") :: Impl
ThrowablesService.Thrown = Signal.new()
ThrowablesService.Hit = Signal.new()

--//Types

export type ThrowableData = {
	Origin: Vector3,
	Strength: number,
	Direction: Vector3,
	Performer: Player,
}

export type ActiveThrowable = {
	Hitbox: unknown,
	ItemComponent: BaseThrowable.Component,
} & ThrowableData

export type Fields = {
	Hit: Signal.Signal<ActiveThrowable, Player?>,
	Thrown: Signal.Signal<ActiveThrowable>,
}

export type Impl = {
	__index: Impl,
	
	new: () -> Service,
	IsImpl: (self: Service) -> boolean,
	GetName: () -> "ThrowablesService",
	GetExtendsFrom: () -> nil,

	OnConstruct: (self: Service) -> (),
	OnConstructServer: (self: Service) -> (),
	OnConstructClient: (self: Service) -> (),
	
	Create: (self: Service, itemComponent: BaseThrowable.Component, data: ThrowableData) -> (),
	GetActiveThrowableFromInstance: (self: Service) -> ActiveThrowable?,
}

export type Service = typeof(setmetatable({} :: Fields, {} :: Impl))

--//Functions

local function ApplyImpulse(basepart: BasePart, strength: number, origin: Vector3, direction: Vector3)
	
	basepart:PivotTo(CFrame.lookAlong(origin, direction))
	basepart.AssemblyLinearVelocity = Vector3.zero
	basepart.AssemblyAngularVelocity = Vector3.zero
	
	--print("APPLYING IMPULSE TO", basepart, origin, direction, direction - origin)
	basepart:ApplyImpulse(direction * strength * 90)
end

--//Methods

function ThrowablesService.GetActiveThrowableFromInstance(self: Service, instance: Instance)
	for _, ActiveThrowable in ipairs(ActiveThrowables) do
		if ActiveThrowable.ItemComponent.Instance:IsAncestorOf(instance) then
			return ActiveThrowable
		end
	end
end

function ThrowablesService.Create(self: Service, itemComponent: BaseThrowable.Component, data: ThrowableData, castData: ShapecastHitbox.CastData)
	assert(RunService:IsServer())
	
	local ActiveThrowable = TableKit.MergeDictionary({ ItemComponent = itemComponent }, data) :: ActiveThrowable
	
	table.insert(ActiveThrowables, ActiveThrowable)
	
	--memory cleaning
	itemComponent.Janitor:Add(function()
		
		local Index = table.find(ActiveThrowables, ActiveThrowable)
		
		if not Index then
			return
		end
		
		table.clear(ActiveThrowable)
		table.remove(ActiveThrowables, Index)
	end)

	local Hitbox = itemComponent.Janitor:Add(ShapecastHitbox.new(itemComponent.Handle), "Destroy")
	local ItemImpl = ComponentsManager.GetImpl(itemComponent.GetName()) :: BaseThrowable?
	
	ShapecastHitbox.Settings.Debug_Visible = false
	if castData then
		Hitbox:SetCastData(castData)
	end
	--Hitbox.Settings.Visualizer = false
	--Hitbox.DetectionMode = RaycastHitbox.DetectionMode.PartMode
	Hitbox.RaycastParams = RaycastParams.new()
	
	local Filter = { workspace.ThrownItems, workspace.Temp }
	if data.Performer then
		table.insert(Filter, data.Performer.Character)
	end
	
	Utility.ApplyParams(Hitbox.RaycastParams, {
		
		FilterType = Enum.RaycastFilterType.Exclude,
		CollisionGroup = PROJECTILE_COLLISION_GROUP,
		FilterDescendantsInstances = Filter,
		
	} :: RaycastParams)
	
	--itemComponent.Janitor:Add(Hitbox.OnHit:Connect(function(basepart: BasePart, _, raycastResult: RaycastResult)

	--	local HitPlayer = Players:GetPlayerFromCharacter(
	--		raycastResult.Instance:FindFirstAncestorOfClass("Model")
	--	)

	--	--bypass function
	--	if not HitPlayer
	--		and not basepart.CanCollide
	--		and basepart.Transparency == 1 then

	--		return
	--	end

	--	self.Hit:Fire(ActiveThrowable, HitPlayer or basepart)

	--	itemComponent:OnHit(raycastResult, HitPlayer)
	--	if itemComponent.DestroyOnHit then 
	--		itemComponent:Destroy()
	--	end

	--end), "Disconnect")
	local killswitch = false
	itemComponent.Janitor:Add(Hitbox:HitStart():OnHit(function(raycastResult: RaycastResult, segmentHit: ShapecastHitbox.Segment)
		if killswitch then return end
		local HitPlayer = Players:GetPlayerFromCharacter(
			raycastResult.Instance:FindFirstAncestorOfClass("Model")
		)
		local basepart = raycastResult.Instance
		
		--bypass function
		if not HitPlayer
			and not basepart.CanCollide
			and basepart.Transparency == 1 then
			return
		end
		
		killswitch = true

		self.Hit:Fire(ActiveThrowable, HitPlayer or basepart)

		itemComponent:OnHit(raycastResult, HitPlayer)
		if itemComponent.DestroyOnHit then 
			itemComponent:Destroy()
		end
	end):OnStopped(function(stopCallback) stopCallback() end))

	ActiveThrowable.Hitbox = Hitbox
	
	if data.Performer then 
		itemComponent:GetInventory():Remove(itemComponent)
	end
	
	if itemComponent.Instance:FindFirstChildWhichIsA("LinearVelocity") then
		itemComponent.Instance:FindFirstChildWhichIsA("LinearVelocity"):Destroy()
	end
	
		
	itemComponent.Instance.Parent = workspace.ThrownItems
	itemComponent.Handle:SetNetworkOwner(nil)
	itemComponent.Handle.CollisionGroup = Hitbox.RaycastParams.CollisionGroup
	itemComponent.Handle.CanCollide = false
	itemComponent.Handle.CanQuery = true

	if itemComponent.Interaction then
		itemComponent.Interaction.Instance:Destroy()
		itemComponent.Interaction = nil
	end
	
	Hitbox:HitStart()
	
	ApplyImpulse(
		itemComponent.Handle,
		ActiveThrowable.Strength,
		ActiveThrowable.Origin,
		ActiveThrowable.Direction
	)
	
	--local RemoteData = table.clone(ActiveThrowable) :: ActiveThrowable
	--RemoteData.Hitbox = nil
	--RemoteData.ItemComponent = nil
	
	ServerRemotes.ThrowablesServiceCreate.FireAll({
		instance = itemComponent.Instance,
		userData = data
	})
	
	itemComponent:OnFlightStart(itemComponent.Handle, itemComponent.Janitor, data)
	itemComponent.Janitor:Add(task.delay(10, function() itemComponent:Destroy() end)) -- preventing memory leaks
	
	self.Thrown:Fire(data)
end

function ThrowablesService.OnConstructServer(self: Service)
	
	ThrowablesContainer = Instance.new("Folder")
	ThrowablesContainer.Name = "ThrowablesTemp"
	ThrowablesContainer.Parent = workspace
end

function ThrowablesService.OnConstructClient(self: Service)
	
	ThrowablesContainer = workspace:FindFirstChild("ThrowablesTemp")
	
	ClientRemotes.ThrowablesServiceCreate.SetCallback(function(args)
		
		self.Thrown:Fire(args.userData)
		
		local ImplString = args.instance:GetAttribute("Impl")
		local ItemImpl = ComponentsManager.GetImpl(ImplString) :: BaseThrowable?
		
		if not ItemImpl then
			
			warn(`Throwable item impl doesn't exist: { ImplString }`)
			
			return
		end
		
		local Handle = args.instance:FindFirstChildWhichIsA("BasePart")
		
		if not Handle then
			return
		end
		
		local Projectile = Handle:Clone()
		Projectile.Parent = ThrowablesContainer
		Projectile.LocalTransparencyModifier = 0
		--Projectile.Material = Enum.Material.Neon
		
		--making original invisible
		Handle.Transparency = 1
		Handle.LocalTransparencyModifier = 1
		--Handle.Material = Enum.Material.Neon
		
		Handle:ClearAllChildren()
		
		ApplyImpulse(
			Projectile,
			args.userData.Strength,
			args.userData.Origin,
			args.userData.Direction
		)
		
		local ClientJanitor = Janitor.new()
		ClientJanitor:Add(Projectile)
		ClientJanitor:LinkToInstance(args.instance)

		ItemImpl:OnFlightStart(Projectile, ClientJanitor, args.userData)
	end)
end

--//Returner

local Singleton = ThrowablesService.new() :: Service
return Singleton