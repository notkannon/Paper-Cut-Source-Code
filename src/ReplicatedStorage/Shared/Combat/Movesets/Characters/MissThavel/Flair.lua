--//Services

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseSkill = require(ReplicatedStorage.Shared.Combat.Abstract.BaseSkill)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local FlairEffect = require(ReplicatedStorage.Shared.Effects.Specific.Role.MissThavel.Flair)

local Utility = require(ReplicatedStorage.Shared.Utility)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Constants

local IGNORED_STATUSES = {
	"Hidden",
	"Stealthed", -- like invisibility
}

--//Variables

local Player = Players.LocalPlayer

local Flair = WCS.RegisterSkill("Flair", BaseSkill)

--//Types

type Skill = BaseSkill.BaseSkill

--//Methods

function Flair.OnStartClient(self: Skill)
	
	local Correction = self.GenericJanitor:Add(
		Instance.new("ColorCorrectionEffect")
	)
	
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Players.Skills.Flair.Use
	)
	
	Correction.Parent = Lighting
	Correction.Contrast = -2
	Correction.Saturation = -0.5
	Correction.Brightness = -0.5
	
	TweenUtility.PlayTween(Correction, TweenInfo.new(3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Contrast = 0,
		Saturation = 0,
		Brightness = 0,
		
	}, function(state)
		if not Correction then
			return
		end
		
		Correction:Destroy()
	end)
end

function Flair.OnStartServer(self: Skill)
	
	self:ApplyCooldown(self.FromRoleData.Cooldown)
	
	local Characters = {}
	
	for _, Player in ipairs(Players:GetPlayers()) do
		
		--dude it wont work cuz thavel has no footprints, only StudentAppearance instances
		if (not RunService:IsStudio() and Player == self.Player) or not Player.Character then
			continue
		end
		
		local WCSCharacter = WCS.Character.GetCharacterFromInstance(Player.Character)
		
		if not WCSCharacter then
			continue
		end
		
		--check if character has disallowed statuses (undetectable)
		if WCSUtility.HasActiveStatusEffectsWithNames(WCSCharacter, IGNORED_STATUSES) then
			continue
		end
		
		table.insert(Characters, Player.Character)
	end
	
	--creating effect and storing in janitor
	local Effect = self.GenericJanitor:Add(FlairEffect.new(Characters), nil, "FlairEffect") :: FlairEffect.Effect
	
	--removal
	self.GenericJanitor:Add(task.delay(self.FromRoleData.Duration, function()
		self.GenericJanitor:Remove("FlairEffect")
	end))
	
	--applying effect for current player
	Effect:Start({self.Player})
end

--//Returner

return Flair