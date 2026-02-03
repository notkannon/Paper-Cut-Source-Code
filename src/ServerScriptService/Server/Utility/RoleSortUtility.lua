--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local Classes = require(ReplicatedStorage.Shared.Classes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

local PlayerService = require(ServerScriptService.Server.Services.PlayerService)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)

--// Functions

local function GetSortedKillers(availableKillerRoles: { string })
	local HighestChance = 0
	local HighestChanceComponent

	local ChanceSorted = {}
	local SortedComponents = ComponentsUtility.GetAllPlayerComponents()
	local TargetKillerCount = math.clamp( math.round(#SortedComponents / 3), 1, #availableKillerRoles )

	--Step 1: getting highest teacher role players ignoring their role
	while #SortedComponents > 0 and #ChanceSorted < TargetKillerCount do

		for _, PlayerComponent in ipairs(SortedComponents) do
			local Chance = PlayerComponent:GetHighestKillerChance(availableKillerRoles)

			if Chance.chance >= HighestChance then
				HighestChanceComponent = PlayerComponent
				HighestChance = Chance.chance
			end
		end

		if not HighestChanceComponent and HighestChance == 0 then
			return {}
		end

		table.insert(ChanceSorted, HighestChanceComponent)
		table.remove(SortedComponents, table.find(SortedComponents, HighestChanceComponent))
	end

	--Step 2: Killer role assignment by sorted players
	local Result = {}
	local AssignedPlayers = {}
	local RolesAvailable = table.clone(availableKillerRoles)

	-- this is done so that players can play for each teacher equally, that is, if a player has not got the role of MissBloomie for 10 rounds -
	-- in a row, then with a huge chance he will play in the next round with this role
	while #AssignedPlayers < #ChanceSorted and #RolesAvailable > 0 do
		print("Roles available:", #RolesAvailable)
		
		local RoleChances = {} :: { [string]: {component: any, chance: number} }
		
		--step1: getting highest role chance among players
		for _, Role in ipairs(RolesAvailable) do
			RoleChances[Role] = {
				component = nil,
				chance = -1,
			}
		end
		
		for _, PlayerComponent in ipairs(ChanceSorted) do
			if table.find(AssignedPlayers, PlayerComponent.Instance) then
				continue
			end
			
			local PlayerHighestChance = PlayerComponent:GetHighestKillerChance(RolesAvailable)
			
			for Role, Data in pairs(RoleChances) do
				if PlayerHighestChance.role == Role and PlayerHighestChance.chance > Data.chance then
					RoleChances[Role].component = PlayerComponent
					RoleChances[Role].chance = PlayerHighestChance.chance
				end
			end
		end
		
		--step2: role assignment
		for Role, Data in pairs(RoleChances) do
			if not Data.component then
				continue
			end
			
			Result[Role] = Data.component
			
			table.insert(AssignedPlayers, Data.component.Instance)
			table.remove(RolesAvailable, table.find(RolesAvailable, Role))
		end
	end

	return Result
end

return {
	GetSortedKillers = GetSortedKillers,
}