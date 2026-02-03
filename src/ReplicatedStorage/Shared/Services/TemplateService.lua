--// Services

local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports

local Signal = require(ReplicatedStorage.Packages.Signal)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Classes = require(ReplicatedStorage.Shared.Classes)

--// Variables
local TemplateService = Classes.CreateSingleton("TemplateService", false) :: Singleton

--// Constants

local GENERAL_RICH_COLORS = {
	green = "rgb(0, 255, 0)",
	red = "rgb(255, 0, 0)",
	blue = "rgb(0, 0, 255)",
	yellow = "rgb(255, 255, 0)",
	cyan = "rgb(0, 255, 255)",
	orange = "rgb(255, 150, 0)",
	grey = "rgb(156, 156, 156)",
	gray = "rgb(156, 156, 156)"
}

local CUSTOM_SPECIFIERS = {
	"<PERCENTAGE>",
	"<PERCENTAGE_DIFF>", -- no need to type color version, will be checked in code
	"<PERCENTAGE_DIFF_VERBOSE>"
}

--// Types

export type FormattedValue = number | string

export type MyImpl = {
	__index: MyImpl,

	GetName: () -> "TemplateService",
	GetExtendsFrom: () -> nil,
	IsImpl: (self: Singleton) -> boolean,
	
	FindPropertyValue: (self: Singleton, ContextTable: {}, Property: string) -> FormattedValue?,
	_RenderCustomSpecifier: (self: Singleton, Text: string, Specifier: string, Value: FormattedValue, ReturnOnlyResponse: boolean?) -> string, 
	_HandleColorSpecifier: (self: Singleton, Text: string, Specifier: string, Value: FormattedValue) -> string,
	
	RenderText: (self: Singleton, Text: string, Properties: {string}, ContextTable: {}) -> string, -- the highest level function, does the main thing
	TransformTagToRich: (self: Singleton, Text: string ) -> string,

	new: () -> Singleton,
	OnConstruct: (self: Singleton) -> (),
	OnConstructServer: (self: Singleton) -> (),
	OnConstructClient: (self: Singleton) -> (),
}

export type Fields = {
	Janitor: Janitor.Janitor, 
}

export type Singleton = typeof(setmetatable({} :: Fields, {} :: MyImpl))

--// Methods

function TemplateService.FindPropertyValue(self: Singleton, ContextTable: {}, Property: string)
	local PathTable = string.split(Property, ".")
	local CurrentTable = ContextTable
	
	--print(ContextTable, Property)

	for i = 1, #PathTable do
		CurrentTable = CurrentTable[PathTable[i]]

		if not CurrentTable then
			return nil
		end
	end

	return CurrentTable
end

function TemplateService.OnConstruct(self: Singleton) -- A Ok
	-- adding colored version to the registry: <PERCENTAGE_DIFF> -> <PERCENTAGE_DIFF_COLOR>
	for _, Specifier in CUSTOM_SPECIFIERS do
		if Specifier:match("COLOR") then continue end
		local Base = Specifier:sub(1, -2)
		local Colored = Base .. "_COLOR>"
		local Colored2 = Base .. "_COLOR_REVERSE>"
		if not table.find(CUSTOM_SPECIFIERS, Colored) then
			table.insert(CUSTOM_SPECIFIERS, Colored)
		end
		if not table.find(CUSTOM_SPECIFIERS, Colored2) then
			table.insert(CUSTOM_SPECIFIERS, Colored2)
		end
	end
end

function TemplateService._RenderCustomSpecifier(self: Singleton, Text: string, Specifier: string, Value: FormattedValue, ReturnOnlyResponse: boolean?)
	local Response = nil
	
	if Specifier == "<PERCENTAGE_DIFF>" then 
		Value = math.round(100 * Value - 100)
		if Value > 0 then
			Response = tostring(Value) .. "%%"
		else
			Response = tostring(Value) .. "%%"
		end
	elseif Specifier == "<PERCENTAGE_DIFF_VERBOSE>" then
		Value = 100 * Value - 100 
		Response = tostring(math.round(math.abs(Value))) .. "%%"
		
		if Value > 0 then
			Response ..= " more"
		elseif Value < 0 then
			Response ..= " less"
		end
	elseif Specifier == "<PERCENTAGE>" then
		Value *= 100
		Response = tostring(math.round(Value)) .. "%%"
	else
		error(`Unknown Specifier {Specifier}`)
	end
	
	if ReturnOnlyResponse then
		return Response
	else
		return Text:gsub("%%", "%%%%") -- % compensation
			:gsub(Specifier, tostring(Response), 1)
	end
end

function TemplateService._HandleColorSpecifier(self: Singleton, Text: string, Specifier: string, Value: FormattedValue)
	-- what this does is that it's called when you see <PERCENTAGE_DIFF_COLORED>, it renders <PERCENTAGE_DIFF> and wraps it in color
	
	local NormalVersion = Specifier:split("_COLOR")[1] .. ">"
	local RenderedText = self:_RenderCustomSpecifier(Text, NormalVersion, Value, true)
	local IsReverse = Specifier:find("REVERSE") ~= nil
	
	assert(tonumber(Value))
	
	
	if (Value > 1 and not IsReverse) or (Value < 1 and IsReverse) then
		RenderedText = "<green>" .. RenderedText .. "</green>"
	elseif (Value < 1 and not IsReverse) or (Value > 1 and IsReverse) then
		RenderedText = "<red>" .. RenderedText .. "</red>"
	else
		
	end
	
	RenderedText = RenderedText:gsub("%%", "%%%%") -- % compensation
	
	-- string.format doesnt like % a lot :skull:
	-- LOL
	return Text:gsub(Specifier, RenderedText, 1)
end

function TemplateService.RenderText(self: Singleton, Text: string, Properties: {string}, ContextTable: {})
	local PropertyValues = {}
	
	-- step 1. get values
	for _, Property in Properties do
		table.insert(PropertyValues, self:FindPropertyValue(ContextTable, Property))
	end
	
	-- step 2. check and render for custom specifiers
	
	-- Preprocess: sort words by length (longest first) for proper matching
	-- this is actually optional if we dont have intersecting Specifiers like "dog" and "do" so ill comment
	--table.sort(words, function(a, b)
	--	return #a > #b
	--end)

	local Matches = {}
	local i = 1
	local TextLen = #Text

	while i <= TextLen do
		local found = false
		for _, word in ipairs(CUSTOM_SPECIFIERS) do
			if string.sub(Text, i, i + #word - 1) == word then
				--table.insert(Matches, {pos = i, word = word})
				table.insert(Matches, word)
				i = i + #word -- jump past the matched word
				found = true
				break
			end
		end
		if not found then
			i = i + 1 -- move to next character
		end
	end
	
	--print(Text, PropertyValues)
	for i, Match in ipairs(Matches) do
		--print(Match, "found")
		local Method = if string.find(Match, "COLOR") then self._HandleColorSpecifier else self._RenderCustomSpecifier
		Text = Method(self, Text, Match, PropertyValues[1])
		table.remove(PropertyValues, 1)
	end
	
	if PropertyValues and #PropertyValues > 0 then
		-- step 3. string format the rest
		Text = string.format(Text, table.unpack(PropertyValues))
	end
	
	Text = Text:gsub("%%%%", "%%")
	
	-- step 4. convert color tags to richtext format
	return self:TransformTagToRich(Text)
end


function TemplateService.TransformTagToRich(self: Singleton, Text: string)
	local UnCodedText = "<(.-)>(.-)</%1>"
	--Text = Text:gsub("%%", "%%%%") -- cuz this function eats away benign % signs, avoiding early formatting
	return Text:gsub(UnCodedText, function(ColorTag, RestOfText)
		local TextColor = GENERAL_RICH_COLORS[ColorTag:lower()]
		if not TextColor then
			return RestOfText
		else
			return string.format("<font color='%s'>%s</font>", TextColor, RestOfText)
		end
	end)
end

--// Returner
local Singleton = TemplateService.new()
return Singleton :: Singleton