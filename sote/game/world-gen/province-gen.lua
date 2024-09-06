local tile = require "game.entities.tile"
print("Reading province-gen.lua")

local pp = require "game.entities.province"
local tabb = require "engine.table"

local pro = {}

---@param province Province
---@param deep_logs boolean?
local function calculate_province_neighbors(province, deep_logs)
	local size = #DATA.get_tile_province_membership_from_province(province)
	if deep_logs then
		print("Province size: " .. tostring(size))
		local c = 0
		for _, _ in pairs(DATA.get_tile_province_membership_from_province(province)) do
			c = c + 1
		end
		print("Province tiles from local looping: " .. tostring(c))
	end
	local visited_tiles = 0

	---@type tile_id[]
	local border_tiles = {}

	---@type table<province_id, province_id>
	local neigbours_to_connect = {}
	for _, tile_membership_id in pairs(DATA.get_tile_province_membership_from_province(province)) do
		local tile_id = DATA.tile_province_membership_get_tile(tile_membership_id)
		-- Add province neighbors
		if deep_logs then
			print("Visiting tile: " .. tostring(tile))
		end
		for n in tile.iter_neighbors(tile_id) do
			if deep_logs then
				print("Neigh: " .. tostring(tile.province(n)) .. ", us: " .. tostring(province))
			end
			if tile.province(n) ~= province then
				DATA.tile_set_is_border(tile_id, true)
				table.insert(border_tiles, tile_id)
				neigbours_to_connect[tile.province(n)] = tile.province(n)
			end
		end
		if deep_logs then
			print("Visit ended")
		end
		visited_tiles = visited_tiles + 1
	end

	for index, tile_id in ipairs(border_tiles) do
		for n in tile.iter_neighbors(tile_id) do
			DATA.tile_set_is_border(n, true)
		end
	end

	for _, item in pairs(neigbours_to_connect) do
		local province_link = DATA.fatten_province_neighborhood(DATA.create_province_neighborhood())
		if province_link.id % 10000 == 0 then
			print(province_link.id)
		end
		province_link.origin = province
		province_link.target = item
	end
	if deep_logs then
		print("Neighs: " .. tostring(tabb.size(DATA.get_province_neighborhood_from_origin(province))))
	end
	if deep_logs then
		print("Province size: " .. tostring(size))
		local c = 0
		for _, _ in pairs(DATA.get_tile_province_membership_from_province(province)) do
			c = c + 1
		end
		print("Province tiles from local looping: " .. tostring(c))
		print("Visited tiles: " .. tostring(visited_tiles))

		assert(visited_tiles == c, "Something is wrong")
	end

	-- if deep_logs then
	-- 	for _, tile_membership_id in pairs(DATA.get_tile_province_membership_from_province(province)) do
	-- 		local tile_id = DATA.tile_province_membership_get_tile(tile_membership_id)
	-- 		for n in tile.iter_neighbors(tile_id) do
	-- 			if tile.province(n) ~= province then
	-- 				if province.neighbors[tile.province(n)] == nil then
	-- 					print("Failed province neighbor verification! :c")
	-- 					love.event.quit()
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
end

function pro.run()
	print("Province generation initialization")
	local prov_count = 5000
	local tile_count = WORLD.world_size * WORLD.world_size * 6
	local expected_land_province_size = tile_count * 0.3 / prov_count
	-- local expected_water_province_size = tile_count * 0.7 / prov_count
	local expected_water_province_size = tile_count * 2 / prov_count

	-- Returns true if all neighbors are "free"
	local check_neighs = function(tile_id)
		for n in tile.iter_neighbors(tile_id) do
			if tile.province(n) ~= INVALID_ID then
				return false
			end
		end
		return true
	end

	print("Creating initial provinces...")
	-- Generate starting provinces (first land, then sea)
	---@type Queue<tile_id>
	local queue = (require "engine.queue"):new()
	--local visited = {}
	--local visited_count = 0

	local water_thre = 1000
	local water_seek = 3

	---comment
	---@param strict_flag boolean
	local function fill_out(strict_flag)
		while queue:length() > 0 do
			local tile_id = queue:dequeue()
			local province = tile.province(tile_id)
			local size = #DATA.get_tile_province_membership_from_province(province)
			local fat_province = DATA.fatten_province(province)
			if tile.average_waterflow(tile_id)  > water_thre then
				fat_province.on_a_river = true
			end

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
			local local_center = fat_province.center
			if DATA.tile_get_is_land(local_center) then
				expected_size = expected_land_province_size
			end

			-- NO PROVINCE SIZE LIMIT
			-- expected_size = math.huge
			-- expected_size = 300
			if size < expected_size * 1.1 then
				if DATA.tile_get_is_land(tile_id) then
					local growth_probability = 0.5
					if fat_province.on_a_river then
						growth_probability = 0.3
					end
					if love.math.random() < growth_probability then
						for n in tile.iter_neighbors(tile_id) do
							if tile.province(n) == INVALID_ID and DATA.tile_get_is_land(n) == DATA.tile_get_is_land(tile_id) then
								if (not strict_flag) or (math.abs(DATA.tile_get_elevation(tile_id) - DATA.tile_get_elevation(n)) < 350) then
									pp.Province.add_tile(province, n)
									queue:enqueue(n)
								end
							end
						end
					else
						queue:enqueue(tile_id)
					end
				else
					local growth_probability = 0.6
					if love.math.random() < growth_probability then
						for n in tile.iter_neighbors(tile_id) do
							if tile.province(n) == INVALID_ID and DATA.tile_get_is_land(n) == DATA.tile_get_is_land(tile_id) then
								if (not strict_flag) or (math.abs(DATA.tile_get_elevation(tile_id) - DATA.tile_get_elevation(n)) < 700) then
									pp.Province.add_tile(province, n)
									queue:enqueue(n)
								end
							end
						end
					else
						queue:enqueue(tile_id)
					end
				end
			end
		end
	end



	---adds local coastal tiles to this province
	---@param tile_id tile_id
	---@param depth number
	---@param province Province
	local function coastal_recursion(tile_id, depth, province)
		if depth == 0 then return end
		if (not tile.is_coast(tile_id)) and (depth > 1) then return end
		-- if (not check_neighs(tile)) then return end
		if (tile.province(tile_id) ~= INVALID_ID) then return end

		pp.Province.add_tile(province, tile_id)
		if tile.average_waterflow(tile_id)  > water_thre then
			DATA.province_set_on_a_river(province, true)
		end
		if depth == 1 then
			queue:enqueue(tile_id)
		end

		for n in tile.iter_neighbors(tile_id) do
			if DATA.tile_get_is_land(n) == DATA.tile_get_is_land(tile_id) then
				coastal_recursion(n, depth - 1, province)
			end
		end
	end



	---comment
	---@param tile_id tile_id
	---@param depth number
	---@param searched table<tile_id, boolean>
	---@return tile_id
	local function river_search(tile_id, depth, searched)
		if depth == 0 then return INVALID_ID end
		if tile.average_waterflow(tile_id)  >= water_thre then
			return tile_id
		end
		searched[tile_id] = true
		for n in tile.iter_neighbors(tile_id) do
			if DATA.tile_get_is_land(n) == DATA.tile_get_is_land(tile_id) and not searched[n] then
				local response = river_search(n, depth - 1, searched)
				if response then
					return response
				end
			end
		end
		return INVALID_ID
	end

	---comment
	---@param tile_id tile_id
	---@param depth number
	---@param province Province
	---@return tile_id
	local function waterflow_recursion(tile_id, depth, low_waterflow_counter, province)
		if depth == 0 then
			return river_search(tile_id, 4, {})
		end

		-- print(tile.average_waterflow(tile_id) , low_waterflow_counter, tile.province(tile_id) ~= nil)
		if (tile.average_waterflow(tile_id)  < water_thre) and (low_waterflow_counter == 0) then return INVALID_ID end
		-- if (not check_neighs(tile)) then return end
		if (tile.province(tile_id) ~= INVALID_ID) then return INVALID_ID end

		pp.Province.add_tile(province, tile_id)
		-- queue:enqueue(tile)
		local d = water_seek
		if (tile.average_waterflow(tile_id)  < water_thre) and (not tile.is_coast(tile_id)) then
			d = -1
		end
		if depth == 1 then
			queue:enqueue(tile_id)
		end

		-- print('???')
		tile.set_debug_color(tile_id, 1, 1, 1)

		local response = INVALID_ID
		for n in tile.iter_neighbors(tile_id) do
			if DATA.tile_get_is_land(n) == DATA.tile_get_is_land(tile_id) then
				local next_tile = waterflow_recursion(n, depth - 1, math.min(water_seek, low_waterflow_counter + d),
					province)
				if next_tile then
					response = next_tile
				end
			end
		end
		return response
	end

	---comment
	---@param tile_id tile_id
	local function river_gen_province_recursion(tile_id)
		local new_province = pp.Province.new()
		local fat_province = DATA.fatten_province(new_province)
		fat_province.center = tile_id
		local next_tile = waterflow_recursion(tile_id, 20, water_seek, new_province)
		fat_province.on_a_river = true

		if next_tile ~= INVALID_ID then
			river_gen_province_recursion(next_tile)
		end
	end

	print('creating river-like provinces')
	local riverlike_prov_count = math.floor(prov_count / 8)
	for _ = 1, riverlike_prov_count do
		-- if _ % 100 == 0 then
		-- 	print(_ / riverlike_prov_count * 100)
		-- end
		-- Get a random soil rich tile with no province assigned to it
		local tile_id = WORLD:random_tile()
		local failsafe = 0
		while not DATA.tile_get_is_land(tile_id) or (tile.average_waterflow(tile_id) < water_thre) or tile.province(tile_id) ~= INVALID_ID or not check_neighs(tile_id) do
			tile_id = WORLD:random_tile()
			failsafe = failsafe + 1
			if failsafe > WORLD:tile_count() / 2 then
				break
			end
		end
		river_gen_province_recursion(tile_id)
	end

	print('creating coastal provinces')
	local coastal_count = math.floor(prov_count / 5)
	for _ = 1, coastal_count do
		-- if _ % 100 == 0 then
		-- 	print(_ / coastal_count * 100)
		-- end

		-- Get a random coastal tile with no province assigned to it
		local tile_id = WORLD:random_tile()
		local failsafe = 0
		while not DATA.tile_get_is_land(tile_id) or not tile.is_coast(tile_id) or tile.province(tile_id) ~= INVALID_ID or not check_neighs(tile_id) do
			tile_id = WORLD:random_tile()
			failsafe = failsafe + 1
			if failsafe > WORLD:tile_count() / 2 then break end
		end
		local new_province = pp.Province.new()
		local fat_province = DATA.fatten_province(new_province)
		fat_province.center = tile_id
		-- new_province:add_tile(tile)
		-- for n in tile.iter_neighbors(tile_id) do
		-- 	if DATA.tile_get_is_land(n) == DATA.tile_get_is_land(tile_id) then
		-- 		new_province:add_tile(n)
		-- 		queue:enqueue(n)
		-- 	end
		-- end
		coastal_recursion(tile_id, 60, new_province)
	end

	print('create rest of provinces')
	for _ = 1, prov_count - coastal_count - riverlike_prov_count do
		-- if _ % 100 == 0 then
		-- 	print(_ / (prov_count - coastal_count - riverlike_prov_count) * 100)
		-- end
		-- Get a random land tile with no province assigned to it
		local tile_id = WORLD:random_tile()
		local failsafe = 0
		while not DATA.tile_get_is_land(tile_id) or tile.province(tile_id) ~= INVALID_ID or not check_neighs(tile_id) do
			tile_id = WORLD:random_tile()
			failsafe = failsafe + 1
			if failsafe > WORLD:tile_count() / 2 then break end
		end

		local new_province = pp.Province.new()
		local fat_province = DATA.fatten_province(new_province)
		fat_province.center = tile_id
		pp.Province.add_tile(new_province, tile_id)
		for n in tile.iter_neighbors(tile_id) do
			if DATA.tile_get_is_land(n) == DATA.tile_get_is_land(tile_id) then
				pp.Province.add_tile(new_province, n)
				queue:enqueue(n)
			end
		end
	end
	fill_out(true)

	print('create sea provinces')
	-- sea provinces
	for _ = 1, prov_count do
		-- Get a random sea tile with no province assigned to it
		local tile_id = WORLD:random_tile()
		while DATA.tile_get_is_land(tile_id) or tile.province(tile_id) ~= INVALID_ID do
			tile_id = WORLD:random_tile()
		end
		local new_province = pp.Province.new()
		local fat_province = DATA.fatten_province(new_province)
		fat_province.center = tile_id
		pp.Province.add_tile(new_province, tile_id)
		queue:enqueue(tile_id)
	end
	fill_out(false)

	print('fill the gaps')
	-- at the end, fill in the gaps!
	DATA.for_each_tile(function (tile_id)
		if tile.province(tile_id) == INVALID_ID then
			local new_province = pp.Province.new()
			local fat_province = DATA.fatten_province(new_province)
			fat_province.center = tile_id
			pp.Province.add_tile(new_province, tile_id)
			queue:enqueue(tile_id)
			fill_out(false)
		end
	end)

	local function recalculate_provincial_centers()
		DATA.for_each_province(function (province)
			local N = 20
			-- sample N random tiles
			---@type tile_id[]
			local sample = {}

			for i = 1, N do
				local membership = tabb.random_select_from_array(DATA.get_tile_province_membership_from_province(province))
				table.insert(sample, DATA.tile_province_membership_get_tile(membership))
			end

			-- find average tile coordinates:
			local lat = 0
			local lon = 0
			for _, tile_id in pairs(sample) do
				local tmp_lat, tmp_lon = tile.latlon(tile_id)
				lat = lat + tmp_lat / N
				lon = lon + tmp_lon / N
			end

			-- find tile closest to average
			local best_tile = DATA.province_get_center(province)
			local best_dist = 10000000
			for _, tile_membership_id in pairs(DATA.get_tile_province_membership_from_province(province)) do
				local tile_id = DATA.tile_province_membership_get_tile(tile_membership_id)
				local tmp_lat, tmp_lon = tile.latlon(tile_id)

				---@type number
				local dist = math.abs(tmp_lat - lat) + math.abs(tmp_lon - lon)

				if dist < best_dist then
					best_dist = dist
					best_tile = tile_id
				end
			end

			DATA.province_set_center(province, best_tile)
		end)
	end

	print('calculate initial centers')
	recalculate_provincial_centers()

	do
		local amount_of_provs = 0
		DATA.for_each_province(function (a)
			amount_of_provs = amount_of_provs + 1
		end)

		print("There are " .. amount_of_provs .. " provinces")
	end

	---[==[
	print("Attempting province mergers...")
	---@type Province[]
	local to_wipe = {}
	-- now, after the generation is done, we should loop through all provinces and get rid of the ones that are too small...
	-- we're doing it here to use the above function but before final province neighborhoods are created.
	DATA.for_each_province(function (province)
		-- when a province is half the expected size, attempt to merge it with another province...
		local size = #DATA.get_tile_province_membership_from_province(province)
		local should_merge = false
		local expected_size = 0
		if DATA.tile_get_is_land(DATA.province_get_center(province)) then
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
			-- Find the smallest/best merge target...
			for _, tile_membership_id in pairs(DATA.get_tile_province_membership_from_province(province)) do
				local tile_id = DATA.tile_province_membership_get_tile(tile_membership_id)
				for n in tile.iter_neighbors(tile_id) do
					if tile.province(n) ~= INVALID_ID and tile.province(n) ~= province then
						local neigh = tile.province(n)
						local neigh_center = DATA.province_get_center(neigh)
						if DATA.tile_get_is_land(neigh_center) == DATA.tile_get_is_land(tile_id) then
							-- Merge only if we're not too large but also merge tiny provinces unconditionally!
							-- Merge if center of result is not far awaya from original center
							local small_lat, small_lon = tile.latlon(DATA.province_get_center(province))
							local big_lat, big_lon = tile.latlon(neigh_center)

							local small_x = math.cos(small_lon) * math.cos(small_lat)
							local small_z = math.sin(small_lon) * math.cos(small_lat)
							local small_y = math.sin(small_lat)

							local big_x = math.cos(big_lon) * math.cos(big_lat)
							local big_z = math.sin(big_lon) * math.cos(big_lat)
							local big_y = math.sin(big_lat)

							local small_size = size
							local big_size = #DATA.get_tile_province_membership_from_province(neigh)

							local new_center_x = small_x * small_size + big_x * big_size
							local new_center_z = small_z * small_size + big_z * big_size
							local new_center_y = small_y * small_size + big_y * big_size

							new_center_x = new_center_x / (small_size + big_size)
							new_center_z = new_center_z / (small_size + big_size)
							new_center_y = new_center_y / (small_size + big_size)

							local distance = (new_center_x - big_x) + (new_center_z - big_z) + (new_center_y - big_y)

							if big_size + size < expected_size or size < 10 or distance < 0.005 then
								---@type tile_province_membership_id[]
								local tiles_to_transfer = tabb.copy(DATA.get_tile_province_membership_from_province(neigh))
								-- Merge time!
								for _, neigh_tile_membership_id in pairs(tiles_to_transfer) do
									local neigh_tile_id = DATA.tile_province_membership_get_tile(neigh_tile_membership_id)
									pp.Province.add_tile(province, neigh_tile_id)
								end
								to_wipe[#to_wipe + 1] = neigh
								assert(#DATA.get_tile_province_membership_from_province(neigh) == 0)
							end
						end
						size = #DATA.get_tile_province_membership_from_province(province)
						if size > expected_size * 0.95 then
							goto MERGED
						end
					end
				end
			end
			::MERGED::
			--]]
		end
	end)
	print("preparing to wipe ", tostring(#to_wipe), " provinces")

	for _, tw in pairs(to_wipe) do
		assert(#DATA.get_tile_province_membership_from_province(tw) == 0, "A PROVINCE THAT WAS TO BE REMOVED HAS TILES!")
		DATA.delete_province(tw)
	end

	print("wiped")

	do
		local amount_of_provs = 0
		DATA.for_each_province(function (a)
			amount_of_provs = amount_of_provs + 1
		end)

		print("There are " .. amount_of_provs .. " provinces")
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
	for _, tile_id in pairs(WORLD.tiles) do
		if tile.province(tile_id) then
			-- yay!
		else
			print("A TILE HAS NO PROVINCE!")
			love.event.quit()
		end
	end
	--]]

	-- Recalculate neighbors!
	print("recalculate neighbors")
	DATA.for_each_province(calculate_province_neighbors)

	print("recalculate centers")
	recalculate_provincial_centers()

	print("recalculate size")
	DATA.for_each_province(pp.Province.update_size)

	print("recalculate flags")
	DATA.for_each_province(function (province)
		local forestCount = 0
		local river_count = 0

		for _, tile_membership_id in pairs(DATA.get_tile_province_membership_from_province(province)) do
			local tile_id = DATA.tile_province_membership_get_tile(tile_membership_id)
			local biome = DATA.tile_get_biome(tile_id)
			local biome_name = DATA.biome_get_name(biome)

			if biome_name == "mixed-forest" or
				biome_name == "coniferous-forest" or
				biome_name == "taiga" or
				biome_name == "broadleaf-forest" or
				biome_name == "wet-jungle" or
				biome_name == "dry-jungle" or
				biome_name == "mixed-woodland" or
				biome_name == "coniferous-woodland" or
				biome_name == "woodland-taiga" or
				biome_name == "broadleaf-woodland" then
				forestCount = forestCount + 1
			end

			if tile.average_waterflow(tile_id)  > water_thre then
				river_count = river_count + 1
			end
		end
		if forestCount > DATA.province_get_size(province) / 2 then
			DATA.province_set_on_a_forest(province, true)
		end

		if river_count > 0 then
			DATA.province_set_on_a_river(province, true)
		end
	end)
end

print("province-gen.lua has been read")
return pro
