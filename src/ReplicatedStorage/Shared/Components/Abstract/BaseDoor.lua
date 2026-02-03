--//Service

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Import

local WCS = require(ReplicatedStorage.Packages.WCS)

local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local TableKit = require(ReplicatedStorage.Packages.TableKit)
local Interaction = require(ReplicatedStorage.Shared.Components.Interactions.Interaction)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsData = require(ReplicatedStorage.Shared.Data.ComponentsData)
local SharedComponent = require(ReplicatedStorage.Shared.Classes.Abstract.SharedComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

local DoorBreakEffect = require(ReplicatedStorage.Shared.Effects.Specific.Components.Doors.DoorBreak)
local DoorDamageEffect = require(ReplicatedStorage.Shared.Effects.Specific.Components.Doors.DoorDamage)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)

local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)
local ModifiedStaminaGainStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedStaminaGain)

local WCS = require(ReplicatedStorage.Packages.WCS)
local Promise = require(ReplicatedStorage.Packages.Promise)

--//Constants

local SLAM_DEBOUNCE_AFTER_CLOSE = 0.5

--//Variables

local LocalPlayer = Players.LocalPlayer
local BaseDoor = BaseComponent.CreateComponent("BaseDoor", {

	isAbstract = true,
	ancestorWhitelist = { workspace },

	defaults = {

		Opened = true,
		Broken = false,
		Protected = false,

		Health = 100,
		MaxHealth = 100,
		ForceDirection = 1,
	},

	predicate = function(instance: Model)
		return instance:HasTag("Door")
	end,

}, SharedComponent) :: Impl

--//Type

export type Fields = {

	Broke: Signal.Signal<Player?>,
	Slammed: Signal.Signal<Player?>,
	OpenedChanged: Signal.Signal<boolean, Player?>,
	HealthChanged: Signal.Signal<number, number, Player?>,
	ProtectedChanged: Signal.Signal<boolean, Player?>,

	BrokenInstanceReference: Model,

	Protectors: {},
	SlamEvent: SharedComponent.ServerToClient,
	DoorStatusEvent: SharedComponent.ServerToClient<boolean>,
	Interaction: Interaction.Component,
	InitialCFrames: {[Instance]: CFrame},

	_SlamTimestamp: number,
	_CloseTimestamp: number, -- used to debounce slamming while door is closing
	_DefaultInstanceSet: SharedComponent.ServerToClient,
}

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: SharedComponent.MyImpl)),

	CreateEvent: SharedComponent.CreateEvent<Component>,
	ShouldSlam: (self: Component, player: Player?) -> boolean,
	GetOpenDirection: (self: Component, from: Vector3) -> "Forward" | "Backward",
	GetReferenceInstance: (self: Component) -> Instance?,

	SetHealth: (self: Component, value: number, player: Player?) -> (),
	SetOpened: (self: Component, value: boolean) -> (),

	IsOpened: (self: Component) -> boolean,
	IsBroken: (self: Component) -> boolean,
	IsProtected: (self: Component) -> boolean,

	TakeDamage: (self: Component, DamageContainer: WCS.DamageContainer) -> (),
	PromptSlamClient: (self: Component) -> (),
	SetReferenceInstance: (self: Component, instance: Instance) -> (),

	OnSlam: (self: Component, player: Player?) -> (),
	OnOpen: (self: Component, player: Player?, playerPosition: Vector3?) -> (),
	OnClose: (self: Component, player: Player?) -> (),
	OnHealthChanged: (self: Component, newHealth: number, oldHealth: number, player: Player?) -> (),

	--protectors are things which works couple .Protected state, like objects which protects door from interactions
	AddProtector: (self: Component, protector: unknown) -> (),
	RemoveProtector: (self: Component, protector: unknown) -> (),
	GetNewestProtector: (self: Component) -> unknown,

	OnConstruct: (self: Component) -> (),
	OnConstructServer: (self: Component) -> (),
	OnConstructClient: (self: Component) -> (),

	_InitSounds: (self: Component) -> (),
	_InitInteraction: (self: Component) -> (),
	_InitCollisionNetwork: (self: Component) -> (),
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, string, BaseDoorModel>
export type Component = BaseComponent.Component<MyImpl, Fields, string, BaseDoorModel> 

--//Methods

function BaseDoor.OnSlam(self: Component, player: Player?)

	self.Slammed:Fire(LocalPlayer or player)
	self._SlamTimestamp = os.clock()

	--.. a piece of shit
	if RunService:IsClient() then

		local Character = Players.LocalPlayer.Character

		if not Character then
			return
		end

		local Magnitude = (Character.HumanoidRootPart.Position - self.Instance.Root.Position).Magnitude

		if Magnitude > 30 then
			return
		end

		Classes.GetSingleton("CameraController"):QuickShake(0.23, 30 / Magnitude * 0.45)

	elseif RunService:IsServer() then
		if not player then
			return
		end

		local IsKiller = RolesManager:IsPlayerKiller(player)

		if not IsKiller then
			return
		end

		local WCSCharacter = WCS.Character.GetCharacterFromInstance(player.Character)

		if not WCSCharacter then
			return
		end

		--dealing 50 damage, opening the door
		local SprintSkill = WCSCharacter:GetSkillFromString("Sprint")
		assert(SprintSkill)
		self:TakeDamage(SprintSkill:CreateDamageContainer(50))
		self:SetOpened(true)
		self:OnOpen(player)

		local ProxyService = Classes.GetSingleton("ProxyService")
		ProxyService:AddProxy("DoorSlammed"):Fire(player, self)

		-- slowing down the culprit, and halving stamina regen

		local PenaltyDuration = 2 -- TODO: remove hardcode

		ModifiedSpeedStatus.new(WCSCharacter, "Multiply", 0.5, {Tag = "DoorDamageSlowed", FadeOutTime = 0.5, FadeInTime = 0.5, Priority = 6}):Start(PenaltyDuration)
		ModifiedStaminaGainStatus.new(WCSCharacter, "Multiply", 0.5, {Tag = "DoorDamageStaminaGainSlowed", Priority = 6}):Start(PenaltyDuration)
	end
end

function BaseDoor.OnOpen(self: Component, player: Player?, playerPosition: Vector3?)
	self.OpenedChanged:Fire(true, player)

	--killers cannot close doors
	if RunService:IsServer() then
		self.Interaction:SetTeamAccessibility("Killer", true)
	end
end

function BaseDoor.OnClose(self: Component, player: Player?)
	self.OpenedChanged:Fire(false, player)
	self._CloseTimestamp = os.clock()

	--killers can open doors
	if RunService:IsServer() then
		self.Interaction:SetTeamAccessibility("Killer", false)
	end
end

function BaseDoor.OnHealthChanged(self: Component, newHealth: number, oldHealth: number, player: Player) end

function BaseDoor.GetOpenDirection(self: Component, from: Vector3)

	local FrontNormal = self.Instance.Root.CFrame.LookVector
	local DoorPosition = (from - self.Instance.Root.Position).Unit

	return FrontNormal:Dot(DoorPosition) > 0 and "Forward" or "Backward"
end

function BaseDoor.SetHealth(self: Component, value: number, player: Player?)
	self:OnHealthChanged(value, self.Attributes.Health, player)
	self.HealthChanged:Fire(value, self.Attributes.Health, player)
	self.Attributes.Health = value
end

function BaseDoor.IsBroken(self: Component)
	return self.Attributes.Broken
end

function BaseDoor.IsProtected(self: Component)
	return self.Attributes.Protected
end

function BaseDoor.IsOpened(self: Component)
	return self.Attributes.Opened
end

function BaseDoor.SetOpened(self: Component, value: boolean)

	if self:IsProtected() and value
		or value == self.Attributes.Opened then

		return
	end

	self.Attributes.Opened = value
end

function BaseDoor.SetReferenceInstance(self: Component, instance: Instance)

	if not RunService:IsServer() then
		return
	end

	local ValueInstance = self.Instance:FindFirstChild("ReferenceInstance") :: ObjectValue

	if not ValueInstance then

		ValueInstance = Instance.new("ObjectValue")
		ValueInstance.Parent = self.Instance
		ValueInstance.Name = "ReferenceInstance"
	end

	ValueInstance.Value = instance
end

function BaseDoor.GetReferenceInstance(self: Component)
	local ValueInstance = self.Instance:FindFirstChild("ReferenceInstance") :: ObjectValue
	return ValueInstance and ValueInstance.Value
end

function BaseDoor.GetNewestProtector(self: Component)
	return self.Protectors[#self.Protectors]
end

function BaseDoor.ShouldSlam(self: Component, player: Player?)

	--shared check
	if self:IsOpened()
		or self:IsBroken()
		or self:IsProtected()
		or self:IsDestroying()
		or os.clock() - self._CloseTimestamp < SLAM_DEBOUNCE_AFTER_CLOSE then

		return false
	end

	--player validation
	if player and (
		not player.Character
			or not WCS.Character.GetCharacterFromInstance(player.Character)) then

		return false
	end

	--client only check
	if RunService:IsClient() and os.clock() - self._SlamTimestamp < 1 then
		return false
	end

	return true
end

function BaseDoor.PromptSlamClient(self: Component)
	assert(RunService:IsClient())

	--doing client checks
	if not self:ShouldSlam() then
		return
	end

	local Character = LocalPlayer.Character
	local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
	local RootPart = Humanoid and Humanoid.RootPart

	if not RootPart then
		return
	end

	--prompting server
	self.SlamEvent.Fire(RootPart.Position)

	--client behavior thing
	self:OnSlam()
end

function BaseDoor.TakeDamage(self: Component, DamageContainer: WCS.DamageContainer)

	--hooks
	if self:IsBroken() then

		return

	elseif self:IsProtected() then

		--dealing damage to protector, modifying damage container
		self:GetNewestProtector()
			:TakeDamage(DamageContainer)

		--check if door still protected
		if self:IsProtected() then
			return
		end
	end

	--define source skill if provided
	local Source = DamageContainer and DamageContainer.Source :: WCS.Skill?
	local Damager = Source and Source.Player or nil :: Player?
	local DamagerModel = Source and Source.Character.Instance or nil :: Model

	--effect running
	DoorDamageEffect.new(self.Instance):Start(Players:GetPlayers())

	--updating state
	self:SetHealth(math.max(0, self.Attributes.Health - DamageContainer.Damage), Damager)

	if DamagerModel then
		self.Attributes.ForceDirection = self:GetOpenDirection(DamagerModel.HumanoidRootPart.Position) == "Forward" and -1 or 1
	end

	--mark as broken (disabling door interactions)
	if self.Attributes.Health == 0 and not self:IsBroken() then

		self.Broke:Fire(Damager)
		self.Attributes.Broken = true
		self.Interaction:SetEnabled(false)

		--break door locally for all players
		DoorBreakEffect
			.new(self.Instance, self.BrokenInstanceReference)
			:Start(Players:GetPlayers())
	end
end

function BaseDoor.AddProtector(self: Component, protector: BaseComponent.Component)

	--door ignores any interactions
	self.Attributes.Protected = true
	self.ProtectedChanged:Fire(true)
	self.Interaction:SetEnabled(false)

	--removing protector on destroy
	protector.Janitor:Add(function()
		self:RemoveProtector(protector)
	end)

	--removing protector with door
	self.Janitor:Add(protector)

	--registry
	table.insert(self.Protectors, protector)
end

function BaseDoor.RemoveProtector(self: Component, protector: unknown)

	local Index = table.find(self.Protectors, protector)

	if Index then
		table.remove(self.Protectors, Index)
	end

	--removing from janitor
	self.Janitor:RemoveNoClean(protector)

	--unprotecting door when no protectors left
	if #self.Protectors == 0 then

		print('turning on')

		self.Attributes.Protected = false
		self.ProtectedChanged:Fire(false)
		self.Interaction:SetEnabled(true)
	end
end

function BaseDoor._InitSounds(self: Component)

	--temporary server-only
	if not RunService:IsServer() then
		return
	end

	--slam sound effect
	self.Janitor:Add(self.Slammed:Connect(function(player)

		local SlamSound = SoundUtility.CreateTemporarySound(
			SoundUtility.Sounds.Instances.Doors.Slam, true
		)
		SlamSound.Parent = self.Instance.Root
		SoundUtility.AdjustSoundForCharacter(SlamSound, player.Character)
		SlamSound:Play()
	end))

	--open/close sounds
	self.Janitor:Add(self.OpenedChanged:Connect(function(value, player)

		if value then

			--cancelling close sound playback
			self.Janitor:Remove("DelayedCloseSound")

			local OpenSound = SoundUtility.CreateTemporarySound(
				SoundUtility.Sounds.Instances.Doors.Open, true
			)

			if player then
				SoundUtility.AdjustSoundForCharacter(OpenSound, player.Character)
			end

			OpenSound.Parent = self.Instance.Root
			OpenSound:Play()

		else
			--close sound playback with delay

			self.Janitor:Add(

				task.delay(0.5, function()

					local CloseSound = SoundUtility.CreateTemporarySound(
						SoundUtility.GetRandomSoundFromDirectory(
							SoundUtility.Sounds.Instances.Doors.Close
						), true
					)
					CloseSound.Parent = self.Instance.Root
					SoundUtility.AdjustSoundForCharacter(CloseSound, player.Character)
					CloseSound:Play()
				end),

				nil,
				"DelayedCloseSound"
			)
		end
	end))

	----damage sounds handling
	--self.Janitor:Add(self.HealthChanged:Connect(function(newHealth, oldHealth)

	--	--damage-only
	--	if newHealth >= oldHealth then
	--		return
	--	end

	--	SoundUtility.CreateTemporarySound(
	--		SoundUtility.GetRandomSoundFromDirectory(
	--			SoundUtility.Sounds.Instances.Doors.Damage
	--		)
	--	).Parent = self.Instance.Root
	--end))

	--broke sound effect
	self.Janitor:Add(self.Broke:Connect(function()

		SoundUtility.CreateTemporarySound(
			SoundUtility.Sounds.Instances.Doors.Break
		).Parent = self.Instance.Root
	end))
end

function BaseDoor._InitInteraction(self: Component)
	print(self.Instance)

	local function PromiseChild(inst: Instance, name: string)
		local Child = inst:FindFirstChild(name)

		if Child then
			return Promise.resolve(Child)
		end

		return Promise.fromEvent(inst.ChildAdded, function(potentialChild: Instance)
			return potentialChild.Name == name
		end)
	end

	local ProximityPrompt = PromiseChild(self.Instance, "Root"):timeout(25):expect()
		:FindFirstChild("Interaction") :: ProximityPrompt

	--awaiting interaction component added
	self.Interaction = self.Janitor:AddPromise(ComponentsManager.Await(ProximityPrompt, Interaction))
		:timeout(35)
		:expect()

	--shared settings
	self.Interaction.AllowedSkills.Sprint = false
	self.Interaction.AllowedStatusEffects.Physics = false

	if RunService:IsServer() then

		self.Interaction.Instance.ObjectText = ""
		self.Interaction.Instance.ActionText = "Open"
		self.Interaction.Instance.HoldDuration = 0
		self.Interaction.Instance.RequiresLineOfSight = false
		self.Interaction.Instance.ClickablePrompt = true
		self.Interaction.Instance.MaxActivationDistance = 10

		self.Interaction:SetFilteringType("Exclude")
	end
end

function BaseDoor._InitCollisionNetwork(self: Component)

	for _, Descendant: BasePart? in ipairs(self.Instance:GetDescendants()) do

		if not Descendant:IsA("BasePart") then
			continue
		end

		Descendant.CollisionGroup = "Doors"

		if Descendant.Anchored then
			continue
		end

		Descendant:SetNetworkOwner(nil)
	end
end

function BaseDoor.OnConstructServer(self: Component)

	--listening interaction triggering
	self.Janitor:Add(self.Interaction.Started:Connect(function(player)

		--ignore if broke
		if self:IsBroken() then
			return
		end

		local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(player)

		--negate door opened state
		self:SetOpened(not self:IsOpened())

		if RolesManager:IsPlayerKiller(player) then
			local ProxyService = Classes.GetSingleton("ProxyService")
			ProxyService:AddProxy("DoorUnlocked"):Fire(player, self.Instance)
		end

		if self:IsOpened() then
			self:OnOpen(player)
		else
			self:OnClose(player)
		end

		--cooldown caused only by native interaction, not internal method call
		self.Interaction:ApplyCooldown(
			ComponentsData.Doors.Shared.InteractionCooldown
		)
	end))

	-- door slamming server handler
	self.Janitor:Add(self.SlamEvent.On(function(player: Player, position: Vector3)

		if not self:ShouldSlam(player) then
			return
		end

		print("SlamEvent")

		self:OnSlam(player)
		self:SetOpened(true)
		self:OnOpen(player, position)

		self.SlamEvent.FireExcept(player, true)

		--cooldown caused only by native interaction, not internal method call
		self.Interaction:ApplyCooldown(
			ComponentsData.Doors.Shared.InteractionCooldown
		)
	end))

	--collision setup,  -- bro i have only 4 minutes please figure this out
	self:_InitCollisionNetwork() -- for interaction: when SetEnabled(false) is fired delete/fadeout the UI on the screen

	--server state applying
	if self:IsOpened() then
		self:OnOpen(nil, self.Instance:GetPivot().Position)
	else
		self:OnClose()
	end
end

function BaseDoor.OnConstructClient(self: Component)

	local OldHealth = self.Attributes.Health

	--client slam event handler
	self.Janitor:Add(self.SlamEvent.On(function(...)
		self:OnSlam(...)
	end))

	local function UpdateInteractionClient()

		--applying new interaction text
		local IsOpen = self.Attributes.Opened
		self.Interaction.Instance.ActionText = IsOpen and "Close" or "Open"



		local IsKiller = RolesManager:IsPlayerKiller(LocalPlayer)

		self.Interaction.Instance.HoldDuration = IsKiller and not IsOpen and ComponentsData.Doors.Shared.TeacherOpenTime or 0

		--print('toggling interaction', not IsKiller or IsOpen)
		--self.Interaction:SetEnabled(not IsKiller or not IsOpen) -- so disabled when killer AND open
	end

	--client attributes
	self.Janitor:Add(self.Attributes.AttributeChanged:Connect(function(attribute: string, value: any)

		if attribute == "Opened" then

			if self:IsOpened() then
				self:OnOpen()
			else
				self:OnClose()
			end

			UpdateInteractionClient()

		elseif attribute == "Health" then

			self:OnHealthChanged(value, OldHealth)

			OldHealth = value
		end
	end))

	self.Janitor:Add(RolesManager.PlayerRoleChanged:Connect(function(plr)
		if plr == LocalPlayer then
			UpdateInteractionClient()
		end
	end))

	--client initial state applying

	if self:IsOpened() then
		self:OnOpen()
	else
		self:OnClose()
	end

	UpdateInteractionClient()
end

function BaseDoor.OnConstruct(self: Component) 
	SharedComponent.OnConstruct(self)

	self.Broke = self.Janitor:Add(Signal.new())
	self.Slammed = self.Janitor:Add(Signal.new())
	self.OpenedChanged = self.Janitor:Add(Signal.new())
	self.HealthChanged = self.Janitor:Add(Signal.new())
	self.ProtectedChanged = self.Janitor:Add(Signal.new())

	self.Protectors = {}
	self._SlamTimestamp = 0
	self._CloseTimestamp = 0

	self:_InitInteraction()
	self:_InitSounds()

	--client thing used to send slam requests
	self.SlamEvent = self:CreateEvent(
		"Slam",
		"Reliable",
		function() return true end
	)
end

--//Returner

return BaseDoor