--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TableKit = require(ReplicatedStorage.Packages.TableKit)

local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local ComponentsUtility = RunService:IsServer() and require(ReplicatedStorage.Shared.Utility.ComponentsUtility) or nil
local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)

local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)

--//Constants

local LOGGING_ENABLED = false

--//Variables

local MODIFIERS_THRESHOLD_VALUE = 0 -- minimal value required from :GetAlpha() to be taken into account

local Player = Players.LocalPlayer
local BaseModifierStatusEffect = WCS.RegisterStatusEffect("BaseModifierStatusEffect", BaseStatusEffect)

local DEFAULT_OPTIONS = {
	Style = Enum.EasingStyle.Linear,
	Priority = 0,
	FadeInTime = 0,
	FadeOutTime = 0,
}

--//Types

type Metadata = {
	Duration: number,
	StartTimestamp: number,
	_trackTimestamps: boolean,
}

export type ModifierType = "Set" | "Increment" | 'Multiply'

export type ModifierOptions = {

	DestroyOnEnd: boolean,
	DestroyOnFadeOut: boolean,

	Tag: string?, -- an optional tag for the effect to be later identified in code
	Style: Enum.EasingStyle?,
	Priority: number?,
	FadeInTime: number?,
	FadeOutTime: number?,
}

export type BaseModifierStatusEffect = {
	Method: ModifierType,
	Options: ModifierOptions,
	DestinatedValue: number,
	DestroyOnFadeOut: boolean,

	new: (character: WCS.Character, method: ModifierType, value: number, options: ModifierOptions?) -> Status,
	GetAlpha: (self: Status) -> number,
	
	-- those are class methods. they do not use self, rather a collection of statuses
	-- you do not need to create a status with .new() to use these
	GetAllModifiersOfType: (statuses: {Status}, modifierType: string) -> { Status },
	GetHighestPriorityModifierFromList: (statuses: { Status }) -> Status,
	ResolveModifiers: (statuses: { Status }, baseValue: number) -> number
	
} & BaseStatusEffect.BaseStatusEffect & WCS.StatusEffect

--//Methods

function BaseModifierStatusEffect.GetAlpha(self: Status)
	if self._EndedTimestamp then

		if self.Options.FadeOutTime == 0 then
			return 0
		end

		local EndTimeAlpha = math.clamp((self._EndedTimestamp + self.Options.FadeOutTime - os.clock()) / self.Options.FadeOutTime, 0, 1)

		return TweenService:GetValue(EndTimeAlpha, self.Options.Style, Enum.EasingDirection.In)
	else
		if self.Options.FadeInTime == 0 then
			return 1
		end

		local StartTimeAlpha = math.clamp(1 - (self._StartedTimestamp + self.Options.FadeInTime - os.clock()) / self.Options.FadeInTime, 0, 1)

		return TweenService:GetValue(StartTimeAlpha, self.Options.Style, Enum.EasingDirection.Out)
	end
end

function BaseModifierStatusEffect.OnConstruct(self: Status, method: ModifierType, value: number, options: SpeedModifierOptions?)
	BaseStatusEffect.OnConstruct(self)

	self.Method = method or "Set"
	self.Options = TableKit.MergeDictionary(DEFAULT_OPTIONS, options or {})
	self.DestroyOnEnd = false
	self.DestinatedValue = value or 1
	self.DestroyOnFadeOut = true

	--changes this thing if passed in options (kindashared settings, config sugar)

	if options and options.DestroyOnFadeOut ~= nil then
		self.DestroyOnFadeOut = options.DestroyOnFadeOut
	end

	if options and options.DestroyOnEnd ~= nil then
		self.DestroyOnEnd = options.DestroyOnEnd
	end

	self._EndedTimestamp = nil
	self._StartedTimestamp = os.clock()

	self.Started:Connect(function()
		self._EndedTimestamp = nil
		self._StartedTimestamp = os.clock()
	end)

	self.Ended:Connect(function()

		self._EndedTimestamp = os.clock()

		if not self.DestroyOnEnd
			and self.DestroyOnFadeOut
			and not self:IsDestroyed() then

			if self.Options.FadeOutTime == 0 then

				self:Destroy()

				return
			end

			self.GenericJanitor:Add(task.delay(self.Options.FadeOutTime, self.Destroy, self))
		end
	end)
end

function BaseModifierStatusEffect.GetAllModifiersOfType(statuses: {Status}, modifierType: string)
	local Modifiers = {}

	for _, Modifier in ipairs(statuses) do
		if Modifier.Method ~= modifierType then
			continue
		end

		table.insert(Modifiers, Modifier)
	end

	return Modifiers
end

function BaseModifierStatusEffect.GetHighestModifierFromList(statuses: { Status })
	if #statuses == 0 then
		return
	end

	local Highest = statuses[1]

	for _, Modifier in ipairs(statuses) do
		if Modifier.Options.Priority > Highest.Options.Priority then
			Highest = Modifier
		end
	end

	return Highest
end

function BaseModifierStatusEffect.ResolveModifiers(statuses: { Status }, baseValue: number)
	local SetTypeModifier = BaseModifierStatusEffect.GetHighestModifierFromList(
		BaseModifierStatusEffect.GetAllModifiersOfType(statuses, "Set")
	)
	local DestinatedValue = baseValue

	if SetTypeModifier then

		DestinatedValue = MathUtility.QuickLerp(
			DestinatedValue,
			SetTypeModifier.DestinatedValue,
			SetTypeModifier:GetAlpha()
		)
		
	end

	for _, Modifier in ipairs(BaseModifierStatusEffect.GetAllModifiersOfType(statuses, "Increment")) do

		if SetTypeModifier
			and (SetTypeModifier:GetAlpha() < MODIFIERS_THRESHOLD_VALUE
			or Modifier.Options.Priority < SetTypeModifier.Options.Priority) then

			continue
		end

		DestinatedValue = MathUtility.QuickLerp(
			DestinatedValue,
			DestinatedValue + Modifier.DestinatedValue,
			Modifier:GetAlpha()
		)
	end

	for _, Modifier in ipairs(BaseModifierStatusEffect.GetAllModifiersOfType(statuses, "Multiply")) do

		if SetTypeModifier
			and (SetTypeModifier:GetAlpha() < MODIFIERS_THRESHOLD_VALUE
			or Modifier.Options.Priority < SetTypeModifier.Options.Priority) then

			continue
		end

		DestinatedValue = MathUtility.QuickLerp(
			DestinatedValue,
			DestinatedValue * Modifier.DestinatedValue,
			Modifier:GetAlpha()
		)
	end
	
	return DestinatedValue
end

--//Returner

return BaseModifierStatusEffect