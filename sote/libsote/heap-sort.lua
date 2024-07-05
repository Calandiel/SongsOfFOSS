local hs = {}

---@param i number
---@param j number
local function swap(array, i, j)
	local temp = array[i]
	array[i] = array[j]
	array[j] = temp
end

---@param n number
---@param i number
---@param descending boolean
local function heapify_recursive(get_value, indices, n, i, descending)
	local largest = i
	local left = 2 * i + 1
	local right = 2 * i + 2

	if left < n and ((descending and get_value(indices[left]) < get_value(indices[largest])) or (not descending and get_value(indices[left]) > get_value(indices[largest]))) then
		largest = left
	end

	if right < n and ((descending and get_value(indices[right]) < get_value(indices[largest])) or (not descending and get_value(indices[right]) > get_value(indices[largest]))) then
		largest = right
	end

	if largest ~= i then
		swap(indices, i, largest)
		heapify_recursive(get_value, indices, n, largest, descending)
	end
end

---@param n number
---@param i number
---@param descending boolean
local function heapify_iterative(get_value, indices, n, i, descending)
	while true do
		local largest = i
		local left = 2 * i + 1
		local right = 2 * i + 2

		if left < n and ((descending and get_value(indices[left]) < get_value(indices[largest])) or (not descending and get_value(indices[left]) > get_value(indices[largest]))) then
			largest = left
		end

		if right < n and ((descending and get_value(indices[right]) < get_value(indices[largest])) or (not descending and get_value(indices[right]) > get_value(indices[largest]))) then
			largest = right
		end

		if largest == i then
			break
		end

		swap(indices, i, largest)
		i = largest
	end
end

-- Meant for 0-based indexed arrays
-- Takes a callback that returns the value at index i, sorts only the indices based on the values and returns the sorted indices

-- Iterative version seems to be much faster than the recursive version
-- for example, sorting just over 1M elements with the recursive version takes around 5s, while the iterative version takes under 1s
local heapify = heapify_iterative

local ffi = require("ffi")

---@param get_value fun(i:number):any
---@param n number
---@param descending boolean
function hs.heap_sort_indices(get_value, n, descending)
	descending = descending or false
	local indices = ffi.new("uint32_t[?]", n)
	for i = 0, n - 1 do
		indices[i] = i
	end

	for i = math.floor(n / 2) - 1, 0, -1 do
		heapify(get_value, indices, n, i, descending)
	end

	for i = n - 1, 0, -1 do
		swap(indices, 0, i)
		heapify(get_value, indices, i, 0, descending)
	end

	return indices
end

return hs