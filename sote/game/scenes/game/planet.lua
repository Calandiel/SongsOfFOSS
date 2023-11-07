local cpml = require "cpml"

local pla = {}

function pla.get_planet_mesh()
	local vertices = {}
	local mesh_format = {
		{ "VertexPosition", "float", 3 },
		{ "VertexTexCoord", "float", 2 },
		{ "Face", "float", 1 },
	}

	local add_vert = function(x, y, z, u, v, f)
		table.insert(vertices, {
			x, y, z, u, v, f
		})
	end

	local cube_verts = {
		{ 1.0, 1.0, 1.0 }, -- 0
		{ 1.0, 1.0, -1.0 }, -- 1
		{ -1.0, 1.0, 1.0 }, -- 2
		{ -1.0, 1.0, -1.0 }, -- 3
		{ 1.0, -1.0, 1.0 }, -- 4
		{ 1.0, -1.0, -1.0 }, -- 5
		{ -1.0, -1.0, 1.0 }, -- 6
		{ -1.0, -1.0, -1.0 }, -- 7
	}

	local cube_uvs = {
		{ 0.0, 0.0 }, -- 0
		{ 1.0, 0.0 }, -- 1
		{ 0.0, 1.0 }, -- 2
		{ 1.0, 1.0 }, -- 3
	}

	local cube_face_ids = {
		-- TOP FACE
		{ 4, 4, 4 },
		{ 4, 4, 4 },
		-- RIGHT FACE
		{ 3, 3, 3 },
		{ 3, 3, 3 },
		-- LEFT FACE
		{ 1, 1, 1 },
		{ 1, 1, 1 },
		-- FRONT FACE
		{ 0, 0, 0 },
		{ 0, 0, 0 },
		-- BACK FACE
		{ 2, 2, 2 },
		{ 2, 2, 2 },
		-- BOTTOM FACE
		{ 5, 5, 5 },
		{ 5, 5, 5 },
	}

	local cube_tris_uvs = {
		-- TOP FACE
		{ 3, 2, 1 },
		{ 0, 1, 2 },
		-- RIGHT FACE
		{ 3, 2, 0 },
		{ 0, 1, 3 },
		-- LEFT FACE
		{ 3, 2, 1 },
		{ 0, 1, 2 },
		-- FRONT FACE
		{ 3, 0, 1 },
		{ 2, 0, 3 },
		-- BACK FACE
		{ 1, 2, 0 },
		{ 1, 3, 2 },
		-- BOTTOM FACE
		{ 3, 2, 0 },
		{ 0, 1, 3 },
	}

	local cube_tris = {
		-- TOP FACE
		{ 0, 1, 2 },
		{ 3, 2, 1 },
		-- RIGHT FACE
		{ 1, 0, 4 },
		{ 4, 5, 1 },
		-- LEFT FACE
		{ 2, 3, 6 },
		{ 7, 6, 3 },
		-- FRONT FACE
		{ 0, 6, 4 },
		{ 2, 6, 0 },
		-- BACK FACE
		{ 7, 1, 5 },
		{ 7, 3, 1 },
		-- BOTTOM FACE
		{ 5, 4, 6 },
		{ 6, 7, 5 },
	}

	for i = 1, #cube_tris do
		local cube_tri = cube_tris[i]
		local cube_uv = cube_tris_uvs[i]
		local cube_face = cube_face_ids[i]

		for o = 1, 3 do
			local t = cube_tri[o]
			local u = cube_uv[o]
			local f = cube_face[o]

			local ver = cube_verts[t + 1]
			local uv = cube_uvs[u + 1]

			add_vert(
				ver[1], ver[2], ver[3], uv[1], uv[2], f
			)
		end
	end

	local function subdivide()
		local old_vertices = vertices
		local llen = #vertices
		local tris = llen / 3

		vertices = {} -- replace the old reference...

		-- A small helper function...
		local function quick_add_vertex(pos, uv, face)
			add_vert(pos.x, pos.y, pos.z, uv.x, uv.y, face)
		end

		for t = 1, tris do
			local tri_offset = t * 3 - 2
			local a = old_vertices[tri_offset]
			local b = old_vertices[tri_offset + 1]
			local c = old_vertices[tri_offset + 2]

			local aa = cpml.vec3(a[1], a[2], a[3])
			local bb = cpml.vec3(b[1], b[2], b[3])
			local cc = cpml.vec3(c[1], c[2], c[3])
			local mid_ab = bb + (aa - bb) / 2
			local mid_ac = cc + (aa - cc) / 2
			local mid_bc = cc + (bb - cc) / 2

			local uv_aa = cpml.vec2(a[4], a[5])
			local uv_bb = cpml.vec2(b[4], b[5])
			local uv_cc = cpml.vec2(c[4], c[5])
			local uv_mid_ab = uv_bb + (uv_aa - uv_bb) / 2
			local uv_mid_ac = uv_cc + (uv_aa - uv_cc) / 2
			local uv_mid_bc = uv_cc + (uv_bb - uv_cc) / 2

			local face = a[6]

			quick_add_vertex(aa, uv_aa, face)
			quick_add_vertex(mid_ab, uv_mid_ab, face)
			quick_add_vertex(mid_ac, uv_mid_ac, face)

			quick_add_vertex(mid_ab, uv_mid_ab, face)
			quick_add_vertex(bb, uv_bb, face)
			quick_add_vertex(mid_bc, uv_mid_bc, face)

			quick_add_vertex(mid_ac, uv_mid_ac, face)
			quick_add_vertex(mid_bc, uv_mid_bc, face)
			quick_add_vertex(cc, uv_cc, face)

			quick_add_vertex(mid_ac, uv_mid_ac, face)
			quick_add_vertex(mid_ab, uv_mid_ab, face)
			quick_add_vertex(mid_bc, uv_mid_bc, face)
		end

	end

	local function normalize()
		for _, v in pairs(vertices) do
			local ll = math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
			v[1] = v[1] / ll
			v[2] = v[2] / ll
			v[3] = v[3] / ll
		end
	end

	-- Subdivide the mesh!
	subdivide()
	subdivide()
	subdivide()
	subdivide()
	subdivide()
	normalize()
	print("Planet mesh vertex count: " .. tostring(#vertices))

	return love.graphics.newMesh(
		mesh_format,
		vertices,
		"triangles",
		"static"
	)
end

return pla
