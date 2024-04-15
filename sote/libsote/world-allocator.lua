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

	local ti = 0
	local nti = 0

	if ei == 1 then
		ti = r
		if nei == 3 then
			nti = r
		else
			nti = icosa.size - r
		end
	elseif ei == 2 then
		ti = q
		if nei == 3 then
			nti = q
		else
			nti = icosa.size - q
		end
	elseif ei == 3 then
		ti = -r
		if nei == 3 then
			nti = icosa.size + r
		else
			nti = -r
		end
	end

	if edge.tiles[ti] ~= -1 then
		return edge.tiles[ti], index
	end

	edge.tiles[ti] = index
	icosa.faces[edge.neighbor_face].edges[nei].tiles[nti] = index

	return edge.tiles[ti], index + 1
end

local hexu = require "libsote.hex-utils"

---@param size number
---@param seed number
function wa.allocate(size, seed)
	local world = require("libsote.world"):new(size, seed)

	local icosa_obj = build_icosa(size)

	for q = -size, size do
		for r = -size, size do
			if not world:is_valid(q, r) then goto continue end

			for face = 1, 20 do
				world:_set_empty(q, r, face)
			end

			::continue::
		end
	end

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

				local lat, lon = hexu.hex_coords_to_latlon(q, r, face, size)
				world:_set_latlon(resolved_index, lat, lon)

				index = next_index
			end

			::continue::
		end
	end

	if not world:check() then
		return nil
	end

	return world
end

return wa