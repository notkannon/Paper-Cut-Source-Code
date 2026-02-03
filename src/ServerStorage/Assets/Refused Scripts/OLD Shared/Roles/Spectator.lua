-- requirements
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Enums = require(ReplicatedStorage.Enums)

-- role data
return {
	enum = Enums.GameRolesEnum.Spectator,
	team = nil, -- neutral

	name = 'Spectator',
	descripton = '',

	character = {}
}