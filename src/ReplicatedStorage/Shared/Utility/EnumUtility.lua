local function _NewEnum(manuals: {[string]: number}?, ...)
	local EnumItems = table.pack(...)
	
	local Enum = {
		GetIndexFromEnumItem = function(self, enumItem: string)
			for Item: string, Index: number in pairs(self) do
				if Item ~= enumItem or typeof(Index) == "function" then
					continue
				end

				return Index
			end
		end,

		GetEnumFromIndex = function(self, index: number)
			for Item: string, Index: number in pairs(self) do
				if Index ~= index or typeof(Index) == "function" then
					continue
				end

				return Item
			end
		end
	}
	
	for Index, EnumItem: string? in ipairs(EnumItems) do
		assert(typeof(EnumItem) == "string", "EnumItem can be only string")
		Enum[EnumItem] = Index
	end
	
	if manuals then
		for EnumItem: string, Index: number in pairs(manuals) do
			assert(typeof(EnumItem) == "string", "EnumItem can be only string")
			assert(typeof(Index) == "number", "Index can be only number")
			
			local _repeats = Enum:GetEnumFromIndex(Index)
			assert(not _repeats, `Detected same index for "{_repeats}" and "{ EnumItem }" enum items. Did you forget to set another?`)
			
			Enum[EnumItem] = Index
		end
	end
	
	return table.freeze(Enum)
end

local function NewEnum(...: string): {[string]: number}
	return _NewEnum(nil, ...)
end

local function NewManualEnum(manuals: {[string]: number}): {[string]: number}
	return _NewEnum(manuals)
end

return {
	NewEnum = NewEnum,
	NewManualEnum = NewManualEnum
}