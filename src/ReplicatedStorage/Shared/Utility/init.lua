--[[
	General utility, contains stuff that can be shared with most scripts
--]]

--//Imports

local ThreadUtility = require(script.ThreadUtility)

--//Variables

local StringToKeyCodeMap: { [string]: Enum.KeyCode } = {}

for _, EnumItem in ipairs(Enum.KeyCode:GetEnumItems()) do
	StringToKeyCodeMap[EnumItem.Name] = EnumItem
end

--//Functions

local function CreateIdGenerator(defaultId: number?)
	local Id = defaultId or 0

	local IdGenerator = table.freeze({
		NextId = function()
			Id += 1
			return Id
		end,

		GetId = function()
			return Id
		end,

		IncrementId = function(amount: number?)
			if not amount then
				Id = 0
				return
			end

			Id = Id - amount
		end,

		ResetId = function()
			Id = defaultId or 0
		end,
	})

	return IdGenerator
end

local function AddPaths(path: Instance)
	for _, Module in ipairs(path:GetDescendants()) do
		if not Module:IsA("ModuleScript") then
			continue
		end
		
		ThreadUtility.UseThread(require, Module)
	end
end

local function ApplyParams(Instance: Instance, params: { [string]: any })
	for Index, Value in pairs(params) do
		local Success = pcall(function()
			return Instance[Index]
		end)

		assert(Success, `{Index} is not a valid Instance property.`)

		Instance[Index] = Value
	end
	
	return Instance
end

local function GetModelMass(model: Model)
	local Mass = 0

	for _, Part in ipairs(model:GetDescendants()) do
		if not Part:IsA("BasePart") then
			continue
		end

		Mass += Part:GetMass()
	end

	return Mass
end

local function StringToKeyCode(key: string)
	return StringToKeyCodeMap[key]
end

local function GetAttributed(instance: Instance, tag: string, recursive: boolean?): { Instance }
	local Instances = {}

	for _, Child: Instance in ipairs(recursive and instance:GetDescendants() or instance:GetChildren()) do
		if Child:GetAttribute(tag) ~= nil then
			table.insert(Instances, Child)
		end
	end

	return Instances
end

local function FindFirstAttributed(instance: Instance, tag: string, recursive: boolean?): Instance?
	return GetAttributed(instance, tag, recursive)[1]
end

local function ShuffleTable(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(1, i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

--//Returner

return {
	CreateIdGenerator = CreateIdGenerator,
	AddPaths = AddPaths,
	ApplyParams = ApplyParams,
	GetModelMass = GetModelMass,
	ShuffleTable = ShuffleTable,
	GetAttributed = GetAttributed,
	StringToKeyCode = StringToKeyCode,
	FindFirstAttributed = FindFirstAttributed,
}