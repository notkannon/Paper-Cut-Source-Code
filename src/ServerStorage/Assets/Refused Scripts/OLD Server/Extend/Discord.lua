-- service
local Players = game:GetService('Players')
local Http = game:GetService('HttpService')

-- requirements
local GlobalSettings = require(game.ReplicatedStorage.GlobalSettings)

-- private fields
local AVATAR = 'https://media.discordapp.net/attachments/1117565724945305681/1248219859091984466/image.png?ex=666824d5&is=6666d355&hm=09b4ebd442708f8c0c8885c16ace3d8bf45fef11c2290359e73565d9df08ca66&=&format=webp&quality=lossless&width=618&height=361'
local AVATAR_RESPONCE = 'https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds=%s&size=420x420&format=Png&isCircular=true'
local private = {
	webhook = 'https://discord.com/api/webhooks/1250036561769271358/3l3NICIt_DlmlTeBa-peyAxJeUEX1fM80mgWbFI1KdWsvB4vvgTvDkvh64_WMuNqLIU2',
	source = 'Paper Cut',
}

local COLOR = {
	Admin = 'b6ce42',
	Extra = 'ff81b7',
	Interface = '96d05e',
}


-- discord lib initial
local Discord = {}

-- POST request to discord webhook (when player used cmdr command)
function Discord:LogCommand(
	command_group: string,
	command_name: string,
	executor: Player,
	command_string: string,
	command_args
)
	assert(executor, 'No executor provided')
	assert(command_string, 'No command string provided')
	
	-- request body init
	local body = {
		username = private.source,
		avatar_url = AVATAR,
		content = '',
		
		embeds = {{
			title = `{ executor.Name } used a command in-game - { command_name }`,
			description = '**Prompt**: `' .. tostring(command_string)
				.. '`\n**Timestamp**: <t:' .. DateTime.now().UnixTimestamp .. '>'
				.. '\n**Group Role**: `' .. executor:GetRoleInGroup(GlobalSettings.GroupId)
				.. '`\n**Group Rank**: `' .. executor:GetRankInGroup(GlobalSettings.GroupId) .. '`'
				.. '\n## Arguments:',
			
			color = tonumber('0x' .. COLOR[ command_group ]),
			thumbnail = { url = '' },
			fields = { },
			footer = {
				text = `{ executor.DisplayName } | @{ executor.Name } | { executor.UserId }`,
				icon_url = ''
			}
		}}
	}
	
	-- user thumbnail getting
	local avatar = ''
	local message = ''
	local attempt = 0

	while attempt < 3 do
		local success, async = pcall(function()
			local responce = AVATAR_RESPONCE:format(executor.UserId)
			local raw = Http:GetAsync(responce)
			local data = Http:JSONDecode(raw).data
			return data[1].imageUrl
		end)

		if success then
			avatar = async
			break
		else
			message = async
		end

		attempt += 1
	end
	
	-- avatar apply
	body.embeds[1].footer.icon_url = avatar or ''
	body.embeds[1].thumbnail.url = avatar or ''
	
	-- args parse
	for _, argument in ipairs(command_args) do
		table.insert(body.embeds[1].fields, {
			name = argument.Name:upper(),
			value = '`' .. argument.RawValue .. '`',
			inline = true
		})
	end
	
	-- attempt to POST
	local attempt = 0
	while attempt < 3 do
		local success, async = pcall(function()
			Http:PostAsync(
				private.webhook,
				Http:JSONEncode(body),
				Enum.HttpContentType.ApplicationJson
			)
		end)

		if success then break end
		attempt += 1
	end
end

-- complete
return Discord