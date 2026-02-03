--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

--local Cmdr = require(ReplicatedStorage.Packages.Cmdr) --FIXME: Cmdr Types
local GlobalSettings = require(ReplicatedStorage.Shared.Data.GlobalSettings)
local Logger = RunService:IsServer() and require(ServerScriptService.Server.Utility.Logger) or nil
local ThreadUtility = require(ReplicatedStorage.Shared.Utility.ThreadUtility)

--/Variables

local FailMessage = "You don't have permission to run this command."

--//Functions

local function Log(context)
	if RunService:IsServer() then
		ThreadUtility.UseThread(Logger.Log, context.Group, context.Name, context.Executor, context.RawText, context.Arguments)
	end
end

local function RetrieveGroupPermissionLevel(player: Player) : number?
	local GroupRole = player:GetRoleInGroup(game.CreatorId)
	return GlobalSettings.Cmdr.PassedGroupRoles[GroupRole]
end

local function RetrieveIDPermissionLevel(player: Player) : number?
	return GlobalSettings.Cmdr.PassedUserIds[player.UserId]
end

local function RetrievePermissionLevel(player: Player) : number
	local GroupPermissionLevel = RetrieveGroupPermissionLevel(player) or 0
	local IDPermissionLevel = RetrieveIDPermissionLevel(player) or 0
	return math.max(GroupPermissionLevel, IDPermissionLevel)
end

--//Returner

return function(registery) --: Cmdr.CmdrServer)
	registery:RegisterHook("BeforeRun", function(context)
		if RunService:IsStudio() then
			Log(context)
			return
		end

		if game.CreatorType ~= Enum.CreatorType.Group then
			return "Failed to validate permissions - game is not owned by a group!"
		end

		local ExecutorPermissionLevel = RetrievePermissionLevel(context.Executor)
		local RequiredPermissionLevel = GlobalSettings.Cmdr.RequiredPermissionLevels[context.Group]
		
		if RequiredPermissionLevel == 0 then
			if ExecutorPermissionLevel < 255 then
				return "Permissions for this command are not set up! Assuming it requires Operator level"
			end
			context:Reply("WARN: Permissions for this command are not set up!")
		end
		
		if ExecutorPermissionLevel < RequiredPermissionLevel then
			return FailMessage
		end
		
		Log(context)
		return
	end)
end
