--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local BaseComponent = require(ReplicatedStorage.Shared.Classes.Abstract.BaseComponent)
local BaseConsumable = require(ReplicatedStorage.Shared.Components.Abstract.BaseItem.BaseConsumable)
local PlayerHealEffect = require(ReplicatedStorage.Shared.Effects.PlayerHeal)

local ModifiedSpeedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.ModifiedSpeed)

--//Variables

local OrangeItem = BaseComponent.CreateComponent("OrangeItem", {
	isAbstract = false,
}, BaseConsumable) :: BaseConsumable.Impl

--//Methods

function OrangeItem.OnEquipServer(self: BaseConsumable.Component)
	local Sound = SoundUtility.CreateTemporarySoundAtPosition(self.Character.PrimaryPart.Position, SoundUtility.Sounds.Instances.Items.Food.OrangeEquip)
	Sound.Parent = self.Character.PrimaryPart
	
end

function OrangeItem.OnUseServer(self: BaseConsumable.Component)
	
	if not self.Character then
		return -- Fixed bug when the student eat it
	end
	
	local Explosion = Instance.new("Explosion")
	Explosion.Parent = workspace.Temp
	Explosion.BlastRadius = 100
	Explosion.Position = self.Character.PrimaryPart.Position -- 🤯
	Explosion.BlastPressure = 0
	
	self.Janitor:Add(Explosion) -- >:)
	
	local PointLight = Instance.new("PointLight")
	PointLight.Parent = self.Character.PrimaryPart
	PointLight.Brightness = 10000
	PointLight.Range = 60
	PointLight.Enabled = true
	PointLight.Shadows = false
	
	self.Janitor:Add(PointLight)
	task.delay(0.35, function()
		if PointLight then
			PointLight:Destroy()
		end
	end)
	
	-- oh my god!
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Instances.Items.Food:FindFirstChild("GoshTHE HELL IS THAT")
	).Parent = self.Character.PrimaryPart
	
	SoundUtility.CreateTemporarySound(
		SoundUtility.Sounds.Instances.Items.Food:FindFirstChild("OrangeScreaming")
	).Parent = self.Character.PrimaryPart
	
	self.Character:FindFirstChildWhichIsA("Humanoid").Health -= 60
	
	PlayerHealEffect.new(self.Character, 7):Start(Players:GetPlayers())
	
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(self.Character) :: WCS.Character
	local speedboosted = ModifiedSpeedStatus.new(WCSCharacter, "Multiply", 2.5, {

		Tag = "OrangeBoosted",
		Priority = 7,
		FadeOutTime = 3,

	})
	
	speedboosted.DestroyOnFadeOut = true
	speedboosted.DestroyOnEnd = false
	speedboosted:Start(5)
end

--//Returner

return OrangeItem