local function generate_unique_filename(logname)
	local timestamp = os.date("%Y%m%d%H%M%S") -- Generate a timestamp
	return logname .. "_" .. timestamp .. ".txt"
end

local logger = {}

function logger:new(logname, path)
	local new_logger = {}

	new_logger.file = assert(io.open((path or love.filesystem.getSaveDirectory()) .. "/" .. generate_unique_filename(logname), "w"))

	local sentinel = newproxy(true) -- need this hack since we're on lua 5.1, but it can be removed if we upgrade to 5.2 or beyond
	local mt = getmetatable(sentinel)
	mt.__gc = function()
		new_logger.file:close()
	end
	new_logger.sentinel = sentinel

	setmetatable(new_logger, self)
	self.__index = self

	return new_logger
end

function logger:log(message, do_flush)
	-- self.file:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. message .. "\n")
	self.file:write(message .. "\n")

	if do_flush == nil or do_flush then
		self.file:flush()
	end
end

local loggers = {}

local latlon_logger = nil

function loggers.get_latlon_logger(path)
	if latlon_logger == nil then
		latlon_logger = logger:new("latlon", path)
	end

	return latlon_logger
end

return loggers
