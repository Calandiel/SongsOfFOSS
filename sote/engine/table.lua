local tab = {}

---Clears a table
---@param table_to_clear table
function tab.clear(table_to_clear)
	for k, _ in pairs(table_to_clear) do
		table_to_clear[k] = nil
	end
end

--- Returns a shallow copy of a table
---@param input_table table
---@return table
function tab.copy(input_table)
	local ret = {}
	for i, j in pairs(input_table) do
		ret[i] = j
	end
	return ret
end

--- Prints a table (shallowly)
---@param table_to_print table
function tab.print(table_to_print)
	print(tostring(table_to_print) .. ' = {')
	for i, j in pairs(table_to_print) do
		print('  ' .. tostring(i) .. ': ' .. tostring(j) .. ',')
	end
	print('}')
end

--- Prints a table (deeply, gets stuck on loops!)
---@param table_to_print table
---@param depth string | nil
function tab.deep_print(table_to_print, depth)
	depth = depth or ""
	print(depth .. tostring(table_to_print) .. ' = {')
	for i, j in pairs(table_to_print) do
		if type(j) == "table" then
			print(depth .. '  ' .. tostring(i) .. " : ")
			tab.deep_print(j, depth .. "  ")
		else
			print(depth .. '  ' .. tostring(i) .. ': ' .. tostring(j) .. ',')
		end
	end
	print(depth .. '}')
end

---Given a table, iterate over ipairs and return a boolean for whether or not a value is in the table.
---@param table_to_check_for table
---@param value_to_check_for any
---@return boolean
function tab.contains(table_to_check_for, value_to_check_for)
	for _, v in ipairs(table_to_check_for) do
		if v == value_to_check_for then
			return true
		end
	end
	return false
end

---Returns the number of entries if iterated over with pairs, O(n)
---@param table_to_use table
---@return integer
function tab.size(table_to_use)
	local c = 0
	for _, _ in pairs(table_to_use) do
		c = c + 1
	end
	return c
end

---Returns n-th entry in a table when iterated over with pairs, O(n)
---1-indexed, like normal Lua tables.
---@generic K, T
---@param table_to_use table<K, T>
---@return K key, T|nil value
function tab.nth(table_to_use, n)
	local nth = 0
	for k, v in pairs(table_to_use) do
		nth = nth + 1
		if nth == n then
			return k, v
		end
	end
	return nil, nil
end

---@class (exact) WeightedEntry
---@field entry any
---@field weight number

---Given a number between 0 and 1, returns a weighted entry.
---@param number number
---@param items table<number, WeightedEntry>
function tab.select_one(number, items)
	local total_weight = 0
	for _, w in pairs(items) do
		total_weight = total_weight + w.weight
	end

	local weight_thus_far = 0
	for _, w in pairs(items) do
		weight_thus_far = weight_thus_far + w.weight
		if weight_thus_far / total_weight > number then
			return w.entry
		end
	end

	return items[1].entry
end

---Given a table of objects mapping to numbers (weights), return a randomly selected entry
---@generic T
---@param items table<T, number>
---@return T
function tab.random_select(items)
	local weight = 0
	for _, v in pairs(items) do
		weight = weight + v
	end

	if weight > 0 then
		local threshold = love.math.random() * weight
		local sum = 0
		for k, v in pairs(items) do
			sum = sum + v
			if sum >= threshold then
				return k
			end
		end
	end
	return tab.nth(items, 1)
end

---Given a table of objects mapping to <anything>, return a randomly selected key (equiprobable) and its value
---@generic K, V
---@param items table<K, V>
---@return K, V
function tab.random_select_from_set(items)
	local size = tab.size(items)
	local k, v = tab.nth(items, love.math.random(size))
	return k, v
end

---Given an array of objects, return a randomly selected value according to uniform distribution
---@generic V
---@param items V[]
---@return V|nil
function tab.random_select_from_array(items)
	local size = #items

	if size == 0 then
		return nil
	end

	return items[love.math.random(size)]
end

---Given a table and a function with parameter of table value type that resolves to a boolean,
---return a new table with all values that resolve to true
---@generic K, V
---@param items table<K, V>
---@param filter fun(a: V):boolean
---@return table<K, V>
function tab.filter(items, filter)
	local r = {}
	for k, v in pairs(items) do
		if filter(v) then
			r[k] = v
		end
	end
	return r
end

---Given a array and a function with parameter of table value type that resolves to a boolean,
---return a new table with all values that resolve to true
---@generic V
---@param items V[]
---@param filter fun(a: V):boolean
---@return V[]
function tab.filter_array(items, filter)
	local r = {}
	for k, v in pairs(items) do
		if filter(v) then
			table.insert(r, v)
		end
	end
	return r
end

---@generic V, K
---@param items V[]
---@param mapping fun(a: V):K
---@return K[]
function tab.map_array(items, mapping)
	local r = {}
	for k, v in pairs(items) do
		table.insert(r, mapping(v))
	end
	return r
end

---Given a table; an accumulable of any type; and an accumulator function with parameter the accumulable type,
---and the table's key and value types and returns an accumulable type, apply the function on each key value pair
---and return the accumulable.
---@generic A, K, V
---@param items table<K, V>
---@param accumulable A
---@param accumulator fun(a: A, k: K, v: V):A
---@return A
function tab.accumulate(items, accumulable, accumulator)
	local a = accumulable
	for k, v in pairs(items) do
		a = accumulator(a, k, v)
	end
	return a
end

---Maps values of a given table to according to a given mapping
---@generic S, T, V
---@param items table<S, T>
---@param mapping fun(k: T):V
---@return table<S, V>
function tab.map(items, mapping)
	---@type table
	local a = {}
	for k, v in pairs(items) do
		a[k] = mapping(items)
	end
	return a
end

---Given two tables of similar key-value pairs, insert all values from the second table into the first.
---Returns the first table with all values in both tables, where the second overwrites the first
---@generic K, V
---@param first table<K, V>
---@param second table<K, V>
---@return table<K, V>
function tab.join(first, second)
	for k,v in pairs(second) do
		first[k] = v
	end
	return first
end

---Given two arrays of similar value, insert all values from the second array into the first.
---Returns the first array with all values in both arrays
---@generic V
---@param first V[]
---@param second V[]
---@return V[]
function tab.join_arrays(first, second)
	for k, v in pairs(second) do
		table.insert(first, v)
	end
	return first
end

return tab
