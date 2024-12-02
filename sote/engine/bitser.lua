--[[
Copyright (c) 2020, Jasmijn Wellner

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
]]

local VERSION = '1.1'

local floor = math.floor
local pairs = pairs
local type = type
local insert = table.insert
local getmetatable = getmetatable
local setmetatable = setmetatable

local ffi = require("ffi")
---@type number
local buf_pos = 0
---@type number | nil
local buf_size = -1
local buf = nil
local writable_buf = nil
---@type number | nil
local writable_buf_size = nil
local SEEN_LEN = {}

---@class (exact) BitserCallback
---@field callback fun(value: any, seen: any, counter: any): Queue<BitserCallback>
---@field value any
---@field seen boolean

local function Buffer_prereserve(min_size)
	if buf_size < min_size then
		buf_size = min_size
		buf = ffi.new("uint8_t[?]", buf_size)
	end
end

local function Buffer_clear()
	buf_size = -1
	buf = nil
	writable_buf = nil
	writable_buf_size = nil
end

local function Buffer_makeBuffer(size)
	if writable_buf then
		buf = writable_buf
		buf_size = writable_buf_size
		writable_buf = nil
		writable_buf_size = nil
	end
	buf_pos = 0
	Buffer_prereserve(size)
end

local function Buffer_newReader(str)
	Buffer_makeBuffer(#str)
	ffi.copy(buf, str, #str)
end

local function Buffer_newDataReader(data, size)
	writable_buf = buf
	writable_buf_size = buf_size
	buf_pos = 0
	buf_size = size
	buf = ffi.cast("uint8_t*", data)
end

local function Buffer_reserve(additional_size)
	while buf_pos + additional_size > buf_size do
		buf_size = buf_size * 2
		local oldbuf = buf
		buf = ffi.new("uint8_t[?]", buf_size)
		ffi.copy(buf, oldbuf, buf_pos)
	end
end

local function Buffer_write_byte(x)
	Buffer_reserve(1)
	buf[buf_pos] = x
	buf_pos = buf_pos + 1
end

local function Buffer_write_raw(data, len)
	Buffer_reserve(len)
	ffi.copy(buf + buf_pos, data, len)
	buf_pos = buf_pos + len
end

local function Buffer_write_string(s)
	Buffer_write_raw(s, #s)
end

local function Buffer_write_data(ct, len, ...)
	Buffer_write_raw(ffi.new(ct, ...), len)
end

local function Buffer_ensure(numbytes)
	if buf_pos + numbytes > buf_size then
		error("malformed serialized data")
	end
end

local function Buffer_read_byte()
	Buffer_ensure(1)
	if not buf then
		error('buf is nul during serialization!')
	end
	local x = buf[buf_pos]
	buf_pos = buf_pos + 1
	return x
end

local function Buffer_read_string(len)
	Buffer_ensure(len)
	local x = ffi.string(buf + buf_pos, len)
	buf_pos = buf_pos + len
	return x
end

local function Buffer_read_raw(data, len)
	ffi.copy(data, buf + buf_pos, len)
	buf_pos = buf_pos + len
	return data
end

local function Buffer_read_data(ct, len)
	return Buffer_read_raw(ffi.new(ct), len)
end

local resource_registry = {}
local resource_name_registry = {}
local class_registry = {}
local class_name_registry = {}
local classkey_registry = {}
local class_deserialize_registry = {}

local serialize_value

local function write_number(value, _)
	if floor(value) == value and value >= -2147483648 and value <= 2147483647 then
		if value >= -27 and value <= 100 then
			--small int
			Buffer_write_byte(value + 27)
		elseif value >= -32768 and value <= 32767 then
			--short int
			Buffer_write_byte(250)
			Buffer_write_data("int16_t[1]", 2, value)
		else
			--long int
			Buffer_write_byte(245)
			Buffer_write_data("int32_t[1]", 4, value)
		end
	else
		--double
		Buffer_write_byte(246)
		Buffer_write_data("double[1]", 8, value)
	end

	return require "engine.queue":new()
end

local function write_string(value, _)
	if #value < 32 then
		--short string
		Buffer_write_byte(192 + #value)
	else
		--long string
		Buffer_write_byte(244)
		write_number(#value)
	end
	Buffer_write_string(value)
end

local function write_nil(_, _)
	Buffer_write_byte(247)
end

local function write_boolean(value, _)
	Buffer_write_byte(value and 249 or 248)
end


---commenting
---@param value table
---@return string
local function get_classname(value)
	return (class_name_registry[value.class] -- MiddleClass
		or class_name_registry[value.__baseclass]    -- SECL
		or class_name_registry[getmetatable(value)]  -- hump.class
		or class_name_registry[value.__class__]      -- Slither
		or class_name_registry[value.__class])       -- Moonscript class
end

local function write_table(value, seen, tables_counter)
	-- print("write_table")
	---@type Queue<BitserCallback>
	local callback_queue = require "engine.queue":new()

	local classkey
	local classname = get_classname(value)

	if classname then

		classkey = classkey_registry[classname]
		Buffer_write_byte(242)
		serialize_value(classname, seen)
	else
		Buffer_write_byte(240)
	end

	local len = #value
	callback_queue:enqueue({
		callback = write_number,
		value = len,
		seen = seen
	})
	-- write_number(len, seen)
	for i = 1, len do
		callback_queue:enqueue({
			callback = serialize_value,
			value = value[i],
			seen = seen
		})
		-- serialize_value(value[i], seen)
	end
	local klen = 0
	for k in pairs(value) do
		if (type(k) ~= 'number' or floor(k) ~= k or k > len or k < 1) and k ~= classkey then
			klen = klen + 1
		end
	end
	callback_queue:enqueue({
		callback = write_number,
		value = klen,
		seen = seen
	})
	-- write_number(klen, seen)
	for k, v in pairs(value) do
		if (type(k) ~= 'number' or floor(k) ~= k or k > len or k < 1) and k ~= classkey then
			-- if type(v) ~="table" and type(v) ~= "number" then
			-- 	print(k, v)
			-- end
			callback_queue:enqueue({
				callback = serialize_value,
				value = k,
				seen = seen
			})
			callback_queue:enqueue({
				callback = serialize_value,
				value = v,
				seen = seen
			})
			-- serialize_value(k, seen)
			-- serialize_value(v, seen)
		end
	end

	-- print("queue length " .. callback_queue:length())
	return callback_queue
end

local function write_cdata(value, seen)
	local ty = ffi.typeof(value)
	if ty == value then
		-- ctype
		Buffer_write_byte(251)
		serialize_value(tostring(ty):sub(7, -2), seen)
		return
	end
	-- cdata
	Buffer_write_byte(252)
	serialize_value(ty, seen)
	local len = ffi.sizeof(value)
	write_number(len)
	Buffer_write_raw(ffi.typeof('$[1]', ty)(value), len)
end

local types = {
	number = write_number,
	string = write_string,
	table = write_table,
	boolean = write_boolean,
	["nil"] = write_nil,
	cdata = write_cdata
}


---Serializes a value
---@param value any
---@param seen any
---@return Queue<BitserCallback>
serialize_value = function(value, seen, tables_counter)
	--print(value)
	if seen[value] then
		local ref = seen[value]
		if ref < 64 then
			--small reference
			Buffer_write_byte(128 + ref)
		else
			--long reference
			Buffer_write_byte(243)
			write_number(ref, seen)
		end
		return require "engine.queue":new()
	end
	local t = type(value)
	if t ~= 'number' and t ~= 'boolean' and t ~= 'nil' and t ~= 'cdata' then
		seen[value] = seen[SEEN_LEN]
		seen[SEEN_LEN] = seen[SEEN_LEN] + 1
	end
	if resource_name_registry[value] then
		local name = resource_name_registry[value]
		if #name < 16 then
			--small resource
			Buffer_write_byte(224 + #name)
			Buffer_write_string(name)
		else
			--long resource
			Buffer_write_byte(241)
			write_string(name, seen)
		end
		return require "engine.queue":new()
	end

	-- if t == 'table' then
	-- callback_stack:enqueue_front({
	-- 	callback = types[t] or error("cannot serialize type " .. t),
	-- 	value = value, seen = seen
	-- })
	-- else
	-- 	(types[t] or error("cannot serialize type " .. t))(value, seen)
	-- end
	local res = (types[t] or
		error("cannot serialize type " .. t)
	)(value, seen, tables_counter)

	if res == nil then
		return require "engine.queue":new()
	else
		return res
	end
end

local function serialize(value)
	---@type Queue<Queue<BitserCallback>>
	local callback_stack = require "engine.queue":new()

	Buffer_makeBuffer(64 * 8388608) --4096)
	local seen = { [SEEN_LEN] = 0 }
	print("Value serialization...")
	-- callback_stack:enqueue_front({ callback = serialize_value, value = value, seen = seen })
	local first = serialize_value(value, seen)
	callback_stack:enqueue_front(first)
	-- print(first:length())

	while callback_stack:length() > 0 do
		-- print(callback_stack:length())
		---@type Queue<BitserCallback>
		local callback_queue = callback_stack:peek()
		if (callback_queue == nil) or (callback_queue:length() == 0) then
			-- print("queue is empty")
			callback_stack:dequeue()
		else
			-- print("queue is not empty, continue")
			local callback = callback_queue:dequeue()
			local queue = callback.callback(callback.value, callback.seen)
			callback_stack:enqueue_front(queue)
		end
	end

	print("Value serialization ended!")
end

local function serialize_async(value)
	---@type Queue<Queue<BitserCallback>>
	local callback_stack = require "engine.queue":new()

	Buffer_makeBuffer(64 * 8388608) --4096)
	local seen = { [SEEN_LEN] = 0 }
	print("Value serialization...")
	-- callback_stack:enqueue_front({ callback = serialize_value, value = value, seen = seen })
	local first = serialize_value(value, seen)
	callback_stack:enqueue_front(first)


	local objects_counter = {
		counter = 0,
		yielded = false
	}

	while callback_stack:length() > 0 do
		---@type Queue<BitserCallback>
		local callback_queue = callback_stack:peek()
		if (callback_queue == nil) or (callback_queue:length() == 0) then
			-- print('callback queue is empty')
			-- print(callback_queue)
			callback_stack:dequeue()
		else
			local callback = callback_queue:dequeue()
			-- print(callback.value)
			-- print("stack before callback: " .. callback_stack:length())
			local queue = callback.callback(callback.value, callback.seen, objects_counter)
			-- print("extracted queue length: " .. queue:length())
			callback_stack:enqueue_front(queue)
			-- print("stack after callback: " .. callback_stack:length())
		end

		if (not objects_counter.yielded) and (objects_counter.counter % 1000 == 0) then
			coroutine.yield(objects_counter.counter)
			-- print("callback stack length: " .. callback_stack:length())
			objects_counter.yielded = true
		end
	end

	print("Value serialization ended!")
end

local function add_to_seen(value, seen)
	insert(seen, value)
	return value
end

local function reserve_seen(seen)
	insert(seen, 42)
	return #seen
end

local function table_field_setter(value)
	return function(table, field)
		table[field] = value
	end
end


local INVALID_RESPONCE = "#$@#%@!@#"

local function set_table_length()
	return function()

	end
end

local function read_number(seen)
	local t = Buffer_read_byte()
	if t < 128 then
		--small int
		return t - 27
	elseif t == 245 then
		--long int
		return Buffer_read_data("int32_t[1]", 4)[0]
	elseif t == 246 then
		--double
		return Buffer_read_data("double[1]", 8)[0]
	elseif t == 250 then
		--short int
		return Buffer_read_data("int16_t[1]", 2)[0]
	end
	return INVALID_RESPONCE
end

local function read_string(seen)
	local t = Buffer_read_byte()
	-- print(t)
	if t < 192 then
		--small reference
		return seen[t - 127]
	elseif t < 224 then
		--small string
		return add_to_seen(Buffer_read_string(t - 192), seen)
	elseif t == 243 then
		--reference
		return seen[read_number(seen) + 1]
	elseif t == 244 then
		--long string
		local length = read_number(seen)
		return add_to_seen(Buffer_read_string(length), seen)
	end
end

---@class (exact) TableReader
---@field data table
---@field array_length number|nil
---@field current_array_index number
---@field dict_length number|nil
---@field current_dict_index number
---@field current_key any
---@field current_mode "await init" | "await array value" | "await dict key" | "await dict value" | nil
---@field classname string|nil
---@field classkey any
---@field class any
---@field deserializer any

---comment
---@param table_reader TableReader
---@param value any
local function TableReaderApplyValue(table_reader, value, verbose)
	-- print(value)
	if table_reader.current_mode == 'await array value' then
		if verbose then
			LOGS:write("array value detected: \t ")
			LOGS:write(tostring(value))
			LOGS:write("\n")
			LOGS:flush()
		end

		if verbose then
			LOGS:write("update_index\t")
			LOGS:flush()
		end
		table_reader.current_array_index = table_reader.current_array_index + 1
		if verbose then
			LOGS:write("set table at index to value\t")
			LOGS:flush()
		end
		table_reader.data[table_reader.current_array_index] = value
		if verbose then
			LOGS:write("reset table mode\n")
			LOGS:flush()
		end
		table_reader.current_mode = nil
		return
	end

	if table_reader.current_mode == 'await dict key' then
		if verbose then
			LOGS:write("key detected: \t ")
			LOGS:write(tostring(value))
			LOGS:write("\n")
			LOGS:flush()
		end
		table_reader.current_key = value
		table_reader.current_mode = "await dict value"
		return
	end

	if table_reader.current_mode == 'await dict value' then
		if verbose then
			LOGS:write("value detected: \t ")
			LOGS:write(value)
			LOGS:write("\n")
			LOGS:write("table[" .. tostring(table_reader.current_key) .. "] = \t ")
			LOGS:write(tostring(value))
			LOGS:write("\n")
			LOGS:flush()
		end
		table_reader.data[table_reader.current_key] = value
		table_reader.current_dict_index = table_reader.current_dict_index + 1
		table_reader.current_mode = nil
		return
	end
end

local function deserialize(seen, verbose)
	local queue         = require "engine.queue":new()
	---@type Queue<TableReader>
	local tables_queue  = require "engine.queue":new()
	while true do
		local current_table = tables_queue:peek()

		if verbose and  current_table ~= nil then
			LOGS:write("\t" .. tostring(current_table.current_key) ..
			"\t \t" .. tostring(current_table.current_array_index) .. "/" .. tostring(current_table.array_length) ..
			"\t" .. tostring(current_table.current_dict_index) .. "/" .. tostring(current_table.dict_length) ..
			"\t" .. tostring(current_table.current_mode))
			LOGS:write("\n")
			LOGS:flush()
		end

		if current_table == nil
			or current_table.current_mode == 'await array value'
			or current_table.current_mode == 'await dict key'
			or current_table.current_mode == 'await dict value'
		then

			local t = Buffer_read_byte()
			if (verbose) then
				LOGS:write(t)
				LOGS:write("\t")
				LOGS:write(tostring(current_table))
				LOGS:write("\n")
				LOGS:flush()
			end

			if current_table == nil then
				if t == 240 then
					-- table
					local v = add_to_seen({}, seen)
					tables_queue:enqueue_front({
						data = v,
						current_array_index = 0,
						current_dict_index = 0,
						current_mode = 'await init'
					})
				elseif t == 242 then
					--instance
					local instance = add_to_seen({}, seen)
					local classname = read_string(seen)
					-- print(classname)

					tables_queue:enqueue_front({
						data = instance,
						current_array_index = 0,
						current_dict_index = 0,
						classname = classname,
						class = class_registry[classname],
						classkey = classkey_registry[classname],
						deserializer = class_deserialize_registry[classname],
						current_mode = 'await init'
					})
				end
			elseif t < 128 then
				--small int
				TableReaderApplyValue(current_table, t - 27)
			elseif t < 192 then
				--small reference
				TableReaderApplyValue(current_table, seen[t - 127])
			elseif t < 224 then
				--small string
				TableReaderApplyValue(current_table, add_to_seen(Buffer_read_string(t - 192), seen))
			elseif t < 240 then
				--small resource
				TableReaderApplyValue(current_table, add_to_seen(resource_registry[Buffer_read_string(t - 224)], seen))
			elseif t == 240 then
				if verbose then
					LOGS:write('table detected ')
					LOGS:write("\t")
					LOGS:write(tostring(current_table.current_key))
					LOGS:write("\n")
					LOGS:flush()
				end
				local v = add_to_seen({}, seen)
				tables_queue:enqueue_front({
					data = v,
					current_array_index = 0,
					current_dict_index = 0,
					current_mode = 'await init'
				})
			elseif t == 241 then
				--long resource
				local idx = reserve_seen(seen)
				local name = read_string(seen)
				local value = resource_registry[name]
				seen[idx] = value
				TableReaderApplyValue(current_table, value)
			elseif t == 242 then
				-- print('instance of class detected:')
				--instance
				local instance = add_to_seen({}, seen)
				local classname = read_string(seen)
				-- print(classname)

				tables_queue:enqueue_front({
					data = instance,
					current_array_index = 0,
					current_dict_index = 0,
					classname = classname,
					class = class_registry[classname],
					classkey = classkey_registry[classname],
					deserializer = class_deserialize_registry[classname],
					current_mode = 'await init'
				})
			elseif t == 243 then
				--reference
				TableReaderApplyValue(current_table, seen[read_number(seen) + 1])
			elseif t == 244 then
				--long string
				TableReaderApplyValue(current_table, add_to_seen(Buffer_read_string(read_number(seen)), seen))
			elseif t == 245 then
				--long int
				TableReaderApplyValue(current_table, Buffer_read_data("int32_t[1]", 4)[0], verbose)
			elseif t == 246 then
				--double
				TableReaderApplyValue(current_table, Buffer_read_data("double[1]", 8)[0])
			elseif t == 247 then
				--nil
				TableReaderApplyValue(current_table, nil)
			elseif t == 248 then
				--false
				TableReaderApplyValue(current_table, false)
			elseif t == 249 then
				--true
				TableReaderApplyValue(current_table, true)
			elseif t == 250 then
				--short int
				TableReaderApplyValue(current_table, Buffer_read_data("int16_t[1]", 2)[0])
			elseif t == 251 then
				--ctype
				TableReaderApplyValue(current_table, ffi.typeof(read_string(seen)))
			elseif t == 252 then
				local ctype = ffi.typeof(read_string(seen))
				local len = read_number(seen)
				local read_into = ffi.typeof('$[1]', ctype)()
				Buffer_read_raw(read_into, len)
				TableReaderApplyValue(current_table, ctype(read_into[0]))
			else
				error("unsupported serialized type " .. t)
			end
		elseif current_table.array_length == nil then
			-- print('reading table length')
			local value = read_number(seen)
			if type(value) == "number" then
				current_table.array_length = value
			else
				error("Invalid array length")
			end
		elseif current_table.array_length > current_table.current_array_index then
			-- print('not enough array values')
			current_table.current_mode = 'await array value'
		elseif current_table.dict_length == nil then
			-- print('reading dict length')
			local value = read_number(seen)
			if type(value) == "number" then
				current_table.dict_length = value
			else
				-- error("Invalid dict length")
			end
		elseif current_table.dict_length > current_table.current_dict_index then
			-- print('not enough dict values')
			current_table.current_mode = 'await dict key'
		else
			-- print('table is ready')
			tables_queue:dequeue()
			local prev = tables_queue:peek()
			if tables_queue:length() <= 0 then
				if current_table.classname then
					if current_table.classkey then
						current_table.data[current_table.classkey] = current_table.class
					end
					coroutine.yield("finished", current_table.deserializer(current_table.data, current_table.class))
					return "finished", current_table.deserializer(current_table.data, current_table.class)
				else
					coroutine.yield("finished", current_table.data)
					return "finished", current_table.data
				end
			else
				if current_table.classname then
					-- print('class instance is ready')
					-- print(current_table.classname)
					-- print(current_table.deserializer)
					if current_table.classkey then
						current_table.data[current_table.classkey] = current_table.class
					end
					local class_instance = current_table.deserializer(current_table.data, current_table.class)
					TableReaderApplyValue(prev, class_instance)
				else
					-- print('table is ready')
					TableReaderApplyValue(prev, current_table.data)
				end
			end
		end
	end
end

local function deserialize_MiddleClass(instance, class)
	return setmetatable(instance, class.__instanceDict)
end

local function deserialize_SECL(instance, class)
	return setmetatable(instance, getmetatable(class))
end

local deserialize_humpclass = setmetatable

local function deserialize_Slither(instance, class)
	return getmetatable(class).allocate(instance)
end

local function deserialize_Moonscript(instance, class)
	return setmetatable(instance, class.__base)
end

return {
	dumps = function(value)
		serialize(value)
		return ffi.string(buf, buf_pos)
	end,
	dumpLoveFile = function(fname, value)
		print("Serialization starts...")
		serialize(value)
		print("Serialization ended!")
		assert(love.filesystem.write(fname, ffi.string(buf, buf_pos)))
	end,
	dumpLoveFile_async = function(fname, value)
		print("Serialization starts...")
		local saving_coroutine = coroutine.create(function() serialize_async(value) end)
		local success, data = true, 0
		while success do
			success, data = coroutine.resume(saving_coroutine)
			coroutine.yield(data)
		end
		print("Serialization ended!")
		assert(love.filesystem.write(fname, ffi.string(buf, buf_pos)))
		-- assert(love.filesystem.write(fname, ffi.string(buf, buf_pos)))
	end,
	loadLoveFile = function(fname, verbose)
		if verbose == nil then
			verbose = false
		end

		print("open file")
		local serializedData, error = love.filesystem.newFileData(fname)
		assert(serializedData, error)

		print("create buffer")
		Buffer_newDataReader(serializedData:getFFIPointer(), serializedData:getSize())

		local loading_callback = function()
			local loading_status, data = deserialize({}, verbose)
			return data
		end

		print("load")
		while true do
			return loading_callback()
		end
	end,
	loadLoveFile_async = function(fname, progress_table)
		local serializedData, error = love.filesystem.newFileData(fname)
		assert(serializedData, error)
		Buffer_newDataReader(serializedData:getFFIPointer(), serializedData:getSize())
		local loading_coroutine = coroutine.create(function()
			local value = deserialize({}, false)
			return value
		end)
		while true do
			local co_status, loading_status, data = coroutine.resume(loading_coroutine)
			if loading_status == "finished" then
				print('loading completed')
				coroutine.yield("finished", data)
				return data
			end
			if loading_status == 'tiles count' and progress_table ~= nil then
				progress_table.total = data
				coroutine.yield("in process")
			end
		end
	end,
	register = function(name, resource)
		assert(not resource_registry[name], name .. " already registered")
		resource_registry[name] = resource
		resource_name_registry[resource] = name
		return resource
	end,
	unregister = function(name)
		resource_name_registry[resource_registry[name]] = nil
		resource_registry[name] = nil
	end,
	registerClass = function(name, class, classkey, deserializer)
		if not class then
			class = name
			name = class.__name__ or class.name or class.__name
		end
		if not classkey then
			if class.__instanceDict then
				-- assume MiddleClass
				classkey = 'class'
			elseif class.__baseclass then
				-- assume SECL
				classkey = '__baseclass'
			end
			-- assume hump.class, Slither, Moonscript class or something else that doesn't store the
			-- class directly on the instance
		end
		if not deserializer then
			if class.__instanceDict then
				-- assume MiddleClass
				print("using MiddleClass deserializer for " .. name)
				deserializer = deserialize_MiddleClass
			elseif class.__baseclass then
				-- assume SECL
				print("using SECL deserializer for " .. name)
				deserializer = deserialize_SECL
			elseif class.__index == class then
				-- assume hump.class
				print("using humpclass deserializer for " .. name)
				deserializer = deserialize_humpclass
			elseif class.__name__ then
				-- assume Slither
				print("using Slither deserializer for " .. name)
				deserializer = deserialize_Slither
			elseif class.__base then
				-- assume Moonscript class
				print("using Moonscript deserializer for " .. name)
				deserializer = deserialize_Moonscript
			else
				error("no deserializer given for unsupported class library")
			end
		end
		class_registry[name] = class
		classkey_registry[name] = classkey
		class_deserialize_registry[name] = deserializer
		class_name_registry[class] = name
		return class
	end,
	unregisterClass = function(name)
		class_name_registry[class_registry[name]] = nil
		classkey_registry[name] = nil
		class_deserialize_registry[name] = nil
		class_registry[name] = nil
	end,
	reserveBuffer = Buffer_prereserve,
	clearBuffer = Buffer_clear,
	version = VERSION
}
