--- To be used for loading data exported from sote 0.2, for debugging purposes

local imported_coordinates_hash = {}

local function loadDataFromFile(filename)
	local file = io.open(filename, "r")

	if not file then
		error("Could not open file: " .. filename)
	end

	for line in file:lines() do
		local values = {}
		for value in line:gmatch("%-?%d+%.?%d*") do
			table.insert(values, value)
		end

		-- Assuming the first two values are x and y coordinates
		local x, y = tonumber(values[1]), tonumber(values[2])

		-- Store all values in the hash table
		imported_coordinates_hash[x] = imported_coordinates_hash[x] or {}
		local numeric_values = {}
		for i = 3, #values do
			numeric_values[i - 2] = tonumber(values[i])
		end
		imported_coordinates_hash[x][y] = numeric_values
	end

	file:close()
end

local function getValuesForCoordinates(x, y)
	return imported_coordinates_hash[x] and imported_coordinates_hash[x][y] or nil
end

return {
	loadDataFromFile = loadDataFromFile,
	getValuesForCoordinates = getValuesForCoordinates
}