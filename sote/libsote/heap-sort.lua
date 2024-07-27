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
---@param desc_primary boolean
---@param desc_secondary boolean
local function heapify_iterative(get_primary, get_secondary, indices, n, i, desc_primary, desc_secondary)
	while true do
		local largest = i
		local left = 2 * i + 1
		local right = 2 * i + 2

		if left < n then
			local l_index = indices[left]
			local i_index = indices[largest]
			local l_primary = get_primary(l_index)
			local i_primary = get_primary(i_index)

			if (get_secondary and l_primary == i_primary) then
				local l_secondary = get_secondary(l_index)
				local i_secondary = get_secondary(i_index)
				if (desc_secondary and l_secondary < i_secondary) or (not desc_secondary and l_secondary > i_secondary) then
					largest = left
				end
			elseif (desc_primary and l_primary < i_primary) or (not desc_primary and l_primary > i_primary) then
				largest = left
			end
		end

		if right < n then
			local r_index = indices[right]
			local l_index = indices[largest]
			local r_primary = get_primary(r_index)
			local l_primary = get_primary(l_index)

			if (get_secondary and r_primary == l_primary) then
				local r_secondary = get_secondary(r_index)
				local l_secondary = get_secondary(l_index)
				if (desc_secondary and r_secondary < l_secondary) or (not desc_secondary and r_secondary > l_secondary) then
					largest = right
				end
			elseif (desc_primary and r_primary < l_primary) or (not desc_primary and r_primary > l_primary) then
				largest = right
			end
		end

		if largest == i then
			break
		end

		swap(indices, i, largest)
		i = largest
	end
end

local ffi = require("ffi")

---@param get_primary fun(i:number):any
---@param get_secondary fun(i:number):any
---@param n number
---@param desc_primary boolean
---@param desc_secondary boolean
function hs.heap_sort_indices(get_primary, get_secondary, n, desc_primary, desc_secondary)
	desc_primary = desc_primary or false
	desc_secondary = desc_secondary or false
	local indices = ffi.new("uint32_t[?]", n)
	for i = 0, n - 1 do
		indices[i] = i
	end

	for i = math.floor(n / 2) - 1, 0, -1 do
		heapify_iterative(get_primary, get_secondary, indices, n, i, desc_primary, desc_secondary)
	end

	for i = n - 1, 0, -1 do
		swap(indices, 0, i)
		heapify_iterative(get_primary, get_secondary, indices, i, 0, desc_primary, desc_secondary)
	end

	return indices
end

return hs
