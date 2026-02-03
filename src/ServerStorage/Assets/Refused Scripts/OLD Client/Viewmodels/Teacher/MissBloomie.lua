local client = shared.Client
local requirements = client._requirements

-- paths
local camera = workspace.CurrentCamera
local RunService = game:GetService('RunService')
local UserInput = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local animations = ReplicatedStorage.Assets.Animations.Viewmodel
local Referece = ReplicatedStorage.Assets.Viewmodel.MissBloomie
local BaseViewmodel = require(script.Parent.ViewmodelBase)

-- BloomieViewmodel initial
local BloomieViewmodel = BaseViewmodel.new(Referece)
BloomieViewmodel.Enabled = false

--[[ viewmodel enabling function
function BloomieViewmodel:SetEnabled( enabled: boolean )
	if enabled == self.enabled then return end
	
	local CharacterObject = client.Player.Character
	if not CharacterObject then return end
	
	local character: Model = CharacterObject.Instance
	local humanoid: Humanoid = CharacterObject:GetHumanoid()
	
	-- enabling
	Viewmodel.Parent = enabled and workspace or nil
	BloomieViewmodel.enabled = enabled
	
	-- disabling
	if not enabled then
		RunService:UnbindFromRenderStep('@viewmodel')
		return
	else
		for _, AttackAnimation: Animation in ipairs(animations.MissBloomie.Attacks:GetChildren()) do
			table.insert(Attacks, Animator:LoadAnimation(AttackAnimation))
		end
		
		local track = Animator:LoadAnimation(animations.MissBloomie.Idle)
		track.Looped = true
		track:Play()
	end
	
	-- rendering connection
	RunService:BindToRenderStep('@viewmodel', Enum.RenderPriority.Camera.Value + 2, function(...)
		if not character then BloomieViewmodel:SetEnabled( false ) return end
		BloomieViewmodel:Update(...)
	end)
end]]


function BloomieViewmodel:TestAttack()
	print('Test attack')
--[[	local TestAttack = Attacks[ math.random(1, #Attacks) ]
	if TestAttack.Animation.Name == 'Attack2' then
		TestAttack.Priority = Enum.AnimationPriority.Action4
		TestAttack:Play(0, 1, 1.5)
	else
		TestAttack.Priority = Enum.AnimationPriority.Action4
		TestAttack:Play(0)
	end]]
end

BloomieViewmodel:Init()
return BloomieViewmodel