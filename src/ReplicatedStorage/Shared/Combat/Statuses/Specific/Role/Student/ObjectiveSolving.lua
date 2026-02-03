--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Classes = require(ReplicatedStorage.Shared.Classes)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)
local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

--//Variables

local ObjectiveSolving = WCS.RegisterStatusEffect("ObjectiveSolving", BaseStatusEffect)

--//Types

export type Status = BaseStatusEffect.BaseStatusEffect

--//Methods

function ObjectiveSolving.OnStartClient(self: Status)
	self.Janitor:Get("SpeedModifier"):Start()
end

function ObjectiveSolving.OnConstructClient(self: Status)
	
	local SpeedModifier = self.Janitor:Add(

		ModifiedSpeedStatus.new(self.Character, "Set", 0, {

			Priority = 10,
			Tag = "ObjectiveSolving"

		} :: ModifiedSpeedStatus.SpeedModifierOptions),
		
		"Destroy",
		"SpeedModifier"
	)

	SpeedModifier.DestroyOnEnd = true
	
	self:SetHumanoidData({
		
		JumpPower = { 0, "Set" },
		JumpHeight = { 0, "Set" },
		AutoRotate = { false, "Set" },
		
	} :: WCS.HumanoidDataProps)
end

function ObjectiveSolving.OnConstruct(self: Status)
	BaseStatusEffect.OnConstruct(self)
	self.DestroyOnEnd = true
end

--//Returner

return ObjectiveSolving