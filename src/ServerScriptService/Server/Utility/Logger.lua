--//Services

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--//Imports

local GlobalSettings = require(ReplicatedStorage.Shared.Data.GlobalSettings)

--//Variables

local AVATAR_URL = "https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds=%s&size=420x420&format=Png&isCircular=true"
local WebhookUrl
local GotUrl = pcall(function()
	WebhookUrl = HttpService:GetSecret("CmdrLogsURL"):AddPrefix("https://discord.com/api/webhooks/") --ERROR: Can't find secret with given key
end)

--//Functions

local function Log(type: string, name: string, executor: Player, prompt: string)
	if not GotUrl or RunService:IsStudio() then
		return
	end

	local Avatar = HttpService:JSONDecode(HttpService:GetAsync(AVATAR_URL:format(executor.UserId))).data[1].imageUrl

	local Body = {
		embeds = {
			{
				color = tonumber("0x" .. GlobalSettings.Group.RoleColors[type]),
				thumbnail = {
					url = Avatar,
				},
				title = "Command Used",
				description = `{name} command used in-game by {executor.Name}.`,
				fields = {
					{
						name = "Prompt",
						value = `\`{prompt}\``,
					},
				},
				footer = {
					text = `{executor.DisplayName} | @{executor.Name} | {executor.UserId}`,
					icon_url = Avatar,
				},
				timestamp = DateTime.now():ToIsoDate(),
			},
		},
	}

	if game.CreatorType == Enum.CreatorType.Group and executor:IsInGroup(game.CreatorId) then
		table.insert(Body.embeds[1].fields, {
			name = "Group Role",
			value = executor:GetRoleInGroup(game.CreatorId),
		})
		
		table.insert(Body.embeds[1].fields, {
			name = "Group Rank",
			value = executor:GetRankInGroup(game.CreatorId),
		})
	end

	local PostSuccess, Message = pcall(function()
		return HttpService:PostAsync(WebhookUrl, HttpService:JSONEncode(Body), Enum.HttpContentType.ApplicationJson)
	end)
	
	if not PostSuccess then
		warn(`Failed to post {name} command log. {Message}`)
	end
end

--//Returner

return {
	Log = Log,
}
