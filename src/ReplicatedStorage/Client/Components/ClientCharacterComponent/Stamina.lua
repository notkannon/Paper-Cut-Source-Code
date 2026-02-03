--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)

local ClientRemotes = require(ReplicatedStorage.Client.ClientRemotes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)

local ModifiedStaminaGainStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedStaminaGain)

--//Variables

local LocalPlayer = Players.LocalPlayer
local Stamina = BaseComponent.CreateComponent("Stamina", {
	isAbstract = false,
}) :: Impl

--//Types

export type MyImpl = {
	__index: MyImpl,
	
	Get: (self: Component) -> number,
	Increment: (self: Component, amount: number, ignoreUsageTime: boolean?) -> (),
	UseNoIncrement: (self: Component) -> (),
	OnConstructClient: (self: Component, characterComponent: {any}) -> (),
	
	_ConnectSteps: (self: Component) -> (),
}

export type Fields = {
	Max: number,
	GainPerSecond: number,
	
	Changed: Signal.Signal<number, number>,
	CharacterComponent: {any},
	
	_Value: number,
	_LastUsageTime: number,
}

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "Stamina", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "Stamina", PlayerTypes.Character>

--//Methods

function Stamina.Get(self: Component)
	return self._Value
end

function Stamina.UseNoIncrement(self: Component)
	self._LastUsageTime = os.clock()
end

function Stamina.Increment(self: Component, amount: number, ignoreUsageTime: boolean?)
	
	local OldStamina = self._Value
	local Destinated = math.clamp(self._Value + amount, 0, self.Max)
	
	if OldStamina == Destinated then
		return
	end

	self._Value = Destinated
	
	self.Changed:Fire(Destinated, OldStamina)

	if not ignoreUsageTime then
		self._LastUsageTime = os.clock()
	end
end

function Stamina._ConnectSteps(self: Component)
	
	self.Janitor:Add(RunService.Heartbeat:Connect(function(delta)
		
		if self._Value >= self.Max
			or os.clock() - self._LastUsageTime < 0.5 then
			
			return
		end
		
		local ResultStaminaGain = self.GainPerSecond * delta
		
		if not LocalPlayer.Character then
			return
		end
		
		local WCSCharacter = WCS.Character.GetCharacterFromInstance(LocalPlayer.Character)
		local ModifiedStaminaGainStatuses = WCSUtility.GetAllActiveStatusEffectsFromString(WCSCharacter, "ModifiedStaminaGain")

		ResultStaminaGain = ModifiedStaminaGainStatus.ResolveModifiers(ModifiedStaminaGainStatuses, ResultStaminaGain)
		
		self:Increment(ResultStaminaGain, true)
	end))
end

function Stamina.OnConstructClient(self: Component, characterComponent: {any})
	
	--inverse dependency
	characterComponent.Janitor:Add(self, "Destroy")
	
	--subscribing to server stamina change requests!
	self.Janitor:Add(ClientRemotes.ChangeStamina.On(function(args)

		local currentValue = self:Get() -- Use self:Get() or self._Value directly
		local amountToIncrement = 0

		if args.method == "Set" then
			amountToIncrement = args.value - currentValue
		elseif args.method == "Multiply" then
			amountToIncrement = (currentValue * args.value) - currentValue
		elseif args.method == "Increment" then
			amountToIncrement = args.value
		end
		
		self:Increment(amountToIncrement) -- No need for ignoreUsageTime here, let Increment handle its default
	end))
	
	--data initials
	local StaminaData = Classes.GetSingleton("PlayerController"):GetRoleConfig().CharacterData.Stamina
	
	self.Max = StaminaData.Max
	self.GainPerSecond = StaminaData.GainPerSecond
	self.LossPerSecond = StaminaData.LossPerSecond -- Assuming LossPerSecond might be used elsewhere or intended for future use
	self.Changed = self.Janitor:Add(Signal.new())
	
	self._Value = self.Max
	self._LastUsageTime = os.clock()
	
	self:_ConnectSteps()
end

--//Returner

return Stamina