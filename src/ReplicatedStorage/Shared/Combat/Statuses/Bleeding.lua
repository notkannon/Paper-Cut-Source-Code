--//Services

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local BaseStatusEffect = require(ReplicatedStorage.Shared.Combat.Abstract.BaseStatusEffect)
local PlayerBleedingEffect = require(ReplicatedStorage.Shared.Effects.PlayerBleeding)

--//Variables

local Bleeding = WCS.RegisterStatusEffect("Bleeding", BaseStatusEffect)

--//Methods

function Bleeding.DamageTick(self: Status)
	if self.Character then
		self.Character.Humanoid.Health -= self.Damage

		-- do some kind of bleed effect
		self.Janitor:Add(PlayerBleedingEffect.new(self.Character.Instance), "Destroy"):Start(Players:GetPlayers())
	end
end

function Bleeding.OnEndServer(self: Status)
	BaseStatusEffect.OnEndServer(self)
	
	-- cuz last damage tick gets cut off for some reason
	self:DamageTick()
end

function Bleeding.OnStartServer(self: Status)
	BaseStatusEffect.OnStartServer(self)
	
	-- Bleeding does damage every damageInterval seconds, bypassing damage reduction effects
	self.Janitor:Add(task.spawn(function()
		while task.wait(self.DamageInterval) do
			self:DamageTick()
		end
	end))
end

function Bleeding.OnConstructServer(self: Status, damageInterval: number, damage: number)
	BaseStatusEffect.OnConstructServer(self)
	
	
	self.DestroyOnEnd = true
	self.DamageInterval = damageInterval or 1
	self.Damage = damage or 1
	
end

--//Returner

return Bleeding