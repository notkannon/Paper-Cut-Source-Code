local server = shared.Server
local client = shared.Client

local requirements = server
	and server._requirements
	or client._requirements

-- requirements
local Discord = server and require(game.ServerStorage.Server.Extend.Discord)
local globalSettings = require(game.ReplicatedStorage.GlobalSettings)
local enumsModule = requirements.Enums
local PlayerComponent = server
	and requirements.ServerPlayer
	or requirements.PlayerComponent

-- const & messages
local DEFAULT_CASE = "You don't have permission to run this command."

-- initial
return function( registry )
	registry:RegisterHook("BeforeRun", function(context)
		local executor: Player = context.Executor
		local userId: number = executor.UserId
		local commandGroup: string = context.Group
		local execRole: string = executor:GetRoleInGroup(globalSettings.GroupId)
		local execRank: number = executor:GetRankInGroup(globalSettings.GroupId)
		
		local bypassed = false
		
		if table.find(globalSettings.Cmdr.PassedUserIds, userId) then
			bypassed = true -- user passed check
		end
		
		if not bypassed then
			-- was granted?
			local has_rank = false -- player has same rank or higher?
			local has_role = false -- player has one of command whitelisted roles?
			local message = ' '
			
			-- run conditions
			local group_acccess = globalSettings.Cmdr.CommandGroupAccess[ context.Group ]
			has_role = table.find(group_acccess.roles, execRole) or has_role
			has_rank = execRank >= group_acccess.rank or has_rank
			
			-- no passed
			if not has_rank and not has_role then
				return DEFAULT_CASE
			end
		end
			
		-- log
		if Discord then
			task.spawn(function()
				Discord:LogCommand(
					context.Group,
					context.Name,
					executor,
					context.RawText,
					context.Arguments
				)
			end)
		end
		
		-- passed
		return nil
	end)
end