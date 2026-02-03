local TableKit = {}

--[=[
	This function "deep" copies a table, and all of its contents. This means that it will clone the entire table,
	and tables within that table- as opposed to shallow-copying with table.clone
	
	```lua
	local Dictionary = {
		SomethingInside = {
			A = 1,
			B = 2,
		},
	}
	
	local CopiedDictionary = TableKit.DeepCopy(Dictionary)
	
	print(CopiedDictionary) -- prints { ["SomethingInside"] = { ["A"] = 1, ["B"] = 1 } }
	```
	
	:::caution Recursive Function
	This function is recursive- this can cause stack overflows.

	@within TableKit
	@param tableToClone table
	@return table
]=]
function TableKit.DeepCopy<T>(tableToClone: { [unknown]: unknown }): T
	local clone = table.clone(tableToClone)
	for index, value in clone do
		if typeof(value) == "table" then
			clone[index] = TableKit.DeepCopy(value :: { [unknown]: unknown })
		end
	end
	return clone
end

--[=[
	This function merges two dictionaries.

	Keys *will* overwrite- if there are duplicate keys, dictionary2 will take priority.

	```lua
	local Dictionary = {
		A = 1,
		B = 2,
	}
	local SecondDictionary = {
		C = 3,
		D = 4,
	}
	
	print(TableKit.MergeDictionary(Dictionary, SecondDictionary)) -- prints { ["A"] = 1, ["B"] = 2, ["C"] = 3, ["D"] = 4 }
	```
	
	:::caution Potential overwrite
	Keys are overwritten when using .MergeDictionary()
	
	@within TableKit
	@param dictionary1 table
	@param dictionary2 table
	@return table
]=]
function TableKit.MergeDictionary<dictionary1, dictionary2>(
	dictionary1: { [unknown]: unknown },
	dictionary2: { [unknown]: unknown }
): dictionary1 & dictionary2
	local newTable = table.clone(dictionary1)

	for key, value in dictionary2 do
		newTable[key] = value
	end

	return newTable
end


--[=[
	@function DeepMerge
	@within TableKit

	Recursively merges two tables, copying values from `source` into `target` without discarding existing nested data.
	If both values under the same key are tables, they will be merged recursively.
	If a key exists only in `source`, it will be added.
	If the value in `target` is not a table, the value from `source` will overwrite it.

	Useful for cascading config construction.

	@param target table — The destination table to receive new or updated values.
	@param source table — The source table providing the values to merge.

	@return table — The updated `target` table (after merging).
]=]
function TableKit.DeepMerge(target, source)
	for key, sourceValue in pairs(source) do
		local targetValue = target[key]

		if typeof(sourceValue) == "table" and typeof(targetValue) == "table" then
			TableKit.DeepMerge(targetValue, sourceValue)
		elseif typeof(sourceValue) == "table" then
			target[key] = TableKit.DeepMerge({}, sourceValue)
		else
			target[key] = sourceValue
		end
	end

	return target
end


--[=[
	This function returns a table with the keys of the passed dictionary.
	
	```lua
	local Dictionary = {
		A = 1,
		B = 2,
		C = 3,
	}
	
	print(TableKit.Keys(Dictionary)) -- prints {"A", "B", "C"}
	```

	@within TableKit
	@param dictionary table
	@return table
]=]
function TableKit.Keys(dictionary: { [unknown]: unknown }): { unknown }
	local keyArray = {}

	for key in dictionary do
		table.insert(keyArray, key)
	end

	return keyArray
end

--[=[
	This function returns a table with the values of the passed dictionary.
	
	```lua
	local Dictionary = {
		A = 1,
		B = 2,
		C = 3,
	}
	
	print(TableKit.Values(Dictionary)) -- prints {1, 2, 3}
	```

	@within TableKit
	@param dictionary table
	@return table
]=]
function TableKit.Values<T>(dictionary: { [unknown]: T }): { T }
	local valueArray = {}

	for _, value in dictionary do
		table.insert(valueArray, value)
	end

	return valueArray
end

--[=[
	Merges two arrays; array2 will be added to array1- this means that the indexes of array1 will be the same.
	
	```lua
	local FirstArray = {"A", "B", "C", "D"}
	local SecondArray = {"E", "F", "G", "H"}
	
	print(TableKit.MergeArrays(FirstArray, SecondArray)) -- prints {"A", "B", "C", D", "E", "F", "G", "H"}
	```

	@within TableKit
	@param array1 table
	@param array2 table
	@return table
]=]
function TableKit.MergeArrays<a, b>(a: { unknown }, b: { unknown }): a & b
	local result = table.clone(a)
	table.move(b, 1, #b, #result + 1, result)
	return result
end

--[=[
	Deep-reconciles a dictionary into another dictionary.
	
	```lua
	local template = {
		A = 0,
		B = 0,
		C = {
			D = "",
		},
	}

	local toReconcile = {
		A = 9,
		B = 8,
		C = {},
	}
	
	print(TableKit.Reconcile(toReconcile, template)) -- prints { A = 9, B = 8, C = { D = "" }
	```

	@within TableKit
	@param original table
	@param reconcile table
	@return table
]=]
function TableKit.Reconcile(original: { [unknown]: unknown }, reconcile: { [unknown]: any })
	local tbl = table.clone(original)

	for key, value in reconcile do
		if tbl[key] == nil then
			if typeof(value) == "table" then
				tbl[key] = TableKit.DeepCopy(value)
			else
				tbl[key] = value
			end
		elseif typeof(reconcile[key]) == "table" then
			if typeof(value) == "table" then
				tbl[key] = TableKit.Reconcile(value, reconcile[key])
			else
				tbl[key] = TableKit.DeepCopy(reconcile[key])
			end
		end
	end

	return tbl
end

--[=[
    @function DeepReconcile
    @within TableKit

    Deeply reconciles two tables, preserving existing values in `target` while adding missing values from `source`.
    Unlike regular merge functions, this will NEVER overwrite existing non-nil values in the target table,
    and handles nested tables recursively.

    Key behaviors:
    1. If a key exists in both tables and both values are tables - merges them recursively
    2. If a key exists only in source - adds it to target
    3. If a key exists in target (even with nil) - preserves the target value
    4. Properly handles metatables and avoids circular references

    @param target {[any]: any} -- The table to reconcile into (values here take priority)
    @param source {[any]: any} -- The table to copy missing values from
    @return {[any]: any} -- Reconciled table (modified version of target)

    @example
    ```lua
    local base = {
        a = 1,
        b = {x = 1, y = 2},
        c = nil
    }

    local custom = {
        a = 99,       -- Won't overwrite (target has value)
        b = {y = 99}, -- Will merge recursively
        c = 3,        -- Will add (target has nil)
        d = 4         -- Will add (new key)
    }

    local result = TableKit.DeepReconcile(base, custom)
    -- result = {
    --    a = 1,       -- Preserved from base
    --    b = {x = 1, y = 2}, -- y remains 2 (from base)
    --    c = nil,     -- Preserved nil from base
    --    d = 4        -- Added from custom
    -- }
    ```
]=]
function TableKit.DeepReconcile(target: {[any]: any}, source: {[any]: any}): {[any]: any}
	-- Create a new table to avoid modifying the original target
	local result = table.clone(target)

	-- Track processed tables to avoid circular references
	local processed = {}

	local function reconcile(t, s)
		if processed[t] or processed[s] then return t end
		processed[t] = true
		processed[s] = true

		for key, sourceValue in pairs(s) do
			local targetValue = t[key]

			-- Only process if target doesn't have this key or it's nil
			if targetValue == nil then
				if typeof(sourceValue) == "table" then
					-- Deep copy tables to avoid reference sharing
					t[key] = TableKit.DeepCopy(sourceValue)
				else
					t[key] = sourceValue
				end
			elseif typeof(targetValue) == "table" and typeof(sourceValue) == "table" then
				-- Recursively reconcile nested tables
				reconcile(targetValue, sourceValue)
			end
			-- Else keep target value as-is
		end
		return t
	end

	return reconcile(result, source)
end

--[=[
	Detects if a table is an array, meaning purely number indexes and indexes starting at 1.
	
	```lua
	local Array = {"A", "B", "C", "D"}
	local Dictionary = { NotAnArray = true }
	
	print(TableKit.IsArray(Array), TableKit.IsArray(Dictionary)) -- prints true, false
	```

	@within TableKit
	@param mysteryTable table
	@return boolean
]=]
function TableKit.IsArray(mysteryTable: { [unknown]: unknown }): boolean
	local count = 0
	for _ in mysteryTable do
		count += 1
	end
	return count == #mysteryTable
end

--[=[
	Detects if a table is a dictionary, meaning it is not purely number indexes.
	
	```lua
	local Array = {"A", "B", "C", "D"}
	local Dictionary = { NotAnArray = true }
	
	print(TableKit.IsDictionary(Array), TableKit.IsDictionary(Dictionary)) -- prints false, true
	```

	@within TableKit
	@param mysteryTable table
	@return boolean
]=]
function TableKit.IsDictionary(mysteryTable: { [unknown]: unknown }): boolean
	local count = 0
	for _ in mysteryTable do
		count += 1
	end
	return count ~= #mysteryTable
end

--[=[
	Converts a table into a string.
	
	```lua
	local DictionaryA = {
		A = "Z",
		B = "X",
		C = "Y",
	}
	
	print(TableKit.ToString(DictionaryA)) -- prints {
							--			[A]: Z
							--			[C]: Y
							--			[B]: X
							--		 }
	```

	@within TableKit
	@param obj {}
	@return string
]=]
function TableKit.ToString(obj: { [unknown]: unknown }): string
	local result = {}
	for key, value in obj do
		local stringifiedKey
		if typeof(key) == "string" then
			stringifiedKey = `"{tostring(key)}"`
		else
			stringifiedKey = tostring(key)
		end

		local stringifiedValue
		local valueToString = tostring(value)
		if typeof(value) == "string" then
			stringifiedValue = `"{valueToString}"`
		else
			stringifiedValue = valueToString
		end

		local newline = `	[{stringifiedKey}] = {stringifiedValue}`
		table.insert(result, newline)
	end
	return "{\n" .. table.concat(result, "\n") .. "\n}"
end

function TableKit.ToArrayString(obj: { [number]: unknown }): string
	local result = {}
	for _, value in obj do
		local stringifiedValue
		local valueToString = tostring(value)
		if typeof(value) == "string" then
			stringifiedValue = `"{valueToString}"`
		else
			stringifiedValue = valueToString
		end

		table.insert(result, stringifiedValue)
	end
	return "{" .. table.concat(result, ", ") .. "}"
end

--[=[
	Takes in a data type, and returns it in array form.
	
	```lua
	local str = "Test"
	
	print(TableKit.From(str)) -- prints ("T", "e", "s", t")
	```

	@within TableKit
	@param value unknown
	@return { [number]: unknown }
]=]
function TableKit.From(value: any): { any }
	local valueType = typeof(value)
	if valueType == "string" then
		return string.split(value, "")
	elseif valueType == "Color3" then
		return { value.R, value.G, value.B }
	elseif valueType == "Vector2" then
		return { value.X, value.Y }
	elseif valueType == "Vector3" then
		return { value.X, value.Y, value.Z }
	elseif valueType == "NumberSequence" then
		return value.Keypoints
	elseif valueType == "Vector3int16" then
		return { value.X, value.Y, value.Z }
	elseif valueType == "Vector2int16" then
		return { value.X, value.Y }
	else
		return { value }
	end
end

--[=[
	Creates a shallow copy of an array, passed through a filter callback- if the callback returns false, the element is removed.
	
	```lua
	local str = {"a", "b", "c", "d", "e", "f", "g"}
	
	print(TableKit.Filter(str, function(value)
		return value > "c"
	end))
	-- prints {
 		[1] = "d",
 		[2] = "e",
 		[3] = "f",
 		[4] = "g"
 	}
	```

	@within TableKit
	@param arr { [number]: unknown }
	@param callback (value: value) -> boolean
	@return { [number]: unknown }
]=]
function TableKit.Filter<T>(arr: { [number]: T }, callback: (value: T) -> boolean)
	local tbl = {}

	for _, value in arr do
		if callback(value) then
			table.insert(tbl, value)
		end
	end

	return tbl
end

--[=[
	Loops through every single element, and puts it through a callback. If the callback returns true, the function returns true.
	
	```lua
	local array = {1, 2, 3, 4, 5}
	local even = function(value) return value % 2 == 0 end

	print(TableKit.Some(array, even)) -- Prints true
	```
	
	@within TableKit
	@param tbl table
	@param callback (value) -> boolean
	@return boolean
]=]
function TableKit.Some(tbl: { [unknown]: unknown }, callback: (value: unknown) -> boolean): boolean
	for _, value in tbl do
		if callback(value) == true then
			return true
		end
	end
	return false
end

--[=[
	Detects if a table has an embedded table as one of its members.
	
	```lua
	local Shallow = {"a", "b"}
	local Deep = {"a", {"b"}}
	
	print(TableKit.IsFlat(Shallow)) -- prints true
	print(TableKit.IsFlat(Deep)) -- prints false
	```
	
	@within TableKit
	@param tbl table
	@return boolean
]=]
function TableKit.IsFlat(tbl: { [unknown]: unknown }): boolean
	for _, v in tbl do
		if typeof(v) == "table" then
			return false
		end
	end
	return true
end

--[=[
	Loops through every single element, and puts it through a callback. If any of the conditions return false, the function returns false.
	
	```lua
	local array = {1, 2, 3, 4, 5}
	local even = function(value) return value % 2 == 0 end
	local odd = function(value) return value % 2 ~= 0 end
	
	print(TableKit.Every(array, even)) -- Prints false
	print(TableKit.Every(array, odd)) -- Prints false
	```
	
	@within TableKit
	@param tbl table
	@param callback (value) -> boolean
	@return boolean
]=]
function TableKit.Every(tbl: { [unknown]: unknown }, callback: (unknown) -> boolean): (boolean, unknown?)
	for key, value in tbl do
		if not callback(value) then
			return false, key
		end
	end
	return true
end

--[=[
	Detects if a dictionary has a certain key.
	
	```lua
	local Dictionary = {
		Hay = "A",
		MoreHay = "B",
		Needle = "C",
		SomeHay = "D",
	}
	
	print(TableKit.HasKey(Dictionary, "Needle")) -- prints true
	```
	
	@within TableKit
	@param dictionary table
	@param key unknown
	@return boolean
]=]
function TableKit.HasKey(dictionary: { [any]: unknown }, key: any): boolean
	return dictionary[key] ~= nil
end

--[=[
	Detects if a dictionary has a certain value.
	
	```lua
	local Array = { "Has", "this", "thing" }
	
	print(TableKit.HasValue(Array, "Has")) -- prints true
	```
	
	@within TableKit
	@param tbl table
	@param value unknown
	@return boolean
]=]
function TableKit.HasValue(tbl: { [unknown]: unknown }, value: unknown): boolean
	for _, v in tbl do
		if v == value then
			return true
		end
	end
	return false
end

--[=[
	Detects if a table is empty.
	
	```lua
	local Empty = {}
	local NotEmpty = { "Stuff" }
	
	print(TableKit.IsEmpty(Empty), TableKit.IsEmpty(NotEmpty)) -- prints true, false
	```

	@within TableKit
	@param mysteryTable table
	@return boolean
]=]
function TableKit.IsEmpty(mysteryTable: { [unknown]: unknown }): boolean
	return next(mysteryTable) == nil
end

-- PROVITIA PATCH

function TableKit.CompareTables(t1: {}, t2: {}, nilOk: boolean)
	--print('hi')
	if type(t1) ~= "table" or type(t2) ~= "table" then
		--print('fail 1', type(t1), type(t2))
		return false
	end
	if #t1 ~= #t2 then
		--print('fail 2', #t1, #t2)
		return false
	end
	for i, v in pairs(t1) do
		local w = t2[i]
		-- type check: if different types, then cooked
		if type(v) ~= type(w) then
			-- exception! ignore nil if nilOk is true
			if nilOk and (type(v) == "nil" or type(w) == "nil") then
				continue
			end
			--print('fail 3', type(v), type(w), nilOk)
			return false
		end

		-- if not tables (primitives), then just compare directly
		if type(v) ~= "table" then
			if w ~= v then
				--print('fail 4', type(v), type(w), w, v, w == v)
				return false
			end
		-- both tables, compare recursively
		elseif not TableKit.CompareTables(v, w, nilOk) then
			--print('fail 5')
			return false
		end
	end
	--print('success')
	return true
end

return table.freeze(TableKit)
