-- declarations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Enums = require(ReplicatedStorage.Enums).ItemTypeEnum

-- complete
return {
	cost = 10, -- points
	name = 'Crayon',
	enum = Enums.Crayon,
	icon = 'rbxassetid://17273716264',
	description = 'A basic tool for stun.',
	reference = ReplicatedStorage.Shared.Item.Crayon -- a link to original item instance
}