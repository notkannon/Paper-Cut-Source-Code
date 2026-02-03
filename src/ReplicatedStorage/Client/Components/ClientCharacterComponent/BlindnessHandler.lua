
--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local ModifiedVisibilityStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedVisibility)
local BaseModifierHandler = require(ReplicatedStorage.Shared.Components.Abstract.BaseModifierHandler)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local MathUtility = require(ReplicatedStorage.Shared.Utility.MathUtility)

--//Types

export type MyImpl = { } & BaseModifierHandler.MyImpl

export type Fields = { } & BaseModifierHandler.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "BlindnessHandler", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "BlindnessHandler", PlayerTypes.Character>

--//Variables

local Player = Players.LocalPlayer

local BlindnessHandler = BaseComponent.CreateComponent("BlindnessHandler", {
	isAbstract = false,
	predicate = function(instance)
		return instance == Player.Character
	end,
}, BaseModifierHandler) :: Impl

--//Methods

local function BlindnessEffect()
	local BlurEffect = Lighting:FindFirstChild("BlindnessBlur") :: BlurEffect
	
	if not BlurEffect then
		BlurEffect = Instance.new("BlurEffect")
		BlurEffect.Name = "BlindnessBlur"
		BlurEffect.Size = 0
		BlurEffect.Parent = Lighting
	end

	return BlurEffect
end

function BlindnessHandler.GetBaseValue(self: Component)
	return 0
end

function BlindnessHandler.HandleProcessedValue(self: Component, value: number)
	local UIController = Classes.GetSingleton("UIController")
	local BindnessVignette : ImageLabel = UIController.Instance.Screen.BlindnessVignette
	local VignetteOpaqueness = math.clamp(1 - value, 0, 1)
	local BlurAlpha = 1 - VignetteOpaqueness
	local BlurEffect : BlurEffect = BlindnessEffect()
	
	BindnessVignette.BackgroundTransparency = VignetteOpaqueness
	BindnessVignette.ImageTransparency = VignetteOpaqueness
	BlurEffect.Size = MathUtility.QuickLerp(0, 56, BlurAlpha)
end

function BlindnessHandler.OnConstructClient(self: Component, ...)
	self.ModifierClass = ModifiedVisibilityStatus
	BaseModifierHandler.OnConstructClient(self, ...)
end

--//Returner

return BlindnessHandler