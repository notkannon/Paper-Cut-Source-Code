--//Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local Signal = require(ReplicatedStorage.Packages.Signal)
local EnumUtil = require(ReplicatedStorage.Shared.Utility.EnumUtility)
local BaseRound = require(ServerScriptService.Server.Classes.BaseRound)
local RoundTypes = require(ServerScriptService.Server.Types.RoundTypes)

local Classes = require(ReplicatedStorage.Shared.Classes)
local ServerRemotes = require(ServerScriptService.Server.ServerRemotes)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)
local RoleSelectionComponent = require(ReplicatedStorage.Shared.Components.Matchmaking.RoleSelection)
local PlayerRoundStatsComponent = require(ReplicatedStorage.Shared.Components.Matchmaking.PlayerRoundStats)
local ItemService = require(ServerScriptService.Server.Services.ItemService)

local HideoutLimitedStatus = require(ReplicatedStorage.Shared.Combat.Statuses.Specific.Role.Student.HideoutLimited)

local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local SoundUtility = require(ReplicatedStorage.Shared.Utility.SoundUtility)
local ComponentsUtility = require(ReplicatedStorage.Shared.Utility.ComponentsUtility)
local HighlightPlayerEffect = require(ReplicatedStorage.Shared.Effects.HighlightPlayer)

local ShopService = require(ReplicatedStorage.Shared.Services.ShopService)
local RolesManager = require(ReplicatedStorage.Shared.Services.RolesManager)
local ItemService = require(ServerScriptService.Server.Services.ItemService)
local MapsManager = require(ServerScriptService.Server.Services.MapsManager)
local PlayerService = require(ServerScriptService.Server.Services.PlayerService)
local ObjectivesService = require(ServerScriptService.Server.Services.ObjectivesService)

local Selectors = require(ReplicatedStorage.Shared.Slices.PlayerData.Selectors)

local ServerProducer = RunService:IsServer() and require(ServerScriptService.Server.ServerProducer) or nil

--//Constants

local FREEZE_ON_STUDIO = true

local DEFAULT_ROUND_DURATION = 420

local USE_DEFAULT_ROUND_DURATION = false

-- A minimal player count to start or continue round
local MINIMAL_PLAYER_COUNT = 1

-- sometimes you want to have LMS off
local DO_LMS = false
local END_ROUNDS_IF_NO_TEACHERS = false

local DO_MAP_VOTING = false

--[[
--  The variables are unused because players can not join midmatch. However you might consider adding a case for leaving

-- If time value is equal or less than provided here then we won't apply LEFT_PLAYER_TIME_INCREMENT to it
local TIME_LOWER_VALUE = 60

-- When player joins the game we could increment a time of the round
local NEW_PLAYER_TIME_INCREMENT = 20

-- When player leaves the game we could decrement a time of the round
local LEFT_PLAYER_TIME_INCREMENT = -30
]]

--//Variables

local Round = BaseRound.CreateRound("Round")

--//Types

export type MyImpl = {

}

export type Fields = {

	IsLastManStanding: boolean,
	LastManStandingStarted: Signal.Signal<Player, {Player}>
}

export type Impl = RoundTypes.RoundImpl<nil, Fields, "Round">
export type Round = RoundTypes.Round<nil, Fields, "Round">

--//Methods

function Round.GetKillerCount(self: Round, playerCount: number): number

	local maxPlayers = 15
	local maxKillers = 3

	-- 1-5 plrs = 1 killer
	-- 6-10 plrs = 2 killers
	-- 11-15 plrs = 3 killers
	return math.clamp(math.ceil(playerCount * (maxKillers / maxPlayers)), 1, maxKillers)
end

function Round.GetPhaseDuration(self: Round): number

	if USE_DEFAULT_ROUND_DURATION then
		return DEFAULT_ROUND_DURATION
	end

	local nEP = #self.Service.GetEngagedPlayers()

	return 20 * math.round( 0.05 * (260 * math.sqrt(0.145 * nEP) + 60) ) + 60 - 30 * self:GetKillerCount(nEP)
end

function Round.CheckPlayerCountValid(self: Round): boolean
	return (RunService:IsStudio() and #self.Service.GetEngagedPlayers() >= 1) or #self.Service.GetEngagedPlayers() >= MINIMAL_PLAYER_COUNT
end

function Round.SubscribeMatchEvents(self: Round)

	--initing objectives
	self.Janitor:Add(ObjectivesService.ObjectiveCompleted:Connect(function(_, player, state)

		--time drain
		if state == "Success" then
			print(player.Name, "He maked his homework of miss circle :D.")

			self.Service:IncrementCountdown(-5, "ObjectiveSolved")
		end
	end))

	self.Janitor:Add(self.Service.PlayerDied:Connect(function(...)
		print(table.pack(...))

		self.Service:IncrementCountdown(10, "StudentDied")
	end))

	--called on any players changes
	local function OnPlayersStateChanged(state)

		--potential last man standing LMS (1 Student and 1 or more killers)
		if #state.Students == 1
			and state.InMatchCount > 1
			and not self.IsLastManStanding and DO_LMS then

			self.IsLastManStanding = true

			self:OnLastManStandingStart(state)

		elseif not RunService:IsStudio() and (#state.Students == 0 or #state.Killers == 0) and END_ROUNDS_IF_NO_TEACHERS then

			self.Janitor:Remove("NextPhaseTask")
			self.Janitor:Add(
				task.delay(
					1,
					self.Service._NextPhase,
					self.Service
				),

				nil,
				"NextPhaseTask"
			)
		end
	end

	--round players state control
	self.Janitor:Add(self.Service.PlayersChanged:Connect(OnPlayersStateChanged))

	--initial state
	--TODO: UNCOMMENT ON RELEASE
	OnPlayersStateChanged(self.Service:GetPlayersState())
end

function Round.AssignRoles(self: Round, killers: { Player })

	--getting all potentially Students
	local Students = {} :: { Player }

	for _, PlayerComponent in ipairs(ComponentsUtility.GetAllPlayerComponents()) do

		if not self.Service.IsPlayerEngaged(PlayerComponent.Instance) then
			continue
		end

		--filtering killers
		if table.find(killers, PlayerComponent.Instance) then
			continue
		end

		table.insert(Students, PlayerComponent.Instance)

	end

	--Role selection thing
	local KillerRoleSelectionInstance = Instance.new("Folder")
	KillerRoleSelectionInstance.Parent = ReplicatedStorage
	KillerRoleSelectionInstance.Name = "@roleselection"

	local KillerRoleSelection = self.Janitor:Add(
		ComponentsManager.Add(
			KillerRoleSelectionInstance,
			RoleSelectionComponent,
			killers,
			{
				MissCircle = { MaxPlayers = 1 },
				MissThavel = { MaxPlayers = 1 },
				MissBloomie = { MaxPlayers = 1 },
			}
		)
	)

	KillerRoleSelection.Janitor:Add(
		KillerRoleSelectionInstance
	)

	--Role selection thing
	local StudentRoleSelectionInstance = Instance.new("Folder")
	StudentRoleSelectionInstance.Parent = ReplicatedStorage
	StudentRoleSelectionInstance.Name = "@roleselection"

	local StudentAmount = #Students
	local ClassLimit = math.ceil((StudentAmount + 1) / 4) -- this ensures we never have a situation where the last player doesn't have a choice

	local StudentRoleSelection = self.Janitor:Add(
		ComponentsManager.Add(
			StudentRoleSelectionInstance,
			RoleSelectionComponent,
			Students,
			{
				Medic = { MaxPlayers = ClassLimit, ThumbnailKey = "ROLE", },
				Stealther = { MaxPlayers = ClassLimit, ThumbnailKey = "ROLE",} ,
				Troublemaker = { MaxPlayers = ClassLimit, ThumbnailKey = "ROLE", },
				Runner = { MaxPlayers = ClassLimit, ThumbnailKey = "ROLE", }
			}
		)
	)

	StudentRoleSelection.Janitor:Add(
		StudentRoleSelectionInstance
	)

	--starting role selection thing
	KillerRoleSelection:Start(5)
	StudentRoleSelection:Start(5)

	--subscribing to match events after roles distributed
	self.Janitor:Add(task.delay(6, self.SubscribeMatchEvents, self))
	self.Janitor:Add(task.delay(6, function()
		self.Service:SetCountdown(self.PhaseDuration)
	end))

	--distributing killer roles
	KillerRoleSelection.Completed:Once(function(result: { [string]: {Player} })
		for Choice, Players in pairs(result) do
			for _, Player in ipairs(Players) do

				--async call
				self.Janitor:Add(task.spawn(function()

					local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(Player)

					if not PlayerComponent then
						return
					end

					local Character = ShopService:GetCurrentCharacter(Player, "Student") 
					local Skin = ShopService:GetCurrentSkin(Player, Character) or "Default"

					--				print(Character, Skin, "Round")
					--					print(Skin, "252 Round")

					--applying currently equipped character and role
					PlayerComponent:SetRole("Teacher")
					PlayerComponent:SetCharacter(Choice, "Teacher")
					ServerProducer.SetMockData(Player.Name, "MockSkin", Skin)
					PlayerComponent:ResetCharacterMockData()
					PlayerComponent:ApplyRoleConfig()

					--					print(ShopService.PlayerItemsSaved[Player.Name])
				end))
			end
		end

		--cleanup role selection
		KillerRoleSelection:Destroy()
	end)

	--distributing Student roles
	StudentRoleSelection.Completed:Once(function(result: { [string]: {Player} })

		for Choice, Players in pairs(result) do
			for _, Player in ipairs(Players) do

				--async call
				self.Janitor:Add(task.spawn(function()

					local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(Player)

					if not PlayerComponent then
						return
					end

					--applying currently equipped character and role
					PlayerComponent:SetRole(Choice)

					-- randomized Student stuff (for when shop breaks)
					--local StudentNames = {}

					--for _, StudentModule in pairs(ReplicatedStorage.Shared.Data.Characters.Students:GetChildren()) do
					--	table.insert(StudentNames, StudentModule.Name)
					--end

					local Character = ShopService:GetCurrentCharacter(Player, "Student")  or "Claire" 
					local Skin = ShopService:GetCurrentSkin(Player, Character) or "Default"

					print(Character, Skin, "Round")

					PlayerComponent:SetCharacter(Character, "Student")
					ServerProducer.SetMockData(Player.Name,"MockSkin", Skin)
					PlayerComponent:ApplyRoleConfig()

				end))
			end
		end

		--cleanup role selection
		StudentRoleSelection:Destroy()
	end)
	
	-- btw this function isnt round start, this is choice start, so 5 of these 6 seconds are going to choice
	-- should be fine tho cuz you await
	self.Janitor:Add(task.delay(7, function()
		--TODO: givving the roundstats // this its because will add when its player selecting lmao XD
		for _, PlayerComponent in ComponentsUtility.GetAllPlayerComponents() do
			
			--adding round stats to everyone on round start
			if not ComponentsManager.Get(PlayerComponent.Instance, PlayerRoundStatsComponent) then
				ComponentsManager.Add(PlayerComponent.Instance, PlayerRoundStatsComponent)
			end

			--now we gonna add the items purchased before start the round
			if PlayerComponent:IsStudent() then
				local Player = PlayerComponent.Instance :: Player
				self.Janitor:AddPromise(ComponentsManager.Await(Player.Backpack, "InventoryComponent"):timeout(20):andThen(function(InventoryComponent)

					local Items = ShopService.PlayerItemsSaved[Player.Name].Items or {}
					if Items == {} then
						print("No Items Purchased")
						return
					end

					for ItemNamePrefix, ItemName in Items do

						print(ItemNamePrefix, ItemName, Player.Name)

						local ItemComponent = ItemService:CreateItem(ItemName, true)
						InventoryComponent:Add(ItemComponent, true) -- giving items with overstack

						Items[ItemNamePrefix] = nil

						print("Adding item: ".. ItemName, " To: ".. Player.Name)
					end
					ServerRemotes.ShopItemPayoutComplete.Fire(Player, {Items = Items})

					print("Added "..Player.Name.." Items Purchased")
				end), function()
					warn("Couldn't give out items to", Player.Name)
				end)
			end
		end
	end))
end

function Round.HandleChances(self: Round)

	--getting a list of players who shall be killer
	local Killers = {}

	--TODO: some players can be AFK
	local KillerCount = self:GetKillerCount(#self.Service.GetEngagedPlayers())

	--getting killer list

	-- LEGACY method: just pick people with the biggest teacher chance
	--local ChanceSorted = self.Service:GetChanceSortedPlayers("Default")
	--for x = 1, KillerCount do
	--	table.insert(Killers, ChanceSorted[x])
	--end

	-- MODERN: use chances as actual weights
	local function WeightedRandom(chanceTable)
		local poolsize = 0
		for _, v in pairs(chanceTable) do
			poolsize += v.Chance
		end

		local selection

		if poolsize == 0 then
			-- edgecase #1 - noone has any weights so we pick randomly
			local Index = math.random(1, #chanceTable)
			return {Index = Index, Value = chanceTable[Index].Player}
		elseif poolsize == 1 then
			-- edgecase #2 - since math.random(1, 1) errors out, we place 1 manually
			selection = 1
		else
			selection = math.random(1, poolsize)
		end

		for i, v in ipairs(chanceTable) do
			selection -= v.Chance
			if selection <= 0 then
				return {Index = i, Value = v.Player}
			end
		end
	end

	local PlayerChances = self.Service:GetPlayerChances("Default")
	for i = 1, KillerCount do
		local Result = WeightedRandom(PlayerChances)
		table.remove(PlayerChances, Result.Index)
		table.insert(Killers, Result.Value)
	end

	for _, Player in ipairs(self.Service.GetEngagedPlayers()) do
		local PlayerComponent = ComponentsUtility.GetComponentFromPlayer(Player)

		--chances handling (parallel call)
		self.Janitor:Add(task.spawn(function()

			--despawning from lobby
			PlayerComponent:Despawn()

			if table.find(Killers, PlayerComponent.Instance) then

				--setting player's role as Student but not respawning
				PlayerComponent:SetChance("Default", 0)

			else

				--increasing their chance
				PlayerComponent:SetChance("Default",
					PlayerComponent:GetChance("Default") + 1
				)
			end
		end))
	end

	return Killers
end

--makes game work like 1 Student VS few killers. No hideouts. Vaults are opened.
function Round.OnLastManStandingStart(self: Round, matchState)
	-- fire locally
	self.LastManStandingStarted:Fire(matchState.Students[1], matchState.Killers)

	--telling all clients to start LMS playback
	ServerRemotes.MatchServiceStartLMS.FireAll(#matchState.Killers)

	--highlighting last Student for all killers
	HighlightPlayerEffect.new(matchState.Students[1].Character, {
		mode = "Overlay",
		color = Color3.fromRGB(255, 217, 79),
		transparency = 0.7,
		lifetime = 5,
		fadeInTime = 2,
		fadeOutTime = 2,
		respectTargetTransparency = false
	}):Start(matchState.Killers)

	--highlighting all killers for last Student
	for _, Killer: Player in ipairs(matchState.Killers) do

		HighlightPlayerEffect.new(Killer.Character, {
			mode = "Overlay",
			color = Color3.fromRGB(227, 12, 12),
			transparency = 0.7,
			lifetime = 5,
			fadeInTime = 2,
			fadeOutTime = 2,
			respectTargetTransparency = false
		}):Start(matchState.Students)
	end
	
	for _, Objective in ObjectivesService.Objectives do
		ObjectivesService:_GraceDestroy(Objective)
	end

	--hideout handling
	local WCSCharacter = WCS.Character.GetCharacterFromInstance(matchState.Students[1].Character)
	local HiddenStatus = WCSUtility.GetAllActiveStatusEffectsFromString(WCSCharacter, "Hidden")[1]
	local HiddenComingStatus = WCSUtility.GetAllActiveStatusEffectsFromString(WCSCharacter, "HiddenComing")[1]

	if HiddenComingStatus then

		--cancelling player's hide attempt
		HiddenComingStatus:End()

	elseif HiddenStatus then

		local Hideout = ComponentsManager.GetFirstComponentInstanceOf(HiddenStatus.HideoutInstance, "BaseHideout")

		if Hideout then
			--removing player with panicking >:)
			Hideout:SetOccupant(nil, false, true)
		end
	end

	local LMSSongName = "1v1"
	if #matchState.Killers >= 3 then
		LMSSongName = "1v3"
	elseif #matchState.Killers == 2 then
		LMSSongName = "1v2"
	end

	local RoundLength = math.ceil(SoundUtility.Sounds.Music.LastStand.Teacher:FindFirstChild(LMSSongName).TimeLength) - 2
	
	if LMSSongName == "1v1" then
		RoundLength -= 1
	end

	local RoleConfig = RolesManager:GetPlayerRoleConfig(matchState.Students[1])

	--limiting player from hideout
	if RoleConfig.CharacterData 
		and RoleConfig.CharacterData.UniqueProperties 
		and RoleConfig.CharacterData.UniqueProperties.LMSPanickedDurationMultiplier then

		HideoutLimitedStatus.new(WCSCharacter):Start(RoundLength * RoleConfig.CharacterData.UniqueProperties.LMSPanickedDurationMultiplier)
	else
		HideoutLimitedStatus.new(WCSCharacter):Start()
	end

	self.Service:SetCountdown(RoundLength)
end

function Round.OnConstruct(self: Round)
	self.NextPhaseName = "Result"
	self.PhaseDuration = DEFAULT_ROUND_DURATION
	self.IsLastManStanding = false
	self.LastManStandingStarted = self.Janitor:Add(Signal.new())
end

function Round.OnStartServer(self: Round)
	-- freezing countdown
	if not RunService:IsStudio() and not FREEZE_ON_STUDIO then
		self.Service:ToggleCountdown(true) 
	end
	
	local function GetMapsNames()
		local MapNames: {string} = {}
		
		for _, Map in MapsManager:GetListOfMaps() do
			local Name = string.gsub(tostring(Map), "Map", "")
			table.insert(MapNames, Name)
			
			print(_, Map)
		end
		
		return MapNames
	end
	
	local function Proceed(map)
		self.Service:SetPreparing(true) -- blocks commands like `setround`
		
		self.Service:_SetMap(map)
		self.PhaseDuration = self:GetPhaseDuration()

		task.wait(2)

		-- loading map
		MapsManager:LoadMap(map.."Map")

		task.wait(10)

		if not RunService:IsStudio() and not FREEZE_ON_STUDIO then
			self.Service:ToggleCountdown(true) 
		end

		self.Service:SetPreparing(false) -- unblocks

		--distributing players roles
		self:AssignRoles(
			self:HandleChances()
		)
		
		--self.Service:SetCountdown(60)
	end
	
	local DefaultMap = "School"
	
	if DO_MAP_VOTING then
		-- TODO: a person can break the game if they were to run setround intermission during map voting
		-- unfortunately using :SetPreparing(true) creates a black screen that doesnt let you vote
		
		self.PhaseDuration = 60
		self.Service:SetCountdown(60)
		
		-- Mapping
		local MapsSelectionRoleInstance = Instance.new("Folder")
		MapsSelectionRoleInstance.Parent = ReplicatedStorage
		MapsSelectionRoleInstance.Name = "@mapselection"
		
		print(GetMapsNames())
		local MapsToVote = { "School", "Camping" }-- TODO: unhardcode in the future when we have >3 maps
		local SelectionTable = {}
		for _, map in MapsToVote do
			SelectionTable[map] = {MaxPlayers = #self.Service.GetEngagedPlayers(), ThumbnailKey = "MAP"}
		end
		
		local MapChosen
		local MapsSelection = self.Janitor:Add(
			ComponentsManager.Add(
				MapsSelectionRoleInstance,
				RoleSelectionComponent,
				self.Service.GetEngagedPlayers(),
				SelectionTable,
				"Vote on the map"
			)
		)

		MapsSelection.Janitor:Add(
			MapsSelectionRoleInstance
		)

		MapsSelection:Start(7)
		MapsSelection.Completed:Once(function(result: { [string]: {Player} })
			
			local MapsVotes = {}
			for _, map in MapsToVote do
				MapsVotes[map] = 0
			end
			
			local MostVotedMap
			local MostVotes = 0
			
			for MapChoiced, Player in result do
				local Votes = #Player
				MapsVotes[MapChoiced] += Votes
				
				if Votes > MostVotes then
					MostVotedMap = MapChoiced
					MostVotes = Votes
				end
			end
			
			if MostVotedMap then
				MapChosen = MostVotedMap
			else
				MapChosen = DefaultMap
			end
			
			--firing all players event to prepare
			print("Map Chosen: ", MapChosen)
			
			Proceed(MapChosen)
			
			-- cleaning up
			MapsSelectionRoleInstance:Destroy()
		end)
	else 
		Proceed(DefaultMap)
	end
end

function Round.OnEndServer(self: Round)
	
	--print(self.Service:GetPlayersWithRoundStats())

	for _, Player in self.Service:GetPlayersWithRoundStats() do
		local RoundStatComponent = ComponentsManager.GetFirstComponentInstanceOf(Player, "PlayerRoundStats")
		
		if not RoundStatComponent then
			warn('couldnt find RoundStats component for', Player)
		else
			RoundStatComponent:ProcessRoundEnd()
			--RoundStatComponent:UpdateAwardsToClient() UNUSED
		end
	end
	
	--resetting stuff
	self.IsLastManStanding = false
	self.Janitor:Cleanup()

	--removing all items
	ItemService:Cleanup()
end

function Round.ShouldStart(self: Round)
	return self:CheckPlayerCountValid()
end

--//Returner

return Round