-- declarations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Enums = require(ReplicatedStorage.Enums).ItemTypeEnum

-- complete
return {
	cost = 19, -- points
	name = 'Paper Airplane',
	enum = Enums.PaperAirplane,
	icon = 'rbxassetid://17273948519',
	description = 'A basic tool for stun.',
	reference = game.ReplicatedStorage.Shared.Item.PaperAirplane -- a link to original item instance
}