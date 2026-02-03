
--//Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Imports

local TableKit = require(ReplicatedStorage.Packages.TableKit)
local BaseCharacter = require(script.BaseCharacter)

--//Variables

local Characters = {} :: { [string]: BaseCharacter.CharacterData }

--//Performing

for _, Instance in ipairs(script:GetDescendants()) do
	
	--sorting only characters
	if not Instance:IsA("ModuleScript")
		or Instance.Parent:IsA("ModuleScript") then
		
		continue
	end
	
	local CharacterData = require(Instance) :: BaseCharacter.CharacterData
	
	if not CharacterData.Name then
		continue
	end
	
	assert(not Characters[CharacterData.Name], `Already registered character with name { CharacterData.Name }`)
	
	CharacterData = TableKit.DeepCopy(CharacterData)
	CharacterData.Skins = {
		
		-- default skin
		Default = {
			Name = "Default",
			Icon = CharacterData.Icon,
			Thumbnail = CharacterData.Thumbnail,
			Cost = 0,
			IsFree = true,
			IsForSale = true,
			FacePack = nil,
			SoundPack = nil,

		}
	}
	
	--collecting character skins data
	for _, SkinModule in ipairs(Instance:GetChildren()) do
		
		local SkinData = require(SkinModule)
		
		if not SkinData.Name then
			continue
		end
		
		CharacterData.Skins[SkinData.Name] = SkinData
	end
	
	if not CharacterData.AltIcons then
		CharacterData.AltIcons = {}
	end
	
	table.freeze(CharacterData)
	Characters[CharacterData.Name] = CharacterData
	
	--if CharacterData.Name == "Kenny" then
	--	print(CharacterData)
	--end
end

--//Returner

return table.freeze(Characters)