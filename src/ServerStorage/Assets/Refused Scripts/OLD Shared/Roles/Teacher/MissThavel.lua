-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Teams = game:GetService('Teams')

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local Server = game:GetService('ServerStorage'):FindFirstChild('Server')
local Animations = game.ReplicatedStorage.Assets.Animations.Teacher.MissBloomie -- REPLACE

-- role data
return {
	enum = Enums.GameRolesEnum.MissThavel,
	team = Teams.Teacher,
	
	name = 'Miss Thavel',
	moveset_name = 'MissThavel',
	descripton = '',
	
	skills_data = {
		Attack = {
			Cooldown = .97,
			SkillIcon = 'rbxassetid://17607926339'
		}
	},
	
	character = {
		morph = Server and Server.Instances.Morphs.MissThavel,
		DefaultWalkspeed = 11,
		
		animations = {
			{Instance = Animations.Sprinting,	Speed = 1.55,	Looped = true,	Priority = Enum.AnimationPriority.Action},
			{Instance = Animations.FreeFall,	Speed = 1,		Looped = true,	Priority = Enum.AnimationPriority.Action3},
			{Instance = Animations.Idling,		Speed = 1,		Looped = true,	Priority = Enum.AnimationPriority.Core},
			{Instance = Animations.Jump,		Speed = 2,		Looped = false,	Priority = Enum.AnimationPriority.Action2},
			{Instance = Animations.Walk,		Speed = 1,		Looped = true,	Priority = Enum.AnimationPriority.Idle},
			
			-- add
			{Instance = Animations.Attack1,		Speed = 1,		Looped = false, Priority = Enum.AnimationPriority.Action2},
			{Instance = Animations.Attack2,		Speed = 1,		Looped = false, Priority = Enum.AnimationPriority.Action2},
			{Instance = Animations.Attack3,		Speed = 1,		Looped = false, Priority = Enum.AnimationPriority.Action2}, -- test
		},
	}
}