--//Service

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local WCS = require(ReplicatedStorage.Packages.WCS)

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ComponentReplicator = require(ReplicatedStorage.Shared.Services.ComponentReplicator)
local InteractionComponent = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)

local ObjectiveSolvingStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Student.ObjectiveSolving)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil

--//Variables

local LocalPlayer = Players.LocalPlayer
local BaseObjective = BaseComponent.CreateComponent("BaseObjective", { isAbstract = true, }, SharedComponent) :: Impl

--//Types

export type ObjectiveCompletionState = "Success" | "Failed" | "Cancelled"

type ObjectiveState = {
	Players: { Player? },
}

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: SharedComponent.MyImpl)),

	CreateEvent: SharedComponent.CreateEvent<Component>,
	
	PromptComplete: (self: Component, status: ObjectiveCompletionState, userData: { any }?) -> (),
	OnCompleteCallback: (self: Component, player: Player, status: ObjectiveCompletionState, userData: { any }?) -> (),
	
	HasPlayer: (self: Component, player: Player) -> boolean,
	RemoveAll: (self: Component) -> (),
	AddPlayer: (self: Component, player: Player) -> (),
	RemovePlayer: (self: Component, player: Player) -> (),
	IsProcessing: (self: Component) -> boolean,
	
	HandleSubObjectiveCompletion: (self: Component, subObjective: Component, state: ObjectiveState) -> (),
	RegisterSubObjective: (self: Component, subObjective: Component) -> Component,
	
	OnConstruct: (self: Component, options: SharedComponent.SharedComponentConstructOptions?) -> (),
	OnConstructServer: (self: Component) -> (),
}

export type Fields = {
	
	Interaction: InteractionComponent.Component,
	DestroyOnComplete: boolean,
	DestroyDelay: number?,
	
	Changed: Signal.Signal<ObjectiveState>,
	Completed: Signal.Signal<Player, ObjectiveCompletionState>,
	
	_Players: { Player? },
	_InternalClientCallback: SharedComponent.ClientToServer<ObjectiveCompletionState>,
	
	SubObjectives: {Component},
	ParentObjective: Component?,
	
	IsSoloObjective: boolean?,
	Cooldown: number?
} & SharedComponent.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BaseObjective", Instance, any...>
export type Component = BaseComponent.Component<MyImpl, Fields, "BaseObjective", Instance, any...>

--//Methods

--we can override this thing to validate/modify completion pipeline
function BaseObjective.OnCompleteCallback(self: Component, player: Player, status: ObjectiveCompletionState, ...: any?)
	
	if status == "Cancelled" then

		self:RemovePlayer(player)

	else

		self.Completed:Fire(player, status)
		self:RemoveAll()
	end
	
	if status ~= "Success" and self.Cooldown then
		self.Interaction:SetPlayerAccessibility(player, false)

		self.Janitor:Add(task.delay(self.Cooldown, function()
			self.Interaction:SetPlayerAccessibility(player, nil)
		end))
	end

end

-- @override
function BaseObjective.HandleSubObjectiveCompletion(self: Component, subObjective: Component, player: Player, state: ObjectiveState)
	
end

function BaseObjective.RegisterSubObjective(self: Component, SubObjective: Component)
	self.Janitor:Add(SubObjective)
	SubObjective.ParentObjective = self
	
	SubObjective.Janitor:Add(SubObjective.Completed:Connect(function(player: Player, state: ObjectiveState)
		self:HandleSubObjectiveCompletion(SubObjective, player, state)
	end))
	
	table.insert(self.SubObjectives, SubObjective)
	return SubObjective
end

function BaseObjective.PromptComplete(self: Component, status: ObjectiveCompletionState, userData: { any }?)
	assert(RunService:IsClient(), "Client only method")
	
	--can't call it twice
	if self:IsDestroying() then
		return
	end
	
	--also providing UserData that probably will be handled by extensions
	self._InternalClientCallback.Fire(status or "Cancelled", userData)
	self.Completed:Fire(LocalPlayer, status or "Cancelled", userData)
end

function BaseObjective.IsProcessing(self: Component)
	return #self._Players > 0
end

function BaseObjective.HasPlayer(self: Component, player: Player)
	return table.find(self._Players, player) ~= nil
end

function BaseObjective.AddPlayer(self: Component, player: Player)
	assert(RunService:IsServer())
	
	--getting player's character component
	local CharacterComponent = ComponentsUtility.GetComponentFromCharacter(player.Character)
	
	--validation
	if self:HasPlayer(player)
		or not CharacterComponent then
		
		return
	end
	
	--applying status effect
	CharacterComponent.Janitor:Add(
		
		ObjectiveSolvingStatus.new(
			CharacterComponent.WCSCharacter
		),
		
		"Destroy",
		"ObjectiveSolvingStatus"
		
	):Start()
	
	--replication
	--ComponentReplicator:PromptCreate(self, { player }, {Started = true})
	
	--removing access
	self.Interaction:SetPlayerAccessibility(player, false)
	
	table.insert(self._Players, player)
	
	self.Changed:Fire({
		Players = self._Players
	})
end

function BaseObjective.RemoveAll(self: Component)
	assert(RunService:IsServer())
	
	for _, Member in ipairs(self._Players) do
		
		self:RemovePlayer(Member)
	end
	
	table.clear(self._Players)
end

function BaseObjective.RemovePlayer(self: Component, player: Player)
	assert(RunService:IsServer())
	
	--is exist?
	if not self:HasPlayer(player) then
		return
	end
	
	local CharacterComponent = ComponentsUtility.GetComponentFromCharacter(player.Character)
	
	--status removal
	if CharacterComponent then
		CharacterComponent.Janitor:Remove("ObjectiveSolvingStatus")
	end
	
	--replication
	--ComponentReplicator:PromptDestroy(self, { player })
	
	--access

	table.remove(self._Players,
		table.find(self._Players, player)
	)

	self.Changed:Fire({
		Players = self._Players
	})
	
	pcall(function() self.Interaction:SetPlayerAccessibility(player, nil) end) -- this line might fail if player left the game so pcall
end

function BaseObjective.OnConstruct(self: Component, options: SharedComponent.SharedComponentConstructOptions?, ...: any)
	SharedComponent.OnConstruct(self, options)
	
	self._Players = {}
	self.DestroyOnComplete = true
	
	self.Changed = self.Janitor:Add(Signal.new())
	self.Completed = self.Janitor:Add(Signal.new())
	
	self.ParentObjective = nil
	self.SubObjectives = {}
	
	--event registery
	self._InternalClientCallback = self:CreateEvent(
		"InternalClientCallback",
		"Reliable",
		
		function(...) return table.find({"Success", "Failed", "Cancelled"}, ...) ~= nil end,
		function() return true end
	)
	
	--awaiting interaction component
	self.Interaction = self.Janitor:Add(self.Janitor:AddPromise(
		
		ComponentsManager.Await(
			
			self.Instance:FindFirstChildWhichIsA("ProximityPrompt"),
			InteractionComponent
		)
	):expect(), "Destroy")
end

function BaseObjective.OnConstructServer(self: Component)
	
	local MatchService = Classes.GetSingleton("MatchService")
	local ObjectivesService = Classes.GetSingleton("ObjectivesService")
	
	--inverse registery
	ObjectivesService:AddObjective(self)
	
	--interaction access (Students only by default)
	self.Interaction:SetFilteringType("Include")
	self.Interaction:SetTeamAccessibility("Student", true)
	
	--interaction removal
	self.Janitor:Add(function()

		if not self.Interaction
			or self.Interaction:IsDestroyed() then

			return
		end

		self.Interaction:Destroy()
		self.Interaction = nil
	end)
	
	--remove if despawned
	self.Janitor:Add(WCS.Character.CharacterDestroyed:Connect(function(wcsCharacter)
		
		--safe thing
		if not wcsCharacter.Player then
			return
		end
		
		self:RemovePlayer(wcsCharacter.Player)
	end))
	
	--remove player on any damage
	self.Janitor:Add(MatchService.PlayerDamaged:Connect(function(player)
		self:RemovePlayer(player)
	end))
	
	--player removal on death
	self.Janitor:Add(MatchService.PlayerDied:Connect(function(player)
		self:RemovePlayer(player)
	end))
	
	self.Janitor:Add(self._InternalClientCallback.On(function(player, ...)
		
		--is player valid member of this objective.
		if not self:HasPlayer(player)
			or self:IsDestroying()
			or self:IsDestroyed() then
			
			return
		end
		
		--handling completion
		self:OnCompleteCallback(player, ...)
	end))
	
	if self.IsSoloObjective then
		self.Janitor:Add(self.Changed:Connect(function(state: ObjectiveState)
			if not self.Interaction:IsDestroying() and not self.Interaction:IsDestroyed() then
				self.Interaction:SetEnabled(not self:IsProcessing())
			end
		end))
	end
end

function BaseObjective.OnDestroy(self: Component)
	
	--server only thing
	if not RunService:IsServer() then
		return
	end
	
	--destroying component for all players
	ComponentReplicator:PromptDestroy(self, self._Players)
end

--//Returner

return BaseObjective