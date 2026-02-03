--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseConsumable = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem.BaseConsumable)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

local ServerRemotes = RunService:IsServer() and require(ServerScriptService.Server.ServerRemotes) or nil

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local AnimationUtility = require(ReplicatedStorage.Shared.Utility.AnimationUtility)

--//Variables

local SodaAnimations = ReplicatedStorage.Assets.Animations.Items.Soda
local SodaItem = BaseComponent.CreateComponent("SodaItem", {
	
	isAbstract = false,
	
}, BaseConsumable) :: BaseConsumable.Impl

--//Methods

function SodaItem._InitHandleJoint(self: BaseConsumable.Component)
	
	--motor initials

	local Motor = self.Handle:FindFirstChildWhichIsA("Motor6D")
	Motor.Part0 = self.Character:FindFirstChild("RightHand")
	Motor.Part1 = self.Handle
	Motor.Enabled = true

	--removing motor joint
	self.EquipJanitor:Add(function()
		if Motor then
			Motor.Enabled = false
		end
	end)
end

function SodaItem.OnCancelServer(self: BaseConsumable.Component)
	self.EquipJanitor:RemoveList(
		"UseAnimation",
		"SlowedStatus",
		"UsageSound"
	)
end

function SodaItem.BeforeUseServer(self: BaseConsumable.Component)
	
	local Humanoid = self.Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Character)
	local AnimationTrack = AnimationUtility.QuickPlay(Humanoid, SodaAnimations.Use, {

		Looped = false,
		Priority = Enum.AnimationPriority.Action4

	})

	--animation cleanup
	self.EquipJanitor:Add(AnimationTrack, "Stop", "UseAnimation")
	
	self.EquipJanitor:Add(ModifiedSpeedStatus.new(WCSCharacter, "Multiply", 0.5, {

		Tag = "ItemUseSlowed",
		Priority = 11,
		FadeInTime = 1,
		FadeOutTime = 1,

	}), "Destroy", "SlowedStatus"):Start()
	
	--usage sound playback
	self.EquipJanitor:Add(
		
		SoundUtility.CreateTemporarySound(
			SoundUtility.Sounds.Instances.Items.Food.SodaUse
		),
		
		"Destroy",
		"UsageSound"
		
	).Parent = self.Character.PrimaryPart

	--applying delay
	self.UseDelay = AnimationUtility.PromiseDuration(AnimationTrack, 3, true):expect()
end

function SodaItem.OnEquipServer(self: BaseConsumable.Component)
	BaseConsumable.OnEquipServer(self)
	
	--yup
	self:_InitHandleJoint()
end

function SodaItem.OnEquipClient(self: BaseConsumable.Component)
	BaseConsumable.OnEquipClient(self)
	
	--equip sound
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Instances.Items.Food.SodaEquip
	).Parent = self.Character.PrimaryPart
	
	--yup
	self:_InitHandleJoint()
	
	local Humanoid = self.Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	
	--idle track playback
	self.EquipJanitor:Add(AnimationUtility.QuickPlay(Humanoid, SodaAnimations.Idle, {

		Looped = true,
		Priority = Enum.AnimationPriority.Idle,

	}), "Stop")

	--equip track
	self.EquipJanitor:Add(AnimationUtility.QuickPlay(Humanoid, SodaAnimations.Equip, {

		Looped = false,
		Priority = Enum.AnimationPriority.Action3,

	}), "Stop")
end

function SodaItem.OnUseServer(self: BaseConsumable.Component)
	
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Instances.Items.Food.Drink
	).Parent = self.Character.PrimaryPart
	
	--removing slowed effect
	self.EquipJanitor:Remove("SlowedStatus")
	
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Character)
	local SpeedBoost = ModifiedSpeedStatus.new(WCSCharacter, "Increment", 5, {
		
		Tag = "SodaBoosted",
		Priority = 7,
		FadeOutTime = 4,
		
	})
	
	SpeedBoost.DestroyOnFadeOut = true
	SpeedBoost.DestroyOnEnd = false
	SpeedBoost:Start(6)
	
	--applying stamina to client
	ServerRemotes.ChangeStamina.Fire(self.Player, {
		method = "Increment",
		value = 50,
	})
end

--function SodaItem.OnUseClient(self: BaseConsumable.Component)
--	ComponentsManager
--		.Get(self.Character, "Stamina")
--		:Increment(35, true)
--end

function SodaItem.OnConstruct(self: BaseConsumable.Component)
	BaseConsumable.OnConstruct(self)
	
	self.IgnoreClientUsage = true
	self.RespectExternaInfluences = true
end

--//Returner

return SodaItem