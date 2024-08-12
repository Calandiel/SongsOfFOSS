local ph = {}

local function profile(func)
	local start = love.timer.getTime()
	func()
	local duration = love.timer.getTime() - start

	return duration
end

local function profiling_log(depth, prefix, log_text, duration)
	prefix = prefix .. " "

	depth = depth or 0
	for _ = 1, depth do
		prefix = prefix .. "\t"
	end

	return prefix .. log_text .. ": " .. string.format("%.2f", duration * 1000) .. "ms"
end

function ph.log_profiling_data(prof_data, prefix, log_text)
	local total_duration = 0
	for _, v in ipairs(prof_data) do
		total_duration = total_duration + v[1]
	end
	print(profiling_log(0, prefix, log_text .. " TOTAL", total_duration))
	for _, v in ipairs(prof_data) do
		print(v[2])
	end
end

function ph.profile_and_get(func, prefix, log_text, depth)
	local duration = profile(func)
	return duration, profiling_log(depth, prefix, log_text, duration)
end

function ph.run_with_profiling(func, prefix, log_text, depth)
	local _, log = ph.profile_and_get(func, prefix, log_text, depth)
	print(log)
end

return ph