local Util = {}


function Util.IsObject(object)
	if type(object) ~= 'table' then return end
	return getmetatable(object) ~= nil
end


function Util.DeepCopy(object)
	if type(object) ~= 'table' then return object end
	local copy = {}
	
	for k, v in pairs(object) do
		copy[k] = Util.DeepCopy(v)
	end
	
	return copy
end

function Util.DeepReconcile(original: { [unknown]: unknown }, reconcile: { [unknown]: any })
	local tbl = table.clone(original)

	for key, value in reconcile do
		if tbl[key] == nil then
			if typeof(value) == "table" then
				tbl[key] = Util.DeepCopy(value)
			else
				tbl[key] = value
			end
		elseif typeof(reconcile[key]) == "table" then
			if typeof(value) == "table" then
				tbl[key] = Util.DeepReconcile(value, reconcile[key])
			else
				tbl[key] = Util.DeepCopy(reconcile[key])
			end
		end
	end

	return tbl
end

function Util.Reconcile(original: { [unknown]: unknown }, reconcile: { [unknown]: any })
	local tbl = table.clone(original)

	for key, value in reconcile do
		if tbl[key] == nil then
			tbl[key] = value
		end
	end

	return tbl
end


function Util.Lerp(a: number?, b: number?, t: number)
	return a + (b - a) * t
end


function Util.SecondsToMS(s: number)
	return ("%02i:%02i"):format(s/60%60, s%60)
end


function Util.SecondsToDHM(s: number)
	local days = math.floor(s / 86400)
	local hours = math.floor(s % 86400 / 3600)
	local minutes = math.floor(s % 3600 / 60)
	
	return string.format("%dd %02dh %02dm", days, hours, minutes)
end


function Util.GetGUID()
	return game:GetService('HttpService'):GenerateGUID(false)
end

-- returns a list of players (excluding provided)
function Util.GetPlayersExcluding(...)
	local PlayersExcluding = table.pack(...)
	local Players = {}
	
	for _, player: Player in ipairs(game:GetService('Players'):GetPlayers()) do
		if table.find(PlayersExcluding, player) then continue end
		table.insert(Players, player)
	end
	
	return Players
end

return Util