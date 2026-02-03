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
local ComponentTypes = require(ServerScriptService.Server.Types.ComponentTypes)
local BaseDestroyable = require(ReplicatedStorage.Shared.Classes.Abstract.BaseDestroyable)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local HandledStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Handled)
local HideoutLimitedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Student.HideoutLimited)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local MatchService = require(ServerScriptService.Server.Services.MatchService)
local PlayerService = require(ServerScriptService.Server.Services.PlayerService)

local ProxyService = require(ReplicatedStorage.Shared.Services.ProxyService)

--//Variables

local HandlerObjects = {} :: { Handler? }
local HideoutCheckHandler = BaseDestroyable.CreateClass("HideoutCheckHandler") :: MyImpl

--//Type

export type Fields = {
	
	IsRunning: boolean,

	PlayerSeek: ComponentTypes.PlayerComponent?,
	PlayerHiding: ComponentTypes.PlayerComponent?,
	HideoutInstance: Instance,
	
} & BaseDestroyable.Fields

export type MyImpl = {
	__index: typeof( setmetatable({} :: MyImpl, {} :: BaseDestroyable.MyImpl) ),

	new: (playerSeek: Player, playerHiding: Player, hideoutInstance: Instance) -> Handler,
	Run: (self: Handler) -> (),
	Destroy: (self: Handler) -> (),
	
	_InitConnections: (self: Handler) -> (),
}

export type Handler = typeof(setmetatable({} :: Fields, {} :: MyImpl))

--//Functions

local function GetObjectFromHiding(hiding: Player): Handler?
	for _, Handler in ipairs(HandlerObjects) do
		if Handler.PlayerHiding == hiding then
			return Handler
		end
	end
end

local function GetObjectFromSeeker(seeker: Player): Handler?
	for _, Handler in ipairs(HandlerObjects) do
		if Handler.PlayerSeek == seeker then
			return Handler
		end
	end
end

local function GetObjectFromHideout(hideout: Instance | unknown): Handler?
	
	hideout = typeof(hideout == "Instance") and hideout or hideout.Instance
	
	for _, Handler in ipairs(HandlerObjects) do
		if Handler.HideoutInstance == hideout then
			return Handler
		end
	end
end

--//Methods

function HideoutCheckHandler._InitConnections(self: Handler)
	
	--listening to unexpected cases to forcely stop this cutscene
	
	--death listening
	self.Janitor:Add(MatchService.PlayerDied:Connect(function(player)
		
		if player == self.PlayerSeek
			or player == self.PlayerHiding then

			self:Destroy()
		end
	end))
	
	--character removal listening (also player leaving)
	self.Janitor:Add(PlayerService.CharacterRemoved:Connect(function(_, player)
		
		if player == self.PlayerSeek
			or player == self.PlayerHiding then

			self:Destroy()
		end
	end))
	
	--detecting round ended thing
	self.Janitor:Add(MatchService.MatchEnded:Once(function(round)
		self:Destroy()
	end))
end

function HideoutCheckHandler.Run(self: Handler)
	
	if self.IsRunning then
		return
	end

	self.IsRunning = true
	
	local SeekerComponent = self.PlayerSeek
	local HidingComponent = self.PlayerHiding
	local SeekerCharacter = SeekerComponent.CharacterComponent
	
	--getting hideout component reference
	local Hideout = ComponentsManager.GetFirstComponentInstanceOf(self.HideoutInstance, "BaseHideout")
	local SeekerHideoutAnimations = Hideout.AnimationsSource[ RolesManager:GetPlayerRoleConfig(SeekerComponent.Instance).CharacterName ]
	local HideoutAnimationController = Hideout.Instance:FindFirstChildWhichIsA("AnimationController") :: AnimationController
	
	Hideout.Interaction:SetEnabled(false)

	self.Janitor:Add(HandledStatus.new(SeekerCharacter.WCSCharacter))
	self.Janitor:Add(function()
		
		Hideout.Interaction:SetEnabled(true)

		if SeekerCharacter.Instance then
			SeekerCharacter.HumanoidRootPart.Anchored = false
		end
	end)

	SeekerCharacter.HumanoidRootPart.Anchored = true
	SeekerCharacter.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	SeekerCharacter.Instance:PivotTo(Hideout.Instance.Root.KillerOrigin.WorldCFrame)

	-- check ways
	if not HidingComponent then

		-- single check

		--TODO // SFX playback //

		self.Janitor:Add(
			AnimationUtility.QuickPlay(
				HideoutAnimationController,
				SeekerHideoutAnimations.NotFound,
				{
					Looped = false,
					Priority = Enum.AnimationPriority.Action4,
				}
			), "Stop"
		)
		
		local Track = self.Janitor:Add(
			AnimationUtility.QuickPlay(
				SeekerCharacter.Humanoid,
				SeekerHideoutAnimations.KillerNotFound,
				{
					Looped = false,
					Priority = Enum.AnimationPriority.Action4,
				}
			), "Stop"
		)
		
		Hideout.Interaction:ApplyCooldown(4)
		
		self.Janitor:AddPromise(AnimationUtility.PromiseDuration(Track, 4, true):andThen(function(d)
			Hideout.Interaction:ApplyCooldown(d)

			--using threads to destroy handler
			self.Janitor:Add(
				task.delay(
					d, 
					self.Destroy, self
				)
			)
		end))

		
	else

		-- pair check
		
		ProxyService:AddProxy("StudentPulledOutOfLocker"):Fire(SeekerComponent.Instance, HidingComponent.Instance)

		local HidingCharacter = HidingComponent.CharacterComponent
		
		--forcely removing player as occupant
		Hideout:SetOccupant(nil, true)
		
		--posing Student out of hideout
		HidingCharacter.Instance.HumanoidRootPart.Anchored = true
		HidingCharacter.Instance.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
		HidingCharacter.Instance:PivotTo(Hideout.Instance.Root.StudentOriginKick.WorldCFrame)
		
		--Umm.. TODO: we shall move this number in another place (limiting victim after seek)
		self.Janitor:Add(function()
			
			if HidingCharacter.Instance then
				HidingCharacter.HumanoidRootPart.Anchored = false
				
				local HideoutLimitedDuration = 30
				local RoleConfig = RolesManager:GetPlayerRoleConfig(HidingComponent.Instance)
				local DurationMultiplier = RoleConfig and RoleConfig.CharacterData.UniqueProperties and RoleConfig.CharacterData.UniqueProperties.PanickedDurationMultiplier or 1
				HideoutLimitedDuration *= DurationMultiplier
				
				
				HideoutLimitedStatus.new(HidingCharacter.WCSCharacter):Start(HideoutLimitedDuration)
			end
		end)

		-- forcely removing hidden status effect
		--WCSUtility.RemoveStatusEffectsWithNames(HidingCharacter.WCSCharacter, {
		--	"HiddenLeaving",
		--	"HiddenComing",
		--	"Hidden",
		--}, "Destroy", "All")
		
		self.Janitor:Add(HandledStatus.new(HidingCharacter.WCSCharacter))

		self.Janitor:Add(
			AnimationUtility.QuickPlay(
				HideoutAnimationController,
				SeekerHideoutAnimations.Found,
				{
					Looped = false,
					Priority = Enum.AnimationPriority.Action4,
				}
			), "Stop"
		)

		self.Janitor:Add(
			AnimationUtility.QuickPlay(
				SeekerCharacter.Humanoid,
				SeekerHideoutAnimations.KillerFound,
				{
					Looped = false,
					Priority = Enum.AnimationPriority.Action4,
				}
			), "Stop"
		)
		
		local Track = self.Janitor:Add(
			AnimationUtility.QuickPlay(
				HidingCharacter.Humanoid, 
				SeekerHideoutAnimations.StudentFound, 
				{
					Looped = false,
					Priority = Enum.AnimationPriority.Action4,
				}
			), "Stop"
		)

		HidingCharacter.Appearance:ApplyTransparency(0)
		
		Hideout.Interaction:ApplyCooldown(4)

		self.Janitor:AddPromise(AnimationUtility.PromiseDuration(Track, 4, true):andThen(function(d)
			Hideout.Interaction:ApplyCooldown(d)

			--using threads to destroy handler
			self.Janitor:Add(
				task.delay(
					d, 
					self.Destroy, self
				)
			)
		end))
	end
end

function HideoutCheckHandler.OnConstructServer(self: Handler, playerSeek: Player, playerHiding: Player, hideoutInstance: Instance)
	
	--gc related
	table.insert(HandlerObjects, self)
	
	--removal on destroy
	self.Janitor:Add(function()
		
		table.remove(HandlerObjects,
			table.find(HandlerObjects, self)
		)
	end)
	
	self.IsRunning = false

	local SeekerComponent = ComponentsManager.Get(playerSeek, "PlayerComponent") :: ComponentTypes.PlayerComponent?
	local HidingComponent = ComponentsManager.Get(playerHiding, "PlayerComponent") :: ComponentTypes.PlayerComponent?

	assert(SeekerComponent)

	if playerHiding then
		assert(HidingComponent)
	end

	self.PlayerSeek = SeekerComponent
	self.PlayerHiding = HidingComponent
	self.HideoutInstance = hideoutInstance

	self:_InitConnections()
	self:Run()
end

--//Returner

return {
	new = HideoutCheckHandler.new,
	GetObjectFromHiding = GetObjectFromHiding,
	GetObjectFromSeeker = GetObjectFromSeeker,
	GetObjectFromHideout = GetObjectFromHideout,
}