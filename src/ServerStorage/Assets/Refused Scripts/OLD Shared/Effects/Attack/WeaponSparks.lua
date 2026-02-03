local server = shared.Server
local client = shared.Client
local IS_CLIENT = client ~= nil

-- declarations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AttackSFX = game:GetService('SoundService').Master.Players.Attacks.Attack

-- getting refx module link
local Refx = require(ReplicatedStorage.Package.refx)
local WeaponSparksEffect = Refx.CreateEffect('WeaponSparks')

-- client only
function WeaponSparksEffect:OnStart(cframe: CFrame)
	local att = Instance.new('Attachment', workspace.Terrain)
	att.WorldCFrame = cframe

	for _, eff: ParticleEmitter in ipairs(ReplicatedStorage.Assets.Particles.HitSparks:GetChildren()) do
		local eff = eff:Clone()
		eff.Parent = att
		eff:Emit(math.random(7, 13))
	end

	local hit_sounds = game:GetService('SoundService').Master.Character.Attacks.Hit:GetChildren()
	local sound = hit_sounds[ math.random(1, #hit_sounds) ]:Clone()
	sound.Parent = att
	sound:Play()

	game:GetService('Debris'):AddItem(att, 5)
end

return WeaponSparksEffect