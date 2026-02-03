local Client = shared.Client
local Requirements = Client._requirements

-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ContextActionService = game:GetService('ContextActionService')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')

-- Requirements
local PlayerObject = Client.Player
local CharacterView = Requirements.CharacterView
local ClientWcsController = Requirements.ClientWcsController
local RaycastHitbox = require(ReplicatedStorage.Package.RaycastHitboxV4)

-- character object getting
local CharacterObject = Client.Player.Character
if not CharacterObject then Client.Player.CharacterChanged:Wait() end
CharacterObject = Client.Player.Character
local Character: Model = CharacterObject.Instance

-- declaration
local OnHeavyAttackHeld
local AttackHoldStart
local AttackHoldEnd
local Setup

-- const
local HEAVY_ATTACK_HOLD_DURATION = .35

-- vars
local hitboxes = {} :: { main: any }

-- controls setting up
function Setup()
	ClientWcsController.SkillStarted:Connect(function(skill_name, ...)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			ClientWcsController:PromptSkill('Attack')
		end
	end)
end

-- main
Setup()