-- service
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Teams = game:GetService('Teams')

-- requirements
local Enums = require(ReplicatedStorage.Enums)
local Animations = ReplicatedStorage.Assets.Animations.Student

-- role data
return {
	enum = Enums.GameRolesEnum.Student,
	team = Teams.Student,
	
	name = 'Student',
	moveset_name = 'Student',
	descripton = '',
	
	character = {
		DefaultWalkspeed = 10,
		
		animations = {
			-- locker presence
			{Instance = Animations.Parent.Locker.PlayerEnter, Speed = 1, Looped = false, Priority = Enum.AnimationPriority.Action4},
			{Instance = Animations.Parent.Locker.PlayerLeave, Speed = 1, Looped = false, Priority = Enum.AnimationPriority.Action4},
			{Instance = Animations.Parent.Locker.PlayerIdle,  Speed = 1, Looped = true,  Priority = Enum.AnimationPriority.Action3},

			-- downed
			{Instance = Animations.DownedMovement,		Speed = 2,    Looped = true,  Priority = Enum.AnimationPriority.Movement},
			{Instance = Animations.DownedIdling,		Speed = 1,    Looped = true,  Priority = Enum.AnimationPriority.Idle},
			
			-- injured
			{Instance = Animations.InjuredSprinting,	Speed = 1.8,  Looped = true,  Priority = Enum.AnimationPriority.Action},
			{Instance = Animations.InjuredMovement,		Speed = 1.3,  Looped = true,  Priority = Enum.AnimationPriority.Movement},
			{Instance = Animations.InjuredIdling,		Speed = 1,    Looped = true,  Priority = Enum.AnimationPriority.Idle},
			
			-- crouching
			{Instance = Animations.CrouchMovement,		Speed = 2,    Looped = true,  Priority = Enum.AnimationPriority.Movement},
			{Instance = Animations.CrouchIdling,		Speed = 1,    Looped = true,  Priority = Enum.AnimationPriority.Idle},
			
			-- sprinting
			{Instance = Animations.Sprinting,			Speed = 1.45, Looped = true,  Priority = Enum.AnimationPriority.Action},
			
			-- default
			{Instance = Animations.Jump,				Speed = 1,	  Looped = false, Priority = Enum.AnimationPriority.Action2},
			{Instance = Animations.Land,				Speed = 1,	  Looped = false, Priority = Enum.AnimationPriority.Idle},
			{Instance = Animations.Walk,		  		Speed = 1,    Looped = true,  Priority = Enum.AnimationPriority.Idle},
			{Instance = Animations.Idling,  			Speed = 1,    Looped = true,  Priority = Enum.AnimationPriority.Core},
			{Instance = Animations.FreeFall,			Speed = 1,    Looped = true,  Priority = Enum.AnimationPriority.Action},
		},
	}
}