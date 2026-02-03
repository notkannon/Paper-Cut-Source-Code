--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Refx = require(ReplicatedStorage.Packages.Refx)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)
local RefxWrapper = RunService:IsServer() and require(ServerScriptService.Server.Classes.RefxWrapper) or nil

--//Variables

local LocalPlayer = Players.LocalPlayer
local StealthEffect = Refx.CreateEffect("StealthEffect") :: Impl

--//Types

type Morph = typeof(ReplicatedStorage.Assets.Morphs.MissBloomie)

export type MyImpl = {
	__index: MyImpl,
}

export type Fields = {
	Instance: Morph,
}

export type Impl = Refx.EffectImpl<MyImpl, Fields, Morph>
export type Effect = Refx.Effect<MyImpl, Fields, Morph>

--//Functions

local function New(character: Morph)
	local Wrapper = RefxWrapper.new(StealthEffect, character)
	Wrapper.CreatesForNewPlayers = true
	return Wrapper
end

--//Methods

function StealthEffect.OnConstruct(self: Effect)
	self.DestroyOnEnd = false
	self.DisableLeakWarning = true
	self.DestroyOnLifecycleEnd = false
end

function StealthEffect.OnStart(self: Effect, character: Morph)
	
	self.Instance = character
	
	for _, Instance in ipairs(character:GetDescendants()) do
		if Instance:IsA("PointLight") then
			Instance.Enabled = false
		end
	end
end

function StealthEffect.OnDestroy(self: Effect)
	
	local Player = Players:GetPlayerFromCharacter(self.Instance)
	
	if not self.Instance then
		return
	end
	
	for _, Instance in ipairs(self.Instance:GetDescendants()) do
		if Instance:IsA("PointLight") then
			Instance.Enabled = true
		end
	end
end

--//Return

return {
	new = New,
	locally = StealthEffect.locally
}