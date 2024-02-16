local world = {
    size = nil,
    coord = nil
}

function world:new(size)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    obj.size = size
    obj.coord = {}

    return obj
end

function world:is_valid(q, r)
    local s = -(q + r)
    return q - s <= self.size and r - q <= self.size and s - r <= self.size
end

function world:is_edge(q, r)
    local s = -(q + r)
    return q - s == self.size or r - q == self.size or s - r == self.size
end

function world:is_penta(q, r)
    local s = -(q + r)
    return q - s == self.size and s - r == self.size or
           r - q == self.size and s - r == self.size or
           q - s == self.size and r - q == self.size
end

local bit = require("bit")

local function hash(a, b, c)
    return bit.bor(bit.lshift(a, 16), bit.lshift(b, 5), c)
end

function world:_set_index(q, r, face, index)
    self.coord[hash(q + self.size, r + self.size, face)] = index
end

function world:_set_empty(q, r, face)
    self:_set_index(q, r, face, -1)
end

function world:check()
    if not self:_check_collisions() then return false end
    if not self:_check_valid_indices() then return false end

    return true
end

function world:_check_collisions()
    local face_count = 3 + 0.5 * (3 * (self.size - 1)^2 + 3 * (self.size - 1) + 2) + 3 * (self.size - 1)
    face_count = face_count * 20
    local count = 0
    for _ in pairs(self.coord) do
        count = count + 1
    end
    if count ~= face_count then
        print("hash function is not good enough, got collisions; expected", face_count, "got", count)
        return false
    end

    return true
end

function world:_check_valid_indices()
    local max_index = 3 + 0.5 * (3 * (self.size - 1)^2 + 3 * (self.size - 1) + 2) + 3 * (self.size - 1)
    max_index = max_index * 20

    for fi = 1, 20 do
        for q = -self.size, self.size do
            for r = -self.size, self.size do
                if not self:is_valid(q, r) then goto continue end

                local index = self.coord[hash(q + self.size, r + self.size, fi)]
                if index < 0 or index >= max_index then
                    print("invalid index", self.coord[hash(q + self.size, r + self.size, fi)], "at", q, r, fi)
                    return false
                end

                ::continue::
            end
        end
    end

    return true
end

return world