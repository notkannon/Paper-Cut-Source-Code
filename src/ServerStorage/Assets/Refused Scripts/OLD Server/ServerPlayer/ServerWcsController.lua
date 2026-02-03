local server = shared.Server

-- requirements
local WCS = server:Require(game.ReplicatedStorage.Package.wcs, 'WCS')
local WCSServer = WCS.CreateServer()
local WCSCharacter = WCS.Character

-- ServerWcsController initial
local Initialized = false
local ServerWcsController = {}
ServerWcsController.wcs_server_object = WCSServer

-- running WCS server
function ServerWcsController:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	WCSServer:RegisterDirectory(game.ReplicatedStorage.Shared.Skill.StatusEffects)
	WCSServer:RegisterDirectory(game.ReplicatedStorage.Shared.Skill.SkillSets)
	WCSServer:Start()
end

-- complete
return ServerWcsController