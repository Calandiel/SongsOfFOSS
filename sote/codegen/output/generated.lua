local ffi = require("ffi")
ffi.cdef[[
    void* malloc(size_t size);
]]
local bitser = require("engine.bitser")

DATA = {}
---@class struct_trade_good_container
---@field good trade_good_id
---@field amount number
ffi.cdef[[
    typedef struct {
        uint32_t good;
        float amount;
    } trade_good_container;
]]
---@class struct_resource_location
---@field resource resource_id
---@field location tile_id
ffi.cdef[[
    typedef struct {
        uint32_t resource;
        uint32_t location;
    } resource_location;
]]
---@class struct_need_satisfaction
---@field need NEED
---@field use_case use_case_id
---@field consumed number
---@field demanded number
ffi.cdef[[
    typedef struct {
        uint8_t need;
        uint32_t use_case;
        float consumed;
        float demanded;
    } need_satisfaction;
]]
---@class struct_need_definition
---@field need NEED
---@field use_case use_case_id
---@field required number
ffi.cdef[[
    typedef struct {
        uint8_t need;
        uint32_t use_case;
        float required;
    } need_definition;
]]
----------tile----------


---tile: LSP types---

---Unique identificator for tile entity
---@alias tile_id number

---@class fat_tile_id
---@field id tile_id Unique tile id
---@field is_land boolean
---@field is_fresh boolean
---@field elevation number
---@field grass number
---@field shrub number
---@field conifer number
---@field broadleaf number
---@field ideal_grass number
---@field ideal_shrub number
---@field ideal_conifer number
---@field ideal_broadleaf number
---@field silt number
---@field clay number
---@field sand number
---@field soil_minerals number
---@field soil_organics number
---@field january_waterflow number
---@field july_waterflow number
---@field waterlevel number
---@field has_river boolean
---@field has_marsh boolean
---@field ice number
---@field ice_age_ice number
---@field debug_r number between 0 and 1, as per Love2Ds convention...
---@field debug_g number between 0 and 1, as per Love2Ds convention...
---@field debug_b number between 0 and 1, as per Love2Ds convention...
---@field real_r number between 0 and 1, as per Love2Ds convention...
---@field real_g number between 0 and 1, as per Love2Ds convention...
---@field real_b number between 0 and 1, as per Love2Ds convention...
---@field pathfinding_index number
---@field resource resource_id
---@field bedrock bedrock_id
---@field biome biome_id

---@class struct_tile
---@field is_land boolean
---@field is_fresh boolean
---@field elevation number
---@field grass number
---@field shrub number
---@field conifer number
---@field broadleaf number
---@field ideal_grass number
---@field ideal_shrub number
---@field ideal_conifer number
---@field ideal_broadleaf number
---@field silt number
---@field clay number
---@field sand number
---@field soil_minerals number
---@field soil_organics number
---@field january_waterflow number
---@field july_waterflow number
---@field waterlevel number
---@field has_river boolean
---@field has_marsh boolean
---@field ice number
---@field ice_age_ice number
---@field debug_r number between 0 and 1, as per Love2Ds convention...
---@field debug_g number between 0 and 1, as per Love2Ds convention...
---@field debug_b number between 0 and 1, as per Love2Ds convention...
---@field real_r number between 0 and 1, as per Love2Ds convention...
---@field real_g number between 0 and 1, as per Love2Ds convention...
---@field real_b number between 0 and 1, as per Love2Ds convention...
---@field pathfinding_index number


ffi.cdef[[
    typedef struct {
        bool is_land;
        bool is_fresh;
        float elevation;
        float grass;
        float shrub;
        float conifer;
        float broadleaf;
        float ideal_grass;
        float ideal_shrub;
        float ideal_conifer;
        float ideal_broadleaf;
        float silt;
        float clay;
        float sand;
        float soil_minerals;
        float soil_organics;
        float january_waterflow;
        float july_waterflow;
        float waterlevel;
        bool has_river;
        bool has_marsh;
        float ice;
        float ice_age_ice;
        float debug_r;
        float debug_g;
        float debug_b;
        float real_r;
        float real_g;
        float real_b;
        uint32_t pathfinding_index;
    } tile;
]]

---tile: FFI arrays---
---@type (resource_id)[]
DATA.tile_resource= {}
---@type (bedrock_id)[]
DATA.tile_bedrock= {}
---@type (biome_id)[]
DATA.tile_biome= {}
---@type nil
DATA.tile_malloc = ffi.C.malloc(ffi.sizeof("tile") * 1500001)
---@type table<tile_id, struct_tile>
DATA.tile = ffi.cast("tile*", DATA.tile_malloc)

---tile: LUA bindings---

DATA.tile_size = 1500000
---@type table<tile_id, boolean>
local tile_indices_pool = ffi.new("bool[?]", 1500000)
for i = 1, 1499999 do
    tile_indices_pool[i] = true
end
---@type table<tile_id, tile_id>
DATA.tile_indices_set = {}
function DATA.create_tile()
    for i = 1, 1499999 do
        if tile_indices_pool[i] then
            tile_indices_pool[i] = false
            DATA.tile_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for tile")
end
function DATA.delete_tile(i)
    do
        local to_delete = DATA.get_tile_province_membership_from_tile(i)
        DATA.delete_tile_province_membership(to_delete)
    end
    tile_indices_pool[i] = true
    DATA.tile_indices_set[i] = nil
end
---@param func fun(item: tile_id)
function DATA.for_each_tile(func)
    for _, item in pairs(DATA.tile_indices_set) do
        func(item)
    end
end

---@param tile_id tile_id valid tile id
---@return boolean is_land
function DATA.tile_get_is_land(tile_id)
    return DATA.tile[tile_id].is_land
end
---@param tile_id tile_id valid tile id
---@param value boolean valid boolean
function DATA.tile_set_is_land(tile_id, value)
    DATA.tile[tile_id].is_land = value
end
---@param tile_id tile_id valid tile id
---@return boolean is_fresh
function DATA.tile_get_is_fresh(tile_id)
    return DATA.tile[tile_id].is_fresh
end
---@param tile_id tile_id valid tile id
---@param value boolean valid boolean
function DATA.tile_set_is_fresh(tile_id, value)
    DATA.tile[tile_id].is_fresh = value
end
---@param tile_id tile_id valid tile id
---@return number elevation
function DATA.tile_get_elevation(tile_id)
    return DATA.tile[tile_id].elevation
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_elevation(tile_id, value)
    DATA.tile[tile_id].elevation = value
end
---@param tile_id tile_id valid tile id
---@return number grass
function DATA.tile_get_grass(tile_id)
    return DATA.tile[tile_id].grass
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_grass(tile_id, value)
    DATA.tile[tile_id].grass = value
end
---@param tile_id tile_id valid tile id
---@return number shrub
function DATA.tile_get_shrub(tile_id)
    return DATA.tile[tile_id].shrub
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_shrub(tile_id, value)
    DATA.tile[tile_id].shrub = value
end
---@param tile_id tile_id valid tile id
---@return number conifer
function DATA.tile_get_conifer(tile_id)
    return DATA.tile[tile_id].conifer
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_conifer(tile_id, value)
    DATA.tile[tile_id].conifer = value
end
---@param tile_id tile_id valid tile id
---@return number broadleaf
function DATA.tile_get_broadleaf(tile_id)
    return DATA.tile[tile_id].broadleaf
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_broadleaf(tile_id, value)
    DATA.tile[tile_id].broadleaf = value
end
---@param tile_id tile_id valid tile id
---@return number ideal_grass
function DATA.tile_get_ideal_grass(tile_id)
    return DATA.tile[tile_id].ideal_grass
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_ideal_grass(tile_id, value)
    DATA.tile[tile_id].ideal_grass = value
end
---@param tile_id tile_id valid tile id
---@return number ideal_shrub
function DATA.tile_get_ideal_shrub(tile_id)
    return DATA.tile[tile_id].ideal_shrub
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_ideal_shrub(tile_id, value)
    DATA.tile[tile_id].ideal_shrub = value
end
---@param tile_id tile_id valid tile id
---@return number ideal_conifer
function DATA.tile_get_ideal_conifer(tile_id)
    return DATA.tile[tile_id].ideal_conifer
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_ideal_conifer(tile_id, value)
    DATA.tile[tile_id].ideal_conifer = value
end
---@param tile_id tile_id valid tile id
---@return number ideal_broadleaf
function DATA.tile_get_ideal_broadleaf(tile_id)
    return DATA.tile[tile_id].ideal_broadleaf
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_ideal_broadleaf(tile_id, value)
    DATA.tile[tile_id].ideal_broadleaf = value
end
---@param tile_id tile_id valid tile id
---@return number silt
function DATA.tile_get_silt(tile_id)
    return DATA.tile[tile_id].silt
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_silt(tile_id, value)
    DATA.tile[tile_id].silt = value
end
---@param tile_id tile_id valid tile id
---@return number clay
function DATA.tile_get_clay(tile_id)
    return DATA.tile[tile_id].clay
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_clay(tile_id, value)
    DATA.tile[tile_id].clay = value
end
---@param tile_id tile_id valid tile id
---@return number sand
function DATA.tile_get_sand(tile_id)
    return DATA.tile[tile_id].sand
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_sand(tile_id, value)
    DATA.tile[tile_id].sand = value
end
---@param tile_id tile_id valid tile id
---@return number soil_minerals
function DATA.tile_get_soil_minerals(tile_id)
    return DATA.tile[tile_id].soil_minerals
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_soil_minerals(tile_id, value)
    DATA.tile[tile_id].soil_minerals = value
end
---@param tile_id tile_id valid tile id
---@return number soil_organics
function DATA.tile_get_soil_organics(tile_id)
    return DATA.tile[tile_id].soil_organics
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_soil_organics(tile_id, value)
    DATA.tile[tile_id].soil_organics = value
end
---@param tile_id tile_id valid tile id
---@return number january_waterflow
function DATA.tile_get_january_waterflow(tile_id)
    return DATA.tile[tile_id].january_waterflow
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_january_waterflow(tile_id, value)
    DATA.tile[tile_id].january_waterflow = value
end
---@param tile_id tile_id valid tile id
---@return number july_waterflow
function DATA.tile_get_july_waterflow(tile_id)
    return DATA.tile[tile_id].july_waterflow
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_july_waterflow(tile_id, value)
    DATA.tile[tile_id].july_waterflow = value
end
---@param tile_id tile_id valid tile id
---@return number waterlevel
function DATA.tile_get_waterlevel(tile_id)
    return DATA.tile[tile_id].waterlevel
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_waterlevel(tile_id, value)
    DATA.tile[tile_id].waterlevel = value
end
---@param tile_id tile_id valid tile id
---@return boolean has_river
function DATA.tile_get_has_river(tile_id)
    return DATA.tile[tile_id].has_river
end
---@param tile_id tile_id valid tile id
---@param value boolean valid boolean
function DATA.tile_set_has_river(tile_id, value)
    DATA.tile[tile_id].has_river = value
end
---@param tile_id tile_id valid tile id
---@return boolean has_marsh
function DATA.tile_get_has_marsh(tile_id)
    return DATA.tile[tile_id].has_marsh
end
---@param tile_id tile_id valid tile id
---@param value boolean valid boolean
function DATA.tile_set_has_marsh(tile_id, value)
    DATA.tile[tile_id].has_marsh = value
end
---@param tile_id tile_id valid tile id
---@return number ice
function DATA.tile_get_ice(tile_id)
    return DATA.tile[tile_id].ice
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_ice(tile_id, value)
    DATA.tile[tile_id].ice = value
end
---@param tile_id tile_id valid tile id
---@return number ice_age_ice
function DATA.tile_get_ice_age_ice(tile_id)
    return DATA.tile[tile_id].ice_age_ice
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_ice_age_ice(tile_id, value)
    DATA.tile[tile_id].ice_age_ice = value
end
---@param tile_id tile_id valid tile id
---@return number debug_r between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_debug_r(tile_id)
    return DATA.tile[tile_id].debug_r
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_debug_r(tile_id, value)
    DATA.tile[tile_id].debug_r = value
end
---@param tile_id tile_id valid tile id
---@return number debug_g between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_debug_g(tile_id)
    return DATA.tile[tile_id].debug_g
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_debug_g(tile_id, value)
    DATA.tile[tile_id].debug_g = value
end
---@param tile_id tile_id valid tile id
---@return number debug_b between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_debug_b(tile_id)
    return DATA.tile[tile_id].debug_b
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_debug_b(tile_id, value)
    DATA.tile[tile_id].debug_b = value
end
---@param tile_id tile_id valid tile id
---@return number real_r between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_real_r(tile_id)
    return DATA.tile[tile_id].real_r
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_real_r(tile_id, value)
    DATA.tile[tile_id].real_r = value
end
---@param tile_id tile_id valid tile id
---@return number real_g between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_real_g(tile_id)
    return DATA.tile[tile_id].real_g
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_real_g(tile_id, value)
    DATA.tile[tile_id].real_g = value
end
---@param tile_id tile_id valid tile id
---@return number real_b between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_real_b(tile_id)
    return DATA.tile[tile_id].real_b
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_real_b(tile_id, value)
    DATA.tile[tile_id].real_b = value
end
---@param tile_id tile_id valid tile id
---@return number pathfinding_index
function DATA.tile_get_pathfinding_index(tile_id)
    return DATA.tile[tile_id].pathfinding_index
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_pathfinding_index(tile_id, value)
    DATA.tile[tile_id].pathfinding_index = value
end
---@param tile_id tile_id valid tile id
---@return resource_id resource
function DATA.tile_get_resource(tile_id)
    return DATA.tile_resource[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value resource_id valid resource_id
function DATA.tile_set_resource(tile_id, value)
    DATA.tile_resource[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return bedrock_id bedrock
function DATA.tile_get_bedrock(tile_id)
    return DATA.tile_bedrock[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value bedrock_id valid bedrock_id
function DATA.tile_set_bedrock(tile_id, value)
    DATA.tile_bedrock[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return biome_id biome
function DATA.tile_get_biome(tile_id)
    return DATA.tile_biome[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value biome_id valid biome_id
function DATA.tile_set_biome(tile_id, value)
    DATA.tile_biome[tile_id] = value
end


local fat_tile_id_metatable = {
    __index = function (t,k)
        if (k == "is_land") then return DATA.tile_get_is_land(t.id) end
        if (k == "is_fresh") then return DATA.tile_get_is_fresh(t.id) end
        if (k == "elevation") then return DATA.tile_get_elevation(t.id) end
        if (k == "grass") then return DATA.tile_get_grass(t.id) end
        if (k == "shrub") then return DATA.tile_get_shrub(t.id) end
        if (k == "conifer") then return DATA.tile_get_conifer(t.id) end
        if (k == "broadleaf") then return DATA.tile_get_broadleaf(t.id) end
        if (k == "ideal_grass") then return DATA.tile_get_ideal_grass(t.id) end
        if (k == "ideal_shrub") then return DATA.tile_get_ideal_shrub(t.id) end
        if (k == "ideal_conifer") then return DATA.tile_get_ideal_conifer(t.id) end
        if (k == "ideal_broadleaf") then return DATA.tile_get_ideal_broadleaf(t.id) end
        if (k == "silt") then return DATA.tile_get_silt(t.id) end
        if (k == "clay") then return DATA.tile_get_clay(t.id) end
        if (k == "sand") then return DATA.tile_get_sand(t.id) end
        if (k == "soil_minerals") then return DATA.tile_get_soil_minerals(t.id) end
        if (k == "soil_organics") then return DATA.tile_get_soil_organics(t.id) end
        if (k == "january_waterflow") then return DATA.tile_get_january_waterflow(t.id) end
        if (k == "july_waterflow") then return DATA.tile_get_july_waterflow(t.id) end
        if (k == "waterlevel") then return DATA.tile_get_waterlevel(t.id) end
        if (k == "has_river") then return DATA.tile_get_has_river(t.id) end
        if (k == "has_marsh") then return DATA.tile_get_has_marsh(t.id) end
        if (k == "ice") then return DATA.tile_get_ice(t.id) end
        if (k == "ice_age_ice") then return DATA.tile_get_ice_age_ice(t.id) end
        if (k == "debug_r") then return DATA.tile_get_debug_r(t.id) end
        if (k == "debug_g") then return DATA.tile_get_debug_g(t.id) end
        if (k == "debug_b") then return DATA.tile_get_debug_b(t.id) end
        if (k == "real_r") then return DATA.tile_get_real_r(t.id) end
        if (k == "real_g") then return DATA.tile_get_real_g(t.id) end
        if (k == "real_b") then return DATA.tile_get_real_b(t.id) end
        if (k == "pathfinding_index") then return DATA.tile_get_pathfinding_index(t.id) end
        if (k == "resource") then return DATA.tile_get_resource(t.id) end
        if (k == "bedrock") then return DATA.tile_get_bedrock(t.id) end
        if (k == "biome") then return DATA.tile_get_biome(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "is_land") then
            DATA.tile_set_is_land(t.id, v)
            return
        end
        if (k == "is_fresh") then
            DATA.tile_set_is_fresh(t.id, v)
            return
        end
        if (k == "elevation") then
            DATA.tile_set_elevation(t.id, v)
            return
        end
        if (k == "grass") then
            DATA.tile_set_grass(t.id, v)
            return
        end
        if (k == "shrub") then
            DATA.tile_set_shrub(t.id, v)
            return
        end
        if (k == "conifer") then
            DATA.tile_set_conifer(t.id, v)
            return
        end
        if (k == "broadleaf") then
            DATA.tile_set_broadleaf(t.id, v)
            return
        end
        if (k == "ideal_grass") then
            DATA.tile_set_ideal_grass(t.id, v)
            return
        end
        if (k == "ideal_shrub") then
            DATA.tile_set_ideal_shrub(t.id, v)
            return
        end
        if (k == "ideal_conifer") then
            DATA.tile_set_ideal_conifer(t.id, v)
            return
        end
        if (k == "ideal_broadleaf") then
            DATA.tile_set_ideal_broadleaf(t.id, v)
            return
        end
        if (k == "silt") then
            DATA.tile_set_silt(t.id, v)
            return
        end
        if (k == "clay") then
            DATA.tile_set_clay(t.id, v)
            return
        end
        if (k == "sand") then
            DATA.tile_set_sand(t.id, v)
            return
        end
        if (k == "soil_minerals") then
            DATA.tile_set_soil_minerals(t.id, v)
            return
        end
        if (k == "soil_organics") then
            DATA.tile_set_soil_organics(t.id, v)
            return
        end
        if (k == "january_waterflow") then
            DATA.tile_set_january_waterflow(t.id, v)
            return
        end
        if (k == "july_waterflow") then
            DATA.tile_set_july_waterflow(t.id, v)
            return
        end
        if (k == "waterlevel") then
            DATA.tile_set_waterlevel(t.id, v)
            return
        end
        if (k == "has_river") then
            DATA.tile_set_has_river(t.id, v)
            return
        end
        if (k == "has_marsh") then
            DATA.tile_set_has_marsh(t.id, v)
            return
        end
        if (k == "ice") then
            DATA.tile_set_ice(t.id, v)
            return
        end
        if (k == "ice_age_ice") then
            DATA.tile_set_ice_age_ice(t.id, v)
            return
        end
        if (k == "debug_r") then
            DATA.tile_set_debug_r(t.id, v)
            return
        end
        if (k == "debug_g") then
            DATA.tile_set_debug_g(t.id, v)
            return
        end
        if (k == "debug_b") then
            DATA.tile_set_debug_b(t.id, v)
            return
        end
        if (k == "real_r") then
            DATA.tile_set_real_r(t.id, v)
            return
        end
        if (k == "real_g") then
            DATA.tile_set_real_g(t.id, v)
            return
        end
        if (k == "real_b") then
            DATA.tile_set_real_b(t.id, v)
            return
        end
        if (k == "pathfinding_index") then
            DATA.tile_set_pathfinding_index(t.id, v)
            return
        end
        if (k == "resource") then
            DATA.tile_set_resource(t.id, v)
            return
        end
        if (k == "bedrock") then
            DATA.tile_set_bedrock(t.id, v)
            return
        end
        if (k == "biome") then
            DATA.tile_set_biome(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id tile_id
---@return fat_tile_id fat_id
function DATA.fatten_tile(id)
    local result = {id = id}
    setmetatable(result, fat_tile_id_metatable)    return result
end
----------race----------


---race: LSP types---

---Unique identificator for race entity
---@alias race_id number

---@class fat_race_id
---@field id race_id Unique race id
---@field name string
---@field icon string
---@field female_portrait nil|PortraitSet
---@field male_portrait nil|PortraitSet
---@field description string
---@field r number
---@field g number
---@field b number
---@field carrying_capacity_weight number
---@field fecundity number
---@field spotting number How good is this unit at scouting
---@field visibility number How visible is this unit in battles
---@field males_per_hundred_females number
---@field child_age number
---@field teen_age number
---@field adult_age number
---@field middle_age number
---@field elder_age number
---@field max_age number
---@field minimum_comfortable_temperature number
---@field minimum_absolute_temperature number
---@field minimum_comfortable_elevation number
---@field female_body_size number
---@field male_body_size number
---@field female_infrastructure_needs number
---@field male_infrastructure_needs number
---@field requires_large_river boolean
---@field requires_large_forest boolean

---@class struct_race
---@field r number
---@field g number
---@field b number
---@field carrying_capacity_weight number
---@field fecundity number
---@field spotting number How good is this unit at scouting
---@field visibility number How visible is this unit in battles
---@field males_per_hundred_females number
---@field child_age number
---@field teen_age number
---@field adult_age number
---@field middle_age number
---@field elder_age number
---@field max_age number
---@field minimum_comfortable_temperature number
---@field minimum_absolute_temperature number
---@field minimum_comfortable_elevation number
---@field female_body_size number
---@field male_body_size number
---@field female_efficiency table<JOBTYPE, number>
---@field male_efficiency table<JOBTYPE, number>
---@field female_infrastructure_needs number
---@field male_infrastructure_needs number
---@field female_needs table<number, struct_need_definition>
---@field male_needs table<number, struct_need_definition>
---@field requires_large_river boolean
---@field requires_large_forest boolean


ffi.cdef[[
    typedef struct {
        float r;
        float g;
        float b;
        float carrying_capacity_weight;
        float fecundity;
        float spotting;
        float visibility;
        float males_per_hundred_females;
        float child_age;
        float teen_age;
        float adult_age;
        float middle_age;
        float elder_age;
        float max_age;
        float minimum_comfortable_temperature;
        float minimum_absolute_temperature;
        float minimum_comfortable_elevation;
        float female_body_size;
        float male_body_size;
        float female_efficiency[10];
        float male_efficiency[10];
        float female_infrastructure_needs;
        float male_infrastructure_needs;
        need_definition female_needs[20];
        need_definition male_needs[20];
        bool requires_large_river;
        bool requires_large_forest;
    } race;
]]

---race: FFI arrays---
---@type (string)[]
DATA.race_name= {}
---@type (string)[]
DATA.race_icon= {}
---@type (nil|PortraitSet)[]
DATA.race_female_portrait= {}
---@type (nil|PortraitSet)[]
DATA.race_male_portrait= {}
---@type (string)[]
DATA.race_description= {}
---@type nil
DATA.race_malloc = ffi.C.malloc(ffi.sizeof("race") * 16)
---@type table<race_id, struct_race>
DATA.race = ffi.cast("race*", DATA.race_malloc)

---race: LUA bindings---

DATA.race_size = 15
---@type table<race_id, boolean>
local race_indices_pool = ffi.new("bool[?]", 15)
for i = 1, 14 do
    race_indices_pool[i] = true
end
---@type table<race_id, race_id>
DATA.race_indices_set = {}
function DATA.create_race()
    for i = 1, 14 do
        if race_indices_pool[i] then
            race_indices_pool[i] = false
            DATA.race_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for race")
end
function DATA.delete_race(i)
    race_indices_pool[i] = true
    DATA.race_indices_set[i] = nil
end
---@param func fun(item: race_id)
function DATA.for_each_race(func)
    for _, item in pairs(DATA.race_indices_set) do
        func(item)
    end
end

---@param race_id race_id valid race id
---@return string name
function DATA.race_get_name(race_id)
    return DATA.race_name[race_id]
end
---@param race_id race_id valid race id
---@param value string valid string
function DATA.race_set_name(race_id, value)
    DATA.race_name[race_id] = value
end
---@param race_id race_id valid race id
---@return string icon
function DATA.race_get_icon(race_id)
    return DATA.race_icon[race_id]
end
---@param race_id race_id valid race id
---@param value string valid string
function DATA.race_set_icon(race_id, value)
    DATA.race_icon[race_id] = value
end
---@param race_id race_id valid race id
---@return nil|PortraitSet female_portrait
function DATA.race_get_female_portrait(race_id)
    return DATA.race_female_portrait[race_id]
end
---@param race_id race_id valid race id
---@param value nil|PortraitSet valid nil|PortraitSet
function DATA.race_set_female_portrait(race_id, value)
    DATA.race_female_portrait[race_id] = value
end
---@param race_id race_id valid race id
---@return nil|PortraitSet male_portrait
function DATA.race_get_male_portrait(race_id)
    return DATA.race_male_portrait[race_id]
end
---@param race_id race_id valid race id
---@param value nil|PortraitSet valid nil|PortraitSet
function DATA.race_set_male_portrait(race_id, value)
    DATA.race_male_portrait[race_id] = value
end
---@param race_id race_id valid race id
---@return string description
function DATA.race_get_description(race_id)
    return DATA.race_description[race_id]
end
---@param race_id race_id valid race id
---@param value string valid string
function DATA.race_set_description(race_id, value)
    DATA.race_description[race_id] = value
end
---@param race_id race_id valid race id
---@return number r
function DATA.race_get_r(race_id)
    return DATA.race[race_id].r
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_r(race_id, value)
    DATA.race[race_id].r = value
end
---@param race_id race_id valid race id
---@return number g
function DATA.race_get_g(race_id)
    return DATA.race[race_id].g
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_g(race_id, value)
    DATA.race[race_id].g = value
end
---@param race_id race_id valid race id
---@return number b
function DATA.race_get_b(race_id)
    return DATA.race[race_id].b
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_b(race_id, value)
    DATA.race[race_id].b = value
end
---@param race_id race_id valid race id
---@return number carrying_capacity_weight
function DATA.race_get_carrying_capacity_weight(race_id)
    return DATA.race[race_id].carrying_capacity_weight
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_carrying_capacity_weight(race_id, value)
    DATA.race[race_id].carrying_capacity_weight = value
end
---@param race_id race_id valid race id
---@return number fecundity
function DATA.race_get_fecundity(race_id)
    return DATA.race[race_id].fecundity
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_fecundity(race_id, value)
    DATA.race[race_id].fecundity = value
end
---@param race_id race_id valid race id
---@return number spotting How good is this unit at scouting
function DATA.race_get_spotting(race_id)
    return DATA.race[race_id].spotting
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_spotting(race_id, value)
    DATA.race[race_id].spotting = value
end
---@param race_id race_id valid race id
---@return number visibility How visible is this unit in battles
function DATA.race_get_visibility(race_id)
    return DATA.race[race_id].visibility
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_visibility(race_id, value)
    DATA.race[race_id].visibility = value
end
---@param race_id race_id valid race id
---@return number males_per_hundred_females
function DATA.race_get_males_per_hundred_females(race_id)
    return DATA.race[race_id].males_per_hundred_females
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_males_per_hundred_females(race_id, value)
    DATA.race[race_id].males_per_hundred_females = value
end
---@param race_id race_id valid race id
---@return number child_age
function DATA.race_get_child_age(race_id)
    return DATA.race[race_id].child_age
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_child_age(race_id, value)
    DATA.race[race_id].child_age = value
end
---@param race_id race_id valid race id
---@return number teen_age
function DATA.race_get_teen_age(race_id)
    return DATA.race[race_id].teen_age
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_teen_age(race_id, value)
    DATA.race[race_id].teen_age = value
end
---@param race_id race_id valid race id
---@return number adult_age
function DATA.race_get_adult_age(race_id)
    return DATA.race[race_id].adult_age
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_adult_age(race_id, value)
    DATA.race[race_id].adult_age = value
end
---@param race_id race_id valid race id
---@return number middle_age
function DATA.race_get_middle_age(race_id)
    return DATA.race[race_id].middle_age
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_middle_age(race_id, value)
    DATA.race[race_id].middle_age = value
end
---@param race_id race_id valid race id
---@return number elder_age
function DATA.race_get_elder_age(race_id)
    return DATA.race[race_id].elder_age
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_elder_age(race_id, value)
    DATA.race[race_id].elder_age = value
end
---@param race_id race_id valid race id
---@return number max_age
function DATA.race_get_max_age(race_id)
    return DATA.race[race_id].max_age
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_max_age(race_id, value)
    DATA.race[race_id].max_age = value
end
---@param race_id race_id valid race id
---@return number minimum_comfortable_temperature
function DATA.race_get_minimum_comfortable_temperature(race_id)
    return DATA.race[race_id].minimum_comfortable_temperature
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_minimum_comfortable_temperature(race_id, value)
    DATA.race[race_id].minimum_comfortable_temperature = value
end
---@param race_id race_id valid race id
---@return number minimum_absolute_temperature
function DATA.race_get_minimum_absolute_temperature(race_id)
    return DATA.race[race_id].minimum_absolute_temperature
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_minimum_absolute_temperature(race_id, value)
    DATA.race[race_id].minimum_absolute_temperature = value
end
---@param race_id race_id valid race id
---@return number minimum_comfortable_elevation
function DATA.race_get_minimum_comfortable_elevation(race_id)
    return DATA.race[race_id].minimum_comfortable_elevation
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_minimum_comfortable_elevation(race_id, value)
    DATA.race[race_id].minimum_comfortable_elevation = value
end
---@param race_id race_id valid race id
---@return number female_body_size
function DATA.race_get_female_body_size(race_id)
    return DATA.race[race_id].female_body_size
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_female_body_size(race_id, value)
    DATA.race[race_id].female_body_size = value
end
---@param race_id race_id valid race id
---@return number male_body_size
function DATA.race_get_male_body_size(race_id)
    return DATA.race[race_id].male_body_size
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_male_body_size(race_id, value)
    DATA.race[race_id].male_body_size = value
end
---@param race_id race_id valid race id
---@param index JOBTYPE valid
---@return number female_efficiency
function DATA.race_get_female_efficiency(race_id, index)
    return DATA.race[race_id].female_efficiency[index]
end
---@param race_id race_id valid race id
---@param index JOBTYPE valid index
---@param value number valid number
function DATA.race_set_female_efficiency(race_id, index, value)
    DATA.race[race_id].female_efficiency[index] = value
end
---@param race_id race_id valid race id
---@param index JOBTYPE valid
---@return number male_efficiency
function DATA.race_get_male_efficiency(race_id, index)
    return DATA.race[race_id].male_efficiency[index]
end
---@param race_id race_id valid race id
---@param index JOBTYPE valid index
---@param value number valid number
function DATA.race_set_male_efficiency(race_id, index, value)
    DATA.race[race_id].male_efficiency[index] = value
end
---@param race_id race_id valid race id
---@return number female_infrastructure_needs
function DATA.race_get_female_infrastructure_needs(race_id)
    return DATA.race[race_id].female_infrastructure_needs
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_female_infrastructure_needs(race_id, value)
    DATA.race[race_id].female_infrastructure_needs = value
end
---@param race_id race_id valid race id
---@return number male_infrastructure_needs
function DATA.race_get_male_infrastructure_needs(race_id)
    return DATA.race[race_id].male_infrastructure_needs
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_male_infrastructure_needs(race_id, value)
    DATA.race[race_id].male_infrastructure_needs = value
end
---@param race_id race_id valid race id
---@param index number valid
---@return NEED female_needs
function DATA.race_get_female_needs_need(race_id, index)
    return DATA.race[race_id].female_needs[index].need
end
---@param race_id race_id valid race id
---@param index number valid
---@return use_case_id female_needs
function DATA.race_get_female_needs_use_case(race_id, index)
    return DATA.race[race_id].female_needs[index].use_case
end
---@param race_id race_id valid race id
---@param index number valid
---@return number female_needs
function DATA.race_get_female_needs_required(race_id, index)
    return DATA.race[race_id].female_needs[index].required
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value NEED valid NEED
function DATA.race_set_female_needs_need(race_id, index, value)
    DATA.race[race_id].female_needs[index].need = value
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value use_case_id valid use_case_id
function DATA.race_set_female_needs_use_case(race_id, index, value)
    DATA.race[race_id].female_needs[index].use_case = value
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value number valid number
function DATA.race_set_female_needs_required(race_id, index, value)
    DATA.race[race_id].female_needs[index].required = value
end
---@param race_id race_id valid race id
---@param index number valid
---@return NEED male_needs
function DATA.race_get_male_needs_need(race_id, index)
    return DATA.race[race_id].male_needs[index].need
end
---@param race_id race_id valid race id
---@param index number valid
---@return use_case_id male_needs
function DATA.race_get_male_needs_use_case(race_id, index)
    return DATA.race[race_id].male_needs[index].use_case
end
---@param race_id race_id valid race id
---@param index number valid
---@return number male_needs
function DATA.race_get_male_needs_required(race_id, index)
    return DATA.race[race_id].male_needs[index].required
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value NEED valid NEED
function DATA.race_set_male_needs_need(race_id, index, value)
    DATA.race[race_id].male_needs[index].need = value
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value use_case_id valid use_case_id
function DATA.race_set_male_needs_use_case(race_id, index, value)
    DATA.race[race_id].male_needs[index].use_case = value
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value number valid number
function DATA.race_set_male_needs_required(race_id, index, value)
    DATA.race[race_id].male_needs[index].required = value
end
---@param race_id race_id valid race id
---@return boolean requires_large_river
function DATA.race_get_requires_large_river(race_id)
    return DATA.race[race_id].requires_large_river
end
---@param race_id race_id valid race id
---@param value boolean valid boolean
function DATA.race_set_requires_large_river(race_id, value)
    DATA.race[race_id].requires_large_river = value
end
---@param race_id race_id valid race id
---@return boolean requires_large_forest
function DATA.race_get_requires_large_forest(race_id)
    return DATA.race[race_id].requires_large_forest
end
---@param race_id race_id valid race id
---@param value boolean valid boolean
function DATA.race_set_requires_large_forest(race_id, value)
    DATA.race[race_id].requires_large_forest = value
end


local fat_race_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.race_get_name(t.id) end
        if (k == "icon") then return DATA.race_get_icon(t.id) end
        if (k == "female_portrait") then return DATA.race_get_female_portrait(t.id) end
        if (k == "male_portrait") then return DATA.race_get_male_portrait(t.id) end
        if (k == "description") then return DATA.race_get_description(t.id) end
        if (k == "r") then return DATA.race_get_r(t.id) end
        if (k == "g") then return DATA.race_get_g(t.id) end
        if (k == "b") then return DATA.race_get_b(t.id) end
        if (k == "carrying_capacity_weight") then return DATA.race_get_carrying_capacity_weight(t.id) end
        if (k == "fecundity") then return DATA.race_get_fecundity(t.id) end
        if (k == "spotting") then return DATA.race_get_spotting(t.id) end
        if (k == "visibility") then return DATA.race_get_visibility(t.id) end
        if (k == "males_per_hundred_females") then return DATA.race_get_males_per_hundred_females(t.id) end
        if (k == "child_age") then return DATA.race_get_child_age(t.id) end
        if (k == "teen_age") then return DATA.race_get_teen_age(t.id) end
        if (k == "adult_age") then return DATA.race_get_adult_age(t.id) end
        if (k == "middle_age") then return DATA.race_get_middle_age(t.id) end
        if (k == "elder_age") then return DATA.race_get_elder_age(t.id) end
        if (k == "max_age") then return DATA.race_get_max_age(t.id) end
        if (k == "minimum_comfortable_temperature") then return DATA.race_get_minimum_comfortable_temperature(t.id) end
        if (k == "minimum_absolute_temperature") then return DATA.race_get_minimum_absolute_temperature(t.id) end
        if (k == "minimum_comfortable_elevation") then return DATA.race_get_minimum_comfortable_elevation(t.id) end
        if (k == "female_body_size") then return DATA.race_get_female_body_size(t.id) end
        if (k == "male_body_size") then return DATA.race_get_male_body_size(t.id) end
        if (k == "female_infrastructure_needs") then return DATA.race_get_female_infrastructure_needs(t.id) end
        if (k == "male_infrastructure_needs") then return DATA.race_get_male_infrastructure_needs(t.id) end
        if (k == "requires_large_river") then return DATA.race_get_requires_large_river(t.id) end
        if (k == "requires_large_forest") then return DATA.race_get_requires_large_forest(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.race_set_name(t.id, v)
            return
        end
        if (k == "icon") then
            DATA.race_set_icon(t.id, v)
            return
        end
        if (k == "female_portrait") then
            DATA.race_set_female_portrait(t.id, v)
            return
        end
        if (k == "male_portrait") then
            DATA.race_set_male_portrait(t.id, v)
            return
        end
        if (k == "description") then
            DATA.race_set_description(t.id, v)
            return
        end
        if (k == "r") then
            DATA.race_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.race_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.race_set_b(t.id, v)
            return
        end
        if (k == "carrying_capacity_weight") then
            DATA.race_set_carrying_capacity_weight(t.id, v)
            return
        end
        if (k == "fecundity") then
            DATA.race_set_fecundity(t.id, v)
            return
        end
        if (k == "spotting") then
            DATA.race_set_spotting(t.id, v)
            return
        end
        if (k == "visibility") then
            DATA.race_set_visibility(t.id, v)
            return
        end
        if (k == "males_per_hundred_females") then
            DATA.race_set_males_per_hundred_females(t.id, v)
            return
        end
        if (k == "child_age") then
            DATA.race_set_child_age(t.id, v)
            return
        end
        if (k == "teen_age") then
            DATA.race_set_teen_age(t.id, v)
            return
        end
        if (k == "adult_age") then
            DATA.race_set_adult_age(t.id, v)
            return
        end
        if (k == "middle_age") then
            DATA.race_set_middle_age(t.id, v)
            return
        end
        if (k == "elder_age") then
            DATA.race_set_elder_age(t.id, v)
            return
        end
        if (k == "max_age") then
            DATA.race_set_max_age(t.id, v)
            return
        end
        if (k == "minimum_comfortable_temperature") then
            DATA.race_set_minimum_comfortable_temperature(t.id, v)
            return
        end
        if (k == "minimum_absolute_temperature") then
            DATA.race_set_minimum_absolute_temperature(t.id, v)
            return
        end
        if (k == "minimum_comfortable_elevation") then
            DATA.race_set_minimum_comfortable_elevation(t.id, v)
            return
        end
        if (k == "female_body_size") then
            DATA.race_set_female_body_size(t.id, v)
            return
        end
        if (k == "male_body_size") then
            DATA.race_set_male_body_size(t.id, v)
            return
        end
        if (k == "female_infrastructure_needs") then
            DATA.race_set_female_infrastructure_needs(t.id, v)
            return
        end
        if (k == "male_infrastructure_needs") then
            DATA.race_set_male_infrastructure_needs(t.id, v)
            return
        end
        if (k == "requires_large_river") then
            DATA.race_set_requires_large_river(t.id, v)
            return
        end
        if (k == "requires_large_forest") then
            DATA.race_set_requires_large_forest(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id race_id
---@return fat_race_id fat_id
function DATA.fatten_race(id)
    local result = {id = id}
    setmetatable(result, fat_race_id_metatable)    return result
end
----------pop----------


---pop: LSP types---

---Unique identificator for pop entity
---@alias pop_id number

---@class fat_pop_id
---@field id pop_id Unique pop id
---@field race race_id
---@field faith Faith
---@field culture Culture
---@field female boolean
---@field age number
---@field name string
---@field job Job
---@field savings number
---@field parent pop_id
---@field loyalty pop_id
---@field life_needs_satisfaction number from 0 to 1
---@field basic_needs_satisfaction number from 0 to 1
---@field employer Building
---@field successor pop_id
---@field owned_buildings table <Building,Building>
---@field has_trade_permits_in table<Realm,Realm>
---@field has_building_permits_in table<Realm,Realm>
---@field forage_ratio number a number in (0, 1) interval representing a ratio of time pop spends to forage
---@field work_ratio number a number in (0, 1) interval representing a ratio of time workers spend on a job compared to maximal
---@field busy boolean
---@field dead boolean
---@field realm Realm Represents the home realm of the character
---@field leader_of table<Realm,Realm>
---@field current_negotiations table<pop_id,pop_id>
---@field rank CHARACTER_RANK
---@field former_pop boolean

---@class struct_pop
---@field race race_id
---@field female boolean
---@field age number
---@field savings number
---@field parent pop_id
---@field loyalty pop_id
---@field life_needs_satisfaction number from 0 to 1
---@field basic_needs_satisfaction number from 0 to 1
---@field need_satisfaction table<number, struct_need_satisfaction>
---@field traits table<number, TRAIT>
---@field successor pop_id
---@field inventory table<trade_good_id, number>
---@field price_memory table<trade_good_id, number>
---@field forage_ratio number a number in (0, 1) interval representing a ratio of time pop spends to forage
---@field work_ratio number a number in (0, 1) interval representing a ratio of time workers spend on a job compared to maximal
---@field rank CHARACTER_RANK
---@field dna table<number, number>


ffi.cdef[[
    typedef struct {
        uint32_t race;
        bool female;
        uint32_t age;
        float savings;
        uint32_t parent;
        uint32_t loyalty;
        float life_needs_satisfaction;
        float basic_needs_satisfaction;
        need_satisfaction need_satisfaction[20];
        uint8_t traits[10];
        uint32_t successor;
        float inventory[100];
        float price_memory[100];
        float forage_ratio;
        float work_ratio;
        uint8_t rank;
        float dna[20];
    } pop;
]]

---pop: FFI arrays---
---@type (Faith)[]
DATA.pop_faith= {}
---@type (Culture)[]
DATA.pop_culture= {}
---@type (string)[]
DATA.pop_name= {}
---@type (Job)[]
DATA.pop_job= {}
---@type (Building)[]
DATA.pop_employer= {}
---@type (table)[]
DATA.pop_owned_buildings= {}
---@type (table<Realm,Realm>)[]
DATA.pop_has_trade_permits_in= {}
---@type (table<Realm,Realm>)[]
DATA.pop_has_building_permits_in= {}
---@type (boolean)[]
DATA.pop_busy= {}
---@type (boolean)[]
DATA.pop_dead= {}
---@type (Realm)[]
DATA.pop_realm= {}
---@type (table<Realm,Realm>)[]
DATA.pop_leader_of= {}
---@type (table<pop_id,pop_id>)[]
DATA.pop_current_negotiations= {}
---@type (boolean)[]
DATA.pop_former_pop= {}
---@type nil
DATA.pop_malloc = ffi.C.malloc(ffi.sizeof("pop") * 300001)
---@type table<pop_id, struct_pop>
DATA.pop = ffi.cast("pop*", DATA.pop_malloc)

---pop: LUA bindings---

DATA.pop_size = 300000
---@type table<pop_id, boolean>
local pop_indices_pool = ffi.new("bool[?]", 300000)
for i = 1, 299999 do
    pop_indices_pool[i] = true
end
---@type table<pop_id, pop_id>
DATA.pop_indices_set = {}
function DATA.create_pop()
    for i = 1, 299999 do
        if pop_indices_pool[i] then
            pop_indices_pool[i] = false
            DATA.pop_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for pop")
end
function DATA.delete_pop(i)
    do
        local to_delete = DATA.get_warband_leader_from_leader(i)
        DATA.delete_warband_leader(to_delete)
    end
    do
        local to_delete = DATA.get_warband_recruiter_from_recruiter(i)
        DATA.delete_warband_recruiter(to_delete)
    end
    do
        local to_delete = DATA.get_warband_commander_from_commander(i)
        DATA.delete_warband_commander(to_delete)
    end
    do
        local to_delete = DATA.get_warband_unit_from_unit(i)
        DATA.delete_warband_unit(to_delete)
    end
    do
        local to_delete = DATA.get_character_location_from_character(i)
        DATA.delete_character_location(to_delete)
    end
    do
        local to_delete = DATA.get_home_from_pop(i)
        DATA.delete_home(to_delete)
    end
    do
        local to_delete = DATA.get_pop_location_from_pop(i)
        DATA.delete_pop_location(to_delete)
    end
    do
        local to_delete = DATA.get_outlaw_location_from_outlaw(i)
        DATA.delete_outlaw_location(to_delete)
    end
    do
        ---@type parent_child_relation_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_parent_child_relation_from_parent(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_parent_child_relation(value)
        end
    end
    do
        local to_delete = DATA.get_parent_child_relation_from_child(i)
        DATA.delete_parent_child_relation(to_delete)
    end
    do
        ---@type loyalty_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_loyalty_from_top(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_loyalty(value)
        end
    end
    do
        local to_delete = DATA.get_loyalty_from_bottom(i)
        DATA.delete_loyalty(to_delete)
    end
    do
        local to_delete = DATA.get_succession_from_successor_of(i)
        DATA.delete_succession(to_delete)
    end
    do
        ---@type succession_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_succession_from_successor(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_succession(value)
        end
    end
    pop_indices_pool[i] = true
    DATA.pop_indices_set[i] = nil
end
---@param func fun(item: pop_id)
function DATA.for_each_pop(func)
    for _, item in pairs(DATA.pop_indices_set) do
        func(item)
    end
end

---@param pop_id pop_id valid pop id
---@return race_id race
function DATA.pop_get_race(pop_id)
    return DATA.pop[pop_id].race
end
---@param pop_id pop_id valid pop id
---@param value race_id valid race_id
function DATA.pop_set_race(pop_id, value)
    DATA.pop[pop_id].race = value
end
---@param pop_id pop_id valid pop id
---@return Faith faith
function DATA.pop_get_faith(pop_id)
    return DATA.pop_faith[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value Faith valid Faith
function DATA.pop_set_faith(pop_id, value)
    DATA.pop_faith[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@return Culture culture
function DATA.pop_get_culture(pop_id)
    return DATA.pop_culture[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value Culture valid Culture
function DATA.pop_set_culture(pop_id, value)
    DATA.pop_culture[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@return boolean female
function DATA.pop_get_female(pop_id)
    return DATA.pop[pop_id].female
end
---@param pop_id pop_id valid pop id
---@param value boolean valid boolean
function DATA.pop_set_female(pop_id, value)
    DATA.pop[pop_id].female = value
end
---@param pop_id pop_id valid pop id
---@return number age
function DATA.pop_get_age(pop_id)
    return DATA.pop[pop_id].age
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_age(pop_id, value)
    DATA.pop[pop_id].age = value
end
---@param pop_id pop_id valid pop id
---@return string name
function DATA.pop_get_name(pop_id)
    return DATA.pop_name[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value string valid string
function DATA.pop_set_name(pop_id, value)
    DATA.pop_name[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@return Job job
function DATA.pop_get_job(pop_id)
    return DATA.pop_job[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value Job valid Job
function DATA.pop_set_job(pop_id, value)
    DATA.pop_job[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@return number savings
function DATA.pop_get_savings(pop_id)
    return DATA.pop[pop_id].savings
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_savings(pop_id, value)
    DATA.pop[pop_id].savings = value
end
---@param pop_id pop_id valid pop id
---@return pop_id parent
function DATA.pop_get_parent(pop_id)
    return DATA.pop[pop_id].parent
end
---@param pop_id pop_id valid pop id
---@param value pop_id valid pop_id
function DATA.pop_set_parent(pop_id, value)
    DATA.pop[pop_id].parent = value
end
---@param pop_id pop_id valid pop id
---@return pop_id loyalty
function DATA.pop_get_loyalty(pop_id)
    return DATA.pop[pop_id].loyalty
end
---@param pop_id pop_id valid pop id
---@param value pop_id valid pop_id
function DATA.pop_set_loyalty(pop_id, value)
    DATA.pop[pop_id].loyalty = value
end
---@param pop_id pop_id valid pop id
---@return number life_needs_satisfaction from 0 to 1
function DATA.pop_get_life_needs_satisfaction(pop_id)
    return DATA.pop[pop_id].life_needs_satisfaction
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_life_needs_satisfaction(pop_id, value)
    DATA.pop[pop_id].life_needs_satisfaction = value
end
---@param pop_id pop_id valid pop id
---@return number basic_needs_satisfaction from 0 to 1
function DATA.pop_get_basic_needs_satisfaction(pop_id)
    return DATA.pop[pop_id].basic_needs_satisfaction
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_basic_needs_satisfaction(pop_id, value)
    DATA.pop[pop_id].basic_needs_satisfaction = value
end
---@param pop_id pop_id valid pop id
---@param index number valid
---@return NEED need_satisfaction
function DATA.pop_get_need_satisfaction_need(pop_id, index)
    return DATA.pop[pop_id].need_satisfaction[index].need
end
---@param pop_id pop_id valid pop id
---@param index number valid
---@return use_case_id need_satisfaction
function DATA.pop_get_need_satisfaction_use_case(pop_id, index)
    return DATA.pop[pop_id].need_satisfaction[index].use_case
end
---@param pop_id pop_id valid pop id
---@param index number valid
---@return number need_satisfaction
function DATA.pop_get_need_satisfaction_consumed(pop_id, index)
    return DATA.pop[pop_id].need_satisfaction[index].consumed
end
---@param pop_id pop_id valid pop id
---@param index number valid
---@return number need_satisfaction
function DATA.pop_get_need_satisfaction_demanded(pop_id, index)
    return DATA.pop[pop_id].need_satisfaction[index].demanded
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value NEED valid NEED
function DATA.pop_set_need_satisfaction_need(pop_id, index, value)
    DATA.pop[pop_id].need_satisfaction[index].need = value
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value use_case_id valid use_case_id
function DATA.pop_set_need_satisfaction_use_case(pop_id, index, value)
    DATA.pop[pop_id].need_satisfaction[index].use_case = value
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value number valid number
function DATA.pop_set_need_satisfaction_consumed(pop_id, index, value)
    DATA.pop[pop_id].need_satisfaction[index].consumed = value
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value number valid number
function DATA.pop_set_need_satisfaction_demanded(pop_id, index, value)
    DATA.pop[pop_id].need_satisfaction[index].demanded = value
end
---@param pop_id pop_id valid pop id
---@param index number valid
---@return TRAIT traits
function DATA.pop_get_traits(pop_id, index)
    return DATA.pop[pop_id].traits[index]
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value TRAIT valid TRAIT
function DATA.pop_set_traits(pop_id, index, value)
    DATA.pop[pop_id].traits[index] = value
end
---@param pop_id pop_id valid pop id
---@return Building employer
function DATA.pop_get_employer(pop_id)
    return DATA.pop_employer[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value Building valid Building
function DATA.pop_set_employer(pop_id, value)
    DATA.pop_employer[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@return pop_id successor
function DATA.pop_get_successor(pop_id)
    return DATA.pop[pop_id].successor
end
---@param pop_id pop_id valid pop id
---@param value pop_id valid pop_id
function DATA.pop_set_successor(pop_id, value)
    DATA.pop[pop_id].successor = value
end
---@param pop_id pop_id valid pop id
---@return table owned_buildings <Building,Building>
function DATA.pop_get_owned_buildings(pop_id)
    return DATA.pop_owned_buildings[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value table valid table
function DATA.pop_set_owned_buildings(pop_id, value)
    DATA.pop_owned_buildings[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@return table<Realm,Realm> has_trade_permits_in
function DATA.pop_get_has_trade_permits_in(pop_id)
    return DATA.pop_has_trade_permits_in[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value table<Realm,Realm> valid table<Realm,Realm>
function DATA.pop_set_has_trade_permits_in(pop_id, value)
    DATA.pop_has_trade_permits_in[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@return table<Realm,Realm> has_building_permits_in
function DATA.pop_get_has_building_permits_in(pop_id)
    return DATA.pop_has_building_permits_in[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value table<Realm,Realm> valid table<Realm,Realm>
function DATA.pop_set_has_building_permits_in(pop_id, value)
    DATA.pop_has_building_permits_in[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@param index trade_good_id valid
---@return number inventory
function DATA.pop_get_inventory(pop_id, index)
    return DATA.pop[pop_id].inventory[index]
end
---@param pop_id pop_id valid pop id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.pop_set_inventory(pop_id, index, value)
    DATA.pop[pop_id].inventory[index] = value
end
---@param pop_id pop_id valid pop id
---@param index trade_good_id valid
---@return number price_memory
function DATA.pop_get_price_memory(pop_id, index)
    return DATA.pop[pop_id].price_memory[index]
end
---@param pop_id pop_id valid pop id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.pop_set_price_memory(pop_id, index, value)
    DATA.pop[pop_id].price_memory[index] = value
end
---@param pop_id pop_id valid pop id
---@return number forage_ratio a number in (0, 1) interval representing a ratio of time pop spends to forage
function DATA.pop_get_forage_ratio(pop_id)
    return DATA.pop[pop_id].forage_ratio
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_forage_ratio(pop_id, value)
    DATA.pop[pop_id].forage_ratio = value
end
---@param pop_id pop_id valid pop id
---@return number work_ratio a number in (0, 1) interval representing a ratio of time workers spend on a job compared to maximal
function DATA.pop_get_work_ratio(pop_id)
    return DATA.pop[pop_id].work_ratio
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_work_ratio(pop_id, value)
    DATA.pop[pop_id].work_ratio = value
end
---@param pop_id pop_id valid pop id
---@return boolean busy
function DATA.pop_get_busy(pop_id)
    return DATA.pop_busy[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value boolean valid boolean
function DATA.pop_set_busy(pop_id, value)
    DATA.pop_busy[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@return boolean dead
function DATA.pop_get_dead(pop_id)
    return DATA.pop_dead[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value boolean valid boolean
function DATA.pop_set_dead(pop_id, value)
    DATA.pop_dead[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@return Realm realm Represents the home realm of the character
function DATA.pop_get_realm(pop_id)
    return DATA.pop_realm[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value Realm valid Realm
function DATA.pop_set_realm(pop_id, value)
    DATA.pop_realm[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@return table<Realm,Realm> leader_of
function DATA.pop_get_leader_of(pop_id)
    return DATA.pop_leader_of[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value table<Realm,Realm> valid table<Realm,Realm>
function DATA.pop_set_leader_of(pop_id, value)
    DATA.pop_leader_of[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@return table<pop_id,pop_id> current_negotiations
function DATA.pop_get_current_negotiations(pop_id)
    return DATA.pop_current_negotiations[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value table<pop_id,pop_id> valid table<pop_id,pop_id>
function DATA.pop_set_current_negotiations(pop_id, value)
    DATA.pop_current_negotiations[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@return CHARACTER_RANK rank
function DATA.pop_get_rank(pop_id)
    return DATA.pop[pop_id].rank
end
---@param pop_id pop_id valid pop id
---@param value CHARACTER_RANK valid CHARACTER_RANK
function DATA.pop_set_rank(pop_id, value)
    DATA.pop[pop_id].rank = value
end
---@param pop_id pop_id valid pop id
---@return boolean former_pop
function DATA.pop_get_former_pop(pop_id)
    return DATA.pop_former_pop[pop_id]
end
---@param pop_id pop_id valid pop id
---@param value boolean valid boolean
function DATA.pop_set_former_pop(pop_id, value)
    DATA.pop_former_pop[pop_id] = value
end
---@param pop_id pop_id valid pop id
---@param index number valid
---@return number dna
function DATA.pop_get_dna(pop_id, index)
    return DATA.pop[pop_id].dna[index]
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value number valid number
function DATA.pop_set_dna(pop_id, index, value)
    DATA.pop[pop_id].dna[index] = value
end


local fat_pop_id_metatable = {
    __index = function (t,k)
        if (k == "race") then return DATA.pop_get_race(t.id) end
        if (k == "faith") then return DATA.pop_get_faith(t.id) end
        if (k == "culture") then return DATA.pop_get_culture(t.id) end
        if (k == "female") then return DATA.pop_get_female(t.id) end
        if (k == "age") then return DATA.pop_get_age(t.id) end
        if (k == "name") then return DATA.pop_get_name(t.id) end
        if (k == "job") then return DATA.pop_get_job(t.id) end
        if (k == "savings") then return DATA.pop_get_savings(t.id) end
        if (k == "parent") then return DATA.pop_get_parent(t.id) end
        if (k == "loyalty") then return DATA.pop_get_loyalty(t.id) end
        if (k == "life_needs_satisfaction") then return DATA.pop_get_life_needs_satisfaction(t.id) end
        if (k == "basic_needs_satisfaction") then return DATA.pop_get_basic_needs_satisfaction(t.id) end
        if (k == "employer") then return DATA.pop_get_employer(t.id) end
        if (k == "successor") then return DATA.pop_get_successor(t.id) end
        if (k == "owned_buildings") then return DATA.pop_get_owned_buildings(t.id) end
        if (k == "has_trade_permits_in") then return DATA.pop_get_has_trade_permits_in(t.id) end
        if (k == "has_building_permits_in") then return DATA.pop_get_has_building_permits_in(t.id) end
        if (k == "forage_ratio") then return DATA.pop_get_forage_ratio(t.id) end
        if (k == "work_ratio") then return DATA.pop_get_work_ratio(t.id) end
        if (k == "busy") then return DATA.pop_get_busy(t.id) end
        if (k == "dead") then return DATA.pop_get_dead(t.id) end
        if (k == "realm") then return DATA.pop_get_realm(t.id) end
        if (k == "leader_of") then return DATA.pop_get_leader_of(t.id) end
        if (k == "current_negotiations") then return DATA.pop_get_current_negotiations(t.id) end
        if (k == "rank") then return DATA.pop_get_rank(t.id) end
        if (k == "former_pop") then return DATA.pop_get_former_pop(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "race") then
            DATA.pop_set_race(t.id, v)
            return
        end
        if (k == "faith") then
            DATA.pop_set_faith(t.id, v)
            return
        end
        if (k == "culture") then
            DATA.pop_set_culture(t.id, v)
            return
        end
        if (k == "female") then
            DATA.pop_set_female(t.id, v)
            return
        end
        if (k == "age") then
            DATA.pop_set_age(t.id, v)
            return
        end
        if (k == "name") then
            DATA.pop_set_name(t.id, v)
            return
        end
        if (k == "job") then
            DATA.pop_set_job(t.id, v)
            return
        end
        if (k == "savings") then
            DATA.pop_set_savings(t.id, v)
            return
        end
        if (k == "parent") then
            DATA.pop_set_parent(t.id, v)
            return
        end
        if (k == "loyalty") then
            DATA.pop_set_loyalty(t.id, v)
            return
        end
        if (k == "life_needs_satisfaction") then
            DATA.pop_set_life_needs_satisfaction(t.id, v)
            return
        end
        if (k == "basic_needs_satisfaction") then
            DATA.pop_set_basic_needs_satisfaction(t.id, v)
            return
        end
        if (k == "employer") then
            DATA.pop_set_employer(t.id, v)
            return
        end
        if (k == "successor") then
            DATA.pop_set_successor(t.id, v)
            return
        end
        if (k == "owned_buildings") then
            DATA.pop_set_owned_buildings(t.id, v)
            return
        end
        if (k == "has_trade_permits_in") then
            DATA.pop_set_has_trade_permits_in(t.id, v)
            return
        end
        if (k == "has_building_permits_in") then
            DATA.pop_set_has_building_permits_in(t.id, v)
            return
        end
        if (k == "forage_ratio") then
            DATA.pop_set_forage_ratio(t.id, v)
            return
        end
        if (k == "work_ratio") then
            DATA.pop_set_work_ratio(t.id, v)
            return
        end
        if (k == "busy") then
            DATA.pop_set_busy(t.id, v)
            return
        end
        if (k == "dead") then
            DATA.pop_set_dead(t.id, v)
            return
        end
        if (k == "realm") then
            DATA.pop_set_realm(t.id, v)
            return
        end
        if (k == "leader_of") then
            DATA.pop_set_leader_of(t.id, v)
            return
        end
        if (k == "current_negotiations") then
            DATA.pop_set_current_negotiations(t.id, v)
            return
        end
        if (k == "rank") then
            DATA.pop_set_rank(t.id, v)
            return
        end
        if (k == "former_pop") then
            DATA.pop_set_former_pop(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id pop_id
---@return fat_pop_id fat_id
function DATA.fatten_pop(id)
    local result = {id = id}
    setmetatable(result, fat_pop_id_metatable)    return result
end
----------province----------


---province: LSP types---

---Unique identificator for province entity
---@alias province_id number

---@class fat_province_id
---@field id province_id Unique province id
---@field name string
---@field r number
---@field g number
---@field b number
---@field is_land boolean
---@field province_id number
---@field size number
---@field hydration number Number of humans that can live of off this provinces innate water
---@field movement_cost number
---@field center tile_id The tile which contains this province's settlement, if there is any.
---@field infrastructure_needed number
---@field infrastructure number
---@field infrastructure_investment number
---@field realm Realm?
---@field buildings table<Building,Building>
---@field technologies_present table<Technology,Technology>
---@field technologies_researchable table<Technology,Technology>
---@field buildable_buildings table<BuildingType,BuildingType>
---@field local_wealth number
---@field trade_wealth number
---@field local_income number
---@field local_building_upkeep number
---@field foragers number Keeps track of the number of foragers in the province. Used to calculate yields of independent foraging.
---@field foragers_water number amount foraged by pops and characters
---@field foragers_limit number amount of calories foraged by pops and characters
---@field foragers_targets table<ForageResource,{icon:string,output:table<trade_good_id,number>,amount:number,handle:JOBTYPE}>
---@field mood number how local population thinks about the state
---@field throughput_boosts table<ProductionMethod,number>
---@field input_efficiency_boosts table<ProductionMethod,number>
---@field output_efficiency_boosts table<ProductionMethod,number>
---@field on_a_river boolean
---@field on_a_forest boolean

---@class struct_province
---@field r number
---@field g number
---@field b number
---@field is_land boolean
---@field province_id number
---@field size number
---@field hydration number Number of humans that can live of off this provinces innate water
---@field movement_cost number
---@field center tile_id The tile which contains this province's settlement, if there is any.
---@field infrastructure_needed number
---@field infrastructure number
---@field infrastructure_investment number
---@field local_production table<trade_good_id, number>
---@field local_consumption table<trade_good_id, number>
---@field local_demand table<trade_good_id, number>
---@field local_storage table<trade_good_id, number>
---@field local_prices table<trade_good_id, number>
---@field local_wealth number
---@field trade_wealth number
---@field local_income number
---@field local_building_upkeep number
---@field foragers number Keeps track of the number of foragers in the province. Used to calculate yields of independent foraging.
---@field foragers_water number amount foraged by pops and characters
---@field foragers_limit number amount of calories foraged by pops and characters
---@field local_resources table<number, struct_resource_location> An array of local resources and their positions
---@field mood number how local population thinks about the state
---@field unit_types table<unit_type_id, number>
---@field on_a_river boolean
---@field on_a_forest boolean


ffi.cdef[[
    typedef struct {
        float r;
        float g;
        float b;
        bool is_land;
        float province_id;
        float size;
        float hydration;
        float movement_cost;
        uint32_t center;
        float infrastructure_needed;
        float infrastructure;
        float infrastructure_investment;
        float local_production[100];
        float local_consumption[100];
        float local_demand[100];
        float local_storage[100];
        float local_prices[100];
        float local_wealth;
        float trade_wealth;
        float local_income;
        float local_building_upkeep;
        float foragers;
        float foragers_water;
        float foragers_limit;
        resource_location local_resources[25];
        float mood;
        uint32_t unit_types[20];
        bool on_a_river;
        bool on_a_forest;
    } province;
]]

---province: FFI arrays---
---@type (string)[]
DATA.province_name= {}
---@type (Realm?)[]
DATA.province_realm= {}
---@type (table<Building,Building>)[]
DATA.province_buildings= {}
---@type (table<Technology,Technology>)[]
DATA.province_technologies_present= {}
---@type (table<Technology,Technology>)[]
DATA.province_technologies_researchable= {}
---@type (table<BuildingType,BuildingType>)[]
DATA.province_buildable_buildings= {}
---@type (table<ForageResource,{icon:string,output:table<trade_good_id,number>,amount:number,handle:JOBTYPE}>)[]
DATA.province_foragers_targets= {}
---@type (table<ProductionMethod,number>)[]
DATA.province_throughput_boosts= {}
---@type (table<ProductionMethod,number>)[]
DATA.province_input_efficiency_boosts= {}
---@type (table<ProductionMethod,number>)[]
DATA.province_output_efficiency_boosts= {}
---@type nil
DATA.province_malloc = ffi.C.malloc(ffi.sizeof("province") * 10001)
---@type table<province_id, struct_province>
DATA.province = ffi.cast("province*", DATA.province_malloc)

---province: LUA bindings---

DATA.province_size = 10000
---@type table<province_id, boolean>
local province_indices_pool = ffi.new("bool[?]", 10000)
for i = 1, 9999 do
    province_indices_pool[i] = true
end
---@type table<province_id, province_id>
DATA.province_indices_set = {}
function DATA.create_province()
    for i = 1, 9999 do
        if province_indices_pool[i] then
            province_indices_pool[i] = false
            DATA.province_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for province")
end
function DATA.delete_province(i)
    do
        ---@type warband_location_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_warband_location_from_location(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_warband_location(value)
        end
    end
    do
        ---@type character_location_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_character_location_from_location(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_character_location(value)
        end
    end
    do
        ---@type home_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_home_from_home(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_home(value)
        end
    end
    do
        ---@type pop_location_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_pop_location_from_location(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_pop_location(value)
        end
    end
    do
        ---@type outlaw_location_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_outlaw_location_from_location(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_outlaw_location(value)
        end
    end
    do
        ---@type tile_province_membership_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_tile_province_membership_from_province(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_tile_province_membership(value)
        end
    end
    do
        ---@type province_neighborhood_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_province_neighborhood_from_origin(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_province_neighborhood(value)
        end
    end
    do
        ---@type province_neighborhood_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_province_neighborhood_from_target(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_province_neighborhood(value)
        end
    end
    province_indices_pool[i] = true
    DATA.province_indices_set[i] = nil
end
---@param func fun(item: province_id)
function DATA.for_each_province(func)
    for _, item in pairs(DATA.province_indices_set) do
        func(item)
    end
end

---@param province_id province_id valid province id
---@return string name
function DATA.province_get_name(province_id)
    return DATA.province_name[province_id]
end
---@param province_id province_id valid province id
---@param value string valid string
function DATA.province_set_name(province_id, value)
    DATA.province_name[province_id] = value
end
---@param province_id province_id valid province id
---@return number r
function DATA.province_get_r(province_id)
    return DATA.province[province_id].r
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_r(province_id, value)
    DATA.province[province_id].r = value
end
---@param province_id province_id valid province id
---@return number g
function DATA.province_get_g(province_id)
    return DATA.province[province_id].g
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_g(province_id, value)
    DATA.province[province_id].g = value
end
---@param province_id province_id valid province id
---@return number b
function DATA.province_get_b(province_id)
    return DATA.province[province_id].b
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_b(province_id, value)
    DATA.province[province_id].b = value
end
---@param province_id province_id valid province id
---@return boolean is_land
function DATA.province_get_is_land(province_id)
    return DATA.province[province_id].is_land
end
---@param province_id province_id valid province id
---@param value boolean valid boolean
function DATA.province_set_is_land(province_id, value)
    DATA.province[province_id].is_land = value
end
---@param province_id province_id valid province id
---@return number province_id
function DATA.province_get_province_id(province_id)
    return DATA.province[province_id].province_id
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_province_id(province_id, value)
    DATA.province[province_id].province_id = value
end
---@param province_id province_id valid province id
---@return number size
function DATA.province_get_size(province_id)
    return DATA.province[province_id].size
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_size(province_id, value)
    DATA.province[province_id].size = value
end
---@param province_id province_id valid province id
---@return number hydration Number of humans that can live of off this provinces innate water
function DATA.province_get_hydration(province_id)
    return DATA.province[province_id].hydration
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_hydration(province_id, value)
    DATA.province[province_id].hydration = value
end
---@param province_id province_id valid province id
---@return number movement_cost
function DATA.province_get_movement_cost(province_id)
    return DATA.province[province_id].movement_cost
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_movement_cost(province_id, value)
    DATA.province[province_id].movement_cost = value
end
---@param province_id province_id valid province id
---@return tile_id center The tile which contains this province's settlement, if there is any.
function DATA.province_get_center(province_id)
    return DATA.province[province_id].center
end
---@param province_id province_id valid province id
---@param value tile_id valid tile_id
function DATA.province_set_center(province_id, value)
    DATA.province[province_id].center = value
end
---@param province_id province_id valid province id
---@return number infrastructure_needed
function DATA.province_get_infrastructure_needed(province_id)
    return DATA.province[province_id].infrastructure_needed
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_infrastructure_needed(province_id, value)
    DATA.province[province_id].infrastructure_needed = value
end
---@param province_id province_id valid province id
---@return number infrastructure
function DATA.province_get_infrastructure(province_id)
    return DATA.province[province_id].infrastructure
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_infrastructure(province_id, value)
    DATA.province[province_id].infrastructure = value
end
---@param province_id province_id valid province id
---@return number infrastructure_investment
function DATA.province_get_infrastructure_investment(province_id)
    return DATA.province[province_id].infrastructure_investment
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_infrastructure_investment(province_id, value)
    DATA.province[province_id].infrastructure_investment = value
end
---@param province_id province_id valid province id
---@return Realm? realm
function DATA.province_get_realm(province_id)
    return DATA.province_realm[province_id]
end
---@param province_id province_id valid province id
---@param value Realm? valid Realm?
function DATA.province_set_realm(province_id, value)
    DATA.province_realm[province_id] = value
end
---@param province_id province_id valid province id
---@return table<Building,Building> buildings
function DATA.province_get_buildings(province_id)
    return DATA.province_buildings[province_id]
end
---@param province_id province_id valid province id
---@param value table<Building,Building> valid table<Building,Building>
function DATA.province_set_buildings(province_id, value)
    DATA.province_buildings[province_id] = value
end
---@param province_id province_id valid province id
---@return table<Technology,Technology> technologies_present
function DATA.province_get_technologies_present(province_id)
    return DATA.province_technologies_present[province_id]
end
---@param province_id province_id valid province id
---@param value table<Technology,Technology> valid table<Technology,Technology>
function DATA.province_set_technologies_present(province_id, value)
    DATA.province_technologies_present[province_id] = value
end
---@param province_id province_id valid province id
---@return table<Technology,Technology> technologies_researchable
function DATA.province_get_technologies_researchable(province_id)
    return DATA.province_technologies_researchable[province_id]
end
---@param province_id province_id valid province id
---@param value table<Technology,Technology> valid table<Technology,Technology>
function DATA.province_set_technologies_researchable(province_id, value)
    DATA.province_technologies_researchable[province_id] = value
end
---@param province_id province_id valid province id
---@return table<BuildingType,BuildingType> buildable_buildings
function DATA.province_get_buildable_buildings(province_id)
    return DATA.province_buildable_buildings[province_id]
end
---@param province_id province_id valid province id
---@param value table<BuildingType,BuildingType> valid table<BuildingType,BuildingType>
function DATA.province_set_buildable_buildings(province_id, value)
    DATA.province_buildable_buildings[province_id] = value
end
---@param province_id province_id valid province id
---@param index trade_good_id valid
---@return number local_production
function DATA.province_get_local_production(province_id, index)
    return DATA.province[province_id].local_production[index]
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_set_local_production(province_id, index, value)
    DATA.province[province_id].local_production[index] = value
end
---@param province_id province_id valid province id
---@param index trade_good_id valid
---@return number local_consumption
function DATA.province_get_local_consumption(province_id, index)
    return DATA.province[province_id].local_consumption[index]
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_set_local_consumption(province_id, index, value)
    DATA.province[province_id].local_consumption[index] = value
end
---@param province_id province_id valid province id
---@param index trade_good_id valid
---@return number local_demand
function DATA.province_get_local_demand(province_id, index)
    return DATA.province[province_id].local_demand[index]
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_set_local_demand(province_id, index, value)
    DATA.province[province_id].local_demand[index] = value
end
---@param province_id province_id valid province id
---@param index trade_good_id valid
---@return number local_storage
function DATA.province_get_local_storage(province_id, index)
    return DATA.province[province_id].local_storage[index]
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_set_local_storage(province_id, index, value)
    DATA.province[province_id].local_storage[index] = value
end
---@param province_id province_id valid province id
---@param index trade_good_id valid
---@return number local_prices
function DATA.province_get_local_prices(province_id, index)
    return DATA.province[province_id].local_prices[index]
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_set_local_prices(province_id, index, value)
    DATA.province[province_id].local_prices[index] = value
end
---@param province_id province_id valid province id
---@return number local_wealth
function DATA.province_get_local_wealth(province_id)
    return DATA.province[province_id].local_wealth
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_local_wealth(province_id, value)
    DATA.province[province_id].local_wealth = value
end
---@param province_id province_id valid province id
---@return number trade_wealth
function DATA.province_get_trade_wealth(province_id)
    return DATA.province[province_id].trade_wealth
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_trade_wealth(province_id, value)
    DATA.province[province_id].trade_wealth = value
end
---@param province_id province_id valid province id
---@return number local_income
function DATA.province_get_local_income(province_id)
    return DATA.province[province_id].local_income
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_local_income(province_id, value)
    DATA.province[province_id].local_income = value
end
---@param province_id province_id valid province id
---@return number local_building_upkeep
function DATA.province_get_local_building_upkeep(province_id)
    return DATA.province[province_id].local_building_upkeep
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_local_building_upkeep(province_id, value)
    DATA.province[province_id].local_building_upkeep = value
end
---@param province_id province_id valid province id
---@return number foragers Keeps track of the number of foragers in the province. Used to calculate yields of independent foraging.
function DATA.province_get_foragers(province_id)
    return DATA.province[province_id].foragers
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_foragers(province_id, value)
    DATA.province[province_id].foragers = value
end
---@param province_id province_id valid province id
---@return number foragers_water amount foraged by pops and characters
function DATA.province_get_foragers_water(province_id)
    return DATA.province[province_id].foragers_water
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_foragers_water(province_id, value)
    DATA.province[province_id].foragers_water = value
end
---@param province_id province_id valid province id
---@return number foragers_limit amount of calories foraged by pops and characters
function DATA.province_get_foragers_limit(province_id)
    return DATA.province[province_id].foragers_limit
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_foragers_limit(province_id, value)
    DATA.province[province_id].foragers_limit = value
end
---@param province_id province_id valid province id
---@return table<ForageResource,{icon:string,output:table<trade_good_id,number>,amount:number,handle:JOBTYPE}> foragers_targets
function DATA.province_get_foragers_targets(province_id)
    return DATA.province_foragers_targets[province_id]
end
---@param province_id province_id valid province id
---@param value table<ForageResource,{icon:string,output:table<trade_good_id,number>,amount:number,handle:JOBTYPE}> valid table<ForageResource,{icon:string,output:table<trade_good_id,number>,amount:number,handle:JOBTYPE}>
function DATA.province_set_foragers_targets(province_id, value)
    DATA.province_foragers_targets[province_id] = value
end
---@param province_id province_id valid province id
---@param index number valid
---@return resource_id local_resources An array of local resources and their positions
function DATA.province_get_local_resources_resource(province_id, index)
    return DATA.province[province_id].local_resources[index].resource
end
---@param province_id province_id valid province id
---@param index number valid
---@return tile_id local_resources An array of local resources and their positions
function DATA.province_get_local_resources_location(province_id, index)
    return DATA.province[province_id].local_resources[index].location
end
---@param province_id province_id valid province id
---@param index number valid index
---@param value resource_id valid resource_id
function DATA.province_set_local_resources_resource(province_id, index, value)
    DATA.province[province_id].local_resources[index].resource = value
end
---@param province_id province_id valid province id
---@param index number valid index
---@param value tile_id valid tile_id
function DATA.province_set_local_resources_location(province_id, index, value)
    DATA.province[province_id].local_resources[index].location = value
end
---@param province_id province_id valid province id
---@return number mood how local population thinks about the state
function DATA.province_get_mood(province_id)
    return DATA.province[province_id].mood
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_mood(province_id, value)
    DATA.province[province_id].mood = value
end
---@param province_id province_id valid province id
---@param index unit_type_id valid
---@return number unit_types
function DATA.province_get_unit_types(province_id, index)
    return DATA.province[province_id].unit_types[index]
end
---@param province_id province_id valid province id
---@param index unit_type_id valid index
---@param value number valid number
function DATA.province_set_unit_types(province_id, index, value)
    DATA.province[province_id].unit_types[index] = value
end
---@param province_id province_id valid province id
---@return table<ProductionMethod,number> throughput_boosts
function DATA.province_get_throughput_boosts(province_id)
    return DATA.province_throughput_boosts[province_id]
end
---@param province_id province_id valid province id
---@param value table<ProductionMethod,number> valid table<ProductionMethod,number>
function DATA.province_set_throughput_boosts(province_id, value)
    DATA.province_throughput_boosts[province_id] = value
end
---@param province_id province_id valid province id
---@return table<ProductionMethod,number> input_efficiency_boosts
function DATA.province_get_input_efficiency_boosts(province_id)
    return DATA.province_input_efficiency_boosts[province_id]
end
---@param province_id province_id valid province id
---@param value table<ProductionMethod,number> valid table<ProductionMethod,number>
function DATA.province_set_input_efficiency_boosts(province_id, value)
    DATA.province_input_efficiency_boosts[province_id] = value
end
---@param province_id province_id valid province id
---@return table<ProductionMethod,number> output_efficiency_boosts
function DATA.province_get_output_efficiency_boosts(province_id)
    return DATA.province_output_efficiency_boosts[province_id]
end
---@param province_id province_id valid province id
---@param value table<ProductionMethod,number> valid table<ProductionMethod,number>
function DATA.province_set_output_efficiency_boosts(province_id, value)
    DATA.province_output_efficiency_boosts[province_id] = value
end
---@param province_id province_id valid province id
---@return boolean on_a_river
function DATA.province_get_on_a_river(province_id)
    return DATA.province[province_id].on_a_river
end
---@param province_id province_id valid province id
---@param value boolean valid boolean
function DATA.province_set_on_a_river(province_id, value)
    DATA.province[province_id].on_a_river = value
end
---@param province_id province_id valid province id
---@return boolean on_a_forest
function DATA.province_get_on_a_forest(province_id)
    return DATA.province[province_id].on_a_forest
end
---@param province_id province_id valid province id
---@param value boolean valid boolean
function DATA.province_set_on_a_forest(province_id, value)
    DATA.province[province_id].on_a_forest = value
end


local fat_province_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.province_get_name(t.id) end
        if (k == "r") then return DATA.province_get_r(t.id) end
        if (k == "g") then return DATA.province_get_g(t.id) end
        if (k == "b") then return DATA.province_get_b(t.id) end
        if (k == "is_land") then return DATA.province_get_is_land(t.id) end
        if (k == "province_id") then return DATA.province_get_province_id(t.id) end
        if (k == "size") then return DATA.province_get_size(t.id) end
        if (k == "hydration") then return DATA.province_get_hydration(t.id) end
        if (k == "movement_cost") then return DATA.province_get_movement_cost(t.id) end
        if (k == "center") then return DATA.province_get_center(t.id) end
        if (k == "infrastructure_needed") then return DATA.province_get_infrastructure_needed(t.id) end
        if (k == "infrastructure") then return DATA.province_get_infrastructure(t.id) end
        if (k == "infrastructure_investment") then return DATA.province_get_infrastructure_investment(t.id) end
        if (k == "realm") then return DATA.province_get_realm(t.id) end
        if (k == "buildings") then return DATA.province_get_buildings(t.id) end
        if (k == "technologies_present") then return DATA.province_get_technologies_present(t.id) end
        if (k == "technologies_researchable") then return DATA.province_get_technologies_researchable(t.id) end
        if (k == "buildable_buildings") then return DATA.province_get_buildable_buildings(t.id) end
        if (k == "local_wealth") then return DATA.province_get_local_wealth(t.id) end
        if (k == "trade_wealth") then return DATA.province_get_trade_wealth(t.id) end
        if (k == "local_income") then return DATA.province_get_local_income(t.id) end
        if (k == "local_building_upkeep") then return DATA.province_get_local_building_upkeep(t.id) end
        if (k == "foragers") then return DATA.province_get_foragers(t.id) end
        if (k == "foragers_water") then return DATA.province_get_foragers_water(t.id) end
        if (k == "foragers_limit") then return DATA.province_get_foragers_limit(t.id) end
        if (k == "foragers_targets") then return DATA.province_get_foragers_targets(t.id) end
        if (k == "mood") then return DATA.province_get_mood(t.id) end
        if (k == "throughput_boosts") then return DATA.province_get_throughput_boosts(t.id) end
        if (k == "input_efficiency_boosts") then return DATA.province_get_input_efficiency_boosts(t.id) end
        if (k == "output_efficiency_boosts") then return DATA.province_get_output_efficiency_boosts(t.id) end
        if (k == "on_a_river") then return DATA.province_get_on_a_river(t.id) end
        if (k == "on_a_forest") then return DATA.province_get_on_a_forest(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.province_set_name(t.id, v)
            return
        end
        if (k == "r") then
            DATA.province_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.province_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.province_set_b(t.id, v)
            return
        end
        if (k == "is_land") then
            DATA.province_set_is_land(t.id, v)
            return
        end
        if (k == "province_id") then
            DATA.province_set_province_id(t.id, v)
            return
        end
        if (k == "size") then
            DATA.province_set_size(t.id, v)
            return
        end
        if (k == "hydration") then
            DATA.province_set_hydration(t.id, v)
            return
        end
        if (k == "movement_cost") then
            DATA.province_set_movement_cost(t.id, v)
            return
        end
        if (k == "center") then
            DATA.province_set_center(t.id, v)
            return
        end
        if (k == "infrastructure_needed") then
            DATA.province_set_infrastructure_needed(t.id, v)
            return
        end
        if (k == "infrastructure") then
            DATA.province_set_infrastructure(t.id, v)
            return
        end
        if (k == "infrastructure_investment") then
            DATA.province_set_infrastructure_investment(t.id, v)
            return
        end
        if (k == "realm") then
            DATA.province_set_realm(t.id, v)
            return
        end
        if (k == "buildings") then
            DATA.province_set_buildings(t.id, v)
            return
        end
        if (k == "technologies_present") then
            DATA.province_set_technologies_present(t.id, v)
            return
        end
        if (k == "technologies_researchable") then
            DATA.province_set_technologies_researchable(t.id, v)
            return
        end
        if (k == "buildable_buildings") then
            DATA.province_set_buildable_buildings(t.id, v)
            return
        end
        if (k == "local_wealth") then
            DATA.province_set_local_wealth(t.id, v)
            return
        end
        if (k == "trade_wealth") then
            DATA.province_set_trade_wealth(t.id, v)
            return
        end
        if (k == "local_income") then
            DATA.province_set_local_income(t.id, v)
            return
        end
        if (k == "local_building_upkeep") then
            DATA.province_set_local_building_upkeep(t.id, v)
            return
        end
        if (k == "foragers") then
            DATA.province_set_foragers(t.id, v)
            return
        end
        if (k == "foragers_water") then
            DATA.province_set_foragers_water(t.id, v)
            return
        end
        if (k == "foragers_limit") then
            DATA.province_set_foragers_limit(t.id, v)
            return
        end
        if (k == "foragers_targets") then
            DATA.province_set_foragers_targets(t.id, v)
            return
        end
        if (k == "mood") then
            DATA.province_set_mood(t.id, v)
            return
        end
        if (k == "throughput_boosts") then
            DATA.province_set_throughput_boosts(t.id, v)
            return
        end
        if (k == "input_efficiency_boosts") then
            DATA.province_set_input_efficiency_boosts(t.id, v)
            return
        end
        if (k == "output_efficiency_boosts") then
            DATA.province_set_output_efficiency_boosts(t.id, v)
            return
        end
        if (k == "on_a_river") then
            DATA.province_set_on_a_river(t.id, v)
            return
        end
        if (k == "on_a_forest") then
            DATA.province_set_on_a_forest(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id province_id
---@return fat_province_id fat_id
function DATA.fatten_province(id)
    local result = {id = id}
    setmetatable(result, fat_province_id_metatable)    return result
end
----------army----------


---army: LSP types---

---Unique identificator for army entity
---@alias army_id number

---@class fat_army_id
---@field id army_id Unique army id
---@field destination province_id

---@class struct_army
---@field destination province_id


ffi.cdef[[
    typedef struct {
        uint32_t destination;
    } army;
]]

---army: FFI arrays---
---@type nil
DATA.army_malloc = ffi.C.malloc(ffi.sizeof("army") * 5001)
---@type table<army_id, struct_army>
DATA.army = ffi.cast("army*", DATA.army_malloc)

---army: LUA bindings---

DATA.army_size = 5000
---@type table<army_id, boolean>
local army_indices_pool = ffi.new("bool[?]", 5000)
for i = 1, 4999 do
    army_indices_pool[i] = true
end
---@type table<army_id, army_id>
DATA.army_indices_set = {}
function DATA.create_army()
    for i = 1, 4999 do
        if army_indices_pool[i] then
            army_indices_pool[i] = false
            DATA.army_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for army")
end
function DATA.delete_army(i)
    do
        ---@type army_membership_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_army_membership_from_army(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_army_membership(value)
        end
    end
    army_indices_pool[i] = true
    DATA.army_indices_set[i] = nil
end
---@param func fun(item: army_id)
function DATA.for_each_army(func)
    for _, item in pairs(DATA.army_indices_set) do
        func(item)
    end
end

---@param army_id army_id valid army id
---@return province_id destination
function DATA.army_get_destination(army_id)
    return DATA.army[army_id].destination
end
---@param army_id army_id valid army id
---@param value province_id valid province_id
function DATA.army_set_destination(army_id, value)
    DATA.army[army_id].destination = value
end


local fat_army_id_metatable = {
    __index = function (t,k)
        if (k == "destination") then return DATA.army_get_destination(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "destination") then
            DATA.army_set_destination(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id army_id
---@return fat_army_id fat_id
function DATA.fatten_army(id)
    local result = {id = id}
    setmetatable(result, fat_army_id_metatable)    return result
end
----------warband----------


---warband: LSP types---

---Unique identificator for warband entity
---@alias warband_id number

---@class fat_warband_id
---@field id warband_id Unique warband id
---@field name string
---@field guard_of Realm?
---@field status WARBAND_STATUS
---@field idle_stance WARBAND_STANCE
---@field current_free_time_ratio number How much of "idle" free time they are actually idle. Set by events.
---@field treasury number
---@field total_upkeep number
---@field predicted_upkeep number
---@field supplies number
---@field supplies_target_days number
---@field morale number

---@class struct_warband
---@field units_current table<unit_type_id, number> Current distribution of units in the warband
---@field units_target table<unit_type_id, number> Units to recruit
---@field status WARBAND_STATUS
---@field idle_stance WARBAND_STANCE
---@field current_free_time_ratio number How much of "idle" free time they are actually idle. Set by events.
---@field treasury number
---@field total_upkeep number
---@field predicted_upkeep number
---@field supplies number
---@field supplies_target_days number
---@field morale number


ffi.cdef[[
    typedef struct {
        float units_current[20];
        float units_target[20];
        uint8_t status;
        uint8_t idle_stance;
        float current_free_time_ratio;
        float treasury;
        float total_upkeep;
        float predicted_upkeep;
        float supplies;
        float supplies_target_days;
        float morale;
    } warband;
]]

---warband: FFI arrays---
---@type (string)[]
DATA.warband_name= {}
---@type (Realm?)[]
DATA.warband_guard_of= {}
---@type nil
DATA.warband_malloc = ffi.C.malloc(ffi.sizeof("warband") * 10001)
---@type table<warband_id, struct_warband>
DATA.warband = ffi.cast("warband*", DATA.warband_malloc)

---warband: LUA bindings---

DATA.warband_size = 10000
---@type table<warband_id, boolean>
local warband_indices_pool = ffi.new("bool[?]", 10000)
for i = 1, 9999 do
    warband_indices_pool[i] = true
end
---@type table<warband_id, warband_id>
DATA.warband_indices_set = {}
function DATA.create_warband()
    for i = 1, 9999 do
        if warband_indices_pool[i] then
            warband_indices_pool[i] = false
            DATA.warband_indices_set[i] = i
            DATA.warband_set_name(i, "Warband")
            DATA.warband_set_current_free_time_ratio(i, 1.0)
            DATA.warband_set_treasury(i, 0)
            DATA.warband_set_total_upkeep(i, 0.0)
            DATA.warband_set_predicted_upkeep(i, 0.0)
            DATA.warband_set_supplies(i, 0.0)
            DATA.warband_set_supplies_target_days(i, 60)
            DATA.warband_set_morale(i, 0.5)
            return i
        end
    end
    error("Run out of space for warband")
end
function DATA.delete_warband(i)
    do
        local to_delete = DATA.get_army_membership_from_member(i)
        DATA.delete_army_membership(to_delete)
    end
    do
        local to_delete = DATA.get_warband_leader_from_warband(i)
        DATA.delete_warband_leader(to_delete)
    end
    do
        local to_delete = DATA.get_warband_recruiter_from_warband(i)
        DATA.delete_warband_recruiter(to_delete)
    end
    do
        local to_delete = DATA.get_warband_commander_from_warband(i)
        DATA.delete_warband_commander(to_delete)
    end
    do
        local to_delete = DATA.get_warband_location_from_warband(i)
        DATA.delete_warband_location(to_delete)
    end
    do
        ---@type warband_unit_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_warband_unit_from_warband(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_warband_unit(value)
        end
    end
    warband_indices_pool[i] = true
    DATA.warband_indices_set[i] = nil
end
---@param func fun(item: warband_id)
function DATA.for_each_warband(func)
    for _, item in pairs(DATA.warband_indices_set) do
        func(item)
    end
end

---@param warband_id warband_id valid warband id
---@return string name
function DATA.warband_get_name(warband_id)
    return DATA.warband_name[warband_id]
end
---@param warband_id warband_id valid warband id
---@param value string valid string
function DATA.warband_set_name(warband_id, value)
    DATA.warband_name[warband_id] = value
end
---@param warband_id warband_id valid warband id
---@return Realm? guard_of
function DATA.warband_get_guard_of(warband_id)
    return DATA.warband_guard_of[warband_id]
end
---@param warband_id warband_id valid warband id
---@param value Realm? valid Realm?
function DATA.warband_set_guard_of(warband_id, value)
    DATA.warband_guard_of[warband_id] = value
end
---@param warband_id warband_id valid warband id
---@param index unit_type_id valid
---@return number units_current Current distribution of units in the warband
function DATA.warband_get_units_current(warband_id, index)
    return DATA.warband[warband_id].units_current[index]
end
---@param warband_id warband_id valid warband id
---@param index unit_type_id valid index
---@param value number valid number
function DATA.warband_set_units_current(warband_id, index, value)
    DATA.warband[warband_id].units_current[index] = value
end
---@param warband_id warband_id valid warband id
---@param index unit_type_id valid
---@return number units_target Units to recruit
function DATA.warband_get_units_target(warband_id, index)
    return DATA.warband[warband_id].units_target[index]
end
---@param warband_id warband_id valid warband id
---@param index unit_type_id valid index
---@param value number valid number
function DATA.warband_set_units_target(warband_id, index, value)
    DATA.warband[warband_id].units_target[index] = value
end
---@param warband_id warband_id valid warband id
---@return WARBAND_STATUS status
function DATA.warband_get_status(warband_id)
    return DATA.warband[warband_id].status
end
---@param warband_id warband_id valid warband id
---@param value WARBAND_STATUS valid WARBAND_STATUS
function DATA.warband_set_status(warband_id, value)
    DATA.warband[warband_id].status = value
end
---@param warband_id warband_id valid warband id
---@return WARBAND_STANCE idle_stance
function DATA.warband_get_idle_stance(warband_id)
    return DATA.warband[warband_id].idle_stance
end
---@param warband_id warband_id valid warband id
---@param value WARBAND_STANCE valid WARBAND_STANCE
function DATA.warband_set_idle_stance(warband_id, value)
    DATA.warband[warband_id].idle_stance = value
end
---@param warband_id warband_id valid warband id
---@return number current_free_time_ratio How much of "idle" free time they are actually idle. Set by events.
function DATA.warband_get_current_free_time_ratio(warband_id)
    return DATA.warband[warband_id].current_free_time_ratio
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_current_free_time_ratio(warband_id, value)
    DATA.warband[warband_id].current_free_time_ratio = value
end
---@param warband_id warband_id valid warband id
---@return number treasury
function DATA.warband_get_treasury(warband_id)
    return DATA.warband[warband_id].treasury
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_treasury(warband_id, value)
    DATA.warband[warband_id].treasury = value
end
---@param warband_id warband_id valid warband id
---@return number total_upkeep
function DATA.warband_get_total_upkeep(warband_id)
    return DATA.warband[warband_id].total_upkeep
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_total_upkeep(warband_id, value)
    DATA.warband[warband_id].total_upkeep = value
end
---@param warband_id warband_id valid warband id
---@return number predicted_upkeep
function DATA.warband_get_predicted_upkeep(warband_id)
    return DATA.warband[warband_id].predicted_upkeep
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_predicted_upkeep(warband_id, value)
    DATA.warband[warband_id].predicted_upkeep = value
end
---@param warband_id warband_id valid warband id
---@return number supplies
function DATA.warband_get_supplies(warband_id)
    return DATA.warband[warband_id].supplies
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_supplies(warband_id, value)
    DATA.warband[warband_id].supplies = value
end
---@param warband_id warband_id valid warband id
---@return number supplies_target_days
function DATA.warband_get_supplies_target_days(warband_id)
    return DATA.warband[warband_id].supplies_target_days
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_supplies_target_days(warband_id, value)
    DATA.warband[warband_id].supplies_target_days = value
end
---@param warband_id warband_id valid warband id
---@return number morale
function DATA.warband_get_morale(warband_id)
    return DATA.warband[warband_id].morale
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_morale(warband_id, value)
    DATA.warband[warband_id].morale = value
end


local fat_warband_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.warband_get_name(t.id) end
        if (k == "guard_of") then return DATA.warband_get_guard_of(t.id) end
        if (k == "status") then return DATA.warband_get_status(t.id) end
        if (k == "idle_stance") then return DATA.warband_get_idle_stance(t.id) end
        if (k == "current_free_time_ratio") then return DATA.warband_get_current_free_time_ratio(t.id) end
        if (k == "treasury") then return DATA.warband_get_treasury(t.id) end
        if (k == "total_upkeep") then return DATA.warband_get_total_upkeep(t.id) end
        if (k == "predicted_upkeep") then return DATA.warband_get_predicted_upkeep(t.id) end
        if (k == "supplies") then return DATA.warband_get_supplies(t.id) end
        if (k == "supplies_target_days") then return DATA.warband_get_supplies_target_days(t.id) end
        if (k == "morale") then return DATA.warband_get_morale(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.warband_set_name(t.id, v)
            return
        end
        if (k == "guard_of") then
            DATA.warband_set_guard_of(t.id, v)
            return
        end
        if (k == "status") then
            DATA.warband_set_status(t.id, v)
            return
        end
        if (k == "idle_stance") then
            DATA.warband_set_idle_stance(t.id, v)
            return
        end
        if (k == "current_free_time_ratio") then
            DATA.warband_set_current_free_time_ratio(t.id, v)
            return
        end
        if (k == "treasury") then
            DATA.warband_set_treasury(t.id, v)
            return
        end
        if (k == "total_upkeep") then
            DATA.warband_set_total_upkeep(t.id, v)
            return
        end
        if (k == "predicted_upkeep") then
            DATA.warband_set_predicted_upkeep(t.id, v)
            return
        end
        if (k == "supplies") then
            DATA.warband_set_supplies(t.id, v)
            return
        end
        if (k == "supplies_target_days") then
            DATA.warband_set_supplies_target_days(t.id, v)
            return
        end
        if (k == "morale") then
            DATA.warband_set_morale(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id warband_id
---@return fat_warband_id fat_id
function DATA.fatten_warband(id)
    local result = {id = id}
    setmetatable(result, fat_warband_id_metatable)    return result
end
----------army_membership----------


---army_membership: LSP types---

---Unique identificator for army_membership entity
---@alias army_membership_id number

---@class fat_army_membership_id
---@field id army_membership_id Unique army_membership id
---@field army army_id
---@field member warband_id part of army

---@class struct_army_membership
---@field army army_id
---@field member warband_id part of army


ffi.cdef[[
    typedef struct {
        uint32_t army;
        uint32_t member;
    } army_membership;
]]

---army_membership: FFI arrays---
---@type nil
DATA.army_membership_malloc = ffi.C.malloc(ffi.sizeof("army_membership") * 10001)
---@type table<army_membership_id, struct_army_membership>
DATA.army_membership = ffi.cast("army_membership*", DATA.army_membership_malloc)
---@type table<army_id, army_membership_id[]>>
DATA.army_membership_from_army= {}
---@type table<warband_id, army_membership_id>
DATA.army_membership_from_member= {}

---army_membership: LUA bindings---

DATA.army_membership_size = 10000
---@type table<army_membership_id, boolean>
local army_membership_indices_pool = ffi.new("bool[?]", 10000)
for i = 1, 9999 do
    army_membership_indices_pool[i] = true
end
---@type table<army_membership_id, army_membership_id>
DATA.army_membership_indices_set = {}
function DATA.create_army_membership()
    for i = 1, 9999 do
        if army_membership_indices_pool[i] then
            army_membership_indices_pool[i] = false
            DATA.army_membership_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for army_membership")
end
function DATA.delete_army_membership(i)
    do
        local old_value = DATA.army_membership[i].army
        __REMOVE_KEY_ARMY_MEMBERSHIP_ARMY(i, old_value)
    end
    do
        local old_value = DATA.army_membership[i].member
        __REMOVE_KEY_ARMY_MEMBERSHIP_MEMBER(old_value)
    end
    army_membership_indices_pool[i] = true
    DATA.army_membership_indices_set[i] = nil
end
---@param func fun(item: army_membership_id)
function DATA.for_each_army_membership(func)
    for _, item in pairs(DATA.army_membership_indices_set) do
        func(item)
    end
end

---@param army_membership_id army_membership_id valid army_membership id
---@return army_id army
function DATA.army_membership_get_army(army_membership_id)
    return DATA.army_membership[army_membership_id].army
end
---@param army army_id valid army_id
---@return army_membership_id[] An array of army_membership
function DATA.get_army_membership_from_army(army)
    return DATA.army_membership_from_army[army]
end
---@param army_membership_id army_membership_id valid army_membership id
---@param old_value army_id valid army_id
function __REMOVE_KEY_ARMY_MEMBERSHIP_ARMY(army_membership_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.army_membership_from_army[old_value]) do
        if value == army_membership_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.army_membership_from_army[old_value], found_key)
    end
end
---@param army_membership_id army_membership_id valid army_membership id
---@param value army_id valid army_id
function DATA.army_membership_set_army(army_membership_id, value)
    local old_value = DATA.army_membership[army_membership_id].army
    DATA.army_membership[army_membership_id].army = value
    __REMOVE_KEY_ARMY_MEMBERSHIP_ARMY(army_membership_id, old_value)
    table.insert(DATA.army_membership_from_army[value], army_membership_id)
end
---@param army_membership_id army_membership_id valid army_membership id
---@return warband_id member part of army
function DATA.army_membership_get_member(army_membership_id)
    return DATA.army_membership[army_membership_id].member
end
---@param member warband_id valid warband_id
---@return army_membership_id army_membership
function DATA.get_army_membership_from_member(member)
    return DATA.army_membership_from_member[member]
end
function __REMOVE_KEY_ARMY_MEMBERSHIP_MEMBER(old_value)
    DATA.army_membership_from_member[old_value] = nil
end
---@param army_membership_id army_membership_id valid army_membership id
---@param value warband_id valid warband_id
function DATA.army_membership_set_member(army_membership_id, value)
    local old_value = DATA.army_membership[army_membership_id].member
    DATA.army_membership[army_membership_id].member = value
    __REMOVE_KEY_ARMY_MEMBERSHIP_MEMBER(old_value)
    DATA.army_membership_from_member[value] = army_membership_id
end


local fat_army_membership_id_metatable = {
    __index = function (t,k)
        if (k == "army") then return DATA.army_membership_get_army(t.id) end
        if (k == "member") then return DATA.army_membership_get_member(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id army_membership_id
---@return fat_army_membership_id fat_id
function DATA.fatten_army_membership(id)
    local result = {id = id}
    setmetatable(result, fat_army_membership_id_metatable)    return result
end
----------warband_leader----------


---warband_leader: LSP types---

---Unique identificator for warband_leader entity
---@alias warband_leader_id number

---@class fat_warband_leader_id
---@field id warband_leader_id Unique warband_leader id
---@field leader pop_id
---@field warband warband_id

---@class struct_warband_leader
---@field leader pop_id
---@field warband warband_id


ffi.cdef[[
    typedef struct {
        uint32_t leader;
        uint32_t warband;
    } warband_leader;
]]

---warband_leader: FFI arrays---
---@type nil
DATA.warband_leader_malloc = ffi.C.malloc(ffi.sizeof("warband_leader") * 10001)
---@type table<warband_leader_id, struct_warband_leader>
DATA.warband_leader = ffi.cast("warband_leader*", DATA.warband_leader_malloc)
---@type table<pop_id, warband_leader_id>
DATA.warband_leader_from_leader= {}
---@type table<warband_id, warband_leader_id>
DATA.warband_leader_from_warband= {}

---warband_leader: LUA bindings---

DATA.warband_leader_size = 10000
---@type table<warband_leader_id, boolean>
local warband_leader_indices_pool = ffi.new("bool[?]", 10000)
for i = 1, 9999 do
    warband_leader_indices_pool[i] = true
end
---@type table<warband_leader_id, warband_leader_id>
DATA.warband_leader_indices_set = {}
function DATA.create_warband_leader()
    for i = 1, 9999 do
        if warband_leader_indices_pool[i] then
            warband_leader_indices_pool[i] = false
            DATA.warband_leader_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for warband_leader")
end
function DATA.delete_warband_leader(i)
    do
        local old_value = DATA.warband_leader[i].leader
        __REMOVE_KEY_WARBAND_LEADER_LEADER(old_value)
    end
    do
        local old_value = DATA.warband_leader[i].warband
        __REMOVE_KEY_WARBAND_LEADER_WARBAND(old_value)
    end
    warband_leader_indices_pool[i] = true
    DATA.warband_leader_indices_set[i] = nil
end
---@param func fun(item: warband_leader_id)
function DATA.for_each_warband_leader(func)
    for _, item in pairs(DATA.warband_leader_indices_set) do
        func(item)
    end
end

---@param warband_leader_id warband_leader_id valid warband_leader id
---@return pop_id leader
function DATA.warband_leader_get_leader(warband_leader_id)
    return DATA.warband_leader[warband_leader_id].leader
end
---@param leader pop_id valid pop_id
---@return warband_leader_id warband_leader
function DATA.get_warband_leader_from_leader(leader)
    return DATA.warband_leader_from_leader[leader]
end
function __REMOVE_KEY_WARBAND_LEADER_LEADER(old_value)
    DATA.warband_leader_from_leader[old_value] = nil
end
---@param warband_leader_id warband_leader_id valid warband_leader id
---@param value pop_id valid pop_id
function DATA.warband_leader_set_leader(warband_leader_id, value)
    local old_value = DATA.warband_leader[warband_leader_id].leader
    DATA.warband_leader[warband_leader_id].leader = value
    __REMOVE_KEY_WARBAND_LEADER_LEADER(old_value)
    DATA.warband_leader_from_leader[value] = warband_leader_id
end
---@param warband_leader_id warband_leader_id valid warband_leader id
---@return warband_id warband
function DATA.warband_leader_get_warband(warband_leader_id)
    return DATA.warband_leader[warband_leader_id].warband
end
---@param warband warband_id valid warband_id
---@return warband_leader_id warband_leader
function DATA.get_warband_leader_from_warband(warband)
    return DATA.warband_leader_from_warband[warband]
end
function __REMOVE_KEY_WARBAND_LEADER_WARBAND(old_value)
    DATA.warband_leader_from_warband[old_value] = nil
end
---@param warband_leader_id warband_leader_id valid warband_leader id
---@param value warband_id valid warband_id
function DATA.warband_leader_set_warband(warband_leader_id, value)
    local old_value = DATA.warband_leader[warband_leader_id].warband
    DATA.warband_leader[warband_leader_id].warband = value
    __REMOVE_KEY_WARBAND_LEADER_WARBAND(old_value)
    DATA.warband_leader_from_warband[value] = warband_leader_id
end


local fat_warband_leader_id_metatable = {
    __index = function (t,k)
        if (k == "leader") then return DATA.warband_leader_get_leader(t.id) end
        if (k == "warband") then return DATA.warband_leader_get_warband(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id warband_leader_id
---@return fat_warband_leader_id fat_id
function DATA.fatten_warband_leader(id)
    local result = {id = id}
    setmetatable(result, fat_warband_leader_id_metatable)    return result
end
----------warband_recruiter----------


---warband_recruiter: LSP types---

---Unique identificator for warband_recruiter entity
---@alias warband_recruiter_id number

---@class fat_warband_recruiter_id
---@field id warband_recruiter_id Unique warband_recruiter id
---@field recruiter pop_id
---@field warband warband_id

---@class struct_warband_recruiter
---@field recruiter pop_id
---@field warband warband_id


ffi.cdef[[
    typedef struct {
        uint32_t recruiter;
        uint32_t warband;
    } warband_recruiter;
]]

---warband_recruiter: FFI arrays---
---@type nil
DATA.warband_recruiter_malloc = ffi.C.malloc(ffi.sizeof("warband_recruiter") * 10001)
---@type table<warband_recruiter_id, struct_warband_recruiter>
DATA.warband_recruiter = ffi.cast("warband_recruiter*", DATA.warband_recruiter_malloc)
---@type table<pop_id, warband_recruiter_id>
DATA.warband_recruiter_from_recruiter= {}
---@type table<warband_id, warband_recruiter_id>
DATA.warband_recruiter_from_warband= {}

---warband_recruiter: LUA bindings---

DATA.warband_recruiter_size = 10000
---@type table<warband_recruiter_id, boolean>
local warband_recruiter_indices_pool = ffi.new("bool[?]", 10000)
for i = 1, 9999 do
    warband_recruiter_indices_pool[i] = true
end
---@type table<warband_recruiter_id, warband_recruiter_id>
DATA.warband_recruiter_indices_set = {}
function DATA.create_warband_recruiter()
    for i = 1, 9999 do
        if warband_recruiter_indices_pool[i] then
            warband_recruiter_indices_pool[i] = false
            DATA.warband_recruiter_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for warband_recruiter")
end
function DATA.delete_warband_recruiter(i)
    do
        local old_value = DATA.warband_recruiter[i].recruiter
        __REMOVE_KEY_WARBAND_RECRUITER_RECRUITER(old_value)
    end
    do
        local old_value = DATA.warband_recruiter[i].warband
        __REMOVE_KEY_WARBAND_RECRUITER_WARBAND(old_value)
    end
    warband_recruiter_indices_pool[i] = true
    DATA.warband_recruiter_indices_set[i] = nil
end
---@param func fun(item: warband_recruiter_id)
function DATA.for_each_warband_recruiter(func)
    for _, item in pairs(DATA.warband_recruiter_indices_set) do
        func(item)
    end
end

---@param warband_recruiter_id warband_recruiter_id valid warband_recruiter id
---@return pop_id recruiter
function DATA.warband_recruiter_get_recruiter(warband_recruiter_id)
    return DATA.warband_recruiter[warband_recruiter_id].recruiter
end
---@param recruiter pop_id valid pop_id
---@return warband_recruiter_id warband_recruiter
function DATA.get_warband_recruiter_from_recruiter(recruiter)
    return DATA.warband_recruiter_from_recruiter[recruiter]
end
function __REMOVE_KEY_WARBAND_RECRUITER_RECRUITER(old_value)
    DATA.warband_recruiter_from_recruiter[old_value] = nil
end
---@param warband_recruiter_id warband_recruiter_id valid warband_recruiter id
---@param value pop_id valid pop_id
function DATA.warband_recruiter_set_recruiter(warband_recruiter_id, value)
    local old_value = DATA.warband_recruiter[warband_recruiter_id].recruiter
    DATA.warband_recruiter[warband_recruiter_id].recruiter = value
    __REMOVE_KEY_WARBAND_RECRUITER_RECRUITER(old_value)
    DATA.warband_recruiter_from_recruiter[value] = warband_recruiter_id
end
---@param warband_recruiter_id warband_recruiter_id valid warband_recruiter id
---@return warband_id warband
function DATA.warband_recruiter_get_warband(warband_recruiter_id)
    return DATA.warband_recruiter[warband_recruiter_id].warband
end
---@param warband warband_id valid warband_id
---@return warband_recruiter_id warband_recruiter
function DATA.get_warband_recruiter_from_warband(warband)
    return DATA.warband_recruiter_from_warband[warband]
end
function __REMOVE_KEY_WARBAND_RECRUITER_WARBAND(old_value)
    DATA.warband_recruiter_from_warband[old_value] = nil
end
---@param warband_recruiter_id warband_recruiter_id valid warband_recruiter id
---@param value warband_id valid warband_id
function DATA.warband_recruiter_set_warband(warband_recruiter_id, value)
    local old_value = DATA.warband_recruiter[warband_recruiter_id].warband
    DATA.warband_recruiter[warband_recruiter_id].warband = value
    __REMOVE_KEY_WARBAND_RECRUITER_WARBAND(old_value)
    DATA.warband_recruiter_from_warband[value] = warband_recruiter_id
end


local fat_warband_recruiter_id_metatable = {
    __index = function (t,k)
        if (k == "recruiter") then return DATA.warband_recruiter_get_recruiter(t.id) end
        if (k == "warband") then return DATA.warband_recruiter_get_warband(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id warband_recruiter_id
---@return fat_warband_recruiter_id fat_id
function DATA.fatten_warband_recruiter(id)
    local result = {id = id}
    setmetatable(result, fat_warband_recruiter_id_metatable)    return result
end
----------warband_commander----------


---warband_commander: LSP types---

---Unique identificator for warband_commander entity
---@alias warband_commander_id number

---@class fat_warband_commander_id
---@field id warband_commander_id Unique warband_commander id
---@field commander pop_id
---@field warband warband_id

---@class struct_warband_commander
---@field commander pop_id
---@field warband warband_id


ffi.cdef[[
    typedef struct {
        uint32_t commander;
        uint32_t warband;
    } warband_commander;
]]

---warband_commander: FFI arrays---
---@type nil
DATA.warband_commander_malloc = ffi.C.malloc(ffi.sizeof("warband_commander") * 10001)
---@type table<warband_commander_id, struct_warband_commander>
DATA.warband_commander = ffi.cast("warband_commander*", DATA.warband_commander_malloc)
---@type table<pop_id, warband_commander_id>
DATA.warband_commander_from_commander= {}
---@type table<warband_id, warband_commander_id>
DATA.warband_commander_from_warband= {}

---warband_commander: LUA bindings---

DATA.warband_commander_size = 10000
---@type table<warband_commander_id, boolean>
local warband_commander_indices_pool = ffi.new("bool[?]", 10000)
for i = 1, 9999 do
    warband_commander_indices_pool[i] = true
end
---@type table<warband_commander_id, warband_commander_id>
DATA.warband_commander_indices_set = {}
function DATA.create_warband_commander()
    for i = 1, 9999 do
        if warband_commander_indices_pool[i] then
            warband_commander_indices_pool[i] = false
            DATA.warband_commander_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for warband_commander")
end
function DATA.delete_warband_commander(i)
    do
        local old_value = DATA.warband_commander[i].commander
        __REMOVE_KEY_WARBAND_COMMANDER_COMMANDER(old_value)
    end
    do
        local old_value = DATA.warband_commander[i].warband
        __REMOVE_KEY_WARBAND_COMMANDER_WARBAND(old_value)
    end
    warband_commander_indices_pool[i] = true
    DATA.warband_commander_indices_set[i] = nil
end
---@param func fun(item: warband_commander_id)
function DATA.for_each_warband_commander(func)
    for _, item in pairs(DATA.warband_commander_indices_set) do
        func(item)
    end
end

---@param warband_commander_id warband_commander_id valid warband_commander id
---@return pop_id commander
function DATA.warband_commander_get_commander(warband_commander_id)
    return DATA.warband_commander[warband_commander_id].commander
end
---@param commander pop_id valid pop_id
---@return warband_commander_id warband_commander
function DATA.get_warband_commander_from_commander(commander)
    return DATA.warband_commander_from_commander[commander]
end
function __REMOVE_KEY_WARBAND_COMMANDER_COMMANDER(old_value)
    DATA.warband_commander_from_commander[old_value] = nil
end
---@param warband_commander_id warband_commander_id valid warband_commander id
---@param value pop_id valid pop_id
function DATA.warband_commander_set_commander(warband_commander_id, value)
    local old_value = DATA.warband_commander[warband_commander_id].commander
    DATA.warband_commander[warband_commander_id].commander = value
    __REMOVE_KEY_WARBAND_COMMANDER_COMMANDER(old_value)
    DATA.warband_commander_from_commander[value] = warband_commander_id
end
---@param warband_commander_id warband_commander_id valid warband_commander id
---@return warband_id warband
function DATA.warband_commander_get_warband(warband_commander_id)
    return DATA.warband_commander[warband_commander_id].warband
end
---@param warband warband_id valid warband_id
---@return warband_commander_id warband_commander
function DATA.get_warband_commander_from_warband(warband)
    return DATA.warband_commander_from_warband[warband]
end
function __REMOVE_KEY_WARBAND_COMMANDER_WARBAND(old_value)
    DATA.warband_commander_from_warband[old_value] = nil
end
---@param warband_commander_id warband_commander_id valid warband_commander id
---@param value warband_id valid warband_id
function DATA.warband_commander_set_warband(warband_commander_id, value)
    local old_value = DATA.warband_commander[warband_commander_id].warband
    DATA.warband_commander[warband_commander_id].warband = value
    __REMOVE_KEY_WARBAND_COMMANDER_WARBAND(old_value)
    DATA.warband_commander_from_warband[value] = warband_commander_id
end


local fat_warband_commander_id_metatable = {
    __index = function (t,k)
        if (k == "commander") then return DATA.warband_commander_get_commander(t.id) end
        if (k == "warband") then return DATA.warband_commander_get_warband(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id warband_commander_id
---@return fat_warband_commander_id fat_id
function DATA.fatten_warband_commander(id)
    local result = {id = id}
    setmetatable(result, fat_warband_commander_id_metatable)    return result
end
----------warband_location----------


---warband_location: LSP types---

---Unique identificator for warband_location entity
---@alias warband_location_id number

---@class fat_warband_location_id
---@field id warband_location_id Unique warband_location id
---@field location province_id location of warband
---@field warband warband_id

---@class struct_warband_location
---@field location province_id location of warband
---@field warband warband_id


ffi.cdef[[
    typedef struct {
        uint32_t location;
        uint32_t warband;
    } warband_location;
]]

---warband_location: FFI arrays---
---@type nil
DATA.warband_location_malloc = ffi.C.malloc(ffi.sizeof("warband_location") * 10001)
---@type table<warband_location_id, struct_warband_location>
DATA.warband_location = ffi.cast("warband_location*", DATA.warband_location_malloc)
---@type table<province_id, warband_location_id[]>>
DATA.warband_location_from_location= {}
---@type table<warband_id, warband_location_id>
DATA.warband_location_from_warband= {}

---warband_location: LUA bindings---

DATA.warband_location_size = 10000
---@type table<warband_location_id, boolean>
local warband_location_indices_pool = ffi.new("bool[?]", 10000)
for i = 1, 9999 do
    warband_location_indices_pool[i] = true
end
---@type table<warband_location_id, warband_location_id>
DATA.warband_location_indices_set = {}
function DATA.create_warband_location()
    for i = 1, 9999 do
        if warband_location_indices_pool[i] then
            warband_location_indices_pool[i] = false
            DATA.warband_location_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for warband_location")
end
function DATA.delete_warband_location(i)
    do
        local old_value = DATA.warband_location[i].location
        __REMOVE_KEY_WARBAND_LOCATION_LOCATION(i, old_value)
    end
    do
        local old_value = DATA.warband_location[i].warband
        __REMOVE_KEY_WARBAND_LOCATION_WARBAND(old_value)
    end
    warband_location_indices_pool[i] = true
    DATA.warband_location_indices_set[i] = nil
end
---@param func fun(item: warband_location_id)
function DATA.for_each_warband_location(func)
    for _, item in pairs(DATA.warband_location_indices_set) do
        func(item)
    end
end

---@param warband_location_id warband_location_id valid warband_location id
---@return province_id location location of warband
function DATA.warband_location_get_location(warband_location_id)
    return DATA.warband_location[warband_location_id].location
end
---@param location province_id valid province_id
---@return warband_location_id[] An array of warband_location
function DATA.get_warband_location_from_location(location)
    return DATA.warband_location_from_location[location]
end
---@param warband_location_id warband_location_id valid warband_location id
---@param old_value province_id valid province_id
function __REMOVE_KEY_WARBAND_LOCATION_LOCATION(warband_location_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.warband_location_from_location[old_value]) do
        if value == warband_location_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.warband_location_from_location[old_value], found_key)
    end
end
---@param warband_location_id warband_location_id valid warband_location id
---@param value province_id valid province_id
function DATA.warband_location_set_location(warband_location_id, value)
    local old_value = DATA.warband_location[warband_location_id].location
    DATA.warband_location[warband_location_id].location = value
    __REMOVE_KEY_WARBAND_LOCATION_LOCATION(warband_location_id, old_value)
    table.insert(DATA.warband_location_from_location[value], warband_location_id)
end
---@param warband_location_id warband_location_id valid warband_location id
---@return warband_id warband
function DATA.warband_location_get_warband(warband_location_id)
    return DATA.warband_location[warband_location_id].warband
end
---@param warband warband_id valid warband_id
---@return warband_location_id warband_location
function DATA.get_warband_location_from_warband(warband)
    return DATA.warband_location_from_warband[warband]
end
function __REMOVE_KEY_WARBAND_LOCATION_WARBAND(old_value)
    DATA.warband_location_from_warband[old_value] = nil
end
---@param warband_location_id warband_location_id valid warband_location id
---@param value warband_id valid warband_id
function DATA.warband_location_set_warband(warband_location_id, value)
    local old_value = DATA.warband_location[warband_location_id].warband
    DATA.warband_location[warband_location_id].warband = value
    __REMOVE_KEY_WARBAND_LOCATION_WARBAND(old_value)
    DATA.warband_location_from_warband[value] = warband_location_id
end


local fat_warband_location_id_metatable = {
    __index = function (t,k)
        if (k == "location") then return DATA.warband_location_get_location(t.id) end
        if (k == "warband") then return DATA.warband_location_get_warband(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id warband_location_id
---@return fat_warband_location_id fat_id
function DATA.fatten_warband_location(id)
    local result = {id = id}
    setmetatable(result, fat_warband_location_id_metatable)    return result
end
----------warband_unit----------


---warband_unit: LSP types---

---Unique identificator for warband_unit entity
---@alias warband_unit_id number

---@class fat_warband_unit_id
---@field id warband_unit_id Unique warband_unit id
---@field type unit_type_id Current unit type
---@field unit pop_id
---@field warband warband_id

---@class struct_warband_unit
---@field type unit_type_id Current unit type
---@field unit pop_id
---@field warband warband_id


ffi.cdef[[
    typedef struct {
        uint32_t type;
        uint32_t unit;
        uint32_t warband;
    } warband_unit;
]]

---warband_unit: FFI arrays---
---@type nil
DATA.warband_unit_malloc = ffi.C.malloc(ffi.sizeof("warband_unit") * 50001)
---@type table<warband_unit_id, struct_warband_unit>
DATA.warband_unit = ffi.cast("warband_unit*", DATA.warband_unit_malloc)
---@type table<pop_id, warband_unit_id>
DATA.warband_unit_from_unit= {}
---@type table<warband_id, warband_unit_id[]>>
DATA.warband_unit_from_warband= {}

---warband_unit: LUA bindings---

DATA.warband_unit_size = 50000
---@type table<warband_unit_id, boolean>
local warband_unit_indices_pool = ffi.new("bool[?]", 50000)
for i = 1, 49999 do
    warband_unit_indices_pool[i] = true
end
---@type table<warband_unit_id, warband_unit_id>
DATA.warband_unit_indices_set = {}
function DATA.create_warband_unit()
    for i = 1, 49999 do
        if warband_unit_indices_pool[i] then
            warband_unit_indices_pool[i] = false
            DATA.warband_unit_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for warband_unit")
end
function DATA.delete_warband_unit(i)
    do
        local old_value = DATA.warband_unit[i].unit
        __REMOVE_KEY_WARBAND_UNIT_UNIT(old_value)
    end
    do
        local old_value = DATA.warband_unit[i].warband
        __REMOVE_KEY_WARBAND_UNIT_WARBAND(i, old_value)
    end
    warband_unit_indices_pool[i] = true
    DATA.warband_unit_indices_set[i] = nil
end
---@param func fun(item: warband_unit_id)
function DATA.for_each_warband_unit(func)
    for _, item in pairs(DATA.warband_unit_indices_set) do
        func(item)
    end
end

---@param warband_unit_id warband_unit_id valid warband_unit id
---@return unit_type_id type Current unit type
function DATA.warband_unit_get_type(warband_unit_id)
    return DATA.warband_unit[warband_unit_id].type
end
---@param warband_unit_id warband_unit_id valid warband_unit id
---@param value unit_type_id valid unit_type_id
function DATA.warband_unit_set_type(warband_unit_id, value)
    DATA.warband_unit[warband_unit_id].type = value
end
---@param warband_unit_id warband_unit_id valid warband_unit id
---@return pop_id unit
function DATA.warband_unit_get_unit(warband_unit_id)
    return DATA.warband_unit[warband_unit_id].unit
end
---@param unit pop_id valid pop_id
---@return warband_unit_id warband_unit
function DATA.get_warband_unit_from_unit(unit)
    return DATA.warband_unit_from_unit[unit]
end
function __REMOVE_KEY_WARBAND_UNIT_UNIT(old_value)
    DATA.warband_unit_from_unit[old_value] = nil
end
---@param warband_unit_id warband_unit_id valid warband_unit id
---@param value pop_id valid pop_id
function DATA.warband_unit_set_unit(warband_unit_id, value)
    local old_value = DATA.warband_unit[warband_unit_id].unit
    DATA.warband_unit[warband_unit_id].unit = value
    __REMOVE_KEY_WARBAND_UNIT_UNIT(old_value)
    DATA.warband_unit_from_unit[value] = warband_unit_id
end
---@param warband_unit_id warband_unit_id valid warband_unit id
---@return warband_id warband
function DATA.warband_unit_get_warband(warband_unit_id)
    return DATA.warband_unit[warband_unit_id].warband
end
---@param warband warband_id valid warband_id
---@return warband_unit_id[] An array of warband_unit
function DATA.get_warband_unit_from_warband(warband)
    return DATA.warband_unit_from_warband[warband]
end
---@param warband_unit_id warband_unit_id valid warband_unit id
---@param old_value warband_id valid warband_id
function __REMOVE_KEY_WARBAND_UNIT_WARBAND(warband_unit_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.warband_unit_from_warband[old_value]) do
        if value == warband_unit_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.warband_unit_from_warband[old_value], found_key)
    end
end
---@param warband_unit_id warband_unit_id valid warband_unit id
---@param value warband_id valid warband_id
function DATA.warband_unit_set_warband(warband_unit_id, value)
    local old_value = DATA.warband_unit[warband_unit_id].warband
    DATA.warband_unit[warband_unit_id].warband = value
    __REMOVE_KEY_WARBAND_UNIT_WARBAND(warband_unit_id, old_value)
    table.insert(DATA.warband_unit_from_warband[value], warband_unit_id)
end


local fat_warband_unit_id_metatable = {
    __index = function (t,k)
        if (k == "type") then return DATA.warband_unit_get_type(t.id) end
        if (k == "unit") then return DATA.warband_unit_get_unit(t.id) end
        if (k == "warband") then return DATA.warband_unit_get_warband(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "type") then
            DATA.warband_unit_set_type(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id warband_unit_id
---@return fat_warband_unit_id fat_id
function DATA.fatten_warband_unit(id)
    local result = {id = id}
    setmetatable(result, fat_warband_unit_id_metatable)    return result
end
----------character_location----------


---character_location: LSP types---

---Unique identificator for character_location entity
---@alias character_location_id number

---@class fat_character_location_id
---@field id character_location_id Unique character_location id
---@field location province_id location of character
---@field character pop_id

---@class struct_character_location
---@field location province_id location of character
---@field character pop_id


ffi.cdef[[
    typedef struct {
        uint32_t location;
        uint32_t character;
    } character_location;
]]

---character_location: FFI arrays---
---@type nil
DATA.character_location_malloc = ffi.C.malloc(ffi.sizeof("character_location") * 100001)
---@type table<character_location_id, struct_character_location>
DATA.character_location = ffi.cast("character_location*", DATA.character_location_malloc)
---@type table<province_id, character_location_id[]>>
DATA.character_location_from_location= {}
---@type table<pop_id, character_location_id>
DATA.character_location_from_character= {}

---character_location: LUA bindings---

DATA.character_location_size = 100000
---@type table<character_location_id, boolean>
local character_location_indices_pool = ffi.new("bool[?]", 100000)
for i = 1, 99999 do
    character_location_indices_pool[i] = true
end
---@type table<character_location_id, character_location_id>
DATA.character_location_indices_set = {}
function DATA.create_character_location()
    for i = 1, 99999 do
        if character_location_indices_pool[i] then
            character_location_indices_pool[i] = false
            DATA.character_location_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for character_location")
end
function DATA.delete_character_location(i)
    do
        local old_value = DATA.character_location[i].location
        __REMOVE_KEY_CHARACTER_LOCATION_LOCATION(i, old_value)
    end
    do
        local old_value = DATA.character_location[i].character
        __REMOVE_KEY_CHARACTER_LOCATION_CHARACTER(old_value)
    end
    character_location_indices_pool[i] = true
    DATA.character_location_indices_set[i] = nil
end
---@param func fun(item: character_location_id)
function DATA.for_each_character_location(func)
    for _, item in pairs(DATA.character_location_indices_set) do
        func(item)
    end
end

---@param character_location_id character_location_id valid character_location id
---@return province_id location location of character
function DATA.character_location_get_location(character_location_id)
    return DATA.character_location[character_location_id].location
end
---@param location province_id valid province_id
---@return character_location_id[] An array of character_location
function DATA.get_character_location_from_location(location)
    return DATA.character_location_from_location[location]
end
---@param character_location_id character_location_id valid character_location id
---@param old_value province_id valid province_id
function __REMOVE_KEY_CHARACTER_LOCATION_LOCATION(character_location_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.character_location_from_location[old_value]) do
        if value == character_location_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.character_location_from_location[old_value], found_key)
    end
end
---@param character_location_id character_location_id valid character_location id
---@param value province_id valid province_id
function DATA.character_location_set_location(character_location_id, value)
    local old_value = DATA.character_location[character_location_id].location
    DATA.character_location[character_location_id].location = value
    __REMOVE_KEY_CHARACTER_LOCATION_LOCATION(character_location_id, old_value)
    table.insert(DATA.character_location_from_location[value], character_location_id)
end
---@param character_location_id character_location_id valid character_location id
---@return pop_id character
function DATA.character_location_get_character(character_location_id)
    return DATA.character_location[character_location_id].character
end
---@param character pop_id valid pop_id
---@return character_location_id character_location
function DATA.get_character_location_from_character(character)
    return DATA.character_location_from_character[character]
end
function __REMOVE_KEY_CHARACTER_LOCATION_CHARACTER(old_value)
    DATA.character_location_from_character[old_value] = nil
end
---@param character_location_id character_location_id valid character_location id
---@param value pop_id valid pop_id
function DATA.character_location_set_character(character_location_id, value)
    local old_value = DATA.character_location[character_location_id].character
    DATA.character_location[character_location_id].character = value
    __REMOVE_KEY_CHARACTER_LOCATION_CHARACTER(old_value)
    DATA.character_location_from_character[value] = character_location_id
end


local fat_character_location_id_metatable = {
    __index = function (t,k)
        if (k == "location") then return DATA.character_location_get_location(t.id) end
        if (k == "character") then return DATA.character_location_get_character(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id character_location_id
---@return fat_character_location_id fat_id
function DATA.fatten_character_location(id)
    local result = {id = id}
    setmetatable(result, fat_character_location_id_metatable)    return result
end
----------home----------


---home: LSP types---

---Unique identificator for home entity
---@alias home_id number

---@class fat_home_id
---@field id home_id Unique home id
---@field home province_id home of pop
---@field pop pop_id characters and pops which think of this province as their home

---@class struct_home
---@field home province_id home of pop
---@field pop pop_id characters and pops which think of this province as their home


ffi.cdef[[
    typedef struct {
        uint32_t home;
        uint32_t pop;
    } home;
]]

---home: FFI arrays---
---@type nil
DATA.home_malloc = ffi.C.malloc(ffi.sizeof("home") * 300001)
---@type table<home_id, struct_home>
DATA.home = ffi.cast("home*", DATA.home_malloc)
---@type table<province_id, home_id[]>>
DATA.home_from_home= {}
---@type table<pop_id, home_id>
DATA.home_from_pop= {}

---home: LUA bindings---

DATA.home_size = 300000
---@type table<home_id, boolean>
local home_indices_pool = ffi.new("bool[?]", 300000)
for i = 1, 299999 do
    home_indices_pool[i] = true
end
---@type table<home_id, home_id>
DATA.home_indices_set = {}
function DATA.create_home()
    for i = 1, 299999 do
        if home_indices_pool[i] then
            home_indices_pool[i] = false
            DATA.home_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for home")
end
function DATA.delete_home(i)
    do
        local old_value = DATA.home[i].home
        __REMOVE_KEY_HOME_HOME(i, old_value)
    end
    do
        local old_value = DATA.home[i].pop
        __REMOVE_KEY_HOME_POP(old_value)
    end
    home_indices_pool[i] = true
    DATA.home_indices_set[i] = nil
end
---@param func fun(item: home_id)
function DATA.for_each_home(func)
    for _, item in pairs(DATA.home_indices_set) do
        func(item)
    end
end

---@param home_id home_id valid home id
---@return province_id home home of pop
function DATA.home_get_home(home_id)
    return DATA.home[home_id].home
end
---@param home province_id valid province_id
---@return home_id[] An array of home
function DATA.get_home_from_home(home)
    return DATA.home_from_home[home]
end
---@param home_id home_id valid home id
---@param old_value province_id valid province_id
function __REMOVE_KEY_HOME_HOME(home_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.home_from_home[old_value]) do
        if value == home_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.home_from_home[old_value], found_key)
    end
end
---@param home_id home_id valid home id
---@param value province_id valid province_id
function DATA.home_set_home(home_id, value)
    local old_value = DATA.home[home_id].home
    DATA.home[home_id].home = value
    __REMOVE_KEY_HOME_HOME(home_id, old_value)
    table.insert(DATA.home_from_home[value], home_id)
end
---@param home_id home_id valid home id
---@return pop_id pop characters and pops which think of this province as their home
function DATA.home_get_pop(home_id)
    return DATA.home[home_id].pop
end
---@param pop pop_id valid pop_id
---@return home_id home
function DATA.get_home_from_pop(pop)
    return DATA.home_from_pop[pop]
end
function __REMOVE_KEY_HOME_POP(old_value)
    DATA.home_from_pop[old_value] = nil
end
---@param home_id home_id valid home id
---@param value pop_id valid pop_id
function DATA.home_set_pop(home_id, value)
    local old_value = DATA.home[home_id].pop
    DATA.home[home_id].pop = value
    __REMOVE_KEY_HOME_POP(old_value)
    DATA.home_from_pop[value] = home_id
end


local fat_home_id_metatable = {
    __index = function (t,k)
        if (k == "home") then return DATA.home_get_home(t.id) end
        if (k == "pop") then return DATA.home_get_pop(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id home_id
---@return fat_home_id fat_id
function DATA.fatten_home(id)
    local result = {id = id}
    setmetatable(result, fat_home_id_metatable)    return result
end
----------pop_location----------


---pop_location: LSP types---

---Unique identificator for pop_location entity
---@alias pop_location_id number

---@class fat_pop_location_id
---@field id pop_location_id Unique pop_location id
---@field location province_id location of pop
---@field pop pop_id

---@class struct_pop_location
---@field location province_id location of pop
---@field pop pop_id


ffi.cdef[[
    typedef struct {
        uint32_t location;
        uint32_t pop;
    } pop_location;
]]

---pop_location: FFI arrays---
---@type nil
DATA.pop_location_malloc = ffi.C.malloc(ffi.sizeof("pop_location") * 300001)
---@type table<pop_location_id, struct_pop_location>
DATA.pop_location = ffi.cast("pop_location*", DATA.pop_location_malloc)
---@type table<province_id, pop_location_id[]>>
DATA.pop_location_from_location= {}
---@type table<pop_id, pop_location_id>
DATA.pop_location_from_pop= {}

---pop_location: LUA bindings---

DATA.pop_location_size = 300000
---@type table<pop_location_id, boolean>
local pop_location_indices_pool = ffi.new("bool[?]", 300000)
for i = 1, 299999 do
    pop_location_indices_pool[i] = true
end
---@type table<pop_location_id, pop_location_id>
DATA.pop_location_indices_set = {}
function DATA.create_pop_location()
    for i = 1, 299999 do
        if pop_location_indices_pool[i] then
            pop_location_indices_pool[i] = false
            DATA.pop_location_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for pop_location")
end
function DATA.delete_pop_location(i)
    do
        local old_value = DATA.pop_location[i].location
        __REMOVE_KEY_POP_LOCATION_LOCATION(i, old_value)
    end
    do
        local old_value = DATA.pop_location[i].pop
        __REMOVE_KEY_POP_LOCATION_POP(old_value)
    end
    pop_location_indices_pool[i] = true
    DATA.pop_location_indices_set[i] = nil
end
---@param func fun(item: pop_location_id)
function DATA.for_each_pop_location(func)
    for _, item in pairs(DATA.pop_location_indices_set) do
        func(item)
    end
end

---@param pop_location_id pop_location_id valid pop_location id
---@return province_id location location of pop
function DATA.pop_location_get_location(pop_location_id)
    return DATA.pop_location[pop_location_id].location
end
---@param location province_id valid province_id
---@return pop_location_id[] An array of pop_location
function DATA.get_pop_location_from_location(location)
    return DATA.pop_location_from_location[location]
end
---@param pop_location_id pop_location_id valid pop_location id
---@param old_value province_id valid province_id
function __REMOVE_KEY_POP_LOCATION_LOCATION(pop_location_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.pop_location_from_location[old_value]) do
        if value == pop_location_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.pop_location_from_location[old_value], found_key)
    end
end
---@param pop_location_id pop_location_id valid pop_location id
---@param value province_id valid province_id
function DATA.pop_location_set_location(pop_location_id, value)
    local old_value = DATA.pop_location[pop_location_id].location
    DATA.pop_location[pop_location_id].location = value
    __REMOVE_KEY_POP_LOCATION_LOCATION(pop_location_id, old_value)
    table.insert(DATA.pop_location_from_location[value], pop_location_id)
end
---@param pop_location_id pop_location_id valid pop_location id
---@return pop_id pop
function DATA.pop_location_get_pop(pop_location_id)
    return DATA.pop_location[pop_location_id].pop
end
---@param pop pop_id valid pop_id
---@return pop_location_id pop_location
function DATA.get_pop_location_from_pop(pop)
    return DATA.pop_location_from_pop[pop]
end
function __REMOVE_KEY_POP_LOCATION_POP(old_value)
    DATA.pop_location_from_pop[old_value] = nil
end
---@param pop_location_id pop_location_id valid pop_location id
---@param value pop_id valid pop_id
function DATA.pop_location_set_pop(pop_location_id, value)
    local old_value = DATA.pop_location[pop_location_id].pop
    DATA.pop_location[pop_location_id].pop = value
    __REMOVE_KEY_POP_LOCATION_POP(old_value)
    DATA.pop_location_from_pop[value] = pop_location_id
end


local fat_pop_location_id_metatable = {
    __index = function (t,k)
        if (k == "location") then return DATA.pop_location_get_location(t.id) end
        if (k == "pop") then return DATA.pop_location_get_pop(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id pop_location_id
---@return fat_pop_location_id fat_id
function DATA.fatten_pop_location(id)
    local result = {id = id}
    setmetatable(result, fat_pop_location_id_metatable)    return result
end
----------outlaw_location----------


---outlaw_location: LSP types---

---Unique identificator for outlaw_location entity
---@alias outlaw_location_id number

---@class fat_outlaw_location_id
---@field id outlaw_location_id Unique outlaw_location id
---@field location province_id location of the outlaw
---@field outlaw pop_id

---@class struct_outlaw_location
---@field location province_id location of the outlaw
---@field outlaw pop_id


ffi.cdef[[
    typedef struct {
        uint32_t location;
        uint32_t outlaw;
    } outlaw_location;
]]

---outlaw_location: FFI arrays---
---@type nil
DATA.outlaw_location_malloc = ffi.C.malloc(ffi.sizeof("outlaw_location") * 300001)
---@type table<outlaw_location_id, struct_outlaw_location>
DATA.outlaw_location = ffi.cast("outlaw_location*", DATA.outlaw_location_malloc)
---@type table<province_id, outlaw_location_id[]>>
DATA.outlaw_location_from_location= {}
---@type table<pop_id, outlaw_location_id>
DATA.outlaw_location_from_outlaw= {}

---outlaw_location: LUA bindings---

DATA.outlaw_location_size = 300000
---@type table<outlaw_location_id, boolean>
local outlaw_location_indices_pool = ffi.new("bool[?]", 300000)
for i = 1, 299999 do
    outlaw_location_indices_pool[i] = true
end
---@type table<outlaw_location_id, outlaw_location_id>
DATA.outlaw_location_indices_set = {}
function DATA.create_outlaw_location()
    for i = 1, 299999 do
        if outlaw_location_indices_pool[i] then
            outlaw_location_indices_pool[i] = false
            DATA.outlaw_location_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for outlaw_location")
end
function DATA.delete_outlaw_location(i)
    do
        local old_value = DATA.outlaw_location[i].location
        __REMOVE_KEY_OUTLAW_LOCATION_LOCATION(i, old_value)
    end
    do
        local old_value = DATA.outlaw_location[i].outlaw
        __REMOVE_KEY_OUTLAW_LOCATION_OUTLAW(old_value)
    end
    outlaw_location_indices_pool[i] = true
    DATA.outlaw_location_indices_set[i] = nil
end
---@param func fun(item: outlaw_location_id)
function DATA.for_each_outlaw_location(func)
    for _, item in pairs(DATA.outlaw_location_indices_set) do
        func(item)
    end
end

---@param outlaw_location_id outlaw_location_id valid outlaw_location id
---@return province_id location location of the outlaw
function DATA.outlaw_location_get_location(outlaw_location_id)
    return DATA.outlaw_location[outlaw_location_id].location
end
---@param location province_id valid province_id
---@return outlaw_location_id[] An array of outlaw_location
function DATA.get_outlaw_location_from_location(location)
    return DATA.outlaw_location_from_location[location]
end
---@param outlaw_location_id outlaw_location_id valid outlaw_location id
---@param old_value province_id valid province_id
function __REMOVE_KEY_OUTLAW_LOCATION_LOCATION(outlaw_location_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.outlaw_location_from_location[old_value]) do
        if value == outlaw_location_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.outlaw_location_from_location[old_value], found_key)
    end
end
---@param outlaw_location_id outlaw_location_id valid outlaw_location id
---@param value province_id valid province_id
function DATA.outlaw_location_set_location(outlaw_location_id, value)
    local old_value = DATA.outlaw_location[outlaw_location_id].location
    DATA.outlaw_location[outlaw_location_id].location = value
    __REMOVE_KEY_OUTLAW_LOCATION_LOCATION(outlaw_location_id, old_value)
    table.insert(DATA.outlaw_location_from_location[value], outlaw_location_id)
end
---@param outlaw_location_id outlaw_location_id valid outlaw_location id
---@return pop_id outlaw
function DATA.outlaw_location_get_outlaw(outlaw_location_id)
    return DATA.outlaw_location[outlaw_location_id].outlaw
end
---@param outlaw pop_id valid pop_id
---@return outlaw_location_id outlaw_location
function DATA.get_outlaw_location_from_outlaw(outlaw)
    return DATA.outlaw_location_from_outlaw[outlaw]
end
function __REMOVE_KEY_OUTLAW_LOCATION_OUTLAW(old_value)
    DATA.outlaw_location_from_outlaw[old_value] = nil
end
---@param outlaw_location_id outlaw_location_id valid outlaw_location id
---@param value pop_id valid pop_id
function DATA.outlaw_location_set_outlaw(outlaw_location_id, value)
    local old_value = DATA.outlaw_location[outlaw_location_id].outlaw
    DATA.outlaw_location[outlaw_location_id].outlaw = value
    __REMOVE_KEY_OUTLAW_LOCATION_OUTLAW(old_value)
    DATA.outlaw_location_from_outlaw[value] = outlaw_location_id
end


local fat_outlaw_location_id_metatable = {
    __index = function (t,k)
        if (k == "location") then return DATA.outlaw_location_get_location(t.id) end
        if (k == "outlaw") then return DATA.outlaw_location_get_outlaw(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id outlaw_location_id
---@return fat_outlaw_location_id fat_id
function DATA.fatten_outlaw_location(id)
    local result = {id = id}
    setmetatable(result, fat_outlaw_location_id_metatable)    return result
end
----------tile_province_membership----------


---tile_province_membership: LSP types---

---Unique identificator for tile_province_membership entity
---@alias tile_province_membership_id number

---@class fat_tile_province_membership_id
---@field id tile_province_membership_id Unique tile_province_membership id
---@field province province_id
---@field tile tile_id

---@class struct_tile_province_membership
---@field province province_id
---@field tile tile_id


ffi.cdef[[
    typedef struct {
        uint32_t province;
        uint32_t tile;
    } tile_province_membership;
]]

---tile_province_membership: FFI arrays---
---@type nil
DATA.tile_province_membership_malloc = ffi.C.malloc(ffi.sizeof("tile_province_membership") * 1500001)
---@type table<tile_province_membership_id, struct_tile_province_membership>
DATA.tile_province_membership = ffi.cast("tile_province_membership*", DATA.tile_province_membership_malloc)
---@type table<province_id, tile_province_membership_id[]>>
DATA.tile_province_membership_from_province= {}
---@type table<tile_id, tile_province_membership_id>
DATA.tile_province_membership_from_tile= {}

---tile_province_membership: LUA bindings---

DATA.tile_province_membership_size = 1500000
---@type table<tile_province_membership_id, boolean>
local tile_province_membership_indices_pool = ffi.new("bool[?]", 1500000)
for i = 1, 1499999 do
    tile_province_membership_indices_pool[i] = true
end
---@type table<tile_province_membership_id, tile_province_membership_id>
DATA.tile_province_membership_indices_set = {}
function DATA.create_tile_province_membership()
    for i = 1, 1499999 do
        if tile_province_membership_indices_pool[i] then
            tile_province_membership_indices_pool[i] = false
            DATA.tile_province_membership_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for tile_province_membership")
end
function DATA.delete_tile_province_membership(i)
    do
        local old_value = DATA.tile_province_membership[i].province
        __REMOVE_KEY_TILE_PROVINCE_MEMBERSHIP_PROVINCE(i, old_value)
    end
    do
        local old_value = DATA.tile_province_membership[i].tile
        __REMOVE_KEY_TILE_PROVINCE_MEMBERSHIP_TILE(old_value)
    end
    tile_province_membership_indices_pool[i] = true
    DATA.tile_province_membership_indices_set[i] = nil
end
---@param func fun(item: tile_province_membership_id)
function DATA.for_each_tile_province_membership(func)
    for _, item in pairs(DATA.tile_province_membership_indices_set) do
        func(item)
    end
end

---@param tile_province_membership_id tile_province_membership_id valid tile_province_membership id
---@return province_id province
function DATA.tile_province_membership_get_province(tile_province_membership_id)
    return DATA.tile_province_membership[tile_province_membership_id].province
end
---@param province province_id valid province_id
---@return tile_province_membership_id[] An array of tile_province_membership
function DATA.get_tile_province_membership_from_province(province)
    return DATA.tile_province_membership_from_province[province]
end
---@param tile_province_membership_id tile_province_membership_id valid tile_province_membership id
---@param old_value province_id valid province_id
function __REMOVE_KEY_TILE_PROVINCE_MEMBERSHIP_PROVINCE(tile_province_membership_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.tile_province_membership_from_province[old_value]) do
        if value == tile_province_membership_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.tile_province_membership_from_province[old_value], found_key)
    end
end
---@param tile_province_membership_id tile_province_membership_id valid tile_province_membership id
---@param value province_id valid province_id
function DATA.tile_province_membership_set_province(tile_province_membership_id, value)
    local old_value = DATA.tile_province_membership[tile_province_membership_id].province
    DATA.tile_province_membership[tile_province_membership_id].province = value
    __REMOVE_KEY_TILE_PROVINCE_MEMBERSHIP_PROVINCE(tile_province_membership_id, old_value)
    table.insert(DATA.tile_province_membership_from_province[value], tile_province_membership_id)
end
---@param tile_province_membership_id tile_province_membership_id valid tile_province_membership id
---@return tile_id tile
function DATA.tile_province_membership_get_tile(tile_province_membership_id)
    return DATA.tile_province_membership[tile_province_membership_id].tile
end
---@param tile tile_id valid tile_id
---@return tile_province_membership_id tile_province_membership
function DATA.get_tile_province_membership_from_tile(tile)
    return DATA.tile_province_membership_from_tile[tile]
end
function __REMOVE_KEY_TILE_PROVINCE_MEMBERSHIP_TILE(old_value)
    DATA.tile_province_membership_from_tile[old_value] = nil
end
---@param tile_province_membership_id tile_province_membership_id valid tile_province_membership id
---@param value tile_id valid tile_id
function DATA.tile_province_membership_set_tile(tile_province_membership_id, value)
    local old_value = DATA.tile_province_membership[tile_province_membership_id].tile
    DATA.tile_province_membership[tile_province_membership_id].tile = value
    __REMOVE_KEY_TILE_PROVINCE_MEMBERSHIP_TILE(old_value)
    DATA.tile_province_membership_from_tile[value] = tile_province_membership_id
end


local fat_tile_province_membership_id_metatable = {
    __index = function (t,k)
        if (k == "province") then return DATA.tile_province_membership_get_province(t.id) end
        if (k == "tile") then return DATA.tile_province_membership_get_tile(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id tile_province_membership_id
---@return fat_tile_province_membership_id fat_id
function DATA.fatten_tile_province_membership(id)
    local result = {id = id}
    setmetatable(result, fat_tile_province_membership_id_metatable)    return result
end
----------province_neighborhood----------


---province_neighborhood: LSP types---

---Unique identificator for province_neighborhood entity
---@alias province_neighborhood_id number

---@class fat_province_neighborhood_id
---@field id province_neighborhood_id Unique province_neighborhood id
---@field origin province_id
---@field target province_id

---@class struct_province_neighborhood
---@field origin province_id
---@field target province_id


ffi.cdef[[
    typedef struct {
        uint32_t origin;
        uint32_t target;
    } province_neighborhood;
]]

---province_neighborhood: FFI arrays---
---@type nil
DATA.province_neighborhood_malloc = ffi.C.malloc(ffi.sizeof("province_neighborhood") * 100001)
---@type table<province_neighborhood_id, struct_province_neighborhood>
DATA.province_neighborhood = ffi.cast("province_neighborhood*", DATA.province_neighborhood_malloc)
---@type table<province_id, province_neighborhood_id[]>>
DATA.province_neighborhood_from_origin= {}
---@type table<province_id, province_neighborhood_id[]>>
DATA.province_neighborhood_from_target= {}

---province_neighborhood: LUA bindings---

DATA.province_neighborhood_size = 100000
---@type table<province_neighborhood_id, boolean>
local province_neighborhood_indices_pool = ffi.new("bool[?]", 100000)
for i = 1, 99999 do
    province_neighborhood_indices_pool[i] = true
end
---@type table<province_neighborhood_id, province_neighborhood_id>
DATA.province_neighborhood_indices_set = {}
function DATA.create_province_neighborhood()
    for i = 1, 99999 do
        if province_neighborhood_indices_pool[i] then
            province_neighborhood_indices_pool[i] = false
            DATA.province_neighborhood_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for province_neighborhood")
end
function DATA.delete_province_neighborhood(i)
    do
        local old_value = DATA.province_neighborhood[i].origin
        __REMOVE_KEY_PROVINCE_NEIGHBORHOOD_ORIGIN(i, old_value)
    end
    do
        local old_value = DATA.province_neighborhood[i].target
        __REMOVE_KEY_PROVINCE_NEIGHBORHOOD_TARGET(i, old_value)
    end
    province_neighborhood_indices_pool[i] = true
    DATA.province_neighborhood_indices_set[i] = nil
end
---@param func fun(item: province_neighborhood_id)
function DATA.for_each_province_neighborhood(func)
    for _, item in pairs(DATA.province_neighborhood_indices_set) do
        func(item)
    end
end

---@param province_neighborhood_id province_neighborhood_id valid province_neighborhood id
---@return province_id origin
function DATA.province_neighborhood_get_origin(province_neighborhood_id)
    return DATA.province_neighborhood[province_neighborhood_id].origin
end
---@param origin province_id valid province_id
---@return province_neighborhood_id[] An array of province_neighborhood
function DATA.get_province_neighborhood_from_origin(origin)
    return DATA.province_neighborhood_from_origin[origin]
end
---@param province_neighborhood_id province_neighborhood_id valid province_neighborhood id
---@param old_value province_id valid province_id
function __REMOVE_KEY_PROVINCE_NEIGHBORHOOD_ORIGIN(province_neighborhood_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.province_neighborhood_from_origin[old_value]) do
        if value == province_neighborhood_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.province_neighborhood_from_origin[old_value], found_key)
    end
end
---@param province_neighborhood_id province_neighborhood_id valid province_neighborhood id
---@param value province_id valid province_id
function DATA.province_neighborhood_set_origin(province_neighborhood_id, value)
    local old_value = DATA.province_neighborhood[province_neighborhood_id].origin
    DATA.province_neighborhood[province_neighborhood_id].origin = value
    __REMOVE_KEY_PROVINCE_NEIGHBORHOOD_ORIGIN(province_neighborhood_id, old_value)
    table.insert(DATA.province_neighborhood_from_origin[value], province_neighborhood_id)
end
---@param province_neighborhood_id province_neighborhood_id valid province_neighborhood id
---@return province_id target
function DATA.province_neighborhood_get_target(province_neighborhood_id)
    return DATA.province_neighborhood[province_neighborhood_id].target
end
---@param target province_id valid province_id
---@return province_neighborhood_id[] An array of province_neighborhood
function DATA.get_province_neighborhood_from_target(target)
    return DATA.province_neighborhood_from_target[target]
end
---@param province_neighborhood_id province_neighborhood_id valid province_neighborhood id
---@param old_value province_id valid province_id
function __REMOVE_KEY_PROVINCE_NEIGHBORHOOD_TARGET(province_neighborhood_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.province_neighborhood_from_target[old_value]) do
        if value == province_neighborhood_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.province_neighborhood_from_target[old_value], found_key)
    end
end
---@param province_neighborhood_id province_neighborhood_id valid province_neighborhood id
---@param value province_id valid province_id
function DATA.province_neighborhood_set_target(province_neighborhood_id, value)
    local old_value = DATA.province_neighborhood[province_neighborhood_id].target
    DATA.province_neighborhood[province_neighborhood_id].target = value
    __REMOVE_KEY_PROVINCE_NEIGHBORHOOD_TARGET(province_neighborhood_id, old_value)
    table.insert(DATA.province_neighborhood_from_target[value], province_neighborhood_id)
end


local fat_province_neighborhood_id_metatable = {
    __index = function (t,k)
        if (k == "origin") then return DATA.province_neighborhood_get_origin(t.id) end
        if (k == "target") then return DATA.province_neighborhood_get_target(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id province_neighborhood_id
---@return fat_province_neighborhood_id fat_id
function DATA.fatten_province_neighborhood(id)
    local result = {id = id}
    setmetatable(result, fat_province_neighborhood_id_metatable)    return result
end
----------parent_child_relation----------


---parent_child_relation: LSP types---

---Unique identificator for parent_child_relation entity
---@alias parent_child_relation_id number

---@class fat_parent_child_relation_id
---@field id parent_child_relation_id Unique parent_child_relation id
---@field parent pop_id
---@field child pop_id

---@class struct_parent_child_relation
---@field parent pop_id
---@field child pop_id


ffi.cdef[[
    typedef struct {
        uint32_t parent;
        uint32_t child;
    } parent_child_relation;
]]

---parent_child_relation: FFI arrays---
---@type nil
DATA.parent_child_relation_malloc = ffi.C.malloc(ffi.sizeof("parent_child_relation") * 900001)
---@type table<parent_child_relation_id, struct_parent_child_relation>
DATA.parent_child_relation = ffi.cast("parent_child_relation*", DATA.parent_child_relation_malloc)
---@type table<pop_id, parent_child_relation_id[]>>
DATA.parent_child_relation_from_parent= {}
---@type table<pop_id, parent_child_relation_id>
DATA.parent_child_relation_from_child= {}

---parent_child_relation: LUA bindings---

DATA.parent_child_relation_size = 900000
---@type table<parent_child_relation_id, boolean>
local parent_child_relation_indices_pool = ffi.new("bool[?]", 900000)
for i = 1, 899999 do
    parent_child_relation_indices_pool[i] = true
end
---@type table<parent_child_relation_id, parent_child_relation_id>
DATA.parent_child_relation_indices_set = {}
function DATA.create_parent_child_relation()
    for i = 1, 899999 do
        if parent_child_relation_indices_pool[i] then
            parent_child_relation_indices_pool[i] = false
            DATA.parent_child_relation_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for parent_child_relation")
end
function DATA.delete_parent_child_relation(i)
    do
        local old_value = DATA.parent_child_relation[i].parent
        __REMOVE_KEY_PARENT_CHILD_RELATION_PARENT(i, old_value)
    end
    do
        local old_value = DATA.parent_child_relation[i].child
        __REMOVE_KEY_PARENT_CHILD_RELATION_CHILD(old_value)
    end
    parent_child_relation_indices_pool[i] = true
    DATA.parent_child_relation_indices_set[i] = nil
end
---@param func fun(item: parent_child_relation_id)
function DATA.for_each_parent_child_relation(func)
    for _, item in pairs(DATA.parent_child_relation_indices_set) do
        func(item)
    end
end

---@param parent_child_relation_id parent_child_relation_id valid parent_child_relation id
---@return pop_id parent
function DATA.parent_child_relation_get_parent(parent_child_relation_id)
    return DATA.parent_child_relation[parent_child_relation_id].parent
end
---@param parent pop_id valid pop_id
---@return parent_child_relation_id[] An array of parent_child_relation
function DATA.get_parent_child_relation_from_parent(parent)
    return DATA.parent_child_relation_from_parent[parent]
end
---@param parent_child_relation_id parent_child_relation_id valid parent_child_relation id
---@param old_value pop_id valid pop_id
function __REMOVE_KEY_PARENT_CHILD_RELATION_PARENT(parent_child_relation_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.parent_child_relation_from_parent[old_value]) do
        if value == parent_child_relation_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.parent_child_relation_from_parent[old_value], found_key)
    end
end
---@param parent_child_relation_id parent_child_relation_id valid parent_child_relation id
---@param value pop_id valid pop_id
function DATA.parent_child_relation_set_parent(parent_child_relation_id, value)
    local old_value = DATA.parent_child_relation[parent_child_relation_id].parent
    DATA.parent_child_relation[parent_child_relation_id].parent = value
    __REMOVE_KEY_PARENT_CHILD_RELATION_PARENT(parent_child_relation_id, old_value)
    table.insert(DATA.parent_child_relation_from_parent[value], parent_child_relation_id)
end
---@param parent_child_relation_id parent_child_relation_id valid parent_child_relation id
---@return pop_id child
function DATA.parent_child_relation_get_child(parent_child_relation_id)
    return DATA.parent_child_relation[parent_child_relation_id].child
end
---@param child pop_id valid pop_id
---@return parent_child_relation_id parent_child_relation
function DATA.get_parent_child_relation_from_child(child)
    return DATA.parent_child_relation_from_child[child]
end
function __REMOVE_KEY_PARENT_CHILD_RELATION_CHILD(old_value)
    DATA.parent_child_relation_from_child[old_value] = nil
end
---@param parent_child_relation_id parent_child_relation_id valid parent_child_relation id
---@param value pop_id valid pop_id
function DATA.parent_child_relation_set_child(parent_child_relation_id, value)
    local old_value = DATA.parent_child_relation[parent_child_relation_id].child
    DATA.parent_child_relation[parent_child_relation_id].child = value
    __REMOVE_KEY_PARENT_CHILD_RELATION_CHILD(old_value)
    DATA.parent_child_relation_from_child[value] = parent_child_relation_id
end


local fat_parent_child_relation_id_metatable = {
    __index = function (t,k)
        if (k == "parent") then return DATA.parent_child_relation_get_parent(t.id) end
        if (k == "child") then return DATA.parent_child_relation_get_child(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id parent_child_relation_id
---@return fat_parent_child_relation_id fat_id
function DATA.fatten_parent_child_relation(id)
    local result = {id = id}
    setmetatable(result, fat_parent_child_relation_id_metatable)    return result
end
----------loyalty----------


---loyalty: LSP types---

---Unique identificator for loyalty entity
---@alias loyalty_id number

---@class fat_loyalty_id
---@field id loyalty_id Unique loyalty id
---@field top pop_id
---@field bottom pop_id

---@class struct_loyalty
---@field top pop_id
---@field bottom pop_id


ffi.cdef[[
    typedef struct {
        uint32_t top;
        uint32_t bottom;
    } loyalty;
]]

---loyalty: FFI arrays---
---@type nil
DATA.loyalty_malloc = ffi.C.malloc(ffi.sizeof("loyalty") * 10001)
---@type table<loyalty_id, struct_loyalty>
DATA.loyalty = ffi.cast("loyalty*", DATA.loyalty_malloc)
---@type table<pop_id, loyalty_id[]>>
DATA.loyalty_from_top= {}
---@type table<pop_id, loyalty_id>
DATA.loyalty_from_bottom= {}

---loyalty: LUA bindings---

DATA.loyalty_size = 10000
---@type table<loyalty_id, boolean>
local loyalty_indices_pool = ffi.new("bool[?]", 10000)
for i = 1, 9999 do
    loyalty_indices_pool[i] = true
end
---@type table<loyalty_id, loyalty_id>
DATA.loyalty_indices_set = {}
function DATA.create_loyalty()
    for i = 1, 9999 do
        if loyalty_indices_pool[i] then
            loyalty_indices_pool[i] = false
            DATA.loyalty_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for loyalty")
end
function DATA.delete_loyalty(i)
    do
        local old_value = DATA.loyalty[i].top
        __REMOVE_KEY_LOYALTY_TOP(i, old_value)
    end
    do
        local old_value = DATA.loyalty[i].bottom
        __REMOVE_KEY_LOYALTY_BOTTOM(old_value)
    end
    loyalty_indices_pool[i] = true
    DATA.loyalty_indices_set[i] = nil
end
---@param func fun(item: loyalty_id)
function DATA.for_each_loyalty(func)
    for _, item in pairs(DATA.loyalty_indices_set) do
        func(item)
    end
end

---@param loyalty_id loyalty_id valid loyalty id
---@return pop_id top
function DATA.loyalty_get_top(loyalty_id)
    return DATA.loyalty[loyalty_id].top
end
---@param top pop_id valid pop_id
---@return loyalty_id[] An array of loyalty
function DATA.get_loyalty_from_top(top)
    return DATA.loyalty_from_top[top]
end
---@param loyalty_id loyalty_id valid loyalty id
---@param old_value pop_id valid pop_id
function __REMOVE_KEY_LOYALTY_TOP(loyalty_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.loyalty_from_top[old_value]) do
        if value == loyalty_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.loyalty_from_top[old_value], found_key)
    end
end
---@param loyalty_id loyalty_id valid loyalty id
---@param value pop_id valid pop_id
function DATA.loyalty_set_top(loyalty_id, value)
    local old_value = DATA.loyalty[loyalty_id].top
    DATA.loyalty[loyalty_id].top = value
    __REMOVE_KEY_LOYALTY_TOP(loyalty_id, old_value)
    table.insert(DATA.loyalty_from_top[value], loyalty_id)
end
---@param loyalty_id loyalty_id valid loyalty id
---@return pop_id bottom
function DATA.loyalty_get_bottom(loyalty_id)
    return DATA.loyalty[loyalty_id].bottom
end
---@param bottom pop_id valid pop_id
---@return loyalty_id loyalty
function DATA.get_loyalty_from_bottom(bottom)
    return DATA.loyalty_from_bottom[bottom]
end
function __REMOVE_KEY_LOYALTY_BOTTOM(old_value)
    DATA.loyalty_from_bottom[old_value] = nil
end
---@param loyalty_id loyalty_id valid loyalty id
---@param value pop_id valid pop_id
function DATA.loyalty_set_bottom(loyalty_id, value)
    local old_value = DATA.loyalty[loyalty_id].bottom
    DATA.loyalty[loyalty_id].bottom = value
    __REMOVE_KEY_LOYALTY_BOTTOM(old_value)
    DATA.loyalty_from_bottom[value] = loyalty_id
end


local fat_loyalty_id_metatable = {
    __index = function (t,k)
        if (k == "top") then return DATA.loyalty_get_top(t.id) end
        if (k == "bottom") then return DATA.loyalty_get_bottom(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id loyalty_id
---@return fat_loyalty_id fat_id
function DATA.fatten_loyalty(id)
    local result = {id = id}
    setmetatable(result, fat_loyalty_id_metatable)    return result
end
----------succession----------


---succession: LSP types---

---Unique identificator for succession entity
---@alias succession_id number

---@class fat_succession_id
---@field id succession_id Unique succession id
---@field successor_of pop_id
---@field successor pop_id

---@class struct_succession
---@field successor_of pop_id
---@field successor pop_id


ffi.cdef[[
    typedef struct {
        uint32_t successor_of;
        uint32_t successor;
    } succession;
]]

---succession: FFI arrays---
---@type nil
DATA.succession_malloc = ffi.C.malloc(ffi.sizeof("succession") * 10001)
---@type table<succession_id, struct_succession>
DATA.succession = ffi.cast("succession*", DATA.succession_malloc)
---@type table<pop_id, succession_id>
DATA.succession_from_successor_of= {}
---@type table<pop_id, succession_id[]>>
DATA.succession_from_successor= {}

---succession: LUA bindings---

DATA.succession_size = 10000
---@type table<succession_id, boolean>
local succession_indices_pool = ffi.new("bool[?]", 10000)
for i = 1, 9999 do
    succession_indices_pool[i] = true
end
---@type table<succession_id, succession_id>
DATA.succession_indices_set = {}
function DATA.create_succession()
    for i = 1, 9999 do
        if succession_indices_pool[i] then
            succession_indices_pool[i] = false
            DATA.succession_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for succession")
end
function DATA.delete_succession(i)
    do
        local old_value = DATA.succession[i].successor_of
        __REMOVE_KEY_SUCCESSION_SUCCESSOR_OF(old_value)
    end
    do
        local old_value = DATA.succession[i].successor
        __REMOVE_KEY_SUCCESSION_SUCCESSOR(i, old_value)
    end
    succession_indices_pool[i] = true
    DATA.succession_indices_set[i] = nil
end
---@param func fun(item: succession_id)
function DATA.for_each_succession(func)
    for _, item in pairs(DATA.succession_indices_set) do
        func(item)
    end
end

---@param succession_id succession_id valid succession id
---@return pop_id successor_of
function DATA.succession_get_successor_of(succession_id)
    return DATA.succession[succession_id].successor_of
end
---@param successor_of pop_id valid pop_id
---@return succession_id succession
function DATA.get_succession_from_successor_of(successor_of)
    return DATA.succession_from_successor_of[successor_of]
end
function __REMOVE_KEY_SUCCESSION_SUCCESSOR_OF(old_value)
    DATA.succession_from_successor_of[old_value] = nil
end
---@param succession_id succession_id valid succession id
---@param value pop_id valid pop_id
function DATA.succession_set_successor_of(succession_id, value)
    local old_value = DATA.succession[succession_id].successor_of
    DATA.succession[succession_id].successor_of = value
    __REMOVE_KEY_SUCCESSION_SUCCESSOR_OF(old_value)
    DATA.succession_from_successor_of[value] = succession_id
end
---@param succession_id succession_id valid succession id
---@return pop_id successor
function DATA.succession_get_successor(succession_id)
    return DATA.succession[succession_id].successor
end
---@param successor pop_id valid pop_id
---@return succession_id[] An array of succession
function DATA.get_succession_from_successor(successor)
    return DATA.succession_from_successor[successor]
end
---@param succession_id succession_id valid succession id
---@param old_value pop_id valid pop_id
function __REMOVE_KEY_SUCCESSION_SUCCESSOR(succession_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.succession_from_successor[old_value]) do
        if value == succession_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.succession_from_successor[old_value], found_key)
    end
end
---@param succession_id succession_id valid succession id
---@param value pop_id valid pop_id
function DATA.succession_set_successor(succession_id, value)
    local old_value = DATA.succession[succession_id].successor
    DATA.succession[succession_id].successor = value
    __REMOVE_KEY_SUCCESSION_SUCCESSOR(succession_id, old_value)
    table.insert(DATA.succession_from_successor[value], succession_id)
end


local fat_succession_id_metatable = {
    __index = function (t,k)
        if (k == "successor_of") then return DATA.succession_get_successor_of(t.id) end
        if (k == "successor") then return DATA.succession_get_successor(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        rawset(t, k, v)
    end
}
---@param id succession_id
---@return fat_succession_id fat_id
function DATA.fatten_succession(id)
    local result = {id = id}
    setmetatable(result, fat_succession_id_metatable)    return result
end
----------jobtype----------


---jobtype: LSP types---

---Unique identificator for jobtype entity
---@alias jobtype_id number

---@class fat_jobtype_id
---@field id jobtype_id Unique jobtype id
---@field name string

---@class struct_jobtype

---@class (exact) jobtype_id_data_blob_definition
---@field name string
---Sets values of jobtype for given id
---@param id jobtype_id
---@param data jobtype_id_data_blob_definition
function DATA.setup_jobtype(id, data)
    DATA.jobtype_set_name(id, data.name)
end

ffi.cdef[[
    typedef struct {
    } jobtype;
]]

---jobtype: FFI arrays---
---@type (string)[]
DATA.jobtype_name= {}
---@type nil
DATA.jobtype_malloc = ffi.C.malloc(ffi.sizeof("jobtype") * 11)
---@type table<jobtype_id, struct_jobtype>
DATA.jobtype = ffi.cast("jobtype*", DATA.jobtype_malloc)

---jobtype: LUA bindings---

DATA.jobtype_size = 10
---@type table<jobtype_id, boolean>
local jobtype_indices_pool = ffi.new("bool[?]", 10)
for i = 1, 9 do
    jobtype_indices_pool[i] = true
end
---@type table<jobtype_id, jobtype_id>
DATA.jobtype_indices_set = {}
function DATA.create_jobtype()
    for i = 1, 9 do
        if jobtype_indices_pool[i] then
            jobtype_indices_pool[i] = false
            DATA.jobtype_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for jobtype")
end
function DATA.delete_jobtype(i)
    jobtype_indices_pool[i] = true
    DATA.jobtype_indices_set[i] = nil
end
---@param func fun(item: jobtype_id)
function DATA.for_each_jobtype(func)
    for _, item in pairs(DATA.jobtype_indices_set) do
        func(item)
    end
end

---@param jobtype_id jobtype_id valid jobtype id
---@return string name
function DATA.jobtype_get_name(jobtype_id)
    return DATA.jobtype_name[jobtype_id]
end
---@param jobtype_id jobtype_id valid jobtype id
---@param value string valid string
function DATA.jobtype_set_name(jobtype_id, value)
    DATA.jobtype_name[jobtype_id] = value
end


local fat_jobtype_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.jobtype_get_name(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.jobtype_set_name(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id jobtype_id
---@return fat_jobtype_id fat_id
function DATA.fatten_jobtype(id)
    local result = {id = id}
    setmetatable(result, fat_jobtype_id_metatable)    return result
end
---@enum JOBTYPE
JOBTYPE = {
    INVALID = 0,
    FORAGER = 1,
    FARMER = 2,
    LABOURER = 3,
    ARTISAN = 4,
    CLERK = 5,
    WARRIOR = 6,
    HAULING = 7,
    HUNTING = 8,
}
local index_jobtype
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "FORAGER")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "FARMER")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "LABOURER")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "ARTISAN")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "CLERK")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "WARRIOR")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "HAULING")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "HUNTING")
----------need----------


---need: LSP types---

---Unique identificator for need entity
---@alias need_id number

---@class fat_need_id
---@field id need_id Unique need id
---@field name string
---@field age_independent boolean
---@field life_need boolean
---@field tool boolean can we use satisfaction of this need in calculations related to production
---@field container boolean can we use satisfaction of this need in calculations related to gathering
---@field time_to_satisfy number Represents amount of time a pop should spend to satisfy a unit of this need.
---@field job_to_satisfy JOBTYPE represents a job type required to satisfy the need on your own

---@class struct_need
---@field age_independent boolean
---@field life_need boolean
---@field tool boolean can we use satisfaction of this need in calculations related to production
---@field container boolean can we use satisfaction of this need in calculations related to gathering
---@field time_to_satisfy number Represents amount of time a pop should spend to satisfy a unit of this need.
---@field job_to_satisfy JOBTYPE represents a job type required to satisfy the need on your own

---@class (exact) need_id_data_blob_definition
---@field name string
---@field age_independent boolean
---@field life_need boolean
---@field tool boolean can we use satisfaction of this need in calculations related to production
---@field container boolean can we use satisfaction of this need in calculations related to gathering
---@field time_to_satisfy number Represents amount of time a pop should spend to satisfy a unit of this need.
---@field job_to_satisfy JOBTYPE represents a job type required to satisfy the need on your own
---Sets values of need for given id
---@param id need_id
---@param data need_id_data_blob_definition
function DATA.setup_need(id, data)
    DATA.need_set_name(id, data.name)
    DATA.need_set_age_independent(id, data.age_independent)
    DATA.need_set_life_need(id, data.life_need)
    DATA.need_set_tool(id, data.tool)
    DATA.need_set_container(id, data.container)
    DATA.need_set_time_to_satisfy(id, data.time_to_satisfy)
    DATA.need_set_job_to_satisfy(id, data.job_to_satisfy)
end

ffi.cdef[[
    typedef struct {
        bool age_independent;
        bool life_need;
        bool tool;
        bool container;
        float time_to_satisfy;
        uint8_t job_to_satisfy;
    } need;
]]

---need: FFI arrays---
---@type (string)[]
DATA.need_name= {}
---@type nil
DATA.need_malloc = ffi.C.malloc(ffi.sizeof("need") * 10)
---@type table<need_id, struct_need>
DATA.need = ffi.cast("need*", DATA.need_malloc)

---need: LUA bindings---

DATA.need_size = 9
---@type table<need_id, boolean>
local need_indices_pool = ffi.new("bool[?]", 9)
for i = 1, 8 do
    need_indices_pool[i] = true
end
---@type table<need_id, need_id>
DATA.need_indices_set = {}
function DATA.create_need()
    for i = 1, 8 do
        if need_indices_pool[i] then
            need_indices_pool[i] = false
            DATA.need_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for need")
end
function DATA.delete_need(i)
    need_indices_pool[i] = true
    DATA.need_indices_set[i] = nil
end
---@param func fun(item: need_id)
function DATA.for_each_need(func)
    for _, item in pairs(DATA.need_indices_set) do
        func(item)
    end
end

---@param need_id need_id valid need id
---@return string name
function DATA.need_get_name(need_id)
    return DATA.need_name[need_id]
end
---@param need_id need_id valid need id
---@param value string valid string
function DATA.need_set_name(need_id, value)
    DATA.need_name[need_id] = value
end
---@param need_id need_id valid need id
---@return boolean age_independent
function DATA.need_get_age_independent(need_id)
    return DATA.need[need_id].age_independent
end
---@param need_id need_id valid need id
---@param value boolean valid boolean
function DATA.need_set_age_independent(need_id, value)
    DATA.need[need_id].age_independent = value
end
---@param need_id need_id valid need id
---@return boolean life_need
function DATA.need_get_life_need(need_id)
    return DATA.need[need_id].life_need
end
---@param need_id need_id valid need id
---@param value boolean valid boolean
function DATA.need_set_life_need(need_id, value)
    DATA.need[need_id].life_need = value
end
---@param need_id need_id valid need id
---@return boolean tool can we use satisfaction of this need in calculations related to production
function DATA.need_get_tool(need_id)
    return DATA.need[need_id].tool
end
---@param need_id need_id valid need id
---@param value boolean valid boolean
function DATA.need_set_tool(need_id, value)
    DATA.need[need_id].tool = value
end
---@param need_id need_id valid need id
---@return boolean container can we use satisfaction of this need in calculations related to gathering
function DATA.need_get_container(need_id)
    return DATA.need[need_id].container
end
---@param need_id need_id valid need id
---@param value boolean valid boolean
function DATA.need_set_container(need_id, value)
    DATA.need[need_id].container = value
end
---@param need_id need_id valid need id
---@return number time_to_satisfy Represents amount of time a pop should spend to satisfy a unit of this need.
function DATA.need_get_time_to_satisfy(need_id)
    return DATA.need[need_id].time_to_satisfy
end
---@param need_id need_id valid need id
---@param value number valid number
function DATA.need_set_time_to_satisfy(need_id, value)
    DATA.need[need_id].time_to_satisfy = value
end
---@param need_id need_id valid need id
---@return JOBTYPE job_to_satisfy represents a job type required to satisfy the need on your own
function DATA.need_get_job_to_satisfy(need_id)
    return DATA.need[need_id].job_to_satisfy
end
---@param need_id need_id valid need id
---@param value JOBTYPE valid JOBTYPE
function DATA.need_set_job_to_satisfy(need_id, value)
    DATA.need[need_id].job_to_satisfy = value
end


local fat_need_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.need_get_name(t.id) end
        if (k == "age_independent") then return DATA.need_get_age_independent(t.id) end
        if (k == "life_need") then return DATA.need_get_life_need(t.id) end
        if (k == "tool") then return DATA.need_get_tool(t.id) end
        if (k == "container") then return DATA.need_get_container(t.id) end
        if (k == "time_to_satisfy") then return DATA.need_get_time_to_satisfy(t.id) end
        if (k == "job_to_satisfy") then return DATA.need_get_job_to_satisfy(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.need_set_name(t.id, v)
            return
        end
        if (k == "age_independent") then
            DATA.need_set_age_independent(t.id, v)
            return
        end
        if (k == "life_need") then
            DATA.need_set_life_need(t.id, v)
            return
        end
        if (k == "tool") then
            DATA.need_set_tool(t.id, v)
            return
        end
        if (k == "container") then
            DATA.need_set_container(t.id, v)
            return
        end
        if (k == "time_to_satisfy") then
            DATA.need_set_time_to_satisfy(t.id, v)
            return
        end
        if (k == "job_to_satisfy") then
            DATA.need_set_job_to_satisfy(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id need_id
---@return fat_need_id fat_id
function DATA.fatten_need(id)
    local result = {id = id}
    setmetatable(result, fat_need_id_metatable)    return result
end
---@enum NEED
NEED = {
    INVALID = 0,
    FOOD = 1,
    TOOLS = 2,
    CONTAINER = 3,
    CLOTHING = 4,
    FURNITURE = 5,
    HEALTHCARE = 6,
    LUXURY = 7,
}
local index_need
index_need = DATA.create_need()
DATA.need_set_name(index_need, "food")
DATA.need_set_age_independent(index_need, false)
DATA.need_set_life_need(index_need, true)
DATA.need_set_tool(index_need, false)
DATA.need_set_container(index_need, false)
DATA.need_set_time_to_satisfy(index_need, 1.5)
DATA.need_set_job_to_satisfy(index_need, JOBTYPE.FORAGER)
index_need = DATA.create_need()
DATA.need_set_name(index_need, "tools")
DATA.need_set_age_independent(index_need, false)
DATA.need_set_life_need(index_need, false)
DATA.need_set_tool(index_need, true)
DATA.need_set_container(index_need, false)
DATA.need_set_time_to_satisfy(index_need, 1.0)
DATA.need_set_job_to_satisfy(index_need, JOBTYPE.ARTISAN)
index_need = DATA.create_need()
DATA.need_set_name(index_need, "container")
DATA.need_set_age_independent(index_need, false)
DATA.need_set_life_need(index_need, false)
DATA.need_set_tool(index_need, false)
DATA.need_set_container(index_need, true)
DATA.need_set_time_to_satisfy(index_need, 1.0)
DATA.need_set_job_to_satisfy(index_need, JOBTYPE.ARTISAN)
index_need = DATA.create_need()
DATA.need_set_name(index_need, "clothing")
DATA.need_set_age_independent(index_need, false)
DATA.need_set_life_need(index_need, false)
DATA.need_set_tool(index_need, false)
DATA.need_set_container(index_need, false)
DATA.need_set_time_to_satisfy(index_need, 0.5)
DATA.need_set_job_to_satisfy(index_need, JOBTYPE.LABOURER)
index_need = DATA.create_need()
DATA.need_set_name(index_need, "furniture")
DATA.need_set_age_independent(index_need, false)
DATA.need_set_life_need(index_need, false)
DATA.need_set_tool(index_need, false)
DATA.need_set_container(index_need, false)
DATA.need_set_time_to_satisfy(index_need, 2.0)
DATA.need_set_job_to_satisfy(index_need, JOBTYPE.LABOURER)
index_need = DATA.create_need()
DATA.need_set_name(index_need, "healthcare")
DATA.need_set_age_independent(index_need, false)
DATA.need_set_life_need(index_need, false)
DATA.need_set_tool(index_need, false)
DATA.need_set_container(index_need, false)
DATA.need_set_time_to_satisfy(index_need, 1.0)
DATA.need_set_job_to_satisfy(index_need, JOBTYPE.CLERK)
index_need = DATA.create_need()
DATA.need_set_name(index_need, "luxury")
DATA.need_set_age_independent(index_need, false)
DATA.need_set_life_need(index_need, false)
DATA.need_set_tool(index_need, false)
DATA.need_set_container(index_need, false)
DATA.need_set_time_to_satisfy(index_need, 3.0)
DATA.need_set_job_to_satisfy(index_need, JOBTYPE.ARTISAN)
----------character_rank----------


---character_rank: LSP types---

---Unique identificator for character_rank entity
---@alias character_rank_id number

---@class fat_character_rank_id
---@field id character_rank_id Unique character_rank id
---@field name string
---@field localisation string

---@class struct_character_rank

---@class (exact) character_rank_id_data_blob_definition
---@field name string
---@field localisation string
---Sets values of character_rank for given id
---@param id character_rank_id
---@param data character_rank_id_data_blob_definition
function DATA.setup_character_rank(id, data)
    DATA.character_rank_set_name(id, data.name)
    DATA.character_rank_set_localisation(id, data.localisation)
end

ffi.cdef[[
    typedef struct {
    } character_rank;
]]

---character_rank: FFI arrays---
---@type (string)[]
DATA.character_rank_name= {}
---@type (string)[]
DATA.character_rank_localisation= {}
---@type nil
DATA.character_rank_malloc = ffi.C.malloc(ffi.sizeof("character_rank") * 6)
---@type table<character_rank_id, struct_character_rank>
DATA.character_rank = ffi.cast("character_rank*", DATA.character_rank_malloc)

---character_rank: LUA bindings---

DATA.character_rank_size = 5
---@type table<character_rank_id, boolean>
local character_rank_indices_pool = ffi.new("bool[?]", 5)
for i = 1, 4 do
    character_rank_indices_pool[i] = true
end
---@type table<character_rank_id, character_rank_id>
DATA.character_rank_indices_set = {}
function DATA.create_character_rank()
    for i = 1, 4 do
        if character_rank_indices_pool[i] then
            character_rank_indices_pool[i] = false
            DATA.character_rank_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for character_rank")
end
function DATA.delete_character_rank(i)
    character_rank_indices_pool[i] = true
    DATA.character_rank_indices_set[i] = nil
end
---@param func fun(item: character_rank_id)
function DATA.for_each_character_rank(func)
    for _, item in pairs(DATA.character_rank_indices_set) do
        func(item)
    end
end

---@param character_rank_id character_rank_id valid character_rank id
---@return string name
function DATA.character_rank_get_name(character_rank_id)
    return DATA.character_rank_name[character_rank_id]
end
---@param character_rank_id character_rank_id valid character_rank id
---@param value string valid string
function DATA.character_rank_set_name(character_rank_id, value)
    DATA.character_rank_name[character_rank_id] = value
end
---@param character_rank_id character_rank_id valid character_rank id
---@return string localisation
function DATA.character_rank_get_localisation(character_rank_id)
    return DATA.character_rank_localisation[character_rank_id]
end
---@param character_rank_id character_rank_id valid character_rank id
---@param value string valid string
function DATA.character_rank_set_localisation(character_rank_id, value)
    DATA.character_rank_localisation[character_rank_id] = value
end


local fat_character_rank_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.character_rank_get_name(t.id) end
        if (k == "localisation") then return DATA.character_rank_get_localisation(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.character_rank_set_name(t.id, v)
            return
        end
        if (k == "localisation") then
            DATA.character_rank_set_localisation(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id character_rank_id
---@return fat_character_rank_id fat_id
function DATA.fatten_character_rank(id)
    local result = {id = id}
    setmetatable(result, fat_character_rank_id_metatable)    return result
end
---@enum CHARACTER_RANK
CHARACTER_RANK = {
    INVALID = 0,
    POP = 1,
    NOBLE = 2,
    CHIEF = 3,
}
local index_character_rank
index_character_rank = DATA.create_character_rank()
DATA.character_rank_set_name(index_character_rank, "POP")
DATA.character_rank_set_localisation(index_character_rank, "Commoner")
index_character_rank = DATA.create_character_rank()
DATA.character_rank_set_name(index_character_rank, "NOBLE")
DATA.character_rank_set_localisation(index_character_rank, "Noble")
index_character_rank = DATA.create_character_rank()
DATA.character_rank_set_name(index_character_rank, "CHIEF")
DATA.character_rank_set_localisation(index_character_rank, "Chief")
----------trait----------


---trait: LSP types---

---Unique identificator for trait entity
---@alias trait_id number

---@class fat_trait_id
---@field id trait_id Unique trait id
---@field name string
---@field short_description string
---@field full_description string
---@field icon string

---@class struct_trait

---@class (exact) trait_id_data_blob_definition
---@field name string
---@field short_description string
---@field full_description string
---@field icon string
---Sets values of trait for given id
---@param id trait_id
---@param data trait_id_data_blob_definition
function DATA.setup_trait(id, data)
    DATA.trait_set_name(id, data.name)
    DATA.trait_set_short_description(id, data.short_description)
    DATA.trait_set_full_description(id, data.full_description)
    DATA.trait_set_icon(id, data.icon)
end

ffi.cdef[[
    typedef struct {
    } trait;
]]

---trait: FFI arrays---
---@type (string)[]
DATA.trait_name= {}
---@type (string)[]
DATA.trait_short_description= {}
---@type (string)[]
DATA.trait_full_description= {}
---@type (string)[]
DATA.trait_icon= {}
---@type nil
DATA.trait_malloc = ffi.C.malloc(ffi.sizeof("trait") * 13)
---@type table<trait_id, struct_trait>
DATA.trait = ffi.cast("trait*", DATA.trait_malloc)

---trait: LUA bindings---

DATA.trait_size = 12
---@type table<trait_id, boolean>
local trait_indices_pool = ffi.new("bool[?]", 12)
for i = 1, 11 do
    trait_indices_pool[i] = true
end
---@type table<trait_id, trait_id>
DATA.trait_indices_set = {}
function DATA.create_trait()
    for i = 1, 11 do
        if trait_indices_pool[i] then
            trait_indices_pool[i] = false
            DATA.trait_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for trait")
end
function DATA.delete_trait(i)
    trait_indices_pool[i] = true
    DATA.trait_indices_set[i] = nil
end
---@param func fun(item: trait_id)
function DATA.for_each_trait(func)
    for _, item in pairs(DATA.trait_indices_set) do
        func(item)
    end
end

---@param trait_id trait_id valid trait id
---@return string name
function DATA.trait_get_name(trait_id)
    return DATA.trait_name[trait_id]
end
---@param trait_id trait_id valid trait id
---@param value string valid string
function DATA.trait_set_name(trait_id, value)
    DATA.trait_name[trait_id] = value
end
---@param trait_id trait_id valid trait id
---@return string short_description
function DATA.trait_get_short_description(trait_id)
    return DATA.trait_short_description[trait_id]
end
---@param trait_id trait_id valid trait id
---@param value string valid string
function DATA.trait_set_short_description(trait_id, value)
    DATA.trait_short_description[trait_id] = value
end
---@param trait_id trait_id valid trait id
---@return string full_description
function DATA.trait_get_full_description(trait_id)
    return DATA.trait_full_description[trait_id]
end
---@param trait_id trait_id valid trait id
---@param value string valid string
function DATA.trait_set_full_description(trait_id, value)
    DATA.trait_full_description[trait_id] = value
end
---@param trait_id trait_id valid trait id
---@return string icon
function DATA.trait_get_icon(trait_id)
    return DATA.trait_icon[trait_id]
end
---@param trait_id trait_id valid trait id
---@param value string valid string
function DATA.trait_set_icon(trait_id, value)
    DATA.trait_icon[trait_id] = value
end


local fat_trait_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.trait_get_name(t.id) end
        if (k == "short_description") then return DATA.trait_get_short_description(t.id) end
        if (k == "full_description") then return DATA.trait_get_full_description(t.id) end
        if (k == "icon") then return DATA.trait_get_icon(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.trait_set_name(t.id, v)
            return
        end
        if (k == "short_description") then
            DATA.trait_set_short_description(t.id, v)
            return
        end
        if (k == "full_description") then
            DATA.trait_set_full_description(t.id, v)
            return
        end
        if (k == "icon") then
            DATA.trait_set_icon(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id trait_id
---@return fat_trait_id fat_id
function DATA.fatten_trait(id)
    local result = {id = id}
    setmetatable(result, fat_trait_id_metatable)    return result
end
---@enum TRAIT
TRAIT = {
    INVALID = 0,
    AMBITIOUS = 1,
    CONTENT = 2,
    LOYAL = 3,
    GREEDY = 4,
    WARLIKE = 5,
    BAD_ORGANISER = 6,
    GOOD_ORGANISER = 7,
    LAZY = 8,
    HARDWORKER = 9,
    TRADER = 10,
}
local index_trait
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "AMBITIOUS")
DATA.trait_set_short_description(index_trait, "ambitious")
DATA.trait_set_full_description(index_trait, "TODO")
DATA.trait_set_icon(index_trait, "mountaintop.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "CONTENT")
DATA.trait_set_short_description(index_trait, "content")
DATA.trait_set_full_description(index_trait, "This person has no ambitions: it would be hard to persuade them to change occupation")
DATA.trait_set_icon(index_trait, "inner-self.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "LOYAL")
DATA.trait_set_short_description(index_trait, "loyal")
DATA.trait_set_full_description(index_trait, "This person rarely betrays people")
DATA.trait_set_icon(index_trait, "check-mark.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "GREEDY")
DATA.trait_set_short_description(index_trait, "greedy")
DATA.trait_set_full_description(index_trait, "Desire for money drives this person's actions")
DATA.trait_set_icon(index_trait, "receive-money.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "WARLIKE")
DATA.trait_set_short_description(index_trait, "warlike")
DATA.trait_set_full_description(index_trait, "TODO")
DATA.trait_set_icon(index_trait, "barbute.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "BAD_ORGANISER")
DATA.trait_set_short_description(index_trait, "bad organiser")
DATA.trait_set_full_description(index_trait, "TODO")
DATA.trait_set_icon(index_trait, "shrug.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "GOOD_ORGANISER")
DATA.trait_set_short_description(index_trait, "good organiser")
DATA.trait_set_full_description(index_trait, "TODO")
DATA.trait_set_icon(index_trait, "pitchfork.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "LAZY")
DATA.trait_set_short_description(index_trait, "lazy")
DATA.trait_set_full_description(index_trait, "This person prefers to do nothing")
DATA.trait_set_icon(index_trait, "parmecia.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "HARDWORKER")
DATA.trait_set_short_description(index_trait, "hard worker")
DATA.trait_set_full_description(index_trait, "TODO")
DATA.trait_set_icon(index_trait, "miner.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "TRADER")
DATA.trait_set_short_description(index_trait, "trader")
DATA.trait_set_full_description(index_trait, "TODO")
DATA.trait_set_icon(index_trait, "scales.png")
----------trade_good_category----------


---trade_good_category: LSP types---

---Unique identificator for trade_good_category entity
---@alias trade_good_category_id number

---@class fat_trade_good_category_id
---@field id trade_good_category_id Unique trade_good_category id
---@field name string

---@class struct_trade_good_category

---@class (exact) trade_good_category_id_data_blob_definition
---@field name string
---Sets values of trade_good_category for given id
---@param id trade_good_category_id
---@param data trade_good_category_id_data_blob_definition
function DATA.setup_trade_good_category(id, data)
    DATA.trade_good_category_set_name(id, data.name)
end

ffi.cdef[[
    typedef struct {
    } trade_good_category;
]]

---trade_good_category: FFI arrays---
---@type (string)[]
DATA.trade_good_category_name= {}
---@type nil
DATA.trade_good_category_malloc = ffi.C.malloc(ffi.sizeof("trade_good_category") * 6)
---@type table<trade_good_category_id, struct_trade_good_category>
DATA.trade_good_category = ffi.cast("trade_good_category*", DATA.trade_good_category_malloc)

---trade_good_category: LUA bindings---

DATA.trade_good_category_size = 5
---@type table<trade_good_category_id, boolean>
local trade_good_category_indices_pool = ffi.new("bool[?]", 5)
for i = 1, 4 do
    trade_good_category_indices_pool[i] = true
end
---@type table<trade_good_category_id, trade_good_category_id>
DATA.trade_good_category_indices_set = {}
function DATA.create_trade_good_category()
    for i = 1, 4 do
        if trade_good_category_indices_pool[i] then
            trade_good_category_indices_pool[i] = false
            DATA.trade_good_category_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for trade_good_category")
end
function DATA.delete_trade_good_category(i)
    trade_good_category_indices_pool[i] = true
    DATA.trade_good_category_indices_set[i] = nil
end
---@param func fun(item: trade_good_category_id)
function DATA.for_each_trade_good_category(func)
    for _, item in pairs(DATA.trade_good_category_indices_set) do
        func(item)
    end
end

---@param trade_good_category_id trade_good_category_id valid trade_good_category id
---@return string name
function DATA.trade_good_category_get_name(trade_good_category_id)
    return DATA.trade_good_category_name[trade_good_category_id]
end
---@param trade_good_category_id trade_good_category_id valid trade_good_category id
---@param value string valid string
function DATA.trade_good_category_set_name(trade_good_category_id, value)
    DATA.trade_good_category_name[trade_good_category_id] = value
end


local fat_trade_good_category_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.trade_good_category_get_name(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.trade_good_category_set_name(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id trade_good_category_id
---@return fat_trade_good_category_id fat_id
function DATA.fatten_trade_good_category(id)
    local result = {id = id}
    setmetatable(result, fat_trade_good_category_id_metatable)    return result
end
---@enum TRADE_GOOD_CATEGORY
TRADE_GOOD_CATEGORY = {
    INVALID = 0,
    GOOD = 1,
    SERVICE = 2,
    CAPACITY = 3,
}
local index_trade_good_category
index_trade_good_category = DATA.create_trade_good_category()
DATA.trade_good_category_set_name(index_trade_good_category, "good")
index_trade_good_category = DATA.create_trade_good_category()
DATA.trade_good_category_set_name(index_trade_good_category, "service")
index_trade_good_category = DATA.create_trade_good_category()
DATA.trade_good_category_set_name(index_trade_good_category, "capacity")
----------warband_status----------


---warband_status: LSP types---

---Unique identificator for warband_status entity
---@alias warband_status_id number

---@class fat_warband_status_id
---@field id warband_status_id Unique warband_status id
---@field name string

---@class struct_warband_status

---@class (exact) warband_status_id_data_blob_definition
---@field name string
---Sets values of warband_status for given id
---@param id warband_status_id
---@param data warband_status_id_data_blob_definition
function DATA.setup_warband_status(id, data)
    DATA.warband_status_set_name(id, data.name)
end

ffi.cdef[[
    typedef struct {
    } warband_status;
]]

---warband_status: FFI arrays---
---@type (string)[]
DATA.warband_status_name= {}
---@type nil
DATA.warband_status_malloc = ffi.C.malloc(ffi.sizeof("warband_status") * 11)
---@type table<warband_status_id, struct_warband_status>
DATA.warband_status = ffi.cast("warband_status*", DATA.warband_status_malloc)

---warband_status: LUA bindings---

DATA.warband_status_size = 10
---@type table<warband_status_id, boolean>
local warband_status_indices_pool = ffi.new("bool[?]", 10)
for i = 1, 9 do
    warband_status_indices_pool[i] = true
end
---@type table<warband_status_id, warband_status_id>
DATA.warband_status_indices_set = {}
function DATA.create_warband_status()
    for i = 1, 9 do
        if warband_status_indices_pool[i] then
            warband_status_indices_pool[i] = false
            DATA.warband_status_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for warband_status")
end
function DATA.delete_warband_status(i)
    warband_status_indices_pool[i] = true
    DATA.warband_status_indices_set[i] = nil
end
---@param func fun(item: warband_status_id)
function DATA.for_each_warband_status(func)
    for _, item in pairs(DATA.warband_status_indices_set) do
        func(item)
    end
end

---@param warband_status_id warband_status_id valid warband_status id
---@return string name
function DATA.warband_status_get_name(warband_status_id)
    return DATA.warband_status_name[warband_status_id]
end
---@param warband_status_id warband_status_id valid warband_status id
---@param value string valid string
function DATA.warband_status_set_name(warband_status_id, value)
    DATA.warband_status_name[warband_status_id] = value
end


local fat_warband_status_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.warband_status_get_name(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.warband_status_set_name(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id warband_status_id
---@return fat_warband_status_id fat_id
function DATA.fatten_warband_status(id)
    local result = {id = id}
    setmetatable(result, fat_warband_status_id_metatable)    return result
end
---@enum WARBAND_STATUS
WARBAND_STATUS = {
    INVALID = 0,
    IDLE = 1,
    RAIDING = 2,
    PREPARING_RAID = 3,
    PREPARING_PATROL = 4,
    PATROL = 5,
    ATTACKING = 6,
    TRAVELLING = 7,
    OFF_DUTY = 8,
}
local index_warband_status
index_warband_status = DATA.create_warband_status()
DATA.warband_status_set_name(index_warband_status, "idle")
index_warband_status = DATA.create_warband_status()
DATA.warband_status_set_name(index_warband_status, "raiding")
index_warband_status = DATA.create_warband_status()
DATA.warband_status_set_name(index_warband_status, "preparing_raid")
index_warband_status = DATA.create_warband_status()
DATA.warband_status_set_name(index_warband_status, "preparing_patrol")
index_warband_status = DATA.create_warband_status()
DATA.warband_status_set_name(index_warband_status, "patrol")
index_warband_status = DATA.create_warband_status()
DATA.warband_status_set_name(index_warband_status, "attacking")
index_warband_status = DATA.create_warband_status()
DATA.warband_status_set_name(index_warband_status, "travelling")
index_warband_status = DATA.create_warband_status()
DATA.warband_status_set_name(index_warband_status, "off_duty")
----------warband_stance----------


---warband_stance: LSP types---

---Unique identificator for warband_stance entity
---@alias warband_stance_id number

---@class fat_warband_stance_id
---@field id warband_stance_id Unique warband_stance id
---@field name string

---@class struct_warband_stance

---@class (exact) warband_stance_id_data_blob_definition
---@field name string
---Sets values of warband_stance for given id
---@param id warband_stance_id
---@param data warband_stance_id_data_blob_definition
function DATA.setup_warband_stance(id, data)
    DATA.warband_stance_set_name(id, data.name)
end

ffi.cdef[[
    typedef struct {
    } warband_stance;
]]

---warband_stance: FFI arrays---
---@type (string)[]
DATA.warband_stance_name= {}
---@type nil
DATA.warband_stance_malloc = ffi.C.malloc(ffi.sizeof("warband_stance") * 5)
---@type table<warband_stance_id, struct_warband_stance>
DATA.warband_stance = ffi.cast("warband_stance*", DATA.warband_stance_malloc)

---warband_stance: LUA bindings---

DATA.warband_stance_size = 4
---@type table<warband_stance_id, boolean>
local warband_stance_indices_pool = ffi.new("bool[?]", 4)
for i = 1, 3 do
    warband_stance_indices_pool[i] = true
end
---@type table<warband_stance_id, warband_stance_id>
DATA.warband_stance_indices_set = {}
function DATA.create_warband_stance()
    for i = 1, 3 do
        if warband_stance_indices_pool[i] then
            warband_stance_indices_pool[i] = false
            DATA.warband_stance_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for warband_stance")
end
function DATA.delete_warband_stance(i)
    warband_stance_indices_pool[i] = true
    DATA.warband_stance_indices_set[i] = nil
end
---@param func fun(item: warband_stance_id)
function DATA.for_each_warband_stance(func)
    for _, item in pairs(DATA.warband_stance_indices_set) do
        func(item)
    end
end

---@param warband_stance_id warband_stance_id valid warband_stance id
---@return string name
function DATA.warband_stance_get_name(warband_stance_id)
    return DATA.warband_stance_name[warband_stance_id]
end
---@param warband_stance_id warband_stance_id valid warband_stance id
---@param value string valid string
function DATA.warband_stance_set_name(warband_stance_id, value)
    DATA.warband_stance_name[warband_stance_id] = value
end


local fat_warband_stance_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.warband_stance_get_name(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.warband_stance_set_name(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id warband_stance_id
---@return fat_warband_stance_id fat_id
function DATA.fatten_warband_stance(id)
    local result = {id = id}
    setmetatable(result, fat_warband_stance_id_metatable)    return result
end
---@enum WARBAND_STANCE
WARBAND_STANCE = {
    INVALID = 0,
    WORK = 1,
    FORAGE = 2,
}
local index_warband_stance
index_warband_stance = DATA.create_warband_stance()
DATA.warband_stance_set_name(index_warband_stance, "work")
index_warband_stance = DATA.create_warband_stance()
DATA.warband_stance_set_name(index_warband_stance, "forage")
----------trade_good----------


---trade_good: LSP types---

---Unique identificator for trade_good entity
---@alias trade_good_id number

---@class fat_trade_good_id
---@field id trade_good_id Unique trade_good id
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field category TRADE_GOOD_CATEGORY
---@field base_price number

---@class struct_trade_good
---@field r number
---@field g number
---@field b number
---@field category TRADE_GOOD_CATEGORY
---@field base_price number

---@class (exact) trade_good_id_data_blob_definition
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field category TRADE_GOOD_CATEGORY?
---@field base_price number
---Sets values of trade_good for given id
---@param id trade_good_id
---@param data trade_good_id_data_blob_definition
function DATA.setup_trade_good(id, data)
    DATA.trade_good_set_name(id, data.name)
    DATA.trade_good_set_icon(id, data.icon)
    DATA.trade_good_set_description(id, data.description)
    DATA.trade_good_set_r(id, data.r)
    DATA.trade_good_set_g(id, data.g)
    DATA.trade_good_set_b(id, data.b)
    if data.category ~= nil then
        DATA.trade_good_set_category(id, data.category)
    end
    DATA.trade_good_set_base_price(id, data.base_price)
end

ffi.cdef[[
    typedef struct {
        float r;
        float g;
        float b;
        uint8_t category;
        float base_price;
    } trade_good;
]]

---trade_good: FFI arrays---
---@type (string)[]
DATA.trade_good_name= {}
---@type (string)[]
DATA.trade_good_icon= {}
---@type (string)[]
DATA.trade_good_description= {}
---@type nil
DATA.trade_good_malloc = ffi.C.malloc(ffi.sizeof("trade_good") * 101)
---@type table<trade_good_id, struct_trade_good>
DATA.trade_good = ffi.cast("trade_good*", DATA.trade_good_malloc)

---trade_good: LUA bindings---

DATA.trade_good_size = 100
---@type table<trade_good_id, boolean>
local trade_good_indices_pool = ffi.new("bool[?]", 100)
for i = 1, 99 do
    trade_good_indices_pool[i] = true
end
---@type table<trade_good_id, trade_good_id>
DATA.trade_good_indices_set = {}
function DATA.create_trade_good()
    for i = 1, 99 do
        if trade_good_indices_pool[i] then
            trade_good_indices_pool[i] = false
            DATA.trade_good_indices_set[i] = i
            DATA.trade_good_set_category(i, TRADE_GOOD_CATEGORY.GOOD)
            return i
        end
    end
    error("Run out of space for trade_good")
end
function DATA.delete_trade_good(i)
    do
        ---@type use_weight_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_use_weight_from_trade_good(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_use_weight(value)
        end
    end
    trade_good_indices_pool[i] = true
    DATA.trade_good_indices_set[i] = nil
end
---@param func fun(item: trade_good_id)
function DATA.for_each_trade_good(func)
    for _, item in pairs(DATA.trade_good_indices_set) do
        func(item)
    end
end

---@param trade_good_id trade_good_id valid trade_good id
---@return string name
function DATA.trade_good_get_name(trade_good_id)
    return DATA.trade_good_name[trade_good_id]
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value string valid string
function DATA.trade_good_set_name(trade_good_id, value)
    DATA.trade_good_name[trade_good_id] = value
end
---@param trade_good_id trade_good_id valid trade_good id
---@return string icon
function DATA.trade_good_get_icon(trade_good_id)
    return DATA.trade_good_icon[trade_good_id]
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value string valid string
function DATA.trade_good_set_icon(trade_good_id, value)
    DATA.trade_good_icon[trade_good_id] = value
end
---@param trade_good_id trade_good_id valid trade_good id
---@return string description
function DATA.trade_good_get_description(trade_good_id)
    return DATA.trade_good_description[trade_good_id]
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value string valid string
function DATA.trade_good_set_description(trade_good_id, value)
    DATA.trade_good_description[trade_good_id] = value
end
---@param trade_good_id trade_good_id valid trade_good id
---@return number r
function DATA.trade_good_get_r(trade_good_id)
    return DATA.trade_good[trade_good_id].r
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value number valid number
function DATA.trade_good_set_r(trade_good_id, value)
    DATA.trade_good[trade_good_id].r = value
end
---@param trade_good_id trade_good_id valid trade_good id
---@return number g
function DATA.trade_good_get_g(trade_good_id)
    return DATA.trade_good[trade_good_id].g
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value number valid number
function DATA.trade_good_set_g(trade_good_id, value)
    DATA.trade_good[trade_good_id].g = value
end
---@param trade_good_id trade_good_id valid trade_good id
---@return number b
function DATA.trade_good_get_b(trade_good_id)
    return DATA.trade_good[trade_good_id].b
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value number valid number
function DATA.trade_good_set_b(trade_good_id, value)
    DATA.trade_good[trade_good_id].b = value
end
---@param trade_good_id trade_good_id valid trade_good id
---@return TRADE_GOOD_CATEGORY category
function DATA.trade_good_get_category(trade_good_id)
    return DATA.trade_good[trade_good_id].category
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value TRADE_GOOD_CATEGORY valid TRADE_GOOD_CATEGORY
function DATA.trade_good_set_category(trade_good_id, value)
    DATA.trade_good[trade_good_id].category = value
end
---@param trade_good_id trade_good_id valid trade_good id
---@return number base_price
function DATA.trade_good_get_base_price(trade_good_id)
    return DATA.trade_good[trade_good_id].base_price
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value number valid number
function DATA.trade_good_set_base_price(trade_good_id, value)
    DATA.trade_good[trade_good_id].base_price = value
end


local fat_trade_good_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.trade_good_get_name(t.id) end
        if (k == "icon") then return DATA.trade_good_get_icon(t.id) end
        if (k == "description") then return DATA.trade_good_get_description(t.id) end
        if (k == "r") then return DATA.trade_good_get_r(t.id) end
        if (k == "g") then return DATA.trade_good_get_g(t.id) end
        if (k == "b") then return DATA.trade_good_get_b(t.id) end
        if (k == "category") then return DATA.trade_good_get_category(t.id) end
        if (k == "base_price") then return DATA.trade_good_get_base_price(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.trade_good_set_name(t.id, v)
            return
        end
        if (k == "icon") then
            DATA.trade_good_set_icon(t.id, v)
            return
        end
        if (k == "description") then
            DATA.trade_good_set_description(t.id, v)
            return
        end
        if (k == "r") then
            DATA.trade_good_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.trade_good_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.trade_good_set_b(t.id, v)
            return
        end
        if (k == "category") then
            DATA.trade_good_set_category(t.id, v)
            return
        end
        if (k == "base_price") then
            DATA.trade_good_set_base_price(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id trade_good_id
---@return fat_trade_good_id fat_id
function DATA.fatten_trade_good(id)
    local result = {id = id}
    setmetatable(result, fat_trade_good_id_metatable)    return result
end
----------use_case----------


---use_case: LSP types---

---Unique identificator for use_case entity
---@alias use_case_id number

---@class fat_use_case_id
---@field id use_case_id Unique use_case id
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number

---@class struct_use_case
---@field r number
---@field g number
---@field b number

---@class (exact) use_case_id_data_blob_definition
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---Sets values of use_case for given id
---@param id use_case_id
---@param data use_case_id_data_blob_definition
function DATA.setup_use_case(id, data)
    DATA.use_case_set_name(id, data.name)
    DATA.use_case_set_icon(id, data.icon)
    DATA.use_case_set_description(id, data.description)
    DATA.use_case_set_r(id, data.r)
    DATA.use_case_set_g(id, data.g)
    DATA.use_case_set_b(id, data.b)
end

ffi.cdef[[
    typedef struct {
        float r;
        float g;
        float b;
    } use_case;
]]

---use_case: FFI arrays---
---@type (string)[]
DATA.use_case_name= {}
---@type (string)[]
DATA.use_case_icon= {}
---@type (string)[]
DATA.use_case_description= {}
---@type nil
DATA.use_case_malloc = ffi.C.malloc(ffi.sizeof("use_case") * 101)
---@type table<use_case_id, struct_use_case>
DATA.use_case = ffi.cast("use_case*", DATA.use_case_malloc)

---use_case: LUA bindings---

DATA.use_case_size = 100
---@type table<use_case_id, boolean>
local use_case_indices_pool = ffi.new("bool[?]", 100)
for i = 1, 99 do
    use_case_indices_pool[i] = true
end
---@type table<use_case_id, use_case_id>
DATA.use_case_indices_set = {}
function DATA.create_use_case()
    for i = 1, 99 do
        if use_case_indices_pool[i] then
            use_case_indices_pool[i] = false
            DATA.use_case_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for use_case")
end
function DATA.delete_use_case(i)
    do
        ---@type use_weight_id[]
        local to_delete = {}
        for _, value in ipairs(DATA.get_use_weight_from_use_case(i)) do
            table.insert(to_delete, value)
        end
        for _, value in ipairs(to_delete) do
            DATA.delete_use_weight(value)
        end
    end
    use_case_indices_pool[i] = true
    DATA.use_case_indices_set[i] = nil
end
---@param func fun(item: use_case_id)
function DATA.for_each_use_case(func)
    for _, item in pairs(DATA.use_case_indices_set) do
        func(item)
    end
end

---@param use_case_id use_case_id valid use_case id
---@return string name
function DATA.use_case_get_name(use_case_id)
    return DATA.use_case_name[use_case_id]
end
---@param use_case_id use_case_id valid use_case id
---@param value string valid string
function DATA.use_case_set_name(use_case_id, value)
    DATA.use_case_name[use_case_id] = value
end
---@param use_case_id use_case_id valid use_case id
---@return string icon
function DATA.use_case_get_icon(use_case_id)
    return DATA.use_case_icon[use_case_id]
end
---@param use_case_id use_case_id valid use_case id
---@param value string valid string
function DATA.use_case_set_icon(use_case_id, value)
    DATA.use_case_icon[use_case_id] = value
end
---@param use_case_id use_case_id valid use_case id
---@return string description
function DATA.use_case_get_description(use_case_id)
    return DATA.use_case_description[use_case_id]
end
---@param use_case_id use_case_id valid use_case id
---@param value string valid string
function DATA.use_case_set_description(use_case_id, value)
    DATA.use_case_description[use_case_id] = value
end
---@param use_case_id use_case_id valid use_case id
---@return number r
function DATA.use_case_get_r(use_case_id)
    return DATA.use_case[use_case_id].r
end
---@param use_case_id use_case_id valid use_case id
---@param value number valid number
function DATA.use_case_set_r(use_case_id, value)
    DATA.use_case[use_case_id].r = value
end
---@param use_case_id use_case_id valid use_case id
---@return number g
function DATA.use_case_get_g(use_case_id)
    return DATA.use_case[use_case_id].g
end
---@param use_case_id use_case_id valid use_case id
---@param value number valid number
function DATA.use_case_set_g(use_case_id, value)
    DATA.use_case[use_case_id].g = value
end
---@param use_case_id use_case_id valid use_case id
---@return number b
function DATA.use_case_get_b(use_case_id)
    return DATA.use_case[use_case_id].b
end
---@param use_case_id use_case_id valid use_case id
---@param value number valid number
function DATA.use_case_set_b(use_case_id, value)
    DATA.use_case[use_case_id].b = value
end


local fat_use_case_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.use_case_get_name(t.id) end
        if (k == "icon") then return DATA.use_case_get_icon(t.id) end
        if (k == "description") then return DATA.use_case_get_description(t.id) end
        if (k == "r") then return DATA.use_case_get_r(t.id) end
        if (k == "g") then return DATA.use_case_get_g(t.id) end
        if (k == "b") then return DATA.use_case_get_b(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.use_case_set_name(t.id, v)
            return
        end
        if (k == "icon") then
            DATA.use_case_set_icon(t.id, v)
            return
        end
        if (k == "description") then
            DATA.use_case_set_description(t.id, v)
            return
        end
        if (k == "r") then
            DATA.use_case_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.use_case_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.use_case_set_b(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id use_case_id
---@return fat_use_case_id fat_id
function DATA.fatten_use_case(id)
    local result = {id = id}
    setmetatable(result, fat_use_case_id_metatable)    return result
end
----------use_weight----------


---use_weight: LSP types---

---Unique identificator for use_weight entity
---@alias use_weight_id number

---@class fat_use_weight_id
---@field id use_weight_id Unique use_weight id
---@field weight number efficiency of this relation
---@field trade_good trade_good_id index of trade good
---@field use_case use_case_id index of use case

---@class struct_use_weight
---@field weight number efficiency of this relation
---@field trade_good trade_good_id index of trade good
---@field use_case use_case_id index of use case

---@class (exact) use_weight_id_data_blob_definition
---@field weight number efficiency of this relation
---@field trade_good trade_good_id index of trade good
---@field use_case use_case_id index of use case
---Sets values of use_weight for given id
---@param id use_weight_id
---@param data use_weight_id_data_blob_definition
function DATA.setup_use_weight(id, data)
    DATA.use_weight_set_weight(id, data.weight)
end

ffi.cdef[[
    typedef struct {
        float weight;
        uint32_t trade_good;
        uint32_t use_case;
    } use_weight;
]]

---use_weight: FFI arrays---
---@type nil
DATA.use_weight_malloc = ffi.C.malloc(ffi.sizeof("use_weight") * 301)
---@type table<use_weight_id, struct_use_weight>
DATA.use_weight = ffi.cast("use_weight*", DATA.use_weight_malloc)
---@type table<trade_good_id, use_weight_id[]>>
DATA.use_weight_from_trade_good= {}
---@type table<use_case_id, use_weight_id[]>>
DATA.use_weight_from_use_case= {}

---use_weight: LUA bindings---

DATA.use_weight_size = 300
---@type table<use_weight_id, boolean>
local use_weight_indices_pool = ffi.new("bool[?]", 300)
for i = 1, 299 do
    use_weight_indices_pool[i] = true
end
---@type table<use_weight_id, use_weight_id>
DATA.use_weight_indices_set = {}
function DATA.create_use_weight()
    for i = 1, 299 do
        if use_weight_indices_pool[i] then
            use_weight_indices_pool[i] = false
            DATA.use_weight_indices_set[i] = i
            return i
        end
    end
    error("Run out of space for use_weight")
end
function DATA.delete_use_weight(i)
    do
        local old_value = DATA.use_weight[i].trade_good
        __REMOVE_KEY_USE_WEIGHT_TRADE_GOOD(i, old_value)
    end
    do
        local old_value = DATA.use_weight[i].use_case
        __REMOVE_KEY_USE_WEIGHT_USE_CASE(i, old_value)
    end
    use_weight_indices_pool[i] = true
    DATA.use_weight_indices_set[i] = nil
end
---@param func fun(item: use_weight_id)
function DATA.for_each_use_weight(func)
    for _, item in pairs(DATA.use_weight_indices_set) do
        func(item)
    end
end

---@param use_weight_id use_weight_id valid use_weight id
---@return number weight efficiency of this relation
function DATA.use_weight_get_weight(use_weight_id)
    return DATA.use_weight[use_weight_id].weight
end
---@param use_weight_id use_weight_id valid use_weight id
---@param value number valid number
function DATA.use_weight_set_weight(use_weight_id, value)
    DATA.use_weight[use_weight_id].weight = value
end
---@param use_weight_id use_weight_id valid use_weight id
---@return trade_good_id trade_good index of trade good
function DATA.use_weight_get_trade_good(use_weight_id)
    return DATA.use_weight[use_weight_id].trade_good
end
---@param trade_good trade_good_id valid trade_good_id
---@return use_weight_id[] An array of use_weight
function DATA.get_use_weight_from_trade_good(trade_good)
    return DATA.use_weight_from_trade_good[trade_good]
end
---@param use_weight_id use_weight_id valid use_weight id
---@param old_value trade_good_id valid trade_good_id
function __REMOVE_KEY_USE_WEIGHT_TRADE_GOOD(use_weight_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.use_weight_from_trade_good[old_value]) do
        if value == use_weight_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.use_weight_from_trade_good[old_value], found_key)
    end
end
---@param use_weight_id use_weight_id valid use_weight id
---@param value trade_good_id valid trade_good_id
function DATA.use_weight_set_trade_good(use_weight_id, value)
    local old_value = DATA.use_weight[use_weight_id].trade_good
    DATA.use_weight[use_weight_id].trade_good = value
    __REMOVE_KEY_USE_WEIGHT_TRADE_GOOD(use_weight_id, old_value)
    table.insert(DATA.use_weight_from_trade_good[value], use_weight_id)
end
---@param use_weight_id use_weight_id valid use_weight id
---@return use_case_id use_case index of use case
function DATA.use_weight_get_use_case(use_weight_id)
    return DATA.use_weight[use_weight_id].use_case
end
---@param use_case use_case_id valid use_case_id
---@return use_weight_id[] An array of use_weight
function DATA.get_use_weight_from_use_case(use_case)
    return DATA.use_weight_from_use_case[use_case]
end
---@param use_weight_id use_weight_id valid use_weight id
---@param old_value use_case_id valid use_case_id
function __REMOVE_KEY_USE_WEIGHT_USE_CASE(use_weight_id, old_value)
    local found_key = nil
    for key, value in pairs(DATA.use_weight_from_use_case[old_value]) do
        if value == use_weight_id then
            found_key = key
            break
        end
    end
    if found_key ~= nil then
        table.remove(DATA.use_weight_from_use_case[old_value], found_key)
    end
end
---@param use_weight_id use_weight_id valid use_weight id
---@param value use_case_id valid use_case_id
function DATA.use_weight_set_use_case(use_weight_id, value)
    local old_value = DATA.use_weight[use_weight_id].use_case
    DATA.use_weight[use_weight_id].use_case = value
    __REMOVE_KEY_USE_WEIGHT_USE_CASE(use_weight_id, old_value)
    table.insert(DATA.use_weight_from_use_case[value], use_weight_id)
end


local fat_use_weight_id_metatable = {
    __index = function (t,k)
        if (k == "weight") then return DATA.use_weight_get_weight(t.id) end
        if (k == "trade_good") then return DATA.use_weight_get_trade_good(t.id) end
        if (k == "use_case") then return DATA.use_weight_get_use_case(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "weight") then
            DATA.use_weight_set_weight(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id use_weight_id
---@return fat_use_weight_id fat_id
function DATA.fatten_use_weight(id)
    local result = {id = id}
    setmetatable(result, fat_use_weight_id_metatable)    return result
end
----------biome----------


---biome: LSP types---

---Unique identificator for biome entity
---@alias biome_id number

---@class fat_biome_id
---@field id biome_id Unique biome id
---@field name string
---@field r number
---@field g number
---@field b number
---@field aquatic boolean
---@field marsh boolean
---@field icy boolean
---@field minimum_slope number m
---@field maximum_slope number m
---@field minimum_elevation number m
---@field maximum_elevation number m
---@field minimum_temperature number C
---@field maximum_temperature number C
---@field minimum_summer_temperature number C
---@field maximum_summer_temperature number C
---@field minimum_winter_temperature number C
---@field maximum_winter_temperature number C
---@field minimum_rain number mm
---@field maximum_rain number mm
---@field minimum_available_water number abstract, adjusted for permeability
---@field maximum_available_water number abstract, adjusted for permeability
---@field minimum_trees number %
---@field maximum_trees number %
---@field minimum_grass number %
---@field maximum_grass number %
---@field minimum_shrubs number %
---@field maximum_shrubs number %
---@field minimum_conifer_fraction number %
---@field maximum_conifer_fraction number %
---@field minimum_dead_land number %
---@field maximum_dead_land number %
---@field minimum_soil_depth number m
---@field maximum_soil_depth number m
---@field minimum_soil_richness number %
---@field maximum_soil_richness number %
---@field minimum_sand number %
---@field maximum_sand number %
---@field minimum_clay number %
---@field maximum_clay number %
---@field minimum_silt number %
---@field maximum_silt number %

---@class struct_biome
---@field r number
---@field g number
---@field b number
---@field aquatic boolean
---@field marsh boolean
---@field icy boolean
---@field minimum_slope number m
---@field maximum_slope number m
---@field minimum_elevation number m
---@field maximum_elevation number m
---@field minimum_temperature number C
---@field maximum_temperature number C
---@field minimum_summer_temperature number C
---@field maximum_summer_temperature number C
---@field minimum_winter_temperature number C
---@field maximum_winter_temperature number C
---@field minimum_rain number mm
---@field maximum_rain number mm
---@field minimum_available_water number abstract, adjusted for permeability
---@field maximum_available_water number abstract, adjusted for permeability
---@field minimum_trees number %
---@field maximum_trees number %
---@field minimum_grass number %
---@field maximum_grass number %
---@field minimum_shrubs number %
---@field maximum_shrubs number %
---@field minimum_conifer_fraction number %
---@field maximum_conifer_fraction number %
---@field minimum_dead_land number %
---@field maximum_dead_land number %
---@field minimum_soil_depth number m
---@field maximum_soil_depth number m
---@field minimum_soil_richness number %
---@field maximum_soil_richness number %
---@field minimum_sand number %
---@field maximum_sand number %
---@field minimum_clay number %
---@field maximum_clay number %
---@field minimum_silt number %
---@field maximum_silt number %

---@class (exact) biome_id_data_blob_definition
---@field name string
---@field r number
---@field g number
---@field b number
---@field aquatic boolean?
---@field marsh boolean?
---@field icy boolean?
---@field minimum_slope number? m
---@field maximum_slope number? m
---@field minimum_elevation number? m
---@field maximum_elevation number? m
---@field minimum_temperature number? C
---@field maximum_temperature number? C
---@field minimum_summer_temperature number? C
---@field maximum_summer_temperature number? C
---@field minimum_winter_temperature number? C
---@field maximum_winter_temperature number? C
---@field minimum_rain number? mm
---@field maximum_rain number? mm
---@field minimum_available_water number? abstract, adjusted for permeability
---@field maximum_available_water number? abstract, adjusted for permeability
---@field minimum_trees number? %
---@field maximum_trees number? %
---@field minimum_grass number? %
---@field maximum_grass number? %
---@field minimum_shrubs number? %
---@field maximum_shrubs number? %
---@field minimum_conifer_fraction number? %
---@field maximum_conifer_fraction number? %
---@field minimum_dead_land number? %
---@field maximum_dead_land number? %
---@field minimum_soil_depth number? m
---@field maximum_soil_depth number? m
---@field minimum_soil_richness number? %
---@field maximum_soil_richness number? %
---@field minimum_sand number? %
---@field maximum_sand number? %
---@field minimum_clay number? %
---@field maximum_clay number? %
---@field minimum_silt number? %
---@field maximum_silt number? %
---Sets values of biome for given id
---@param id biome_id
---@param data biome_id_data_blob_definition
function DATA.setup_biome(id, data)
    DATA.biome_set_name(id, data.name)
    DATA.biome_set_r(id, data.r)
    DATA.biome_set_g(id, data.g)
    DATA.biome_set_b(id, data.b)
    if data.aquatic ~= nil then
        DATA.biome_set_aquatic(id, data.aquatic)
    end
    if data.marsh ~= nil then
        DATA.biome_set_marsh(id, data.marsh)
    end
    if data.icy ~= nil then
        DATA.biome_set_icy(id, data.icy)
    end
    if data.minimum_slope ~= nil then
        DATA.biome_set_minimum_slope(id, data.minimum_slope)
    end
    if data.maximum_slope ~= nil then
        DATA.biome_set_maximum_slope(id, data.maximum_slope)
    end
    if data.minimum_elevation ~= nil then
        DATA.biome_set_minimum_elevation(id, data.minimum_elevation)
    end
    if data.maximum_elevation ~= nil then
        DATA.biome_set_maximum_elevation(id, data.maximum_elevation)
    end
    if data.minimum_temperature ~= nil then
        DATA.biome_set_minimum_temperature(id, data.minimum_temperature)
    end
    if data.maximum_temperature ~= nil then
        DATA.biome_set_maximum_temperature(id, data.maximum_temperature)
    end
    if data.minimum_summer_temperature ~= nil then
        DATA.biome_set_minimum_summer_temperature(id, data.minimum_summer_temperature)
    end
    if data.maximum_summer_temperature ~= nil then
        DATA.biome_set_maximum_summer_temperature(id, data.maximum_summer_temperature)
    end
    if data.minimum_winter_temperature ~= nil then
        DATA.biome_set_minimum_winter_temperature(id, data.minimum_winter_temperature)
    end
    if data.maximum_winter_temperature ~= nil then
        DATA.biome_set_maximum_winter_temperature(id, data.maximum_winter_temperature)
    end
    if data.minimum_rain ~= nil then
        DATA.biome_set_minimum_rain(id, data.minimum_rain)
    end
    if data.maximum_rain ~= nil then
        DATA.biome_set_maximum_rain(id, data.maximum_rain)
    end
    if data.minimum_available_water ~= nil then
        DATA.biome_set_minimum_available_water(id, data.minimum_available_water)
    end
    if data.maximum_available_water ~= nil then
        DATA.biome_set_maximum_available_water(id, data.maximum_available_water)
    end
    if data.minimum_trees ~= nil then
        DATA.biome_set_minimum_trees(id, data.minimum_trees)
    end
    if data.maximum_trees ~= nil then
        DATA.biome_set_maximum_trees(id, data.maximum_trees)
    end
    if data.minimum_grass ~= nil then
        DATA.biome_set_minimum_grass(id, data.minimum_grass)
    end
    if data.maximum_grass ~= nil then
        DATA.biome_set_maximum_grass(id, data.maximum_grass)
    end
    if data.minimum_shrubs ~= nil then
        DATA.biome_set_minimum_shrubs(id, data.minimum_shrubs)
    end
    if data.maximum_shrubs ~= nil then
        DATA.biome_set_maximum_shrubs(id, data.maximum_shrubs)
    end
    if data.minimum_conifer_fraction ~= nil then
        DATA.biome_set_minimum_conifer_fraction(id, data.minimum_conifer_fraction)
    end
    if data.maximum_conifer_fraction ~= nil then
        DATA.biome_set_maximum_conifer_fraction(id, data.maximum_conifer_fraction)
    end
    if data.minimum_dead_land ~= nil then
        DATA.biome_set_minimum_dead_land(id, data.minimum_dead_land)
    end
    if data.maximum_dead_land ~= nil then
        DATA.biome_set_maximum_dead_land(id, data.maximum_dead_land)
    end
    if data.minimum_soil_depth ~= nil then
        DATA.biome_set_minimum_soil_depth(id, data.minimum_soil_depth)
    end
    if data.maximum_soil_depth ~= nil then
        DATA.biome_set_maximum_soil_depth(id, data.maximum_soil_depth)
    end
    if data.minimum_soil_richness ~= nil then
        DATA.biome_set_minimum_soil_richness(id, data.minimum_soil_richness)
    end
    if data.maximum_soil_richness ~= nil then
        DATA.biome_set_maximum_soil_richness(id, data.maximum_soil_richness)
    end
    if data.minimum_sand ~= nil then
        DATA.biome_set_minimum_sand(id, data.minimum_sand)
    end
    if data.maximum_sand ~= nil then
        DATA.biome_set_maximum_sand(id, data.maximum_sand)
    end
    if data.minimum_clay ~= nil then
        DATA.biome_set_minimum_clay(id, data.minimum_clay)
    end
    if data.maximum_clay ~= nil then
        DATA.biome_set_maximum_clay(id, data.maximum_clay)
    end
    if data.minimum_silt ~= nil then
        DATA.biome_set_minimum_silt(id, data.minimum_silt)
    end
    if data.maximum_silt ~= nil then
        DATA.biome_set_maximum_silt(id, data.maximum_silt)
    end
end

ffi.cdef[[
    typedef struct {
        float r;
        float g;
        float b;
        bool aquatic;
        bool marsh;
        bool icy;
        float minimum_slope;
        float maximum_slope;
        float minimum_elevation;
        float maximum_elevation;
        float minimum_temperature;
        float maximum_temperature;
        float minimum_summer_temperature;
        float maximum_summer_temperature;
        float minimum_winter_temperature;
        float maximum_winter_temperature;
        float minimum_rain;
        float maximum_rain;
        float minimum_available_water;
        float maximum_available_water;
        float minimum_trees;
        float maximum_trees;
        float minimum_grass;
        float maximum_grass;
        float minimum_shrubs;
        float maximum_shrubs;
        float minimum_conifer_fraction;
        float maximum_conifer_fraction;
        float minimum_dead_land;
        float maximum_dead_land;
        float minimum_soil_depth;
        float maximum_soil_depth;
        float minimum_soil_richness;
        float maximum_soil_richness;
        float minimum_sand;
        float maximum_sand;
        float minimum_clay;
        float maximum_clay;
        float minimum_silt;
        float maximum_silt;
    } biome;
]]

---biome: FFI arrays---
---@type (string)[]
DATA.biome_name= {}
---@type nil
DATA.biome_malloc = ffi.C.malloc(ffi.sizeof("biome") * 101)
---@type table<biome_id, struct_biome>
DATA.biome = ffi.cast("biome*", DATA.biome_malloc)

---biome: LUA bindings---

DATA.biome_size = 100
---@type table<biome_id, boolean>
local biome_indices_pool = ffi.new("bool[?]", 100)
for i = 1, 99 do
    biome_indices_pool[i] = true
end
---@type table<biome_id, biome_id>
DATA.biome_indices_set = {}
function DATA.create_biome()
    for i = 1, 99 do
        if biome_indices_pool[i] then
            biome_indices_pool[i] = false
            DATA.biome_indices_set[i] = i
            DATA.biome_set_aquatic(i, false)
            DATA.biome_set_marsh(i, false)
            DATA.biome_set_icy(i, false)
            DATA.biome_set_minimum_slope(i, -99999999)
            DATA.biome_set_maximum_slope(i, 99999999)
            DATA.biome_set_minimum_elevation(i, -99999999)
            DATA.biome_set_maximum_elevation(i, 99999999)
            DATA.biome_set_minimum_temperature(i, -99999999)
            DATA.biome_set_maximum_temperature(i, 99999999)
            DATA.biome_set_minimum_summer_temperature(i, -99999999)
            DATA.biome_set_maximum_summer_temperature(i, 99999999)
            DATA.biome_set_minimum_winter_temperature(i, -99999999)
            DATA.biome_set_maximum_winter_temperature(i, 99999999)
            DATA.biome_set_minimum_rain(i, -99999999)
            DATA.biome_set_maximum_rain(i, 99999999)
            DATA.biome_set_minimum_available_water(i, -99999999)
            DATA.biome_set_maximum_available_water(i, 99999999)
            DATA.biome_set_minimum_trees(i, -99999999)
            DATA.biome_set_maximum_trees(i, 99999999)
            DATA.biome_set_minimum_grass(i, -99999999)
            DATA.biome_set_maximum_grass(i, 99999999)
            DATA.biome_set_minimum_shrubs(i, -99999999)
            DATA.biome_set_maximum_shrubs(i, 99999999)
            DATA.biome_set_minimum_conifer_fraction(i, -99999999)
            DATA.biome_set_maximum_conifer_fraction(i, 99999999)
            DATA.biome_set_minimum_dead_land(i, -99999999)
            DATA.biome_set_maximum_dead_land(i, 99999999)
            DATA.biome_set_minimum_soil_depth(i, -99999999)
            DATA.biome_set_maximum_soil_depth(i, 99999999)
            DATA.biome_set_minimum_soil_richness(i, -99999999)
            DATA.biome_set_maximum_soil_richness(i, 99999999)
            DATA.biome_set_minimum_sand(i, -99999999)
            DATA.biome_set_maximum_sand(i, -99999999)
            DATA.biome_set_minimum_clay(i, -99999999)
            DATA.biome_set_maximum_clay(i, 99999999)
            DATA.biome_set_minimum_silt(i, -99999999)
            DATA.biome_set_maximum_silt(i, 99999999)
            return i
        end
    end
    error("Run out of space for biome")
end
function DATA.delete_biome(i)
    biome_indices_pool[i] = true
    DATA.biome_indices_set[i] = nil
end
---@param func fun(item: biome_id)
function DATA.for_each_biome(func)
    for _, item in pairs(DATA.biome_indices_set) do
        func(item)
    end
end

---@param biome_id biome_id valid biome id
---@return string name
function DATA.biome_get_name(biome_id)
    return DATA.biome_name[biome_id]
end
---@param biome_id biome_id valid biome id
---@param value string valid string
function DATA.biome_set_name(biome_id, value)
    DATA.biome_name[biome_id] = value
end
---@param biome_id biome_id valid biome id
---@return number r
function DATA.biome_get_r(biome_id)
    return DATA.biome[biome_id].r
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_r(biome_id, value)
    DATA.biome[biome_id].r = value
end
---@param biome_id biome_id valid biome id
---@return number g
function DATA.biome_get_g(biome_id)
    return DATA.biome[biome_id].g
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_g(biome_id, value)
    DATA.biome[biome_id].g = value
end
---@param biome_id biome_id valid biome id
---@return number b
function DATA.biome_get_b(biome_id)
    return DATA.biome[biome_id].b
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_b(biome_id, value)
    DATA.biome[biome_id].b = value
end
---@param biome_id biome_id valid biome id
---@return boolean aquatic
function DATA.biome_get_aquatic(biome_id)
    return DATA.biome[biome_id].aquatic
end
---@param biome_id biome_id valid biome id
---@param value boolean valid boolean
function DATA.biome_set_aquatic(biome_id, value)
    DATA.biome[biome_id].aquatic = value
end
---@param biome_id biome_id valid biome id
---@return boolean marsh
function DATA.biome_get_marsh(biome_id)
    return DATA.biome[biome_id].marsh
end
---@param biome_id biome_id valid biome id
---@param value boolean valid boolean
function DATA.biome_set_marsh(biome_id, value)
    DATA.biome[biome_id].marsh = value
end
---@param biome_id biome_id valid biome id
---@return boolean icy
function DATA.biome_get_icy(biome_id)
    return DATA.biome[biome_id].icy
end
---@param biome_id biome_id valid biome id
---@param value boolean valid boolean
function DATA.biome_set_icy(biome_id, value)
    DATA.biome[biome_id].icy = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_slope m
function DATA.biome_get_minimum_slope(biome_id)
    return DATA.biome[biome_id].minimum_slope
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_slope(biome_id, value)
    DATA.biome[biome_id].minimum_slope = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_slope m
function DATA.biome_get_maximum_slope(biome_id)
    return DATA.biome[biome_id].maximum_slope
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_slope(biome_id, value)
    DATA.biome[biome_id].maximum_slope = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_elevation m
function DATA.biome_get_minimum_elevation(biome_id)
    return DATA.biome[biome_id].minimum_elevation
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_elevation(biome_id, value)
    DATA.biome[biome_id].minimum_elevation = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_elevation m
function DATA.biome_get_maximum_elevation(biome_id)
    return DATA.biome[biome_id].maximum_elevation
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_elevation(biome_id, value)
    DATA.biome[biome_id].maximum_elevation = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_temperature C
function DATA.biome_get_minimum_temperature(biome_id)
    return DATA.biome[biome_id].minimum_temperature
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_temperature(biome_id, value)
    DATA.biome[biome_id].minimum_temperature = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_temperature C
function DATA.biome_get_maximum_temperature(biome_id)
    return DATA.biome[biome_id].maximum_temperature
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_temperature(biome_id, value)
    DATA.biome[biome_id].maximum_temperature = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_summer_temperature C
function DATA.biome_get_minimum_summer_temperature(biome_id)
    return DATA.biome[biome_id].minimum_summer_temperature
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_summer_temperature(biome_id, value)
    DATA.biome[biome_id].minimum_summer_temperature = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_summer_temperature C
function DATA.biome_get_maximum_summer_temperature(biome_id)
    return DATA.biome[biome_id].maximum_summer_temperature
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_summer_temperature(biome_id, value)
    DATA.biome[biome_id].maximum_summer_temperature = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_winter_temperature C
function DATA.biome_get_minimum_winter_temperature(biome_id)
    return DATA.biome[biome_id].minimum_winter_temperature
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_winter_temperature(biome_id, value)
    DATA.biome[biome_id].minimum_winter_temperature = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_winter_temperature C
function DATA.biome_get_maximum_winter_temperature(biome_id)
    return DATA.biome[biome_id].maximum_winter_temperature
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_winter_temperature(biome_id, value)
    DATA.biome[biome_id].maximum_winter_temperature = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_rain mm
function DATA.biome_get_minimum_rain(biome_id)
    return DATA.biome[biome_id].minimum_rain
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_rain(biome_id, value)
    DATA.biome[biome_id].minimum_rain = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_rain mm
function DATA.biome_get_maximum_rain(biome_id)
    return DATA.biome[biome_id].maximum_rain
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_rain(biome_id, value)
    DATA.biome[biome_id].maximum_rain = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_available_water abstract, adjusted for permeability
function DATA.biome_get_minimum_available_water(biome_id)
    return DATA.biome[biome_id].minimum_available_water
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_available_water(biome_id, value)
    DATA.biome[biome_id].minimum_available_water = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_available_water abstract, adjusted for permeability
function DATA.biome_get_maximum_available_water(biome_id)
    return DATA.biome[biome_id].maximum_available_water
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_available_water(biome_id, value)
    DATA.biome[biome_id].maximum_available_water = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_trees %
function DATA.biome_get_minimum_trees(biome_id)
    return DATA.biome[biome_id].minimum_trees
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_trees(biome_id, value)
    DATA.biome[biome_id].minimum_trees = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_trees %
function DATA.biome_get_maximum_trees(biome_id)
    return DATA.biome[biome_id].maximum_trees
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_trees(biome_id, value)
    DATA.biome[biome_id].maximum_trees = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_grass %
function DATA.biome_get_minimum_grass(biome_id)
    return DATA.biome[biome_id].minimum_grass
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_grass(biome_id, value)
    DATA.biome[biome_id].minimum_grass = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_grass %
function DATA.biome_get_maximum_grass(biome_id)
    return DATA.biome[biome_id].maximum_grass
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_grass(biome_id, value)
    DATA.biome[biome_id].maximum_grass = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_shrubs %
function DATA.biome_get_minimum_shrubs(biome_id)
    return DATA.biome[biome_id].minimum_shrubs
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_shrubs(biome_id, value)
    DATA.biome[biome_id].minimum_shrubs = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_shrubs %
function DATA.biome_get_maximum_shrubs(biome_id)
    return DATA.biome[biome_id].maximum_shrubs
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_shrubs(biome_id, value)
    DATA.biome[biome_id].maximum_shrubs = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_conifer_fraction %
function DATA.biome_get_minimum_conifer_fraction(biome_id)
    return DATA.biome[biome_id].minimum_conifer_fraction
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_conifer_fraction(biome_id, value)
    DATA.biome[biome_id].minimum_conifer_fraction = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_conifer_fraction %
function DATA.biome_get_maximum_conifer_fraction(biome_id)
    return DATA.biome[biome_id].maximum_conifer_fraction
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_conifer_fraction(biome_id, value)
    DATA.biome[biome_id].maximum_conifer_fraction = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_dead_land %
function DATA.biome_get_minimum_dead_land(biome_id)
    return DATA.biome[biome_id].minimum_dead_land
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_dead_land(biome_id, value)
    DATA.biome[biome_id].minimum_dead_land = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_dead_land %
function DATA.biome_get_maximum_dead_land(biome_id)
    return DATA.biome[biome_id].maximum_dead_land
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_dead_land(biome_id, value)
    DATA.biome[biome_id].maximum_dead_land = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_soil_depth m
function DATA.biome_get_minimum_soil_depth(biome_id)
    return DATA.biome[biome_id].minimum_soil_depth
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_soil_depth(biome_id, value)
    DATA.biome[biome_id].minimum_soil_depth = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_soil_depth m
function DATA.biome_get_maximum_soil_depth(biome_id)
    return DATA.biome[biome_id].maximum_soil_depth
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_soil_depth(biome_id, value)
    DATA.biome[biome_id].maximum_soil_depth = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_soil_richness %
function DATA.biome_get_minimum_soil_richness(biome_id)
    return DATA.biome[biome_id].minimum_soil_richness
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_soil_richness(biome_id, value)
    DATA.biome[biome_id].minimum_soil_richness = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_soil_richness %
function DATA.biome_get_maximum_soil_richness(biome_id)
    return DATA.biome[biome_id].maximum_soil_richness
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_soil_richness(biome_id, value)
    DATA.biome[biome_id].maximum_soil_richness = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_sand %
function DATA.biome_get_minimum_sand(biome_id)
    return DATA.biome[biome_id].minimum_sand
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_sand(biome_id, value)
    DATA.biome[biome_id].minimum_sand = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_sand %
function DATA.biome_get_maximum_sand(biome_id)
    return DATA.biome[biome_id].maximum_sand
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_sand(biome_id, value)
    DATA.biome[biome_id].maximum_sand = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_clay %
function DATA.biome_get_minimum_clay(biome_id)
    return DATA.biome[biome_id].minimum_clay
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_clay(biome_id, value)
    DATA.biome[biome_id].minimum_clay = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_clay %
function DATA.biome_get_maximum_clay(biome_id)
    return DATA.biome[biome_id].maximum_clay
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_clay(biome_id, value)
    DATA.biome[biome_id].maximum_clay = value
end
---@param biome_id biome_id valid biome id
---@return number minimum_silt %
function DATA.biome_get_minimum_silt(biome_id)
    return DATA.biome[biome_id].minimum_silt
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_silt(biome_id, value)
    DATA.biome[biome_id].minimum_silt = value
end
---@param biome_id biome_id valid biome id
---@return number maximum_silt %
function DATA.biome_get_maximum_silt(biome_id)
    return DATA.biome[biome_id].maximum_silt
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_silt(biome_id, value)
    DATA.biome[biome_id].maximum_silt = value
end


local fat_biome_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.biome_get_name(t.id) end
        if (k == "r") then return DATA.biome_get_r(t.id) end
        if (k == "g") then return DATA.biome_get_g(t.id) end
        if (k == "b") then return DATA.biome_get_b(t.id) end
        if (k == "aquatic") then return DATA.biome_get_aquatic(t.id) end
        if (k == "marsh") then return DATA.biome_get_marsh(t.id) end
        if (k == "icy") then return DATA.biome_get_icy(t.id) end
        if (k == "minimum_slope") then return DATA.biome_get_minimum_slope(t.id) end
        if (k == "maximum_slope") then return DATA.biome_get_maximum_slope(t.id) end
        if (k == "minimum_elevation") then return DATA.biome_get_minimum_elevation(t.id) end
        if (k == "maximum_elevation") then return DATA.biome_get_maximum_elevation(t.id) end
        if (k == "minimum_temperature") then return DATA.biome_get_minimum_temperature(t.id) end
        if (k == "maximum_temperature") then return DATA.biome_get_maximum_temperature(t.id) end
        if (k == "minimum_summer_temperature") then return DATA.biome_get_minimum_summer_temperature(t.id) end
        if (k == "maximum_summer_temperature") then return DATA.biome_get_maximum_summer_temperature(t.id) end
        if (k == "minimum_winter_temperature") then return DATA.biome_get_minimum_winter_temperature(t.id) end
        if (k == "maximum_winter_temperature") then return DATA.biome_get_maximum_winter_temperature(t.id) end
        if (k == "minimum_rain") then return DATA.biome_get_minimum_rain(t.id) end
        if (k == "maximum_rain") then return DATA.biome_get_maximum_rain(t.id) end
        if (k == "minimum_available_water") then return DATA.biome_get_minimum_available_water(t.id) end
        if (k == "maximum_available_water") then return DATA.biome_get_maximum_available_water(t.id) end
        if (k == "minimum_trees") then return DATA.biome_get_minimum_trees(t.id) end
        if (k == "maximum_trees") then return DATA.biome_get_maximum_trees(t.id) end
        if (k == "minimum_grass") then return DATA.biome_get_minimum_grass(t.id) end
        if (k == "maximum_grass") then return DATA.biome_get_maximum_grass(t.id) end
        if (k == "minimum_shrubs") then return DATA.biome_get_minimum_shrubs(t.id) end
        if (k == "maximum_shrubs") then return DATA.biome_get_maximum_shrubs(t.id) end
        if (k == "minimum_conifer_fraction") then return DATA.biome_get_minimum_conifer_fraction(t.id) end
        if (k == "maximum_conifer_fraction") then return DATA.biome_get_maximum_conifer_fraction(t.id) end
        if (k == "minimum_dead_land") then return DATA.biome_get_minimum_dead_land(t.id) end
        if (k == "maximum_dead_land") then return DATA.biome_get_maximum_dead_land(t.id) end
        if (k == "minimum_soil_depth") then return DATA.biome_get_minimum_soil_depth(t.id) end
        if (k == "maximum_soil_depth") then return DATA.biome_get_maximum_soil_depth(t.id) end
        if (k == "minimum_soil_richness") then return DATA.biome_get_minimum_soil_richness(t.id) end
        if (k == "maximum_soil_richness") then return DATA.biome_get_maximum_soil_richness(t.id) end
        if (k == "minimum_sand") then return DATA.biome_get_minimum_sand(t.id) end
        if (k == "maximum_sand") then return DATA.biome_get_maximum_sand(t.id) end
        if (k == "minimum_clay") then return DATA.biome_get_minimum_clay(t.id) end
        if (k == "maximum_clay") then return DATA.biome_get_maximum_clay(t.id) end
        if (k == "minimum_silt") then return DATA.biome_get_minimum_silt(t.id) end
        if (k == "maximum_silt") then return DATA.biome_get_maximum_silt(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.biome_set_name(t.id, v)
            return
        end
        if (k == "r") then
            DATA.biome_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.biome_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.biome_set_b(t.id, v)
            return
        end
        if (k == "aquatic") then
            DATA.biome_set_aquatic(t.id, v)
            return
        end
        if (k == "marsh") then
            DATA.biome_set_marsh(t.id, v)
            return
        end
        if (k == "icy") then
            DATA.biome_set_icy(t.id, v)
            return
        end
        if (k == "minimum_slope") then
            DATA.biome_set_minimum_slope(t.id, v)
            return
        end
        if (k == "maximum_slope") then
            DATA.biome_set_maximum_slope(t.id, v)
            return
        end
        if (k == "minimum_elevation") then
            DATA.biome_set_minimum_elevation(t.id, v)
            return
        end
        if (k == "maximum_elevation") then
            DATA.biome_set_maximum_elevation(t.id, v)
            return
        end
        if (k == "minimum_temperature") then
            DATA.biome_set_minimum_temperature(t.id, v)
            return
        end
        if (k == "maximum_temperature") then
            DATA.biome_set_maximum_temperature(t.id, v)
            return
        end
        if (k == "minimum_summer_temperature") then
            DATA.biome_set_minimum_summer_temperature(t.id, v)
            return
        end
        if (k == "maximum_summer_temperature") then
            DATA.biome_set_maximum_summer_temperature(t.id, v)
            return
        end
        if (k == "minimum_winter_temperature") then
            DATA.biome_set_minimum_winter_temperature(t.id, v)
            return
        end
        if (k == "maximum_winter_temperature") then
            DATA.biome_set_maximum_winter_temperature(t.id, v)
            return
        end
        if (k == "minimum_rain") then
            DATA.biome_set_minimum_rain(t.id, v)
            return
        end
        if (k == "maximum_rain") then
            DATA.biome_set_maximum_rain(t.id, v)
            return
        end
        if (k == "minimum_available_water") then
            DATA.biome_set_minimum_available_water(t.id, v)
            return
        end
        if (k == "maximum_available_water") then
            DATA.biome_set_maximum_available_water(t.id, v)
            return
        end
        if (k == "minimum_trees") then
            DATA.biome_set_minimum_trees(t.id, v)
            return
        end
        if (k == "maximum_trees") then
            DATA.biome_set_maximum_trees(t.id, v)
            return
        end
        if (k == "minimum_grass") then
            DATA.biome_set_minimum_grass(t.id, v)
            return
        end
        if (k == "maximum_grass") then
            DATA.biome_set_maximum_grass(t.id, v)
            return
        end
        if (k == "minimum_shrubs") then
            DATA.biome_set_minimum_shrubs(t.id, v)
            return
        end
        if (k == "maximum_shrubs") then
            DATA.biome_set_maximum_shrubs(t.id, v)
            return
        end
        if (k == "minimum_conifer_fraction") then
            DATA.biome_set_minimum_conifer_fraction(t.id, v)
            return
        end
        if (k == "maximum_conifer_fraction") then
            DATA.biome_set_maximum_conifer_fraction(t.id, v)
            return
        end
        if (k == "minimum_dead_land") then
            DATA.biome_set_minimum_dead_land(t.id, v)
            return
        end
        if (k == "maximum_dead_land") then
            DATA.biome_set_maximum_dead_land(t.id, v)
            return
        end
        if (k == "minimum_soil_depth") then
            DATA.biome_set_minimum_soil_depth(t.id, v)
            return
        end
        if (k == "maximum_soil_depth") then
            DATA.biome_set_maximum_soil_depth(t.id, v)
            return
        end
        if (k == "minimum_soil_richness") then
            DATA.biome_set_minimum_soil_richness(t.id, v)
            return
        end
        if (k == "maximum_soil_richness") then
            DATA.biome_set_maximum_soil_richness(t.id, v)
            return
        end
        if (k == "minimum_sand") then
            DATA.biome_set_minimum_sand(t.id, v)
            return
        end
        if (k == "maximum_sand") then
            DATA.biome_set_maximum_sand(t.id, v)
            return
        end
        if (k == "minimum_clay") then
            DATA.biome_set_minimum_clay(t.id, v)
            return
        end
        if (k == "maximum_clay") then
            DATA.biome_set_maximum_clay(t.id, v)
            return
        end
        if (k == "minimum_silt") then
            DATA.biome_set_minimum_silt(t.id, v)
            return
        end
        if (k == "maximum_silt") then
            DATA.biome_set_maximum_silt(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id biome_id
---@return fat_biome_id fat_id
function DATA.fatten_biome(id)
    local result = {id = id}
    setmetatable(result, fat_biome_id_metatable)    return result
end
----------bedrock----------


---bedrock: LSP types---

---Unique identificator for bedrock entity
---@alias bedrock_id number

---@class fat_bedrock_id
---@field id bedrock_id Unique bedrock id
---@field name string
---@field r number
---@field g number
---@field b number
---@field color_id number
---@field sand number
---@field silt number
---@field clay number
---@field organics number
---@field minerals number
---@field weathering number
---@field grain_size number
---@field acidity number
---@field igneous_extrusive boolean
---@field igneous_intrusive boolean
---@field sedimentary boolean
---@field clastic boolean
---@field evaporative boolean
---@field metamorphic_marble boolean
---@field metamorphic_slate boolean
---@field oceanic boolean
---@field sedimentary_ocean_deep boolean
---@field sedimentary_ocean_shallow boolean

---@class struct_bedrock
---@field r number
---@field g number
---@field b number
---@field color_id number
---@field sand number
---@field silt number
---@field clay number
---@field organics number
---@field minerals number
---@field weathering number
---@field grain_size number
---@field acidity number
---@field igneous_extrusive boolean
---@field igneous_intrusive boolean
---@field sedimentary boolean
---@field clastic boolean
---@field evaporative boolean
---@field metamorphic_marble boolean
---@field metamorphic_slate boolean
---@field oceanic boolean
---@field sedimentary_ocean_deep boolean
---@field sedimentary_ocean_shallow boolean

---@class (exact) bedrock_id_data_blob_definition
---@field name string
---@field r number
---@field g number
---@field b number
---@field sand number
---@field silt number
---@field clay number
---@field organics number
---@field minerals number
---@field weathering number
---@field grain_size number?
---@field acidity number?
---@field igneous_extrusive boolean?
---@field igneous_intrusive boolean?
---@field sedimentary boolean?
---@field clastic boolean?
---@field evaporative boolean?
---@field metamorphic_marble boolean?
---@field metamorphic_slate boolean?
---@field oceanic boolean?
---@field sedimentary_ocean_deep boolean?
---@field sedimentary_ocean_shallow boolean?
---Sets values of bedrock for given id
---@param id bedrock_id
---@param data bedrock_id_data_blob_definition
function DATA.setup_bedrock(id, data)
    DATA.bedrock_set_name(id, data.name)
    DATA.bedrock_set_r(id, data.r)
    DATA.bedrock_set_g(id, data.g)
    DATA.bedrock_set_b(id, data.b)
    DATA.bedrock_set_sand(id, data.sand)
    DATA.bedrock_set_silt(id, data.silt)
    DATA.bedrock_set_clay(id, data.clay)
    DATA.bedrock_set_organics(id, data.organics)
    DATA.bedrock_set_minerals(id, data.minerals)
    DATA.bedrock_set_weathering(id, data.weathering)
    if data.grain_size ~= nil then
        DATA.bedrock_set_grain_size(id, data.grain_size)
    end
    if data.acidity ~= nil then
        DATA.bedrock_set_acidity(id, data.acidity)
    end
    if data.igneous_extrusive ~= nil then
        DATA.bedrock_set_igneous_extrusive(id, data.igneous_extrusive)
    end
    if data.igneous_intrusive ~= nil then
        DATA.bedrock_set_igneous_intrusive(id, data.igneous_intrusive)
    end
    if data.sedimentary ~= nil then
        DATA.bedrock_set_sedimentary(id, data.sedimentary)
    end
    if data.clastic ~= nil then
        DATA.bedrock_set_clastic(id, data.clastic)
    end
    if data.evaporative ~= nil then
        DATA.bedrock_set_evaporative(id, data.evaporative)
    end
    if data.metamorphic_marble ~= nil then
        DATA.bedrock_set_metamorphic_marble(id, data.metamorphic_marble)
    end
    if data.metamorphic_slate ~= nil then
        DATA.bedrock_set_metamorphic_slate(id, data.metamorphic_slate)
    end
    if data.oceanic ~= nil then
        DATA.bedrock_set_oceanic(id, data.oceanic)
    end
    if data.sedimentary_ocean_deep ~= nil then
        DATA.bedrock_set_sedimentary_ocean_deep(id, data.sedimentary_ocean_deep)
    end
    if data.sedimentary_ocean_shallow ~= nil then
        DATA.bedrock_set_sedimentary_ocean_shallow(id, data.sedimentary_ocean_shallow)
    end
end

ffi.cdef[[
    typedef struct {
        float r;
        float g;
        float b;
        uint32_t color_id;
        float sand;
        float silt;
        float clay;
        float organics;
        float minerals;
        float weathering;
        float grain_size;
        float acidity;
        bool igneous_extrusive;
        bool igneous_intrusive;
        bool sedimentary;
        bool clastic;
        bool evaporative;
        bool metamorphic_marble;
        bool metamorphic_slate;
        bool oceanic;
        bool sedimentary_ocean_deep;
        bool sedimentary_ocean_shallow;
    } bedrock;
]]

---bedrock: FFI arrays---
---@type (string)[]
DATA.bedrock_name= {}
---@type nil
DATA.bedrock_malloc = ffi.C.malloc(ffi.sizeof("bedrock") * 151)
---@type table<bedrock_id, struct_bedrock>
DATA.bedrock = ffi.cast("bedrock*", DATA.bedrock_malloc)

---bedrock: LUA bindings---

DATA.bedrock_size = 150
---@type table<bedrock_id, boolean>
local bedrock_indices_pool = ffi.new("bool[?]", 150)
for i = 1, 149 do
    bedrock_indices_pool[i] = true
end
---@type table<bedrock_id, bedrock_id>
DATA.bedrock_indices_set = {}
function DATA.create_bedrock()
    for i = 1, 149 do
        if bedrock_indices_pool[i] then
            bedrock_indices_pool[i] = false
            DATA.bedrock_indices_set[i] = i
            DATA.bedrock_set_grain_size(i, 0.0)
            DATA.bedrock_set_acidity(i, 0.0)
            DATA.bedrock_set_igneous_extrusive(i, false)
            DATA.bedrock_set_igneous_intrusive(i, false)
            DATA.bedrock_set_sedimentary(i, false)
            DATA.bedrock_set_clastic(i, false)
            DATA.bedrock_set_evaporative(i, false)
            DATA.bedrock_set_metamorphic_marble(i, false)
            DATA.bedrock_set_metamorphic_slate(i, false)
            DATA.bedrock_set_oceanic(i, false)
            DATA.bedrock_set_sedimentary_ocean_deep(i, false)
            DATA.bedrock_set_sedimentary_ocean_shallow(i, false)
            return i
        end
    end
    error("Run out of space for bedrock")
end
function DATA.delete_bedrock(i)
    bedrock_indices_pool[i] = true
    DATA.bedrock_indices_set[i] = nil
end
---@param func fun(item: bedrock_id)
function DATA.for_each_bedrock(func)
    for _, item in pairs(DATA.bedrock_indices_set) do
        func(item)
    end
end

---@param bedrock_id bedrock_id valid bedrock id
---@return string name
function DATA.bedrock_get_name(bedrock_id)
    return DATA.bedrock_name[bedrock_id]
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value string valid string
function DATA.bedrock_set_name(bedrock_id, value)
    DATA.bedrock_name[bedrock_id] = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number r
function DATA.bedrock_get_r(bedrock_id)
    return DATA.bedrock[bedrock_id].r
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_r(bedrock_id, value)
    DATA.bedrock[bedrock_id].r = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number g
function DATA.bedrock_get_g(bedrock_id)
    return DATA.bedrock[bedrock_id].g
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_g(bedrock_id, value)
    DATA.bedrock[bedrock_id].g = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number b
function DATA.bedrock_get_b(bedrock_id)
    return DATA.bedrock[bedrock_id].b
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_b(bedrock_id, value)
    DATA.bedrock[bedrock_id].b = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number color_id
function DATA.bedrock_get_color_id(bedrock_id)
    return DATA.bedrock[bedrock_id].color_id
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_color_id(bedrock_id, value)
    DATA.bedrock[bedrock_id].color_id = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number sand
function DATA.bedrock_get_sand(bedrock_id)
    return DATA.bedrock[bedrock_id].sand
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_sand(bedrock_id, value)
    DATA.bedrock[bedrock_id].sand = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number silt
function DATA.bedrock_get_silt(bedrock_id)
    return DATA.bedrock[bedrock_id].silt
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_silt(bedrock_id, value)
    DATA.bedrock[bedrock_id].silt = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number clay
function DATA.bedrock_get_clay(bedrock_id)
    return DATA.bedrock[bedrock_id].clay
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_clay(bedrock_id, value)
    DATA.bedrock[bedrock_id].clay = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number organics
function DATA.bedrock_get_organics(bedrock_id)
    return DATA.bedrock[bedrock_id].organics
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_organics(bedrock_id, value)
    DATA.bedrock[bedrock_id].organics = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number minerals
function DATA.bedrock_get_minerals(bedrock_id)
    return DATA.bedrock[bedrock_id].minerals
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_minerals(bedrock_id, value)
    DATA.bedrock[bedrock_id].minerals = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number weathering
function DATA.bedrock_get_weathering(bedrock_id)
    return DATA.bedrock[bedrock_id].weathering
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_weathering(bedrock_id, value)
    DATA.bedrock[bedrock_id].weathering = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number grain_size
function DATA.bedrock_get_grain_size(bedrock_id)
    return DATA.bedrock[bedrock_id].grain_size
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_grain_size(bedrock_id, value)
    DATA.bedrock[bedrock_id].grain_size = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number acidity
function DATA.bedrock_get_acidity(bedrock_id)
    return DATA.bedrock[bedrock_id].acidity
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_acidity(bedrock_id, value)
    DATA.bedrock[bedrock_id].acidity = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean igneous_extrusive
function DATA.bedrock_get_igneous_extrusive(bedrock_id)
    return DATA.bedrock[bedrock_id].igneous_extrusive
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_igneous_extrusive(bedrock_id, value)
    DATA.bedrock[bedrock_id].igneous_extrusive = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean igneous_intrusive
function DATA.bedrock_get_igneous_intrusive(bedrock_id)
    return DATA.bedrock[bedrock_id].igneous_intrusive
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_igneous_intrusive(bedrock_id, value)
    DATA.bedrock[bedrock_id].igneous_intrusive = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean sedimentary
function DATA.bedrock_get_sedimentary(bedrock_id)
    return DATA.bedrock[bedrock_id].sedimentary
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_sedimentary(bedrock_id, value)
    DATA.bedrock[bedrock_id].sedimentary = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean clastic
function DATA.bedrock_get_clastic(bedrock_id)
    return DATA.bedrock[bedrock_id].clastic
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_clastic(bedrock_id, value)
    DATA.bedrock[bedrock_id].clastic = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean evaporative
function DATA.bedrock_get_evaporative(bedrock_id)
    return DATA.bedrock[bedrock_id].evaporative
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_evaporative(bedrock_id, value)
    DATA.bedrock[bedrock_id].evaporative = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean metamorphic_marble
function DATA.bedrock_get_metamorphic_marble(bedrock_id)
    return DATA.bedrock[bedrock_id].metamorphic_marble
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_metamorphic_marble(bedrock_id, value)
    DATA.bedrock[bedrock_id].metamorphic_marble = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean metamorphic_slate
function DATA.bedrock_get_metamorphic_slate(bedrock_id)
    return DATA.bedrock[bedrock_id].metamorphic_slate
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_metamorphic_slate(bedrock_id, value)
    DATA.bedrock[bedrock_id].metamorphic_slate = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean oceanic
function DATA.bedrock_get_oceanic(bedrock_id)
    return DATA.bedrock[bedrock_id].oceanic
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_oceanic(bedrock_id, value)
    DATA.bedrock[bedrock_id].oceanic = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean sedimentary_ocean_deep
function DATA.bedrock_get_sedimentary_ocean_deep(bedrock_id)
    return DATA.bedrock[bedrock_id].sedimentary_ocean_deep
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_sedimentary_ocean_deep(bedrock_id, value)
    DATA.bedrock[bedrock_id].sedimentary_ocean_deep = value
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean sedimentary_ocean_shallow
function DATA.bedrock_get_sedimentary_ocean_shallow(bedrock_id)
    return DATA.bedrock[bedrock_id].sedimentary_ocean_shallow
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_sedimentary_ocean_shallow(bedrock_id, value)
    DATA.bedrock[bedrock_id].sedimentary_ocean_shallow = value
end


local fat_bedrock_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.bedrock_get_name(t.id) end
        if (k == "r") then return DATA.bedrock_get_r(t.id) end
        if (k == "g") then return DATA.bedrock_get_g(t.id) end
        if (k == "b") then return DATA.bedrock_get_b(t.id) end
        if (k == "color_id") then return DATA.bedrock_get_color_id(t.id) end
        if (k == "sand") then return DATA.bedrock_get_sand(t.id) end
        if (k == "silt") then return DATA.bedrock_get_silt(t.id) end
        if (k == "clay") then return DATA.bedrock_get_clay(t.id) end
        if (k == "organics") then return DATA.bedrock_get_organics(t.id) end
        if (k == "minerals") then return DATA.bedrock_get_minerals(t.id) end
        if (k == "weathering") then return DATA.bedrock_get_weathering(t.id) end
        if (k == "grain_size") then return DATA.bedrock_get_grain_size(t.id) end
        if (k == "acidity") then return DATA.bedrock_get_acidity(t.id) end
        if (k == "igneous_extrusive") then return DATA.bedrock_get_igneous_extrusive(t.id) end
        if (k == "igneous_intrusive") then return DATA.bedrock_get_igneous_intrusive(t.id) end
        if (k == "sedimentary") then return DATA.bedrock_get_sedimentary(t.id) end
        if (k == "clastic") then return DATA.bedrock_get_clastic(t.id) end
        if (k == "evaporative") then return DATA.bedrock_get_evaporative(t.id) end
        if (k == "metamorphic_marble") then return DATA.bedrock_get_metamorphic_marble(t.id) end
        if (k == "metamorphic_slate") then return DATA.bedrock_get_metamorphic_slate(t.id) end
        if (k == "oceanic") then return DATA.bedrock_get_oceanic(t.id) end
        if (k == "sedimentary_ocean_deep") then return DATA.bedrock_get_sedimentary_ocean_deep(t.id) end
        if (k == "sedimentary_ocean_shallow") then return DATA.bedrock_get_sedimentary_ocean_shallow(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.bedrock_set_name(t.id, v)
            return
        end
        if (k == "r") then
            DATA.bedrock_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.bedrock_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.bedrock_set_b(t.id, v)
            return
        end
        if (k == "color_id") then
            DATA.bedrock_set_color_id(t.id, v)
            return
        end
        if (k == "sand") then
            DATA.bedrock_set_sand(t.id, v)
            return
        end
        if (k == "silt") then
            DATA.bedrock_set_silt(t.id, v)
            return
        end
        if (k == "clay") then
            DATA.bedrock_set_clay(t.id, v)
            return
        end
        if (k == "organics") then
            DATA.bedrock_set_organics(t.id, v)
            return
        end
        if (k == "minerals") then
            DATA.bedrock_set_minerals(t.id, v)
            return
        end
        if (k == "weathering") then
            DATA.bedrock_set_weathering(t.id, v)
            return
        end
        if (k == "grain_size") then
            DATA.bedrock_set_grain_size(t.id, v)
            return
        end
        if (k == "acidity") then
            DATA.bedrock_set_acidity(t.id, v)
            return
        end
        if (k == "igneous_extrusive") then
            DATA.bedrock_set_igneous_extrusive(t.id, v)
            return
        end
        if (k == "igneous_intrusive") then
            DATA.bedrock_set_igneous_intrusive(t.id, v)
            return
        end
        if (k == "sedimentary") then
            DATA.bedrock_set_sedimentary(t.id, v)
            return
        end
        if (k == "clastic") then
            DATA.bedrock_set_clastic(t.id, v)
            return
        end
        if (k == "evaporative") then
            DATA.bedrock_set_evaporative(t.id, v)
            return
        end
        if (k == "metamorphic_marble") then
            DATA.bedrock_set_metamorphic_marble(t.id, v)
            return
        end
        if (k == "metamorphic_slate") then
            DATA.bedrock_set_metamorphic_slate(t.id, v)
            return
        end
        if (k == "oceanic") then
            DATA.bedrock_set_oceanic(t.id, v)
            return
        end
        if (k == "sedimentary_ocean_deep") then
            DATA.bedrock_set_sedimentary_ocean_deep(t.id, v)
            return
        end
        if (k == "sedimentary_ocean_shallow") then
            DATA.bedrock_set_sedimentary_ocean_shallow(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id bedrock_id
---@return fat_bedrock_id fat_id
function DATA.fatten_bedrock(id)
    local result = {id = id}
    setmetatable(result, fat_bedrock_id_metatable)    return result
end
----------resource----------


---resource: LSP types---

---Unique identificator for resource entity
---@alias resource_id number

---@class fat_resource_id
---@field id resource_id Unique resource id
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field base_frequency number number of tiles per which this resource is spawned
---@field coastal boolean
---@field land boolean
---@field water boolean
---@field ice_age boolean requires presence of ice age ice
---@field minimum_trees number
---@field maximum_trees number
---@field minimum_elevation number
---@field maximum_elevation number

---@class struct_resource
---@field r number
---@field g number
---@field b number
---@field required_biome table<number, biome_id>
---@field required_bedrock table<number, bedrock_id>
---@field base_frequency number number of tiles per which this resource is spawned
---@field minimum_trees number
---@field maximum_trees number
---@field minimum_elevation number
---@field maximum_elevation number

---@class (exact) resource_id_data_blob_definition
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field required_biome biome_id[]
---@field required_bedrock bedrock_id[]
---@field base_frequency number? number of tiles per which this resource is spawned
---@field coastal boolean?
---@field land boolean?
---@field water boolean?
---@field ice_age boolean? requires presence of ice age ice
---@field minimum_trees number?
---@field maximum_trees number?
---@field minimum_elevation number?
---@field maximum_elevation number?
---Sets values of resource for given id
---@param id resource_id
---@param data resource_id_data_blob_definition
function DATA.setup_resource(id, data)
    DATA.resource_set_name(id, data.name)
    DATA.resource_set_icon(id, data.icon)
    DATA.resource_set_description(id, data.description)
    DATA.resource_set_r(id, data.r)
    DATA.resource_set_g(id, data.g)
    DATA.resource_set_b(id, data.b)
    for i, value in ipairs(data.required_biome) do
        DATA.resource_set_required_biome(id, value, i - 1)
    end
    for i, value in ipairs(data.required_bedrock) do
        DATA.resource_set_required_bedrock(id, value, i - 1)
    end
    if data.base_frequency ~= nil then
        DATA.resource_set_base_frequency(id, data.base_frequency)
    end
    if data.coastal ~= nil then
        DATA.resource_set_coastal(id, data.coastal)
    end
    if data.land ~= nil then
        DATA.resource_set_land(id, data.land)
    end
    if data.water ~= nil then
        DATA.resource_set_water(id, data.water)
    end
    if data.ice_age ~= nil then
        DATA.resource_set_ice_age(id, data.ice_age)
    end
    if data.minimum_trees ~= nil then
        DATA.resource_set_minimum_trees(id, data.minimum_trees)
    end
    if data.maximum_trees ~= nil then
        DATA.resource_set_maximum_trees(id, data.maximum_trees)
    end
    if data.minimum_elevation ~= nil then
        DATA.resource_set_minimum_elevation(id, data.minimum_elevation)
    end
    if data.maximum_elevation ~= nil then
        DATA.resource_set_maximum_elevation(id, data.maximum_elevation)
    end
end

ffi.cdef[[
    typedef struct {
        float r;
        float g;
        float b;
        uint32_t required_biome[20];
        uint32_t required_bedrock[20];
        float base_frequency;
        float minimum_trees;
        float maximum_trees;
        float minimum_elevation;
        float maximum_elevation;
    } resource;
]]

---resource: FFI arrays---
---@type (string)[]
DATA.resource_name= {}
---@type (string)[]
DATA.resource_icon= {}
---@type (string)[]
DATA.resource_description= {}
---@type (boolean)[]
DATA.resource_coastal= {}
---@type (boolean)[]
DATA.resource_land= {}
---@type (boolean)[]
DATA.resource_water= {}
---@type (boolean)[]
DATA.resource_ice_age= {}
---@type nil
DATA.resource_malloc = ffi.C.malloc(ffi.sizeof("resource") * 301)
---@type table<resource_id, struct_resource>
DATA.resource = ffi.cast("resource*", DATA.resource_malloc)

---resource: LUA bindings---

DATA.resource_size = 300
---@type table<resource_id, boolean>
local resource_indices_pool = ffi.new("bool[?]", 300)
for i = 1, 299 do
    resource_indices_pool[i] = true
end
---@type table<resource_id, resource_id>
DATA.resource_indices_set = {}
function DATA.create_resource()
    for i = 1, 299 do
        if resource_indices_pool[i] then
            resource_indices_pool[i] = false
            DATA.resource_indices_set[i] = i
            DATA.resource_set_base_frequency(i, 1000)
            DATA.resource_set_coastal(i, false)
            DATA.resource_set_land(i, true)
            DATA.resource_set_water(i, false)
            DATA.resource_set_ice_age(i, false)
            DATA.resource_set_minimum_trees(i, 0)
            DATA.resource_set_maximum_trees(i, 1)
            DATA.resource_set_minimum_elevation(i, -math.huge)
            DATA.resource_set_maximum_elevation(i, math.huge)
            return i
        end
    end
    error("Run out of space for resource")
end
function DATA.delete_resource(i)
    resource_indices_pool[i] = true
    DATA.resource_indices_set[i] = nil
end
---@param func fun(item: resource_id)
function DATA.for_each_resource(func)
    for _, item in pairs(DATA.resource_indices_set) do
        func(item)
    end
end

---@param resource_id resource_id valid resource id
---@return string name
function DATA.resource_get_name(resource_id)
    return DATA.resource_name[resource_id]
end
---@param resource_id resource_id valid resource id
---@param value string valid string
function DATA.resource_set_name(resource_id, value)
    DATA.resource_name[resource_id] = value
end
---@param resource_id resource_id valid resource id
---@return string icon
function DATA.resource_get_icon(resource_id)
    return DATA.resource_icon[resource_id]
end
---@param resource_id resource_id valid resource id
---@param value string valid string
function DATA.resource_set_icon(resource_id, value)
    DATA.resource_icon[resource_id] = value
end
---@param resource_id resource_id valid resource id
---@return string description
function DATA.resource_get_description(resource_id)
    return DATA.resource_description[resource_id]
end
---@param resource_id resource_id valid resource id
---@param value string valid string
function DATA.resource_set_description(resource_id, value)
    DATA.resource_description[resource_id] = value
end
---@param resource_id resource_id valid resource id
---@return number r
function DATA.resource_get_r(resource_id)
    return DATA.resource[resource_id].r
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_r(resource_id, value)
    DATA.resource[resource_id].r = value
end
---@param resource_id resource_id valid resource id
---@return number g
function DATA.resource_get_g(resource_id)
    return DATA.resource[resource_id].g
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_g(resource_id, value)
    DATA.resource[resource_id].g = value
end
---@param resource_id resource_id valid resource id
---@return number b
function DATA.resource_get_b(resource_id)
    return DATA.resource[resource_id].b
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_b(resource_id, value)
    DATA.resource[resource_id].b = value
end
---@param resource_id resource_id valid resource id
---@param index number valid
---@return biome_id required_biome
function DATA.resource_get_required_biome(resource_id, index)
    return DATA.resource[resource_id].required_biome[index]
end
---@param resource_id resource_id valid resource id
---@param index number valid index
---@param value biome_id valid biome_id
function DATA.resource_set_required_biome(resource_id, index, value)
    DATA.resource[resource_id].required_biome[index] = value
end
---@param resource_id resource_id valid resource id
---@param index number valid
---@return bedrock_id required_bedrock
function DATA.resource_get_required_bedrock(resource_id, index)
    return DATA.resource[resource_id].required_bedrock[index]
end
---@param resource_id resource_id valid resource id
---@param index number valid index
---@param value bedrock_id valid bedrock_id
function DATA.resource_set_required_bedrock(resource_id, index, value)
    DATA.resource[resource_id].required_bedrock[index] = value
end
---@param resource_id resource_id valid resource id
---@return number base_frequency number of tiles per which this resource is spawned
function DATA.resource_get_base_frequency(resource_id)
    return DATA.resource[resource_id].base_frequency
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_base_frequency(resource_id, value)
    DATA.resource[resource_id].base_frequency = value
end
---@param resource_id resource_id valid resource id
---@return boolean coastal
function DATA.resource_get_coastal(resource_id)
    return DATA.resource_coastal[resource_id]
end
---@param resource_id resource_id valid resource id
---@param value boolean valid boolean
function DATA.resource_set_coastal(resource_id, value)
    DATA.resource_coastal[resource_id] = value
end
---@param resource_id resource_id valid resource id
---@return boolean land
function DATA.resource_get_land(resource_id)
    return DATA.resource_land[resource_id]
end
---@param resource_id resource_id valid resource id
---@param value boolean valid boolean
function DATA.resource_set_land(resource_id, value)
    DATA.resource_land[resource_id] = value
end
---@param resource_id resource_id valid resource id
---@return boolean water
function DATA.resource_get_water(resource_id)
    return DATA.resource_water[resource_id]
end
---@param resource_id resource_id valid resource id
---@param value boolean valid boolean
function DATA.resource_set_water(resource_id, value)
    DATA.resource_water[resource_id] = value
end
---@param resource_id resource_id valid resource id
---@return boolean ice_age requires presence of ice age ice
function DATA.resource_get_ice_age(resource_id)
    return DATA.resource_ice_age[resource_id]
end
---@param resource_id resource_id valid resource id
---@param value boolean valid boolean
function DATA.resource_set_ice_age(resource_id, value)
    DATA.resource_ice_age[resource_id] = value
end
---@param resource_id resource_id valid resource id
---@return number minimum_trees
function DATA.resource_get_minimum_trees(resource_id)
    return DATA.resource[resource_id].minimum_trees
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_minimum_trees(resource_id, value)
    DATA.resource[resource_id].minimum_trees = value
end
---@param resource_id resource_id valid resource id
---@return number maximum_trees
function DATA.resource_get_maximum_trees(resource_id)
    return DATA.resource[resource_id].maximum_trees
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_maximum_trees(resource_id, value)
    DATA.resource[resource_id].maximum_trees = value
end
---@param resource_id resource_id valid resource id
---@return number minimum_elevation
function DATA.resource_get_minimum_elevation(resource_id)
    return DATA.resource[resource_id].minimum_elevation
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_minimum_elevation(resource_id, value)
    DATA.resource[resource_id].minimum_elevation = value
end
---@param resource_id resource_id valid resource id
---@return number maximum_elevation
function DATA.resource_get_maximum_elevation(resource_id)
    return DATA.resource[resource_id].maximum_elevation
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_maximum_elevation(resource_id, value)
    DATA.resource[resource_id].maximum_elevation = value
end


local fat_resource_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.resource_get_name(t.id) end
        if (k == "icon") then return DATA.resource_get_icon(t.id) end
        if (k == "description") then return DATA.resource_get_description(t.id) end
        if (k == "r") then return DATA.resource_get_r(t.id) end
        if (k == "g") then return DATA.resource_get_g(t.id) end
        if (k == "b") then return DATA.resource_get_b(t.id) end
        if (k == "base_frequency") then return DATA.resource_get_base_frequency(t.id) end
        if (k == "coastal") then return DATA.resource_get_coastal(t.id) end
        if (k == "land") then return DATA.resource_get_land(t.id) end
        if (k == "water") then return DATA.resource_get_water(t.id) end
        if (k == "ice_age") then return DATA.resource_get_ice_age(t.id) end
        if (k == "minimum_trees") then return DATA.resource_get_minimum_trees(t.id) end
        if (k == "maximum_trees") then return DATA.resource_get_maximum_trees(t.id) end
        if (k == "minimum_elevation") then return DATA.resource_get_minimum_elevation(t.id) end
        if (k == "maximum_elevation") then return DATA.resource_get_maximum_elevation(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.resource_set_name(t.id, v)
            return
        end
        if (k == "icon") then
            DATA.resource_set_icon(t.id, v)
            return
        end
        if (k == "description") then
            DATA.resource_set_description(t.id, v)
            return
        end
        if (k == "r") then
            DATA.resource_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.resource_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.resource_set_b(t.id, v)
            return
        end
        if (k == "base_frequency") then
            DATA.resource_set_base_frequency(t.id, v)
            return
        end
        if (k == "coastal") then
            DATA.resource_set_coastal(t.id, v)
            return
        end
        if (k == "land") then
            DATA.resource_set_land(t.id, v)
            return
        end
        if (k == "water") then
            DATA.resource_set_water(t.id, v)
            return
        end
        if (k == "ice_age") then
            DATA.resource_set_ice_age(t.id, v)
            return
        end
        if (k == "minimum_trees") then
            DATA.resource_set_minimum_trees(t.id, v)
            return
        end
        if (k == "maximum_trees") then
            DATA.resource_set_maximum_trees(t.id, v)
            return
        end
        if (k == "minimum_elevation") then
            DATA.resource_set_minimum_elevation(t.id, v)
            return
        end
        if (k == "maximum_elevation") then
            DATA.resource_set_maximum_elevation(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id resource_id
---@return fat_resource_id fat_id
function DATA.fatten_resource(id)
    local result = {id = id}
    setmetatable(result, fat_resource_id_metatable)    return result
end
----------unit_type----------


---unit_type: LSP types---

---Unique identificator for unit_type entity
---@alias unit_type_id number

---@class fat_unit_type_id
---@field id unit_type_id Unique unit_type id
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field base_price number
---@field upkeep number
---@field supply_used number how much food does this unit consume each month
---@field base_health number
---@field base_attack number
---@field base_armor number
---@field speed number
---@field foraging number how much food does this unit forage from the local province?
---@field supply_capacity number how much food can this unit carry
---@field unlocked_by Technology?
---@field spotting number
---@field visibility number

---@class struct_unit_type
---@field r number
---@field g number
---@field b number
---@field base_price number
---@field upkeep number
---@field supply_used number how much food does this unit consume each month
---@field trade_good_requirements table<number, struct_trade_good_container>
---@field base_health number
---@field base_attack number
---@field base_armor number
---@field speed number
---@field foraging number how much food does this unit forage from the local province?
---@field bonuses table<unit_type_id, number>
---@field supply_capacity number how much food can this unit carry
---@field spotting number
---@field visibility number

---@class (exact) unit_type_id_data_blob_definition
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field base_price number?
---@field upkeep number?
---@field supply_used number? how much food does this unit consume each month
---@field trade_good_requirements struct_trade_good_container[]
---@field base_health number?
---@field base_attack number?
---@field base_armor number?
---@field speed number?
---@field foraging number? how much food does this unit forage from the local province?
---@field bonuses number[]
---@field supply_capacity number? how much food can this unit carry
---@field unlocked_by Technology??
---@field spotting number?
---@field visibility number?
---Sets values of unit_type for given id
---@param id unit_type_id
---@param data unit_type_id_data_blob_definition
function DATA.setup_unit_type(id, data)
    DATA.unit_type_set_name(id, data.name)
    DATA.unit_type_set_icon(id, data.icon)
    DATA.unit_type_set_description(id, data.description)
    DATA.unit_type_set_r(id, data.r)
    DATA.unit_type_set_g(id, data.g)
    DATA.unit_type_set_b(id, data.b)
    if data.base_price ~= nil then
        DATA.unit_type_set_base_price(id, data.base_price)
    end
    if data.upkeep ~= nil then
        DATA.unit_type_set_upkeep(id, data.upkeep)
    end
    if data.supply_used ~= nil then
        DATA.unit_type_set_supply_used(id, data.supply_used)
    end
    for i, value in ipairs(data.trade_good_requirements) do
        DATA.unit_type_set_trade_good_requirements(id, value, i - 1)
    end
    if data.base_health ~= nil then
        DATA.unit_type_set_base_health(id, data.base_health)
    end
    if data.base_attack ~= nil then
        DATA.unit_type_set_base_attack(id, data.base_attack)
    end
    if data.base_armor ~= nil then
        DATA.unit_type_set_base_armor(id, data.base_armor)
    end
    if data.speed ~= nil then
        DATA.unit_type_set_speed(id, data.speed)
    end
    if data.foraging ~= nil then
        DATA.unit_type_set_foraging(id, data.foraging)
    end
    for i, value in ipairs(data.bonuses) do
        DATA.unit_type_set_bonuses(id, value, i - 1)
    end
    if data.supply_capacity ~= nil then
        DATA.unit_type_set_supply_capacity(id, data.supply_capacity)
    end
    if data.unlocked_by ~= nil then
        DATA.unit_type_set_unlocked_by(id, data.unlocked_by)
    end
    if data.spotting ~= nil then
        DATA.unit_type_set_spotting(id, data.spotting)
    end
    if data.visibility ~= nil then
        DATA.unit_type_set_visibility(id, data.visibility)
    end
end

ffi.cdef[[
    typedef struct {
        float r;
        float g;
        float b;
        float base_price;
        float upkeep;
        float supply_used;
        trade_good_container trade_good_requirements[10];
        float base_health;
        float base_attack;
        float base_armor;
        float speed;
        float foraging;
        float bonuses[20];
        float supply_capacity;
        float spotting;
        float visibility;
    } unit_type;
]]

---unit_type: FFI arrays---
---@type (string)[]
DATA.unit_type_name= {}
---@type (string)[]
DATA.unit_type_icon= {}
---@type (string)[]
DATA.unit_type_description= {}
---@type (Technology?)[]
DATA.unit_type_unlocked_by= {}
---@type nil
DATA.unit_type_malloc = ffi.C.malloc(ffi.sizeof("unit_type") * 21)
---@type table<unit_type_id, struct_unit_type>
DATA.unit_type = ffi.cast("unit_type*", DATA.unit_type_malloc)

---unit_type: LUA bindings---

DATA.unit_type_size = 20
---@type table<unit_type_id, boolean>
local unit_type_indices_pool = ffi.new("bool[?]", 20)
for i = 1, 19 do
    unit_type_indices_pool[i] = true
end
---@type table<unit_type_id, unit_type_id>
DATA.unit_type_indices_set = {}
function DATA.create_unit_type()
    for i = 1, 19 do
        if unit_type_indices_pool[i] then
            unit_type_indices_pool[i] = false
            DATA.unit_type_indices_set[i] = i
            DATA.unit_type_set_base_price(i, 10)
            DATA.unit_type_set_upkeep(i, 0.5)
            DATA.unit_type_set_supply_used(i, 1)
            DATA.unit_type_set_base_health(i, 50)
            DATA.unit_type_set_base_attack(i, 5)
            DATA.unit_type_set_base_armor(i, 1)
            DATA.unit_type_set_speed(i, 1)
            DATA.unit_type_set_foraging(i, 0.1)
            DATA.unit_type_set_supply_capacity(i, 5)
            DATA.unit_type_set_unlocked_by(i, nil)
            DATA.unit_type_set_spotting(i, 1)
            DATA.unit_type_set_visibility(i, 1)
            return i
        end
    end
    error("Run out of space for unit_type")
end
function DATA.delete_unit_type(i)
    unit_type_indices_pool[i] = true
    DATA.unit_type_indices_set[i] = nil
end
---@param func fun(item: unit_type_id)
function DATA.for_each_unit_type(func)
    for _, item in pairs(DATA.unit_type_indices_set) do
        func(item)
    end
end

---@param unit_type_id unit_type_id valid unit_type id
---@return string name
function DATA.unit_type_get_name(unit_type_id)
    return DATA.unit_type_name[unit_type_id]
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value string valid string
function DATA.unit_type_set_name(unit_type_id, value)
    DATA.unit_type_name[unit_type_id] = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return string icon
function DATA.unit_type_get_icon(unit_type_id)
    return DATA.unit_type_icon[unit_type_id]
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value string valid string
function DATA.unit_type_set_icon(unit_type_id, value)
    DATA.unit_type_icon[unit_type_id] = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return string description
function DATA.unit_type_get_description(unit_type_id)
    return DATA.unit_type_description[unit_type_id]
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value string valid string
function DATA.unit_type_set_description(unit_type_id, value)
    DATA.unit_type_description[unit_type_id] = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number r
function DATA.unit_type_get_r(unit_type_id)
    return DATA.unit_type[unit_type_id].r
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_r(unit_type_id, value)
    DATA.unit_type[unit_type_id].r = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number g
function DATA.unit_type_get_g(unit_type_id)
    return DATA.unit_type[unit_type_id].g
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_g(unit_type_id, value)
    DATA.unit_type[unit_type_id].g = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number b
function DATA.unit_type_get_b(unit_type_id)
    return DATA.unit_type[unit_type_id].b
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_b(unit_type_id, value)
    DATA.unit_type[unit_type_id].b = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number base_price
function DATA.unit_type_get_base_price(unit_type_id)
    return DATA.unit_type[unit_type_id].base_price
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_base_price(unit_type_id, value)
    DATA.unit_type[unit_type_id].base_price = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number upkeep
function DATA.unit_type_get_upkeep(unit_type_id)
    return DATA.unit_type[unit_type_id].upkeep
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_upkeep(unit_type_id, value)
    DATA.unit_type[unit_type_id].upkeep = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number supply_used how much food does this unit consume each month
function DATA.unit_type_get_supply_used(unit_type_id)
    return DATA.unit_type[unit_type_id].supply_used
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_supply_used(unit_type_id, value)
    DATA.unit_type[unit_type_id].supply_used = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index number valid
---@return trade_good_id trade_good_requirements
function DATA.unit_type_get_trade_good_requirements_good(unit_type_id, index)
    return DATA.unit_type[unit_type_id].trade_good_requirements[index].good
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index number valid
---@return number trade_good_requirements
function DATA.unit_type_get_trade_good_requirements_amount(unit_type_id, index)
    return DATA.unit_type[unit_type_id].trade_good_requirements[index].amount
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index number valid index
---@param value trade_good_id valid trade_good_id
function DATA.unit_type_set_trade_good_requirements_good(unit_type_id, index, value)
    DATA.unit_type[unit_type_id].trade_good_requirements[index].good = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index number valid index
---@param value number valid number
function DATA.unit_type_set_trade_good_requirements_amount(unit_type_id, index, value)
    DATA.unit_type[unit_type_id].trade_good_requirements[index].amount = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number base_health
function DATA.unit_type_get_base_health(unit_type_id)
    return DATA.unit_type[unit_type_id].base_health
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_base_health(unit_type_id, value)
    DATA.unit_type[unit_type_id].base_health = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number base_attack
function DATA.unit_type_get_base_attack(unit_type_id)
    return DATA.unit_type[unit_type_id].base_attack
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_base_attack(unit_type_id, value)
    DATA.unit_type[unit_type_id].base_attack = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number base_armor
function DATA.unit_type_get_base_armor(unit_type_id)
    return DATA.unit_type[unit_type_id].base_armor
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_base_armor(unit_type_id, value)
    DATA.unit_type[unit_type_id].base_armor = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number speed
function DATA.unit_type_get_speed(unit_type_id)
    return DATA.unit_type[unit_type_id].speed
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_speed(unit_type_id, value)
    DATA.unit_type[unit_type_id].speed = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number foraging how much food does this unit forage from the local province?
function DATA.unit_type_get_foraging(unit_type_id)
    return DATA.unit_type[unit_type_id].foraging
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_foraging(unit_type_id, value)
    DATA.unit_type[unit_type_id].foraging = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index unit_type_id valid
---@return number bonuses
function DATA.unit_type_get_bonuses(unit_type_id, index)
    return DATA.unit_type[unit_type_id].bonuses[index]
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index unit_type_id valid index
---@param value number valid number
function DATA.unit_type_set_bonuses(unit_type_id, index, value)
    DATA.unit_type[unit_type_id].bonuses[index] = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number supply_capacity how much food can this unit carry
function DATA.unit_type_get_supply_capacity(unit_type_id)
    return DATA.unit_type[unit_type_id].supply_capacity
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_supply_capacity(unit_type_id, value)
    DATA.unit_type[unit_type_id].supply_capacity = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return Technology? unlocked_by
function DATA.unit_type_get_unlocked_by(unit_type_id)
    return DATA.unit_type_unlocked_by[unit_type_id]
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value Technology? valid Technology?
function DATA.unit_type_set_unlocked_by(unit_type_id, value)
    DATA.unit_type_unlocked_by[unit_type_id] = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number spotting
function DATA.unit_type_get_spotting(unit_type_id)
    return DATA.unit_type[unit_type_id].spotting
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_spotting(unit_type_id, value)
    DATA.unit_type[unit_type_id].spotting = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number visibility
function DATA.unit_type_get_visibility(unit_type_id)
    return DATA.unit_type[unit_type_id].visibility
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_visibility(unit_type_id, value)
    DATA.unit_type[unit_type_id].visibility = value
end


local fat_unit_type_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.unit_type_get_name(t.id) end
        if (k == "icon") then return DATA.unit_type_get_icon(t.id) end
        if (k == "description") then return DATA.unit_type_get_description(t.id) end
        if (k == "r") then return DATA.unit_type_get_r(t.id) end
        if (k == "g") then return DATA.unit_type_get_g(t.id) end
        if (k == "b") then return DATA.unit_type_get_b(t.id) end
        if (k == "base_price") then return DATA.unit_type_get_base_price(t.id) end
        if (k == "upkeep") then return DATA.unit_type_get_upkeep(t.id) end
        if (k == "supply_used") then return DATA.unit_type_get_supply_used(t.id) end
        if (k == "base_health") then return DATA.unit_type_get_base_health(t.id) end
        if (k == "base_attack") then return DATA.unit_type_get_base_attack(t.id) end
        if (k == "base_armor") then return DATA.unit_type_get_base_armor(t.id) end
        if (k == "speed") then return DATA.unit_type_get_speed(t.id) end
        if (k == "foraging") then return DATA.unit_type_get_foraging(t.id) end
        if (k == "supply_capacity") then return DATA.unit_type_get_supply_capacity(t.id) end
        if (k == "unlocked_by") then return DATA.unit_type_get_unlocked_by(t.id) end
        if (k == "spotting") then return DATA.unit_type_get_spotting(t.id) end
        if (k == "visibility") then return DATA.unit_type_get_visibility(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.unit_type_set_name(t.id, v)
            return
        end
        if (k == "icon") then
            DATA.unit_type_set_icon(t.id, v)
            return
        end
        if (k == "description") then
            DATA.unit_type_set_description(t.id, v)
            return
        end
        if (k == "r") then
            DATA.unit_type_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.unit_type_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.unit_type_set_b(t.id, v)
            return
        end
        if (k == "base_price") then
            DATA.unit_type_set_base_price(t.id, v)
            return
        end
        if (k == "upkeep") then
            DATA.unit_type_set_upkeep(t.id, v)
            return
        end
        if (k == "supply_used") then
            DATA.unit_type_set_supply_used(t.id, v)
            return
        end
        if (k == "base_health") then
            DATA.unit_type_set_base_health(t.id, v)
            return
        end
        if (k == "base_attack") then
            DATA.unit_type_set_base_attack(t.id, v)
            return
        end
        if (k == "base_armor") then
            DATA.unit_type_set_base_armor(t.id, v)
            return
        end
        if (k == "speed") then
            DATA.unit_type_set_speed(t.id, v)
            return
        end
        if (k == "foraging") then
            DATA.unit_type_set_foraging(t.id, v)
            return
        end
        if (k == "supply_capacity") then
            DATA.unit_type_set_supply_capacity(t.id, v)
            return
        end
        if (k == "unlocked_by") then
            DATA.unit_type_set_unlocked_by(t.id, v)
            return
        end
        if (k == "spotting") then
            DATA.unit_type_set_spotting(t.id, v)
            return
        end
        if (k == "visibility") then
            DATA.unit_type_set_visibility(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id unit_type_id
---@return fat_unit_type_id fat_id
function DATA.fatten_unit_type(id)
    local result = {id = id}
    setmetatable(result, fat_unit_type_id_metatable)    return result
end


function DATA.save_state()
    local current_offset = 0
    local current_shift = 0
    local total_ffi_size = 0
    total_ffi_size = total_ffi_size + ffi.sizeof("tile") * 1500000
    total_ffi_size = total_ffi_size + ffi.sizeof("race") * 15
    total_ffi_size = total_ffi_size + ffi.sizeof("pop") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("province") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("army") * 5000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("army_membership") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_leader") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_recruiter") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_commander") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_location") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_unit") * 50000
    total_ffi_size = total_ffi_size + ffi.sizeof("character_location") * 100000
    total_ffi_size = total_ffi_size + ffi.sizeof("home") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("pop_location") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("outlaw_location") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("tile_province_membership") * 1500000
    total_ffi_size = total_ffi_size + ffi.sizeof("province_neighborhood") * 100000
    total_ffi_size = total_ffi_size + ffi.sizeof("parent_child_relation") * 900000
    total_ffi_size = total_ffi_size + ffi.sizeof("loyalty") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("succession") * 10000
    local current_buffer = ffi.new("uint8_t[?]", total_ffi_size)
    current_shift = ffi.sizeof("tile") * 1500000
    ffi.copy(current_buffer + current_offset, DATA.tile, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("race") * 15
    ffi.copy(current_buffer + current_offset, DATA.race, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("pop") * 300000
    ffi.copy(current_buffer + current_offset, DATA.pop, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("province") * 10000
    ffi.copy(current_buffer + current_offset, DATA.province, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("army") * 5000
    ffi.copy(current_buffer + current_offset, DATA.army, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband") * 10000
    ffi.copy(current_buffer + current_offset, DATA.warband, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("army_membership") * 10000
    ffi.copy(current_buffer + current_offset, DATA.army_membership, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_leader") * 10000
    ffi.copy(current_buffer + current_offset, DATA.warband_leader, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_recruiter") * 10000
    ffi.copy(current_buffer + current_offset, DATA.warband_recruiter, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_commander") * 10000
    ffi.copy(current_buffer + current_offset, DATA.warband_commander, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_location") * 10000
    ffi.copy(current_buffer + current_offset, DATA.warband_location, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_unit") * 50000
    ffi.copy(current_buffer + current_offset, DATA.warband_unit, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("character_location") * 100000
    ffi.copy(current_buffer + current_offset, DATA.character_location, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("home") * 300000
    ffi.copy(current_buffer + current_offset, DATA.home, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("pop_location") * 300000
    ffi.copy(current_buffer + current_offset, DATA.pop_location, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("outlaw_location") * 300000
    ffi.copy(current_buffer + current_offset, DATA.outlaw_location, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("tile_province_membership") * 1500000
    ffi.copy(current_buffer + current_offset, DATA.tile_province_membership, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("province_neighborhood") * 100000
    ffi.copy(current_buffer + current_offset, DATA.province_neighborhood, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("parent_child_relation") * 900000
    ffi.copy(current_buffer + current_offset, DATA.parent_child_relation, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("loyalty") * 10000
    ffi.copy(current_buffer + current_offset, DATA.loyalty, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("succession") * 10000
    ffi.copy(current_buffer + current_offset, DATA.succession, current_shift)
    current_offset = current_offset + current_shift
    assert(love.filesystem.write("gamestatesave.binbeaver", ffi.string(current_buffer, total_ffi_size)))
end
function DATA.load_state()
    local data_love, error = love.filesystem.newFileData("gamestatesave.binbeaver")
    assert(data_love, error)
    local data = ffi.cast("uint8_t*", data_love:getPointer())
    local current_offset = 0
    local current_shift = 0
    local total_ffi_size = 0
    total_ffi_size = total_ffi_size + ffi.sizeof("tile") * 1500000
    total_ffi_size = total_ffi_size + ffi.sizeof("race") * 15
    total_ffi_size = total_ffi_size + ffi.sizeof("pop") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("province") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("army") * 5000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("army_membership") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_leader") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_recruiter") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_commander") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_location") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_unit") * 50000
    total_ffi_size = total_ffi_size + ffi.sizeof("character_location") * 100000
    total_ffi_size = total_ffi_size + ffi.sizeof("home") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("pop_location") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("outlaw_location") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("tile_province_membership") * 1500000
    total_ffi_size = total_ffi_size + ffi.sizeof("province_neighborhood") * 100000
    total_ffi_size = total_ffi_size + ffi.sizeof("parent_child_relation") * 900000
    total_ffi_size = total_ffi_size + ffi.sizeof("loyalty") * 10000
    total_ffi_size = total_ffi_size + ffi.sizeof("succession") * 10000
    current_shift = ffi.sizeof("tile") * 1500000
    ffi.copy(DATA.tile, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("race") * 15
    ffi.copy(DATA.race, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("pop") * 300000
    ffi.copy(DATA.pop, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("province") * 10000
    ffi.copy(DATA.province, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("army") * 5000
    ffi.copy(DATA.army, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband") * 10000
    ffi.copy(DATA.warband, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("army_membership") * 10000
    ffi.copy(DATA.army_membership, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_leader") * 10000
    ffi.copy(DATA.warband_leader, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_recruiter") * 10000
    ffi.copy(DATA.warband_recruiter, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_commander") * 10000
    ffi.copy(DATA.warband_commander, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_location") * 10000
    ffi.copy(DATA.warband_location, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_unit") * 50000
    ffi.copy(DATA.warband_unit, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("character_location") * 100000
    ffi.copy(DATA.character_location, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("home") * 300000
    ffi.copy(DATA.home, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("pop_location") * 300000
    ffi.copy(DATA.pop_location, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("outlaw_location") * 300000
    ffi.copy(DATA.outlaw_location, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("tile_province_membership") * 1500000
    ffi.copy(DATA.tile_province_membership, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("province_neighborhood") * 100000
    ffi.copy(DATA.province_neighborhood, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("parent_child_relation") * 900000
    ffi.copy(DATA.parent_child_relation, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("loyalty") * 10000
    ffi.copy(DATA.loyalty, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("succession") * 10000
    ffi.copy(DATA.succession, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
end
function DATA.test_save_load_0()
    for i = 0, 1500000 do
        DATA.tile[i].is_land = false
    end
    for i = 0, 1500000 do
        DATA.tile[i].is_fresh = false
    end
    for i = 0, 1500000 do
        DATA.tile[i].elevation = -18
    end
    for i = 0, 1500000 do
        DATA.tile[i].grass = -4
    end
    for i = 0, 1500000 do
        DATA.tile[i].shrub = 12
    end
    for i = 0, 1500000 do
        DATA.tile[i].conifer = 11
    end
    for i = 0, 1500000 do
        DATA.tile[i].broadleaf = 5
    end
    for i = 0, 1500000 do
        DATA.tile[i].ideal_grass = -1
    end
    for i = 0, 1500000 do
        DATA.tile[i].ideal_shrub = 10
    end
    for i = 0, 1500000 do
        DATA.tile[i].ideal_conifer = 2
    end
    for i = 0, 1500000 do
        DATA.tile[i].ideal_broadleaf = 17
    end
    for i = 0, 1500000 do
        DATA.tile[i].silt = -7
    end
    for i = 0, 1500000 do
        DATA.tile[i].clay = 12
    end
    for i = 0, 1500000 do
        DATA.tile[i].sand = -12
    end
    for i = 0, 1500000 do
        DATA.tile[i].soil_minerals = -2
    end
    for i = 0, 1500000 do
        DATA.tile[i].soil_organics = -12
    end
    for i = 0, 1500000 do
        DATA.tile[i].january_waterflow = -14
    end
    for i = 0, 1500000 do
        DATA.tile[i].july_waterflow = 19
    end
    for i = 0, 1500000 do
        DATA.tile[i].waterlevel = -4
    end
    for i = 0, 1500000 do
        DATA.tile[i].has_river = true
    end
    for i = 0, 1500000 do
        DATA.tile[i].has_marsh = false
    end
    for i = 0, 1500000 do
        DATA.tile[i].ice = -14
    end
    for i = 0, 1500000 do
        DATA.tile[i].ice_age_ice = -16
    end
    for i = 0, 1500000 do
        DATA.tile[i].debug_r = 1
    end
    for i = 0, 1500000 do
        DATA.tile[i].debug_g = 10
    end
    for i = 0, 1500000 do
        DATA.tile[i].debug_b = 15
    end
    for i = 0, 1500000 do
        DATA.tile[i].real_r = -14
    end
    for i = 0, 1500000 do
        DATA.tile[i].real_g = 2
    end
    for i = 0, 1500000 do
        DATA.tile[i].real_b = 7
    end
    for i = 0, 1500000 do
        DATA.tile[i].pathfinding_index = 10
    end
    for i = 0, 15 do
        DATA.race[i].r = 19
    end
    for i = 0, 15 do
        DATA.race[i].g = 20
    end
    for i = 0, 15 do
        DATA.race[i].b = -7
    end
    for i = 0, 15 do
        DATA.race[i].carrying_capacity_weight = 15
    end
    for i = 0, 15 do
        DATA.race[i].fecundity = 10
    end
    for i = 0, 15 do
        DATA.race[i].spotting = 8
    end
    for i = 0, 15 do
        DATA.race[i].visibility = 13
    end
    for i = 0, 15 do
        DATA.race[i].males_per_hundred_females = -4
    end
    for i = 0, 15 do
        DATA.race[i].child_age = -17
    end
    for i = 0, 15 do
        DATA.race[i].teen_age = 15
    end
    for i = 0, 15 do
        DATA.race[i].adult_age = -20
    end
    for i = 0, 15 do
        DATA.race[i].middle_age = -15
    end
    for i = 0, 15 do
        DATA.race[i].elder_age = 5
    end
    for i = 0, 15 do
        DATA.race[i].max_age = 20
    end
    for i = 0, 15 do
        DATA.race[i].minimum_comfortable_temperature = -20
    end
    for i = 0, 15 do
        DATA.race[i].minimum_absolute_temperature = 19
    end
    for i = 0, 15 do
        DATA.race[i].minimum_comfortable_elevation = 11
    end
    for i = 0, 15 do
        DATA.race[i].female_body_size = 1
    end
    for i = 0, 15 do
        DATA.race[i].male_body_size = -5
    end
    for i = 0, 15 do
    for j = 0, 9 do
        DATA.race[i].female_efficiency[j] = 0
    end
    end
    for i = 0, 15 do
    for j = 0, 9 do
        DATA.race[i].male_efficiency[j] = -16
    end
    end
    for i = 0, 15 do
        DATA.race[i].female_infrastructure_needs = -8
    end
    for i = 0, 15 do
        DATA.race[i].male_infrastructure_needs = 16
    end
    for i = 0, 15 do
    for j = 0, 19 do
        DATA.race[i].female_needs[j].need = 3
    end
    for j = 0, 19 do
        DATA.race[i].female_needs[j].use_case = 7
    end
    for j = 0, 19 do
        DATA.race[i].female_needs[j].required = -11
    end
    end
    for i = 0, 15 do
    for j = 0, 19 do
        DATA.race[i].male_needs[j].need = 7
    end
    for j = 0, 19 do
        DATA.race[i].male_needs[j].use_case = 2
    end
    for j = 0, 19 do
        DATA.race[i].male_needs[j].required = -15
    end
    end
    for i = 0, 15 do
        DATA.race[i].requires_large_river = false
    end
    for i = 0, 15 do
        DATA.race[i].requires_large_forest = false
    end
    for i = 0, 300000 do
        DATA.pop[i].race = 3
    end
    for i = 0, 300000 do
        DATA.pop[i].female = false
    end
    for i = 0, 300000 do
        DATA.pop[i].age = 17
    end
    for i = 0, 300000 do
        DATA.pop[i].savings = -2
    end
    for i = 0, 300000 do
        DATA.pop[i].parent = 3
    end
    for i = 0, 300000 do
        DATA.pop[i].loyalty = 17
    end
    for i = 0, 300000 do
        DATA.pop[i].life_needs_satisfaction = 1
    end
    for i = 0, 300000 do
        DATA.pop[i].basic_needs_satisfaction = 14
    end
    for i = 0, 300000 do
    for j = 0, 19 do
        DATA.pop[i].need_satisfaction[j].need = 3
    end
    for j = 0, 19 do
        DATA.pop[i].need_satisfaction[j].use_case = 19
    end
    for j = 0, 19 do
        DATA.pop[i].need_satisfaction[j].consumed = 15
    end
    for j = 0, 19 do
        DATA.pop[i].need_satisfaction[j].demanded = 17
    end
    end
    for i = 0, 300000 do
    for j = 0, 9 do
        DATA.pop[i].traits[j] = 4
    end
    end
    for i = 0, 300000 do
        DATA.pop[i].successor = 14
    end
    for i = 0, 300000 do
    for j = 0, 99 do
        DATA.pop[i].inventory[j] = -15
    end
    end
    for i = 0, 300000 do
    for j = 0, 99 do
        DATA.pop[i].price_memory[j] = 18
    end
    end
    for i = 0, 300000 do
        DATA.pop[i].forage_ratio = 4
    end
    for i = 0, 300000 do
        DATA.pop[i].work_ratio = 0
    end
    for i = 0, 300000 do
        DATA.pop[i].rank = 1
    end
    for i = 0, 300000 do
    for j = 0, 19 do
        DATA.pop[i].dna[j] = -2
    end
    end
    for i = 0, 10000 do
        DATA.province[i].r = -9
    end
    for i = 0, 10000 do
        DATA.province[i].g = -8
    end
    for i = 0, 10000 do
        DATA.province[i].b = -9
    end
    for i = 0, 10000 do
        DATA.province[i].is_land = true
    end
    for i = 0, 10000 do
        DATA.province[i].province_id = 19
    end
    for i = 0, 10000 do
        DATA.province[i].size = -4
    end
    for i = 0, 10000 do
        DATA.province[i].hydration = 10
    end
    for i = 0, 10000 do
        DATA.province[i].movement_cost = -16
    end
    for i = 0, 10000 do
        DATA.province[i].center = 2
    end
    for i = 0, 10000 do
        DATA.province[i].infrastructure_needed = -12
    end
    for i = 0, 10000 do
        DATA.province[i].infrastructure = -11
    end
    for i = 0, 10000 do
        DATA.province[i].infrastructure_investment = -18
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_production[j] = -15
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_consumption[j] = 14
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_demand[j] = 5
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_storage[j] = 13
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_prices[j] = -3
    end
    end
    for i = 0, 10000 do
        DATA.province[i].local_wealth = 13
    end
    for i = 0, 10000 do
        DATA.province[i].trade_wealth = -5
    end
    for i = 0, 10000 do
        DATA.province[i].local_income = -7
    end
    for i = 0, 10000 do
        DATA.province[i].local_building_upkeep = 17
    end
    for i = 0, 10000 do
        DATA.province[i].foragers = 6
    end
    for i = 0, 10000 do
        DATA.province[i].foragers_water = 17
    end
    for i = 0, 10000 do
        DATA.province[i].foragers_limit = -3
    end
    for i = 0, 10000 do
    for j = 0, 24 do
        DATA.province[i].local_resources[j].resource = 14
    end
    for j = 0, 24 do
        DATA.province[i].local_resources[j].location = 15
    end
    end
    for i = 0, 10000 do
        DATA.province[i].mood = 2
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        DATA.province[i].unit_types[j] = 2
    end
    end
    for i = 0, 10000 do
        DATA.province[i].on_a_river = false
    end
    for i = 0, 10000 do
        DATA.province[i].on_a_forest = true
    end
    for i = 0, 5000 do
        DATA.army[i].destination = 15
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        DATA.warband[i].units_current[j] = 17
    end
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        DATA.warband[i].units_target[j] = 20
    end
    end
    for i = 0, 10000 do
        DATA.warband[i].status = 5
    end
    for i = 0, 10000 do
        DATA.warband[i].idle_stance = 0
    end
    for i = 0, 10000 do
        DATA.warband[i].current_free_time_ratio = -5
    end
    for i = 0, 10000 do
        DATA.warband[i].treasury = -19
    end
    for i = 0, 10000 do
        DATA.warband[i].total_upkeep = -3
    end
    for i = 0, 10000 do
        DATA.warband[i].predicted_upkeep = -13
    end
    for i = 0, 10000 do
        DATA.warband[i].supplies = -6
    end
    for i = 0, 10000 do
        DATA.warband[i].supplies_target_days = 3
    end
    for i = 0, 10000 do
        DATA.warband[i].morale = -10
    end
    for i = 0, 50000 do
        DATA.warband_unit[i].type = 10
    end
    DATA.save_state()
    DATA.load_state()
    local test_passed = true
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].is_land == false
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].is_fresh == false
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].elevation == -18
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].grass == -4
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].shrub == 12
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].conifer == 11
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].broadleaf == 5
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ideal_grass == -1
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ideal_shrub == 10
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ideal_conifer == 2
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ideal_broadleaf == 17
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].silt == -7
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].clay == 12
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].sand == -12
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].soil_minerals == -2
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].soil_organics == -12
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].january_waterflow == -14
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].july_waterflow == 19
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].waterlevel == -4
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].has_river == true
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].has_marsh == false
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ice == -14
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ice_age_ice == -16
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].debug_r == 1
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].debug_g == 10
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].debug_b == 15
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].real_r == -14
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].real_g == 2
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].real_b == 7
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].pathfinding_index == 10
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].r == 19
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].g == 20
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].b == -7
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].carrying_capacity_weight == 15
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].fecundity == 10
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].spotting == 8
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].visibility == 13
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].males_per_hundred_females == -4
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].child_age == -17
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].teen_age == 15
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].adult_age == -20
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].middle_age == -15
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].elder_age == 5
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].max_age == 20
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].minimum_comfortable_temperature == -20
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].minimum_absolute_temperature == 19
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].minimum_comfortable_elevation == 11
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].female_body_size == 1
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].male_body_size == -5
    end
    for i = 0, 15 do
    for j = 0, 9 do
        test_passed = test_passed and DATA.race[i].female_efficiency[j] == 0
    end
    end
    for i = 0, 15 do
    for j = 0, 9 do
        test_passed = test_passed and DATA.race[i].male_efficiency[j] == -16
    end
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].female_infrastructure_needs == -8
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].male_infrastructure_needs == 16
    end
    for i = 0, 15 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].female_needs[j].need == 3
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].female_needs[j].use_case == 7
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].female_needs[j].required == -11
    end
    end
    for i = 0, 15 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].male_needs[j].need == 7
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].male_needs[j].use_case == 2
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].male_needs[j].required == -15
    end
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].requires_large_river == false
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].requires_large_forest == false
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].race == 3
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].female == false
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].age == 17
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].savings == -2
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].parent == 3
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].loyalty == 17
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].life_needs_satisfaction == 1
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].basic_needs_satisfaction == 14
    end
    for i = 0, 300000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].need_satisfaction[j].need == 3
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].need_satisfaction[j].use_case == 19
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].need_satisfaction[j].consumed == 15
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].need_satisfaction[j].demanded == 17
    end
    end
    for i = 0, 300000 do
    for j = 0, 9 do
        test_passed = test_passed and DATA.pop[i].traits[j] == 4
    end
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].successor == 14
    end
    for i = 0, 300000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.pop[i].inventory[j] == -15
    end
    end
    for i = 0, 300000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.pop[i].price_memory[j] == 18
    end
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].forage_ratio == 4
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].work_ratio == 0
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].rank == 1
    end
    for i = 0, 300000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].dna[j] == -2
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].r == -9
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].g == -8
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].b == -9
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].is_land == true
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].province_id == 19
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].size == -4
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].hydration == 10
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].movement_cost == -16
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].center == 2
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].infrastructure_needed == -12
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].infrastructure == -11
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].infrastructure_investment == -18
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_production[j] == -15
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_consumption[j] == 14
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_demand[j] == 5
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_storage[j] == 13
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_prices[j] == -3
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].local_wealth == 13
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].trade_wealth == -5
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].local_income == -7
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].local_building_upkeep == 17
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].foragers == 6
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].foragers_water == 17
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].foragers_limit == -3
    end
    for i = 0, 10000 do
    for j = 0, 24 do
        test_passed = test_passed and DATA.province[i].local_resources[j].resource == 14
    end
    for j = 0, 24 do
        test_passed = test_passed and DATA.province[i].local_resources[j].location == 15
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].mood == 2
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.province[i].unit_types[j] == 2
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].on_a_river == false
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].on_a_forest == true
    end
    for i = 0, 5000 do
        test_passed = test_passed and DATA.army[i].destination == 15
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.warband[i].units_current[j] == 17
    end
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.warband[i].units_target[j] == 20
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].status == 5
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].idle_stance == 0
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].current_free_time_ratio == -5
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].treasury == -19
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].total_upkeep == -3
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].predicted_upkeep == -13
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].supplies == -6
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].supplies_target_days == 3
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].morale == -10
    end
    for i = 0, 50000 do
        test_passed = test_passed and DATA.warband_unit[i].type == 10
    end
    print("SAVE_LOAD_TEST_0:")
    if test_passed then print("PASSED") else print("ERROR") end
end
function DATA.test_set_get_0()
    local fat_id = DATA.fatten_tile(0)
    fat_id.is_land = false
    fat_id.is_fresh = false
    fat_id.elevation = -18
    fat_id.grass = -4
    fat_id.shrub = 12
    fat_id.conifer = 11
    fat_id.broadleaf = 5
    fat_id.ideal_grass = -1
    fat_id.ideal_shrub = 10
    fat_id.ideal_conifer = 2
    fat_id.ideal_broadleaf = 17
    fat_id.silt = -7
    fat_id.clay = 12
    fat_id.sand = -12
    fat_id.soil_minerals = -2
    fat_id.soil_organics = -12
    fat_id.january_waterflow = -14
    fat_id.july_waterflow = 19
    fat_id.waterlevel = -4
    fat_id.has_river = true
    fat_id.has_marsh = false
    fat_id.ice = -14
    fat_id.ice_age_ice = -16
    fat_id.debug_r = 1
    fat_id.debug_g = 10
    fat_id.debug_b = 15
    fat_id.real_r = -14
    fat_id.real_g = 2
    fat_id.real_b = 7
    fat_id.pathfinding_index = 10
    local test_passed = true
    test_passed = test_passed and fat_id.is_land == false
    if not test_passed then print("is_land", false, fat_id.is_land) end
    test_passed = test_passed and fat_id.is_fresh == false
    if not test_passed then print("is_fresh", false, fat_id.is_fresh) end
    test_passed = test_passed and fat_id.elevation == -18
    if not test_passed then print("elevation", -18, fat_id.elevation) end
    test_passed = test_passed and fat_id.grass == -4
    if not test_passed then print("grass", -4, fat_id.grass) end
    test_passed = test_passed and fat_id.shrub == 12
    if not test_passed then print("shrub", 12, fat_id.shrub) end
    test_passed = test_passed and fat_id.conifer == 11
    if not test_passed then print("conifer", 11, fat_id.conifer) end
    test_passed = test_passed and fat_id.broadleaf == 5
    if not test_passed then print("broadleaf", 5, fat_id.broadleaf) end
    test_passed = test_passed and fat_id.ideal_grass == -1
    if not test_passed then print("ideal_grass", -1, fat_id.ideal_grass) end
    test_passed = test_passed and fat_id.ideal_shrub == 10
    if not test_passed then print("ideal_shrub", 10, fat_id.ideal_shrub) end
    test_passed = test_passed and fat_id.ideal_conifer == 2
    if not test_passed then print("ideal_conifer", 2, fat_id.ideal_conifer) end
    test_passed = test_passed and fat_id.ideal_broadleaf == 17
    if not test_passed then print("ideal_broadleaf", 17, fat_id.ideal_broadleaf) end
    test_passed = test_passed and fat_id.silt == -7
    if not test_passed then print("silt", -7, fat_id.silt) end
    test_passed = test_passed and fat_id.clay == 12
    if not test_passed then print("clay", 12, fat_id.clay) end
    test_passed = test_passed and fat_id.sand == -12
    if not test_passed then print("sand", -12, fat_id.sand) end
    test_passed = test_passed and fat_id.soil_minerals == -2
    if not test_passed then print("soil_minerals", -2, fat_id.soil_minerals) end
    test_passed = test_passed and fat_id.soil_organics == -12
    if not test_passed then print("soil_organics", -12, fat_id.soil_organics) end
    test_passed = test_passed and fat_id.january_waterflow == -14
    if not test_passed then print("january_waterflow", -14, fat_id.january_waterflow) end
    test_passed = test_passed and fat_id.july_waterflow == 19
    if not test_passed then print("july_waterflow", 19, fat_id.july_waterflow) end
    test_passed = test_passed and fat_id.waterlevel == -4
    if not test_passed then print("waterlevel", -4, fat_id.waterlevel) end
    test_passed = test_passed and fat_id.has_river == true
    if not test_passed then print("has_river", true, fat_id.has_river) end
    test_passed = test_passed and fat_id.has_marsh == false
    if not test_passed then print("has_marsh", false, fat_id.has_marsh) end
    test_passed = test_passed and fat_id.ice == -14
    if not test_passed then print("ice", -14, fat_id.ice) end
    test_passed = test_passed and fat_id.ice_age_ice == -16
    if not test_passed then print("ice_age_ice", -16, fat_id.ice_age_ice) end
    test_passed = test_passed and fat_id.debug_r == 1
    if not test_passed then print("debug_r", 1, fat_id.debug_r) end
    test_passed = test_passed and fat_id.debug_g == 10
    if not test_passed then print("debug_g", 10, fat_id.debug_g) end
    test_passed = test_passed and fat_id.debug_b == 15
    if not test_passed then print("debug_b", 15, fat_id.debug_b) end
    test_passed = test_passed and fat_id.real_r == -14
    if not test_passed then print("real_r", -14, fat_id.real_r) end
    test_passed = test_passed and fat_id.real_g == 2
    if not test_passed then print("real_g", 2, fat_id.real_g) end
    test_passed = test_passed and fat_id.real_b == 7
    if not test_passed then print("real_b", 7, fat_id.real_b) end
    test_passed = test_passed and fat_id.pathfinding_index == 10
    if not test_passed then print("pathfinding_index", 10, fat_id.pathfinding_index) end
    print("SET_GET_TEST_0_tile:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_race(0)
    fat_id.r = 4
    fat_id.g = 6
    fat_id.b = -18
    fat_id.carrying_capacity_weight = -4
    fat_id.fecundity = 12
    fat_id.spotting = 11
    fat_id.visibility = 5
    fat_id.males_per_hundred_females = -1
    fat_id.child_age = 10
    fat_id.teen_age = 2
    fat_id.adult_age = 17
    fat_id.middle_age = -7
    fat_id.elder_age = 12
    fat_id.max_age = -12
    fat_id.minimum_comfortable_temperature = -2
    fat_id.minimum_absolute_temperature = -12
    fat_id.minimum_comfortable_elevation = -14
    fat_id.female_body_size = 19
    fat_id.male_body_size = -4
    for j = 0, 9 do
        DATA.race[0].female_efficiency[j] = 14
    end
    for j = 0, 9 do
        DATA.race[0].male_efficiency[j] = 18
    end
    fat_id.female_infrastructure_needs = -11
    fat_id.male_infrastructure_needs = -1
    for j = 0, 19 do
        DATA.race[0].female_needs[j].need = 1
    end
    for j = 0, 19 do
        DATA.race[0].female_needs[j].use_case = 2
    end
    for j = 0, 19 do
        DATA.race[0].female_needs[j].required = 1
    end
    for j = 0, 19 do
        DATA.race[0].male_needs[j].need = 7
    end
    for j = 0, 19 do
        DATA.race[0].male_needs[j].use_case = 17
    end
    for j = 0, 19 do
        DATA.race[0].male_needs[j].required = -14
    end
    fat_id.requires_large_river = false
    fat_id.requires_large_forest = false
    local test_passed = true
    test_passed = test_passed and fat_id.r == 4
    if not test_passed then print("r", 4, fat_id.r) end
    test_passed = test_passed and fat_id.g == 6
    if not test_passed then print("g", 6, fat_id.g) end
    test_passed = test_passed and fat_id.b == -18
    if not test_passed then print("b", -18, fat_id.b) end
    test_passed = test_passed and fat_id.carrying_capacity_weight == -4
    if not test_passed then print("carrying_capacity_weight", -4, fat_id.carrying_capacity_weight) end
    test_passed = test_passed and fat_id.fecundity == 12
    if not test_passed then print("fecundity", 12, fat_id.fecundity) end
    test_passed = test_passed and fat_id.spotting == 11
    if not test_passed then print("spotting", 11, fat_id.spotting) end
    test_passed = test_passed and fat_id.visibility == 5
    if not test_passed then print("visibility", 5, fat_id.visibility) end
    test_passed = test_passed and fat_id.males_per_hundred_females == -1
    if not test_passed then print("males_per_hundred_females", -1, fat_id.males_per_hundred_females) end
    test_passed = test_passed and fat_id.child_age == 10
    if not test_passed then print("child_age", 10, fat_id.child_age) end
    test_passed = test_passed and fat_id.teen_age == 2
    if not test_passed then print("teen_age", 2, fat_id.teen_age) end
    test_passed = test_passed and fat_id.adult_age == 17
    if not test_passed then print("adult_age", 17, fat_id.adult_age) end
    test_passed = test_passed and fat_id.middle_age == -7
    if not test_passed then print("middle_age", -7, fat_id.middle_age) end
    test_passed = test_passed and fat_id.elder_age == 12
    if not test_passed then print("elder_age", 12, fat_id.elder_age) end
    test_passed = test_passed and fat_id.max_age == -12
    if not test_passed then print("max_age", -12, fat_id.max_age) end
    test_passed = test_passed and fat_id.minimum_comfortable_temperature == -2
    if not test_passed then print("minimum_comfortable_temperature", -2, fat_id.minimum_comfortable_temperature) end
    test_passed = test_passed and fat_id.minimum_absolute_temperature == -12
    if not test_passed then print("minimum_absolute_temperature", -12, fat_id.minimum_absolute_temperature) end
    test_passed = test_passed and fat_id.minimum_comfortable_elevation == -14
    if not test_passed then print("minimum_comfortable_elevation", -14, fat_id.minimum_comfortable_elevation) end
    test_passed = test_passed and fat_id.female_body_size == 19
    if not test_passed then print("female_body_size", 19, fat_id.female_body_size) end
    test_passed = test_passed and fat_id.male_body_size == -4
    if not test_passed then print("male_body_size", -4, fat_id.male_body_size) end
    for j = 0, 9 do
        test_passed = test_passed and DATA.race[0].female_efficiency[j] == 14
    end
    if not test_passed then print("female_efficiency", 14, DATA.race[0].female_efficiency[0]) end
    for j = 0, 9 do
        test_passed = test_passed and DATA.race[0].male_efficiency[j] == 18
    end
    if not test_passed then print("male_efficiency", 18, DATA.race[0].male_efficiency[0]) end
    test_passed = test_passed and fat_id.female_infrastructure_needs == -11
    if not test_passed then print("female_infrastructure_needs", -11, fat_id.female_infrastructure_needs) end
    test_passed = test_passed and fat_id.male_infrastructure_needs == -1
    if not test_passed then print("male_infrastructure_needs", -1, fat_id.male_infrastructure_needs) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].female_needs[j].need == 1
    end
    if not test_passed then print("female_needs.need", 1, DATA.race[0].female_needs[0].need) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].female_needs[j].use_case == 2
    end
    if not test_passed then print("female_needs.use_case", 2, DATA.race[0].female_needs[0].use_case) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].female_needs[j].required == 1
    end
    if not test_passed then print("female_needs.required", 1, DATA.race[0].female_needs[0].required) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].male_needs[j].need == 7
    end
    if not test_passed then print("male_needs.need", 7, DATA.race[0].male_needs[0].need) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].male_needs[j].use_case == 17
    end
    if not test_passed then print("male_needs.use_case", 17, DATA.race[0].male_needs[0].use_case) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].male_needs[j].required == -14
    end
    if not test_passed then print("male_needs.required", -14, DATA.race[0].male_needs[0].required) end
    test_passed = test_passed and fat_id.requires_large_river == false
    if not test_passed then print("requires_large_river", false, fat_id.requires_large_river) end
    test_passed = test_passed and fat_id.requires_large_forest == false
    if not test_passed then print("requires_large_forest", false, fat_id.requires_large_forest) end
    print("SET_GET_TEST_0_race:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_pop(0)
    fat_id.race = 12
    fat_id.female = false
    fat_id.age = 1
    fat_id.savings = -4
    fat_id.parent = 16
    fat_id.loyalty = 15
    fat_id.life_needs_satisfaction = 5
    fat_id.basic_needs_satisfaction = -1
    for j = 0, 19 do
        DATA.pop[0].need_satisfaction[j].need = 7
    end
    for j = 0, 19 do
        DATA.pop[0].need_satisfaction[j].use_case = 11
    end
    for j = 0, 19 do
        DATA.pop[0].need_satisfaction[j].consumed = 17
    end
    for j = 0, 19 do
        DATA.pop[0].need_satisfaction[j].demanded = -7
    end
    for j = 0, 9 do
        DATA.pop[0].traits[j] = 8
    end
    fat_id.successor = 4
    for j = 0, 99 do
        DATA.pop[0].inventory[j] = -2
    end
    for j = 0, 99 do
        DATA.pop[0].price_memory[j] = -12
    end
    fat_id.forage_ratio = -14
    fat_id.work_ratio = 19
    fat_id.rank = 2
    for j = 0, 19 do
        DATA.pop[0].dna[j] = 14
    end
    local test_passed = true
    test_passed = test_passed and fat_id.race == 12
    if not test_passed then print("race", 12, fat_id.race) end
    test_passed = test_passed and fat_id.female == false
    if not test_passed then print("female", false, fat_id.female) end
    test_passed = test_passed and fat_id.age == 1
    if not test_passed then print("age", 1, fat_id.age) end
    test_passed = test_passed and fat_id.savings == -4
    if not test_passed then print("savings", -4, fat_id.savings) end
    test_passed = test_passed and fat_id.parent == 16
    if not test_passed then print("parent", 16, fat_id.parent) end
    test_passed = test_passed and fat_id.loyalty == 15
    if not test_passed then print("loyalty", 15, fat_id.loyalty) end
    test_passed = test_passed and fat_id.life_needs_satisfaction == 5
    if not test_passed then print("life_needs_satisfaction", 5, fat_id.life_needs_satisfaction) end
    test_passed = test_passed and fat_id.basic_needs_satisfaction == -1
    if not test_passed then print("basic_needs_satisfaction", -1, fat_id.basic_needs_satisfaction) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].need_satisfaction[j].need == 7
    end
    if not test_passed then print("need_satisfaction.need", 7, DATA.pop[0].need_satisfaction[0].need) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].need_satisfaction[j].use_case == 11
    end
    if not test_passed then print("need_satisfaction.use_case", 11, DATA.pop[0].need_satisfaction[0].use_case) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].need_satisfaction[j].consumed == 17
    end
    if not test_passed then print("need_satisfaction.consumed", 17, DATA.pop[0].need_satisfaction[0].consumed) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].need_satisfaction[j].demanded == -7
    end
    if not test_passed then print("need_satisfaction.demanded", -7, DATA.pop[0].need_satisfaction[0].demanded) end
    for j = 0, 9 do
        test_passed = test_passed and DATA.pop[0].traits[j] == 8
    end
    if not test_passed then print("traits", 8, DATA.pop[0].traits[0]) end
    test_passed = test_passed and fat_id.successor == 4
    if not test_passed then print("successor", 4, fat_id.successor) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.pop[0].inventory[j] == -2
    end
    if not test_passed then print("inventory", -2, DATA.pop[0].inventory[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.pop[0].price_memory[j] == -12
    end
    if not test_passed then print("price_memory", -12, DATA.pop[0].price_memory[0]) end
    test_passed = test_passed and fat_id.forage_ratio == -14
    if not test_passed then print("forage_ratio", -14, fat_id.forage_ratio) end
    test_passed = test_passed and fat_id.work_ratio == 19
    if not test_passed then print("work_ratio", 19, fat_id.work_ratio) end
    test_passed = test_passed and fat_id.rank == 2
    if not test_passed then print("rank", 2, fat_id.rank) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].dna[j] == 14
    end
    if not test_passed then print("dna", 14, DATA.pop[0].dna[0]) end
    print("SET_GET_TEST_0_pop:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_province(0)
    fat_id.r = 4
    fat_id.g = 6
    fat_id.b = -18
    fat_id.is_land = false
    fat_id.province_id = 12
    fat_id.size = 11
    fat_id.hydration = 5
    fat_id.movement_cost = -1
    fat_id.center = 15
    fat_id.infrastructure_needed = 2
    fat_id.infrastructure = 17
    fat_id.infrastructure_investment = -7
    for j = 0, 99 do
        DATA.province[0].local_production[j] = 12
    end
    for j = 0, 99 do
        DATA.province[0].local_consumption[j] = -12
    end
    for j = 0, 99 do
        DATA.province[0].local_demand[j] = -2
    end
    for j = 0, 99 do
        DATA.province[0].local_storage[j] = -12
    end
    for j = 0, 99 do
        DATA.province[0].local_prices[j] = -14
    end
    fat_id.local_wealth = 19
    fat_id.trade_wealth = -4
    fat_id.local_income = 14
    fat_id.local_building_upkeep = 18
    fat_id.foragers = -11
    fat_id.foragers_water = -1
    fat_id.foragers_limit = -14
    for j = 0, 24 do
        DATA.province[0].local_resources[j].resource = 2
    end
    for j = 0, 24 do
        DATA.province[0].local_resources[j].location = 10
    end
    fat_id.mood = 10
    for j = 0, 19 do
        DATA.province[0].unit_types[j] = 17
    end
    fat_id.on_a_river = true
    fat_id.on_a_forest = false
    local test_passed = true
    test_passed = test_passed and fat_id.r == 4
    if not test_passed then print("r", 4, fat_id.r) end
    test_passed = test_passed and fat_id.g == 6
    if not test_passed then print("g", 6, fat_id.g) end
    test_passed = test_passed and fat_id.b == -18
    if not test_passed then print("b", -18, fat_id.b) end
    test_passed = test_passed and fat_id.is_land == false
    if not test_passed then print("is_land", false, fat_id.is_land) end
    test_passed = test_passed and fat_id.province_id == 12
    if not test_passed then print("province_id", 12, fat_id.province_id) end
    test_passed = test_passed and fat_id.size == 11
    if not test_passed then print("size", 11, fat_id.size) end
    test_passed = test_passed and fat_id.hydration == 5
    if not test_passed then print("hydration", 5, fat_id.hydration) end
    test_passed = test_passed and fat_id.movement_cost == -1
    if not test_passed then print("movement_cost", -1, fat_id.movement_cost) end
    test_passed = test_passed and fat_id.center == 15
    if not test_passed then print("center", 15, fat_id.center) end
    test_passed = test_passed and fat_id.infrastructure_needed == 2
    if not test_passed then print("infrastructure_needed", 2, fat_id.infrastructure_needed) end
    test_passed = test_passed and fat_id.infrastructure == 17
    if not test_passed then print("infrastructure", 17, fat_id.infrastructure) end
    test_passed = test_passed and fat_id.infrastructure_investment == -7
    if not test_passed then print("infrastructure_investment", -7, fat_id.infrastructure_investment) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_production[j] == 12
    end
    if not test_passed then print("local_production", 12, DATA.province[0].local_production[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_consumption[j] == -12
    end
    if not test_passed then print("local_consumption", -12, DATA.province[0].local_consumption[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_demand[j] == -2
    end
    if not test_passed then print("local_demand", -2, DATA.province[0].local_demand[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_storage[j] == -12
    end
    if not test_passed then print("local_storage", -12, DATA.province[0].local_storage[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_prices[j] == -14
    end
    if not test_passed then print("local_prices", -14, DATA.province[0].local_prices[0]) end
    test_passed = test_passed and fat_id.local_wealth == 19
    if not test_passed then print("local_wealth", 19, fat_id.local_wealth) end
    test_passed = test_passed and fat_id.trade_wealth == -4
    if not test_passed then print("trade_wealth", -4, fat_id.trade_wealth) end
    test_passed = test_passed and fat_id.local_income == 14
    if not test_passed then print("local_income", 14, fat_id.local_income) end
    test_passed = test_passed and fat_id.local_building_upkeep == 18
    if not test_passed then print("local_building_upkeep", 18, fat_id.local_building_upkeep) end
    test_passed = test_passed and fat_id.foragers == -11
    if not test_passed then print("foragers", -11, fat_id.foragers) end
    test_passed = test_passed and fat_id.foragers_water == -1
    if not test_passed then print("foragers_water", -1, fat_id.foragers_water) end
    test_passed = test_passed and fat_id.foragers_limit == -14
    if not test_passed then print("foragers_limit", -14, fat_id.foragers_limit) end
    for j = 0, 24 do
        test_passed = test_passed and DATA.province[0].local_resources[j].resource == 2
    end
    if not test_passed then print("local_resources.resource", 2, DATA.province[0].local_resources[0].resource) end
    for j = 0, 24 do
        test_passed = test_passed and DATA.province[0].local_resources[j].location == 10
    end
    if not test_passed then print("local_resources.location", 10, DATA.province[0].local_resources[0].location) end
    test_passed = test_passed and fat_id.mood == 10
    if not test_passed then print("mood", 10, fat_id.mood) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.province[0].unit_types[j] == 17
    end
    if not test_passed then print("unit_types", 17, DATA.province[0].unit_types[0]) end
    test_passed = test_passed and fat_id.on_a_river == true
    if not test_passed then print("on_a_river", true, fat_id.on_a_river) end
    test_passed = test_passed and fat_id.on_a_forest == false
    if not test_passed then print("on_a_forest", false, fat_id.on_a_forest) end
    print("SET_GET_TEST_0_province:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_army(0)
    fat_id.destination = 12
    local test_passed = true
    test_passed = test_passed and fat_id.destination == 12
    if not test_passed then print("destination", 12, fat_id.destination) end
    print("SET_GET_TEST_0_army:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband(0)
    for j = 0, 19 do
        DATA.warband[0].units_current[j] = 4
    end
    for j = 0, 19 do
        DATA.warband[0].units_target[j] = 6
    end
    fat_id.status = 0
    fat_id.idle_stance = 1
    fat_id.current_free_time_ratio = 12
    fat_id.treasury = 11
    fat_id.total_upkeep = 5
    fat_id.predicted_upkeep = -1
    fat_id.supplies = 10
    fat_id.supplies_target_days = 2
    fat_id.morale = 17
    local test_passed = true
    for j = 0, 19 do
        test_passed = test_passed and DATA.warband[0].units_current[j] == 4
    end
    if not test_passed then print("units_current", 4, DATA.warband[0].units_current[0]) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.warband[0].units_target[j] == 6
    end
    if not test_passed then print("units_target", 6, DATA.warband[0].units_target[0]) end
    test_passed = test_passed and fat_id.status == 0
    if not test_passed then print("status", 0, fat_id.status) end
    test_passed = test_passed and fat_id.idle_stance == 1
    if not test_passed then print("idle_stance", 1, fat_id.idle_stance) end
    test_passed = test_passed and fat_id.current_free_time_ratio == 12
    if not test_passed then print("current_free_time_ratio", 12, fat_id.current_free_time_ratio) end
    test_passed = test_passed and fat_id.treasury == 11
    if not test_passed then print("treasury", 11, fat_id.treasury) end
    test_passed = test_passed and fat_id.total_upkeep == 5
    if not test_passed then print("total_upkeep", 5, fat_id.total_upkeep) end
    test_passed = test_passed and fat_id.predicted_upkeep == -1
    if not test_passed then print("predicted_upkeep", -1, fat_id.predicted_upkeep) end
    test_passed = test_passed and fat_id.supplies == 10
    if not test_passed then print("supplies", 10, fat_id.supplies) end
    test_passed = test_passed and fat_id.supplies_target_days == 2
    if not test_passed then print("supplies_target_days", 2, fat_id.supplies_target_days) end
    test_passed = test_passed and fat_id.morale == 17
    if not test_passed then print("morale", 17, fat_id.morale) end
    print("SET_GET_TEST_0_warband:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_army_membership(0)
    local test_passed = true
    print("SET_GET_TEST_0_army_membership:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_leader(0)
    local test_passed = true
    print("SET_GET_TEST_0_warband_leader:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_recruiter(0)
    local test_passed = true
    print("SET_GET_TEST_0_warband_recruiter:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_commander(0)
    local test_passed = true
    print("SET_GET_TEST_0_warband_commander:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_location(0)
    local test_passed = true
    print("SET_GET_TEST_0_warband_location:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_unit(0)
    fat_id.type = 12
    local test_passed = true
    test_passed = test_passed and fat_id.type == 12
    if not test_passed then print("type", 12, fat_id.type) end
    print("SET_GET_TEST_0_warband_unit:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_character_location(0)
    local test_passed = true
    print("SET_GET_TEST_0_character_location:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_home(0)
    local test_passed = true
    print("SET_GET_TEST_0_home:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_pop_location(0)
    local test_passed = true
    print("SET_GET_TEST_0_pop_location:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_outlaw_location(0)
    local test_passed = true
    print("SET_GET_TEST_0_outlaw_location:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_tile_province_membership(0)
    local test_passed = true
    print("SET_GET_TEST_0_tile_province_membership:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_province_neighborhood(0)
    local test_passed = true
    print("SET_GET_TEST_0_province_neighborhood:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_parent_child_relation(0)
    local test_passed = true
    print("SET_GET_TEST_0_parent_child_relation:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_loyalty(0)
    local test_passed = true
    print("SET_GET_TEST_0_loyalty:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_succession(0)
    local test_passed = true
    print("SET_GET_TEST_0_succession:")
    if test_passed then print("PASSED") else print("ERROR") end
end
function DATA.test_save_load_1()
    for i = 0, 1500000 do
        DATA.tile[i].is_land = true
    end
    for i = 0, 1500000 do
        DATA.tile[i].is_fresh = true
    end
    for i = 0, 1500000 do
        DATA.tile[i].elevation = -4
    end
    for i = 0, 1500000 do
        DATA.tile[i].grass = -13
    end
    for i = 0, 1500000 do
        DATA.tile[i].shrub = 11
    end
    for i = 0, 1500000 do
        DATA.tile[i].conifer = 8
    end
    for i = 0, 1500000 do
        DATA.tile[i].broadleaf = 10
    end
    for i = 0, 1500000 do
        DATA.tile[i].ideal_grass = 4
    end
    for i = 0, 1500000 do
        DATA.tile[i].ideal_shrub = -7
    end
    for i = 0, 1500000 do
        DATA.tile[i].ideal_conifer = -14
    end
    for i = 0, 1500000 do
        DATA.tile[i].ideal_broadleaf = 11
    end
    for i = 0, 1500000 do
        DATA.tile[i].silt = -19
    end
    for i = 0, 1500000 do
        DATA.tile[i].clay = 4
    end
    for i = 0, 1500000 do
        DATA.tile[i].sand = 7
    end
    for i = 0, 1500000 do
        DATA.tile[i].soil_minerals = 18
    end
    for i = 0, 1500000 do
        DATA.tile[i].soil_organics = -20
    end
    for i = 0, 1500000 do
        DATA.tile[i].january_waterflow = 8
    end
    for i = 0, 1500000 do
        DATA.tile[i].july_waterflow = -3
    end
    for i = 0, 1500000 do
        DATA.tile[i].waterlevel = -6
    end
    for i = 0, 1500000 do
        DATA.tile[i].has_river = true
    end
    for i = 0, 1500000 do
        DATA.tile[i].has_marsh = false
    end
    for i = 0, 1500000 do
        DATA.tile[i].ice = -19
    end
    for i = 0, 1500000 do
        DATA.tile[i].ice_age_ice = -19
    end
    for i = 0, 1500000 do
        DATA.tile[i].debug_r = -19
    end
    for i = 0, 1500000 do
        DATA.tile[i].debug_g = 14
    end
    for i = 0, 1500000 do
        DATA.tile[i].debug_b = -20
    end
    for i = 0, 1500000 do
        DATA.tile[i].real_r = 4
    end
    for i = 0, 1500000 do
        DATA.tile[i].real_g = -7
    end
    for i = 0, 1500000 do
        DATA.tile[i].real_b = 7
    end
    for i = 0, 1500000 do
        DATA.tile[i].pathfinding_index = 0
    end
    for i = 0, 15 do
        DATA.race[i].r = 13
    end
    for i = 0, 15 do
        DATA.race[i].g = -6
    end
    for i = 0, 15 do
        DATA.race[i].b = 8
    end
    for i = 0, 15 do
        DATA.race[i].carrying_capacity_weight = 11
    end
    for i = 0, 15 do
        DATA.race[i].fecundity = 15
    end
    for i = 0, 15 do
        DATA.race[i].spotting = -6
    end
    for i = 0, 15 do
        DATA.race[i].visibility = 2
    end
    for i = 0, 15 do
        DATA.race[i].males_per_hundred_females = -6
    end
    for i = 0, 15 do
        DATA.race[i].child_age = -6
    end
    for i = 0, 15 do
        DATA.race[i].teen_age = 9
    end
    for i = 0, 15 do
        DATA.race[i].adult_age = -2
    end
    for i = 0, 15 do
        DATA.race[i].middle_age = -19
    end
    for i = 0, 15 do
        DATA.race[i].elder_age = 6
    end
    for i = 0, 15 do
        DATA.race[i].max_age = 15
    end
    for i = 0, 15 do
        DATA.race[i].minimum_comfortable_temperature = -14
    end
    for i = 0, 15 do
        DATA.race[i].minimum_absolute_temperature = -9
    end
    for i = 0, 15 do
        DATA.race[i].minimum_comfortable_elevation = 20
    end
    for i = 0, 15 do
        DATA.race[i].female_body_size = -2
    end
    for i = 0, 15 do
        DATA.race[i].male_body_size = -13
    end
    for i = 0, 15 do
    for j = 0, 9 do
        DATA.race[i].female_efficiency[j] = 1
    end
    end
    for i = 0, 15 do
    for j = 0, 9 do
        DATA.race[i].male_efficiency[j] = 12
    end
    end
    for i = 0, 15 do
        DATA.race[i].female_infrastructure_needs = 7
    end
    for i = 0, 15 do
        DATA.race[i].male_infrastructure_needs = 12
    end
    for i = 0, 15 do
    for j = 0, 19 do
        DATA.race[i].female_needs[j].need = 3
    end
    for j = 0, 19 do
        DATA.race[i].female_needs[j].use_case = 9
    end
    for j = 0, 19 do
        DATA.race[i].female_needs[j].required = -2
    end
    end
    for i = 0, 15 do
    for j = 0, 19 do
        DATA.race[i].male_needs[j].need = 7
    end
    for j = 0, 19 do
        DATA.race[i].male_needs[j].use_case = 16
    end
    for j = 0, 19 do
        DATA.race[i].male_needs[j].required = 5
    end
    end
    for i = 0, 15 do
        DATA.race[i].requires_large_river = true
    end
    for i = 0, 15 do
        DATA.race[i].requires_large_forest = false
    end
    for i = 0, 300000 do
        DATA.pop[i].race = 7
    end
    for i = 0, 300000 do
        DATA.pop[i].female = false
    end
    for i = 0, 300000 do
        DATA.pop[i].age = 13
    end
    for i = 0, 300000 do
        DATA.pop[i].savings = -9
    end
    for i = 0, 300000 do
        DATA.pop[i].parent = 11
    end
    for i = 0, 300000 do
        DATA.pop[i].loyalty = 17
    end
    for i = 0, 300000 do
        DATA.pop[i].life_needs_satisfaction = 3
    end
    for i = 0, 300000 do
        DATA.pop[i].basic_needs_satisfaction = -15
    end
    for i = 0, 300000 do
    for j = 0, 19 do
        DATA.pop[i].need_satisfaction[j].need = 7
    end
    for j = 0, 19 do
        DATA.pop[i].need_satisfaction[j].use_case = 16
    end
    for j = 0, 19 do
        DATA.pop[i].need_satisfaction[j].consumed = -14
    end
    for j = 0, 19 do
        DATA.pop[i].need_satisfaction[j].demanded = -10
    end
    end
    for i = 0, 300000 do
    for j = 0, 9 do
        DATA.pop[i].traits[j] = 8
    end
    end
    for i = 0, 300000 do
        DATA.pop[i].successor = 12
    end
    for i = 0, 300000 do
    for j = 0, 99 do
        DATA.pop[i].inventory[j] = 3
    end
    end
    for i = 0, 300000 do
    for j = 0, 99 do
        DATA.pop[i].price_memory[j] = 11
    end
    end
    for i = 0, 300000 do
        DATA.pop[i].forage_ratio = -19
    end
    for i = 0, 300000 do
        DATA.pop[i].work_ratio = 10
    end
    for i = 0, 300000 do
        DATA.pop[i].rank = 0
    end
    for i = 0, 300000 do
    for j = 0, 19 do
        DATA.pop[i].dna[j] = -1
    end
    end
    for i = 0, 10000 do
        DATA.province[i].r = 19
    end
    for i = 0, 10000 do
        DATA.province[i].g = 17
    end
    for i = 0, 10000 do
        DATA.province[i].b = 17
    end
    for i = 0, 10000 do
        DATA.province[i].is_land = false
    end
    for i = 0, 10000 do
        DATA.province[i].province_id = -10
    end
    for i = 0, 10000 do
        DATA.province[i].size = -10
    end
    for i = 0, 10000 do
        DATA.province[i].hydration = 12
    end
    for i = 0, 10000 do
        DATA.province[i].movement_cost = -6
    end
    for i = 0, 10000 do
        DATA.province[i].center = 0
    end
    for i = 0, 10000 do
        DATA.province[i].infrastructure_needed = -8
    end
    for i = 0, 10000 do
        DATA.province[i].infrastructure = 14
    end
    for i = 0, 10000 do
        DATA.province[i].infrastructure_investment = 15
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_production[j] = -6
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_consumption[j] = 5
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_demand[j] = 12
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_storage[j] = 2
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_prices[j] = 16
    end
    end
    for i = 0, 10000 do
        DATA.province[i].local_wealth = 2
    end
    for i = 0, 10000 do
        DATA.province[i].trade_wealth = 9
    end
    for i = 0, 10000 do
        DATA.province[i].local_income = -3
    end
    for i = 0, 10000 do
        DATA.province[i].local_building_upkeep = 15
    end
    for i = 0, 10000 do
        DATA.province[i].foragers = 18
    end
    for i = 0, 10000 do
        DATA.province[i].foragers_water = -20
    end
    for i = 0, 10000 do
        DATA.province[i].foragers_limit = 4
    end
    for i = 0, 10000 do
    for j = 0, 24 do
        DATA.province[i].local_resources[j].resource = 16
    end
    for j = 0, 24 do
        DATA.province[i].local_resources[j].location = 4
    end
    end
    for i = 0, 10000 do
        DATA.province[i].mood = 13
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        DATA.province[i].unit_types[j] = 17
    end
    end
    for i = 0, 10000 do
        DATA.province[i].on_a_river = true
    end
    for i = 0, 10000 do
        DATA.province[i].on_a_forest = false
    end
    for i = 0, 5000 do
        DATA.army[i].destination = 1
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        DATA.warband[i].units_current[j] = 10
    end
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        DATA.warband[i].units_target[j] = 3
    end
    end
    for i = 0, 10000 do
        DATA.warband[i].status = 8
    end
    for i = 0, 10000 do
        DATA.warband[i].idle_stance = 0
    end
    for i = 0, 10000 do
        DATA.warband[i].current_free_time_ratio = 12
    end
    for i = 0, 10000 do
        DATA.warband[i].treasury = 6
    end
    for i = 0, 10000 do
        DATA.warband[i].total_upkeep = 11
    end
    for i = 0, 10000 do
        DATA.warband[i].predicted_upkeep = 2
    end
    for i = 0, 10000 do
        DATA.warband[i].supplies = 6
    end
    for i = 0, 10000 do
        DATA.warband[i].supplies_target_days = 2
    end
    for i = 0, 10000 do
        DATA.warband[i].morale = -20
    end
    for i = 0, 50000 do
        DATA.warband_unit[i].type = 17
    end
    DATA.save_state()
    DATA.load_state()
    local test_passed = true
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].is_land == true
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].is_fresh == true
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].elevation == -4
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].grass == -13
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].shrub == 11
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].conifer == 8
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].broadleaf == 10
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ideal_grass == 4
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ideal_shrub == -7
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ideal_conifer == -14
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ideal_broadleaf == 11
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].silt == -19
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].clay == 4
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].sand == 7
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].soil_minerals == 18
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].soil_organics == -20
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].january_waterflow == 8
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].july_waterflow == -3
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].waterlevel == -6
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].has_river == true
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].has_marsh == false
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ice == -19
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ice_age_ice == -19
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].debug_r == -19
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].debug_g == 14
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].debug_b == -20
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].real_r == 4
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].real_g == -7
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].real_b == 7
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].pathfinding_index == 0
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].r == 13
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].g == -6
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].b == 8
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].carrying_capacity_weight == 11
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].fecundity == 15
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].spotting == -6
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].visibility == 2
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].males_per_hundred_females == -6
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].child_age == -6
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].teen_age == 9
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].adult_age == -2
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].middle_age == -19
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].elder_age == 6
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].max_age == 15
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].minimum_comfortable_temperature == -14
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].minimum_absolute_temperature == -9
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].minimum_comfortable_elevation == 20
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].female_body_size == -2
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].male_body_size == -13
    end
    for i = 0, 15 do
    for j = 0, 9 do
        test_passed = test_passed and DATA.race[i].female_efficiency[j] == 1
    end
    end
    for i = 0, 15 do
    for j = 0, 9 do
        test_passed = test_passed and DATA.race[i].male_efficiency[j] == 12
    end
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].female_infrastructure_needs == 7
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].male_infrastructure_needs == 12
    end
    for i = 0, 15 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].female_needs[j].need == 3
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].female_needs[j].use_case == 9
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].female_needs[j].required == -2
    end
    end
    for i = 0, 15 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].male_needs[j].need == 7
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].male_needs[j].use_case == 16
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].male_needs[j].required == 5
    end
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].requires_large_river == true
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].requires_large_forest == false
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].race == 7
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].female == false
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].age == 13
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].savings == -9
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].parent == 11
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].loyalty == 17
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].life_needs_satisfaction == 3
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].basic_needs_satisfaction == -15
    end
    for i = 0, 300000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].need_satisfaction[j].need == 7
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].need_satisfaction[j].use_case == 16
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].need_satisfaction[j].consumed == -14
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].need_satisfaction[j].demanded == -10
    end
    end
    for i = 0, 300000 do
    for j = 0, 9 do
        test_passed = test_passed and DATA.pop[i].traits[j] == 8
    end
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].successor == 12
    end
    for i = 0, 300000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.pop[i].inventory[j] == 3
    end
    end
    for i = 0, 300000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.pop[i].price_memory[j] == 11
    end
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].forage_ratio == -19
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].work_ratio == 10
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].rank == 0
    end
    for i = 0, 300000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].dna[j] == -1
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].r == 19
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].g == 17
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].b == 17
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].is_land == false
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].province_id == -10
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].size == -10
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].hydration == 12
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].movement_cost == -6
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].center == 0
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].infrastructure_needed == -8
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].infrastructure == 14
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].infrastructure_investment == 15
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_production[j] == -6
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_consumption[j] == 5
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_demand[j] == 12
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_storage[j] == 2
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_prices[j] == 16
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].local_wealth == 2
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].trade_wealth == 9
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].local_income == -3
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].local_building_upkeep == 15
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].foragers == 18
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].foragers_water == -20
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].foragers_limit == 4
    end
    for i = 0, 10000 do
    for j = 0, 24 do
        test_passed = test_passed and DATA.province[i].local_resources[j].resource == 16
    end
    for j = 0, 24 do
        test_passed = test_passed and DATA.province[i].local_resources[j].location == 4
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].mood == 13
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.province[i].unit_types[j] == 17
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].on_a_river == true
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].on_a_forest == false
    end
    for i = 0, 5000 do
        test_passed = test_passed and DATA.army[i].destination == 1
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.warband[i].units_current[j] == 10
    end
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.warband[i].units_target[j] == 3
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].status == 8
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].idle_stance == 0
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].current_free_time_ratio == 12
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].treasury == 6
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].total_upkeep == 11
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].predicted_upkeep == 2
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].supplies == 6
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].supplies_target_days == 2
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].morale == -20
    end
    for i = 0, 50000 do
        test_passed = test_passed and DATA.warband_unit[i].type == 17
    end
    print("SAVE_LOAD_TEST_1:")
    if test_passed then print("PASSED") else print("ERROR") end
end
function DATA.test_set_get_1()
    local fat_id = DATA.fatten_tile(0)
    fat_id.is_land = true
    fat_id.is_fresh = true
    fat_id.elevation = -4
    fat_id.grass = -13
    fat_id.shrub = 11
    fat_id.conifer = 8
    fat_id.broadleaf = 10
    fat_id.ideal_grass = 4
    fat_id.ideal_shrub = -7
    fat_id.ideal_conifer = -14
    fat_id.ideal_broadleaf = 11
    fat_id.silt = -19
    fat_id.clay = 4
    fat_id.sand = 7
    fat_id.soil_minerals = 18
    fat_id.soil_organics = -20
    fat_id.january_waterflow = 8
    fat_id.july_waterflow = -3
    fat_id.waterlevel = -6
    fat_id.has_river = true
    fat_id.has_marsh = false
    fat_id.ice = -19
    fat_id.ice_age_ice = -19
    fat_id.debug_r = -19
    fat_id.debug_g = 14
    fat_id.debug_b = -20
    fat_id.real_r = 4
    fat_id.real_g = -7
    fat_id.real_b = 7
    fat_id.pathfinding_index = 0
    local test_passed = true
    test_passed = test_passed and fat_id.is_land == true
    if not test_passed then print("is_land", true, fat_id.is_land) end
    test_passed = test_passed and fat_id.is_fresh == true
    if not test_passed then print("is_fresh", true, fat_id.is_fresh) end
    test_passed = test_passed and fat_id.elevation == -4
    if not test_passed then print("elevation", -4, fat_id.elevation) end
    test_passed = test_passed and fat_id.grass == -13
    if not test_passed then print("grass", -13, fat_id.grass) end
    test_passed = test_passed and fat_id.shrub == 11
    if not test_passed then print("shrub", 11, fat_id.shrub) end
    test_passed = test_passed and fat_id.conifer == 8
    if not test_passed then print("conifer", 8, fat_id.conifer) end
    test_passed = test_passed and fat_id.broadleaf == 10
    if not test_passed then print("broadleaf", 10, fat_id.broadleaf) end
    test_passed = test_passed and fat_id.ideal_grass == 4
    if not test_passed then print("ideal_grass", 4, fat_id.ideal_grass) end
    test_passed = test_passed and fat_id.ideal_shrub == -7
    if not test_passed then print("ideal_shrub", -7, fat_id.ideal_shrub) end
    test_passed = test_passed and fat_id.ideal_conifer == -14
    if not test_passed then print("ideal_conifer", -14, fat_id.ideal_conifer) end
    test_passed = test_passed and fat_id.ideal_broadleaf == 11
    if not test_passed then print("ideal_broadleaf", 11, fat_id.ideal_broadleaf) end
    test_passed = test_passed and fat_id.silt == -19
    if not test_passed then print("silt", -19, fat_id.silt) end
    test_passed = test_passed and fat_id.clay == 4
    if not test_passed then print("clay", 4, fat_id.clay) end
    test_passed = test_passed and fat_id.sand == 7
    if not test_passed then print("sand", 7, fat_id.sand) end
    test_passed = test_passed and fat_id.soil_minerals == 18
    if not test_passed then print("soil_minerals", 18, fat_id.soil_minerals) end
    test_passed = test_passed and fat_id.soil_organics == -20
    if not test_passed then print("soil_organics", -20, fat_id.soil_organics) end
    test_passed = test_passed and fat_id.january_waterflow == 8
    if not test_passed then print("january_waterflow", 8, fat_id.january_waterflow) end
    test_passed = test_passed and fat_id.july_waterflow == -3
    if not test_passed then print("july_waterflow", -3, fat_id.july_waterflow) end
    test_passed = test_passed and fat_id.waterlevel == -6
    if not test_passed then print("waterlevel", -6, fat_id.waterlevel) end
    test_passed = test_passed and fat_id.has_river == true
    if not test_passed then print("has_river", true, fat_id.has_river) end
    test_passed = test_passed and fat_id.has_marsh == false
    if not test_passed then print("has_marsh", false, fat_id.has_marsh) end
    test_passed = test_passed and fat_id.ice == -19
    if not test_passed then print("ice", -19, fat_id.ice) end
    test_passed = test_passed and fat_id.ice_age_ice == -19
    if not test_passed then print("ice_age_ice", -19, fat_id.ice_age_ice) end
    test_passed = test_passed and fat_id.debug_r == -19
    if not test_passed then print("debug_r", -19, fat_id.debug_r) end
    test_passed = test_passed and fat_id.debug_g == 14
    if not test_passed then print("debug_g", 14, fat_id.debug_g) end
    test_passed = test_passed and fat_id.debug_b == -20
    if not test_passed then print("debug_b", -20, fat_id.debug_b) end
    test_passed = test_passed and fat_id.real_r == 4
    if not test_passed then print("real_r", 4, fat_id.real_r) end
    test_passed = test_passed and fat_id.real_g == -7
    if not test_passed then print("real_g", -7, fat_id.real_g) end
    test_passed = test_passed and fat_id.real_b == 7
    if not test_passed then print("real_b", 7, fat_id.real_b) end
    test_passed = test_passed and fat_id.pathfinding_index == 0
    if not test_passed then print("pathfinding_index", 0, fat_id.pathfinding_index) end
    print("SET_GET_TEST_1_tile:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_race(0)
    fat_id.r = -12
    fat_id.g = 16
    fat_id.b = -16
    fat_id.carrying_capacity_weight = -4
    fat_id.fecundity = -13
    fat_id.spotting = 11
    fat_id.visibility = 8
    fat_id.males_per_hundred_females = 10
    fat_id.child_age = 4
    fat_id.teen_age = -7
    fat_id.adult_age = -14
    fat_id.middle_age = 11
    fat_id.elder_age = -19
    fat_id.max_age = 4
    fat_id.minimum_comfortable_temperature = 7
    fat_id.minimum_absolute_temperature = 18
    fat_id.minimum_comfortable_elevation = -20
    fat_id.female_body_size = 8
    fat_id.male_body_size = -3
    for j = 0, 9 do
        DATA.race[0].female_efficiency[j] = -6
    end
    for j = 0, 9 do
        DATA.race[0].male_efficiency[j] = 17
    end
    fat_id.female_infrastructure_needs = -14
    fat_id.male_infrastructure_needs = 0
    for j = 0, 19 do
        DATA.race[0].female_needs[j].need = 0
    end
    for j = 0, 19 do
        DATA.race[0].female_needs[j].use_case = 0
    end
    for j = 0, 19 do
        DATA.race[0].female_needs[j].required = -19
    end
    for j = 0, 19 do
        DATA.race[0].male_needs[j].need = 0
    end
    for j = 0, 19 do
        DATA.race[0].male_needs[j].use_case = 12
    end
    for j = 0, 19 do
        DATA.race[0].male_needs[j].required = -7
    end
    fat_id.requires_large_river = false
    fat_id.requires_large_forest = true
    local test_passed = true
    test_passed = test_passed and fat_id.r == -12
    if not test_passed then print("r", -12, fat_id.r) end
    test_passed = test_passed and fat_id.g == 16
    if not test_passed then print("g", 16, fat_id.g) end
    test_passed = test_passed and fat_id.b == -16
    if not test_passed then print("b", -16, fat_id.b) end
    test_passed = test_passed and fat_id.carrying_capacity_weight == -4
    if not test_passed then print("carrying_capacity_weight", -4, fat_id.carrying_capacity_weight) end
    test_passed = test_passed and fat_id.fecundity == -13
    if not test_passed then print("fecundity", -13, fat_id.fecundity) end
    test_passed = test_passed and fat_id.spotting == 11
    if not test_passed then print("spotting", 11, fat_id.spotting) end
    test_passed = test_passed and fat_id.visibility == 8
    if not test_passed then print("visibility", 8, fat_id.visibility) end
    test_passed = test_passed and fat_id.males_per_hundred_females == 10
    if not test_passed then print("males_per_hundred_females", 10, fat_id.males_per_hundred_females) end
    test_passed = test_passed and fat_id.child_age == 4
    if not test_passed then print("child_age", 4, fat_id.child_age) end
    test_passed = test_passed and fat_id.teen_age == -7
    if not test_passed then print("teen_age", -7, fat_id.teen_age) end
    test_passed = test_passed and fat_id.adult_age == -14
    if not test_passed then print("adult_age", -14, fat_id.adult_age) end
    test_passed = test_passed and fat_id.middle_age == 11
    if not test_passed then print("middle_age", 11, fat_id.middle_age) end
    test_passed = test_passed and fat_id.elder_age == -19
    if not test_passed then print("elder_age", -19, fat_id.elder_age) end
    test_passed = test_passed and fat_id.max_age == 4
    if not test_passed then print("max_age", 4, fat_id.max_age) end
    test_passed = test_passed and fat_id.minimum_comfortable_temperature == 7
    if not test_passed then print("minimum_comfortable_temperature", 7, fat_id.minimum_comfortable_temperature) end
    test_passed = test_passed and fat_id.minimum_absolute_temperature == 18
    if not test_passed then print("minimum_absolute_temperature", 18, fat_id.minimum_absolute_temperature) end
    test_passed = test_passed and fat_id.minimum_comfortable_elevation == -20
    if not test_passed then print("minimum_comfortable_elevation", -20, fat_id.minimum_comfortable_elevation) end
    test_passed = test_passed and fat_id.female_body_size == 8
    if not test_passed then print("female_body_size", 8, fat_id.female_body_size) end
    test_passed = test_passed and fat_id.male_body_size == -3
    if not test_passed then print("male_body_size", -3, fat_id.male_body_size) end
    for j = 0, 9 do
        test_passed = test_passed and DATA.race[0].female_efficiency[j] == -6
    end
    if not test_passed then print("female_efficiency", -6, DATA.race[0].female_efficiency[0]) end
    for j = 0, 9 do
        test_passed = test_passed and DATA.race[0].male_efficiency[j] == 17
    end
    if not test_passed then print("male_efficiency", 17, DATA.race[0].male_efficiency[0]) end
    test_passed = test_passed and fat_id.female_infrastructure_needs == -14
    if not test_passed then print("female_infrastructure_needs", -14, fat_id.female_infrastructure_needs) end
    test_passed = test_passed and fat_id.male_infrastructure_needs == 0
    if not test_passed then print("male_infrastructure_needs", 0, fat_id.male_infrastructure_needs) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].female_needs[j].need == 0
    end
    if not test_passed then print("female_needs.need", 0, DATA.race[0].female_needs[0].need) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].female_needs[j].use_case == 0
    end
    if not test_passed then print("female_needs.use_case", 0, DATA.race[0].female_needs[0].use_case) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].female_needs[j].required == -19
    end
    if not test_passed then print("female_needs.required", -19, DATA.race[0].female_needs[0].required) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].male_needs[j].need == 0
    end
    if not test_passed then print("male_needs.need", 0, DATA.race[0].male_needs[0].need) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].male_needs[j].use_case == 12
    end
    if not test_passed then print("male_needs.use_case", 12, DATA.race[0].male_needs[0].use_case) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].male_needs[j].required == -7
    end
    if not test_passed then print("male_needs.required", -7, DATA.race[0].male_needs[0].required) end
    test_passed = test_passed and fat_id.requires_large_river == false
    if not test_passed then print("requires_large_river", false, fat_id.requires_large_river) end
    test_passed = test_passed and fat_id.requires_large_forest == true
    if not test_passed then print("requires_large_forest", true, fat_id.requires_large_forest) end
    print("SET_GET_TEST_1_race:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_pop(0)
    fat_id.race = 4
    fat_id.female = true
    fat_id.age = 8
    fat_id.savings = -13
    fat_id.parent = 15
    fat_id.loyalty = 14
    fat_id.life_needs_satisfaction = 10
    fat_id.basic_needs_satisfaction = 4
    for j = 0, 19 do
        DATA.pop[0].need_satisfaction[j].need = 3
    end
    for j = 0, 19 do
        DATA.pop[0].need_satisfaction[j].use_case = 3
    end
    for j = 0, 19 do
        DATA.pop[0].need_satisfaction[j].consumed = 11
    end
    for j = 0, 19 do
        DATA.pop[0].need_satisfaction[j].demanded = -19
    end
    for j = 0, 9 do
        DATA.pop[0].traits[j] = 6
    end
    fat_id.successor = 13
    for j = 0, 99 do
        DATA.pop[0].inventory[j] = 18
    end
    for j = 0, 99 do
        DATA.pop[0].price_memory[j] = -20
    end
    fat_id.forage_ratio = 8
    fat_id.work_ratio = -3
    fat_id.rank = 1
    for j = 0, 19 do
        DATA.pop[0].dna[j] = 17
    end
    local test_passed = true
    test_passed = test_passed and fat_id.race == 4
    if not test_passed then print("race", 4, fat_id.race) end
    test_passed = test_passed and fat_id.female == true
    if not test_passed then print("female", true, fat_id.female) end
    test_passed = test_passed and fat_id.age == 8
    if not test_passed then print("age", 8, fat_id.age) end
    test_passed = test_passed and fat_id.savings == -13
    if not test_passed then print("savings", -13, fat_id.savings) end
    test_passed = test_passed and fat_id.parent == 15
    if not test_passed then print("parent", 15, fat_id.parent) end
    test_passed = test_passed and fat_id.loyalty == 14
    if not test_passed then print("loyalty", 14, fat_id.loyalty) end
    test_passed = test_passed and fat_id.life_needs_satisfaction == 10
    if not test_passed then print("life_needs_satisfaction", 10, fat_id.life_needs_satisfaction) end
    test_passed = test_passed and fat_id.basic_needs_satisfaction == 4
    if not test_passed then print("basic_needs_satisfaction", 4, fat_id.basic_needs_satisfaction) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].need_satisfaction[j].need == 3
    end
    if not test_passed then print("need_satisfaction.need", 3, DATA.pop[0].need_satisfaction[0].need) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].need_satisfaction[j].use_case == 3
    end
    if not test_passed then print("need_satisfaction.use_case", 3, DATA.pop[0].need_satisfaction[0].use_case) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].need_satisfaction[j].consumed == 11
    end
    if not test_passed then print("need_satisfaction.consumed", 11, DATA.pop[0].need_satisfaction[0].consumed) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].need_satisfaction[j].demanded == -19
    end
    if not test_passed then print("need_satisfaction.demanded", -19, DATA.pop[0].need_satisfaction[0].demanded) end
    for j = 0, 9 do
        test_passed = test_passed and DATA.pop[0].traits[j] == 6
    end
    if not test_passed then print("traits", 6, DATA.pop[0].traits[0]) end
    test_passed = test_passed and fat_id.successor == 13
    if not test_passed then print("successor", 13, fat_id.successor) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.pop[0].inventory[j] == 18
    end
    if not test_passed then print("inventory", 18, DATA.pop[0].inventory[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.pop[0].price_memory[j] == -20
    end
    if not test_passed then print("price_memory", -20, DATA.pop[0].price_memory[0]) end
    test_passed = test_passed and fat_id.forage_ratio == 8
    if not test_passed then print("forage_ratio", 8, fat_id.forage_ratio) end
    test_passed = test_passed and fat_id.work_ratio == -3
    if not test_passed then print("work_ratio", -3, fat_id.work_ratio) end
    test_passed = test_passed and fat_id.rank == 1
    if not test_passed then print("rank", 1, fat_id.rank) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].dna[j] == 17
    end
    if not test_passed then print("dna", 17, DATA.pop[0].dna[0]) end
    print("SET_GET_TEST_1_pop:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_province(0)
    fat_id.r = -12
    fat_id.g = 16
    fat_id.b = -16
    fat_id.is_land = false
    fat_id.province_id = -13
    fat_id.size = 11
    fat_id.hydration = 8
    fat_id.movement_cost = 10
    fat_id.center = 20
    fat_id.infrastructure_needed = 4
    fat_id.infrastructure = -7
    fat_id.infrastructure_investment = -14
    for j = 0, 99 do
        DATA.province[0].local_production[j] = 11
    end
    for j = 0, 99 do
        DATA.province[0].local_consumption[j] = -19
    end
    for j = 0, 99 do
        DATA.province[0].local_demand[j] = 4
    end
    for j = 0, 99 do
        DATA.province[0].local_storage[j] = 7
    end
    for j = 0, 99 do
        DATA.province[0].local_prices[j] = 18
    end
    fat_id.local_wealth = -20
    fat_id.trade_wealth = 8
    fat_id.local_income = -3
    fat_id.local_building_upkeep = -6
    fat_id.foragers = 17
    fat_id.foragers_water = -14
    fat_id.foragers_limit = 0
    for j = 0, 24 do
        DATA.province[0].local_resources[j].resource = 0
    end
    for j = 0, 24 do
        DATA.province[0].local_resources[j].location = 0
    end
    fat_id.mood = -19
    for j = 0, 19 do
        DATA.province[0].unit_types[j] = 20
    end
    fat_id.on_a_river = true
    fat_id.on_a_forest = false
    local test_passed = true
    test_passed = test_passed and fat_id.r == -12
    if not test_passed then print("r", -12, fat_id.r) end
    test_passed = test_passed and fat_id.g == 16
    if not test_passed then print("g", 16, fat_id.g) end
    test_passed = test_passed and fat_id.b == -16
    if not test_passed then print("b", -16, fat_id.b) end
    test_passed = test_passed and fat_id.is_land == false
    if not test_passed then print("is_land", false, fat_id.is_land) end
    test_passed = test_passed and fat_id.province_id == -13
    if not test_passed then print("province_id", -13, fat_id.province_id) end
    test_passed = test_passed and fat_id.size == 11
    if not test_passed then print("size", 11, fat_id.size) end
    test_passed = test_passed and fat_id.hydration == 8
    if not test_passed then print("hydration", 8, fat_id.hydration) end
    test_passed = test_passed and fat_id.movement_cost == 10
    if not test_passed then print("movement_cost", 10, fat_id.movement_cost) end
    test_passed = test_passed and fat_id.center == 20
    if not test_passed then print("center", 20, fat_id.center) end
    test_passed = test_passed and fat_id.infrastructure_needed == 4
    if not test_passed then print("infrastructure_needed", 4, fat_id.infrastructure_needed) end
    test_passed = test_passed and fat_id.infrastructure == -7
    if not test_passed then print("infrastructure", -7, fat_id.infrastructure) end
    test_passed = test_passed and fat_id.infrastructure_investment == -14
    if not test_passed then print("infrastructure_investment", -14, fat_id.infrastructure_investment) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_production[j] == 11
    end
    if not test_passed then print("local_production", 11, DATA.province[0].local_production[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_consumption[j] == -19
    end
    if not test_passed then print("local_consumption", -19, DATA.province[0].local_consumption[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_demand[j] == 4
    end
    if not test_passed then print("local_demand", 4, DATA.province[0].local_demand[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_storage[j] == 7
    end
    if not test_passed then print("local_storage", 7, DATA.province[0].local_storage[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_prices[j] == 18
    end
    if not test_passed then print("local_prices", 18, DATA.province[0].local_prices[0]) end
    test_passed = test_passed and fat_id.local_wealth == -20
    if not test_passed then print("local_wealth", -20, fat_id.local_wealth) end
    test_passed = test_passed and fat_id.trade_wealth == 8
    if not test_passed then print("trade_wealth", 8, fat_id.trade_wealth) end
    test_passed = test_passed and fat_id.local_income == -3
    if not test_passed then print("local_income", -3, fat_id.local_income) end
    test_passed = test_passed and fat_id.local_building_upkeep == -6
    if not test_passed then print("local_building_upkeep", -6, fat_id.local_building_upkeep) end
    test_passed = test_passed and fat_id.foragers == 17
    if not test_passed then print("foragers", 17, fat_id.foragers) end
    test_passed = test_passed and fat_id.foragers_water == -14
    if not test_passed then print("foragers_water", -14, fat_id.foragers_water) end
    test_passed = test_passed and fat_id.foragers_limit == 0
    if not test_passed then print("foragers_limit", 0, fat_id.foragers_limit) end
    for j = 0, 24 do
        test_passed = test_passed and DATA.province[0].local_resources[j].resource == 0
    end
    if not test_passed then print("local_resources.resource", 0, DATA.province[0].local_resources[0].resource) end
    for j = 0, 24 do
        test_passed = test_passed and DATA.province[0].local_resources[j].location == 0
    end
    if not test_passed then print("local_resources.location", 0, DATA.province[0].local_resources[0].location) end
    test_passed = test_passed and fat_id.mood == -19
    if not test_passed then print("mood", -19, fat_id.mood) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.province[0].unit_types[j] == 20
    end
    if not test_passed then print("unit_types", 20, DATA.province[0].unit_types[0]) end
    test_passed = test_passed and fat_id.on_a_river == true
    if not test_passed then print("on_a_river", true, fat_id.on_a_river) end
    test_passed = test_passed and fat_id.on_a_forest == false
    if not test_passed then print("on_a_forest", false, fat_id.on_a_forest) end
    print("SET_GET_TEST_1_province:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_army(0)
    fat_id.destination = 4
    local test_passed = true
    test_passed = test_passed and fat_id.destination == 4
    if not test_passed then print("destination", 4, fat_id.destination) end
    print("SET_GET_TEST_1_army:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband(0)
    for j = 0, 19 do
        DATA.warband[0].units_current[j] = -12
    end
    for j = 0, 19 do
        DATA.warband[0].units_target[j] = 16
    end
    fat_id.status = 1
    fat_id.idle_stance = 1
    fat_id.current_free_time_ratio = -13
    fat_id.treasury = 11
    fat_id.total_upkeep = 8
    fat_id.predicted_upkeep = 10
    fat_id.supplies = 4
    fat_id.supplies_target_days = -7
    fat_id.morale = -14
    local test_passed = true
    for j = 0, 19 do
        test_passed = test_passed and DATA.warband[0].units_current[j] == -12
    end
    if not test_passed then print("units_current", -12, DATA.warband[0].units_current[0]) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.warband[0].units_target[j] == 16
    end
    if not test_passed then print("units_target", 16, DATA.warband[0].units_target[0]) end
    test_passed = test_passed and fat_id.status == 1
    if not test_passed then print("status", 1, fat_id.status) end
    test_passed = test_passed and fat_id.idle_stance == 1
    if not test_passed then print("idle_stance", 1, fat_id.idle_stance) end
    test_passed = test_passed and fat_id.current_free_time_ratio == -13
    if not test_passed then print("current_free_time_ratio", -13, fat_id.current_free_time_ratio) end
    test_passed = test_passed and fat_id.treasury == 11
    if not test_passed then print("treasury", 11, fat_id.treasury) end
    test_passed = test_passed and fat_id.total_upkeep == 8
    if not test_passed then print("total_upkeep", 8, fat_id.total_upkeep) end
    test_passed = test_passed and fat_id.predicted_upkeep == 10
    if not test_passed then print("predicted_upkeep", 10, fat_id.predicted_upkeep) end
    test_passed = test_passed and fat_id.supplies == 4
    if not test_passed then print("supplies", 4, fat_id.supplies) end
    test_passed = test_passed and fat_id.supplies_target_days == -7
    if not test_passed then print("supplies_target_days", -7, fat_id.supplies_target_days) end
    test_passed = test_passed and fat_id.morale == -14
    if not test_passed then print("morale", -14, fat_id.morale) end
    print("SET_GET_TEST_1_warband:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_army_membership(0)
    local test_passed = true
    print("SET_GET_TEST_1_army_membership:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_leader(0)
    local test_passed = true
    print("SET_GET_TEST_1_warband_leader:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_recruiter(0)
    local test_passed = true
    print("SET_GET_TEST_1_warband_recruiter:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_commander(0)
    local test_passed = true
    print("SET_GET_TEST_1_warband_commander:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_location(0)
    local test_passed = true
    print("SET_GET_TEST_1_warband_location:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_unit(0)
    fat_id.type = 4
    local test_passed = true
    test_passed = test_passed and fat_id.type == 4
    if not test_passed then print("type", 4, fat_id.type) end
    print("SET_GET_TEST_1_warband_unit:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_character_location(0)
    local test_passed = true
    print("SET_GET_TEST_1_character_location:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_home(0)
    local test_passed = true
    print("SET_GET_TEST_1_home:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_pop_location(0)
    local test_passed = true
    print("SET_GET_TEST_1_pop_location:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_outlaw_location(0)
    local test_passed = true
    print("SET_GET_TEST_1_outlaw_location:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_tile_province_membership(0)
    local test_passed = true
    print("SET_GET_TEST_1_tile_province_membership:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_province_neighborhood(0)
    local test_passed = true
    print("SET_GET_TEST_1_province_neighborhood:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_parent_child_relation(0)
    local test_passed = true
    print("SET_GET_TEST_1_parent_child_relation:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_loyalty(0)
    local test_passed = true
    print("SET_GET_TEST_1_loyalty:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_succession(0)
    local test_passed = true
    print("SET_GET_TEST_1_succession:")
    if test_passed then print("PASSED") else print("ERROR") end
end
function DATA.test_save_load_2()
    for i = 0, 1500000 do
        DATA.tile[i].is_land = true
    end
    for i = 0, 1500000 do
        DATA.tile[i].is_fresh = true
    end
    for i = 0, 1500000 do
        DATA.tile[i].elevation = -15
    end
    for i = 0, 1500000 do
        DATA.tile[i].grass = 3
    end
    for i = 0, 1500000 do
        DATA.tile[i].shrub = -10
    end
    for i = 0, 1500000 do
        DATA.tile[i].conifer = -1
    end
    for i = 0, 1500000 do
        DATA.tile[i].broadleaf = -4
    end
    for i = 0, 1500000 do
        DATA.tile[i].ideal_grass = 18
    end
    for i = 0, 1500000 do
        DATA.tile[i].ideal_shrub = -7
    end
    for i = 0, 1500000 do
        DATA.tile[i].ideal_conifer = 18
    end
    for i = 0, 1500000 do
        DATA.tile[i].ideal_broadleaf = -18
    end
    for i = 0, 1500000 do
        DATA.tile[i].silt = 17
    end
    for i = 0, 1500000 do
        DATA.tile[i].clay = -10
    end
    for i = 0, 1500000 do
        DATA.tile[i].sand = 7
    end
    for i = 0, 1500000 do
        DATA.tile[i].soil_minerals = 20
    end
    for i = 0, 1500000 do
        DATA.tile[i].soil_organics = 5
    end
    for i = 0, 1500000 do
        DATA.tile[i].january_waterflow = 12
    end
    for i = 0, 1500000 do
        DATA.tile[i].july_waterflow = 3
    end
    for i = 0, 1500000 do
        DATA.tile[i].waterlevel = 14
    end
    for i = 0, 1500000 do
        DATA.tile[i].has_river = false
    end
    for i = 0, 1500000 do
        DATA.tile[i].has_marsh = false
    end
    for i = 0, 1500000 do
        DATA.tile[i].ice = -18
    end
    for i = 0, 1500000 do
        DATA.tile[i].ice_age_ice = -19
    end
    for i = 0, 1500000 do
        DATA.tile[i].debug_r = 3
    end
    for i = 0, 1500000 do
        DATA.tile[i].debug_g = 9
    end
    for i = 0, 1500000 do
        DATA.tile[i].debug_b = 0
    end
    for i = 0, 1500000 do
        DATA.tile[i].real_r = 4
    end
    for i = 0, 1500000 do
        DATA.tile[i].real_g = 7
    end
    for i = 0, 1500000 do
        DATA.tile[i].real_b = 13
    end
    for i = 0, 1500000 do
        DATA.tile[i].pathfinding_index = 5
    end
    for i = 0, 15 do
        DATA.race[i].r = 15
    end
    for i = 0, 15 do
        DATA.race[i].g = -9
    end
    for i = 0, 15 do
        DATA.race[i].b = -5
    end
    for i = 0, 15 do
        DATA.race[i].carrying_capacity_weight = -6
    end
    for i = 0, 15 do
        DATA.race[i].fecundity = -19
    end
    for i = 0, 15 do
        DATA.race[i].spotting = -9
    end
    for i = 0, 15 do
        DATA.race[i].visibility = 0
    end
    for i = 0, 15 do
        DATA.race[i].males_per_hundred_females = -9
    end
    for i = 0, 15 do
        DATA.race[i].child_age = -12
    end
    for i = 0, 15 do
        DATA.race[i].teen_age = 12
    end
    for i = 0, 15 do
        DATA.race[i].adult_age = 12
    end
    for i = 0, 15 do
        DATA.race[i].middle_age = 3
    end
    for i = 0, 15 do
        DATA.race[i].elder_age = 12
    end
    for i = 0, 15 do
        DATA.race[i].max_age = 15
    end
    for i = 0, 15 do
        DATA.race[i].minimum_comfortable_temperature = -9
    end
    for i = 0, 15 do
        DATA.race[i].minimum_absolute_temperature = 8
    end
    for i = 0, 15 do
        DATA.race[i].minimum_comfortable_elevation = 6
    end
    for i = 0, 15 do
        DATA.race[i].female_body_size = 13
    end
    for i = 0, 15 do
        DATA.race[i].male_body_size = 3
    end
    for i = 0, 15 do
    for j = 0, 9 do
        DATA.race[i].female_efficiency[j] = 17
    end
    end
    for i = 0, 15 do
    for j = 0, 9 do
        DATA.race[i].male_efficiency[j] = 2
    end
    end
    for i = 0, 15 do
        DATA.race[i].female_infrastructure_needs = 3
    end
    for i = 0, 15 do
        DATA.race[i].male_infrastructure_needs = 8
    end
    for i = 0, 15 do
    for j = 0, 19 do
        DATA.race[i].female_needs[j].need = 2
    end
    for j = 0, 19 do
        DATA.race[i].female_needs[j].use_case = 12
    end
    for j = 0, 19 do
        DATA.race[i].female_needs[j].required = 9
    end
    end
    for i = 0, 15 do
    for j = 0, 19 do
        DATA.race[i].male_needs[j].need = 3
    end
    for j = 0, 19 do
        DATA.race[i].male_needs[j].use_case = 15
    end
    for j = 0, 19 do
        DATA.race[i].male_needs[j].required = -3
    end
    end
    for i = 0, 15 do
        DATA.race[i].requires_large_river = false
    end
    for i = 0, 15 do
        DATA.race[i].requires_large_forest = false
    end
    for i = 0, 300000 do
        DATA.pop[i].race = 14
    end
    for i = 0, 300000 do
        DATA.pop[i].female = false
    end
    for i = 0, 300000 do
        DATA.pop[i].age = 11
    end
    for i = 0, 300000 do
        DATA.pop[i].savings = 16
    end
    for i = 0, 300000 do
        DATA.pop[i].parent = 17
    end
    for i = 0, 300000 do
        DATA.pop[i].loyalty = 14
    end
    for i = 0, 300000 do
        DATA.pop[i].life_needs_satisfaction = 11
    end
    for i = 0, 300000 do
        DATA.pop[i].basic_needs_satisfaction = -6
    end
    for i = 0, 300000 do
    for j = 0, 19 do
        DATA.pop[i].need_satisfaction[j].need = 5
    end
    for j = 0, 19 do
        DATA.pop[i].need_satisfaction[j].use_case = 5
    end
    for j = 0, 19 do
        DATA.pop[i].need_satisfaction[j].consumed = 19
    end
    for j = 0, 19 do
        DATA.pop[i].need_satisfaction[j].demanded = -3
    end
    end
    for i = 0, 300000 do
    for j = 0, 9 do
        DATA.pop[i].traits[j] = 7
    end
    end
    for i = 0, 300000 do
        DATA.pop[i].successor = 9
    end
    for i = 0, 300000 do
    for j = 0, 99 do
        DATA.pop[i].inventory[j] = -1
    end
    end
    for i = 0, 300000 do
    for j = 0, 99 do
        DATA.pop[i].price_memory[j] = 12
    end
    end
    for i = 0, 300000 do
        DATA.pop[i].forage_ratio = 15
    end
    for i = 0, 300000 do
        DATA.pop[i].work_ratio = 13
    end
    for i = 0, 300000 do
        DATA.pop[i].rank = 3
    end
    for i = 0, 300000 do
    for j = 0, 19 do
        DATA.pop[i].dna[j] = -1
    end
    end
    for i = 0, 10000 do
        DATA.province[i].r = -7
    end
    for i = 0, 10000 do
        DATA.province[i].g = 11
    end
    for i = 0, 10000 do
        DATA.province[i].b = 12
    end
    for i = 0, 10000 do
        DATA.province[i].is_land = false
    end
    for i = 0, 10000 do
        DATA.province[i].province_id = 19
    end
    for i = 0, 10000 do
        DATA.province[i].size = -16
    end
    for i = 0, 10000 do
        DATA.province[i].hydration = 1
    end
    for i = 0, 10000 do
        DATA.province[i].movement_cost = -20
    end
    for i = 0, 10000 do
        DATA.province[i].center = 6
    end
    for i = 0, 10000 do
        DATA.province[i].infrastructure_needed = -14
    end
    for i = 0, 10000 do
        DATA.province[i].infrastructure = -17
    end
    for i = 0, 10000 do
        DATA.province[i].infrastructure_investment = 16
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_production[j] = -17
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_consumption[j] = -3
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_demand[j] = 17
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_storage[j] = -6
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        DATA.province[i].local_prices[j] = -14
    end
    end
    for i = 0, 10000 do
        DATA.province[i].local_wealth = 13
    end
    for i = 0, 10000 do
        DATA.province[i].trade_wealth = -12
    end
    for i = 0, 10000 do
        DATA.province[i].local_income = -3
    end
    for i = 0, 10000 do
        DATA.province[i].local_building_upkeep = -5
    end
    for i = 0, 10000 do
        DATA.province[i].foragers = -7
    end
    for i = 0, 10000 do
        DATA.province[i].foragers_water = -17
    end
    for i = 0, 10000 do
        DATA.province[i].foragers_limit = 7
    end
    for i = 0, 10000 do
    for j = 0, 24 do
        DATA.province[i].local_resources[j].resource = 1
    end
    for j = 0, 24 do
        DATA.province[i].local_resources[j].location = 1
    end
    end
    for i = 0, 10000 do
        DATA.province[i].mood = 3
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        DATA.province[i].unit_types[j] = 11
    end
    end
    for i = 0, 10000 do
        DATA.province[i].on_a_river = true
    end
    for i = 0, 10000 do
        DATA.province[i].on_a_forest = true
    end
    for i = 0, 5000 do
        DATA.army[i].destination = 0
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        DATA.warband[i].units_current[j] = -15
    end
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        DATA.warband[i].units_target[j] = -13
    end
    end
    for i = 0, 10000 do
        DATA.warband[i].status = 1
    end
    for i = 0, 10000 do
        DATA.warband[i].idle_stance = 0
    end
    for i = 0, 10000 do
        DATA.warband[i].current_free_time_ratio = -18
    end
    for i = 0, 10000 do
        DATA.warband[i].treasury = -19
    end
    for i = 0, 10000 do
        DATA.warband[i].total_upkeep = 3
    end
    for i = 0, 10000 do
        DATA.warband[i].predicted_upkeep = -4
    end
    for i = 0, 10000 do
        DATA.warband[i].supplies = -12
    end
    for i = 0, 10000 do
        DATA.warband[i].supplies_target_days = -10
    end
    for i = 0, 10000 do
        DATA.warband[i].morale = -9
    end
    for i = 0, 50000 do
        DATA.warband_unit[i].type = 16
    end
    DATA.save_state()
    DATA.load_state()
    local test_passed = true
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].is_land == true
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].is_fresh == true
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].elevation == -15
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].grass == 3
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].shrub == -10
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].conifer == -1
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].broadleaf == -4
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ideal_grass == 18
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ideal_shrub == -7
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ideal_conifer == 18
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ideal_broadleaf == -18
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].silt == 17
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].clay == -10
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].sand == 7
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].soil_minerals == 20
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].soil_organics == 5
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].january_waterflow == 12
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].july_waterflow == 3
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].waterlevel == 14
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].has_river == false
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].has_marsh == false
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ice == -18
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].ice_age_ice == -19
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].debug_r == 3
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].debug_g == 9
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].debug_b == 0
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].real_r == 4
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].real_g == 7
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].real_b == 13
    end
    for i = 0, 1500000 do
        test_passed = test_passed and DATA.tile[i].pathfinding_index == 5
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].r == 15
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].g == -9
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].b == -5
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].carrying_capacity_weight == -6
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].fecundity == -19
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].spotting == -9
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].visibility == 0
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].males_per_hundred_females == -9
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].child_age == -12
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].teen_age == 12
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].adult_age == 12
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].middle_age == 3
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].elder_age == 12
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].max_age == 15
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].minimum_comfortable_temperature == -9
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].minimum_absolute_temperature == 8
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].minimum_comfortable_elevation == 6
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].female_body_size == 13
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].male_body_size == 3
    end
    for i = 0, 15 do
    for j = 0, 9 do
        test_passed = test_passed and DATA.race[i].female_efficiency[j] == 17
    end
    end
    for i = 0, 15 do
    for j = 0, 9 do
        test_passed = test_passed and DATA.race[i].male_efficiency[j] == 2
    end
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].female_infrastructure_needs == 3
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].male_infrastructure_needs == 8
    end
    for i = 0, 15 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].female_needs[j].need == 2
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].female_needs[j].use_case == 12
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].female_needs[j].required == 9
    end
    end
    for i = 0, 15 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].male_needs[j].need == 3
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].male_needs[j].use_case == 15
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[i].male_needs[j].required == -3
    end
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].requires_large_river == false
    end
    for i = 0, 15 do
        test_passed = test_passed and DATA.race[i].requires_large_forest == false
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].race == 14
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].female == false
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].age == 11
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].savings == 16
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].parent == 17
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].loyalty == 14
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].life_needs_satisfaction == 11
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].basic_needs_satisfaction == -6
    end
    for i = 0, 300000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].need_satisfaction[j].need == 5
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].need_satisfaction[j].use_case == 5
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].need_satisfaction[j].consumed == 19
    end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].need_satisfaction[j].demanded == -3
    end
    end
    for i = 0, 300000 do
    for j = 0, 9 do
        test_passed = test_passed and DATA.pop[i].traits[j] == 7
    end
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].successor == 9
    end
    for i = 0, 300000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.pop[i].inventory[j] == -1
    end
    end
    for i = 0, 300000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.pop[i].price_memory[j] == 12
    end
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].forage_ratio == 15
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].work_ratio == 13
    end
    for i = 0, 300000 do
        test_passed = test_passed and DATA.pop[i].rank == 3
    end
    for i = 0, 300000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[i].dna[j] == -1
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].r == -7
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].g == 11
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].b == 12
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].is_land == false
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].province_id == 19
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].size == -16
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].hydration == 1
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].movement_cost == -20
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].center == 6
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].infrastructure_needed == -14
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].infrastructure == -17
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].infrastructure_investment == 16
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_production[j] == -17
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_consumption[j] == -3
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_demand[j] == 17
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_storage[j] == -6
    end
    end
    for i = 0, 10000 do
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[i].local_prices[j] == -14
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].local_wealth == 13
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].trade_wealth == -12
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].local_income == -3
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].local_building_upkeep == -5
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].foragers == -7
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].foragers_water == -17
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].foragers_limit == 7
    end
    for i = 0, 10000 do
    for j = 0, 24 do
        test_passed = test_passed and DATA.province[i].local_resources[j].resource == 1
    end
    for j = 0, 24 do
        test_passed = test_passed and DATA.province[i].local_resources[j].location == 1
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].mood == 3
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.province[i].unit_types[j] == 11
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].on_a_river == true
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.province[i].on_a_forest == true
    end
    for i = 0, 5000 do
        test_passed = test_passed and DATA.army[i].destination == 0
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.warband[i].units_current[j] == -15
    end
    end
    for i = 0, 10000 do
    for j = 0, 19 do
        test_passed = test_passed and DATA.warband[i].units_target[j] == -13
    end
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].status == 1
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].idle_stance == 0
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].current_free_time_ratio == -18
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].treasury == -19
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].total_upkeep == 3
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].predicted_upkeep == -4
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].supplies == -12
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].supplies_target_days == -10
    end
    for i = 0, 10000 do
        test_passed = test_passed and DATA.warband[i].morale == -9
    end
    for i = 0, 50000 do
        test_passed = test_passed and DATA.warband_unit[i].type == 16
    end
    print("SAVE_LOAD_TEST_2:")
    if test_passed then print("PASSED") else print("ERROR") end
end
function DATA.test_set_get_2()
    local fat_id = DATA.fatten_tile(0)
    fat_id.is_land = true
    fat_id.is_fresh = true
    fat_id.elevation = -15
    fat_id.grass = 3
    fat_id.shrub = -10
    fat_id.conifer = -1
    fat_id.broadleaf = -4
    fat_id.ideal_grass = 18
    fat_id.ideal_shrub = -7
    fat_id.ideal_conifer = 18
    fat_id.ideal_broadleaf = -18
    fat_id.silt = 17
    fat_id.clay = -10
    fat_id.sand = 7
    fat_id.soil_minerals = 20
    fat_id.soil_organics = 5
    fat_id.january_waterflow = 12
    fat_id.july_waterflow = 3
    fat_id.waterlevel = 14
    fat_id.has_river = false
    fat_id.has_marsh = false
    fat_id.ice = -18
    fat_id.ice_age_ice = -19
    fat_id.debug_r = 3
    fat_id.debug_g = 9
    fat_id.debug_b = 0
    fat_id.real_r = 4
    fat_id.real_g = 7
    fat_id.real_b = 13
    fat_id.pathfinding_index = 5
    local test_passed = true
    test_passed = test_passed and fat_id.is_land == true
    if not test_passed then print("is_land", true, fat_id.is_land) end
    test_passed = test_passed and fat_id.is_fresh == true
    if not test_passed then print("is_fresh", true, fat_id.is_fresh) end
    test_passed = test_passed and fat_id.elevation == -15
    if not test_passed then print("elevation", -15, fat_id.elevation) end
    test_passed = test_passed and fat_id.grass == 3
    if not test_passed then print("grass", 3, fat_id.grass) end
    test_passed = test_passed and fat_id.shrub == -10
    if not test_passed then print("shrub", -10, fat_id.shrub) end
    test_passed = test_passed and fat_id.conifer == -1
    if not test_passed then print("conifer", -1, fat_id.conifer) end
    test_passed = test_passed and fat_id.broadleaf == -4
    if not test_passed then print("broadleaf", -4, fat_id.broadleaf) end
    test_passed = test_passed and fat_id.ideal_grass == 18
    if not test_passed then print("ideal_grass", 18, fat_id.ideal_grass) end
    test_passed = test_passed and fat_id.ideal_shrub == -7
    if not test_passed then print("ideal_shrub", -7, fat_id.ideal_shrub) end
    test_passed = test_passed and fat_id.ideal_conifer == 18
    if not test_passed then print("ideal_conifer", 18, fat_id.ideal_conifer) end
    test_passed = test_passed and fat_id.ideal_broadleaf == -18
    if not test_passed then print("ideal_broadleaf", -18, fat_id.ideal_broadleaf) end
    test_passed = test_passed and fat_id.silt == 17
    if not test_passed then print("silt", 17, fat_id.silt) end
    test_passed = test_passed and fat_id.clay == -10
    if not test_passed then print("clay", -10, fat_id.clay) end
    test_passed = test_passed and fat_id.sand == 7
    if not test_passed then print("sand", 7, fat_id.sand) end
    test_passed = test_passed and fat_id.soil_minerals == 20
    if not test_passed then print("soil_minerals", 20, fat_id.soil_minerals) end
    test_passed = test_passed and fat_id.soil_organics == 5
    if not test_passed then print("soil_organics", 5, fat_id.soil_organics) end
    test_passed = test_passed and fat_id.january_waterflow == 12
    if not test_passed then print("january_waterflow", 12, fat_id.january_waterflow) end
    test_passed = test_passed and fat_id.july_waterflow == 3
    if not test_passed then print("july_waterflow", 3, fat_id.july_waterflow) end
    test_passed = test_passed and fat_id.waterlevel == 14
    if not test_passed then print("waterlevel", 14, fat_id.waterlevel) end
    test_passed = test_passed and fat_id.has_river == false
    if not test_passed then print("has_river", false, fat_id.has_river) end
    test_passed = test_passed and fat_id.has_marsh == false
    if not test_passed then print("has_marsh", false, fat_id.has_marsh) end
    test_passed = test_passed and fat_id.ice == -18
    if not test_passed then print("ice", -18, fat_id.ice) end
    test_passed = test_passed and fat_id.ice_age_ice == -19
    if not test_passed then print("ice_age_ice", -19, fat_id.ice_age_ice) end
    test_passed = test_passed and fat_id.debug_r == 3
    if not test_passed then print("debug_r", 3, fat_id.debug_r) end
    test_passed = test_passed and fat_id.debug_g == 9
    if not test_passed then print("debug_g", 9, fat_id.debug_g) end
    test_passed = test_passed and fat_id.debug_b == 0
    if not test_passed then print("debug_b", 0, fat_id.debug_b) end
    test_passed = test_passed and fat_id.real_r == 4
    if not test_passed then print("real_r", 4, fat_id.real_r) end
    test_passed = test_passed and fat_id.real_g == 7
    if not test_passed then print("real_g", 7, fat_id.real_g) end
    test_passed = test_passed and fat_id.real_b == 13
    if not test_passed then print("real_b", 13, fat_id.real_b) end
    test_passed = test_passed and fat_id.pathfinding_index == 5
    if not test_passed then print("pathfinding_index", 5, fat_id.pathfinding_index) end
    print("SET_GET_TEST_2_tile:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_race(0)
    fat_id.r = -17
    fat_id.g = -15
    fat_id.b = -15
    fat_id.carrying_capacity_weight = 3
    fat_id.fecundity = -10
    fat_id.spotting = -1
    fat_id.visibility = -4
    fat_id.males_per_hundred_females = 18
    fat_id.child_age = -7
    fat_id.teen_age = 18
    fat_id.adult_age = -18
    fat_id.middle_age = 17
    fat_id.elder_age = -10
    fat_id.max_age = 7
    fat_id.minimum_comfortable_temperature = 20
    fat_id.minimum_absolute_temperature = 5
    fat_id.minimum_comfortable_elevation = 12
    fat_id.female_body_size = 3
    fat_id.male_body_size = 14
    for j = 0, 9 do
        DATA.race[0].female_efficiency[j] = 8
    end
    for j = 0, 9 do
        DATA.race[0].male_efficiency[j] = 12
    end
    fat_id.female_infrastructure_needs = -3
    fat_id.male_infrastructure_needs = -18
    for j = 0, 19 do
        DATA.race[0].female_needs[j].need = 0
    end
    for j = 0, 19 do
        DATA.race[0].female_needs[j].use_case = 11
    end
    for j = 0, 19 do
        DATA.race[0].female_needs[j].required = 9
    end
    for j = 0, 19 do
        DATA.race[0].male_needs[j].need = 5
    end
    for j = 0, 19 do
        DATA.race[0].male_needs[j].use_case = 12
    end
    for j = 0, 19 do
        DATA.race[0].male_needs[j].required = 7
    end
    fat_id.requires_large_river = true
    fat_id.requires_large_forest = true
    local test_passed = true
    test_passed = test_passed and fat_id.r == -17
    if not test_passed then print("r", -17, fat_id.r) end
    test_passed = test_passed and fat_id.g == -15
    if not test_passed then print("g", -15, fat_id.g) end
    test_passed = test_passed and fat_id.b == -15
    if not test_passed then print("b", -15, fat_id.b) end
    test_passed = test_passed and fat_id.carrying_capacity_weight == 3
    if not test_passed then print("carrying_capacity_weight", 3, fat_id.carrying_capacity_weight) end
    test_passed = test_passed and fat_id.fecundity == -10
    if not test_passed then print("fecundity", -10, fat_id.fecundity) end
    test_passed = test_passed and fat_id.spotting == -1
    if not test_passed then print("spotting", -1, fat_id.spotting) end
    test_passed = test_passed and fat_id.visibility == -4
    if not test_passed then print("visibility", -4, fat_id.visibility) end
    test_passed = test_passed and fat_id.males_per_hundred_females == 18
    if not test_passed then print("males_per_hundred_females", 18, fat_id.males_per_hundred_females) end
    test_passed = test_passed and fat_id.child_age == -7
    if not test_passed then print("child_age", -7, fat_id.child_age) end
    test_passed = test_passed and fat_id.teen_age == 18
    if not test_passed then print("teen_age", 18, fat_id.teen_age) end
    test_passed = test_passed and fat_id.adult_age == -18
    if not test_passed then print("adult_age", -18, fat_id.adult_age) end
    test_passed = test_passed and fat_id.middle_age == 17
    if not test_passed then print("middle_age", 17, fat_id.middle_age) end
    test_passed = test_passed and fat_id.elder_age == -10
    if not test_passed then print("elder_age", -10, fat_id.elder_age) end
    test_passed = test_passed and fat_id.max_age == 7
    if not test_passed then print("max_age", 7, fat_id.max_age) end
    test_passed = test_passed and fat_id.minimum_comfortable_temperature == 20
    if not test_passed then print("minimum_comfortable_temperature", 20, fat_id.minimum_comfortable_temperature) end
    test_passed = test_passed and fat_id.minimum_absolute_temperature == 5
    if not test_passed then print("minimum_absolute_temperature", 5, fat_id.minimum_absolute_temperature) end
    test_passed = test_passed and fat_id.minimum_comfortable_elevation == 12
    if not test_passed then print("minimum_comfortable_elevation", 12, fat_id.minimum_comfortable_elevation) end
    test_passed = test_passed and fat_id.female_body_size == 3
    if not test_passed then print("female_body_size", 3, fat_id.female_body_size) end
    test_passed = test_passed and fat_id.male_body_size == 14
    if not test_passed then print("male_body_size", 14, fat_id.male_body_size) end
    for j = 0, 9 do
        test_passed = test_passed and DATA.race[0].female_efficiency[j] == 8
    end
    if not test_passed then print("female_efficiency", 8, DATA.race[0].female_efficiency[0]) end
    for j = 0, 9 do
        test_passed = test_passed and DATA.race[0].male_efficiency[j] == 12
    end
    if not test_passed then print("male_efficiency", 12, DATA.race[0].male_efficiency[0]) end
    test_passed = test_passed and fat_id.female_infrastructure_needs == -3
    if not test_passed then print("female_infrastructure_needs", -3, fat_id.female_infrastructure_needs) end
    test_passed = test_passed and fat_id.male_infrastructure_needs == -18
    if not test_passed then print("male_infrastructure_needs", -18, fat_id.male_infrastructure_needs) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].female_needs[j].need == 0
    end
    if not test_passed then print("female_needs.need", 0, DATA.race[0].female_needs[0].need) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].female_needs[j].use_case == 11
    end
    if not test_passed then print("female_needs.use_case", 11, DATA.race[0].female_needs[0].use_case) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].female_needs[j].required == 9
    end
    if not test_passed then print("female_needs.required", 9, DATA.race[0].female_needs[0].required) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].male_needs[j].need == 5
    end
    if not test_passed then print("male_needs.need", 5, DATA.race[0].male_needs[0].need) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].male_needs[j].use_case == 12
    end
    if not test_passed then print("male_needs.use_case", 12, DATA.race[0].male_needs[0].use_case) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.race[0].male_needs[j].required == 7
    end
    if not test_passed then print("male_needs.required", 7, DATA.race[0].male_needs[0].required) end
    test_passed = test_passed and fat_id.requires_large_river == true
    if not test_passed then print("requires_large_river", true, fat_id.requires_large_river) end
    test_passed = test_passed and fat_id.requires_large_forest == true
    if not test_passed then print("requires_large_forest", true, fat_id.requires_large_forest) end
    print("SET_GET_TEST_2_race:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_pop(0)
    fat_id.race = 1
    fat_id.female = true
    fat_id.age = 2
    fat_id.savings = 3
    fat_id.parent = 5
    fat_id.loyalty = 9
    fat_id.life_needs_satisfaction = -4
    fat_id.basic_needs_satisfaction = 18
    for j = 0, 19 do
        DATA.pop[0].need_satisfaction[j].need = 3
    end
    for j = 0, 19 do
        DATA.pop[0].need_satisfaction[j].use_case = 19
    end
    for j = 0, 19 do
        DATA.pop[0].need_satisfaction[j].consumed = -18
    end
    for j = 0, 19 do
        DATA.pop[0].need_satisfaction[j].demanded = 17
    end
    for j = 0, 9 do
        DATA.pop[0].traits[j] = 10
    end
    fat_id.successor = 5
    for j = 0, 99 do
        DATA.pop[0].inventory[j] = 7
    end
    for j = 0, 99 do
        DATA.pop[0].price_memory[j] = 20
    end
    fat_id.forage_ratio = 5
    fat_id.work_ratio = 12
    fat_id.rank = 2
    for j = 0, 19 do
        DATA.pop[0].dna[j] = 14
    end
    local test_passed = true
    test_passed = test_passed and fat_id.race == 1
    if not test_passed then print("race", 1, fat_id.race) end
    test_passed = test_passed and fat_id.female == true
    if not test_passed then print("female", true, fat_id.female) end
    test_passed = test_passed and fat_id.age == 2
    if not test_passed then print("age", 2, fat_id.age) end
    test_passed = test_passed and fat_id.savings == 3
    if not test_passed then print("savings", 3, fat_id.savings) end
    test_passed = test_passed and fat_id.parent == 5
    if not test_passed then print("parent", 5, fat_id.parent) end
    test_passed = test_passed and fat_id.loyalty == 9
    if not test_passed then print("loyalty", 9, fat_id.loyalty) end
    test_passed = test_passed and fat_id.life_needs_satisfaction == -4
    if not test_passed then print("life_needs_satisfaction", -4, fat_id.life_needs_satisfaction) end
    test_passed = test_passed and fat_id.basic_needs_satisfaction == 18
    if not test_passed then print("basic_needs_satisfaction", 18, fat_id.basic_needs_satisfaction) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].need_satisfaction[j].need == 3
    end
    if not test_passed then print("need_satisfaction.need", 3, DATA.pop[0].need_satisfaction[0].need) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].need_satisfaction[j].use_case == 19
    end
    if not test_passed then print("need_satisfaction.use_case", 19, DATA.pop[0].need_satisfaction[0].use_case) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].need_satisfaction[j].consumed == -18
    end
    if not test_passed then print("need_satisfaction.consumed", -18, DATA.pop[0].need_satisfaction[0].consumed) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].need_satisfaction[j].demanded == 17
    end
    if not test_passed then print("need_satisfaction.demanded", 17, DATA.pop[0].need_satisfaction[0].demanded) end
    for j = 0, 9 do
        test_passed = test_passed and DATA.pop[0].traits[j] == 10
    end
    if not test_passed then print("traits", 10, DATA.pop[0].traits[0]) end
    test_passed = test_passed and fat_id.successor == 5
    if not test_passed then print("successor", 5, fat_id.successor) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.pop[0].inventory[j] == 7
    end
    if not test_passed then print("inventory", 7, DATA.pop[0].inventory[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.pop[0].price_memory[j] == 20
    end
    if not test_passed then print("price_memory", 20, DATA.pop[0].price_memory[0]) end
    test_passed = test_passed and fat_id.forage_ratio == 5
    if not test_passed then print("forage_ratio", 5, fat_id.forage_ratio) end
    test_passed = test_passed and fat_id.work_ratio == 12
    if not test_passed then print("work_ratio", 12, fat_id.work_ratio) end
    test_passed = test_passed and fat_id.rank == 2
    if not test_passed then print("rank", 2, fat_id.rank) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.pop[0].dna[j] == 14
    end
    if not test_passed then print("dna", 14, DATA.pop[0].dna[0]) end
    print("SET_GET_TEST_2_pop:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_province(0)
    fat_id.r = -17
    fat_id.g = -15
    fat_id.b = -15
    fat_id.is_land = false
    fat_id.province_id = -10
    fat_id.size = -1
    fat_id.hydration = -4
    fat_id.movement_cost = 18
    fat_id.center = 6
    fat_id.infrastructure_needed = 18
    fat_id.infrastructure = -18
    fat_id.infrastructure_investment = 17
    for j = 0, 99 do
        DATA.province[0].local_production[j] = -10
    end
    for j = 0, 99 do
        DATA.province[0].local_consumption[j] = 7
    end
    for j = 0, 99 do
        DATA.province[0].local_demand[j] = 20
    end
    for j = 0, 99 do
        DATA.province[0].local_storage[j] = 5
    end
    for j = 0, 99 do
        DATA.province[0].local_prices[j] = 12
    end
    fat_id.local_wealth = 3
    fat_id.trade_wealth = 14
    fat_id.local_income = 8
    fat_id.local_building_upkeep = 12
    fat_id.foragers = -3
    fat_id.foragers_water = -18
    fat_id.foragers_limit = -19
    for j = 0, 24 do
        DATA.province[0].local_resources[j].resource = 11
    end
    for j = 0, 24 do
        DATA.province[0].local_resources[j].location = 14
    end
    fat_id.mood = 0
    for j = 0, 19 do
        DATA.province[0].unit_types[j] = 12
    end
    fat_id.on_a_river = false
    fat_id.on_a_forest = true
    local test_passed = true
    test_passed = test_passed and fat_id.r == -17
    if not test_passed then print("r", -17, fat_id.r) end
    test_passed = test_passed and fat_id.g == -15
    if not test_passed then print("g", -15, fat_id.g) end
    test_passed = test_passed and fat_id.b == -15
    if not test_passed then print("b", -15, fat_id.b) end
    test_passed = test_passed and fat_id.is_land == false
    if not test_passed then print("is_land", false, fat_id.is_land) end
    test_passed = test_passed and fat_id.province_id == -10
    if not test_passed then print("province_id", -10, fat_id.province_id) end
    test_passed = test_passed and fat_id.size == -1
    if not test_passed then print("size", -1, fat_id.size) end
    test_passed = test_passed and fat_id.hydration == -4
    if not test_passed then print("hydration", -4, fat_id.hydration) end
    test_passed = test_passed and fat_id.movement_cost == 18
    if not test_passed then print("movement_cost", 18, fat_id.movement_cost) end
    test_passed = test_passed and fat_id.center == 6
    if not test_passed then print("center", 6, fat_id.center) end
    test_passed = test_passed and fat_id.infrastructure_needed == 18
    if not test_passed then print("infrastructure_needed", 18, fat_id.infrastructure_needed) end
    test_passed = test_passed and fat_id.infrastructure == -18
    if not test_passed then print("infrastructure", -18, fat_id.infrastructure) end
    test_passed = test_passed and fat_id.infrastructure_investment == 17
    if not test_passed then print("infrastructure_investment", 17, fat_id.infrastructure_investment) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_production[j] == -10
    end
    if not test_passed then print("local_production", -10, DATA.province[0].local_production[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_consumption[j] == 7
    end
    if not test_passed then print("local_consumption", 7, DATA.province[0].local_consumption[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_demand[j] == 20
    end
    if not test_passed then print("local_demand", 20, DATA.province[0].local_demand[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_storage[j] == 5
    end
    if not test_passed then print("local_storage", 5, DATA.province[0].local_storage[0]) end
    for j = 0, 99 do
        test_passed = test_passed and DATA.province[0].local_prices[j] == 12
    end
    if not test_passed then print("local_prices", 12, DATA.province[0].local_prices[0]) end
    test_passed = test_passed and fat_id.local_wealth == 3
    if not test_passed then print("local_wealth", 3, fat_id.local_wealth) end
    test_passed = test_passed and fat_id.trade_wealth == 14
    if not test_passed then print("trade_wealth", 14, fat_id.trade_wealth) end
    test_passed = test_passed and fat_id.local_income == 8
    if not test_passed then print("local_income", 8, fat_id.local_income) end
    test_passed = test_passed and fat_id.local_building_upkeep == 12
    if not test_passed then print("local_building_upkeep", 12, fat_id.local_building_upkeep) end
    test_passed = test_passed and fat_id.foragers == -3
    if not test_passed then print("foragers", -3, fat_id.foragers) end
    test_passed = test_passed and fat_id.foragers_water == -18
    if not test_passed then print("foragers_water", -18, fat_id.foragers_water) end
    test_passed = test_passed and fat_id.foragers_limit == -19
    if not test_passed then print("foragers_limit", -19, fat_id.foragers_limit) end
    for j = 0, 24 do
        test_passed = test_passed and DATA.province[0].local_resources[j].resource == 11
    end
    if not test_passed then print("local_resources.resource", 11, DATA.province[0].local_resources[0].resource) end
    for j = 0, 24 do
        test_passed = test_passed and DATA.province[0].local_resources[j].location == 14
    end
    if not test_passed then print("local_resources.location", 14, DATA.province[0].local_resources[0].location) end
    test_passed = test_passed and fat_id.mood == 0
    if not test_passed then print("mood", 0, fat_id.mood) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.province[0].unit_types[j] == 12
    end
    if not test_passed then print("unit_types", 12, DATA.province[0].unit_types[0]) end
    test_passed = test_passed and fat_id.on_a_river == false
    if not test_passed then print("on_a_river", false, fat_id.on_a_river) end
    test_passed = test_passed and fat_id.on_a_forest == true
    if not test_passed then print("on_a_forest", true, fat_id.on_a_forest) end
    print("SET_GET_TEST_2_province:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_army(0)
    fat_id.destination = 1
    local test_passed = true
    test_passed = test_passed and fat_id.destination == 1
    if not test_passed then print("destination", 1, fat_id.destination) end
    print("SET_GET_TEST_2_army:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband(0)
    for j = 0, 19 do
        DATA.warband[0].units_current[j] = -17
    end
    for j = 0, 19 do
        DATA.warband[0].units_target[j] = -15
    end
    fat_id.status = 1
    fat_id.idle_stance = 1
    fat_id.current_free_time_ratio = -10
    fat_id.treasury = -1
    fat_id.total_upkeep = -4
    fat_id.predicted_upkeep = 18
    fat_id.supplies = -7
    fat_id.supplies_target_days = 18
    fat_id.morale = -18
    local test_passed = true
    for j = 0, 19 do
        test_passed = test_passed and DATA.warband[0].units_current[j] == -17
    end
    if not test_passed then print("units_current", -17, DATA.warband[0].units_current[0]) end
    for j = 0, 19 do
        test_passed = test_passed and DATA.warband[0].units_target[j] == -15
    end
    if not test_passed then print("units_target", -15, DATA.warband[0].units_target[0]) end
    test_passed = test_passed and fat_id.status == 1
    if not test_passed then print("status", 1, fat_id.status) end
    test_passed = test_passed and fat_id.idle_stance == 1
    if not test_passed then print("idle_stance", 1, fat_id.idle_stance) end
    test_passed = test_passed and fat_id.current_free_time_ratio == -10
    if not test_passed then print("current_free_time_ratio", -10, fat_id.current_free_time_ratio) end
    test_passed = test_passed and fat_id.treasury == -1
    if not test_passed then print("treasury", -1, fat_id.treasury) end
    test_passed = test_passed and fat_id.total_upkeep == -4
    if not test_passed then print("total_upkeep", -4, fat_id.total_upkeep) end
    test_passed = test_passed and fat_id.predicted_upkeep == 18
    if not test_passed then print("predicted_upkeep", 18, fat_id.predicted_upkeep) end
    test_passed = test_passed and fat_id.supplies == -7
    if not test_passed then print("supplies", -7, fat_id.supplies) end
    test_passed = test_passed and fat_id.supplies_target_days == 18
    if not test_passed then print("supplies_target_days", 18, fat_id.supplies_target_days) end
    test_passed = test_passed and fat_id.morale == -18
    if not test_passed then print("morale", -18, fat_id.morale) end
    print("SET_GET_TEST_2_warband:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_army_membership(0)
    local test_passed = true
    print("SET_GET_TEST_2_army_membership:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_leader(0)
    local test_passed = true
    print("SET_GET_TEST_2_warband_leader:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_recruiter(0)
    local test_passed = true
    print("SET_GET_TEST_2_warband_recruiter:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_commander(0)
    local test_passed = true
    print("SET_GET_TEST_2_warband_commander:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_location(0)
    local test_passed = true
    print("SET_GET_TEST_2_warband_location:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_warband_unit(0)
    fat_id.type = 1
    local test_passed = true
    test_passed = test_passed and fat_id.type == 1
    if not test_passed then print("type", 1, fat_id.type) end
    print("SET_GET_TEST_2_warband_unit:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_character_location(0)
    local test_passed = true
    print("SET_GET_TEST_2_character_location:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_home(0)
    local test_passed = true
    print("SET_GET_TEST_2_home:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_pop_location(0)
    local test_passed = true
    print("SET_GET_TEST_2_pop_location:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_outlaw_location(0)
    local test_passed = true
    print("SET_GET_TEST_2_outlaw_location:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_tile_province_membership(0)
    local test_passed = true
    print("SET_GET_TEST_2_tile_province_membership:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_province_neighborhood(0)
    local test_passed = true
    print("SET_GET_TEST_2_province_neighborhood:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_parent_child_relation(0)
    local test_passed = true
    print("SET_GET_TEST_2_parent_child_relation:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_loyalty(0)
    local test_passed = true
    print("SET_GET_TEST_2_loyalty:")
    if test_passed then print("PASSED") else print("ERROR") end
    local fat_id = DATA.fatten_succession(0)
    local test_passed = true
    print("SET_GET_TEST_2_succession:")
    if test_passed then print("PASSED") else print("ERROR") end
end
return DATA
