local fu = {}

function fu.csv_rows(file_path)
	local file = io.open(file_path, "r")
	if not file then
		error("File not found: " .. file_path)
		return
	end

	-- Read and discard the first line
	local _ = file:read()

	return coroutine.wrap(function()
		for line in file:lines() do
			local values = {}
			for value in line:gmatch("[^,]+") do
				table.insert(values, value)
			end
			coroutine.yield(values)
		end
		file:close()
	end)
end

return fu