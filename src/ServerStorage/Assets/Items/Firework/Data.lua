-- declarations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Enums = require(ReplicatedStorage.Enums).ItemTypeEnum

-- complete
return {
	cost = 35, -- points
	name = 'Firework',
	enum = Enums.Firework,
	icon = 'rbxassetid://15814714233',
	description = 'Item for stunning teachers. In addition to stunning, it imposes additional effects in the form of confetti on the screen, which closes their view for a few seconds.',
	reference = game.ReplicatedStorage.Shared.Item.Firework -- a link to original item instance
}