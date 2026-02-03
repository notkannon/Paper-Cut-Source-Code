local server = shared.Server
local requirements = server._requirements

-- requirements
local enumsModule = requirements.Enums
local globalSettings = requirements.GlobalSettings
local ReplicaService = requirements.ReplicaService
local ServerPlayer = requirements.ServerPlayer

-- declarations
local playerService = game:GetService('Players')
local GameRolesEnum = enumsModule.GameRolesEnum
local GameRoles = globalSettings.Roles
local GameModule

-- AliceEvent initial
local AliceEvent = {}
AliceEvent.last_time = 0

-- :p initial method
function AliceEvent:Init()
	GameModule = requirements.GameModule
end

-- returns true if event can start
function AliceEvent:CanStart()
end

-- OH NO
function AliceEvent:Run()
end

-- WE SAVED
function AliceEvent:Stop()
end

-- complete
AliceEvent:Init()
return AliceEvent