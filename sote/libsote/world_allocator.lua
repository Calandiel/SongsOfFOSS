local icosa_defines = require("libsote.icosa_defines")

local function calc_edge_tile_count(size)
    return size - 1
end

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

            local neighbor_face, neighbor_edge = icosa_defines.neighbor_face_edge_at(fi, ei)
            edge.neighbor_face = neighbor_face
            edge.neighbor_edge = neighbor_edge

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

local function icosa_edge_index(q, r, size)
    local s = -(q + r)
    if q - s == size then return 2 end
    if r - q == size then return 1 end
    if s - r == size then return 3 end
    return 0
end

local function icosa_vertex_index(q, r, size)
    if q == size then return 1 end
    if q == -size then return 3 end
    if r == size then return 2 end
    return 0
end

local function resolve_index_for_penta(q, r, face_index, icosa, index)
    local vi = icosa.faces[face_index].vertices[icosa_vertex_index(q, r, icosa.size)]

    if icosa.vertices[vi] ~= -1 then
        return icosa.vertices[vi], index
    end

    icosa.vertices[vi] = index

    return icosa.vertices[vi], index + 1
end

local function resolve_index_for_edge(q, r, face_index, icosa, index)
    local ei = icosa_edge_index(q, r, icosa.size)
    local edge = icosa.faces[face_index].edges[ei]
    local nei = edge.neighbor_edge

    local ti = 0
    local nti = 0

    if ei == 1 then
        ti = r
        if edge.neighbor_edge == 3 then
            nti = -r
        else
            nti = icosa.size - ti
        end
    elseif ei == 2 then
        ti = q
        if edge.neighbor_edge == 2 then
            nti = icosa.size - q
        elseif edge.neighbor_edge == 3 then
            nti = q
        end
    elseif ei == 3 then
        ti = -r
        if edge.neighbor_edge == 2 then
            nti = -r
        elseif edge.neighbor_edge == 3 then
            nti = icosa.size + r
        end
    end

    if edge.tiles[ti] ~= -1 then
        return edge.tiles[ti], index
    end

    edge.tiles[ti] = index
    icosa.faces[edge.neighbor_face].edges[edge.neighbor_edge].tiles[nti] = index

    return edge.tiles[ti], index + 1
end

local world_allocator = {}

function world_allocator:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function world_allocator:allocate(size)
    local world = require("libsote.world"):new(size)

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

    for fi = 1, 20 do
        for q = -size, size do
            for r = -size, size do
                if not world:is_valid(q, r) then goto continue end

                if world:is_edge(q, r) then
                    local resolved_index = -1

                    if world:is_penta(q, r) then
                        resolved_index, index = resolve_index_for_penta(q, r, fi, icosa_obj, index)
                    else
                        resolved_index, index = resolve_index_for_edge(q, r, fi, icosa_obj, index)
                    end

                    world:_set_index(q, r, fi, resolved_index)
                else
                    world:_set_index(q, r, fi, index)
                    index = index + 1
                end

                ::continue::
            end
        end
    end

    if not world:check() then
        return nil
    end

    return world
end

return world_allocator