--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService("ServerScriptService")

--//Imports

local WCS = require(ReplicatedStorage.Packages.WCS)
local WCSUtility = require(ReplicatedStorage.Shared.Utility.WCSUtility)
local ComponentsManager = require(ReplicatedStorage.Shared.Classes.ComponentsManager)

--//Functions

local function GetStatusImplFromString(statusName: string): WCS.StatusEffectImpl?
	for _, Module in ipairs(ReplicatedStorage.Shared.Combat.Statuses:GetDescendants()) do
		if not Module:IsA("ModuleScript") then
			continue
		end

		local Impl = require(Module)
		if not Impl or tostring(Impl) ~= statusName then
			continue
		end

		return Impl
	end
end


function ParseMetadata(metadata: string, tablemode: boolean?) : table
	if tablemode == nil then tablemode = false end
	if #metadata == 0 then return {} end
	--[[ example format:
	 5:number;Multiply:string
	 should return
	 {5, "Multiply"}
	 Arguments are split by semicolons (;), value and types are separated by colons (:)
	 
	 table update!
	 input like this should be possible:
	 5:number;Multiply:string;{Tag=cool:string,FadeInTime=5:number}
	 NOTICE! SEPARATE ARGUMENTS BY COMMA IN TABLES, AND BY SEMICOLON OUTSIDE OF TABLES
	 this will still break if you have nested tables but its not worth fixing tbh
	]]
	local Result = {}
	local args
	if tablemode then
		args = string.split(metadata, ",")
	else
		args = string.split(metadata, ";")
	end
	for argumentIndex, argument in args do
		local value, proposedType, key
		if tablemode then
			key, argument = table.unpack(string.split(argument, "="))
		end
		if argument:sub(1, 1) == "{" then
			-- special case - we need a recursive call
			proposedType = "table"
			assert(argument:sub(-1, -1) == "}", `Unclosed curly brackets in argument {argumentIndex}`)
			value = ParseMetadata(argument:sub(2, -2), true)
		else
			value, proposedType = table.unpack(string.split(argument, ":"))
			-- TODO: support for more types
			if proposedType == "number" then
				value = tonumber(value)
			elseif proposedType == "string" then
				-- nothing, it's already a string
			elseif proposedType == "nil" then
				value = nil
			elseif proposedType == "bool" or proposedType == "boolean" then
				value = not not value
			end
		end

		if key == nil then 
			table.insert(Result, value)
		else
			Result[key] = value
		end
	end

	return Result
end

--//Returner

return function(context, players: { Player }, statusName: string, duration: number, metadata: string?)
	local success = 0
	local StatusEffectImpl = GetStatusImplFromString(statusName)
	assert(StatusEffectImpl, "Invalid status type provided")
	
	local Args = {}
	if metadata then
		Args = ParseMetadata(metadata)
	end

	for _, Player in ipairs(players) do
		local CharacterComponent = ComponentsManager.Get(Player.Character, "CharacterComponent")
		if not CharacterComponent then
			continue
		end
		
		local Status = StatusEffectImpl.new(CharacterComponent.WCSCharacter, table.unpack(Args))
		Status.DestroyOnEnd = true
		Status:Start(duration)
		
		success += 1
	end
	
	return `{ success } { statusName } statuses created.`
end