-- TODO: use an actual min heap


local pa = {}

---@param tab table<Province, number>
---@return Province, number
local function get_min(tab)
	local cost = math.huge
	local ret = nil
	for prov, prov_cost in pairs(tab) do
		if prov_cost < cost then
			cost = prov_cost
			ret = prov
		end
	end

	assert(ret ~= nil)

	tab[ret] = nil
	return ret, cost
end

---@alias province_scalar_field fun(province: Province): number

---@type province_scalar_field
local function dummy_speed(province)
	return 1
end

---Pathfinds from origin province to target province, returns the travel time in hours and the path itself (can only pathfind from land to land or from sea to sea)
---@param origin Province
---@param target Province
---@param speed_modifier nil|province_scalar_field Adjusts movement costs of provinces
---@param allowed_provinces table<Province, Province> Provinces allowed for pathfinding
---@return number,table<number,Province>|nil
function pa.pathfind(origin, target, speed_modifier, allowed_provinces)

	if speed_modifier == nil then
		speed_modifier = dummy_speed
	end

	local origin_center = DATA.province_get_center(origin)
	local target_center = DATA.province_get_center(target)

	if DATA.tile_get_pathfinding_index(origin_center) ~= DATA.tile_get_pathfinding_index(target_center) then
		return math.huge, nil
	end

	---@type table<Province, number>
	local qq = {} -- maps provinces to their distances
	---@type table<Province, number>
	local distance_cache = {}
	---@type table<Province, boolean>
	local visited = {}
	---@type table<Province, Province>
	local prev = {}

	--[[
15         u ← Q.extract_min()                    // Remove and return best vertex
16         for each neighbor v of u:              // only v that are still in Q
17             alt ← dist[u] + Graph.Edges(u, v)
18             if alt < dist[v]:
19                 dist[v] ← alt
20                 prev[v] ← u
21                 Q.decrease_priority(v, alt)
22
23     return dist, prev
	]]

	-- queue size
	---@type number
	local q_size = 1
	qq[origin] = 0
	distance_cache[origin] = 0

	-- Djikstra flood fill thing
	while q_size > 0 do
		local prov, dist = get_min(qq)
		q_size = q_size - 1
		visited[prov] = true

		if prov == target then
			break -- We found the path!
		end
		local prov_center = DATA.province_get_center(prov)
		local prov_movement_cost = DATA.province_get_movement_cost(prov)

		DATA.for_each_province_neighborhood_from_origin(prov, function (connection)
			local neigh = DATA.province_neighborhood_get_target(connection)
			local neigh_center = DATA.province_get_center(neigh)
			local neigh_movement_cost = DATA.province_get_movement_cost(neigh)

			if DATA.tile_get_is_land(neigh_center) == DATA.tile_get_is_land(prov_center) and allowed_provinces[neigh] then
				if visited[neigh] ~= true then
					local speed_n = speed_modifier(neigh)
					local speed_prov = speed_modifier(prov)
					local alt = dist + 0.5 * (neigh_movement_cost / speed_n + prov_movement_cost / speed_prov)
					local old_distance = distance_cache[neigh] or math.huge

					if alt < old_distance then
						distance_cache[neigh] = alt
						prev[neigh] = prov
						if qq[neigh] == nil then
							qq[neigh] = alt

							---@type number
							q_size = q_size + 1
						else
							qq[neigh] = alt
						end
					end
				end
			end
		end)
	end

	-- Get the path

	---@type Province[]
	local path = {}
	local u = target
	local target_movement_cost = DATA.province_get_movement_cost(target)
	local total_cost = target_movement_cost / speed_modifier(target)
	while prev[u] do
		path[#path + 1] = u
		u = prev[u]
		local u_movement_cost = DATA.province_get_movement_cost(u)

		---@type number
		total_cost = total_cost + u_movement_cost / speed_modifier(u)
	end
	--total_cost = total_cost - 0.5 * (origin.movement_cost + target.movement_cost)

	return total_cost, path
end

---@param hours number
---@return number
function pa.hours_to_travel_days(hours)
	return hours / 12.0 -- Assume 12 hours of travel every day
end

return pa
