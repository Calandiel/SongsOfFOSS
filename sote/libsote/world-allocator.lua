local wa = {}

local icosa_defines = require("sote.libsote.icosa-defines")

---@param size number
---@return number
local function calc_edge_tile_count(size)
	return size - 1
end

---@param size number
---@return table
local function build_icosa(size)
	local icosa = {
		size = size,
		faces = {},
		vertices = {}
	}

	local edge_tile_count = calc_edge_tile_count(size)

	for fi = 1, 20 do
		icosa.faces[fi] = {
			edges = {},
			vertices = {}
		}

		local face = icosa.faces[fi]

		for ei = 1, 3 do
			face.edges[ei] = {
				neighbor_face = 0,
				neighbor_edge = 0,
				tiles = {}
			}
			local edge = face.edges[ei]

			edge.neighbor_face, edge.neighbor_edge = icosa_defines.neighbor_face_edge_at(fi, ei)

			for i = 1, edge_tile_count do
				edge.tiles[i] = -1
			end
		end

		for vi = 1, 3 do
			face.vertices[vi] = icosa_defines.face_vertices[fi][vi]
		end
	end

	for vi = 1, 12 do
		icosa.vertices[vi] = -1
	end

	return icosa
end

---@param q number
---@param r number
---@param size number
---@return number
local function icosa_edge_index(q, r, size)
	local s = -(q + r)
	if q - s == size then return 2 end
	if r - q == size then return 1 end
	if s - r == size then return 3 end
	return 0
end

---@param q number
---@param r number
---@param size number
---@return number
local function icosa_vertex_index(q, r, size)
	if q == size then return 1 end
	if q == -size then return 3 end
	if r == size then return 2 end
	return 0
end

---@param vi number vertex/penta index 1..3
---@return number, number the indices of the 2 edges that are connected to the vertex
local function icosa_edges_for_subpenta(vi)
	if vi == 1 then
		return 2, 3
	elseif vi == 2 then
		return 1, 2
	elseif vi == 3 then
		return 1, 3
	else
		error("invalid vertex index")
	end
end

---@param q number
---@param r number
---@param face number
---@param icosa table
---@param index number
---@return number, number
local function resolve_index_for_penta(q, r, face, icosa, index)
	local vi = icosa.faces[face].vertices[icosa_vertex_index(q, r, icosa.size)]

	if icosa.vertices[vi] ~= -1 then
		return icosa.vertices[vi], index
	end

	icosa.vertices[vi] = index

	return icosa.vertices[vi], index + 1
end

---@param ei number edge index
---@param q number
---@param r number
---@param nei number neighbor edge index
---@param size number
---@return number, number local tile index, neighbor tile index
local function resolve_tile_indices_for_edge(ei, q, r, nei, size)
	if ei == 1 then
		if nei == 3 then
			return r, r
		else
			return r, size - r
		end
	elseif ei == 2 then
		if nei == 3 then
			return q, q
		else
			return q, size - q
		end
	elseif ei == 3 then
		if nei == 3 then
			return -r, size + r
		else
			return -r, -r
		end
	else
		error("invalid edge index")
	end
end

---@param q number
---@param r number
---@param face number
---@param icosa table
---@param index number
---@return number, number
local function resolve_index_for_edge(q, r, face, icosa, index)
	local ei = icosa_edge_index(q, r, icosa.size)
	local edge = icosa.faces[face].edges[ei]
	local nei = edge.neighbor_edge

	local ti, nti = resolve_tile_indices_for_edge(ei, q, r, nei, icosa.size)

	if edge.tiles[ti] ~= -1 then
		return edge.tiles[ti], index
	end

	edge.tiles[ti] = index
	icosa.faces[edge.neighbor_face].edges[nei].tiles[nti] = index

	return edge.tiles[ti], index + 1
end

---@param vi number vertex index
---@param size number
---@return number, number hex coordinates q and r
local function hex_for_penta_tile(vi, size)
	if vi == 1 then
		return size, -size
	elseif vi == 2 then
		return 0, size
	elseif vi == 3 then
		return -size, 0
	else
		error("invalid vertex index")
	end
end

---@param ei number edge index
---@param ti number tile index
---@param size number
---@return number, number hex coordinates q and r
local function hex_for_edge_tile(ei, ti, size)
	if ei == 1 then
		return -size + ti, ti
	elseif ei == 2 then
		return ti, size - 2 * ti
	elseif ei == 3 then
		return -size + 2 * ti, -ti
	else
		error("invalid edge index")
	end
end

---@param q number
---@param r number
---@return number, number
local function north(q, r)
	return q + 1, r - 1
end

---@param q number
---@param r number
---@return number, number
local function northeast(q, r)
	return q + 1, r
end

---@param q number
---@param r number
---@return number, number
local function southeast(q, r)
	return q, r + 1
end

---@param q number
---@param r number
---@return number, number
local function south(q, r)
	return q - 1, r + 1
end

---@param q number
---@param r number
---@return number, number
local function southwest(q, r)
	return q - 1, r
end

---@param q number
---@param r number
---@return number, number
local function northwest(q, r)
	return q, r - 1
end

local all_helpers = { north, northeast, southeast, south, southwest, northwest }
local e1_helpers = { northwest, north, northeast }
local e2_helpers = { south, southwest, northwest }
local e3_helpers = { northeast, southeast, south }
local se1_helpers = { southwest, northwest, north, northeast, southeast }
local se2_helpers = { north, northwest, southwest, south, southeast }
local se3_helpers = { north, northeast, southeast, south, southwest }
local sp1_helpers = { north, southwest, south, southeast }
local sp2_helpers = { southeast, north, northwest, southwest }
local sp3_helpers = { southwest, north, northeast, southeast }

local function helpers_for_edge(ei)
	if ei == 1 then
		return e1_helpers
	elseif ei == 2 then
		return e2_helpers
	elseif ei == 3 then
		return e3_helpers
	else
		error("invalid edge index")
	end
end

local function helpers_for_subedge(ei)
	if ei == 1 then
		return se1_helpers
	elseif ei == 2 then
		return se2_helpers
	elseif ei == 3 then
		return se3_helpers
	else
		error("invalid edge index")
	end
end

local function helpers_for_subpenta(vi)
	if vi == 1 then
		return sp1_helpers
	elseif vi == 2 then
		return sp2_helpers
	elseif vi == 3 then
		return sp3_helpers
	else
		error("invalid vertex index")
	end
end

---@param q number
---@param r number
---@param f number face
---@return table
local function resolve_neighbors_for_inner(q, r, f)
	local neighbors = {}

	for i = 1, 6 do
		neighbors[i] = {}
		neighbors[i].f = f
		neighbors[i].q, neighbors[i].r = all_helpers[i](q, r)
	end

	return neighbors
end

-- local logger = require("libsote.debug-loggers").get_neighbors_logger("d:/temp")

---@param q number
---@param r number
---@param f number face
---@return table
local function resolve_neighbors_for_edge(q, r, f, size)
	local neighbors = {}

	for i = 1, 6 do
		neighbors[i] = {}
	end

	local ei = icosa_edge_index(q, r, size)
	local helpers = helpers_for_edge(ei)

	for i = 1, 3 do
		neighbors[i].f = f
		neighbors[i].q, neighbors[i].r = helpers[i](q, r)
	end

	local nf, nei = icosa_defines.neighbor_face_edge_at(f, ei)
	local _, nti = resolve_tile_indices_for_edge(ei, q, r, nei, size)
	local nq, nr = hex_for_edge_tile(nei, nti, size)

	helpers = helpers_for_edge(nei)

	for i = 4, 6 do
		neighbors[i].f = nf
		neighbors[i].q, neighbors[i].r = helpers[i - 3](nq, nr)
	end

	return neighbors
end

---@param q number
---@param r number
---@param f number face
---@return table
local function resolve_neighbors_for_subedge(q, r, f, size)
	local neighbors = {}

	for i = 1, 6 do
		neighbors[i] = {}
	end

	local ei = icosa_edge_index(q, r, size - 1) -- sub edge
	local helpers = helpers_for_subedge(ei)

	for i = 1, 5 do
		neighbors[i].f = f
		neighbors[i].q, neighbors[i].r = helpers[i](q, r)
	end

	local nf, nei = icosa_defines.neighbor_face_edge_at(f, ei)
	local _, nti = resolve_tile_indices_for_edge(ei, q, r, nei, size - 1) -- sub edge
	local nq, nr = hex_for_edge_tile(nei, nti, size - 1) -- sub edge

	neighbors[6].f = nf
	neighbors[6].q, neighbors[6].r = nq, nr

	return neighbors
end

---@param vi number vertex index
---@param q number
---@param r number
---@param f number face
---@param size number
---@return table
local function resolve_neighbors_for_subpenta(vi, q, r, f, size)
	local neighbors = {}

	for i = 1, 6 do
		neighbors[i] = {}
	end

	local helpers = helpers_for_subpenta(vi)

	for i = 1, 4 do
		neighbors[i].f = f
		neighbors[i].q, neighbors[i].r = helpers[i](q, r)
	end

	local function resolve_subpenta_neighbour(ei)
		local nf, nei = icosa_defines.neighbor_face_edge_at(f, ei)
		local _, nti = resolve_tile_indices_for_edge(ei, q, r, nei, size - 1) -- sub edge
		local nq, nr = hex_for_edge_tile(nei, nti, size - 1) -- sub edge
		return nf, nq, nr
	end

	local ei1, ei2 = icosa_edges_for_subpenta(vi)

	neighbors[5].f, neighbors[5].q, neighbors[5].r = resolve_subpenta_neighbour(ei1)

	neighbors[6].f, neighbors[6].q, neighbors[6].r = resolve_subpenta_neighbour(ei2)

	return neighbors
end

local function init_world(world)
	for q = -world.size, world.size do
		for r = -world.size, world.size do
			if not world:is_valid(q, r) then goto continue end

			for face = 1, 20 do
				world:_set_empty(q, r, face)
			end

			::continue::
		end
	end

	world:_init_neighbours()
end

local function build_neighbors(world)
	for q = -world.size, world.size do
		for r = -world.size, world.size do
			if not world:is_valid(q, r) then goto continue end

			local neighbors = {}

			for face = 1, 20 do
				if world:is_edge(q, r) then
					if world:is_penta(q, r) then
						-- do nothing, will be processed separately
					else
						neighbors = resolve_neighbors_for_edge(q, r, face, world.size)
					end
				elseif world:is_subedge(q, r) then
					if world:is_subpenta(q, r) then
						-- do nothing, will be processed separately
					else
						neighbors = resolve_neighbors_for_subedge(q, r, face, world.size)
					end
				else
					neighbors = resolve_neighbors_for_inner(q, r, face)
				end

				world:_set_neighbors(q, r, face, neighbors)
			end

			::continue::
		end
	end

	-- loop over all 20 vertex pentagon tiles
	for penta = 1,#icosa_defines.vertex_faces do
		local penta_neighbours = {}

		-- loop over the 5 adjacent faces of the vertex
		for fi = 1, 5 do
			penta_neighbours[fi] = {}

			local face, vi = icosa_defines.face_vertex_at(penta, fi)
			local q, r = hex_for_penta_tile(vi, world.size - 1) -- sub penta

			penta_neighbours[fi].f = face
			penta_neighbours[fi].q, penta_neighbours[fi].r = q, r

			local subpenta_neighbours = resolve_neighbors_for_subpenta(vi, q, r, face, world.size)
			world:_set_neighbors(q, r, face, subpenta_neighbours)
		end

		local first_face, first_vi = icosa_defines.face_vertex_at(penta, 1)
		local first_q, first_r = hex_for_penta_tile(first_vi, world.size)

		world:_set_neighbors(first_q, first_r, first_face, penta_neighbours)
	end
end

-- local hexu = require "libsote.hex-utils"

---@param size number
---@param seed number
function wa.allocate(size, seed)
	local world = require("libsote.world"):new(size, seed)

	init_world(world)

	local icosa_obj = build_icosa(size)

	local index = 0
	local next_index = 0

	for q = -size, size do
		for r = -size, size do
			if not world:is_valid(q, r) then goto continue end

			for face = 1, 20 do
				local resolved_index = index

				if world:is_edge(q, r) then
					if world:is_penta(q, r) then
						resolved_index, next_index = resolve_index_for_penta(q, r, face, icosa_obj, index)
					else
						resolved_index, next_index = resolve_index_for_edge(q, r, face, icosa_obj, index)
					end
				else
					next_index = index + 1
				end

				world:_set_index(q, r, face, resolved_index)

				-- local lat, lon = hexu.hex_coords_to_latlon(q, r, face - 1, size)
				-- world:_set_latlon(resolved_index, lat, lon)

				index = next_index
			end

			::continue::
		end
	end

	build_neighbors(world)

	if not world:check() then
		return nil
	end

	return world
end

return wa