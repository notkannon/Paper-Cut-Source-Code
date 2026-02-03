--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)
local ModifiedDamageDealtStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedDamageDealt)

--//Variables

local SneakAttacking = WCS.RegisterStatusEffect("SneakAttacking", BaseStatusEffect)

--//Types

export type Status = BaseStatusEffect.BaseStatusEffect

--//Methods

function SneakAttacking.OnConstructServer(self: Status)
	BaseStatusEffect.OnConstruct(self)
	self.DestroyOnEnd = false
end

function SneakAttacking.OnStartServer(self: Status)
	self.DamageModifier = ModifiedDamageDealtStatus.new(self.Character, "Multiply", 2, {Tag = "SneakAttacking"})
	self.DamageModifier:Start()
end

function SneakAttacking.OnEndServer(self: Status)
	task.delay(1, function()
		if not self.DamageModifier:IsDestroyed() then
			self.DamageModifier:End()
		end
	end)
end

function SneakAttacking.OnStartClient(self: Status)
	
	local UIController = Classes.GetSingleton("UIController")
	
	TweenUtility.ClearAllTweens(UIController.Instance.Screen.Gameplay.OtherVignette)
	TweenUtility.PlayTween(UIController.Instance.Screen.Gameplay.OtherVignette, TweenInfo.new(2), {
		ImageColor3 = Color3.fromRGB(208, 42, 42),
		ImageTransparency = 0.4,
	})
end

--//Returner

return SneakAttacking