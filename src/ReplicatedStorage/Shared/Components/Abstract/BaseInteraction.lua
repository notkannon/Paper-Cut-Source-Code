-- wrote by fucking Cannon :))
--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local WCS = require(ReplicatedStorage.Packages.WCS)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Variables

local Player = Players.LocalPlayer

local BaseInteraction = BaseComponent.CreateComponent("BaseInteraction", {
	isAbstract = true,
	
	defaults = {
		Cooldowned = false,
		FilteringType = "Exclude"
	},
	
	predicate = function(instance: ProximityPrompt?)
		return typeof(instance) == "Instance" and instance:IsA("ProximityPrompt")
	end,
	
}, SharedComponent) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: SharedComponent.MyImpl)),
	
	SetEnabled: (self: Component, value: boolean) -> (),
	
	CreateEvent: SharedComponent.CreateEvent<Component>,
	PlayerHasAccess: (self: Component, player: Player) -> boolean,
	
	GetFilteringType: (self: Component) -> "Include" | "Exclude",
	SetFilteringType: (self: Component, filteringType: "Include" | "Exclude") -> (),
	
	SetTeamAccessibility: (self: Component, team: Team|string, available: boolean?) -> (),
	SetRoleAccessibility: (self: Component, role: string, available: boolean?) -> (),
	SetPlayerAccessibility: (self: Component, player: Player, available: boolean?) -> (),
	
	OnDestroy: (self: Component) -> (),
	OnConstruct: (self: Component, options: SharedComponent.SharedComponentConstructOptions?) -> (),
	OnConstructClient: (self: Component) -> (),
	
	_InitClientAccess: (
		self: Component,
		initialPlayerAccessibility: {[Player]: boolean?}?,
		initialRoleAccessibility: {[string]: boolean?}?,
		initialTeamAccessibility: {[string]: boolean}?
	) -> (),
	
	_InitServerNetwork: (self: Component) -> (),
	_InitClientNetwork: (self: Component) -> (),
}

export type Fields = {
	Enabled: boolean,
	Instance: ProximityPrompt,
	ParentComponent: any?,
	ClientAccessChanged: Signal.Signal<boolean>,
	
	AllowedSkills: { [string]: boolean? },
	AllowedStatusEffects: { [string]: boolean? },
	
	Shown: Signal.Signal,
	Hidden: Signal.Signal,
	
	_ClientAccessed: boolean,
	_TeamAccessibility: { [string]: boolean? },
	_RoleAccessibility: { [string]: boolean? },
	_PlayerAccessibility: { [string]: boolean? },
	
	_AccessChangedEvent: SharedComponent.ServerToClient,
	_EnabledChangedEvent: SharedComponent.ServerToClient<boolean>,
	
} & SharedComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseInteraction", ProximityPrompt, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseInteraction", ProximityPrompt, {}>

--//Methods

function BaseInteraction.SetEnabled(self: Component, value: boolean)
	if self.Enabled == value then
		return
	end
	
	self.Enabled = value
	
	if RunService:IsServer() then
		self._EnabledChangedEvent.FireAll(value)
	end
end

function BaseInteraction.GetFilteringType(self: Component)
	return self.Attributes.FilteringType
end

function BaseInteraction.SetFilteringType(self: Component, filteringType: "Include" | "Exclude")
	assert(RunService:IsServer())
	assert(table.find({"Include", "Exclude"}, filteringType), `Wrong type passed ("Include" or "Exclude" expected, got { filteringType })`)
	
	if filteringType == self:GetFilteringType() then
		return
	end
	
	self.Attributes.FilteringType = filteringType
end

function BaseInteraction.SetTeamAccessibility(self: Component, team: string, available: boolean?)
	assert(RunService:IsServer(), "Attempted to call :SetPlayerAccessibility() on client")
	assert(typeof(available) == "nil" or typeof(available) == "boolean", "Wrong type for Available passed (boolean or nil expected)")
	
	if typeof(team) == "Instance" then
		assert(team:IsA("Team"), `Team instance argument expected, got { team }`)
		team = team.Name
	end
	
	assert(game:GetService("Teams"):FindFirstChild(team), `Team with name "{ team }" doesn't exist`)
	
	if self._TeamAccessibility[team] == available then
		return
	end

	self._TeamAccessibility[team] = available
	self._AccessChangedEvent.FireAll("Team", self._TeamAccessibility)
end

function BaseInteraction.SetPlayerAccessibility(self: Component, player: string, available: boolean?)
	assert(RunService:IsServer(), "Attempted to call :SetPlayerAccessibility() on client")
	assert(typeof(available) == "nil" or typeof(available) == "boolean", "Wrong type for Available passed (boolean or nil expected)")
	
	if typeof(player) == "Instance" then
		assert(player:IsA("Player"), `Player instance argument expected, got { player }`)
		player = player.Name
	end

	assert(Players:FindFirstChild(player), `Player with name "{ player }" doesn't exist`)
	
	if self._PlayerAccessibility[player] == available then
		return
	end
	
	self._PlayerAccessibility[player] = available
	self._AccessChangedEvent.FireAll("Player", self._PlayerAccessibility)
end

function BaseInteraction.SetRoleAccessibility(self: Component, role: string, available: boolean?)
	
	assert(RunService:IsServer(), "Attempted to call :SetRoleAccessibility() on client")
	assert(typeof(role) == "string", `Role name(string) argument expected, got { role }`)
	assert(typeof(available) == "nil" or typeof(available) == "boolean", "Wrong type for Available passed (boolean or nil expected)")
	
	if self._RoleAccessibility[role] == available then
		return
	end
	
	self._RoleAccessibility[role] = available
	self._AccessChangedEvent.FireAll("Role", self._RoleAccessibility)
end

function BaseInteraction.PlayerHasAccess(self: Component, player: Player)
	if not self.Enabled then
		return false
	end
	
	local PlayerComponent
	
	if RunService:IsServer() then
		assert(player and typeof(player) == "Instance" and player:IsA("Player"), "Provided non-Player type")
		
		PlayerComponent = ComponentsManager.Get(player, "PlayerComponent")
		player = player
		
		if not PlayerComponent then
			return false
		end
		
	elseif RunService:IsClient() then
		local PlayerController = Classes.GetSingleton("PlayerController")
		assert(PlayerController, "PlayerController doesn't exist")
		
		PlayerComponent = PlayerController
		player = Player
	end
	
	local function Compute(accessTable, key)
		if accessTable[key] == true then
			return self:GetFilteringType() == "Include"
			
		elseif accessTable[key] == false then
			return self:GetFilteringType() == "Exclude"
		end
		
		return nil
	end
	
	local CharacterComponent = PlayerComponent.CharacterComponent
	if not CharacterComponent then
		return false
	end
	
	-- Player (highest priority)
	local ComputedPlayerAccess = Compute(self._PlayerAccessibility, player.Name)
	
	if ComputedPlayerAccess ~= nil then
		return ComputedPlayerAccess
	end
	
	-- WCS related
	local WCSCharacter = CharacterComponent.WCSCharacter :: WCS.Character?
	
	if WCSCharacter then
		for _, Skill in ipairs(WCSCharacter:GetAllActiveSkills()) do
			if self.AllowedSkills[Skill:GetName()] == false then
				return false
			end
		end

		for _, StatusEffect in ipairs(WCSCharacter:GetAllActiveStatusEffects()) do
			if self.AllowedStatusEffects[StatusEffect.Name] == false then
				return false
			end
		end
	end
	
	-- Role
	local RoleString = PlayerComponent:GetRoleConfig().DisplayName
	local ComputedRoleAccess = Compute(self._RoleAccessibility, RoleString)
	
	if ComputedRoleAccess ~= nil then
		return ComputedRoleAccess
	end
	
	-- Team
	local ComputedTeamAccess = Compute(self._TeamAccessibility, player.Team.Name)

	if ComputedTeamAccess ~= nil then
		return ComputedTeamAccess
	end
	
	-- If player isn't excluded
	return self:GetFilteringType() == "Exclude"
end

function BaseInteraction.OnConstruct(self: Component, options: SharedComponent.SharedComponentConstructOptions?)
	SharedComponent.OnConstruct(self, options)
	
	self.Enabled = true
	self.AllowedSkills = {}
	self.AllowedStatusEffects = {
		
		Hidden = false,
		HiddenComing = false,
		HiddenLeaving = false,
		
		Downed = false,
		Stunned = false,
		Handled = false,
		HarpoonPierced = false,
		MarkedForDeath = false,
		ObjectiveSolving = false,
	}
	
	self._TeamAccessibility = {}
	self._RoleAccessibility = {}
	self._PlayerAccessibility = {}
	
	self._AccessChangedEvent = self:CreateEvent(
		"AccessChanged",
		"Reliable",
		
		function(arg) return typeof(arg) == "string" end,
		function(arg) return typeof(arg) == "table" end
	)
	
	self._EnabledChangedEvent = self:CreateEvent(
		"EnabledChanged",
		"Reliable",
		
		function(arg) return typeof(arg) == "boolean" end
	)
	
	self.Janitor:Add(Players.PlayerRemoving:Connect(function(playerRemoving: Player)
		self._PlayerAccessibility[playerRemoving] = nil
	end))
end

function BaseInteraction.OnConstructClient(self: Component)
	
	self.Shown = self.Janitor:Add(Signal.new())
	self.Hidden = self.Janitor:Add(Signal.new())
	self.ClientAccessChanged = self.Janitor:Add(Signal.new())
	
	self:_InitClientNetwork()
	
	self.Janitor:Add(self.ClientAccessChanged:Connect(function(hasAccess)
		--print('changing to', hasAccess)
		self.Instance.Enabled = hasAccess
	end))
	
	self.Janitor:Add(self.Instance.PromptShown:Connect(function()
		if not self:PlayerHasAccess() then
			return
		end
		
		self.Shown:Fire()
	end))

	self.Janitor:Add(self.Instance.PromptHidden:Connect(function()
		self.Hidden:Fire()
	end))
end

function BaseInteraction._InitClientAccess(self: Component,
	initialPlayerAccessibility: {[Player]: boolean?}?,
	initialRoleAccessibility: {[string]: boolean?}?,
	initialTeamAccessibility: {[Team]: boolean}?
)
	assert(RunService:IsClient(), "Attempted to call :_InitClientAccess() on server")

	for Player, Available in pairs(initialPlayerAccessibility) do
		self._PlayerAccessibility[Player] = Available
	end

	for Role, Available in pairs(initialRoleAccessibility) do
		self._RoleAccessibility[Role] = Available
	end
	
	for Team, Available in pairs(initialTeamAccessibility) do
		self._TeamAccessibility[Team] = Available
	end
end

function BaseInteraction._InitClientNetwork(self: Component)
	assert(RunService:IsClient(), "Called on server")
	
	local PlayerController = Classes.GetSingleton("PlayerController")
	assert(PlayerController, "PlayerController doesn't exist")
	
	local function HandleClientAccessChange()
		local HasAccess = self:PlayerHasAccess(Player)
		
		if self._ClientAccessed == HasAccess then
			return
		end
		
		self._ClientAccessed = HasAccess
		self.ClientAccessChanged:Fire(HasAccess)
		
		return HasAccess
	end
	
	self.Janitor:Add(PlayerController.RoleConfigChanged:Connect(HandleClientAccessChange))
	
	self.Janitor:Add(PlayerController.CharacterAdded:Connect(function(component)
		local WCSCharacter = component.WCSCharacter :: WCS.Character
		
		local Connections = {
			WCSCharacter.SkillEnded:Connect(HandleClientAccessChange),
			WCSCharacter.SkillStarted:Connect(HandleClientAccessChange),
			WCSCharacter.StatusEffectEnded:Connect(HandleClientAccessChange),
			WCSCharacter.StatusEffectStarted:Connect(HandleClientAccessChange),
		}
		
		for _, Connection: RBXScriptConnection in ipairs(Connections) do
			self.Janitor:Add(Connection)
		end
		
		self.Janitor:Add(PlayerController.CharacterRemoved:Once(function()
			for _, Connection: RBXScriptConnection in ipairs(Connections) do
				Connection:Disconnect()
			end
			
			table.clear(Connections)
		end))
		
		HandleClientAccessChange()
	end))
	
	self.Janitor:Add(self._EnabledChangedEvent.On(function(value)
		self:SetEnabled(value)
		HandleClientAccessChange()
	end))
	
	self.Janitor:Add(self._AccessChangedEvent.On(function(accessType: "Player" | "Role" | "Team", new: { [Player|string|Team]: boolean? }?)
		assert(table.find({"Player", "Role", "Team"}, accessType), `Client got unexpected AccessType: { accessType }`)
		self[`_{ accessType }Accessibility`] = new
		HandleClientAccessChange()
	end))
	
	HandleClientAccessChange()
end

function BaseInteraction.OnDestroy(self: Component)
	self.Janitor:Cleanup()
	
	SharedComponent.OnDestroy(self)
end

--//Returner

return BaseInteraction