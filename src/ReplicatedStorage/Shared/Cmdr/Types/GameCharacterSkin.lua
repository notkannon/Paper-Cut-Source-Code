--//Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local Characters = require(ReplicatedStorage.Shared.Data.Characters)

--//Variables

local SkinMap = {}

--//Main
for _, CharacterData in pairs(Characters) do
	
	if not CharacterData.Skins
		or not next(CharacterData.Skins) then
		
		continue
	end

	SkinMap[CharacterData.Name] = TableKit.Keys(CharacterData.Skins)
	table.insert(SkinMap[CharacterData.Name], 1, "None")
	table.insert(SkinMap[CharacterData.Name], 1, "Default")
end

--//Cmdr Hook for live tracking typed command

local Interface

-- Отслеживание текущего текста команды (на клиенте)

if RunService:IsClient() then
	
	task.defer(function()
		
		local CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient"))
		Interface = CmdrClient:GetInterface()
	end)
end

--//Returner
return function(registry)
	
	registry:RegisterType("characterSkin", {
		
		Transform = function(text)
			return text
		end,

		Validate = function(value)
			return true
		end,

		Autocomplete = function(text)
			
			local args = {}
			
			for word in Interface:GetEntryText():gmatch("%S+") do
				table.insert(args, word)
			end
			
			-- Если аргументов меньше 3, значит characterName не выбран
			if #args < 3 then
				return {}
			end
			
			local characterName = args[3]
			
			if not SkinMap[characterName] then
				return {}
			end

			local suggestions = {}
			for _, skin in ipairs(SkinMap[characterName]) do
				if skin:lower():find(text:lower(), 1, true) == 1 then
					table.insert(suggestions, skin)
				end
			end

			return suggestions
		end,

		Parse = function(value)
			return value
		end,
	})
end