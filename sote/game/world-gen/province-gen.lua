print("Reading province-gen.lua")

local pp = require "game.entities.province"
local tabb = require "engine.table"

local pro = {}

---@param province Province
---@param deep_logs boolean?
local function calculate_province_neighbors(province, deep_logs)
	province.neighbors = {}
	if deep_logs then
		print("Province size: " .. tostring(tabb.size(province.tiles)))
		local c = 0
		for _, _ in pairs(province.tiles) do
			c = c + 1
		end
		print("Province tiles from local looping: " .. tostring(c))
	end
	local visited_tiles = 0
	for _, tile in pairs(province.tiles) do
		-- Add province neighbors
		if deep_logs then
			print("Visiting tile: " .. tostring(tile))
		end
		for n in tile:iter_neighbors() do
			if deep_logs then
				print("Neigh: " .. tostring(n.province) .. ", us: " .. tostring(province))
			end
			if n.province ~= province then
				province.neighbors[n.province] = n.province
			end
		end
		if deep_logs then
			print("Visit ended")
		end
		visited_tiles = visited_tiles + 1
	end
	if deep_logs then
		print("Neighs: " .. tostring(tabb.size(province.neighbors)))
	end
	if deep_logs then
		print("Province size: " .. tostring(tabb.size(province.tiles)))
		local c = 0
		for _, _ in pairs(province.tiles) do
			c = c + 1
		end
		print("Province tiles from local looping: " .. tostring(c))
		print("Visited tiles: " .. tostring(visited_tiles))

		if visited_tiles ~= c then
			print("Error!")
			love.event.quit()
		end
	end

	if deep_logs then
		for _, tile in pairs(province.tiles) do
			for n in tile:iter_neighbors() do
				if n.province ~= province then
					if province.neighbors[n.province] == nil then
						print("Failed province neighbor verification! :c")
						love.event.quit()
					end
				end
			end
		end
	end
end

function pro.run()
	print("Province generation initialization")
	local prov_count = 5000
	local tile_count = WORLD.world_size * WORLD.world_size * 6
	local expected_land_province_size = tile_count * 0.3 / prov_count
	local expected_water_province_size = tile_count * 0.7 / prov_count

	-- Returns true if all neighbors are "free"
	local check_neighs = function(tile)
		---@type Tile
		local t = tile
		for n in t:iter_neighbors() do
			if n.province ~= nil then
				return false
			end
		end
		return true
	end

	print("Creating itnitial provinces...")
	-- Generate starting provinces (first land, then sea)
	local queue = (require "engine.queue"):new()
	--local visited = {}
	--local visited_count = 0
	local fill_out = function()
		while queue:length() > 0 do
			---@type Tile
			local tile = queue:dequeue()
			--[[
			print(queue:length(), visited_count)
			if visited[tile] then
				--
			else
				visited[tile] = tile
				visited_count = visited_count + 1
			end
			--]]

			-- PROVINCE SIZE LIMIT
			local expected_size = expected_water_province_size
			if tile.province.center.is_land then
				expected_size = expected_land_province_size
			end

			-- NO PROVINCE SIZE LIMIT
			expected_size = math.huge

			if tabb.size(tile.province.tiles) < expected_size then
				if love.math.random() > 0.5 then
					for n in tile:iter_neighbors() do
						if n.province == nil and n.is_land == tile.is_land then
							tile.province:add_tile(n)
							queue:enqueue(n)
						end
					end
				else
					queue:enqueue(tile)
				end
			end
		end
	end
	for _ = 1, prov_count do
		-- Get a random water tile with no province assigned to it
		local tile = WORLD:random_tile()
		while not tile.is_land or tile.province ~= nil or not check_neighs(tile) do tile = WORLD:random_tile() end

		local new_province = pp.Province:new()
		new_province.center = tile
		new_province:add_tile(tile)
		for n in tile:iter_neighbors() do
			if n.is_land == tile.is_land then
				new_province:add_tile(n)
				queue:enqueue(n)
			end
		end
	end
	fill_out()
	for _ = 1, prov_count do
		-- Get a random land tile with no province assigned to it
		local tile = WORLD:random_tile()
		while tile.is_land or tile.province ~= nil do tile = WORLD:random_tile() end
		local new_province = pp.Province:new()
		new_province.center = tile
		new_province:add_tile(tile)
		queue:enqueue(tile)
	end
	fill_out()
	-- at the end, fill in the gaps!
	for _, tile in pairs(WORLD.tiles) do
		if tile.province == nil then
			local new_province = pp.Province:new()
			new_province.center = tile
			new_province:add_tile(tile)
			queue:enqueue(tile)
			fill_out()
		end
	end

	---[==[
	print("Attempting province mergers...")
	local to_wipe = {}
	-- now, after the generation is done, we should loop through all provinces and get rid of the ones that are too small...
	-- we're doing it here to use the above function but before final province neighborhoods are created.
	for _, province in pairs(WORLD.provinces) do
		-- when a province is half the expected size, attempt to merge it with another province...
		local size = tabb.size(province.tiles)
		local should_merge = false
		local expected_size = 0
		if province.center.is_land then
			if expected_land_province_size * 0.7 > size then
				should_merge = true
				expected_size = expected_land_province_size
			end
		else
			if expected_water_province_size * 0.7 > size then
				should_merge = true
				expected_size = expected_water_province_size
			end
		end

		if should_merge then
			---[[
			-- Find the smallest merge target...
			for _, tile in pairs(province.tiles) do
				for n in tile:iter_neighbors() do
					if n.province ~= nil and n.province ~= province then
						local neigh = n.province
						if neigh.center.is_land == province.center.is_land then
							-- Merge only if we're not too large but also merge tiny provinces unconditionally!
							if tabb.size(neigh.tiles) + size < expected_size or size < 10 then
								-- Merge time!
								for _, tile in pairs(neigh.tiles) do
									province:add_tile(tile)
								end
								to_wipe[#to_wipe + 1] = neigh
								if tabb.size(neigh.tiles) > 0 then
									print("Merge... failed?")
									love.event.quit()
								end
							end
						end
						size = tabb.size(province.tiles)
						if size > expected_size * 0.95 then
							goto MERGED
						end
					end
				end
			end
			::MERGED::
			--]]
		end
	end
	for _, tw in pairs(to_wipe) do
		---@type Province
		local ttw = tw
		WORLD.provinces[ttw.province_id] = nil
		for _, _ in pairs(ttw.tiles) do
			print("A PROVINCE THAT WAS TO BE REMOVED HAS TILES!")
			love.event.quit()
		end
	end
	--]==]


	--[[
	-- A check for a tile belonging to multiple provinces
	print("Cross checking tile ownership")
	local owned = {}
	for _, province in pairs(WORLD.provinces) do
		for _, tile in pairs(province.tiles) do
			if owned[tile] then
				print("A TILE IS OWNED BY MULTIPLE PROVINCES!")
				love.event.quit()
			else
				owned[tile] = tile
			end
		end
	end
	print("Verifying that every tile has a province assigned to it")
	for _, tile in pairs(WORLD.tiles) do
		if tile.province then
			-- yay!
		else
			print("A TILE HAS NO PROVINCE!")
			love.event.quit()
		end
	end
	--]]

	---[[
	-- Recalculate neighbors!
	for _, province in pairs(WORLD.provinces) do
		calculate_province_neighbors(province)

		--[===[
		if tabb.size(province.neighbors) == 0 then
			print("???? A province has no neighbors. This is geometrically IMPOSSIBLE")
			calculate_province_neighbors(province, true)
			if tabb.size(province.neighbors) == 0 then
				print("!!!!!!! ITS STILL BORKED")
				--[[
				tabb.print(province.tiles)
				for _, tt in pairs(province.tiles) do
					print("Tile: " .. tostring(tt.tile_id) .. ' with province: ' .. tostring(province.province_id))
					for n in tt:iter_neighbors() do
						print("---neigh: " .. tostring(n.tile_id) .. " with province: " .. tostring(n.province.province_id))
						if n.province.province_id ~= province.province_id then
							print("EXCUSE ME ARE WE OKAY??? THIS CLEARLY SHOULD HAVE WORKED")
						end
					end
				end
				--]]
				love.event.quit()
			end
		end
		--]===]
	end
	--]]
end

print("province-gen.lua has been read")
return pro
