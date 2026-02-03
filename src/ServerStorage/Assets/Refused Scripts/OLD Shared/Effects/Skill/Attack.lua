local server = shared.Server
local client = shared.Client
local IS_CLIENT = client ~= nil

-- declarations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AttackSFX = game:GetService('SoundService').Master.Players.Attacks.Attack

-- getting refx module link
local Refx = require(ReplicatedStorage.Package.refx)
local AttackEffect = Refx.CreateEffect('Attack')

-- client only
function AttackEffect:OnStart(character: Model)
	if not character then warn('No character provided to start effect') return end
	
	local NewSFX: Sound = AttackSFX:FindFirstChild(`Swing{ math.random(1, 3) }`):Clone()
	NewSFX.Parent = character.HumanoidRootPart
	NewSFX:Play()
	
	-- sound cleanup
	NewSFX.Ended:Once(function() NewSFX:Destroy() end)
	
	--[[for _, emitter: ParticleEmitter in ipairs(script.Particle:GetChildren()) do
		local newEmitter = emitter:Clone()
		newEmitter.Parent = rig:FindFirstChild('HumanoidRootPart')
		newEmitter:Emit( 3 )
		game:GetService('Debris'):AddItem(newEmitter, 5)
	end]]
end

return AttackEffect