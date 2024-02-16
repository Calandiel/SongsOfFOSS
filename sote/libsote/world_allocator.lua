--- face 1..20
---    vertex 1..12
local icosa_face_vertices = {
    { 1,  5,  2}, ---  1
    {10,  2,  5}, ---  2
    { 5,  6, 10}, ---  3
    { 4, 10,  6}, ---  4
    { 4,  3,  8}, ---  5
    { 4,  6,  3}, ---  6
    {11,  8,  2}, ---  7
    { 1, 11,  9}, ---  8
    { 1,  9,  5}, ---  9
    { 3,  9, 11}, --- 10
    { 6,  5,  9}, --- 11
    { 9,  3,  6}, --- 12
    { 1,  2,  7}, --- 13
    {12,  7,  2}, --- 14
    { 4, 12, 10}, --- 15
    { 8, 11,  7}, --- 16
    { 4,  8, 12}, --- 17
    { 7, 12,  8}, --- 18
    { 1,  7, 11}, --- 19
    { 2, 10, 12}  --- 20
}

--- face 1..20
---    edge 1..3
---        neighbor_face, neighbor_edge
local icosa_face_neighbors = {
    {{ 2,  1}, {13,  3}, { 9,  2}}, ---  1
    {{ 1,  1}, { 3,  2}, {20,  3}}, ---  2
    {{ 4,  1}, { 2,  2}, {11,  3}}, ---  3
    {{ 3,  1}, { 6,  3}, {15,  2}}, ---  4
    {{ 7,  1}, {17,  3}, { 6,  2}}, ---  5
    {{12,  1}, { 5,  3}, { 4,  2}}, ---  6
    {{ 5,  1}, {17,  3}, { 6,  2}}, ---  7
    {{10,  1}, { 9,  3}, {19,  2}}, ---  8
    {{11,  1}, { 1,  3}, { 8,  2}}, ---  9
    {{ 8,  1}, { 7,  2}, {12,  3}}, --- 10
    {{ 9,  1}, {12,  2}, { 3,  3}}, --- 11
    {{ 6,  1}, { 5,  3}, { 4,  2}}, --- 12
    {{14,  1}, {19,  3}, { 1,  2}}, --- 13
    {{13,  1}, {20,  2}, {18,  3}}, --- 14
    {{20,  1}, { 4,  3}, {17,  2}}, --- 15
    {{19,  1}, {18,  2}, { 7,  3}}, --- 16
    {{18,  1}, {15,  3}, { 5,  2}}, --- 17
    {{17,  1}, {16,  2}, {14,  3}}, --- 18
    {{16,  1}, { 8,  3}, {13,  2}}, --- 19
    {{15,  1}, {14,  2}, { 2,  3}}  --- 20
}

local function neighbor_face_edge_at(face, edge)
    return icosa_face_neighbors[face][edge][1], icosa_face_neighbors[face][edge][2]
end

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

            local neighbor_face, neighbor_edge = neighbor_face_edge_at(fi, ei)
            edge.neighbor_face = neighbor_face
            edge.neighbor_edge = neighbor_edge

            for i = 1, edge_tile_count do
                edge.tiles[i] = 0
            end
        end

        for vi = 1, 5 do
            face.vertices[vi] = icosa_face_vertices[fi][vi]
        end
    end

    for vi = 1, 12 do
        icosa.vertices[vi] = 0
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
    if q == -size then return 2 end
    if r == size then return 3 end
    return 0
end

local function get_or_update_index_for_penta(q, r, face_index, icosa, index)
    local vi = icosa.faces[face_index].vertices[icosa_vertex_index(q, r, icosa.size)]

    if icosa.vertices[vi] > 0 then
        return icosa.vertices[vi]
    end

    icosa.vertices[vi] = index
    index = index + 1

    return icosa.vertices[vi]
end

local function get_or_update_index_for_edge(q, r, face_index, icosa, index)
    local ei = icosa_edge_index(q, r, icosa.size)
    local edge = icosa.faces[face_index].edges[ei]

    local ti = 0
    local nti = 0

    if ei == 1 then
        ti = r
        nti = icosa.size - ti
    elseif ei == 2 then
        ti = q
        if edge.neighbor_edge == 2 then
            nti = icosa.size - q
        elseif edge.neighbor_edge == 3 then
            nti = q
        else
            error("unexpected neighbor_edge: " .. edge.neighbor_edge)
        end
    elseif ei == 3 then
        ti = -r
        if edge.neighbor_edge == 2 then
            nti = -r
        elseif edge.neighbor_edge == 3 then
            nti = icosa.size + r
        else
            error("unexpected neighbor_edge: " .. edge.neighbor_edge)
        end
    end

    if edge.tiles[ti] > 0 then
        return edge.tiles[ti]
    end

    edge.tiles[ti] = index
    icosa.faces[edge.neighbor_face].edges[edge.neighbor_edge].tiles[nti] = index
    index = index + 1

    return edge.tiles[ti]
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
                    if world:is_penta(q, r) then
                        local penta_index = get_or_update_index_for_penta(q, r, fi, icosa_obj, index)
                        world:_set_index(q, r, fi, penta_index)
                    else
                        local edge_index = get_or_update_index_for_edge(q, r, fi, icosa_obj, index)
                        world:_set_index(q, r, fi, edge_index)
                    end
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
