export type BanCard = {
	user_id: number,
	date: number,
	duration: number,
	reason: string,
	active: boolean
}

local server = shared.Server
local requirements = server._requirements

-- requirements
local DatastoreService = game:GetService('DataStoreService')
local MessagingService = game:GetService('MessagingService')
local Http = game:GetService('HttpService')
local Players = game:GetService('Players')

local ServerPlayer = requirements.ServerPlayer
local Util = requirements.Util

-- declaration
local Datastore = DatastoreService:GetDataStore('BannedPlayers')
local GLOBAL_BAN_TOPIC = 'PlayerBan'

--local functions
local function KickWithMessage(player_to_kick: Player, reason: string, duration: number)
	if not player_to_kick or not player_to_kick:IsDescendantOf(Players) then return end
	player_to_kick:Kick(`You were banned on this experience ({ Util.SecondsToDHM(duration) } left). Reason: {reason}.`)
end

local function GetDuratonFromDays(days: number) return days * 86400 end
local function Now() return DateTime.now().UnixTimestamp end -- returns current Unix timestamp


-- BanService initial
local Initialized = false
local BanService = {}

-- initial method
function BanService:Init()
	if Initialized then return end
	self._Initialized = true
	Initialized = true
	
	-- pre-connected players check
	for _, player: Player in ipairs(Players:GetPlayers()) do
		local ban_info = BanService:IsUserBanned(player.UserId)
		if not ban_info then continue end

		KickWithMessage(
			player,
			ban_info.reason,
			(ban_info.date + ban_info.duration) - Now() -- getting time left to unban
		)
	end
end

-- (async) unbans user (if was banned) removes card from datastore
function BanService:UnbanUser(user_id: number)
	local unbanned, log = pcall(function()
		local exists = Datastore:GetAsync(`plr_{ user_id }`)
		assert(exists, `No card to unban exists for user_id: { user_id }`)
		
		-- removing active status
		exists.active = false
		
		-- removing card from datastore (we may know if player was banned)
		Datastore:SetAsync(`plr_{ user_id }`, exists)
	end)
	
	-- failed
	if not unbanned then
		warn('[Ban Service]', log)
	end
end

-- (async) bans provided player
function BanService:BanUser(user_id: number, ban_length: number, ban_reason: string)
	assert(typeof(user_id) == 'number', `Wrong user_id provided ({ user_id })`)
	assert(typeof(ban_length) == 'number', `Wrong ban_length provided ({ ban_length })`)
	
	ban_reason = ban_reason and tostring(ban_reason):sub(1, 256) or 'No reason'
	local player_exists
	
	-- getting target player
	for _, player: Player in ipairs(Players:GetPlayers()) do
		if player.UserId ~= user_id then continue end
			
		-- kicking player from the game
		KickWithMessage(
			player,
			ban_reason,
			ban_length
		)
		
		player_exists = true
		break
	end
	
	--[[ we already kicked player from the game (TODO: Integrate this command to discord bot to live-ban system)
	if not player_exists then
		print('Messaging servers to kick player')

		-- PLAYER NOT FOUND, WE SHOULD SEND REQUEST TO ANOTHER SERVERS
		MessagingService:PublishAsync(
			GLOBAL_BAN_TOPIC,

			Http:JSONEncode({
				user_id = user_id,
				ban_length = ban_length,
				ban_reason = ban_reason
			})
		)
	end]]
	
	-- attempting to add banned player to datastore
	local banned = false
	local attempt = 0
	local log
	
	while attempt < 3 and task.wait(5) do
		banned, log = pcall(function()
			attempt += 1
			
			-- registering new ban card for player
			Datastore:SetAsync(`plr_{ user_id }`, {
				user_id = user_id,
				date = Now(),
				duration = ban_length,
				reason = ban_reason,
				active = true
			})
		end)
	end
end

-- handles global API request
function BanService:HandleAsync(message)
	print('SOME MESSAGE HANDLED', message)
	local ban_data = Http:JSONDecode(message.Data)
	
	-- poll extracting
	local user_id = ban_data.user_id
	local ban_length = ban_data.ban_length
	local ban_reason = ban_data.ban_reason
	
	-- attempting to ban player
	local banned = false
	local attempt = 0
	local log

	-- getting target player
	for _, player: Player in ipairs(Players:GetPlayers()) do
		if player.UserId ~= user_id then continue end

		-- kicking player from the game
		KickWithMessage(
			player,
			ban_reason,
			ban_length
		)
		
		break
	end
end

-- (async) returns true
function BanService:IsUserBanned(user_id: number)
	local success, card: BanCard? = pcall(function()
		return Datastore:GetAsync(`plr_{ user_id }`)
	end)
	
	if success then
		-- no player banned (no card or inactive)
		if not card or not card.active then return end
		
		-- card exists but player can be unbanned
		if Now() - card.date >= card.duration then
			BanService:UnbanUser(user_id) -- player is passed ban duration and can be free now
		else
			return card -- player still banned
		end
	else
		-- error occured
		warn('[Ban Service]', card)
	end
end

-- connections
MessagingService:SubscribeAsync(GLOBAL_BAN_TOPIC, function(...) BanService:HandleAsync(...) end)
Players.PlayerAdded:Connect(function(player)
	local ban_info = BanService:IsUserBanned(player.UserId)
	if not ban_info then return end
	
	KickWithMessage(
		player,
		ban_info.reason,
		(ban_info.date + ban_info.duration) - Now() -- getting time left to unban
	)
end)

-- complete
return BanService