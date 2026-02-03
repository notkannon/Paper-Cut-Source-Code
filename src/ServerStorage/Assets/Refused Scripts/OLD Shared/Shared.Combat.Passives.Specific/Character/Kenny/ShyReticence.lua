--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Refx = require(ReplicatedStorage.Packages.Refx)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BasePassive = require(ReplicatedStorage.Shared.Components.Abstract.BasePassive)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)

local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local MatchService = RunService:IsServer() and require(ServerScriptService.Server.Services.MatchService) or nil
local ChaseReplicator = RunService:IsServer() and require(ServerScriptService.Server.Services.ChaseReplicator) or nil
local HighlightPlayerEffect = require(ReplicatedStorage.Shared.Effects.HighlightPlayer)

--//Variables

local ShyReticence = BaseComponent.CreateComponent("ShyReticence", {

	isAbstract = false,

}, BasePassive) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BasePassive.MyImpl)),
	
	Stop: (self: Component) -> (),
	Start: (self: Component) -> (),
	IsActive: (self: Component) -> boolean,
	ShouldStart: (self: Component) -> boolean,

	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component, enabled: boolean?) -> (),
	OnConstructServer: (self: Component) -> (),
}

export type Fields = {
	
	_Active: boolean,
	_AvailabilityTimestamp: number?,

} & BasePassive.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "ShyReticence", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "ShyReticence", PlayerTypes.Character>

--//Methods

function ShyReticence.IsActive(self: Component)
	return self._Active
end

--start become invisible
function ShyReticence.Start(self: Component)
	
	if not self:IsEnabled()
		or self:IsActive() then
		
		return
	end
	
	self._Active = true
	
	--getting appearance component to access transparency operations
	local Config = self:GetConfig()
	local Appearance = ComponentsManager.GetFirstComponentInstanceOf(self.Instance, "BaseAppearance")
	
	--applying transparency
	Appearance:ApplyTransparency(Config.Transparency, Config.TweenConfig)
	
	--	cancelling connections
	
	--damage
	self.EnabledJanitor:Add(MatchService.PlayerDamaged:Connect(function(player)
		
		if player ~= self.Player then
			return
		end
		
		self:Stop()
		
	end), "Disconnect", "DamageListener")
	
	--movement
	self.EnabledJanitor:Add(self.Instance.Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		
		self:Stop()
		
	end), "Disconnect", "MovementListener")
end

--stop become invisible
function ShyReticence.Stop(self: Component)
	
	if not self:IsEnabled()
		or not self:IsActive() then
		
		return
	end
	
	local Appearance = ComponentsManager.GetFirstComponentInstanceOf(self.Instance, "BaseAppearance")
	
	self._Active = false
	
	self.EnabledJanitor:RemoveList(
		"DamageListener",
		"MovementListener"
	)
	
	--resetting availability
	self._AvailabilityTimestamp = os.clock()
	
	Appearance:ApplyTransparency(0, {
		Time = 0.5
	})
end

function ShyReticence.ShouldStart(self: Component)
	
	local Humanoid = self.Instance.Humanoid :: Humanoid
	
	return Humanoid.MoveDirection.Magnitude == 0
		and Humanoid:GetState() == Enum.HumanoidStateType.Running
end

function ShyReticence.OnEnabledServer(self: Component)
	
	--config definition
	local Config = self:GetConfig()
	
	self._Active = false
	self._AvailabilityTimestamp = os.clock()
	
	self.EnabledJanitor:Add(RunService.Heartbeat:Connect(function()
		
		if not self:ShouldStart() then
			
			self._AvailabilityTimestamp = os.clock()
			
			return
		end
		
		if os.clock() - self._AvailabilityTimestamp < Config.Downtime then
			return
		end
		
		self:Start()
	end))
end

function ShyReticence.OnConstructServer(self: Component, ...)
	BasePassive.OnConstructServer(self, ...)
	
	--passive will not work on class Stealther
	if RolesManager:GetPlayerRoleConfig(self.Player).Name == "Stealther" then
		self._Enabled = false
	end
	
	--local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Instance)
	
	--active exclusives
	--self.Janitor:Add(WCSCharacter.SkillStarted:Connect(function(skill)
	--	if skill:GetName() == "ConcealedPresence" then
			
	--		--print("Shy reticence disabled")
			
	--		self:SetEnabled(false)
	--	end
	--end))

	--self.Janitor:Add(WCSCharacter.SkillEnded:Connect(function(skill)
	--	if skill:GetName() == "ConcealedPresence" then
			
	--		--print("Shy reticence enabled")
			
	--		self:SetEnabled(true)
	--	end
	--end))
end

--function ShyReticence.OnConstruct(self: Component, enabled: boolean?)
--	BasePassive.OnConstruct(self)
	
--	self.Permanent = true
--end

--//Returner

return ShyReticence