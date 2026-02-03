--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local PlayerTypes = require(ReplicatedStorage.Shared.Types.PlayerTypes)

local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseAppearance = require(ReplicatedStorage.Shared.Components.Abstract.BaseAppearance)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local TweenUtility = require(ReplicatedStorage.Shared.Utility.TweenUtility)

--//Constants

local TRANSPARENT_NAMES = {
	"Head",
	"Hair",
	"HairTop",
	"ABCLetters",
	"Handle",
	"WhiteSheet_R",
	"WhiteSheet_L",
	"Horns",
}

--//Variables

local MissThavelAppearance = BaseComponent.CreateComponent("MissThavelAppearance", {
	isAbstract = false
}, BaseAppearance) :: Impl

--//Types

export type MyImpl = {
	__index: typeof(setmetatable({} :: MyImpl, {} :: BaseAppearance.MyImpl)),
}

export type Fields = {

} & BaseAppearance.Fields

export type Impl = BaseComponent.ComponentImpl<MyImpl, Fields, "MissThavelAppearance", PlayerTypes.Character>
export type Component = BaseComponent.Component<MyImpl, Fields, "MissThavelAppearance", PlayerTypes.Character>

--//Methods

function MissThavelAppearance.IsDescendantTransparent(self: Component, descendant: Instance)
	return self:IsLocalPlayer()
		and table.find(TRANSPARENT_NAMES, descendant.Name)
end

function MissThavelAppearance.InterpolateDemonicAppearance(self: Component, alpha: number)
	alpha = math.clamp(alpha, 0, 1)
	
	local Shadow = self.Instance:FindFirstChild("ShadowHighlight") :: Highlight
	Shadow.Enabled = alpha > 0
	Shadow.FillTransparency = 1 - alpha * 0.8
	
	for _, ParticleEmitter: ParticleEmitter in ipairs(self.Instance.UpperTorso:GetChildren()) do
		if not ParticleEmitter:IsA("ParticleEmitter") then
			continue
		end
		
		ParticleEmitter.Enabled = alpha >= 0.4
	end
	
	for _, Detail: BasePart in ipairs(self.Instance.Demonic:GetChildren()) do
		if not Detail:IsA("BasePart") then
			continue
		end
		
		Detail.Transparency = 1 - alpha
	end
end

function MissThavelAppearance.OnConstructServer(self: Component)
	BaseAppearance.OnConstructServer(self)
	
	self:InterpolateDemonicAppearance(0)
	
	local ProgressivePunishment = self.Janitor:AddPromise(ComponentsManager.Await(self.Instance, "ProgressivePunishmentPassive")):expect()
	
	--applying any combo changes
	self.Janitor:Add(ProgressivePunishment.Changed:Connect(function(new: number, old: number)
		
		self:InterpolateDemonicAppearance(new / 5)
		
		if not ProgressivePunishment:IsComboActive() then
			return
		end
		
		--sounds playback
		if ProgressivePunishment:IsMaxCombo() then

			SoundUtility.CreateTemporarySound(
				SoundUtility.Sounds.Players.Combo.Final
			).Parent = self.Instance.HumanoidRootPart

		else

			local Sound = SoundUtility.CreateTemporarySound(
				SoundUtility.Sounds.Players.Combo.Increase
			)
			
			Sound.Parent = self.Instance.HumanoidRootPart
			Sound.PlaybackSpeed = 0.7 + new * 0.2
		end
	end))
end

--//Returner

return MissThavelAppearance