--//Service

local Players = game:GetService("Players")
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local WCS = require(ReplicatedStorage.Packages.WCS)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Interaction = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsData = require(ReplicatedStorage.Shared.Data.ComponentsData)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

local HiddenStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Student.Hidden)
local HiddenComingStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Student.HiddenComing)
local HiddenLeavingStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Student.HiddenLeaving)
local HideoutPanickingStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Student.HideoutPanicking)

local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil
local HideoutCheckHandler = RunService:IsServer() and require(ServerScriptService.Server.Classes.HideoutCheckHandler) or nil

local ChaseReplicator = RunService:IsServer() and require(ServerScriptService.Server.Services.ChaseReplicator) or nil

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)

--//Variables

local BaseHideout = BaseComponent.CreateComponent("BaseHideout", {

	isAbstract = true,
	ancestorWhitelist = {workspace},

	defaults = {

		Locked = false,
		IncomerName = "",
		OccupantName = "",
	},

	predicate = function(instance: Model)
		return instance:HasTag("Hideout")
	end,

}, SharedComponent) :: Impl

--//Type

export type Attributes = {

	Locked: boolean,
	IncomerName: string,
	OccupantName: string,
	AttributeChanged: Signal.Signal<string, any>,
}

export type BaseHideoutModel = Model

export type Fields = {

	Instance: BaseHideoutModel,
	DefaultInstance: BaseHideoutModel,
	AnimationsSource: Folder?,

	Attributes: Attributes,
	Interaction: Interaction.Component,
	CooldownDuration: number,

	Animations: {
		-- student interactive
		StudentEnter: Animation,
		StudentLeave: Animation,
		StudentStatic: Animation,

		-- players check animations
		StudentFound: Animation,
		KillerFound: Animation,
		KillerNotFound: Animation,

		-- hideout instance check animations
		Found: Animation,
		NotFound: Animation,
	},

	_LastOccupantCharacter: Model?,
}

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: SharedComponent.MyImpl)),

	CreateEvent: SharedComponent.CreateEvent<Component>,

	GetOccupant: (self: Component) -> Player?,
	SetOccupant: (self: Component, occupant: Player?, any...) -> (),

	GetIncomer: (self: Component) -> Player?,
	TryEnterCover: (self: Component, player: Player) -> (),
	CancelEnterCover: (self: Component) -> (),

	OnConstruct: (self: Component) -> (),
	OnConstructServer: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, BaseHideoutModel, {}>
export type Component = BaseComponent.Component<MyImpl, Fields, string, BaseHideoutModel, {}> 

--//Methods

function BaseHideout.GetIncomer(self: Component)
	return Players:FindFirstChild(self.Attributes.IncomerName)
end

function BaseHideout.GetOccupant(self: Component)
	return Players:FindFirstChild(self.Attributes.OccupantName) 
end

function BaseHideout.SetOccupant(self: Component, occupant: Player?, ... : any)
	local Args = table.pack(...)
	local Forced: boolean? = Args[1]
	
	assert(RunService:IsServer())
	assert(not occupant or not self:GetOccupant(), "Occupant already set for hideout", self:GetName())
	
	--we're checking not for a player (he can leave the game), but filled attribute field
	if not occupant and self.Attributes.OccupantName then

		local CurrentOccupant = self:GetOccupant()

		--enabling hideout interaction
		self.Interaction:SetTeamAccessibility("Student", nil)
		self.Attributes.OccupantName = ""

		-- avoiding changing respawned player, removing current occupant
		if CurrentOccupant and self._LastOccupantCharacter == CurrentOccupant.Character then

			local WCSCharacter = WCS.Character.GetCharacterFromInstance(CurrentOccupant.Character)

			if not WCSCharacter then
				return
			end
			
			--panicking status handling
			local PanickingStatus = WCSUtility.GetAllActiveStatusEffectsFromString(WCSCharacter, "HideoutPanicking")[1] :: HideoutPanickingStatus.Status?

			--removing player from hideout
			WCSUtility.EndAllStatusEffectsOfType(WCSCharacter, HiddenStatus)
			
			if PanickingStatus then
				
				PanickingStatus.ShouldLeaveOnEnd = false
				PanickingStatus:Destroy()
			end
			
			local _TimeElapsed = os.clock() - self._StartTimestamp
			print(_TimeElapsed, self._WasTROnEnter, ChaseReplicator:GetTerrorRadiusFromPlayer(WCSCharacter.Player))
			if _TimeElapsed >= 10 and self._WasTROnEnter and ChaseReplicator:GetTerrorRadiusFromPlayer(WCSCharacter.Player).CurrentLayer == 0 then
				print(WCSCharacter.Player)
				ProxyService:AddProxy("LockerHidingSuccessful"):Fire(WCSCharacter.Player)
			end
			
			self.Interaction:SetEnabled(false)
			
			--applying leaving status
			local ActiveHiddenLeavingStatus = self.Janitor:Add(HiddenLeavingStatus.new(WCSCharacter, self.Instance, ...))
			ActiveHiddenLeavingStatus:Start()
			ActiveHiddenLeavingStatus.Janitor:Add(function()
				
				--enabling interaction
				self.Interaction:SetEnabled(true)
				self.Interaction:ApplyCooldown(self.CooldownDuration)
			end)
		end

	elseif occupant then

		local WCSCharacter = WCS.Character.GetCharacterFromInstance(occupant.Character)

		--disabling hideout interaction for all Students
		self.Interaction:SetTeamAccessibility("Student", true)
		
		--listening to active hidden status
		local ActiveHiddenStatus = self.Janitor:Add(HiddenStatus.new(WCSCharacter, self.Instance)) :: WCS.StatusEffect
		ActiveHiddenStatus:Start()
		ActiveHiddenStatus.Janitor:Add(function()
			
			--removing forcely
			self:SetOccupant(nil, true)
		end)
		
		local HideoutPanickingDuration = ComponentsData.Hideouts.Shared.PanickingAccumulationLength
		
		local RoleConfig = RolesManager:GetPlayerRoleConfig(occupant)
		local DurationMultiplier = RoleConfig.CharacterData.UniqueProperties and RoleConfig.CharacterData.UniqueProperties.LockerTimeMultiplier or 1
		HideoutPanickingDuration *= DurationMultiplier
		--print(`Hiding for {HideoutPanickingDuration} seconds`)
		
		--applying panicking status
		self.Janitor:Add(HideoutPanickingStatus.new(WCSCharacter))
			:Start(HideoutPanickingDuration)

		self._LastOccupantCharacter = occupant.Character
		self.Attributes.OccupantName = occupant.Name
	end
end

--an attempt to hide player. Animation playback + listening for his state
function BaseHideout.TryEnterCover(self: Component, player: Player)

	--no player's character
	if not player.Character then
		return
	end

	local WCSCharacter = WCS.Character.GetCharacterFromInstance(player.Character)

	--someone already trying to enter or entered this hideout
	if not WCSCharacter
		or self:GetIncomer()
		or self:GetOccupant() then

		return
	end
	
	--providing instance cuz player shall know the exact plahe he hidden in
	local ActiveHiddenComingStatus = self.Janitor:Add(HiddenComingStatus.new(WCSCharacter, self.Instance), "Destroy", "IncomerStatus") :: WCS.StatusEffect
	ActiveHiddenComingStatus:Start()
	ActiveHiddenComingStatus.Janitor:Add(function()
		
		--we can remove this status and player will cancel entering
		self:CancelEnterCover()
	end)
	
	self.Interaction:SetEnabled(false) -- disabling interaction for everyone
	self.Attributes.IncomerName = player.Name

	--damage listener
	self.Janitor:Add(WCSCharacter.DamageTaken:Connect(function()
		self:CancelEnterCover()
	end), "Disconnect", "IncomerDamageListener")

	--death listener
	self.Janitor:Add(WCSCharacter.Humanoid.Died:Once(function()
		self:CancelEnterCover()
	end), "Disconnect", "IncomerDeathListener")

	--despawn/leave/destroy listener
	self.Janitor:Add(WCSCharacter.Destroyed:Once(function()
		self:CancelEnterCover()
	end), "Disconnect", "IncomerForceListener")

	--visuals
	
	--hideout rig animation
	self.Janitor:Add(
		AnimationUtility.QuickPlay(
			self.Instance.AnimationController,
			self.AnimationsSource.Enter
		), "Stop", "EnterAnimationTrack"
	)
	
	--player entering animation
	local ActualTrack = ActiveHiddenComingStatus.Janitor:Get("AnimationTrack") :: AnimationTrack
	local Duration = AnimationUtility.PromiseDuration(ActualTrack, 2, true):expect()
	
	--after this time player becomes "Hidden"
	self.Janitor:Add(task.delay(Duration, function()
		
		-- for point scoring
		self._WasTROnEnter = ChaseReplicator:GetTerrorRadiusFromPlayer(player).CurrentLayer > 0
		self._StartTimestamp = os.clock()
		
		self:CancelEnterCover() -- first cancelling enter stuff
		self:SetOccupant(player) -- then player will forcely moved inside hideout
		
	end), nil, "OccupantSetTask")
end

--[[ called if player who was trying to hide, but not hidden:

a) was damaged
b) left the game
c) died (near to a)

]]
function BaseHideout.CancelEnterCover(self: Component)

	--no player to cancel entry
	if not self:GetIncomer() then
		return
	end
	
	local Player = self:GetIncomer()
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(Player.Character)
	
	self.Interaction:SetEnabled(true)
	self.Interaction:ApplyCooldown(self.CooldownDuration)
	self.Attributes.IncomerName = ""
	
	--removing entering stuff from janitor
	self.Janitor:RemoveList(
		"IncomerStatus",
		"OccupantSetTask",
		"IncomerDamageListener",
		"IncomerDeathListener",
		"IncomerForceListener",
		"EnterAnimationTrack"
	)
end

function BaseHideout.OnConstruct(self: Component) 
	SharedComponent.OnConstruct(self)

	self.Animations = {}
	self.CooldownDuration = 2.5

	--self.Interaction = ComponentsManager.Await(self.Instance:FindFirstChild("Root"):FindFirstChild("InteractionOrigin"):FindFirstChild("Interaction"), Interaction):timeout(25):expect()
	self.Interaction = self.Janitor:AddPromise(ComponentsManager.Await(self.Instance:FindFirstChild("Root"):FindFirstChild("InteractionOrigin"):FindFirstChild("Interaction"), Interaction)):timeout(15):expect()
	self.DefaultInstance = ReplicatedStorage.Assets.Doors:FindFirstChild(self.Instance.Name)

	self.Attributes.Locked = false
	self.Attributes.OccupantName = ""

	--restricted statuses
	self.Interaction.AllowedStatusEffects.HideoutLimited = false
end

function BaseHideout.OnConstructServer(self: Component)

	self.Interaction:SetFilteringType("Exclude")
	self.Interaction.Instance.HoldDuration = 0
	self.Interaction.Instance.RequiresLineOfSight = true

	--used to detect any obstacles on path between player and hideout
	local AccessibilityParams = RaycastParams.new()
	AccessibilityParams.FilterDescendantsInstances = { workspace.Characters, workspace.Temp, self.Instance }
	AccessibilityParams.FilterType = Enum.RaycastFilterType.Exclude
	AccessibilityParams.RespectCanCollide = true
	
	--interaction handling
	self.Janitor:Add(self.Interaction.Started:Connect(function(player)
		
		--temporary ignores any interactions
		--if true then
			
		--	if RunService:IsStudio() then
		--		warn("Locker interactions was temporary paused until we get new animations for Students rigs")
		--	end
			
		--	return
		--end

		local PlayerPos = player.Character.PrimaryPart.Position
		local HideoutPos = self.Instance.PrimaryPart.Position
		local Sub = (HideoutPos - PlayerPos) :: Vector3

		--obstacle check
		if workspace:Raycast(PlayerPos, Sub, AccessibilityParams) ~= nil then
			return
		end

		local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(player)

		--role handling
		if PlayerComponent:IsKiller() then

			if not HideoutCheckHandler.GetObjectFromSeeker(player)
				and not HideoutCheckHandler.GetObjectFromHiding(self:GetOccupant()) then

				--creating new locked check handler to make a cutscene with killer and Student
				self.Janitor:Add(HideoutCheckHandler.new(player, self:GetOccupant(), self.Instance))
			end

		elseif PlayerComponent:IsStudent() and not self:GetOccupant() then

			--we're hiding a player who interacted
			self:TryEnterCover(player)
			
			self.Interaction:ApplyCooldown(self.CooldownDuration)
		end
	end))
	
	--hideout `leave` handling
	self.Janitor:Add(ServerRemotes.HideoutLeavePrompt.On(function(player: Player)
		
		local WCSCharacter = WCS.Character.GetCharacterFromInstance(player.Character)
		
		--filtering other players
		if not WCSCharacter
			or self.Interaction:IsCooldowned()
			or not WCSUtility.HasActiveStatusEffectsWithNames(WCSCharacter, { "Hidden", "HiddenComing" }) then
			
			return
		end
		
		if self:GetOccupant() == player then
			
			--removing occupant
			self:SetOccupant(nil)
			
		elseif self:GetIncomer() == player then
			
			--player cancelled entering the hideout
			self:CancelEnterCover()
		end
	end))
end

function BaseHideout.OnConstructClient(self: Component)
	
	--interaction things
	
	local PlayerController = Classes.GetSingleton("PlayerController")

	--interaction text changing
	local function OnRoleConfigChanged()
		self.Interaction.Instance.ObjectText = ""
		self.Interaction.Instance.ActionText = `{ PlayerController:IsKiller() and "check" or "hide" }`
	end

	OnRoleConfigChanged()

	self.Janitor:Add(PlayerController.RoleConfigChanged:Connect(OnRoleConfigChanged))
end

function BaseHideout.OnDestroy(self: Component)

	local CurrentIncomer = self:GetIncomer()
	local CurrentOccupant = self:GetOccupant()
	local Someone = CurrentIncomer or CurrentOccupant

	if not Someone then
		return
	end

	--removing player's hiding status when component being destroyed
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(Someone.Character)
	
	if CurrentOccupant then
		
		--handling force leave
		self:SetOccupant(nil, true)
		
	elseif CurrentIncomer then
		
		self:CancelEnterCover()
	end
end

--//Returner

return BaseHideout