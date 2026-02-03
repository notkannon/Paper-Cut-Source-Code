--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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

local PlayerService = RunService:IsServer() and require(ServerScriptService.Server.Services.PlayerService) or nil
local ClientRemotes = RunService:IsClient() and require(ReplicatedStorage.Client.ClientRemotes) or nil
local MatchStateClient = RunService:IsClient() and require(ReplicatedStorage.Client.Controllers.MatchStateClient) or nil

--//Variables

local RoleSelection = BaseComponent.CreateComponent("RoleSelection", {
	isAbstract = false,
}, SharedComponent) :: Impl

--//Types

type RoleChoiceOptions = {
	MaxPlayers: number,
	ThumbnailKey: string,
}

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: SharedComponent.MyImpl)),

	CreateEvent: SharedComponent.CreateEvent<Component>,
	
	End: (self: Component) -> (),
	Start: (self: Component, duration: number?) -> (),
	PromptSelect: (self: Component, role: string) -> (),
	SetSelection: (self: Component, player: Player, role: string?) -> (),
	GetRolesResolved: (self: Component) -> { [string]: Player },
	IsRoleSelectable: (self: Component, role: string) -> boolean,
	GetRoleFromPlayer: (self: Component, player: Player) -> string?,
	GetPlayersFromRole: (self: Component, role: string) -> { Player? },
	RemoveSelectionFromPlayer: (self: Component, player: Player) -> (),
	
	OnConstruct: (self: Component) -> (),
	OnConstructClient: (self: Component, roles: { string }) -> (),
	OnConstructServer: (self: Component, players: { Player }, roles: { string }) -> (),
}

export type Fields = {
	
	CustomTitle: string,
	Active: boolean,
	Roles: { [string]: RoleChoiceOptions },
	Players: { Player },
	VotesData: { [string]: {Player?} },
	Duration: number?,
	
	Completed: Signal.Signal<{ [Player]: string }>,
	
	SelectionChanged: SharedComponent.ServerToClient<{ [string]: {Player?} }>,
	SelectionCallback: SharedComponent.ClientToServer<string>,
	
} & SharedComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "RoleSelection", ReplicatedStorage, { Player }, { [string]: RoleChoiceOptions }, string?>
export type Component = BaseComponent.Component<MyImpl, Fields, "RoleSelection", ReplicatedStorage, { Player }, { [string]: RoleChoiceOptions }, string?>

--//Methods

function RoleSelection.IsRoleSelectable(self: Component, role: string)
	return #self.VotesData[role] < self.Roles[role].MaxPlayers
end

function RoleSelection.GetPlayersFromRole(self: Component, role: string)
	
	local Players = {}
	
	for Role, RolePlayers in pairs(self.VotesData) do
		
		if Role ~= role then
			continue
		end
		
		for _, Player in ipairs(RolePlayers) do
			table.insert(Players, Player)
		end
	end
	
	return Players
end

function RoleSelection.GetRoleFromPlayer(self: Component, player: Player)
	for Role, RolePlayers in pairs(self.VotesData) do
		if table.find(RolePlayers, player) then
			return Role
		end
	end
end

function RoleSelection.SetSelection(self: Component, player: Player, role: string?)
	assert(RunService:IsServer())
	
	local SelectedRole = self:GetRoleFromPlayer(player)
	
	--check if already set same role
	if SelectedRole == role then
		return
	end
	
	if SelectedRole then

		--removing player selection
		table.remove(self.VotesData[SelectedRole],
			table.find(self.VotesData[SelectedRole], player)
		)
	end
	
	--assign role to a player
	if role then
		table.insert(self.VotesData[role], player)
	end
	
	--pause replication when inactive
	if not self.Active then
		return
	end
	
	--replication
	self.SelectionChanged.FireList(self.Players, self.VotesData)
end

function RoleSelection.Start(self: Component, duration: number?)
	assert(RunService:IsServer())
	assert(not self.Active)
	
	if duration then
		self.Janitor:Add(
			task.delay(duration, self.End, self)
		)
	end
	
	self.Active = true
	
	--creating component on client
	ComponentReplicator:PromptCreate(self, self.Players, self.Roles, duration, self.CustomTitle)
end

function RoleSelection.End(self: Component)
	assert(RunService:IsServer())
	
	if not self.Active then
		return
	end
	
	self.Active = false
	
	--destroying component on client
	ComponentReplicator:PromptDestroy(self, self.Players)
	
	-- собрать незанятых игроков
	local unassignedPlayers = {}

	for _, player in ipairs(self.Players) do
		if not self:GetRoleFromPlayer(player) then
			table.insert(unassignedPlayers, player)
		end
	end

	-- собрать свободные слоты
	local availableSlots = {} -- { [role] = свободные_слоты }

	for role, info in pairs(self.Roles) do
		
		local taken = #self.VotesData[role]
		local free = info.MaxPlayers - taken
		
		if free > 0 then
			availableSlots[role] = free
		end
	end

	-- распределение случайно
	while #unassignedPlayers > 0 and next(availableSlots) do
		
		local playerIndex = math.random(1, #unassignedPlayers)
		local player = table.remove(unassignedPlayers, playerIndex)

		local rolesList = TableKit.Keys(availableSlots)
		local chosenRole = rolesList[math.random(1, #rolesList)]

		self:SetSelection(player, chosenRole)
		
		availableSlots[chosenRole] -= 1

		if availableSlots[chosenRole] <= 0 then
			availableSlots[chosenRole] = nil
		end
	end
	
	self.Completed:Fire(self.VotesData)
end

function RoleSelection.GetRolesResolved(self: Component)
	return table.clone(self.VotesData)
end

function RoleSelection.PromptSelect(self: Component, choice: string)
	assert(RunService:IsClient())
	
	self.SelectionCallback.Fire(choice)
end

function RoleSelection.OnConstruct(self: Component)
	SharedComponent.OnConstruct(self)

	self.SelectionChanged = self:CreateEvent(
		"SelectionChanged",
		"Reliable",
		
		function(...) return typeof(...) == "table" end
	)
	
	--used by client to send server info about selected role
	self.SelectionCallback = self:CreateEvent(
		"SelectionCallback",
		"Reliable",
		
		function(...) return typeof(...) == "string" end
	)
end

function RoleSelection.OnConstructClient(self: Component, roles: { RoleChoiceOptions }, duration: number?, Title: string?)
	self.Roles = roles
	self.Duration = duration
	self.CustomTitle = Title and string.upper(Title) or "CHOOSE YOUR ROLE"
end

function RoleSelection.OnConstructServer(self: Component, players: { Player }, roles: { RoleChoiceOptions }, CustomTitle: string?)
	
	self.CustomTitle = CustomTitle
	self.Active = false
	self.Roles = roles
	self.Players = players
	self.VotesData = {}
	self.Completed = self.Janitor:Add(Signal.new())
	
	for Role, RoleData in pairs(roles) do
		if not RoleData.ThumnailKey then
			RoleData.ThumnailKey = ""
		end
		
		self.VotesData[Role] = {}
	end
	
	--case when player left during selection
	self.Janitor:Add(Players.PlayerRemoving:Connect(function(player)
		
		if not table.find(self.Players, player) then
			return
		end
		
		local RoleSelected = self:GetRoleFromPlayer(player)
		
		if not RoleSelected then
			return
		end
		
		self:SetSelection(player, nil)
	end))
	
	self.Janitor:Add(self.SelectionCallback.On(function(player, role)
		
		--if player already has role or role was claimed by someone
		if self:GetRoleFromPlayer(player) == role
			or not self:IsRoleSelectable(role) then
			
			return
		end

		self:SetSelection(player, role)
	end))
end

function RoleSelection.OnDestroy(self: Component)
	
	if not RunService:IsServer() then
		return
	end
	
	ComponentReplicator:PromptDestroy(self, self.Players)
end

--//Returner

return RoleSelection