local plate_gen = {}

function plate_gen.run()
	
		
	print("Spawning plates!")
--	local tiles_to_convert = WORLD:tile_count()
	---------------------------
	--- Plate number inputs ---
	---------------------------

	----------------------
	--- Plate clusters ---
	----------------------

	local disable_plate_gen = true

	local micro_plate_clusters = {}

	local num_micro_plates = 4
	local num_micro_ocean_plates = 5
	local num_micro_clusters = 3

	local num_small_plates = 6
	local num_small_ocean_plates = 3
	
	local num_large_land_plates = 2
	local num_large_ocean_plates = 2
	
	local non_cluster_plates = num_micro_plates + num_micro_ocean_plates + num_small_plates + num_small_ocean_plates + num_large_land_plates + num_large_ocean_plates
	local total_plates = non_cluster_plates

	local speed_floor = 2
	local speed_ceiling = 12
		
	local perlin_seed = love.math.random(500000)
	
	local envelopment_threshold = 0.7 --- Determines what percentage of a plate's boundary can be with 1 other plate
	--------------------------------------------
	--- Prep world tiles for plate expansion ---
	--------------------------------------------
	
	for _, tile in pairs(WORLD.tiles) do
		local perlin_variable = (2000 * tile:perlin(20, perlin_seed) ^ 2.5) + 100 -- value of 40 seems best so far
		tile.elevation = perlin_variable
		tile.is_land = true
		tile.value_to_overcome = 1
		tile.expansion_potential = 0
		tile.already_added = false
		tile.times_added = 0
		tile.stop_expansion = false
	end
	
	---------------------------------------------------------------------
	--- Set Random plate starts, check distance, rebuild if too close ---
	---------------------------------------------------------------------
	
	local sufficiently_distanced = 0
	local random_tile_table = {}
	local attempts = 0
	local minimum_distance = 3000 -- how much distance must be maintained between plate start locations
	local start = love.timer.getTime()

	local start = love.timer.getTime()
	
	--------------------------------------------------
	--- Assign Micro Plate Cluster Start Locations ---
	--------------------------------------------------
	random_tile_table = {} --- Reserved for final plate locations
	local micro_cluster_starts = {} --- Reserved for micro plate starts
	local attempts = 0
	for i = 1, (num_micro_clusters) do 
		print("On Cluster: " .. tostring(i))
		local acceptable_plate_location = true
		local minimum_distance = 2000 -- how much distance must be maintained between plate start locations
		local random_tile = WORLD:random_tile()
		repeat --- Check each candidate against all other tiles so far
		--	print("An attempt was made")
			random_tile = WORLD:random_tile() -- Assign random location for start of plate
			acceptable_plate_location = true
			if #micro_cluster_starts > 0 then
				for _, other_tile in pairs(micro_cluster_starts) do 
					local distance = random_tile:distance_to(other_tile)
					if distance >= minimum_distance or distance <= 1 then
					--	print("Acceptable Location")
					else
						acceptable_plate_location = false
						attempts = attempts + 1
					end	
				end
			end
			minimum_distance = minimum_distance - 1
		until (acceptable_plate_location == true)
		table.insert(micro_cluster_starts, random_tile)
	end
	
	for _, micro_start_tile in pairs(micro_cluster_starts) do
		micro_start_tile:set_debug_color(0.9, 0.0, 0.0)
		print("Count me!")
	end
	
	for i = 1, (num_micro_clusters) do  --- Now we set characteristics for the cluster and set members.
		
		local plates_in_cluster = love.math.random(4, 8)
		local minimum_distance_from_conspecifics = 100 -- how much distance must be maintained between plate start locations
		local maximum_distance_from_center = 1500 --- the maximum allowed distance a micro-plate can have from its center 
		local random_tile = WORLD:random_tile()
		
		--- Check each candidate against its cluster center
		for i2 = 1, (plates_in_cluster) do	--- Now we need to iterate through all potential plates in the cluster and assign location
			local terminal_variable = 500
			local acceptable_distance_from_others = true
			local acceptable_distance_from_center = true
			local abandon_plate_placement = false
			repeat	
				repeat --- Make sure start location for plate is sufficiently close to plate center
					acceptable_distance_from_center = true
					random_tile = WORLD:random_tile()
					local distance = random_tile:distance_to(micro_cluster_starts[i]) --- micro_cluster_starts[i] is the cluster center
				--	print(distance)
					if distance <= maximum_distance_from_center and distance >= 1 then
						--print("Acceptable Location found for microplate")
					else
						acceptable_distance_from_center = false
						attempts = attempts + 1
					end	
				until acceptable_distance_from_center == true		

				--- Now check this candidate against ALL other plate starts in the world so far
				repeat -- Getting stuck here
					if #random_tile_table > 0 then
						acceptable_distance_from_others = true
						for _, other_tile in pairs(random_tile_table) do 
							local distance = random_tile:distance_to(other_tile)
							if distance >= minimum_distance_from_conspecifics then --and distance >= 1 then
							--	print("Acceptable Location")
							else
								acceptable_distance_from_others = false
								attempts = attempts + 1
							end	
						end
						terminal_variable = terminal_variable - 1
						if terminal_variable == 0 then
							print("Uh oh, abandon plate placement")
						end
					end	
				until acceptable_distance_from_others == true or terminal_variable <= 0
			until acceptable_distance_from_center == true and acceptable_distance_from_others == true
			if abandon_plate_placement == false then
				table.insert(random_tile_table, random_tile)
		
			end
		end
	end
	
	for _, micro_plate_location in pairs(random_tile_table) do
		micro_plate_location:set_debug_color(0.0, 0.9, 0.0)
	--	print("Count me!")
	end

	for i = 1, (#random_tile_table) do --- Build plates in microplate clusters
		local plate = WORLD:new_plate()
		local expanion_rate = love.math.random(2, 3)
		plate.expansion_rate = expanion_rate
		--- We probably want to put a variableon these guys later that specify that that they are part of a cluster
	end

	total_plates = total_plates + #random_tile_table
	print("Total Plates: " .. tostring(total_plates))

	----------------------------------
	--- Set location of all plates ---
	----------------------------------

	local attempts = 0
	for i = 1, (non_cluster_plates) do 
		print("On Plate: " .. tostring(i))
		local acceptable_plate_location = true
		local minimum_distance = 3000 -- how much distance must be maintained between plate start locations
		local random_tile = WORLD:random_tile()
		repeat --- Check each candidate against all other tiles so far
		--	print("An attempt was made")
			random_tile = WORLD:random_tile() -- Assign random location for start of plate
			acceptable_plate_location = true
			if #random_tile_table > 0 then
				for _, other_tile in pairs(random_tile_table) do 
					local distance = random_tile:distance_to(other_tile)
					if distance >= minimum_distance or distance <= 1 then
					--	print("Acceptable Location")
					else
						acceptable_plate_location = false
						attempts = attempts + 1
					end	
				end
			end
			minimum_distance = minimum_distance - 1
		until (acceptable_plate_location == true)
		table.insert(random_tile_table, random_tile)
	end

	print("Time to rebuild start locations: " .. love.timer.getTime() - start)
	print("Number of Placement attempts: " .. tostring(attempts))
--	print("New Minimum Distance: " .. tostring(minimum_distance))
	
	-----------------------------------------------------
	--- Assign plate qualities specific to plate size ---
	-----------------------------------------------------

	if disable_plate_gen == true then
		
		for i = 1, (num_micro_plates + num_micro_ocean_plates) do 
			local plate = WORLD:new_plate()
			local expanion_rate = love.math.random(2, 3)
			plate.expansion_rate = expanion_rate
		end

		for i = 1, (num_small_plates + num_small_ocean_plates) do 
			local plate = WORLD:new_plate()
			local expanion_rate = love.math.random(3, 5)
			plate.expansion_rate = expanion_rate
		end

		for i = 1, (num_large_land_plates + num_large_ocean_plates) do 
			local plate = WORLD:new_plate()
			local expanion_rate = love.math.random(6, 8)
			plate.expansion_rate = expanion_rate
		end

		-----------------------------------------------------
		--- Assign plate qualities agnostic to plate size ---
		-----------------------------------------------------

		local iterator = 0
		for _, plate in pairs(WORLD.plates) do
			iterator = iterator + 1
			---@type Tile -- a type hint for autocompletion
			---@type Plate -- a type hint for autocompletion
			local plate_direction = love.math.random(4) -- create a random number between 1 and 4 (both inclusive)
			local plate_speed_floor = love.math.random(speed_floor, speed_ceiling) -- a random integer betweeen speed floor and speed ceil

			plate.speed = plate_speed_floor
			plate.direction = plate_direction
			plate.done_expanding = false
			plate.next_tiles = {} -- tiles which are being set this round but will be acting next round
			plate.current_tiles = {} -- tiles which are acting this round
			plate.tiles_to_check = {}
			plate.reserve_for_next_phase = {} -- When a tile is no longer able to expand, it is reserved for next phase after all other plates get a turn
			plate.plate_edge = {} -- Keep a record of all border tiles on a plate, aka, tiles which touch tiles of other plates.
			plate.plate_neighbors = {} -- Keep a record of the plate's neighboring plates
			plate.plate_boundaries = {} -- Record of all plate boundaries on this plate and their respective tiles.
			plate:add_tile(random_tile_table[iterator]) -- assign a starting tile to plate
			table.insert(plate.reserve_for_next_phase, random_tile_table[iterator])
		--	print("Added tile successfully")
		end

		local terminal_variable = 200 -- May want to replace this with a "tiles left" check in the future, but not really necessary

		---------------------------------------------------------------
		--- Expand plates until there are no more tiles to allocate ---		
		---------------------------------------------------------------

		repeat
			for _, plate in pairs(WORLD.plates) do -- Here we access each of the plates
			--	print("Plate: " .. tostring(plate.plate_id))
			--	print("Number Tiles: " .. tostring(#plate.reserve_for_next_phase))
				if #plate.reserve_for_next_phase > 0 then --- Do we have any tiles that need to "attack" neighbors?  If so, continue
					for _, plate_tile in pairs(plate.reserve_for_next_phase) do --- Expansion setup.  Assign expansion value to all starting tiles
						plate_tile.expansion_potential = plate_tile.expansion_potential + (plate.expansion_rate * (plate_tile.elevation / 1000 ) )-- We only want this assigned once per phase
						table.insert(plate.current_tiles, plate_tile)
					end
				--	print("Number Reserve Tiles: " .. tostring(#plate.reserve_for_next_phase))
					plate.reserve_for_next_phase = {}
					local phase = 1
					repeat	
						phase = phase + 1
						for _, plate_tile in pairs(plate.current_tiles) do -- Now we access each of the tiles and divide the left over values up among neighbors
							local num_valid_neighbors = 0
							for n in plate_tile:iter_neighbors() do -- Check valid neighbors first to determine how much we need to divide expansion value
								if n.plate == nil then
									num_valid_neighbors = num_valid_neighbors + 1
								end
							end -- end of neighbor iteration
							if num_valid_neighbors > 0 then --- If no valid neighbors, time to call it quits!	
							--	plate_tile.expansion_potential = plate_tile.expansion_potential + 5
								local each_tile_value = plate_tile.expansion_potential / num_valid_neighbors
								--- now we want to give these values to neighbors?
								for n in plate_tile:iter_neighbors() do -- check neighbors.  If nil, we want to add them next.
									if n.plate == nil then
										n.expansion_potential = n.expansion_potential + each_tile_value
										if n.already_added == false then
											table.insert(plate.tiles_to_check, n)
										end
										n.already_added = true
										-- We don't want to assign to a plate yet because we need all other potential tiles to contribute as well.
									end
								end -- end of neighbor iteration
								plate_tile.expansion_potential = 0
						--	else plate_tile.stop_expansion = true 
							
							end	
						end -- end of tile iteration
						-- Hm... but now we need to iterate through all of the new tiles that receieved goodies.
						for _, plate_tile in pairs(plate.tiles_to_check) do -- Now we do the expansion calculation and determine which tiles are added
							--print("			Expansion Potential: " .. tostring(plate_tile.expansion_potential))
						--	print("Expansion Potential: " .. tostring(plate_tile.expansion_potential))
							if plate_tile.value_to_overcome <= plate_tile.expansion_potential then
								plate_tile.expansion_potential = plate_tile.expansion_potential - plate_tile.value_to_overcome
								plate:add_tile(plate_tile)
								table.insert(plate.next_tiles, plate_tile)
								table.insert(plate.reserve_for_next_phase, plate_tile) -- We evaluate later for which ones are bordertiles
							end
							plate_tile.already_added = false
						end
					--	print("Number Tile-To-Check-Tiles: " .. tostring(#plate.tiles_to_check))
						plate.tiles_to_check = {}
						for _, tile in pairs(plate.current_tiles) do -- If previous current tile has no neighbors, then don't add back in to queue
							local num_valid_neighbors = 0
							for n in tile:iter_neighbors() do 
								if n.plate == nil then
									num_valid_neighbors = num_valid_neighbors + 1
								end
							end -- end of neighbor iteration
							if num_valid_neighbors > 0 then
								table.insert(plate.reserve_for_next_phase, tile)
							end

						--	if tile.stop_expansion == false then
						--		table.insert(plate.next_tiles, tile) --- otherwise... add back in.
						--	end
						end
					--	print("Number Next Tiles: " .. tostring(#plate.next_tiles))

						plate.current_tiles = {}
						for _, tile in pairs(plate.next_tiles) do
							table.insert(plate.current_tiles, tile)
						end
					--	print("Number Curent Tiles: " .. tostring(#plate.current_tiles))
						plate.next_tiles ={}

					until (0 == #plate.current_tiles or phase > 20)
				end
				--- Now we want to look over our reserved tiles and determine "true border" tiles
				for _, plate_tile in pairs(plate.reserve_for_next_phase) do --- Check for nil neighbors
					local num_valid_neighbors = 0
					for n in plate_tile:iter_neighbors() do -- Check valid neighbors first to determine how much we need to divide expansion value
						if n.plate == nil then
							num_valid_neighbors = num_valid_neighbors + 1
						end
					end -- end of neighbor iteration
					if num_valid_neighbors > 0 then -- If there is at least one elligible neighbor, add for next phase.
						table.insert(plate.current_tiles, plate_tile)
					end
				end
			end -- end of plate iteration

			terminal_variable = terminal_variable - 1

		until (0 >= terminal_variable)
		print("Plates spawned!")

		-------------------------------------------------------
		--- Create plate perimeter and find plate neighbors ---
		-------------------------------------------------------

		local plates_removed = 0
		local recalculate_due_to_envelopment = false
		repeat --- repeat assignment of plate boundaries once if enveloped plates exist
			print("Beginning Perimeter Construction!")
			if recalculate_due_to_envelopment == true then
				recalculate_due_to_envelopment = false
			end
			start = love.timer.getTime()

			local tabb = require "engine.table"
			for _, plate in pairs(WORLD.plates) do
			--	local size = tabb.size(plate.tiles)
			--	print("Number of tiles: " .. tostring(size))
				local plate_id = plate.plate_id
				for _, tile in pairs(plate.tiles) do
					local has_foreign_neighbor = false
					for n in tile:iter_neighbors() do -- Check valid neighbors first to determine how much we need to divide expansion value
						if n.plate ~= tile.plate then
							has_foreign_neighbor = true
							local plate_already_in_list = false
							if #plate.plate_neighbors == 0 then
								table.insert(plate.plate_neighbors, n.plate)
							else
								for _, neigh_plate in pairs(plate.plate_neighbors) do
									if neigh_plate == n.plate then
										plate_already_in_list = true
									end
								end
								if plate_already_in_list == false then	
									table.insert(plate.plate_neighbors, n.plate)
								end
							end

							--- Now go ahead and add that neighbor plate into the list.

						end
					end 
					if has_foreign_neighbor == true then
						table.insert( plate.plate_edge, tile)
					end
				end
			end

			-------------------------------------
			--- Populate Plate Boundary Lists ---
			-------------------------------------

			for _, plate in pairs(WORLD.plates) do
				for _, neighbor_plate in pairs(plate.plate_neighbors) do --- Iterate through plate neighbors
					local temp_boundary = {} --- create table of tiles
					local temp_boundary_tiles = {}
					for _, plate_tile in pairs(plate.plate_edge) do
						--- For each plate perimeter, check all neighbors
						local should_be_added = false
						for n in plate_tile:iter_neighbors() do -- Check valid neighbors and insure that we only add a specific tile to boundaries just once
							if n.plate == neighbor_plate then
								should_be_added = true		
							end
						end -- end of neighbor iteration
						if should_be_added == true then
							table.insert(temp_boundary_tiles, plate_tile)
						end
					end
					temp_boundary.tiles = temp_boundary_tiles
					temp_boundary.neigh_plate = neighbor_plate

					table.insert(plate.plate_boundaries, temp_boundary) --- add table of tiles to plate_boundaries table
				--	table.insert(plate.plate_boundaries, neighbor_plate) --- Add corresponding neighbor plate to plate boundary
				end
			end
			print("Time to construct boundaries: " .. love.timer.getTime() - start)
			-- Just debug stuff to remove later ---
		--	for _, plate in pairs(WORLD.plates) do
		--	--	print("Number of boundaries : " .. tostring(#plate.plate_boundaries))
		--		for _, boundary in pairs(plate.plate_boundaries) do
		--			local red = love.math.random(1, 100) / 100 
		--			local green = love.math.random(1, 100) / 100
		--			local blue = love.math.random(1, 100) / 100
		--			for _, boundary_tile in pairs(boundary.tiles) do
		--				boundary_tile:set_debug_color(red, green, blue)
		--			end
		--		end
		--	end

			----------------------------------
			--- Check for Enveloped Plates ---
			----------------------------------

			local plates_to_remove = {} --- Keep a list of plates that need to be removed
			for _, plate in pairs(WORLD.plates) do  --- NOTE MAKE SURE THIS NEVER RUNS MORE THAN ONCE!!! ---

				local perimeter_number = #plate.plate_edge
				print("---------------------------------------------")
				print("Perimeter Size: " .. tostring(perimeter_number))
				local plate_already_dead = false
				for _, boundary in pairs(plate.plate_boundaries) do
					if plate_already_dead == false then 
						local boundary_size = #boundary.tiles
						print("Boundary Size: " .. tostring(boundary_size))
						if perimeter_number * envelopment_threshold <= boundary_size then
							print("Uh oh, a time to Kill!")
							recalculate_due_to_envelopment = true
							plate_already_dead = true
							table.insert(plates_to_remove, plate)
							local red = love.math.random(1, 100) / 100 
							local green = love.math.random(1, 100) / 100
							local blue = love.math.random(1, 100) / 100

							for _, tile in pairs(plate.tiles) do
								boundary.neigh_plate:add_tile(tile)
								tile:set_debug_color(red, green, blue)
							end
						end
					end
				end
			end
			if recalculate_due_to_envelopment == true then
				for _, plate in pairs(WORLD.plates) do --- set all neighbor and edge data to empty so we can relculate
					plate.plate_boundaries = {}
					plate.plate_edge = {}
					plate.plate_neighbors = {}
				end
				for _, plate in pairs(plates_to_remove) do --- Remove plate from global plate list
					WORLD.plates[plate.plate_id] = nil
					plates_removed = plates_removed + 1
				end
			end
		until (recalculate_due_to_envelopment == false)
	end
	print("Plates removed due to envelopment: " .. tostring(plates_removed))
	--- We want to first check to see if envelopment is a problem at all, because there is no need to run the rejigger 
	--- if there is no problem!
	--- So first we check for problem plates.  If plate is a problem, immediately transfer all tiles to enveloping plate.
	--- Then kill plate?  However, we do need to keep a ticker or boolean values that records that a plate is dehd.
	--- If plate is dehd, we iterate through all plates, and wipe out all plate neighbors, all plate boundaries, and all plate perimeters.
	--- Then we reconstruct them all boundaries.



	----------------------------------------------------------------------------
	--- Subroutine to remove all enveloped plates beyond a certain threshold ---
	----------------------------------------------------------------------------

	--- is there a cleaner way to do this?  In theory the cleaner way would be to do this process before we calculate plate
	--- boundaries.

	--- Iterate through plates
		--- Count all tiles in boundary.  Divide number by total perimeter of plate.
		--- if values is above X, remove plate... Take all tile members of plate we want to delete, and add to plate that is
		--- the swallower.  But then, we need to iterate through all neighbor plates, remove 



end
return plate_gen




--- What we need ---
--- We need discrete plate boundaries, aka, a list of boundaries that a plate has with all its neighbors.


--- Plan ---

--- We need to make a table while defining plates which stores plate boundaries and their respective tiles.  So that should
--- be a table of tables?




--- Definitely need to add in subroutine to remove enveloped plates, because minor plates are far too common in the middle of larger plates.
--- We may even want to do a calculation where we sum up all of the border tiles of a plate, have a percentage threshold,
--- and if that threshold is met, remove plate and add it to other plate.

--- Also want to add microplate clustering so we can get cool effects like Mediterranean seas.













	------------------------------------------------------------------
	--- Just a buncha debug code, comment out and move below later ---
	------------------------------------------------------------------

--	for _, plate in pairs(WORLD.plates) do
--	--	print("Plate Number: " .. tostring(plate.plate_id))
--		for _, plate_tile in pairs(plate.plate_edge) do
--			plate_tile:set_debug_color(0, 0.66, 0)
--		end
--	--	print("Total Neighbor Plates: " .. tostring(#plate.plate_neighbors))
--	--	for _, neigh_plate in pairs(plate.plate_neighbors) do
--	--		print("Plate Neighbors: " .. tostring(neigh_plate.plate_id))
--	--	end
--	end


	--	random_tile_table = {}
	--	sufficiently_distanced = 0
	--	attempts = attempts + 1
	--	minimum_distance = minimum_distance - 0.5 -- Each attempt, reduce minimum distance so we don't get stuck in eternal loop
	--	for i = 1, (total_plates) do 
	--		local random_tile = WORLD:random_tile()
	--		table.insert(random_tile_table, random_tile)
	--	end
	--	for _, tile in pairs(random_tile_table) do -- Here we access each of the plates
	--		for _, other_tile in pairs(random_tile_table) do -- Here we access each of the plates
	--			local distance = tile:distance_to(other_tile)
	--			if distance >= minimum_distance or distance <= 1 then
	--				sufficiently_distanced = sufficiently_distanced + 1
	--			end	
	--		end
	--	end
	--	print("Total successful checks " .. tostring(sufficiently_distanced))
--	until (sufficiently_distanced == total_plates * total_plates)