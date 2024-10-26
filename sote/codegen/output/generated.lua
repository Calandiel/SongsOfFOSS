local ffi = require("ffi")
ffi.cdef[[
    void* calloc( size_t num, size_t size );
]]
local bitser = require("engine.bitser")

DATA = {}
---@class struct_budget_per_category_data
---@field ratio number
---@field budget number
---@field to_be_invested number
---@field target number
ffi.cdef[[
    typedef struct {
        float ratio;
        float budget;
        float to_be_invested;
        float target;
    } budget_per_category_data;
]]
---@class struct_trade_good_container
---@field good trade_good_id
---@field amount number
ffi.cdef[[
    typedef struct {
        uint32_t good;
        float amount;
    } trade_good_container;
]]
---@class struct_use_case_container
---@field use use_case_id
---@field amount number
ffi.cdef[[
    typedef struct {
        uint32_t use;
        float amount;
    } use_case_container;
]]
---@class struct_forage_container
---@field output_good trade_good_id
---@field output_value number
---@field amount number
---@field forage FORAGE_RESOURCE
ffi.cdef[[
    typedef struct {
        uint32_t output_good;
        float output_value;
        float amount;
        uint8_t forage;
    } forage_container;
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
---@class struct_job_container
---@field job job_id
---@field amount number
ffi.cdef[[
    typedef struct {
        uint32_t job;
        uint32_t amount;
    } job_container;
]]
----------tile----------


---tile: LSP types---

---Unique identificator for tile entity
---@class (exact) tile_id : number
---@field is_tile nil

---@class (exact) fat_tile_id
---@field id tile_id Unique tile id
---@field world_id number
---@field is_land boolean
---@field is_fresh boolean
---@field is_border boolean
---@field elevation number
---@field slope number
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
---@field january_rain number
---@field january_temperature number
---@field july_waterflow number
---@field july_rain number
---@field july_temperature number
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
---@field world_id number
---@field is_land boolean
---@field is_fresh boolean
---@field is_border boolean
---@field elevation number
---@field slope number
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
---@field january_rain number
---@field january_temperature number
---@field july_waterflow number
---@field july_rain number
---@field july_temperature number
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


ffi.cdef[[
void dcon_tile_set_world_id(int32_t, uint32_t);
uint32_t dcon_tile_get_world_id(int32_t);
void dcon_tile_set_is_land(int32_t, bool);
bool dcon_tile_get_is_land(int32_t);
void dcon_tile_set_is_fresh(int32_t, bool);
bool dcon_tile_get_is_fresh(int32_t);
void dcon_tile_set_is_border(int32_t, bool);
bool dcon_tile_get_is_border(int32_t);
void dcon_tile_set_elevation(int32_t, float);
float dcon_tile_get_elevation(int32_t);
void dcon_tile_set_slope(int32_t, float);
float dcon_tile_get_slope(int32_t);
void dcon_tile_set_grass(int32_t, float);
float dcon_tile_get_grass(int32_t);
void dcon_tile_set_shrub(int32_t, float);
float dcon_tile_get_shrub(int32_t);
void dcon_tile_set_conifer(int32_t, float);
float dcon_tile_get_conifer(int32_t);
void dcon_tile_set_broadleaf(int32_t, float);
float dcon_tile_get_broadleaf(int32_t);
void dcon_tile_set_ideal_grass(int32_t, float);
float dcon_tile_get_ideal_grass(int32_t);
void dcon_tile_set_ideal_shrub(int32_t, float);
float dcon_tile_get_ideal_shrub(int32_t);
void dcon_tile_set_ideal_conifer(int32_t, float);
float dcon_tile_get_ideal_conifer(int32_t);
void dcon_tile_set_ideal_broadleaf(int32_t, float);
float dcon_tile_get_ideal_broadleaf(int32_t);
void dcon_tile_set_silt(int32_t, float);
float dcon_tile_get_silt(int32_t);
void dcon_tile_set_clay(int32_t, float);
float dcon_tile_get_clay(int32_t);
void dcon_tile_set_sand(int32_t, float);
float dcon_tile_get_sand(int32_t);
void dcon_tile_set_soil_minerals(int32_t, float);
float dcon_tile_get_soil_minerals(int32_t);
void dcon_tile_set_soil_organics(int32_t, float);
float dcon_tile_get_soil_organics(int32_t);
void dcon_tile_set_january_waterflow(int32_t, float);
float dcon_tile_get_january_waterflow(int32_t);
void dcon_tile_set_january_rain(int32_t, float);
float dcon_tile_get_january_rain(int32_t);
void dcon_tile_set_january_temperature(int32_t, float);
float dcon_tile_get_january_temperature(int32_t);
void dcon_tile_set_july_waterflow(int32_t, float);
float dcon_tile_get_july_waterflow(int32_t);
void dcon_tile_set_july_rain(int32_t, float);
float dcon_tile_get_july_rain(int32_t);
void dcon_tile_set_july_temperature(int32_t, float);
float dcon_tile_get_july_temperature(int32_t);
void dcon_tile_set_waterlevel(int32_t, float);
float dcon_tile_get_waterlevel(int32_t);
void dcon_tile_set_has_river(int32_t, bool);
bool dcon_tile_get_has_river(int32_t);
void dcon_tile_set_has_marsh(int32_t, bool);
bool dcon_tile_get_has_marsh(int32_t);
void dcon_tile_set_ice(int32_t, float);
float dcon_tile_get_ice(int32_t);
void dcon_tile_set_ice_age_ice(int32_t, float);
float dcon_tile_get_ice_age_ice(int32_t);
void dcon_tile_set_debug_r(int32_t, float);
float dcon_tile_get_debug_r(int32_t);
void dcon_tile_set_debug_g(int32_t, float);
float dcon_tile_get_debug_g(int32_t);
void dcon_tile_set_debug_b(int32_t, float);
float dcon_tile_get_debug_b(int32_t);
void dcon_tile_set_real_r(int32_t, float);
float dcon_tile_get_real_r(int32_t);
void dcon_tile_set_real_g(int32_t, float);
float dcon_tile_get_real_g(int32_t);
void dcon_tile_set_real_b(int32_t, float);
float dcon_tile_get_real_b(int32_t);
void dcon_tile_set_pathfinding_index(int32_t, uint32_t);
uint32_t dcon_tile_get_pathfinding_index(int32_t);
void dcon_tile_set_resource(int32_t, uint32_t);
uint32_t dcon_tile_get_resource(int32_t);
void dcon_tile_set_bedrock(int32_t, uint32_t);
uint32_t dcon_tile_get_bedrock(int32_t);
void dcon_tile_set_biome(int32_t, uint32_t);
uint32_t dcon_tile_get_biome(int32_t);
int32_t dcon_create_tile();
bool dcon_tile_is_valid(int32_t);
void dcon_tile_resize(uint32_t sz);
uint32_t dcon_tile_size();
]]

---tile: FFI arrays---

---tile: LUA bindings---

DATA.tile_size = 1500000
---@return tile_id
function DATA.create_tile()
    ---@type tile_id
    local i  = DCON.dcon_create_tile() + 1
    return i --[[@as tile_id]]
end
---@param func fun(item: tile_id)
function DATA.for_each_tile(func)
    ---@type number
    local range = DCON.dcon_tile_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as tile_id]])
    end
end
---@param func fun(item: tile_id):boolean
---@return table<tile_id, tile_id>
function DATA.filter_tile(func)
    ---@type table<tile_id, tile_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_tile_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as tile_id]]) then t[i + 1 --[[@as tile_id]]] = t[i + 1 --[[@as tile_id]]] end
    end
    return t
end

---@param tile_id tile_id valid tile id
---@return number world_id
function DATA.tile_get_world_id(tile_id)
    return DCON.dcon_tile_get_world_id(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_world_id(tile_id, value)
    DCON.dcon_tile_set_world_id(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_world_id(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_world_id(tile_id - 1)
    DCON.dcon_tile_set_world_id(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return boolean is_land
function DATA.tile_get_is_land(tile_id)
    return DCON.dcon_tile_get_is_land(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value boolean valid boolean
function DATA.tile_set_is_land(tile_id, value)
    DCON.dcon_tile_set_is_land(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@return boolean is_fresh
function DATA.tile_get_is_fresh(tile_id)
    return DCON.dcon_tile_get_is_fresh(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value boolean valid boolean
function DATA.tile_set_is_fresh(tile_id, value)
    DCON.dcon_tile_set_is_fresh(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@return boolean is_border
function DATA.tile_get_is_border(tile_id)
    return DCON.dcon_tile_get_is_border(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value boolean valid boolean
function DATA.tile_set_is_border(tile_id, value)
    DCON.dcon_tile_set_is_border(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@return number elevation
function DATA.tile_get_elevation(tile_id)
    return DCON.dcon_tile_get_elevation(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_elevation(tile_id, value)
    DCON.dcon_tile_set_elevation(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_elevation(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_elevation(tile_id - 1)
    DCON.dcon_tile_set_elevation(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number slope
function DATA.tile_get_slope(tile_id)
    return DCON.dcon_tile_get_slope(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_slope(tile_id, value)
    DCON.dcon_tile_set_slope(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_slope(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_slope(tile_id - 1)
    DCON.dcon_tile_set_slope(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number grass
function DATA.tile_get_grass(tile_id)
    return DCON.dcon_tile_get_grass(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_grass(tile_id, value)
    DCON.dcon_tile_set_grass(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_grass(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_grass(tile_id - 1)
    DCON.dcon_tile_set_grass(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number shrub
function DATA.tile_get_shrub(tile_id)
    return DCON.dcon_tile_get_shrub(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_shrub(tile_id, value)
    DCON.dcon_tile_set_shrub(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_shrub(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_shrub(tile_id - 1)
    DCON.dcon_tile_set_shrub(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number conifer
function DATA.tile_get_conifer(tile_id)
    return DCON.dcon_tile_get_conifer(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_conifer(tile_id, value)
    DCON.dcon_tile_set_conifer(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_conifer(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_conifer(tile_id - 1)
    DCON.dcon_tile_set_conifer(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number broadleaf
function DATA.tile_get_broadleaf(tile_id)
    return DCON.dcon_tile_get_broadleaf(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_broadleaf(tile_id, value)
    DCON.dcon_tile_set_broadleaf(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_broadleaf(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_broadleaf(tile_id - 1)
    DCON.dcon_tile_set_broadleaf(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number ideal_grass
function DATA.tile_get_ideal_grass(tile_id)
    return DCON.dcon_tile_get_ideal_grass(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_ideal_grass(tile_id, value)
    DCON.dcon_tile_set_ideal_grass(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_ideal_grass(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_ideal_grass(tile_id - 1)
    DCON.dcon_tile_set_ideal_grass(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number ideal_shrub
function DATA.tile_get_ideal_shrub(tile_id)
    return DCON.dcon_tile_get_ideal_shrub(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_ideal_shrub(tile_id, value)
    DCON.dcon_tile_set_ideal_shrub(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_ideal_shrub(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_ideal_shrub(tile_id - 1)
    DCON.dcon_tile_set_ideal_shrub(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number ideal_conifer
function DATA.tile_get_ideal_conifer(tile_id)
    return DCON.dcon_tile_get_ideal_conifer(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_ideal_conifer(tile_id, value)
    DCON.dcon_tile_set_ideal_conifer(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_ideal_conifer(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_ideal_conifer(tile_id - 1)
    DCON.dcon_tile_set_ideal_conifer(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number ideal_broadleaf
function DATA.tile_get_ideal_broadleaf(tile_id)
    return DCON.dcon_tile_get_ideal_broadleaf(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_ideal_broadleaf(tile_id, value)
    DCON.dcon_tile_set_ideal_broadleaf(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_ideal_broadleaf(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_ideal_broadleaf(tile_id - 1)
    DCON.dcon_tile_set_ideal_broadleaf(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number silt
function DATA.tile_get_silt(tile_id)
    return DCON.dcon_tile_get_silt(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_silt(tile_id, value)
    DCON.dcon_tile_set_silt(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_silt(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_silt(tile_id - 1)
    DCON.dcon_tile_set_silt(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number clay
function DATA.tile_get_clay(tile_id)
    return DCON.dcon_tile_get_clay(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_clay(tile_id, value)
    DCON.dcon_tile_set_clay(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_clay(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_clay(tile_id - 1)
    DCON.dcon_tile_set_clay(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number sand
function DATA.tile_get_sand(tile_id)
    return DCON.dcon_tile_get_sand(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_sand(tile_id, value)
    DCON.dcon_tile_set_sand(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_sand(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_sand(tile_id - 1)
    DCON.dcon_tile_set_sand(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number soil_minerals
function DATA.tile_get_soil_minerals(tile_id)
    return DCON.dcon_tile_get_soil_minerals(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_soil_minerals(tile_id, value)
    DCON.dcon_tile_set_soil_minerals(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_soil_minerals(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_soil_minerals(tile_id - 1)
    DCON.dcon_tile_set_soil_minerals(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number soil_organics
function DATA.tile_get_soil_organics(tile_id)
    return DCON.dcon_tile_get_soil_organics(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_soil_organics(tile_id, value)
    DCON.dcon_tile_set_soil_organics(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_soil_organics(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_soil_organics(tile_id - 1)
    DCON.dcon_tile_set_soil_organics(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number january_waterflow
function DATA.tile_get_january_waterflow(tile_id)
    return DCON.dcon_tile_get_january_waterflow(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_january_waterflow(tile_id, value)
    DCON.dcon_tile_set_january_waterflow(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_january_waterflow(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_january_waterflow(tile_id - 1)
    DCON.dcon_tile_set_january_waterflow(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number january_rain
function DATA.tile_get_january_rain(tile_id)
    return DCON.dcon_tile_get_january_rain(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_january_rain(tile_id, value)
    DCON.dcon_tile_set_january_rain(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_january_rain(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_january_rain(tile_id - 1)
    DCON.dcon_tile_set_january_rain(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number january_temperature
function DATA.tile_get_january_temperature(tile_id)
    return DCON.dcon_tile_get_january_temperature(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_january_temperature(tile_id, value)
    DCON.dcon_tile_set_january_temperature(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_january_temperature(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_january_temperature(tile_id - 1)
    DCON.dcon_tile_set_january_temperature(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number july_waterflow
function DATA.tile_get_july_waterflow(tile_id)
    return DCON.dcon_tile_get_july_waterflow(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_july_waterflow(tile_id, value)
    DCON.dcon_tile_set_july_waterflow(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_july_waterflow(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_july_waterflow(tile_id - 1)
    DCON.dcon_tile_set_july_waterflow(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number july_rain
function DATA.tile_get_july_rain(tile_id)
    return DCON.dcon_tile_get_july_rain(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_july_rain(tile_id, value)
    DCON.dcon_tile_set_july_rain(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_july_rain(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_july_rain(tile_id - 1)
    DCON.dcon_tile_set_july_rain(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number july_temperature
function DATA.tile_get_july_temperature(tile_id)
    return DCON.dcon_tile_get_july_temperature(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_july_temperature(tile_id, value)
    DCON.dcon_tile_set_july_temperature(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_july_temperature(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_july_temperature(tile_id - 1)
    DCON.dcon_tile_set_july_temperature(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number waterlevel
function DATA.tile_get_waterlevel(tile_id)
    return DCON.dcon_tile_get_waterlevel(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_waterlevel(tile_id, value)
    DCON.dcon_tile_set_waterlevel(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_waterlevel(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_waterlevel(tile_id - 1)
    DCON.dcon_tile_set_waterlevel(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return boolean has_river
function DATA.tile_get_has_river(tile_id)
    return DCON.dcon_tile_get_has_river(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value boolean valid boolean
function DATA.tile_set_has_river(tile_id, value)
    DCON.dcon_tile_set_has_river(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@return boolean has_marsh
function DATA.tile_get_has_marsh(tile_id)
    return DCON.dcon_tile_get_has_marsh(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value boolean valid boolean
function DATA.tile_set_has_marsh(tile_id, value)
    DCON.dcon_tile_set_has_marsh(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@return number ice
function DATA.tile_get_ice(tile_id)
    return DCON.dcon_tile_get_ice(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_ice(tile_id, value)
    DCON.dcon_tile_set_ice(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_ice(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_ice(tile_id - 1)
    DCON.dcon_tile_set_ice(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number ice_age_ice
function DATA.tile_get_ice_age_ice(tile_id)
    return DCON.dcon_tile_get_ice_age_ice(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_ice_age_ice(tile_id, value)
    DCON.dcon_tile_set_ice_age_ice(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_ice_age_ice(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_ice_age_ice(tile_id - 1)
    DCON.dcon_tile_set_ice_age_ice(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number debug_r between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_debug_r(tile_id)
    return DCON.dcon_tile_get_debug_r(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_debug_r(tile_id, value)
    DCON.dcon_tile_set_debug_r(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_debug_r(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_debug_r(tile_id - 1)
    DCON.dcon_tile_set_debug_r(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number debug_g between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_debug_g(tile_id)
    return DCON.dcon_tile_get_debug_g(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_debug_g(tile_id, value)
    DCON.dcon_tile_set_debug_g(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_debug_g(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_debug_g(tile_id - 1)
    DCON.dcon_tile_set_debug_g(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number debug_b between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_debug_b(tile_id)
    return DCON.dcon_tile_get_debug_b(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_debug_b(tile_id, value)
    DCON.dcon_tile_set_debug_b(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_debug_b(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_debug_b(tile_id - 1)
    DCON.dcon_tile_set_debug_b(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number real_r between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_real_r(tile_id)
    return DCON.dcon_tile_get_real_r(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_real_r(tile_id, value)
    DCON.dcon_tile_set_real_r(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_real_r(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_real_r(tile_id - 1)
    DCON.dcon_tile_set_real_r(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number real_g between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_real_g(tile_id)
    return DCON.dcon_tile_get_real_g(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_real_g(tile_id, value)
    DCON.dcon_tile_set_real_g(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_real_g(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_real_g(tile_id - 1)
    DCON.dcon_tile_set_real_g(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number real_b between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_real_b(tile_id)
    return DCON.dcon_tile_get_real_b(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_real_b(tile_id, value)
    DCON.dcon_tile_set_real_b(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_real_b(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_real_b(tile_id - 1)
    DCON.dcon_tile_set_real_b(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return number pathfinding_index
function DATA.tile_get_pathfinding_index(tile_id)
    return DCON.dcon_tile_get_pathfinding_index(tile_id - 1)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_set_pathfinding_index(tile_id, value)
    DCON.dcon_tile_set_pathfinding_index(tile_id - 1, value)
end
---@param tile_id tile_id valid tile id
---@param value number valid number
function DATA.tile_inc_pathfinding_index(tile_id, value)
    ---@type number
    local current = DCON.dcon_tile_get_pathfinding_index(tile_id - 1)
    DCON.dcon_tile_set_pathfinding_index(tile_id - 1, current + value)
end
---@param tile_id tile_id valid tile id
---@return resource_id resource
function DATA.tile_get_resource(tile_id)
    return DCON.dcon_tile_get_resource(tile_id - 1) + 1
end
---@param tile_id tile_id valid tile id
---@param value resource_id valid resource_id
function DATA.tile_set_resource(tile_id, value)
    DCON.dcon_tile_set_resource(tile_id - 1, value - 1)
end
---@param tile_id tile_id valid tile id
---@return bedrock_id bedrock
function DATA.tile_get_bedrock(tile_id)
    return DCON.dcon_tile_get_bedrock(tile_id - 1) + 1
end
---@param tile_id tile_id valid tile id
---@param value bedrock_id valid bedrock_id
function DATA.tile_set_bedrock(tile_id, value)
    DCON.dcon_tile_set_bedrock(tile_id - 1, value - 1)
end
---@param tile_id tile_id valid tile id
---@return biome_id biome
function DATA.tile_get_biome(tile_id)
    return DCON.dcon_tile_get_biome(tile_id - 1) + 1
end
---@param tile_id tile_id valid tile id
---@param value biome_id valid biome_id
function DATA.tile_set_biome(tile_id, value)
    DCON.dcon_tile_set_biome(tile_id - 1, value - 1)
end

local fat_tile_id_metatable = {
    __index = function (t,k)
        if (k == "world_id") then return DATA.tile_get_world_id(t.id) end
        if (k == "is_land") then return DATA.tile_get_is_land(t.id) end
        if (k == "is_fresh") then return DATA.tile_get_is_fresh(t.id) end
        if (k == "is_border") then return DATA.tile_get_is_border(t.id) end
        if (k == "elevation") then return DATA.tile_get_elevation(t.id) end
        if (k == "slope") then return DATA.tile_get_slope(t.id) end
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
        if (k == "january_rain") then return DATA.tile_get_january_rain(t.id) end
        if (k == "january_temperature") then return DATA.tile_get_january_temperature(t.id) end
        if (k == "july_waterflow") then return DATA.tile_get_july_waterflow(t.id) end
        if (k == "july_rain") then return DATA.tile_get_july_rain(t.id) end
        if (k == "july_temperature") then return DATA.tile_get_july_temperature(t.id) end
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
        if (k == "world_id") then
            DATA.tile_set_world_id(t.id, v)
            return
        end
        if (k == "is_land") then
            DATA.tile_set_is_land(t.id, v)
            return
        end
        if (k == "is_fresh") then
            DATA.tile_set_is_fresh(t.id, v)
            return
        end
        if (k == "is_border") then
            DATA.tile_set_is_border(t.id, v)
            return
        end
        if (k == "elevation") then
            DATA.tile_set_elevation(t.id, v)
            return
        end
        if (k == "slope") then
            DATA.tile_set_slope(t.id, v)
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
        if (k == "january_rain") then
            DATA.tile_set_january_rain(t.id, v)
            return
        end
        if (k == "january_temperature") then
            DATA.tile_set_january_temperature(t.id, v)
            return
        end
        if (k == "july_waterflow") then
            DATA.tile_set_july_waterflow(t.id, v)
            return
        end
        if (k == "july_rain") then
            DATA.tile_set_july_rain(t.id, v)
            return
        end
        if (k == "july_temperature") then
            DATA.tile_set_july_temperature(t.id, v)
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
----------pop----------


---pop: LSP types---

---Unique identificator for pop entity
---@class (exact) pop_id : number
---@field is_pop nil

---@class (exact) fat_pop_id
---@field id pop_id Unique pop id
---@field race race_id
---@field faith Faith
---@field culture Culture
---@field female boolean
---@field age number
---@field name string
---@field savings number
---@field life_needs_satisfaction number from 0 to 1
---@field basic_needs_satisfaction number from 0 to 1
---@field pending_economy_income number
---@field forage_ratio number a number in (0, 1) interval representing a ratio of time pop spends to forage
---@field work_ratio number a number in (0, 1) interval representing a ratio of time workers spend on a job compared to maximal
---@field busy boolean
---@field dead boolean
---@field rank CHARACTER_RANK
---@field former_pop boolean

---@class struct_pop
---@field race race_id
---@field female boolean
---@field age number
---@field savings number
---@field life_needs_satisfaction number from 0 to 1
---@field basic_needs_satisfaction number from 0 to 1
---@field need_satisfaction table<number, struct_need_satisfaction>
---@field traits table<number, TRAIT>
---@field inventory table<trade_good_id, number>
---@field price_memory table<trade_good_id, number>
---@field pending_economy_income number
---@field forage_ratio number a number in (0, 1) interval representing a ratio of time pop spends to forage
---@field work_ratio number a number in (0, 1) interval representing a ratio of time workers spend on a job compared to maximal
---@field rank CHARACTER_RANK
---@field dna table<number, number>


ffi.cdef[[
void dcon_pop_set_race(int32_t, uint32_t);
uint32_t dcon_pop_get_race(int32_t);
void dcon_pop_set_female(int32_t, bool);
bool dcon_pop_get_female(int32_t);
void dcon_pop_set_age(int32_t, uint32_t);
uint32_t dcon_pop_get_age(int32_t);
void dcon_pop_set_savings(int32_t, float);
float dcon_pop_get_savings(int32_t);
void dcon_pop_set_life_needs_satisfaction(int32_t, float);
float dcon_pop_get_life_needs_satisfaction(int32_t);
void dcon_pop_set_basic_needs_satisfaction(int32_t, float);
float dcon_pop_get_basic_needs_satisfaction(int32_t);
void dcon_pop_resize_need_satisfaction(uint32_t);
need_satisfaction* dcon_pop_get_need_satisfaction(int32_t, int32_t);
void dcon_pop_resize_traits(uint32_t);
void dcon_pop_set_traits(int32_t, int32_t, uint8_t);
uint8_t dcon_pop_get_traits(int32_t, int32_t);
void dcon_pop_resize_inventory(uint32_t);
void dcon_pop_set_inventory(int32_t, int32_t, float);
float dcon_pop_get_inventory(int32_t, int32_t);
void dcon_pop_resize_price_memory(uint32_t);
void dcon_pop_set_price_memory(int32_t, int32_t, float);
float dcon_pop_get_price_memory(int32_t, int32_t);
void dcon_pop_set_pending_economy_income(int32_t, float);
float dcon_pop_get_pending_economy_income(int32_t);
void dcon_pop_set_forage_ratio(int32_t, float);
float dcon_pop_get_forage_ratio(int32_t);
void dcon_pop_set_work_ratio(int32_t, float);
float dcon_pop_get_work_ratio(int32_t);
void dcon_pop_set_rank(int32_t, uint8_t);
uint8_t dcon_pop_get_rank(int32_t);
void dcon_pop_resize_dna(uint32_t);
void dcon_pop_set_dna(int32_t, int32_t, float);
float dcon_pop_get_dna(int32_t, int32_t);
void dcon_delete_pop(int32_t j);
int32_t dcon_create_pop();
bool dcon_pop_is_valid(int32_t);
void dcon_pop_resize(uint32_t sz);
uint32_t dcon_pop_size();
]]

---pop: FFI arrays---
---@type (Faith)[]
DATA.pop_faith= {}
---@type (Culture)[]
DATA.pop_culture= {}
---@type (string)[]
DATA.pop_name= {}
---@type (boolean)[]
DATA.pop_busy= {}
---@type (boolean)[]
DATA.pop_dead= {}
---@type (boolean)[]
DATA.pop_former_pop= {}

---pop: LUA bindings---

DATA.pop_size = 300000
DCON.dcon_pop_resize_need_satisfaction(21)
DCON.dcon_pop_resize_traits(11)
DCON.dcon_pop_resize_inventory(101)
DCON.dcon_pop_resize_price_memory(101)
DCON.dcon_pop_resize_dna(21)
---@return pop_id
function DATA.create_pop()
    ---@type pop_id
    local i  = DCON.dcon_create_pop() + 1
    return i --[[@as pop_id]]
end
---@param i pop_id
function DATA.delete_pop(i)
    assert(DCON.dcon_pop_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_pop(i - 1)
end
---@param func fun(item: pop_id)
function DATA.for_each_pop(func)
    ---@type number
    local range = DCON.dcon_pop_size()
    for i = 0, range - 1 do
        if DCON.dcon_pop_is_valid(i) then func(i + 1 --[[@as pop_id]]) end
    end
end
---@param func fun(item: pop_id):boolean
---@return table<pop_id, pop_id>
function DATA.filter_pop(func)
    ---@type table<pop_id, pop_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_size()
    for i = 0, range - 1 do
        if DCON.dcon_pop_is_valid(i) and func(i + 1 --[[@as pop_id]]) then t[i + 1 --[[@as pop_id]]] = t[i + 1 --[[@as pop_id]]] end
    end
    return t
end

---@param pop_id pop_id valid pop id
---@return race_id race
function DATA.pop_get_race(pop_id)
    return DCON.dcon_pop_get_race(pop_id - 1) + 1
end
---@param pop_id pop_id valid pop id
---@param value race_id valid race_id
function DATA.pop_set_race(pop_id, value)
    DCON.dcon_pop_set_race(pop_id - 1, value - 1)
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
    return DCON.dcon_pop_get_female(pop_id - 1)
end
---@param pop_id pop_id valid pop id
---@param value boolean valid boolean
function DATA.pop_set_female(pop_id, value)
    DCON.dcon_pop_set_female(pop_id - 1, value)
end
---@param pop_id pop_id valid pop id
---@return number age
function DATA.pop_get_age(pop_id)
    return DCON.dcon_pop_get_age(pop_id - 1)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_age(pop_id, value)
    DCON.dcon_pop_set_age(pop_id - 1, value)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_inc_age(pop_id, value)
    ---@type number
    local current = DCON.dcon_pop_get_age(pop_id - 1)
    DCON.dcon_pop_set_age(pop_id - 1, current + value)
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
---@return number savings
function DATA.pop_get_savings(pop_id)
    return DCON.dcon_pop_get_savings(pop_id - 1)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_savings(pop_id, value)
    DCON.dcon_pop_set_savings(pop_id - 1, value)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_inc_savings(pop_id, value)
    ---@type number
    local current = DCON.dcon_pop_get_savings(pop_id - 1)
    DCON.dcon_pop_set_savings(pop_id - 1, current + value)
end
---@param pop_id pop_id valid pop id
---@return number life_needs_satisfaction from 0 to 1
function DATA.pop_get_life_needs_satisfaction(pop_id)
    return DCON.dcon_pop_get_life_needs_satisfaction(pop_id - 1)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_life_needs_satisfaction(pop_id, value)
    DCON.dcon_pop_set_life_needs_satisfaction(pop_id - 1, value)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_inc_life_needs_satisfaction(pop_id, value)
    ---@type number
    local current = DCON.dcon_pop_get_life_needs_satisfaction(pop_id - 1)
    DCON.dcon_pop_set_life_needs_satisfaction(pop_id - 1, current + value)
end
---@param pop_id pop_id valid pop id
---@return number basic_needs_satisfaction from 0 to 1
function DATA.pop_get_basic_needs_satisfaction(pop_id)
    return DCON.dcon_pop_get_basic_needs_satisfaction(pop_id - 1)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_basic_needs_satisfaction(pop_id, value)
    DCON.dcon_pop_set_basic_needs_satisfaction(pop_id - 1, value)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_inc_basic_needs_satisfaction(pop_id, value)
    ---@type number
    local current = DCON.dcon_pop_get_basic_needs_satisfaction(pop_id - 1)
    DCON.dcon_pop_set_basic_needs_satisfaction(pop_id - 1, current + value)
end
---@param pop_id pop_id valid pop id
---@param index number valid
---@return NEED need_satisfaction
function DATA.pop_get_need_satisfaction_need(pop_id, index)
    assert(index ~= 0)
    return DCON.dcon_pop_get_need_satisfaction(pop_id - 1, index - 1)[0].need
end
---@param pop_id pop_id valid pop id
---@param index number valid
---@return use_case_id need_satisfaction
function DATA.pop_get_need_satisfaction_use_case(pop_id, index)
    assert(index ~= 0)
    return DCON.dcon_pop_get_need_satisfaction(pop_id - 1, index - 1)[0].use_case
end
---@param pop_id pop_id valid pop id
---@param index number valid
---@return number need_satisfaction
function DATA.pop_get_need_satisfaction_consumed(pop_id, index)
    assert(index ~= 0)
    return DCON.dcon_pop_get_need_satisfaction(pop_id - 1, index - 1)[0].consumed
end
---@param pop_id pop_id valid pop id
---@param index number valid
---@return number need_satisfaction
function DATA.pop_get_need_satisfaction_demanded(pop_id, index)
    assert(index ~= 0)
    return DCON.dcon_pop_get_need_satisfaction(pop_id - 1, index - 1)[0].demanded
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value NEED valid NEED
function DATA.pop_set_need_satisfaction_need(pop_id, index, value)
    DCON.dcon_pop_get_need_satisfaction(pop_id - 1, index - 1)[0].need = value
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value use_case_id valid use_case_id
function DATA.pop_set_need_satisfaction_use_case(pop_id, index, value)
    DCON.dcon_pop_get_need_satisfaction(pop_id - 1, index - 1)[0].use_case = value
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value number valid number
function DATA.pop_set_need_satisfaction_consumed(pop_id, index, value)
    DCON.dcon_pop_get_need_satisfaction(pop_id - 1, index - 1)[0].consumed = value
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value number valid number
function DATA.pop_inc_need_satisfaction_consumed(pop_id, index, value)
    ---@type number
    local current = DCON.dcon_pop_get_need_satisfaction(pop_id - 1, index - 1)[0].consumed
    DCON.dcon_pop_get_need_satisfaction(pop_id - 1, index - 1)[0].consumed = current + value
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value number valid number
function DATA.pop_set_need_satisfaction_demanded(pop_id, index, value)
    DCON.dcon_pop_get_need_satisfaction(pop_id - 1, index - 1)[0].demanded = value
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value number valid number
function DATA.pop_inc_need_satisfaction_demanded(pop_id, index, value)
    ---@type number
    local current = DCON.dcon_pop_get_need_satisfaction(pop_id - 1, index - 1)[0].demanded
    DCON.dcon_pop_get_need_satisfaction(pop_id - 1, index - 1)[0].demanded = current + value
end
---@param pop_id pop_id valid pop id
---@param index number valid
---@return TRAIT traits
function DATA.pop_get_traits(pop_id, index)
    assert(index ~= 0)
    return DCON.dcon_pop_get_traits(pop_id - 1, index - 1)
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value TRAIT valid TRAIT
function DATA.pop_set_traits(pop_id, index, value)
    DCON.dcon_pop_set_traits(pop_id - 1, index - 1, value)
end
---@param pop_id pop_id valid pop id
---@param index trade_good_id valid
---@return number inventory
function DATA.pop_get_inventory(pop_id, index)
    assert(index ~= 0)
    return DCON.dcon_pop_get_inventory(pop_id - 1, index - 1)
end
---@param pop_id pop_id valid pop id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.pop_set_inventory(pop_id, index, value)
    DCON.dcon_pop_set_inventory(pop_id - 1, index - 1, value)
end
---@param pop_id pop_id valid pop id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.pop_inc_inventory(pop_id, index, value)
    ---@type number
    local current = DCON.dcon_pop_get_inventory(pop_id - 1, index - 1)
    DCON.dcon_pop_set_inventory(pop_id - 1, index - 1, current + value)
end
---@param pop_id pop_id valid pop id
---@param index trade_good_id valid
---@return number price_memory
function DATA.pop_get_price_memory(pop_id, index)
    assert(index ~= 0)
    return DCON.dcon_pop_get_price_memory(pop_id - 1, index - 1)
end
---@param pop_id pop_id valid pop id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.pop_set_price_memory(pop_id, index, value)
    DCON.dcon_pop_set_price_memory(pop_id - 1, index - 1, value)
end
---@param pop_id pop_id valid pop id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.pop_inc_price_memory(pop_id, index, value)
    ---@type number
    local current = DCON.dcon_pop_get_price_memory(pop_id - 1, index - 1)
    DCON.dcon_pop_set_price_memory(pop_id - 1, index - 1, current + value)
end
---@param pop_id pop_id valid pop id
---@return number pending_economy_income
function DATA.pop_get_pending_economy_income(pop_id)
    return DCON.dcon_pop_get_pending_economy_income(pop_id - 1)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_pending_economy_income(pop_id, value)
    DCON.dcon_pop_set_pending_economy_income(pop_id - 1, value)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_inc_pending_economy_income(pop_id, value)
    ---@type number
    local current = DCON.dcon_pop_get_pending_economy_income(pop_id - 1)
    DCON.dcon_pop_set_pending_economy_income(pop_id - 1, current + value)
end
---@param pop_id pop_id valid pop id
---@return number forage_ratio a number in (0, 1) interval representing a ratio of time pop spends to forage
function DATA.pop_get_forage_ratio(pop_id)
    return DCON.dcon_pop_get_forage_ratio(pop_id - 1)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_forage_ratio(pop_id, value)
    DCON.dcon_pop_set_forage_ratio(pop_id - 1, value)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_inc_forage_ratio(pop_id, value)
    ---@type number
    local current = DCON.dcon_pop_get_forage_ratio(pop_id - 1)
    DCON.dcon_pop_set_forage_ratio(pop_id - 1, current + value)
end
---@param pop_id pop_id valid pop id
---@return number work_ratio a number in (0, 1) interval representing a ratio of time workers spend on a job compared to maximal
function DATA.pop_get_work_ratio(pop_id)
    return DCON.dcon_pop_get_work_ratio(pop_id - 1)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_set_work_ratio(pop_id, value)
    DCON.dcon_pop_set_work_ratio(pop_id - 1, value)
end
---@param pop_id pop_id valid pop id
---@param value number valid number
function DATA.pop_inc_work_ratio(pop_id, value)
    ---@type number
    local current = DCON.dcon_pop_get_work_ratio(pop_id - 1)
    DCON.dcon_pop_set_work_ratio(pop_id - 1, current + value)
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
---@return CHARACTER_RANK rank
function DATA.pop_get_rank(pop_id)
    return DCON.dcon_pop_get_rank(pop_id - 1)
end
---@param pop_id pop_id valid pop id
---@param value CHARACTER_RANK valid CHARACTER_RANK
function DATA.pop_set_rank(pop_id, value)
    DCON.dcon_pop_set_rank(pop_id - 1, value)
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
    assert(index ~= 0)
    return DCON.dcon_pop_get_dna(pop_id - 1, index - 1)
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value number valid number
function DATA.pop_set_dna(pop_id, index, value)
    DCON.dcon_pop_set_dna(pop_id - 1, index - 1, value)
end
---@param pop_id pop_id valid pop id
---@param index number valid index
---@param value number valid number
function DATA.pop_inc_dna(pop_id, index, value)
    ---@type number
    local current = DCON.dcon_pop_get_dna(pop_id - 1, index - 1)
    DCON.dcon_pop_set_dna(pop_id - 1, index - 1, current + value)
end

local fat_pop_id_metatable = {
    __index = function (t,k)
        if (k == "race") then return DATA.pop_get_race(t.id) end
        if (k == "faith") then return DATA.pop_get_faith(t.id) end
        if (k == "culture") then return DATA.pop_get_culture(t.id) end
        if (k == "female") then return DATA.pop_get_female(t.id) end
        if (k == "age") then return DATA.pop_get_age(t.id) end
        if (k == "name") then return DATA.pop_get_name(t.id) end
        if (k == "savings") then return DATA.pop_get_savings(t.id) end
        if (k == "life_needs_satisfaction") then return DATA.pop_get_life_needs_satisfaction(t.id) end
        if (k == "basic_needs_satisfaction") then return DATA.pop_get_basic_needs_satisfaction(t.id) end
        if (k == "pending_economy_income") then return DATA.pop_get_pending_economy_income(t.id) end
        if (k == "forage_ratio") then return DATA.pop_get_forage_ratio(t.id) end
        if (k == "work_ratio") then return DATA.pop_get_work_ratio(t.id) end
        if (k == "busy") then return DATA.pop_get_busy(t.id) end
        if (k == "dead") then return DATA.pop_get_dead(t.id) end
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
        if (k == "savings") then
            DATA.pop_set_savings(t.id, v)
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
        if (k == "pending_economy_income") then
            DATA.pop_set_pending_economy_income(t.id, v)
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
---@class (exact) province_id : number
---@field is_province nil

---@class (exact) fat_province_id
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
---@field infrastructure_efficiency number
---@field local_wealth number
---@field trade_wealth number
---@field local_income number
---@field local_building_upkeep number
---@field foragers number Keeps track of the number of foragers in the province. Used to calculate yields of independent foraging.
---@field foragers_water number amount foraged by pops and characters
---@field foragers_limit number amount of calories foraged by pops and characters
---@field mood number how local population thinks about the state
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
---@field infrastructure_efficiency number
---@field technologies_present table<technology_id, number>
---@field technologies_researchable table<technology_id, number>
---@field buildable_buildings table<building_type_id, number>
---@field local_production table<trade_good_id, number>
---@field temp_buffer_0 table<trade_good_id, number>
---@field local_consumption table<trade_good_id, number>
---@field local_demand table<trade_good_id, number>
---@field local_satisfaction table<trade_good_id, number>
---@field temp_buffer_use_0 table<use_case_id, number>
---@field temp_buffer_use_grad table<use_case_id, number>
---@field local_use_satisfaction table<use_case_id, number>
---@field local_use_buffer_demand table<use_case_id, number>
---@field local_use_buffer_supply table<use_case_id, number>
---@field local_use_buffer_cost table<use_case_id, number>
---@field local_storage table<trade_good_id, number>
---@field local_prices table<trade_good_id, number>
---@field local_wealth number
---@field trade_wealth number
---@field local_income number
---@field local_building_upkeep number
---@field foragers number Keeps track of the number of foragers in the province. Used to calculate yields of independent foraging.
---@field foragers_water number amount foraged by pops and characters
---@field foragers_limit number amount of calories foraged by pops and characters
---@field foragers_targets table<number, struct_forage_container>
---@field local_resources table<number, struct_resource_location> An array of local resources and their positions
---@field mood number how local population thinks about the state
---@field unit_types table<unit_type_id, number>
---@field throughput_boosts table<production_method_id, number>
---@field input_efficiency_boosts table<production_method_id, number>
---@field output_efficiency_boosts table<production_method_id, number>
---@field on_a_river boolean
---@field on_a_forest boolean


ffi.cdef[[
void dcon_province_set_r(int32_t, float);
float dcon_province_get_r(int32_t);
void dcon_province_set_g(int32_t, float);
float dcon_province_get_g(int32_t);
void dcon_province_set_b(int32_t, float);
float dcon_province_get_b(int32_t);
void dcon_province_set_is_land(int32_t, bool);
bool dcon_province_get_is_land(int32_t);
void dcon_province_set_province_id(int32_t, float);
float dcon_province_get_province_id(int32_t);
void dcon_province_set_size(int32_t, float);
float dcon_province_get_size(int32_t);
void dcon_province_set_hydration(int32_t, float);
float dcon_province_get_hydration(int32_t);
void dcon_province_set_movement_cost(int32_t, float);
float dcon_province_get_movement_cost(int32_t);
void dcon_province_set_center(int32_t, uint32_t);
uint32_t dcon_province_get_center(int32_t);
void dcon_province_set_infrastructure_needed(int32_t, float);
float dcon_province_get_infrastructure_needed(int32_t);
void dcon_province_set_infrastructure(int32_t, float);
float dcon_province_get_infrastructure(int32_t);
void dcon_province_set_infrastructure_investment(int32_t, float);
float dcon_province_get_infrastructure_investment(int32_t);
void dcon_province_set_infrastructure_efficiency(int32_t, float);
float dcon_province_get_infrastructure_efficiency(int32_t);
void dcon_province_resize_technologies_present(uint32_t);
void dcon_province_set_technologies_present(int32_t, int32_t, uint8_t);
uint8_t dcon_province_get_technologies_present(int32_t, int32_t);
void dcon_province_resize_technologies_researchable(uint32_t);
void dcon_province_set_technologies_researchable(int32_t, int32_t, uint8_t);
uint8_t dcon_province_get_technologies_researchable(int32_t, int32_t);
void dcon_province_resize_buildable_buildings(uint32_t);
void dcon_province_set_buildable_buildings(int32_t, int32_t, uint8_t);
uint8_t dcon_province_get_buildable_buildings(int32_t, int32_t);
void dcon_province_resize_local_production(uint32_t);
void dcon_province_set_local_production(int32_t, int32_t, float);
float dcon_province_get_local_production(int32_t, int32_t);
void dcon_province_resize_temp_buffer_0(uint32_t);
void dcon_province_set_temp_buffer_0(int32_t, int32_t, float);
float dcon_province_get_temp_buffer_0(int32_t, int32_t);
void dcon_province_resize_local_consumption(uint32_t);
void dcon_province_set_local_consumption(int32_t, int32_t, float);
float dcon_province_get_local_consumption(int32_t, int32_t);
void dcon_province_resize_local_demand(uint32_t);
void dcon_province_set_local_demand(int32_t, int32_t, float);
float dcon_province_get_local_demand(int32_t, int32_t);
void dcon_province_resize_local_satisfaction(uint32_t);
void dcon_province_set_local_satisfaction(int32_t, int32_t, float);
float dcon_province_get_local_satisfaction(int32_t, int32_t);
void dcon_province_resize_temp_buffer_use_0(uint32_t);
void dcon_province_set_temp_buffer_use_0(int32_t, int32_t, float);
float dcon_province_get_temp_buffer_use_0(int32_t, int32_t);
void dcon_province_resize_temp_buffer_use_grad(uint32_t);
void dcon_province_set_temp_buffer_use_grad(int32_t, int32_t, float);
float dcon_province_get_temp_buffer_use_grad(int32_t, int32_t);
void dcon_province_resize_local_use_satisfaction(uint32_t);
void dcon_province_set_local_use_satisfaction(int32_t, int32_t, float);
float dcon_province_get_local_use_satisfaction(int32_t, int32_t);
void dcon_province_resize_local_use_buffer_demand(uint32_t);
void dcon_province_set_local_use_buffer_demand(int32_t, int32_t, float);
float dcon_province_get_local_use_buffer_demand(int32_t, int32_t);
void dcon_province_resize_local_use_buffer_supply(uint32_t);
void dcon_province_set_local_use_buffer_supply(int32_t, int32_t, float);
float dcon_province_get_local_use_buffer_supply(int32_t, int32_t);
void dcon_province_resize_local_use_buffer_cost(uint32_t);
void dcon_province_set_local_use_buffer_cost(int32_t, int32_t, float);
float dcon_province_get_local_use_buffer_cost(int32_t, int32_t);
void dcon_province_resize_local_storage(uint32_t);
void dcon_province_set_local_storage(int32_t, int32_t, float);
float dcon_province_get_local_storage(int32_t, int32_t);
void dcon_province_resize_local_prices(uint32_t);
void dcon_province_set_local_prices(int32_t, int32_t, float);
float dcon_province_get_local_prices(int32_t, int32_t);
void dcon_province_set_local_wealth(int32_t, float);
float dcon_province_get_local_wealth(int32_t);
void dcon_province_set_trade_wealth(int32_t, float);
float dcon_province_get_trade_wealth(int32_t);
void dcon_province_set_local_income(int32_t, float);
float dcon_province_get_local_income(int32_t);
void dcon_province_set_local_building_upkeep(int32_t, float);
float dcon_province_get_local_building_upkeep(int32_t);
void dcon_province_set_foragers(int32_t, float);
float dcon_province_get_foragers(int32_t);
void dcon_province_set_foragers_water(int32_t, float);
float dcon_province_get_foragers_water(int32_t);
void dcon_province_set_foragers_limit(int32_t, float);
float dcon_province_get_foragers_limit(int32_t);
void dcon_province_resize_foragers_targets(uint32_t);
forage_container* dcon_province_get_foragers_targets(int32_t, int32_t);
void dcon_province_resize_local_resources(uint32_t);
resource_location* dcon_province_get_local_resources(int32_t, int32_t);
void dcon_province_set_mood(int32_t, float);
float dcon_province_get_mood(int32_t);
void dcon_province_resize_unit_types(uint32_t);
void dcon_province_set_unit_types(int32_t, int32_t, uint8_t);
uint8_t dcon_province_get_unit_types(int32_t, int32_t);
void dcon_province_resize_throughput_boosts(uint32_t);
void dcon_province_set_throughput_boosts(int32_t, int32_t, float);
float dcon_province_get_throughput_boosts(int32_t, int32_t);
void dcon_province_resize_input_efficiency_boosts(uint32_t);
void dcon_province_set_input_efficiency_boosts(int32_t, int32_t, float);
float dcon_province_get_input_efficiency_boosts(int32_t, int32_t);
void dcon_province_resize_output_efficiency_boosts(uint32_t);
void dcon_province_set_output_efficiency_boosts(int32_t, int32_t, float);
float dcon_province_get_output_efficiency_boosts(int32_t, int32_t);
void dcon_province_set_on_a_river(int32_t, bool);
bool dcon_province_get_on_a_river(int32_t);
void dcon_province_set_on_a_forest(int32_t, bool);
bool dcon_province_get_on_a_forest(int32_t);
void dcon_delete_province(int32_t j);
int32_t dcon_create_province();
bool dcon_province_is_valid(int32_t);
void dcon_province_resize(uint32_t sz);
uint32_t dcon_province_size();
]]

---province: FFI arrays---
---@type (string)[]
DATA.province_name= {}

---province: LUA bindings---

DATA.province_size = 20000
DCON.dcon_province_resize_technologies_present(401)
DCON.dcon_province_resize_technologies_researchable(401)
DCON.dcon_province_resize_buildable_buildings(251)
DCON.dcon_province_resize_local_production(101)
DCON.dcon_province_resize_temp_buffer_0(101)
DCON.dcon_province_resize_local_consumption(101)
DCON.dcon_province_resize_local_demand(101)
DCON.dcon_province_resize_local_satisfaction(101)
DCON.dcon_province_resize_temp_buffer_use_0(101)
DCON.dcon_province_resize_temp_buffer_use_grad(101)
DCON.dcon_province_resize_local_use_satisfaction(101)
DCON.dcon_province_resize_local_use_buffer_demand(101)
DCON.dcon_province_resize_local_use_buffer_supply(101)
DCON.dcon_province_resize_local_use_buffer_cost(101)
DCON.dcon_province_resize_local_storage(101)
DCON.dcon_province_resize_local_prices(101)
DCON.dcon_province_resize_foragers_targets(26)
DCON.dcon_province_resize_local_resources(26)
DCON.dcon_province_resize_unit_types(21)
DCON.dcon_province_resize_throughput_boosts(251)
DCON.dcon_province_resize_input_efficiency_boosts(251)
DCON.dcon_province_resize_output_efficiency_boosts(251)
---@return province_id
function DATA.create_province()
    ---@type province_id
    local i  = DCON.dcon_create_province() + 1
    return i --[[@as province_id]]
end
---@param i province_id
function DATA.delete_province(i)
    assert(DCON.dcon_province_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_province(i - 1)
end
---@param func fun(item: province_id)
function DATA.for_each_province(func)
    ---@type number
    local range = DCON.dcon_province_size()
    for i = 0, range - 1 do
        if DCON.dcon_province_is_valid(i) then func(i + 1 --[[@as province_id]]) end
    end
end
---@param func fun(item: province_id):boolean
---@return table<province_id, province_id>
function DATA.filter_province(func)
    ---@type table<province_id, province_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_size()
    for i = 0, range - 1 do
        if DCON.dcon_province_is_valid(i) and func(i + 1 --[[@as province_id]]) then t[i + 1 --[[@as province_id]]] = t[i + 1 --[[@as province_id]]] end
    end
    return t
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
    return DCON.dcon_province_get_r(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_r(province_id, value)
    DCON.dcon_province_set_r(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_r(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_r(province_id - 1)
    DCON.dcon_province_set_r(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number g
function DATA.province_get_g(province_id)
    return DCON.dcon_province_get_g(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_g(province_id, value)
    DCON.dcon_province_set_g(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_g(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_g(province_id - 1)
    DCON.dcon_province_set_g(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number b
function DATA.province_get_b(province_id)
    return DCON.dcon_province_get_b(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_b(province_id, value)
    DCON.dcon_province_set_b(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_b(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_b(province_id - 1)
    DCON.dcon_province_set_b(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return boolean is_land
function DATA.province_get_is_land(province_id)
    return DCON.dcon_province_get_is_land(province_id - 1)
end
---@param province_id province_id valid province id
---@param value boolean valid boolean
function DATA.province_set_is_land(province_id, value)
    DCON.dcon_province_set_is_land(province_id - 1, value)
end
---@param province_id province_id valid province id
---@return number province_id
function DATA.province_get_province_id(province_id)
    return DCON.dcon_province_get_province_id(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_province_id(province_id, value)
    DCON.dcon_province_set_province_id(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_province_id(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_province_id(province_id - 1)
    DCON.dcon_province_set_province_id(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number size
function DATA.province_get_size(province_id)
    return DCON.dcon_province_get_size(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_size(province_id, value)
    DCON.dcon_province_set_size(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_size(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_size(province_id - 1)
    DCON.dcon_province_set_size(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number hydration Number of humans that can live of off this provinces innate water
function DATA.province_get_hydration(province_id)
    return DCON.dcon_province_get_hydration(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_hydration(province_id, value)
    DCON.dcon_province_set_hydration(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_hydration(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_hydration(province_id - 1)
    DCON.dcon_province_set_hydration(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number movement_cost
function DATA.province_get_movement_cost(province_id)
    return DCON.dcon_province_get_movement_cost(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_movement_cost(province_id, value)
    DCON.dcon_province_set_movement_cost(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_movement_cost(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_movement_cost(province_id - 1)
    DCON.dcon_province_set_movement_cost(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return tile_id center The tile which contains this province's settlement, if there is any.
function DATA.province_get_center(province_id)
    return DCON.dcon_province_get_center(province_id - 1) + 1
end
---@param province_id province_id valid province id
---@param value tile_id valid tile_id
function DATA.province_set_center(province_id, value)
    DCON.dcon_province_set_center(province_id - 1, value - 1)
end
---@param province_id province_id valid province id
---@return number infrastructure_needed
function DATA.province_get_infrastructure_needed(province_id)
    return DCON.dcon_province_get_infrastructure_needed(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_infrastructure_needed(province_id, value)
    DCON.dcon_province_set_infrastructure_needed(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_infrastructure_needed(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_infrastructure_needed(province_id - 1)
    DCON.dcon_province_set_infrastructure_needed(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number infrastructure
function DATA.province_get_infrastructure(province_id)
    return DCON.dcon_province_get_infrastructure(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_infrastructure(province_id, value)
    DCON.dcon_province_set_infrastructure(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_infrastructure(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_infrastructure(province_id - 1)
    DCON.dcon_province_set_infrastructure(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number infrastructure_investment
function DATA.province_get_infrastructure_investment(province_id)
    return DCON.dcon_province_get_infrastructure_investment(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_infrastructure_investment(province_id, value)
    DCON.dcon_province_set_infrastructure_investment(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_infrastructure_investment(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_infrastructure_investment(province_id - 1)
    DCON.dcon_province_set_infrastructure_investment(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number infrastructure_efficiency
function DATA.province_get_infrastructure_efficiency(province_id)
    return DCON.dcon_province_get_infrastructure_efficiency(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_infrastructure_efficiency(province_id, value)
    DCON.dcon_province_set_infrastructure_efficiency(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_infrastructure_efficiency(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_infrastructure_efficiency(province_id - 1)
    DCON.dcon_province_set_infrastructure_efficiency(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@param index technology_id valid
---@return number technologies_present
function DATA.province_get_technologies_present(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_technologies_present(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index technology_id valid index
---@param value number valid number
function DATA.province_set_technologies_present(province_id, index, value)
    DCON.dcon_province_set_technologies_present(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index technology_id valid index
---@param value number valid number
function DATA.province_inc_technologies_present(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_technologies_present(province_id - 1, index - 1)
    DCON.dcon_province_set_technologies_present(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index technology_id valid
---@return number technologies_researchable
function DATA.province_get_technologies_researchable(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_technologies_researchable(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index technology_id valid index
---@param value number valid number
function DATA.province_set_technologies_researchable(province_id, index, value)
    DCON.dcon_province_set_technologies_researchable(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index technology_id valid index
---@param value number valid number
function DATA.province_inc_technologies_researchable(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_technologies_researchable(province_id - 1, index - 1)
    DCON.dcon_province_set_technologies_researchable(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index building_type_id valid
---@return number buildable_buildings
function DATA.province_get_buildable_buildings(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_buildable_buildings(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index building_type_id valid index
---@param value number valid number
function DATA.province_set_buildable_buildings(province_id, index, value)
    DCON.dcon_province_set_buildable_buildings(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index building_type_id valid index
---@param value number valid number
function DATA.province_inc_buildable_buildings(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_buildable_buildings(province_id - 1, index - 1)
    DCON.dcon_province_set_buildable_buildings(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid
---@return number local_production
function DATA.province_get_local_production(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_local_production(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_set_local_production(province_id, index, value)
    DCON.dcon_province_set_local_production(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_inc_local_production(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_local_production(province_id - 1, index - 1)
    DCON.dcon_province_set_local_production(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid
---@return number temp_buffer_0
function DATA.province_get_temp_buffer_0(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_temp_buffer_0(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_set_temp_buffer_0(province_id, index, value)
    DCON.dcon_province_set_temp_buffer_0(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_inc_temp_buffer_0(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_temp_buffer_0(province_id - 1, index - 1)
    DCON.dcon_province_set_temp_buffer_0(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid
---@return number local_consumption
function DATA.province_get_local_consumption(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_local_consumption(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_set_local_consumption(province_id, index, value)
    DCON.dcon_province_set_local_consumption(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_inc_local_consumption(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_local_consumption(province_id - 1, index - 1)
    DCON.dcon_province_set_local_consumption(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid
---@return number local_demand
function DATA.province_get_local_demand(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_local_demand(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_set_local_demand(province_id, index, value)
    DCON.dcon_province_set_local_demand(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_inc_local_demand(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_local_demand(province_id - 1, index - 1)
    DCON.dcon_province_set_local_demand(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid
---@return number local_satisfaction
function DATA.province_get_local_satisfaction(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_local_satisfaction(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_set_local_satisfaction(province_id, index, value)
    DCON.dcon_province_set_local_satisfaction(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_inc_local_satisfaction(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_local_satisfaction(province_id - 1, index - 1)
    DCON.dcon_province_set_local_satisfaction(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index use_case_id valid
---@return number temp_buffer_use_0
function DATA.province_get_temp_buffer_use_0(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_temp_buffer_use_0(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index use_case_id valid index
---@param value number valid number
function DATA.province_set_temp_buffer_use_0(province_id, index, value)
    DCON.dcon_province_set_temp_buffer_use_0(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index use_case_id valid index
---@param value number valid number
function DATA.province_inc_temp_buffer_use_0(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_temp_buffer_use_0(province_id - 1, index - 1)
    DCON.dcon_province_set_temp_buffer_use_0(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index use_case_id valid
---@return number temp_buffer_use_grad
function DATA.province_get_temp_buffer_use_grad(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_temp_buffer_use_grad(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index use_case_id valid index
---@param value number valid number
function DATA.province_set_temp_buffer_use_grad(province_id, index, value)
    DCON.dcon_province_set_temp_buffer_use_grad(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index use_case_id valid index
---@param value number valid number
function DATA.province_inc_temp_buffer_use_grad(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_temp_buffer_use_grad(province_id - 1, index - 1)
    DCON.dcon_province_set_temp_buffer_use_grad(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index use_case_id valid
---@return number local_use_satisfaction
function DATA.province_get_local_use_satisfaction(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_local_use_satisfaction(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index use_case_id valid index
---@param value number valid number
function DATA.province_set_local_use_satisfaction(province_id, index, value)
    DCON.dcon_province_set_local_use_satisfaction(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index use_case_id valid index
---@param value number valid number
function DATA.province_inc_local_use_satisfaction(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_local_use_satisfaction(province_id - 1, index - 1)
    DCON.dcon_province_set_local_use_satisfaction(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index use_case_id valid
---@return number local_use_buffer_demand
function DATA.province_get_local_use_buffer_demand(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_local_use_buffer_demand(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index use_case_id valid index
---@param value number valid number
function DATA.province_set_local_use_buffer_demand(province_id, index, value)
    DCON.dcon_province_set_local_use_buffer_demand(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index use_case_id valid index
---@param value number valid number
function DATA.province_inc_local_use_buffer_demand(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_local_use_buffer_demand(province_id - 1, index - 1)
    DCON.dcon_province_set_local_use_buffer_demand(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index use_case_id valid
---@return number local_use_buffer_supply
function DATA.province_get_local_use_buffer_supply(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_local_use_buffer_supply(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index use_case_id valid index
---@param value number valid number
function DATA.province_set_local_use_buffer_supply(province_id, index, value)
    DCON.dcon_province_set_local_use_buffer_supply(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index use_case_id valid index
---@param value number valid number
function DATA.province_inc_local_use_buffer_supply(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_local_use_buffer_supply(province_id - 1, index - 1)
    DCON.dcon_province_set_local_use_buffer_supply(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index use_case_id valid
---@return number local_use_buffer_cost
function DATA.province_get_local_use_buffer_cost(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_local_use_buffer_cost(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index use_case_id valid index
---@param value number valid number
function DATA.province_set_local_use_buffer_cost(province_id, index, value)
    DCON.dcon_province_set_local_use_buffer_cost(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index use_case_id valid index
---@param value number valid number
function DATA.province_inc_local_use_buffer_cost(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_local_use_buffer_cost(province_id - 1, index - 1)
    DCON.dcon_province_set_local_use_buffer_cost(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid
---@return number local_storage
function DATA.province_get_local_storage(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_local_storage(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_set_local_storage(province_id, index, value)
    DCON.dcon_province_set_local_storage(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_inc_local_storage(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_local_storage(province_id - 1, index - 1)
    DCON.dcon_province_set_local_storage(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid
---@return number local_prices
function DATA.province_get_local_prices(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_local_prices(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_set_local_prices(province_id, index, value)
    DCON.dcon_province_set_local_prices(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.province_inc_local_prices(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_local_prices(province_id - 1, index - 1)
    DCON.dcon_province_set_local_prices(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@return number local_wealth
function DATA.province_get_local_wealth(province_id)
    return DCON.dcon_province_get_local_wealth(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_local_wealth(province_id, value)
    DCON.dcon_province_set_local_wealth(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_local_wealth(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_local_wealth(province_id - 1)
    DCON.dcon_province_set_local_wealth(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number trade_wealth
function DATA.province_get_trade_wealth(province_id)
    return DCON.dcon_province_get_trade_wealth(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_trade_wealth(province_id, value)
    DCON.dcon_province_set_trade_wealth(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_trade_wealth(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_trade_wealth(province_id - 1)
    DCON.dcon_province_set_trade_wealth(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number local_income
function DATA.province_get_local_income(province_id)
    return DCON.dcon_province_get_local_income(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_local_income(province_id, value)
    DCON.dcon_province_set_local_income(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_local_income(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_local_income(province_id - 1)
    DCON.dcon_province_set_local_income(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number local_building_upkeep
function DATA.province_get_local_building_upkeep(province_id)
    return DCON.dcon_province_get_local_building_upkeep(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_local_building_upkeep(province_id, value)
    DCON.dcon_province_set_local_building_upkeep(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_local_building_upkeep(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_local_building_upkeep(province_id - 1)
    DCON.dcon_province_set_local_building_upkeep(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number foragers Keeps track of the number of foragers in the province. Used to calculate yields of independent foraging.
function DATA.province_get_foragers(province_id)
    return DCON.dcon_province_get_foragers(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_foragers(province_id, value)
    DCON.dcon_province_set_foragers(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_foragers(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_foragers(province_id - 1)
    DCON.dcon_province_set_foragers(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number foragers_water amount foraged by pops and characters
function DATA.province_get_foragers_water(province_id)
    return DCON.dcon_province_get_foragers_water(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_foragers_water(province_id, value)
    DCON.dcon_province_set_foragers_water(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_foragers_water(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_foragers_water(province_id - 1)
    DCON.dcon_province_set_foragers_water(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@return number foragers_limit amount of calories foraged by pops and characters
function DATA.province_get_foragers_limit(province_id)
    return DCON.dcon_province_get_foragers_limit(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_foragers_limit(province_id, value)
    DCON.dcon_province_set_foragers_limit(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_foragers_limit(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_foragers_limit(province_id - 1)
    DCON.dcon_province_set_foragers_limit(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@param index number valid
---@return trade_good_id foragers_targets
function DATA.province_get_foragers_targets_output_good(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_foragers_targets(province_id - 1, index - 1)[0].output_good
end
---@param province_id province_id valid province id
---@param index number valid
---@return number foragers_targets
function DATA.province_get_foragers_targets_output_value(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_foragers_targets(province_id - 1, index - 1)[0].output_value
end
---@param province_id province_id valid province id
---@param index number valid
---@return number foragers_targets
function DATA.province_get_foragers_targets_amount(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_foragers_targets(province_id - 1, index - 1)[0].amount
end
---@param province_id province_id valid province id
---@param index number valid
---@return FORAGE_RESOURCE foragers_targets
function DATA.province_get_foragers_targets_forage(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_foragers_targets(province_id - 1, index - 1)[0].forage
end
---@param province_id province_id valid province id
---@param index number valid index
---@param value trade_good_id valid trade_good_id
function DATA.province_set_foragers_targets_output_good(province_id, index, value)
    DCON.dcon_province_get_foragers_targets(province_id - 1, index - 1)[0].output_good = value
end
---@param province_id province_id valid province id
---@param index number valid index
---@param value number valid number
function DATA.province_set_foragers_targets_output_value(province_id, index, value)
    DCON.dcon_province_get_foragers_targets(province_id - 1, index - 1)[0].output_value = value
end
---@param province_id province_id valid province id
---@param index number valid index
---@param value number valid number
function DATA.province_inc_foragers_targets_output_value(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_foragers_targets(province_id - 1, index - 1)[0].output_value
    DCON.dcon_province_get_foragers_targets(province_id - 1, index - 1)[0].output_value = current + value
end
---@param province_id province_id valid province id
---@param index number valid index
---@param value number valid number
function DATA.province_set_foragers_targets_amount(province_id, index, value)
    DCON.dcon_province_get_foragers_targets(province_id - 1, index - 1)[0].amount = value
end
---@param province_id province_id valid province id
---@param index number valid index
---@param value number valid number
function DATA.province_inc_foragers_targets_amount(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_foragers_targets(province_id - 1, index - 1)[0].amount
    DCON.dcon_province_get_foragers_targets(province_id - 1, index - 1)[0].amount = current + value
end
---@param province_id province_id valid province id
---@param index number valid index
---@param value FORAGE_RESOURCE valid FORAGE_RESOURCE
function DATA.province_set_foragers_targets_forage(province_id, index, value)
    DCON.dcon_province_get_foragers_targets(province_id - 1, index - 1)[0].forage = value
end
---@param province_id province_id valid province id
---@param index number valid
---@return resource_id local_resources An array of local resources and their positions
function DATA.province_get_local_resources_resource(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_local_resources(province_id - 1, index - 1)[0].resource
end
---@param province_id province_id valid province id
---@param index number valid
---@return tile_id local_resources An array of local resources and their positions
function DATA.province_get_local_resources_location(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_local_resources(province_id - 1, index - 1)[0].location
end
---@param province_id province_id valid province id
---@param index number valid index
---@param value resource_id valid resource_id
function DATA.province_set_local_resources_resource(province_id, index, value)
    DCON.dcon_province_get_local_resources(province_id - 1, index - 1)[0].resource = value
end
---@param province_id province_id valid province id
---@param index number valid index
---@param value tile_id valid tile_id
function DATA.province_set_local_resources_location(province_id, index, value)
    DCON.dcon_province_get_local_resources(province_id - 1, index - 1)[0].location = value
end
---@param province_id province_id valid province id
---@return number mood how local population thinks about the state
function DATA.province_get_mood(province_id)
    return DCON.dcon_province_get_mood(province_id - 1)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_set_mood(province_id, value)
    DCON.dcon_province_set_mood(province_id - 1, value)
end
---@param province_id province_id valid province id
---@param value number valid number
function DATA.province_inc_mood(province_id, value)
    ---@type number
    local current = DCON.dcon_province_get_mood(province_id - 1)
    DCON.dcon_province_set_mood(province_id - 1, current + value)
end
---@param province_id province_id valid province id
---@param index unit_type_id valid
---@return number unit_types
function DATA.province_get_unit_types(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_unit_types(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index unit_type_id valid index
---@param value number valid number
function DATA.province_set_unit_types(province_id, index, value)
    DCON.dcon_province_set_unit_types(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index unit_type_id valid index
---@param value number valid number
function DATA.province_inc_unit_types(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_unit_types(province_id - 1, index - 1)
    DCON.dcon_province_set_unit_types(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index production_method_id valid
---@return number throughput_boosts
function DATA.province_get_throughput_boosts(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_throughput_boosts(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index production_method_id valid index
---@param value number valid number
function DATA.province_set_throughput_boosts(province_id, index, value)
    DCON.dcon_province_set_throughput_boosts(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index production_method_id valid index
---@param value number valid number
function DATA.province_inc_throughput_boosts(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_throughput_boosts(province_id - 1, index - 1)
    DCON.dcon_province_set_throughput_boosts(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index production_method_id valid
---@return number input_efficiency_boosts
function DATA.province_get_input_efficiency_boosts(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_input_efficiency_boosts(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index production_method_id valid index
---@param value number valid number
function DATA.province_set_input_efficiency_boosts(province_id, index, value)
    DCON.dcon_province_set_input_efficiency_boosts(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index production_method_id valid index
---@param value number valid number
function DATA.province_inc_input_efficiency_boosts(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_input_efficiency_boosts(province_id - 1, index - 1)
    DCON.dcon_province_set_input_efficiency_boosts(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@param index production_method_id valid
---@return number output_efficiency_boosts
function DATA.province_get_output_efficiency_boosts(province_id, index)
    assert(index ~= 0)
    return DCON.dcon_province_get_output_efficiency_boosts(province_id - 1, index - 1)
end
---@param province_id province_id valid province id
---@param index production_method_id valid index
---@param value number valid number
function DATA.province_set_output_efficiency_boosts(province_id, index, value)
    DCON.dcon_province_set_output_efficiency_boosts(province_id - 1, index - 1, value)
end
---@param province_id province_id valid province id
---@param index production_method_id valid index
---@param value number valid number
function DATA.province_inc_output_efficiency_boosts(province_id, index, value)
    ---@type number
    local current = DCON.dcon_province_get_output_efficiency_boosts(province_id - 1, index - 1)
    DCON.dcon_province_set_output_efficiency_boosts(province_id - 1, index - 1, current + value)
end
---@param province_id province_id valid province id
---@return boolean on_a_river
function DATA.province_get_on_a_river(province_id)
    return DCON.dcon_province_get_on_a_river(province_id - 1)
end
---@param province_id province_id valid province id
---@param value boolean valid boolean
function DATA.province_set_on_a_river(province_id, value)
    DCON.dcon_province_set_on_a_river(province_id - 1, value)
end
---@param province_id province_id valid province id
---@return boolean on_a_forest
function DATA.province_get_on_a_forest(province_id)
    return DCON.dcon_province_get_on_a_forest(province_id - 1)
end
---@param province_id province_id valid province id
---@param value boolean valid boolean
function DATA.province_set_on_a_forest(province_id, value)
    DCON.dcon_province_set_on_a_forest(province_id - 1, value)
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
        if (k == "infrastructure_efficiency") then return DATA.province_get_infrastructure_efficiency(t.id) end
        if (k == "local_wealth") then return DATA.province_get_local_wealth(t.id) end
        if (k == "trade_wealth") then return DATA.province_get_trade_wealth(t.id) end
        if (k == "local_income") then return DATA.province_get_local_income(t.id) end
        if (k == "local_building_upkeep") then return DATA.province_get_local_building_upkeep(t.id) end
        if (k == "foragers") then return DATA.province_get_foragers(t.id) end
        if (k == "foragers_water") then return DATA.province_get_foragers_water(t.id) end
        if (k == "foragers_limit") then return DATA.province_get_foragers_limit(t.id) end
        if (k == "mood") then return DATA.province_get_mood(t.id) end
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
        if (k == "infrastructure_efficiency") then
            DATA.province_set_infrastructure_efficiency(t.id, v)
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
        if (k == "mood") then
            DATA.province_set_mood(t.id, v)
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
---@class (exact) army_id : number
---@field is_army nil

---@class (exact) fat_army_id
---@field id army_id Unique army id
---@field destination province_id

---@class struct_army
---@field destination province_id


ffi.cdef[[
void dcon_army_set_destination(int32_t, uint32_t);
uint32_t dcon_army_get_destination(int32_t);
void dcon_delete_army(int32_t j);
int32_t dcon_create_army();
bool dcon_army_is_valid(int32_t);
void dcon_army_resize(uint32_t sz);
uint32_t dcon_army_size();
]]

---army: FFI arrays---

---army: LUA bindings---

DATA.army_size = 5000
---@return army_id
function DATA.create_army()
    ---@type army_id
    local i  = DCON.dcon_create_army() + 1
    return i --[[@as army_id]]
end
---@param i army_id
function DATA.delete_army(i)
    assert(DCON.dcon_army_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_army(i - 1)
end
---@param func fun(item: army_id)
function DATA.for_each_army(func)
    ---@type number
    local range = DCON.dcon_army_size()
    for i = 0, range - 1 do
        if DCON.dcon_army_is_valid(i) then func(i + 1 --[[@as army_id]]) end
    end
end
---@param func fun(item: army_id):boolean
---@return table<army_id, army_id>
function DATA.filter_army(func)
    ---@type table<army_id, army_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_army_size()
    for i = 0, range - 1 do
        if DCON.dcon_army_is_valid(i) and func(i + 1 --[[@as army_id]]) then t[i + 1 --[[@as army_id]]] = t[i + 1 --[[@as army_id]]] end
    end
    return t
end

---@param army_id army_id valid army id
---@return province_id destination
function DATA.army_get_destination(army_id)
    return DCON.dcon_army_get_destination(army_id - 1) + 1
end
---@param army_id army_id valid army id
---@param value province_id valid province_id
function DATA.army_set_destination(army_id, value)
    DCON.dcon_army_set_destination(army_id - 1, value - 1)
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
---@class (exact) warband_id : number
---@field is_warband nil

---@class (exact) fat_warband_id
---@field id warband_id Unique warband id
---@field name string
---@field guard_of Realm?
---@field current_status WARBAND_STATUS
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
---@field current_status WARBAND_STATUS
---@field idle_stance WARBAND_STANCE
---@field current_free_time_ratio number How much of "idle" free time they are actually idle. Set by events.
---@field treasury number
---@field total_upkeep number
---@field predicted_upkeep number
---@field supplies number
---@field supplies_target_days number
---@field morale number


ffi.cdef[[
void dcon_warband_resize_units_current(uint32_t);
void dcon_warband_set_units_current(int32_t, int32_t, float);
float dcon_warband_get_units_current(int32_t, int32_t);
void dcon_warband_resize_units_target(uint32_t);
void dcon_warband_set_units_target(int32_t, int32_t, float);
float dcon_warband_get_units_target(int32_t, int32_t);
void dcon_warband_set_current_status(int32_t, uint8_t);
uint8_t dcon_warband_get_current_status(int32_t);
void dcon_warband_set_idle_stance(int32_t, uint8_t);
uint8_t dcon_warband_get_idle_stance(int32_t);
void dcon_warband_set_current_free_time_ratio(int32_t, float);
float dcon_warband_get_current_free_time_ratio(int32_t);
void dcon_warband_set_treasury(int32_t, float);
float dcon_warband_get_treasury(int32_t);
void dcon_warband_set_total_upkeep(int32_t, float);
float dcon_warband_get_total_upkeep(int32_t);
void dcon_warband_set_predicted_upkeep(int32_t, float);
float dcon_warband_get_predicted_upkeep(int32_t);
void dcon_warband_set_supplies(int32_t, float);
float dcon_warband_get_supplies(int32_t);
void dcon_warband_set_supplies_target_days(int32_t, float);
float dcon_warband_get_supplies_target_days(int32_t);
void dcon_warband_set_morale(int32_t, float);
float dcon_warband_get_morale(int32_t);
void dcon_delete_warband(int32_t j);
int32_t dcon_create_warband();
bool dcon_warband_is_valid(int32_t);
void dcon_warband_resize(uint32_t sz);
uint32_t dcon_warband_size();
]]

---warband: FFI arrays---
---@type (string)[]
DATA.warband_name= {}
---@type (Realm?)[]
DATA.warband_guard_of= {}

---warband: LUA bindings---

DATA.warband_size = 50000
DCON.dcon_warband_resize_units_current(21)
DCON.dcon_warband_resize_units_target(21)
---@return warband_id
function DATA.create_warband()
    ---@type warband_id
    local i  = DCON.dcon_create_warband() + 1
    return i --[[@as warband_id]]
end
---@param i warband_id
function DATA.delete_warband(i)
    assert(DCON.dcon_warband_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_warband(i - 1)
end
---@param func fun(item: warband_id)
function DATA.for_each_warband(func)
    ---@type number
    local range = DCON.dcon_warband_size()
    for i = 0, range - 1 do
        if DCON.dcon_warband_is_valid(i) then func(i + 1 --[[@as warband_id]]) end
    end
end
---@param func fun(item: warband_id):boolean
---@return table<warband_id, warband_id>
function DATA.filter_warband(func)
    ---@type table<warband_id, warband_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_warband_size()
    for i = 0, range - 1 do
        if DCON.dcon_warband_is_valid(i) and func(i + 1 --[[@as warband_id]]) then t[i + 1 --[[@as warband_id]]] = t[i + 1 --[[@as warband_id]]] end
    end
    return t
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
    assert(index ~= 0)
    return DCON.dcon_warband_get_units_current(warband_id - 1, index - 1)
end
---@param warband_id warband_id valid warband id
---@param index unit_type_id valid index
---@param value number valid number
function DATA.warband_set_units_current(warband_id, index, value)
    DCON.dcon_warband_set_units_current(warband_id - 1, index - 1, value)
end
---@param warband_id warband_id valid warband id
---@param index unit_type_id valid index
---@param value number valid number
function DATA.warband_inc_units_current(warband_id, index, value)
    ---@type number
    local current = DCON.dcon_warband_get_units_current(warband_id - 1, index - 1)
    DCON.dcon_warband_set_units_current(warband_id - 1, index - 1, current + value)
end
---@param warband_id warband_id valid warband id
---@param index unit_type_id valid
---@return number units_target Units to recruit
function DATA.warband_get_units_target(warband_id, index)
    assert(index ~= 0)
    return DCON.dcon_warband_get_units_target(warband_id - 1, index - 1)
end
---@param warband_id warband_id valid warband id
---@param index unit_type_id valid index
---@param value number valid number
function DATA.warband_set_units_target(warband_id, index, value)
    DCON.dcon_warband_set_units_target(warband_id - 1, index - 1, value)
end
---@param warband_id warband_id valid warband id
---@param index unit_type_id valid index
---@param value number valid number
function DATA.warband_inc_units_target(warband_id, index, value)
    ---@type number
    local current = DCON.dcon_warband_get_units_target(warband_id - 1, index - 1)
    DCON.dcon_warband_set_units_target(warband_id - 1, index - 1, current + value)
end
---@param warband_id warband_id valid warband id
---@return WARBAND_STATUS current_status
function DATA.warband_get_current_status(warband_id)
    return DCON.dcon_warband_get_current_status(warband_id - 1)
end
---@param warband_id warband_id valid warband id
---@param value WARBAND_STATUS valid WARBAND_STATUS
function DATA.warband_set_current_status(warband_id, value)
    DCON.dcon_warband_set_current_status(warband_id - 1, value)
end
---@param warband_id warband_id valid warband id
---@return WARBAND_STANCE idle_stance
function DATA.warband_get_idle_stance(warband_id)
    return DCON.dcon_warband_get_idle_stance(warband_id - 1)
end
---@param warband_id warband_id valid warband id
---@param value WARBAND_STANCE valid WARBAND_STANCE
function DATA.warband_set_idle_stance(warband_id, value)
    DCON.dcon_warband_set_idle_stance(warband_id - 1, value)
end
---@param warband_id warband_id valid warband id
---@return number current_free_time_ratio How much of "idle" free time they are actually idle. Set by events.
function DATA.warband_get_current_free_time_ratio(warband_id)
    return DCON.dcon_warband_get_current_free_time_ratio(warband_id - 1)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_current_free_time_ratio(warband_id, value)
    DCON.dcon_warband_set_current_free_time_ratio(warband_id - 1, value)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_inc_current_free_time_ratio(warband_id, value)
    ---@type number
    local current = DCON.dcon_warband_get_current_free_time_ratio(warband_id - 1)
    DCON.dcon_warband_set_current_free_time_ratio(warband_id - 1, current + value)
end
---@param warband_id warband_id valid warband id
---@return number treasury
function DATA.warband_get_treasury(warband_id)
    return DCON.dcon_warband_get_treasury(warband_id - 1)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_treasury(warband_id, value)
    DCON.dcon_warband_set_treasury(warband_id - 1, value)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_inc_treasury(warband_id, value)
    ---@type number
    local current = DCON.dcon_warband_get_treasury(warband_id - 1)
    DCON.dcon_warband_set_treasury(warband_id - 1, current + value)
end
---@param warband_id warband_id valid warband id
---@return number total_upkeep
function DATA.warband_get_total_upkeep(warband_id)
    return DCON.dcon_warband_get_total_upkeep(warband_id - 1)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_total_upkeep(warband_id, value)
    DCON.dcon_warband_set_total_upkeep(warband_id - 1, value)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_inc_total_upkeep(warband_id, value)
    ---@type number
    local current = DCON.dcon_warband_get_total_upkeep(warband_id - 1)
    DCON.dcon_warband_set_total_upkeep(warband_id - 1, current + value)
end
---@param warband_id warband_id valid warband id
---@return number predicted_upkeep
function DATA.warband_get_predicted_upkeep(warband_id)
    return DCON.dcon_warband_get_predicted_upkeep(warband_id - 1)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_predicted_upkeep(warband_id, value)
    DCON.dcon_warband_set_predicted_upkeep(warband_id - 1, value)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_inc_predicted_upkeep(warband_id, value)
    ---@type number
    local current = DCON.dcon_warband_get_predicted_upkeep(warband_id - 1)
    DCON.dcon_warband_set_predicted_upkeep(warband_id - 1, current + value)
end
---@param warband_id warband_id valid warband id
---@return number supplies
function DATA.warband_get_supplies(warband_id)
    return DCON.dcon_warband_get_supplies(warband_id - 1)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_supplies(warband_id, value)
    DCON.dcon_warband_set_supplies(warband_id - 1, value)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_inc_supplies(warband_id, value)
    ---@type number
    local current = DCON.dcon_warband_get_supplies(warband_id - 1)
    DCON.dcon_warband_set_supplies(warband_id - 1, current + value)
end
---@param warband_id warband_id valid warband id
---@return number supplies_target_days
function DATA.warband_get_supplies_target_days(warband_id)
    return DCON.dcon_warband_get_supplies_target_days(warband_id - 1)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_supplies_target_days(warband_id, value)
    DCON.dcon_warband_set_supplies_target_days(warband_id - 1, value)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_inc_supplies_target_days(warband_id, value)
    ---@type number
    local current = DCON.dcon_warband_get_supplies_target_days(warband_id - 1)
    DCON.dcon_warband_set_supplies_target_days(warband_id - 1, current + value)
end
---@param warband_id warband_id valid warband id
---@return number morale
function DATA.warband_get_morale(warband_id)
    return DCON.dcon_warband_get_morale(warband_id - 1)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_set_morale(warband_id, value)
    DCON.dcon_warband_set_morale(warband_id - 1, value)
end
---@param warband_id warband_id valid warband id
---@param value number valid number
function DATA.warband_inc_morale(warband_id, value)
    ---@type number
    local current = DCON.dcon_warband_get_morale(warband_id - 1)
    DCON.dcon_warband_set_morale(warband_id - 1, current + value)
end

local fat_warband_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.warband_get_name(t.id) end
        if (k == "guard_of") then return DATA.warband_get_guard_of(t.id) end
        if (k == "current_status") then return DATA.warband_get_current_status(t.id) end
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
        if (k == "current_status") then
            DATA.warband_set_current_status(t.id, v)
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
----------realm----------


---realm: LSP types---

---Unique identificator for realm entity
---@class (exact) realm_id : number
---@field is_realm nil

---@class (exact) fat_realm_id
---@field id realm_id Unique realm id
---@field exists boolean
---@field name string
---@field budget_change number
---@field budget_saved_change number
---@field budget_treasury number
---@field budget_treasury_target number
---@field budget_tax_target number
---@field budget_tax_collected_this_year number
---@field r number
---@field g number
---@field b number
---@field primary_race race_id
---@field primary_culture Culture
---@field primary_faith Faith
---@field capitol province_id
---@field trading_right_cost number
---@field building_right_cost number
---@field law_trade LAW_TRADE
---@field law_building LAW_BUILDING
---@field quests_raid table<province_id,nil|number> reward for raid
---@field quests_explore table<province_id,nil|number> reward for exploration
---@field quests_patrol table<province_id,nil|number> reward for patrol
---@field patrols table<province_id,table<warband_id,warband_id>>
---@field prepare_attack_flag boolean
---@field known_provinces table<province_id,province_id> For terra incognita.
---@field coa_base_r number
---@field coa_base_g number
---@field coa_base_b number
---@field coa_background_r number
---@field coa_background_g number
---@field coa_background_b number
---@field coa_foreground_r number
---@field coa_foreground_g number
---@field coa_foreground_b number
---@field coa_emblem_r number
---@field coa_emblem_g number
---@field coa_emblem_b number
---@field coa_background_image number
---@field coa_foreground_image number
---@field coa_emblem_image number
---@field expected_food_consumption number

---@class struct_realm
---@field budget_change number
---@field budget_saved_change number
---@field budget_spending_by_category table<ECONOMY_REASON, number>
---@field budget_income_by_category table<ECONOMY_REASON, number>
---@field budget_treasury_change_by_category table<ECONOMY_REASON, number>
---@field budget_treasury number
---@field budget_treasury_target number
---@field budget table<BUDGET_CATEGORY, struct_budget_per_category_data>
---@field budget_tax_target number
---@field budget_tax_collected_this_year number
---@field r number
---@field g number
---@field b number
---@field primary_race race_id
---@field capitol province_id
---@field trading_right_cost number
---@field building_right_cost number
---@field law_trade LAW_TRADE
---@field law_building LAW_BUILDING
---@field prepare_attack_flag boolean
---@field coa_base_r number
---@field coa_base_g number
---@field coa_base_b number
---@field coa_background_r number
---@field coa_background_g number
---@field coa_background_b number
---@field coa_foreground_r number
---@field coa_foreground_g number
---@field coa_foreground_b number
---@field coa_emblem_r number
---@field coa_emblem_g number
---@field coa_emblem_b number
---@field coa_background_image number
---@field coa_foreground_image number
---@field coa_emblem_image number
---@field resources table<trade_good_id, number> Currently stockpiled resources
---@field production table<trade_good_id, number> A "balance" of resource creation
---@field bought table<trade_good_id, number>
---@field sold table<trade_good_id, number>
---@field expected_food_consumption number


ffi.cdef[[
void dcon_realm_set_budget_change(int32_t, float);
float dcon_realm_get_budget_change(int32_t);
void dcon_realm_set_budget_saved_change(int32_t, float);
float dcon_realm_get_budget_saved_change(int32_t);
void dcon_realm_resize_budget_spending_by_category(uint32_t);
void dcon_realm_set_budget_spending_by_category(int32_t, int32_t, float);
float dcon_realm_get_budget_spending_by_category(int32_t, int32_t);
void dcon_realm_resize_budget_income_by_category(uint32_t);
void dcon_realm_set_budget_income_by_category(int32_t, int32_t, float);
float dcon_realm_get_budget_income_by_category(int32_t, int32_t);
void dcon_realm_resize_budget_treasury_change_by_category(uint32_t);
void dcon_realm_set_budget_treasury_change_by_category(int32_t, int32_t, float);
float dcon_realm_get_budget_treasury_change_by_category(int32_t, int32_t);
void dcon_realm_set_budget_treasury(int32_t, float);
float dcon_realm_get_budget_treasury(int32_t);
void dcon_realm_set_budget_treasury_target(int32_t, float);
float dcon_realm_get_budget_treasury_target(int32_t);
void dcon_realm_resize_budget(uint32_t);
budget_per_category_data* dcon_realm_get_budget(int32_t, int32_t);
void dcon_realm_set_budget_tax_target(int32_t, float);
float dcon_realm_get_budget_tax_target(int32_t);
void dcon_realm_set_budget_tax_collected_this_year(int32_t, float);
float dcon_realm_get_budget_tax_collected_this_year(int32_t);
void dcon_realm_set_r(int32_t, float);
float dcon_realm_get_r(int32_t);
void dcon_realm_set_g(int32_t, float);
float dcon_realm_get_g(int32_t);
void dcon_realm_set_b(int32_t, float);
float dcon_realm_get_b(int32_t);
void dcon_realm_set_primary_race(int32_t, uint32_t);
uint32_t dcon_realm_get_primary_race(int32_t);
void dcon_realm_set_capitol(int32_t, uint32_t);
uint32_t dcon_realm_get_capitol(int32_t);
void dcon_realm_set_trading_right_cost(int32_t, float);
float dcon_realm_get_trading_right_cost(int32_t);
void dcon_realm_set_building_right_cost(int32_t, float);
float dcon_realm_get_building_right_cost(int32_t);
void dcon_realm_set_law_trade(int32_t, uint8_t);
uint8_t dcon_realm_get_law_trade(int32_t);
void dcon_realm_set_law_building(int32_t, uint8_t);
uint8_t dcon_realm_get_law_building(int32_t);
void dcon_realm_set_prepare_attack_flag(int32_t, bool);
bool dcon_realm_get_prepare_attack_flag(int32_t);
void dcon_realm_set_coa_base_r(int32_t, float);
float dcon_realm_get_coa_base_r(int32_t);
void dcon_realm_set_coa_base_g(int32_t, float);
float dcon_realm_get_coa_base_g(int32_t);
void dcon_realm_set_coa_base_b(int32_t, float);
float dcon_realm_get_coa_base_b(int32_t);
void dcon_realm_set_coa_background_r(int32_t, float);
float dcon_realm_get_coa_background_r(int32_t);
void dcon_realm_set_coa_background_g(int32_t, float);
float dcon_realm_get_coa_background_g(int32_t);
void dcon_realm_set_coa_background_b(int32_t, float);
float dcon_realm_get_coa_background_b(int32_t);
void dcon_realm_set_coa_foreground_r(int32_t, float);
float dcon_realm_get_coa_foreground_r(int32_t);
void dcon_realm_set_coa_foreground_g(int32_t, float);
float dcon_realm_get_coa_foreground_g(int32_t);
void dcon_realm_set_coa_foreground_b(int32_t, float);
float dcon_realm_get_coa_foreground_b(int32_t);
void dcon_realm_set_coa_emblem_r(int32_t, float);
float dcon_realm_get_coa_emblem_r(int32_t);
void dcon_realm_set_coa_emblem_g(int32_t, float);
float dcon_realm_get_coa_emblem_g(int32_t);
void dcon_realm_set_coa_emblem_b(int32_t, float);
float dcon_realm_get_coa_emblem_b(int32_t);
void dcon_realm_set_coa_background_image(int32_t, uint32_t);
uint32_t dcon_realm_get_coa_background_image(int32_t);
void dcon_realm_set_coa_foreground_image(int32_t, uint32_t);
uint32_t dcon_realm_get_coa_foreground_image(int32_t);
void dcon_realm_set_coa_emblem_image(int32_t, uint32_t);
uint32_t dcon_realm_get_coa_emblem_image(int32_t);
void dcon_realm_resize_resources(uint32_t);
void dcon_realm_set_resources(int32_t, int32_t, float);
float dcon_realm_get_resources(int32_t, int32_t);
void dcon_realm_resize_production(uint32_t);
void dcon_realm_set_production(int32_t, int32_t, float);
float dcon_realm_get_production(int32_t, int32_t);
void dcon_realm_resize_bought(uint32_t);
void dcon_realm_set_bought(int32_t, int32_t, float);
float dcon_realm_get_bought(int32_t, int32_t);
void dcon_realm_resize_sold(uint32_t);
void dcon_realm_set_sold(int32_t, int32_t, float);
float dcon_realm_get_sold(int32_t, int32_t);
void dcon_realm_set_expected_food_consumption(int32_t, float);
float dcon_realm_get_expected_food_consumption(int32_t);
void dcon_delete_realm(int32_t j);
int32_t dcon_create_realm();
bool dcon_realm_is_valid(int32_t);
void dcon_realm_resize(uint32_t sz);
uint32_t dcon_realm_size();
]]

---realm: FFI arrays---
---@type (boolean)[]
DATA.realm_exists= {}
---@type (string)[]
DATA.realm_name= {}
---@type (Culture)[]
DATA.realm_primary_culture= {}
---@type (Faith)[]
DATA.realm_primary_faith= {}
---@type (table<province_id,nil|number>)[]
DATA.realm_quests_raid= {}
---@type (table<province_id,nil|number>)[]
DATA.realm_quests_explore= {}
---@type (table<province_id,nil|number>)[]
DATA.realm_quests_patrol= {}
---@type (table<province_id,table<warband_id,warband_id>>)[]
DATA.realm_patrols= {}
---@type (table<province_id,province_id>)[]
DATA.realm_known_provinces= {}

---realm: LUA bindings---

DATA.realm_size = 15000
DCON.dcon_realm_resize_budget_spending_by_category(39)
DCON.dcon_realm_resize_budget_income_by_category(39)
DCON.dcon_realm_resize_budget_treasury_change_by_category(39)
DCON.dcon_realm_resize_budget(8)
DCON.dcon_realm_resize_resources(101)
DCON.dcon_realm_resize_production(101)
DCON.dcon_realm_resize_bought(101)
DCON.dcon_realm_resize_sold(101)
---@return realm_id
function DATA.create_realm()
    ---@type realm_id
    local i  = DCON.dcon_create_realm() + 1
    return i --[[@as realm_id]]
end
---@param i realm_id
function DATA.delete_realm(i)
    assert(DCON.dcon_realm_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_realm(i - 1)
end
---@param func fun(item: realm_id)
function DATA.for_each_realm(func)
    ---@type number
    local range = DCON.dcon_realm_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_is_valid(i) then func(i + 1 --[[@as realm_id]]) end
    end
end
---@param func fun(item: realm_id):boolean
---@return table<realm_id, realm_id>
function DATA.filter_realm(func)
    ---@type table<realm_id, realm_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_is_valid(i) and func(i + 1 --[[@as realm_id]]) then t[i + 1 --[[@as realm_id]]] = t[i + 1 --[[@as realm_id]]] end
    end
    return t
end

---@param realm_id realm_id valid realm id
---@return boolean exists
function DATA.realm_get_exists(realm_id)
    return DATA.realm_exists[realm_id]
end
---@param realm_id realm_id valid realm id
---@param value boolean valid boolean
function DATA.realm_set_exists(realm_id, value)
    DATA.realm_exists[realm_id] = value
end
---@param realm_id realm_id valid realm id
---@return string name
function DATA.realm_get_name(realm_id)
    return DATA.realm_name[realm_id]
end
---@param realm_id realm_id valid realm id
---@param value string valid string
function DATA.realm_set_name(realm_id, value)
    DATA.realm_name[realm_id] = value
end
---@param realm_id realm_id valid realm id
---@return number budget_change
function DATA.realm_get_budget_change(realm_id)
    return DCON.dcon_realm_get_budget_change(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_budget_change(realm_id, value)
    DCON.dcon_realm_set_budget_change(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_budget_change(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget_change(realm_id - 1)
    DCON.dcon_realm_set_budget_change(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number budget_saved_change
function DATA.realm_get_budget_saved_change(realm_id)
    return DCON.dcon_realm_get_budget_saved_change(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_budget_saved_change(realm_id, value)
    DCON.dcon_realm_set_budget_saved_change(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_budget_saved_change(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget_saved_change(realm_id - 1)
    DCON.dcon_realm_set_budget_saved_change(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@param index ECONOMY_REASON valid
---@return number budget_spending_by_category
function DATA.realm_get_budget_spending_by_category(realm_id, index)
    assert(index ~= 0)
    return DCON.dcon_realm_get_budget_spending_by_category(realm_id - 1, index - 1)
end
---@param realm_id realm_id valid realm id
---@param index ECONOMY_REASON valid index
---@param value number valid number
function DATA.realm_set_budget_spending_by_category(realm_id, index, value)
    DCON.dcon_realm_set_budget_spending_by_category(realm_id - 1, index - 1, value)
end
---@param realm_id realm_id valid realm id
---@param index ECONOMY_REASON valid index
---@param value number valid number
function DATA.realm_inc_budget_spending_by_category(realm_id, index, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget_spending_by_category(realm_id - 1, index - 1)
    DCON.dcon_realm_set_budget_spending_by_category(realm_id - 1, index - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@param index ECONOMY_REASON valid
---@return number budget_income_by_category
function DATA.realm_get_budget_income_by_category(realm_id, index)
    assert(index ~= 0)
    return DCON.dcon_realm_get_budget_income_by_category(realm_id - 1, index - 1)
end
---@param realm_id realm_id valid realm id
---@param index ECONOMY_REASON valid index
---@param value number valid number
function DATA.realm_set_budget_income_by_category(realm_id, index, value)
    DCON.dcon_realm_set_budget_income_by_category(realm_id - 1, index - 1, value)
end
---@param realm_id realm_id valid realm id
---@param index ECONOMY_REASON valid index
---@param value number valid number
function DATA.realm_inc_budget_income_by_category(realm_id, index, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget_income_by_category(realm_id - 1, index - 1)
    DCON.dcon_realm_set_budget_income_by_category(realm_id - 1, index - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@param index ECONOMY_REASON valid
---@return number budget_treasury_change_by_category
function DATA.realm_get_budget_treasury_change_by_category(realm_id, index)
    assert(index ~= 0)
    return DCON.dcon_realm_get_budget_treasury_change_by_category(realm_id - 1, index - 1)
end
---@param realm_id realm_id valid realm id
---@param index ECONOMY_REASON valid index
---@param value number valid number
function DATA.realm_set_budget_treasury_change_by_category(realm_id, index, value)
    DCON.dcon_realm_set_budget_treasury_change_by_category(realm_id - 1, index - 1, value)
end
---@param realm_id realm_id valid realm id
---@param index ECONOMY_REASON valid index
---@param value number valid number
function DATA.realm_inc_budget_treasury_change_by_category(realm_id, index, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget_treasury_change_by_category(realm_id - 1, index - 1)
    DCON.dcon_realm_set_budget_treasury_change_by_category(realm_id - 1, index - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number budget_treasury
function DATA.realm_get_budget_treasury(realm_id)
    return DCON.dcon_realm_get_budget_treasury(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_budget_treasury(realm_id, value)
    DCON.dcon_realm_set_budget_treasury(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_budget_treasury(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget_treasury(realm_id - 1)
    DCON.dcon_realm_set_budget_treasury(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number budget_treasury_target
function DATA.realm_get_budget_treasury_target(realm_id)
    return DCON.dcon_realm_get_budget_treasury_target(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_budget_treasury_target(realm_id, value)
    DCON.dcon_realm_set_budget_treasury_target(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_budget_treasury_target(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget_treasury_target(realm_id - 1)
    DCON.dcon_realm_set_budget_treasury_target(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@param index BUDGET_CATEGORY valid
---@return number budget
function DATA.realm_get_budget_ratio(realm_id, index)
    assert(index ~= 0)
    return DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].ratio
end
---@param realm_id realm_id valid realm id
---@param index BUDGET_CATEGORY valid
---@return number budget
function DATA.realm_get_budget_budget(realm_id, index)
    assert(index ~= 0)
    return DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].budget
end
---@param realm_id realm_id valid realm id
---@param index BUDGET_CATEGORY valid
---@return number budget
function DATA.realm_get_budget_to_be_invested(realm_id, index)
    assert(index ~= 0)
    return DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].to_be_invested
end
---@param realm_id realm_id valid realm id
---@param index BUDGET_CATEGORY valid
---@return number budget
function DATA.realm_get_budget_target(realm_id, index)
    assert(index ~= 0)
    return DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].target
end
---@param realm_id realm_id valid realm id
---@param index BUDGET_CATEGORY valid index
---@param value number valid number
function DATA.realm_set_budget_ratio(realm_id, index, value)
    DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].ratio = value
end
---@param realm_id realm_id valid realm id
---@param index BUDGET_CATEGORY valid index
---@param value number valid number
function DATA.realm_inc_budget_ratio(realm_id, index, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].ratio
    DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].ratio = current + value
end
---@param realm_id realm_id valid realm id
---@param index BUDGET_CATEGORY valid index
---@param value number valid number
function DATA.realm_set_budget_budget(realm_id, index, value)
    DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].budget = value
end
---@param realm_id realm_id valid realm id
---@param index BUDGET_CATEGORY valid index
---@param value number valid number
function DATA.realm_inc_budget_budget(realm_id, index, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].budget
    DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].budget = current + value
end
---@param realm_id realm_id valid realm id
---@param index BUDGET_CATEGORY valid index
---@param value number valid number
function DATA.realm_set_budget_to_be_invested(realm_id, index, value)
    DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].to_be_invested = value
end
---@param realm_id realm_id valid realm id
---@param index BUDGET_CATEGORY valid index
---@param value number valid number
function DATA.realm_inc_budget_to_be_invested(realm_id, index, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].to_be_invested
    DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].to_be_invested = current + value
end
---@param realm_id realm_id valid realm id
---@param index BUDGET_CATEGORY valid index
---@param value number valid number
function DATA.realm_set_budget_target(realm_id, index, value)
    DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].target = value
end
---@param realm_id realm_id valid realm id
---@param index BUDGET_CATEGORY valid index
---@param value number valid number
function DATA.realm_inc_budget_target(realm_id, index, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].target
    DCON.dcon_realm_get_budget(realm_id - 1, index - 1)[0].target = current + value
end
---@param realm_id realm_id valid realm id
---@return number budget_tax_target
function DATA.realm_get_budget_tax_target(realm_id)
    return DCON.dcon_realm_get_budget_tax_target(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_budget_tax_target(realm_id, value)
    DCON.dcon_realm_set_budget_tax_target(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_budget_tax_target(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget_tax_target(realm_id - 1)
    DCON.dcon_realm_set_budget_tax_target(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number budget_tax_collected_this_year
function DATA.realm_get_budget_tax_collected_this_year(realm_id)
    return DCON.dcon_realm_get_budget_tax_collected_this_year(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_budget_tax_collected_this_year(realm_id, value)
    DCON.dcon_realm_set_budget_tax_collected_this_year(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_budget_tax_collected_this_year(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_budget_tax_collected_this_year(realm_id - 1)
    DCON.dcon_realm_set_budget_tax_collected_this_year(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number r
function DATA.realm_get_r(realm_id)
    return DCON.dcon_realm_get_r(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_r(realm_id, value)
    DCON.dcon_realm_set_r(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_r(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_r(realm_id - 1)
    DCON.dcon_realm_set_r(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number g
function DATA.realm_get_g(realm_id)
    return DCON.dcon_realm_get_g(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_g(realm_id, value)
    DCON.dcon_realm_set_g(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_g(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_g(realm_id - 1)
    DCON.dcon_realm_set_g(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number b
function DATA.realm_get_b(realm_id)
    return DCON.dcon_realm_get_b(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_b(realm_id, value)
    DCON.dcon_realm_set_b(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_b(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_b(realm_id - 1)
    DCON.dcon_realm_set_b(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return race_id primary_race
function DATA.realm_get_primary_race(realm_id)
    return DCON.dcon_realm_get_primary_race(realm_id - 1) + 1
end
---@param realm_id realm_id valid realm id
---@param value race_id valid race_id
function DATA.realm_set_primary_race(realm_id, value)
    DCON.dcon_realm_set_primary_race(realm_id - 1, value - 1)
end
---@param realm_id realm_id valid realm id
---@return Culture primary_culture
function DATA.realm_get_primary_culture(realm_id)
    return DATA.realm_primary_culture[realm_id]
end
---@param realm_id realm_id valid realm id
---@param value Culture valid Culture
function DATA.realm_set_primary_culture(realm_id, value)
    DATA.realm_primary_culture[realm_id] = value
end
---@param realm_id realm_id valid realm id
---@return Faith primary_faith
function DATA.realm_get_primary_faith(realm_id)
    return DATA.realm_primary_faith[realm_id]
end
---@param realm_id realm_id valid realm id
---@param value Faith valid Faith
function DATA.realm_set_primary_faith(realm_id, value)
    DATA.realm_primary_faith[realm_id] = value
end
---@param realm_id realm_id valid realm id
---@return province_id capitol
function DATA.realm_get_capitol(realm_id)
    return DCON.dcon_realm_get_capitol(realm_id - 1) + 1
end
---@param realm_id realm_id valid realm id
---@param value province_id valid province_id
function DATA.realm_set_capitol(realm_id, value)
    DCON.dcon_realm_set_capitol(realm_id - 1, value - 1)
end
---@param realm_id realm_id valid realm id
---@return number trading_right_cost
function DATA.realm_get_trading_right_cost(realm_id)
    return DCON.dcon_realm_get_trading_right_cost(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_trading_right_cost(realm_id, value)
    DCON.dcon_realm_set_trading_right_cost(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_trading_right_cost(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_trading_right_cost(realm_id - 1)
    DCON.dcon_realm_set_trading_right_cost(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number building_right_cost
function DATA.realm_get_building_right_cost(realm_id)
    return DCON.dcon_realm_get_building_right_cost(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_building_right_cost(realm_id, value)
    DCON.dcon_realm_set_building_right_cost(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_building_right_cost(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_building_right_cost(realm_id - 1)
    DCON.dcon_realm_set_building_right_cost(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return LAW_TRADE law_trade
function DATA.realm_get_law_trade(realm_id)
    return DCON.dcon_realm_get_law_trade(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value LAW_TRADE valid LAW_TRADE
function DATA.realm_set_law_trade(realm_id, value)
    DCON.dcon_realm_set_law_trade(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@return LAW_BUILDING law_building
function DATA.realm_get_law_building(realm_id)
    return DCON.dcon_realm_get_law_building(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value LAW_BUILDING valid LAW_BUILDING
function DATA.realm_set_law_building(realm_id, value)
    DCON.dcon_realm_set_law_building(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@return table<province_id,nil|number> quests_raid reward for raid
function DATA.realm_get_quests_raid(realm_id)
    return DATA.realm_quests_raid[realm_id]
end
---@param realm_id realm_id valid realm id
---@param value table<province_id,nil|number> valid table<province_id,nil|number>
function DATA.realm_set_quests_raid(realm_id, value)
    DATA.realm_quests_raid[realm_id] = value
end
---@param realm_id realm_id valid realm id
---@return table<province_id,nil|number> quests_explore reward for exploration
function DATA.realm_get_quests_explore(realm_id)
    return DATA.realm_quests_explore[realm_id]
end
---@param realm_id realm_id valid realm id
---@param value table<province_id,nil|number> valid table<province_id,nil|number>
function DATA.realm_set_quests_explore(realm_id, value)
    DATA.realm_quests_explore[realm_id] = value
end
---@param realm_id realm_id valid realm id
---@return table<province_id,nil|number> quests_patrol reward for patrol
function DATA.realm_get_quests_patrol(realm_id)
    return DATA.realm_quests_patrol[realm_id]
end
---@param realm_id realm_id valid realm id
---@param value table<province_id,nil|number> valid table<province_id,nil|number>
function DATA.realm_set_quests_patrol(realm_id, value)
    DATA.realm_quests_patrol[realm_id] = value
end
---@param realm_id realm_id valid realm id
---@return table<province_id,table<warband_id,warband_id>> patrols
function DATA.realm_get_patrols(realm_id)
    return DATA.realm_patrols[realm_id]
end
---@param realm_id realm_id valid realm id
---@param value table<province_id,table<warband_id,warband_id>> valid table<province_id,table<warband_id,warband_id>>
function DATA.realm_set_patrols(realm_id, value)
    DATA.realm_patrols[realm_id] = value
end
---@param realm_id realm_id valid realm id
---@return boolean prepare_attack_flag
function DATA.realm_get_prepare_attack_flag(realm_id)
    return DCON.dcon_realm_get_prepare_attack_flag(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value boolean valid boolean
function DATA.realm_set_prepare_attack_flag(realm_id, value)
    DCON.dcon_realm_set_prepare_attack_flag(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@return table<province_id,province_id> known_provinces For terra incognita.
function DATA.realm_get_known_provinces(realm_id)
    return DATA.realm_known_provinces[realm_id]
end
---@param realm_id realm_id valid realm id
---@param value table<province_id,province_id> valid table<province_id,province_id>
function DATA.realm_set_known_provinces(realm_id, value)
    DATA.realm_known_provinces[realm_id] = value
end
---@param realm_id realm_id valid realm id
---@return number coa_base_r
function DATA.realm_get_coa_base_r(realm_id)
    return DCON.dcon_realm_get_coa_base_r(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_base_r(realm_id, value)
    DCON.dcon_realm_set_coa_base_r(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_base_r(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_base_r(realm_id - 1)
    DCON.dcon_realm_set_coa_base_r(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_base_g
function DATA.realm_get_coa_base_g(realm_id)
    return DCON.dcon_realm_get_coa_base_g(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_base_g(realm_id, value)
    DCON.dcon_realm_set_coa_base_g(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_base_g(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_base_g(realm_id - 1)
    DCON.dcon_realm_set_coa_base_g(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_base_b
function DATA.realm_get_coa_base_b(realm_id)
    return DCON.dcon_realm_get_coa_base_b(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_base_b(realm_id, value)
    DCON.dcon_realm_set_coa_base_b(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_base_b(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_base_b(realm_id - 1)
    DCON.dcon_realm_set_coa_base_b(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_background_r
function DATA.realm_get_coa_background_r(realm_id)
    return DCON.dcon_realm_get_coa_background_r(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_background_r(realm_id, value)
    DCON.dcon_realm_set_coa_background_r(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_background_r(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_background_r(realm_id - 1)
    DCON.dcon_realm_set_coa_background_r(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_background_g
function DATA.realm_get_coa_background_g(realm_id)
    return DCON.dcon_realm_get_coa_background_g(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_background_g(realm_id, value)
    DCON.dcon_realm_set_coa_background_g(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_background_g(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_background_g(realm_id - 1)
    DCON.dcon_realm_set_coa_background_g(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_background_b
function DATA.realm_get_coa_background_b(realm_id)
    return DCON.dcon_realm_get_coa_background_b(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_background_b(realm_id, value)
    DCON.dcon_realm_set_coa_background_b(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_background_b(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_background_b(realm_id - 1)
    DCON.dcon_realm_set_coa_background_b(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_foreground_r
function DATA.realm_get_coa_foreground_r(realm_id)
    return DCON.dcon_realm_get_coa_foreground_r(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_foreground_r(realm_id, value)
    DCON.dcon_realm_set_coa_foreground_r(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_foreground_r(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_foreground_r(realm_id - 1)
    DCON.dcon_realm_set_coa_foreground_r(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_foreground_g
function DATA.realm_get_coa_foreground_g(realm_id)
    return DCON.dcon_realm_get_coa_foreground_g(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_foreground_g(realm_id, value)
    DCON.dcon_realm_set_coa_foreground_g(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_foreground_g(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_foreground_g(realm_id - 1)
    DCON.dcon_realm_set_coa_foreground_g(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_foreground_b
function DATA.realm_get_coa_foreground_b(realm_id)
    return DCON.dcon_realm_get_coa_foreground_b(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_foreground_b(realm_id, value)
    DCON.dcon_realm_set_coa_foreground_b(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_foreground_b(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_foreground_b(realm_id - 1)
    DCON.dcon_realm_set_coa_foreground_b(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_emblem_r
function DATA.realm_get_coa_emblem_r(realm_id)
    return DCON.dcon_realm_get_coa_emblem_r(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_emblem_r(realm_id, value)
    DCON.dcon_realm_set_coa_emblem_r(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_emblem_r(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_emblem_r(realm_id - 1)
    DCON.dcon_realm_set_coa_emblem_r(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_emblem_g
function DATA.realm_get_coa_emblem_g(realm_id)
    return DCON.dcon_realm_get_coa_emblem_g(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_emblem_g(realm_id, value)
    DCON.dcon_realm_set_coa_emblem_g(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_emblem_g(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_emblem_g(realm_id - 1)
    DCON.dcon_realm_set_coa_emblem_g(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_emblem_b
function DATA.realm_get_coa_emblem_b(realm_id)
    return DCON.dcon_realm_get_coa_emblem_b(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_emblem_b(realm_id, value)
    DCON.dcon_realm_set_coa_emblem_b(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_emblem_b(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_emblem_b(realm_id - 1)
    DCON.dcon_realm_set_coa_emblem_b(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_background_image
function DATA.realm_get_coa_background_image(realm_id)
    return DCON.dcon_realm_get_coa_background_image(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_background_image(realm_id, value)
    DCON.dcon_realm_set_coa_background_image(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_background_image(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_background_image(realm_id - 1)
    DCON.dcon_realm_set_coa_background_image(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_foreground_image
function DATA.realm_get_coa_foreground_image(realm_id)
    return DCON.dcon_realm_get_coa_foreground_image(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_foreground_image(realm_id, value)
    DCON.dcon_realm_set_coa_foreground_image(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_foreground_image(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_foreground_image(realm_id - 1)
    DCON.dcon_realm_set_coa_foreground_image(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number coa_emblem_image
function DATA.realm_get_coa_emblem_image(realm_id)
    return DCON.dcon_realm_get_coa_emblem_image(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_coa_emblem_image(realm_id, value)
    DCON.dcon_realm_set_coa_emblem_image(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_coa_emblem_image(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_coa_emblem_image(realm_id - 1)
    DCON.dcon_realm_set_coa_emblem_image(realm_id - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@param index trade_good_id valid
---@return number resources Currently stockpiled resources
function DATA.realm_get_resources(realm_id, index)
    assert(index ~= 0)
    return DCON.dcon_realm_get_resources(realm_id - 1, index - 1)
end
---@param realm_id realm_id valid realm id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.realm_set_resources(realm_id, index, value)
    DCON.dcon_realm_set_resources(realm_id - 1, index - 1, value)
end
---@param realm_id realm_id valid realm id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.realm_inc_resources(realm_id, index, value)
    ---@type number
    local current = DCON.dcon_realm_get_resources(realm_id - 1, index - 1)
    DCON.dcon_realm_set_resources(realm_id - 1, index - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@param index trade_good_id valid
---@return number production A "balance" of resource creation
function DATA.realm_get_production(realm_id, index)
    assert(index ~= 0)
    return DCON.dcon_realm_get_production(realm_id - 1, index - 1)
end
---@param realm_id realm_id valid realm id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.realm_set_production(realm_id, index, value)
    DCON.dcon_realm_set_production(realm_id - 1, index - 1, value)
end
---@param realm_id realm_id valid realm id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.realm_inc_production(realm_id, index, value)
    ---@type number
    local current = DCON.dcon_realm_get_production(realm_id - 1, index - 1)
    DCON.dcon_realm_set_production(realm_id - 1, index - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@param index trade_good_id valid
---@return number bought
function DATA.realm_get_bought(realm_id, index)
    assert(index ~= 0)
    return DCON.dcon_realm_get_bought(realm_id - 1, index - 1)
end
---@param realm_id realm_id valid realm id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.realm_set_bought(realm_id, index, value)
    DCON.dcon_realm_set_bought(realm_id - 1, index - 1, value)
end
---@param realm_id realm_id valid realm id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.realm_inc_bought(realm_id, index, value)
    ---@type number
    local current = DCON.dcon_realm_get_bought(realm_id - 1, index - 1)
    DCON.dcon_realm_set_bought(realm_id - 1, index - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@param index trade_good_id valid
---@return number sold
function DATA.realm_get_sold(realm_id, index)
    assert(index ~= 0)
    return DCON.dcon_realm_get_sold(realm_id - 1, index - 1)
end
---@param realm_id realm_id valid realm id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.realm_set_sold(realm_id, index, value)
    DCON.dcon_realm_set_sold(realm_id - 1, index - 1, value)
end
---@param realm_id realm_id valid realm id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.realm_inc_sold(realm_id, index, value)
    ---@type number
    local current = DCON.dcon_realm_get_sold(realm_id - 1, index - 1)
    DCON.dcon_realm_set_sold(realm_id - 1, index - 1, current + value)
end
---@param realm_id realm_id valid realm id
---@return number expected_food_consumption
function DATA.realm_get_expected_food_consumption(realm_id)
    return DCON.dcon_realm_get_expected_food_consumption(realm_id - 1)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_set_expected_food_consumption(realm_id, value)
    DCON.dcon_realm_set_expected_food_consumption(realm_id - 1, value)
end
---@param realm_id realm_id valid realm id
---@param value number valid number
function DATA.realm_inc_expected_food_consumption(realm_id, value)
    ---@type number
    local current = DCON.dcon_realm_get_expected_food_consumption(realm_id - 1)
    DCON.dcon_realm_set_expected_food_consumption(realm_id - 1, current + value)
end

local fat_realm_id_metatable = {
    __index = function (t,k)
        if (k == "exists") then return DATA.realm_get_exists(t.id) end
        if (k == "name") then return DATA.realm_get_name(t.id) end
        if (k == "budget_change") then return DATA.realm_get_budget_change(t.id) end
        if (k == "budget_saved_change") then return DATA.realm_get_budget_saved_change(t.id) end
        if (k == "budget_treasury") then return DATA.realm_get_budget_treasury(t.id) end
        if (k == "budget_treasury_target") then return DATA.realm_get_budget_treasury_target(t.id) end
        if (k == "budget_tax_target") then return DATA.realm_get_budget_tax_target(t.id) end
        if (k == "budget_tax_collected_this_year") then return DATA.realm_get_budget_tax_collected_this_year(t.id) end
        if (k == "r") then return DATA.realm_get_r(t.id) end
        if (k == "g") then return DATA.realm_get_g(t.id) end
        if (k == "b") then return DATA.realm_get_b(t.id) end
        if (k == "primary_race") then return DATA.realm_get_primary_race(t.id) end
        if (k == "primary_culture") then return DATA.realm_get_primary_culture(t.id) end
        if (k == "primary_faith") then return DATA.realm_get_primary_faith(t.id) end
        if (k == "capitol") then return DATA.realm_get_capitol(t.id) end
        if (k == "trading_right_cost") then return DATA.realm_get_trading_right_cost(t.id) end
        if (k == "building_right_cost") then return DATA.realm_get_building_right_cost(t.id) end
        if (k == "law_trade") then return DATA.realm_get_law_trade(t.id) end
        if (k == "law_building") then return DATA.realm_get_law_building(t.id) end
        if (k == "quests_raid") then return DATA.realm_get_quests_raid(t.id) end
        if (k == "quests_explore") then return DATA.realm_get_quests_explore(t.id) end
        if (k == "quests_patrol") then return DATA.realm_get_quests_patrol(t.id) end
        if (k == "patrols") then return DATA.realm_get_patrols(t.id) end
        if (k == "prepare_attack_flag") then return DATA.realm_get_prepare_attack_flag(t.id) end
        if (k == "known_provinces") then return DATA.realm_get_known_provinces(t.id) end
        if (k == "coa_base_r") then return DATA.realm_get_coa_base_r(t.id) end
        if (k == "coa_base_g") then return DATA.realm_get_coa_base_g(t.id) end
        if (k == "coa_base_b") then return DATA.realm_get_coa_base_b(t.id) end
        if (k == "coa_background_r") then return DATA.realm_get_coa_background_r(t.id) end
        if (k == "coa_background_g") then return DATA.realm_get_coa_background_g(t.id) end
        if (k == "coa_background_b") then return DATA.realm_get_coa_background_b(t.id) end
        if (k == "coa_foreground_r") then return DATA.realm_get_coa_foreground_r(t.id) end
        if (k == "coa_foreground_g") then return DATA.realm_get_coa_foreground_g(t.id) end
        if (k == "coa_foreground_b") then return DATA.realm_get_coa_foreground_b(t.id) end
        if (k == "coa_emblem_r") then return DATA.realm_get_coa_emblem_r(t.id) end
        if (k == "coa_emblem_g") then return DATA.realm_get_coa_emblem_g(t.id) end
        if (k == "coa_emblem_b") then return DATA.realm_get_coa_emblem_b(t.id) end
        if (k == "coa_background_image") then return DATA.realm_get_coa_background_image(t.id) end
        if (k == "coa_foreground_image") then return DATA.realm_get_coa_foreground_image(t.id) end
        if (k == "coa_emblem_image") then return DATA.realm_get_coa_emblem_image(t.id) end
        if (k == "expected_food_consumption") then return DATA.realm_get_expected_food_consumption(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "exists") then
            DATA.realm_set_exists(t.id, v)
            return
        end
        if (k == "name") then
            DATA.realm_set_name(t.id, v)
            return
        end
        if (k == "budget_change") then
            DATA.realm_set_budget_change(t.id, v)
            return
        end
        if (k == "budget_saved_change") then
            DATA.realm_set_budget_saved_change(t.id, v)
            return
        end
        if (k == "budget_treasury") then
            DATA.realm_set_budget_treasury(t.id, v)
            return
        end
        if (k == "budget_treasury_target") then
            DATA.realm_set_budget_treasury_target(t.id, v)
            return
        end
        if (k == "budget_tax_target") then
            DATA.realm_set_budget_tax_target(t.id, v)
            return
        end
        if (k == "budget_tax_collected_this_year") then
            DATA.realm_set_budget_tax_collected_this_year(t.id, v)
            return
        end
        if (k == "r") then
            DATA.realm_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.realm_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.realm_set_b(t.id, v)
            return
        end
        if (k == "primary_race") then
            DATA.realm_set_primary_race(t.id, v)
            return
        end
        if (k == "primary_culture") then
            DATA.realm_set_primary_culture(t.id, v)
            return
        end
        if (k == "primary_faith") then
            DATA.realm_set_primary_faith(t.id, v)
            return
        end
        if (k == "capitol") then
            DATA.realm_set_capitol(t.id, v)
            return
        end
        if (k == "trading_right_cost") then
            DATA.realm_set_trading_right_cost(t.id, v)
            return
        end
        if (k == "building_right_cost") then
            DATA.realm_set_building_right_cost(t.id, v)
            return
        end
        if (k == "law_trade") then
            DATA.realm_set_law_trade(t.id, v)
            return
        end
        if (k == "law_building") then
            DATA.realm_set_law_building(t.id, v)
            return
        end
        if (k == "quests_raid") then
            DATA.realm_set_quests_raid(t.id, v)
            return
        end
        if (k == "quests_explore") then
            DATA.realm_set_quests_explore(t.id, v)
            return
        end
        if (k == "quests_patrol") then
            DATA.realm_set_quests_patrol(t.id, v)
            return
        end
        if (k == "patrols") then
            DATA.realm_set_patrols(t.id, v)
            return
        end
        if (k == "prepare_attack_flag") then
            DATA.realm_set_prepare_attack_flag(t.id, v)
            return
        end
        if (k == "known_provinces") then
            DATA.realm_set_known_provinces(t.id, v)
            return
        end
        if (k == "coa_base_r") then
            DATA.realm_set_coa_base_r(t.id, v)
            return
        end
        if (k == "coa_base_g") then
            DATA.realm_set_coa_base_g(t.id, v)
            return
        end
        if (k == "coa_base_b") then
            DATA.realm_set_coa_base_b(t.id, v)
            return
        end
        if (k == "coa_background_r") then
            DATA.realm_set_coa_background_r(t.id, v)
            return
        end
        if (k == "coa_background_g") then
            DATA.realm_set_coa_background_g(t.id, v)
            return
        end
        if (k == "coa_background_b") then
            DATA.realm_set_coa_background_b(t.id, v)
            return
        end
        if (k == "coa_foreground_r") then
            DATA.realm_set_coa_foreground_r(t.id, v)
            return
        end
        if (k == "coa_foreground_g") then
            DATA.realm_set_coa_foreground_g(t.id, v)
            return
        end
        if (k == "coa_foreground_b") then
            DATA.realm_set_coa_foreground_b(t.id, v)
            return
        end
        if (k == "coa_emblem_r") then
            DATA.realm_set_coa_emblem_r(t.id, v)
            return
        end
        if (k == "coa_emblem_g") then
            DATA.realm_set_coa_emblem_g(t.id, v)
            return
        end
        if (k == "coa_emblem_b") then
            DATA.realm_set_coa_emblem_b(t.id, v)
            return
        end
        if (k == "coa_background_image") then
            DATA.realm_set_coa_background_image(t.id, v)
            return
        end
        if (k == "coa_foreground_image") then
            DATA.realm_set_coa_foreground_image(t.id, v)
            return
        end
        if (k == "coa_emblem_image") then
            DATA.realm_set_coa_emblem_image(t.id, v)
            return
        end
        if (k == "expected_food_consumption") then
            DATA.realm_set_expected_food_consumption(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id realm_id
---@return fat_realm_id fat_id
function DATA.fatten_realm(id)
    local result = {id = id}
    setmetatable(result, fat_realm_id_metatable)    return result
end
----------negotiation----------


---negotiation: LSP types---

---Unique identificator for negotiation entity
---@class (exact) negotiation_id : number
---@field is_negotiation nil

---@class (exact) fat_negotiation_id
---@field id negotiation_id Unique negotiation id
---@field initiator pop_id
---@field target pop_id

---@class struct_negotiation


ffi.cdef[[
void dcon_delete_negotiation(int32_t j);
int32_t dcon_force_create_negotiation(int32_t initiator, int32_t target);
void dcon_negotiation_set_initiator(int32_t, int32_t);
int32_t dcon_negotiation_get_initiator(int32_t);
int32_t dcon_pop_get_range_negotiation_as_initiator(int32_t);
int32_t dcon_pop_get_index_negotiation_as_initiator(int32_t, int32_t);
void dcon_negotiation_set_target(int32_t, int32_t);
int32_t dcon_negotiation_get_target(int32_t);
int32_t dcon_pop_get_range_negotiation_as_target(int32_t);
int32_t dcon_pop_get_index_negotiation_as_target(int32_t, int32_t);
bool dcon_negotiation_is_valid(int32_t);
void dcon_negotiation_resize(uint32_t sz);
uint32_t dcon_negotiation_size();
]]

---negotiation: FFI arrays---

---negotiation: LUA bindings---

DATA.negotiation_size = 2500
---@param initiator pop_id
---@param target pop_id
---@return negotiation_id
function DATA.force_create_negotiation(initiator, target)
    ---@type negotiation_id
    local i = DCON.dcon_force_create_negotiation(initiator - 1, target - 1) + 1
    return i --[[@as negotiation_id]]
end
---@param i negotiation_id
function DATA.delete_negotiation(i)
    assert(DCON.dcon_negotiation_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_negotiation(i - 1)
end
---@param func fun(item: negotiation_id)
function DATA.for_each_negotiation(func)
    ---@type number
    local range = DCON.dcon_negotiation_size()
    for i = 0, range - 1 do
        if DCON.dcon_negotiation_is_valid(i) then func(i + 1 --[[@as negotiation_id]]) end
    end
end
---@param func fun(item: negotiation_id):boolean
---@return table<negotiation_id, negotiation_id>
function DATA.filter_negotiation(func)
    ---@type table<negotiation_id, negotiation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_negotiation_size()
    for i = 0, range - 1 do
        if DCON.dcon_negotiation_is_valid(i) and func(i + 1 --[[@as negotiation_id]]) then t[i + 1 --[[@as negotiation_id]]] = t[i + 1 --[[@as negotiation_id]]] end
    end
    return t
end

---@param initiator negotiation_id valid pop_id
---@return pop_id Data retrieved from negotiation
function DATA.negotiation_get_initiator(initiator)
    return DCON.dcon_negotiation_get_initiator(initiator - 1) + 1
end
---@param initiator pop_id valid pop_id
---@return negotiation_id[] An array of negotiation
function DATA.get_negotiation_from_initiator(initiator)
    local result = {}
    DATA.for_each_negotiation_from_initiator(initiator, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param initiator pop_id valid pop_id
---@param func fun(item: negotiation_id) valid pop_id
function DATA.for_each_negotiation_from_initiator(initiator, func)
    ---@type number
    local range = DCON.dcon_pop_get_range_negotiation_as_initiator(initiator - 1)
    for i = 0, range - 1 do
        ---@type negotiation_id
        local accessed_element = DCON.dcon_pop_get_index_negotiation_as_initiator(initiator - 1, i) + 1
        if DCON.dcon_negotiation_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param initiator pop_id valid pop_id
---@param func fun(item: negotiation_id):boolean
---@return negotiation_id[]
function DATA.filter_array_negotiation_from_initiator(initiator, func)
    ---@type table<negotiation_id, negotiation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_negotiation_as_initiator(initiator - 1)
    for i = 0, range - 1 do
        ---@type negotiation_id
        local accessed_element = DCON.dcon_pop_get_index_negotiation_as_initiator(initiator - 1, i) + 1
        if DCON.dcon_negotiation_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param initiator pop_id valid pop_id
---@param func fun(item: negotiation_id):boolean
---@return table<negotiation_id, negotiation_id>
function DATA.filter_negotiation_from_initiator(initiator, func)
    ---@type table<negotiation_id, negotiation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_negotiation_as_initiator(initiator - 1)
    for i = 0, range - 1 do
        ---@type negotiation_id
        local accessed_element = DCON.dcon_pop_get_index_negotiation_as_initiator(initiator - 1, i) + 1
        if DCON.dcon_negotiation_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param negotiation_id negotiation_id valid negotiation id
---@param value pop_id valid pop_id
function DATA.negotiation_set_initiator(negotiation_id, value)
    DCON.dcon_negotiation_set_initiator(negotiation_id - 1, value - 1)
end
---@param target negotiation_id valid pop_id
---@return pop_id Data retrieved from negotiation
function DATA.negotiation_get_target(target)
    return DCON.dcon_negotiation_get_target(target - 1) + 1
end
---@param target pop_id valid pop_id
---@return negotiation_id[] An array of negotiation
function DATA.get_negotiation_from_target(target)
    local result = {}
    DATA.for_each_negotiation_from_target(target, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param target pop_id valid pop_id
---@param func fun(item: negotiation_id) valid pop_id
function DATA.for_each_negotiation_from_target(target, func)
    ---@type number
    local range = DCON.dcon_pop_get_range_negotiation_as_target(target - 1)
    for i = 0, range - 1 do
        ---@type negotiation_id
        local accessed_element = DCON.dcon_pop_get_index_negotiation_as_target(target - 1, i) + 1
        if DCON.dcon_negotiation_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param target pop_id valid pop_id
---@param func fun(item: negotiation_id):boolean
---@return negotiation_id[]
function DATA.filter_array_negotiation_from_target(target, func)
    ---@type table<negotiation_id, negotiation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_negotiation_as_target(target - 1)
    for i = 0, range - 1 do
        ---@type negotiation_id
        local accessed_element = DCON.dcon_pop_get_index_negotiation_as_target(target - 1, i) + 1
        if DCON.dcon_negotiation_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param target pop_id valid pop_id
---@param func fun(item: negotiation_id):boolean
---@return table<negotiation_id, negotiation_id>
function DATA.filter_negotiation_from_target(target, func)
    ---@type table<negotiation_id, negotiation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_negotiation_as_target(target - 1)
    for i = 0, range - 1 do
        ---@type negotiation_id
        local accessed_element = DCON.dcon_pop_get_index_negotiation_as_target(target - 1, i) + 1
        if DCON.dcon_negotiation_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param negotiation_id negotiation_id valid negotiation id
---@param value pop_id valid pop_id
function DATA.negotiation_set_target(negotiation_id, value)
    DCON.dcon_negotiation_set_target(negotiation_id - 1, value - 1)
end

local fat_negotiation_id_metatable = {
    __index = function (t,k)
        if (k == "initiator") then return DATA.negotiation_get_initiator(t.id) end
        if (k == "target") then return DATA.negotiation_get_target(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "initiator") then
            DATA.negotiation_set_initiator(t.id, v)
            return
        end
        if (k == "target") then
            DATA.negotiation_set_target(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id negotiation_id
---@return fat_negotiation_id fat_id
function DATA.fatten_negotiation(id)
    local result = {id = id}
    setmetatable(result, fat_negotiation_id_metatable)    return result
end
----------building----------


---building: LSP types---

---Unique identificator for building entity
---@class (exact) building_id : number
---@field is_building nil

---@class (exact) fat_building_id
---@field id building_id Unique building id
---@field current_type building_type_id
---@field savings number
---@field subsidy number
---@field subsidy_last number
---@field income_mean number
---@field last_income number
---@field last_donation_to_owner number
---@field unused number
---@field work_ratio number
---@field production_scale number

---@class struct_building
---@field current_type building_type_id
---@field savings number
---@field subsidy number
---@field subsidy_last number
---@field income_mean number
---@field last_income number
---@field last_donation_to_owner number
---@field unused number
---@field work_ratio number
---@field production_scale number
---@field spent_on_inputs table<number, struct_use_case_container>
---@field earn_from_outputs table<number, struct_trade_good_container>
---@field amount_of_inputs table<number, struct_use_case_container>
---@field amount_of_outputs table<number, struct_trade_good_container>
---@field inventory table<trade_good_id, number>


ffi.cdef[[
void dcon_building_set_current_type(int32_t, uint32_t);
uint32_t dcon_building_get_current_type(int32_t);
void dcon_building_set_savings(int32_t, float);
float dcon_building_get_savings(int32_t);
void dcon_building_set_subsidy(int32_t, float);
float dcon_building_get_subsidy(int32_t);
void dcon_building_set_subsidy_last(int32_t, float);
float dcon_building_get_subsidy_last(int32_t);
void dcon_building_set_income_mean(int32_t, float);
float dcon_building_get_income_mean(int32_t);
void dcon_building_set_last_income(int32_t, float);
float dcon_building_get_last_income(int32_t);
void dcon_building_set_last_donation_to_owner(int32_t, float);
float dcon_building_get_last_donation_to_owner(int32_t);
void dcon_building_set_unused(int32_t, float);
float dcon_building_get_unused(int32_t);
void dcon_building_set_work_ratio(int32_t, float);
float dcon_building_get_work_ratio(int32_t);
void dcon_building_set_production_scale(int32_t, float);
float dcon_building_get_production_scale(int32_t);
void dcon_building_resize_spent_on_inputs(uint32_t);
use_case_container* dcon_building_get_spent_on_inputs(int32_t, int32_t);
void dcon_building_resize_earn_from_outputs(uint32_t);
trade_good_container* dcon_building_get_earn_from_outputs(int32_t, int32_t);
void dcon_building_resize_amount_of_inputs(uint32_t);
use_case_container* dcon_building_get_amount_of_inputs(int32_t, int32_t);
void dcon_building_resize_amount_of_outputs(uint32_t);
trade_good_container* dcon_building_get_amount_of_outputs(int32_t, int32_t);
void dcon_building_resize_inventory(uint32_t);
void dcon_building_set_inventory(int32_t, int32_t, float);
float dcon_building_get_inventory(int32_t, int32_t);
void dcon_delete_building(int32_t j);
int32_t dcon_create_building();
bool dcon_building_is_valid(int32_t);
void dcon_building_resize(uint32_t sz);
uint32_t dcon_building_size();
]]

---building: FFI arrays---

---building: LUA bindings---

DATA.building_size = 200000
DCON.dcon_building_resize_spent_on_inputs(9)
DCON.dcon_building_resize_earn_from_outputs(9)
DCON.dcon_building_resize_amount_of_inputs(9)
DCON.dcon_building_resize_amount_of_outputs(9)
DCON.dcon_building_resize_inventory(101)
---@return building_id
function DATA.create_building()
    ---@type building_id
    local i  = DCON.dcon_create_building() + 1
    return i --[[@as building_id]]
end
---@param i building_id
function DATA.delete_building(i)
    assert(DCON.dcon_building_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_building(i - 1)
end
---@param func fun(item: building_id)
function DATA.for_each_building(func)
    ---@type number
    local range = DCON.dcon_building_size()
    for i = 0, range - 1 do
        if DCON.dcon_building_is_valid(i) then func(i + 1 --[[@as building_id]]) end
    end
end
---@param func fun(item: building_id):boolean
---@return table<building_id, building_id>
function DATA.filter_building(func)
    ---@type table<building_id, building_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_building_size()
    for i = 0, range - 1 do
        if DCON.dcon_building_is_valid(i) and func(i + 1 --[[@as building_id]]) then t[i + 1 --[[@as building_id]]] = t[i + 1 --[[@as building_id]]] end
    end
    return t
end

---@param building_id building_id valid building id
---@return building_type_id current_type
function DATA.building_get_current_type(building_id)
    return DCON.dcon_building_get_current_type(building_id - 1) + 1
end
---@param building_id building_id valid building id
---@param value building_type_id valid building_type_id
function DATA.building_set_current_type(building_id, value)
    DCON.dcon_building_set_current_type(building_id - 1, value - 1)
end
---@param building_id building_id valid building id
---@return number savings
function DATA.building_get_savings(building_id)
    return DCON.dcon_building_get_savings(building_id - 1)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_set_savings(building_id, value)
    DCON.dcon_building_set_savings(building_id - 1, value)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_inc_savings(building_id, value)
    ---@type number
    local current = DCON.dcon_building_get_savings(building_id - 1)
    DCON.dcon_building_set_savings(building_id - 1, current + value)
end
---@param building_id building_id valid building id
---@return number subsidy
function DATA.building_get_subsidy(building_id)
    return DCON.dcon_building_get_subsidy(building_id - 1)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_set_subsidy(building_id, value)
    DCON.dcon_building_set_subsidy(building_id - 1, value)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_inc_subsidy(building_id, value)
    ---@type number
    local current = DCON.dcon_building_get_subsidy(building_id - 1)
    DCON.dcon_building_set_subsidy(building_id - 1, current + value)
end
---@param building_id building_id valid building id
---@return number subsidy_last
function DATA.building_get_subsidy_last(building_id)
    return DCON.dcon_building_get_subsidy_last(building_id - 1)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_set_subsidy_last(building_id, value)
    DCON.dcon_building_set_subsidy_last(building_id - 1, value)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_inc_subsidy_last(building_id, value)
    ---@type number
    local current = DCON.dcon_building_get_subsidy_last(building_id - 1)
    DCON.dcon_building_set_subsidy_last(building_id - 1, current + value)
end
---@param building_id building_id valid building id
---@return number income_mean
function DATA.building_get_income_mean(building_id)
    return DCON.dcon_building_get_income_mean(building_id - 1)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_set_income_mean(building_id, value)
    DCON.dcon_building_set_income_mean(building_id - 1, value)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_inc_income_mean(building_id, value)
    ---@type number
    local current = DCON.dcon_building_get_income_mean(building_id - 1)
    DCON.dcon_building_set_income_mean(building_id - 1, current + value)
end
---@param building_id building_id valid building id
---@return number last_income
function DATA.building_get_last_income(building_id)
    return DCON.dcon_building_get_last_income(building_id - 1)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_set_last_income(building_id, value)
    DCON.dcon_building_set_last_income(building_id - 1, value)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_inc_last_income(building_id, value)
    ---@type number
    local current = DCON.dcon_building_get_last_income(building_id - 1)
    DCON.dcon_building_set_last_income(building_id - 1, current + value)
end
---@param building_id building_id valid building id
---@return number last_donation_to_owner
function DATA.building_get_last_donation_to_owner(building_id)
    return DCON.dcon_building_get_last_donation_to_owner(building_id - 1)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_set_last_donation_to_owner(building_id, value)
    DCON.dcon_building_set_last_donation_to_owner(building_id - 1, value)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_inc_last_donation_to_owner(building_id, value)
    ---@type number
    local current = DCON.dcon_building_get_last_donation_to_owner(building_id - 1)
    DCON.dcon_building_set_last_donation_to_owner(building_id - 1, current + value)
end
---@param building_id building_id valid building id
---@return number unused
function DATA.building_get_unused(building_id)
    return DCON.dcon_building_get_unused(building_id - 1)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_set_unused(building_id, value)
    DCON.dcon_building_set_unused(building_id - 1, value)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_inc_unused(building_id, value)
    ---@type number
    local current = DCON.dcon_building_get_unused(building_id - 1)
    DCON.dcon_building_set_unused(building_id - 1, current + value)
end
---@param building_id building_id valid building id
---@return number work_ratio
function DATA.building_get_work_ratio(building_id)
    return DCON.dcon_building_get_work_ratio(building_id - 1)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_set_work_ratio(building_id, value)
    DCON.dcon_building_set_work_ratio(building_id - 1, value)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_inc_work_ratio(building_id, value)
    ---@type number
    local current = DCON.dcon_building_get_work_ratio(building_id - 1)
    DCON.dcon_building_set_work_ratio(building_id - 1, current + value)
end
---@param building_id building_id valid building id
---@return number production_scale
function DATA.building_get_production_scale(building_id)
    return DCON.dcon_building_get_production_scale(building_id - 1)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_set_production_scale(building_id, value)
    DCON.dcon_building_set_production_scale(building_id - 1, value)
end
---@param building_id building_id valid building id
---@param value number valid number
function DATA.building_inc_production_scale(building_id, value)
    ---@type number
    local current = DCON.dcon_building_get_production_scale(building_id - 1)
    DCON.dcon_building_set_production_scale(building_id - 1, current + value)
end
---@param building_id building_id valid building id
---@param index number valid
---@return use_case_id spent_on_inputs
function DATA.building_get_spent_on_inputs_use(building_id, index)
    assert(index ~= 0)
    return DCON.dcon_building_get_spent_on_inputs(building_id - 1, index - 1)[0].use
end
---@param building_id building_id valid building id
---@param index number valid
---@return number spent_on_inputs
function DATA.building_get_spent_on_inputs_amount(building_id, index)
    assert(index ~= 0)
    return DCON.dcon_building_get_spent_on_inputs(building_id - 1, index - 1)[0].amount
end
---@param building_id building_id valid building id
---@param index number valid index
---@param value use_case_id valid use_case_id
function DATA.building_set_spent_on_inputs_use(building_id, index, value)
    DCON.dcon_building_get_spent_on_inputs(building_id - 1, index - 1)[0].use = value
end
---@param building_id building_id valid building id
---@param index number valid index
---@param value number valid number
function DATA.building_set_spent_on_inputs_amount(building_id, index, value)
    DCON.dcon_building_get_spent_on_inputs(building_id - 1, index - 1)[0].amount = value
end
---@param building_id building_id valid building id
---@param index number valid index
---@param value number valid number
function DATA.building_inc_spent_on_inputs_amount(building_id, index, value)
    ---@type number
    local current = DCON.dcon_building_get_spent_on_inputs(building_id - 1, index - 1)[0].amount
    DCON.dcon_building_get_spent_on_inputs(building_id - 1, index - 1)[0].amount = current + value
end
---@param building_id building_id valid building id
---@param index number valid
---@return trade_good_id earn_from_outputs
function DATA.building_get_earn_from_outputs_good(building_id, index)
    assert(index ~= 0)
    return DCON.dcon_building_get_earn_from_outputs(building_id - 1, index - 1)[0].good
end
---@param building_id building_id valid building id
---@param index number valid
---@return number earn_from_outputs
function DATA.building_get_earn_from_outputs_amount(building_id, index)
    assert(index ~= 0)
    return DCON.dcon_building_get_earn_from_outputs(building_id - 1, index - 1)[0].amount
end
---@param building_id building_id valid building id
---@param index number valid index
---@param value trade_good_id valid trade_good_id
function DATA.building_set_earn_from_outputs_good(building_id, index, value)
    DCON.dcon_building_get_earn_from_outputs(building_id - 1, index - 1)[0].good = value
end
---@param building_id building_id valid building id
---@param index number valid index
---@param value number valid number
function DATA.building_set_earn_from_outputs_amount(building_id, index, value)
    DCON.dcon_building_get_earn_from_outputs(building_id - 1, index - 1)[0].amount = value
end
---@param building_id building_id valid building id
---@param index number valid index
---@param value number valid number
function DATA.building_inc_earn_from_outputs_amount(building_id, index, value)
    ---@type number
    local current = DCON.dcon_building_get_earn_from_outputs(building_id - 1, index - 1)[0].amount
    DCON.dcon_building_get_earn_from_outputs(building_id - 1, index - 1)[0].amount = current + value
end
---@param building_id building_id valid building id
---@param index number valid
---@return use_case_id amount_of_inputs
function DATA.building_get_amount_of_inputs_use(building_id, index)
    assert(index ~= 0)
    return DCON.dcon_building_get_amount_of_inputs(building_id - 1, index - 1)[0].use
end
---@param building_id building_id valid building id
---@param index number valid
---@return number amount_of_inputs
function DATA.building_get_amount_of_inputs_amount(building_id, index)
    assert(index ~= 0)
    return DCON.dcon_building_get_amount_of_inputs(building_id - 1, index - 1)[0].amount
end
---@param building_id building_id valid building id
---@param index number valid index
---@param value use_case_id valid use_case_id
function DATA.building_set_amount_of_inputs_use(building_id, index, value)
    DCON.dcon_building_get_amount_of_inputs(building_id - 1, index - 1)[0].use = value
end
---@param building_id building_id valid building id
---@param index number valid index
---@param value number valid number
function DATA.building_set_amount_of_inputs_amount(building_id, index, value)
    DCON.dcon_building_get_amount_of_inputs(building_id - 1, index - 1)[0].amount = value
end
---@param building_id building_id valid building id
---@param index number valid index
---@param value number valid number
function DATA.building_inc_amount_of_inputs_amount(building_id, index, value)
    ---@type number
    local current = DCON.dcon_building_get_amount_of_inputs(building_id - 1, index - 1)[0].amount
    DCON.dcon_building_get_amount_of_inputs(building_id - 1, index - 1)[0].amount = current + value
end
---@param building_id building_id valid building id
---@param index number valid
---@return trade_good_id amount_of_outputs
function DATA.building_get_amount_of_outputs_good(building_id, index)
    assert(index ~= 0)
    return DCON.dcon_building_get_amount_of_outputs(building_id - 1, index - 1)[0].good
end
---@param building_id building_id valid building id
---@param index number valid
---@return number amount_of_outputs
function DATA.building_get_amount_of_outputs_amount(building_id, index)
    assert(index ~= 0)
    return DCON.dcon_building_get_amount_of_outputs(building_id - 1, index - 1)[0].amount
end
---@param building_id building_id valid building id
---@param index number valid index
---@param value trade_good_id valid trade_good_id
function DATA.building_set_amount_of_outputs_good(building_id, index, value)
    DCON.dcon_building_get_amount_of_outputs(building_id - 1, index - 1)[0].good = value
end
---@param building_id building_id valid building id
---@param index number valid index
---@param value number valid number
function DATA.building_set_amount_of_outputs_amount(building_id, index, value)
    DCON.dcon_building_get_amount_of_outputs(building_id - 1, index - 1)[0].amount = value
end
---@param building_id building_id valid building id
---@param index number valid index
---@param value number valid number
function DATA.building_inc_amount_of_outputs_amount(building_id, index, value)
    ---@type number
    local current = DCON.dcon_building_get_amount_of_outputs(building_id - 1, index - 1)[0].amount
    DCON.dcon_building_get_amount_of_outputs(building_id - 1, index - 1)[0].amount = current + value
end
---@param building_id building_id valid building id
---@param index trade_good_id valid
---@return number inventory
function DATA.building_get_inventory(building_id, index)
    assert(index ~= 0)
    return DCON.dcon_building_get_inventory(building_id - 1, index - 1)
end
---@param building_id building_id valid building id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.building_set_inventory(building_id, index, value)
    DCON.dcon_building_set_inventory(building_id - 1, index - 1, value)
end
---@param building_id building_id valid building id
---@param index trade_good_id valid index
---@param value number valid number
function DATA.building_inc_inventory(building_id, index, value)
    ---@type number
    local current = DCON.dcon_building_get_inventory(building_id - 1, index - 1)
    DCON.dcon_building_set_inventory(building_id - 1, index - 1, current + value)
end

local fat_building_id_metatable = {
    __index = function (t,k)
        if (k == "current_type") then return DATA.building_get_current_type(t.id) end
        if (k == "savings") then return DATA.building_get_savings(t.id) end
        if (k == "subsidy") then return DATA.building_get_subsidy(t.id) end
        if (k == "subsidy_last") then return DATA.building_get_subsidy_last(t.id) end
        if (k == "income_mean") then return DATA.building_get_income_mean(t.id) end
        if (k == "last_income") then return DATA.building_get_last_income(t.id) end
        if (k == "last_donation_to_owner") then return DATA.building_get_last_donation_to_owner(t.id) end
        if (k == "unused") then return DATA.building_get_unused(t.id) end
        if (k == "work_ratio") then return DATA.building_get_work_ratio(t.id) end
        if (k == "production_scale") then return DATA.building_get_production_scale(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "current_type") then
            DATA.building_set_current_type(t.id, v)
            return
        end
        if (k == "savings") then
            DATA.building_set_savings(t.id, v)
            return
        end
        if (k == "subsidy") then
            DATA.building_set_subsidy(t.id, v)
            return
        end
        if (k == "subsidy_last") then
            DATA.building_set_subsidy_last(t.id, v)
            return
        end
        if (k == "income_mean") then
            DATA.building_set_income_mean(t.id, v)
            return
        end
        if (k == "last_income") then
            DATA.building_set_last_income(t.id, v)
            return
        end
        if (k == "last_donation_to_owner") then
            DATA.building_set_last_donation_to_owner(t.id, v)
            return
        end
        if (k == "unused") then
            DATA.building_set_unused(t.id, v)
            return
        end
        if (k == "work_ratio") then
            DATA.building_set_work_ratio(t.id, v)
            return
        end
        if (k == "production_scale") then
            DATA.building_set_production_scale(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id building_id
---@return fat_building_id fat_id
function DATA.fatten_building(id)
    local result = {id = id}
    setmetatable(result, fat_building_id_metatable)    return result
end
----------ownership----------


---ownership: LSP types---

---Unique identificator for ownership entity
---@class (exact) ownership_id : number
---@field is_ownership nil

---@class (exact) fat_ownership_id
---@field id ownership_id Unique ownership id
---@field building building_id
---@field owner pop_id

---@class struct_ownership


ffi.cdef[[
void dcon_delete_ownership(int32_t j);
int32_t dcon_force_create_ownership(int32_t building, int32_t owner);
void dcon_ownership_set_building(int32_t, int32_t);
int32_t dcon_ownership_get_building(int32_t);
int32_t dcon_building_get_ownership_as_building(int32_t);
void dcon_ownership_set_owner(int32_t, int32_t);
int32_t dcon_ownership_get_owner(int32_t);
int32_t dcon_pop_get_range_ownership_as_owner(int32_t);
int32_t dcon_pop_get_index_ownership_as_owner(int32_t, int32_t);
bool dcon_ownership_is_valid(int32_t);
void dcon_ownership_resize(uint32_t sz);
uint32_t dcon_ownership_size();
]]

---ownership: FFI arrays---

---ownership: LUA bindings---

DATA.ownership_size = 200000
---@param building building_id
---@param owner pop_id
---@return ownership_id
function DATA.force_create_ownership(building, owner)
    ---@type ownership_id
    local i = DCON.dcon_force_create_ownership(building - 1, owner - 1) + 1
    return i --[[@as ownership_id]]
end
---@param i ownership_id
function DATA.delete_ownership(i)
    assert(DCON.dcon_ownership_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_ownership(i - 1)
end
---@param func fun(item: ownership_id)
function DATA.for_each_ownership(func)
    ---@type number
    local range = DCON.dcon_ownership_size()
    for i = 0, range - 1 do
        if DCON.dcon_ownership_is_valid(i) then func(i + 1 --[[@as ownership_id]]) end
    end
end
---@param func fun(item: ownership_id):boolean
---@return table<ownership_id, ownership_id>
function DATA.filter_ownership(func)
    ---@type table<ownership_id, ownership_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_ownership_size()
    for i = 0, range - 1 do
        if DCON.dcon_ownership_is_valid(i) and func(i + 1 --[[@as ownership_id]]) then t[i + 1 --[[@as ownership_id]]] = t[i + 1 --[[@as ownership_id]]] end
    end
    return t
end

---@param building ownership_id valid building_id
---@return building_id Data retrieved from ownership
function DATA.ownership_get_building(building)
    return DCON.dcon_ownership_get_building(building - 1) + 1
end
---@param building building_id valid building_id
---@return ownership_id ownership
function DATA.get_ownership_from_building(building)
    return DCON.dcon_building_get_ownership_as_building(building - 1) + 1
end
---@param ownership_id ownership_id valid ownership id
---@param value building_id valid building_id
function DATA.ownership_set_building(ownership_id, value)
    DCON.dcon_ownership_set_building(ownership_id - 1, value - 1)
end
---@param owner ownership_id valid pop_id
---@return pop_id Data retrieved from ownership
function DATA.ownership_get_owner(owner)
    return DCON.dcon_ownership_get_owner(owner - 1) + 1
end
---@param owner pop_id valid pop_id
---@return ownership_id[] An array of ownership
function DATA.get_ownership_from_owner(owner)
    local result = {}
    DATA.for_each_ownership_from_owner(owner, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param owner pop_id valid pop_id
---@param func fun(item: ownership_id) valid pop_id
function DATA.for_each_ownership_from_owner(owner, func)
    ---@type number
    local range = DCON.dcon_pop_get_range_ownership_as_owner(owner - 1)
    for i = 0, range - 1 do
        ---@type ownership_id
        local accessed_element = DCON.dcon_pop_get_index_ownership_as_owner(owner - 1, i) + 1
        if DCON.dcon_ownership_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param owner pop_id valid pop_id
---@param func fun(item: ownership_id):boolean
---@return ownership_id[]
function DATA.filter_array_ownership_from_owner(owner, func)
    ---@type table<ownership_id, ownership_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_ownership_as_owner(owner - 1)
    for i = 0, range - 1 do
        ---@type ownership_id
        local accessed_element = DCON.dcon_pop_get_index_ownership_as_owner(owner - 1, i) + 1
        if DCON.dcon_ownership_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param owner pop_id valid pop_id
---@param func fun(item: ownership_id):boolean
---@return table<ownership_id, ownership_id>
function DATA.filter_ownership_from_owner(owner, func)
    ---@type table<ownership_id, ownership_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_ownership_as_owner(owner - 1)
    for i = 0, range - 1 do
        ---@type ownership_id
        local accessed_element = DCON.dcon_pop_get_index_ownership_as_owner(owner - 1, i) + 1
        if DCON.dcon_ownership_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param ownership_id ownership_id valid ownership id
---@param value pop_id valid pop_id
function DATA.ownership_set_owner(ownership_id, value)
    DCON.dcon_ownership_set_owner(ownership_id - 1, value - 1)
end

local fat_ownership_id_metatable = {
    __index = function (t,k)
        if (k == "building") then return DATA.ownership_get_building(t.id) end
        if (k == "owner") then return DATA.ownership_get_owner(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "building") then
            DATA.ownership_set_building(t.id, v)
            return
        end
        if (k == "owner") then
            DATA.ownership_set_owner(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id ownership_id
---@return fat_ownership_id fat_id
function DATA.fatten_ownership(id)
    local result = {id = id}
    setmetatable(result, fat_ownership_id_metatable)    return result
end
----------employment----------


---employment: LSP types---

---Unique identificator for employment entity
---@class (exact) employment_id : number
---@field is_employment nil

---@class (exact) fat_employment_id
---@field id employment_id Unique employment id
---@field worker_income number
---@field job job_id
---@field building building_id
---@field worker pop_id

---@class struct_employment
---@field worker_income number
---@field job job_id


ffi.cdef[[
void dcon_employment_set_worker_income(int32_t, float);
float dcon_employment_get_worker_income(int32_t);
void dcon_employment_set_job(int32_t, uint32_t);
uint32_t dcon_employment_get_job(int32_t);
void dcon_delete_employment(int32_t j);
int32_t dcon_force_create_employment(int32_t building, int32_t worker);
void dcon_employment_set_building(int32_t, int32_t);
int32_t dcon_employment_get_building(int32_t);
int32_t dcon_building_get_range_employment_as_building(int32_t);
int32_t dcon_building_get_index_employment_as_building(int32_t, int32_t);
void dcon_employment_set_worker(int32_t, int32_t);
int32_t dcon_employment_get_worker(int32_t);
int32_t dcon_pop_get_employment_as_worker(int32_t);
bool dcon_employment_is_valid(int32_t);
void dcon_employment_resize(uint32_t sz);
uint32_t dcon_employment_size();
]]

---employment: FFI arrays---

---employment: LUA bindings---

DATA.employment_size = 300000
---@param building building_id
---@param worker pop_id
---@return employment_id
function DATA.force_create_employment(building, worker)
    ---@type employment_id
    local i = DCON.dcon_force_create_employment(building - 1, worker - 1) + 1
    return i --[[@as employment_id]]
end
---@param i employment_id
function DATA.delete_employment(i)
    assert(DCON.dcon_employment_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_employment(i - 1)
end
---@param func fun(item: employment_id)
function DATA.for_each_employment(func)
    ---@type number
    local range = DCON.dcon_employment_size()
    for i = 0, range - 1 do
        if DCON.dcon_employment_is_valid(i) then func(i + 1 --[[@as employment_id]]) end
    end
end
---@param func fun(item: employment_id):boolean
---@return table<employment_id, employment_id>
function DATA.filter_employment(func)
    ---@type table<employment_id, employment_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_employment_size()
    for i = 0, range - 1 do
        if DCON.dcon_employment_is_valid(i) and func(i + 1 --[[@as employment_id]]) then t[i + 1 --[[@as employment_id]]] = t[i + 1 --[[@as employment_id]]] end
    end
    return t
end

---@param employment_id employment_id valid employment id
---@return number worker_income
function DATA.employment_get_worker_income(employment_id)
    return DCON.dcon_employment_get_worker_income(employment_id - 1)
end
---@param employment_id employment_id valid employment id
---@param value number valid number
function DATA.employment_set_worker_income(employment_id, value)
    DCON.dcon_employment_set_worker_income(employment_id - 1, value)
end
---@param employment_id employment_id valid employment id
---@param value number valid number
function DATA.employment_inc_worker_income(employment_id, value)
    ---@type number
    local current = DCON.dcon_employment_get_worker_income(employment_id - 1)
    DCON.dcon_employment_set_worker_income(employment_id - 1, current + value)
end
---@param employment_id employment_id valid employment id
---@return job_id job
function DATA.employment_get_job(employment_id)
    return DCON.dcon_employment_get_job(employment_id - 1) + 1
end
---@param employment_id employment_id valid employment id
---@param value job_id valid job_id
function DATA.employment_set_job(employment_id, value)
    DCON.dcon_employment_set_job(employment_id - 1, value - 1)
end
---@param building employment_id valid building_id
---@return building_id Data retrieved from employment
function DATA.employment_get_building(building)
    return DCON.dcon_employment_get_building(building - 1) + 1
end
---@param building building_id valid building_id
---@return employment_id[] An array of employment
function DATA.get_employment_from_building(building)
    local result = {}
    DATA.for_each_employment_from_building(building, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param building building_id valid building_id
---@param func fun(item: employment_id) valid building_id
function DATA.for_each_employment_from_building(building, func)
    ---@type number
    local range = DCON.dcon_building_get_range_employment_as_building(building - 1)
    for i = 0, range - 1 do
        ---@type employment_id
        local accessed_element = DCON.dcon_building_get_index_employment_as_building(building - 1, i) + 1
        if DCON.dcon_employment_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param building building_id valid building_id
---@param func fun(item: employment_id):boolean
---@return employment_id[]
function DATA.filter_array_employment_from_building(building, func)
    ---@type table<employment_id, employment_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_building_get_range_employment_as_building(building - 1)
    for i = 0, range - 1 do
        ---@type employment_id
        local accessed_element = DCON.dcon_building_get_index_employment_as_building(building - 1, i) + 1
        if DCON.dcon_employment_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param building building_id valid building_id
---@param func fun(item: employment_id):boolean
---@return table<employment_id, employment_id>
function DATA.filter_employment_from_building(building, func)
    ---@type table<employment_id, employment_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_building_get_range_employment_as_building(building - 1)
    for i = 0, range - 1 do
        ---@type employment_id
        local accessed_element = DCON.dcon_building_get_index_employment_as_building(building - 1, i) + 1
        if DCON.dcon_employment_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param employment_id employment_id valid employment id
---@param value building_id valid building_id
function DATA.employment_set_building(employment_id, value)
    DCON.dcon_employment_set_building(employment_id - 1, value - 1)
end
---@param worker employment_id valid pop_id
---@return pop_id Data retrieved from employment
function DATA.employment_get_worker(worker)
    return DCON.dcon_employment_get_worker(worker - 1) + 1
end
---@param worker pop_id valid pop_id
---@return employment_id employment
function DATA.get_employment_from_worker(worker)
    return DCON.dcon_pop_get_employment_as_worker(worker - 1) + 1
end
---@param employment_id employment_id valid employment id
---@param value pop_id valid pop_id
function DATA.employment_set_worker(employment_id, value)
    DCON.dcon_employment_set_worker(employment_id - 1, value - 1)
end

local fat_employment_id_metatable = {
    __index = function (t,k)
        if (k == "worker_income") then return DATA.employment_get_worker_income(t.id) end
        if (k == "job") then return DATA.employment_get_job(t.id) end
        if (k == "building") then return DATA.employment_get_building(t.id) end
        if (k == "worker") then return DATA.employment_get_worker(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "worker_income") then
            DATA.employment_set_worker_income(t.id, v)
            return
        end
        if (k == "job") then
            DATA.employment_set_job(t.id, v)
            return
        end
        if (k == "building") then
            DATA.employment_set_building(t.id, v)
            return
        end
        if (k == "worker") then
            DATA.employment_set_worker(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id employment_id
---@return fat_employment_id fat_id
function DATA.fatten_employment(id)
    local result = {id = id}
    setmetatable(result, fat_employment_id_metatable)    return result
end
----------building_location----------


---building_location: LSP types---

---Unique identificator for building_location entity
---@class (exact) building_location_id : number
---@field is_building_location nil

---@class (exact) fat_building_location_id
---@field id building_location_id Unique building_location id
---@field location province_id location of the building
---@field building building_id

---@class struct_building_location


ffi.cdef[[
void dcon_delete_building_location(int32_t j);
int32_t dcon_force_create_building_location(int32_t location, int32_t building);
void dcon_building_location_set_location(int32_t, int32_t);
int32_t dcon_building_location_get_location(int32_t);
int32_t dcon_province_get_range_building_location_as_location(int32_t);
int32_t dcon_province_get_index_building_location_as_location(int32_t, int32_t);
void dcon_building_location_set_building(int32_t, int32_t);
int32_t dcon_building_location_get_building(int32_t);
int32_t dcon_building_get_building_location_as_building(int32_t);
bool dcon_building_location_is_valid(int32_t);
void dcon_building_location_resize(uint32_t sz);
uint32_t dcon_building_location_size();
]]

---building_location: FFI arrays---

---building_location: LUA bindings---

DATA.building_location_size = 200000
---@param location province_id
---@param building building_id
---@return building_location_id
function DATA.force_create_building_location(location, building)
    ---@type building_location_id
    local i = DCON.dcon_force_create_building_location(location - 1, building - 1) + 1
    return i --[[@as building_location_id]]
end
---@param i building_location_id
function DATA.delete_building_location(i)
    assert(DCON.dcon_building_location_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_building_location(i - 1)
end
---@param func fun(item: building_location_id)
function DATA.for_each_building_location(func)
    ---@type number
    local range = DCON.dcon_building_location_size()
    for i = 0, range - 1 do
        if DCON.dcon_building_location_is_valid(i) then func(i + 1 --[[@as building_location_id]]) end
    end
end
---@param func fun(item: building_location_id):boolean
---@return table<building_location_id, building_location_id>
function DATA.filter_building_location(func)
    ---@type table<building_location_id, building_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_building_location_size()
    for i = 0, range - 1 do
        if DCON.dcon_building_location_is_valid(i) and func(i + 1 --[[@as building_location_id]]) then t[i + 1 --[[@as building_location_id]]] = t[i + 1 --[[@as building_location_id]]] end
    end
    return t
end

---@param location building_location_id valid province_id
---@return province_id Data retrieved from building_location
function DATA.building_location_get_location(location)
    return DCON.dcon_building_location_get_location(location - 1) + 1
end
---@param location province_id valid province_id
---@return building_location_id[] An array of building_location
function DATA.get_building_location_from_location(location)
    local result = {}
    DATA.for_each_building_location_from_location(location, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param location province_id valid province_id
---@param func fun(item: building_location_id) valid province_id
function DATA.for_each_building_location_from_location(location, func)
    ---@type number
    local range = DCON.dcon_province_get_range_building_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type building_location_id
        local accessed_element = DCON.dcon_province_get_index_building_location_as_location(location - 1, i) + 1
        if DCON.dcon_building_location_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param location province_id valid province_id
---@param func fun(item: building_location_id):boolean
---@return building_location_id[]
function DATA.filter_array_building_location_from_location(location, func)
    ---@type table<building_location_id, building_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_building_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type building_location_id
        local accessed_element = DCON.dcon_province_get_index_building_location_as_location(location - 1, i) + 1
        if DCON.dcon_building_location_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param location province_id valid province_id
---@param func fun(item: building_location_id):boolean
---@return table<building_location_id, building_location_id>
function DATA.filter_building_location_from_location(location, func)
    ---@type table<building_location_id, building_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_building_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type building_location_id
        local accessed_element = DCON.dcon_province_get_index_building_location_as_location(location - 1, i) + 1
        if DCON.dcon_building_location_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param building_location_id building_location_id valid building_location id
---@param value province_id valid province_id
function DATA.building_location_set_location(building_location_id, value)
    DCON.dcon_building_location_set_location(building_location_id - 1, value - 1)
end
---@param building building_location_id valid building_id
---@return building_id Data retrieved from building_location
function DATA.building_location_get_building(building)
    return DCON.dcon_building_location_get_building(building - 1) + 1
end
---@param building building_id valid building_id
---@return building_location_id building_location
function DATA.get_building_location_from_building(building)
    return DCON.dcon_building_get_building_location_as_building(building - 1) + 1
end
---@param building_location_id building_location_id valid building_location id
---@param value building_id valid building_id
function DATA.building_location_set_building(building_location_id, value)
    DCON.dcon_building_location_set_building(building_location_id - 1, value - 1)
end

local fat_building_location_id_metatable = {
    __index = function (t,k)
        if (k == "location") then return DATA.building_location_get_location(t.id) end
        if (k == "building") then return DATA.building_location_get_building(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "location") then
            DATA.building_location_set_location(t.id, v)
            return
        end
        if (k == "building") then
            DATA.building_location_set_building(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id building_location_id
---@return fat_building_location_id fat_id
function DATA.fatten_building_location(id)
    local result = {id = id}
    setmetatable(result, fat_building_location_id_metatable)    return result
end
----------army_membership----------


---army_membership: LSP types---

---Unique identificator for army_membership entity
---@class (exact) army_membership_id : number
---@field is_army_membership nil

---@class (exact) fat_army_membership_id
---@field id army_membership_id Unique army_membership id
---@field army army_id
---@field member warband_id part of army

---@class struct_army_membership


ffi.cdef[[
void dcon_delete_army_membership(int32_t j);
int32_t dcon_force_create_army_membership(int32_t army, int32_t member);
void dcon_army_membership_set_army(int32_t, int32_t);
int32_t dcon_army_membership_get_army(int32_t);
int32_t dcon_army_get_range_army_membership_as_army(int32_t);
int32_t dcon_army_get_index_army_membership_as_army(int32_t, int32_t);
void dcon_army_membership_set_member(int32_t, int32_t);
int32_t dcon_army_membership_get_member(int32_t);
int32_t dcon_warband_get_army_membership_as_member(int32_t);
bool dcon_army_membership_is_valid(int32_t);
void dcon_army_membership_resize(uint32_t sz);
uint32_t dcon_army_membership_size();
]]

---army_membership: FFI arrays---

---army_membership: LUA bindings---

DATA.army_membership_size = 50000
---@param army army_id
---@param member warband_id
---@return army_membership_id
function DATA.force_create_army_membership(army, member)
    ---@type army_membership_id
    local i = DCON.dcon_force_create_army_membership(army - 1, member - 1) + 1
    return i --[[@as army_membership_id]]
end
---@param i army_membership_id
function DATA.delete_army_membership(i)
    assert(DCON.dcon_army_membership_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_army_membership(i - 1)
end
---@param func fun(item: army_membership_id)
function DATA.for_each_army_membership(func)
    ---@type number
    local range = DCON.dcon_army_membership_size()
    for i = 0, range - 1 do
        if DCON.dcon_army_membership_is_valid(i) then func(i + 1 --[[@as army_membership_id]]) end
    end
end
---@param func fun(item: army_membership_id):boolean
---@return table<army_membership_id, army_membership_id>
function DATA.filter_army_membership(func)
    ---@type table<army_membership_id, army_membership_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_army_membership_size()
    for i = 0, range - 1 do
        if DCON.dcon_army_membership_is_valid(i) and func(i + 1 --[[@as army_membership_id]]) then t[i + 1 --[[@as army_membership_id]]] = t[i + 1 --[[@as army_membership_id]]] end
    end
    return t
end

---@param army army_membership_id valid army_id
---@return army_id Data retrieved from army_membership
function DATA.army_membership_get_army(army)
    return DCON.dcon_army_membership_get_army(army - 1) + 1
end
---@param army army_id valid army_id
---@return army_membership_id[] An array of army_membership
function DATA.get_army_membership_from_army(army)
    local result = {}
    DATA.for_each_army_membership_from_army(army, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param army army_id valid army_id
---@param func fun(item: army_membership_id) valid army_id
function DATA.for_each_army_membership_from_army(army, func)
    ---@type number
    local range = DCON.dcon_army_get_range_army_membership_as_army(army - 1)
    for i = 0, range - 1 do
        ---@type army_membership_id
        local accessed_element = DCON.dcon_army_get_index_army_membership_as_army(army - 1, i) + 1
        if DCON.dcon_army_membership_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param army army_id valid army_id
---@param func fun(item: army_membership_id):boolean
---@return army_membership_id[]
function DATA.filter_array_army_membership_from_army(army, func)
    ---@type table<army_membership_id, army_membership_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_army_get_range_army_membership_as_army(army - 1)
    for i = 0, range - 1 do
        ---@type army_membership_id
        local accessed_element = DCON.dcon_army_get_index_army_membership_as_army(army - 1, i) + 1
        if DCON.dcon_army_membership_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param army army_id valid army_id
---@param func fun(item: army_membership_id):boolean
---@return table<army_membership_id, army_membership_id>
function DATA.filter_army_membership_from_army(army, func)
    ---@type table<army_membership_id, army_membership_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_army_get_range_army_membership_as_army(army - 1)
    for i = 0, range - 1 do
        ---@type army_membership_id
        local accessed_element = DCON.dcon_army_get_index_army_membership_as_army(army - 1, i) + 1
        if DCON.dcon_army_membership_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param army_membership_id army_membership_id valid army_membership id
---@param value army_id valid army_id
function DATA.army_membership_set_army(army_membership_id, value)
    DCON.dcon_army_membership_set_army(army_membership_id - 1, value - 1)
end
---@param member army_membership_id valid warband_id
---@return warband_id Data retrieved from army_membership
function DATA.army_membership_get_member(member)
    return DCON.dcon_army_membership_get_member(member - 1) + 1
end
---@param member warband_id valid warband_id
---@return army_membership_id army_membership
function DATA.get_army_membership_from_member(member)
    return DCON.dcon_warband_get_army_membership_as_member(member - 1) + 1
end
---@param army_membership_id army_membership_id valid army_membership id
---@param value warband_id valid warband_id
function DATA.army_membership_set_member(army_membership_id, value)
    DCON.dcon_army_membership_set_member(army_membership_id - 1, value - 1)
end

local fat_army_membership_id_metatable = {
    __index = function (t,k)
        if (k == "army") then return DATA.army_membership_get_army(t.id) end
        if (k == "member") then return DATA.army_membership_get_member(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "army") then
            DATA.army_membership_set_army(t.id, v)
            return
        end
        if (k == "member") then
            DATA.army_membership_set_member(t.id, v)
            return
        end
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
---@class (exact) warband_leader_id : number
---@field is_warband_leader nil

---@class (exact) fat_warband_leader_id
---@field id warband_leader_id Unique warband_leader id
---@field leader pop_id
---@field warband warband_id

---@class struct_warband_leader


ffi.cdef[[
void dcon_delete_warband_leader(int32_t j);
int32_t dcon_force_create_warband_leader(int32_t leader, int32_t warband);
void dcon_warband_leader_set_leader(int32_t, int32_t);
int32_t dcon_warband_leader_get_leader(int32_t);
int32_t dcon_pop_get_warband_leader_as_leader(int32_t);
void dcon_warband_leader_set_warband(int32_t, int32_t);
int32_t dcon_warband_leader_get_warband(int32_t);
int32_t dcon_warband_get_warband_leader_as_warband(int32_t);
bool dcon_warband_leader_is_valid(int32_t);
void dcon_warband_leader_resize(uint32_t sz);
uint32_t dcon_warband_leader_size();
]]

---warband_leader: FFI arrays---

---warband_leader: LUA bindings---

DATA.warband_leader_size = 50000
---@param leader pop_id
---@param warband warband_id
---@return warband_leader_id
function DATA.force_create_warband_leader(leader, warband)
    ---@type warband_leader_id
    local i = DCON.dcon_force_create_warband_leader(leader - 1, warband - 1) + 1
    return i --[[@as warband_leader_id]]
end
---@param i warband_leader_id
function DATA.delete_warband_leader(i)
    assert(DCON.dcon_warband_leader_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_warband_leader(i - 1)
end
---@param func fun(item: warband_leader_id)
function DATA.for_each_warband_leader(func)
    ---@type number
    local range = DCON.dcon_warband_leader_size()
    for i = 0, range - 1 do
        if DCON.dcon_warband_leader_is_valid(i) then func(i + 1 --[[@as warband_leader_id]]) end
    end
end
---@param func fun(item: warband_leader_id):boolean
---@return table<warband_leader_id, warband_leader_id>
function DATA.filter_warband_leader(func)
    ---@type table<warband_leader_id, warband_leader_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_warband_leader_size()
    for i = 0, range - 1 do
        if DCON.dcon_warband_leader_is_valid(i) and func(i + 1 --[[@as warband_leader_id]]) then t[i + 1 --[[@as warband_leader_id]]] = t[i + 1 --[[@as warband_leader_id]]] end
    end
    return t
end

---@param leader warband_leader_id valid pop_id
---@return pop_id Data retrieved from warband_leader
function DATA.warband_leader_get_leader(leader)
    return DCON.dcon_warband_leader_get_leader(leader - 1) + 1
end
---@param leader pop_id valid pop_id
---@return warband_leader_id warband_leader
function DATA.get_warband_leader_from_leader(leader)
    return DCON.dcon_pop_get_warband_leader_as_leader(leader - 1) + 1
end
---@param warband_leader_id warband_leader_id valid warband_leader id
---@param value pop_id valid pop_id
function DATA.warband_leader_set_leader(warband_leader_id, value)
    DCON.dcon_warband_leader_set_leader(warband_leader_id - 1, value - 1)
end
---@param warband warband_leader_id valid warband_id
---@return warband_id Data retrieved from warband_leader
function DATA.warband_leader_get_warband(warband)
    return DCON.dcon_warband_leader_get_warband(warband - 1) + 1
end
---@param warband warband_id valid warband_id
---@return warband_leader_id warband_leader
function DATA.get_warband_leader_from_warband(warband)
    return DCON.dcon_warband_get_warband_leader_as_warband(warband - 1) + 1
end
---@param warband_leader_id warband_leader_id valid warband_leader id
---@param value warband_id valid warband_id
function DATA.warband_leader_set_warband(warband_leader_id, value)
    DCON.dcon_warband_leader_set_warband(warband_leader_id - 1, value - 1)
end

local fat_warband_leader_id_metatable = {
    __index = function (t,k)
        if (k == "leader") then return DATA.warband_leader_get_leader(t.id) end
        if (k == "warband") then return DATA.warband_leader_get_warband(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "leader") then
            DATA.warband_leader_set_leader(t.id, v)
            return
        end
        if (k == "warband") then
            DATA.warband_leader_set_warband(t.id, v)
            return
        end
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
---@class (exact) warband_recruiter_id : number
---@field is_warband_recruiter nil

---@class (exact) fat_warband_recruiter_id
---@field id warband_recruiter_id Unique warband_recruiter id
---@field recruiter pop_id
---@field warband warband_id

---@class struct_warband_recruiter


ffi.cdef[[
void dcon_delete_warband_recruiter(int32_t j);
int32_t dcon_force_create_warband_recruiter(int32_t recruiter, int32_t warband);
void dcon_warband_recruiter_set_recruiter(int32_t, int32_t);
int32_t dcon_warband_recruiter_get_recruiter(int32_t);
int32_t dcon_pop_get_warband_recruiter_as_recruiter(int32_t);
void dcon_warband_recruiter_set_warband(int32_t, int32_t);
int32_t dcon_warband_recruiter_get_warband(int32_t);
int32_t dcon_warband_get_warband_recruiter_as_warband(int32_t);
bool dcon_warband_recruiter_is_valid(int32_t);
void dcon_warband_recruiter_resize(uint32_t sz);
uint32_t dcon_warband_recruiter_size();
]]

---warband_recruiter: FFI arrays---

---warband_recruiter: LUA bindings---

DATA.warband_recruiter_size = 50000
---@param recruiter pop_id
---@param warband warband_id
---@return warband_recruiter_id
function DATA.force_create_warband_recruiter(recruiter, warband)
    ---@type warband_recruiter_id
    local i = DCON.dcon_force_create_warband_recruiter(recruiter - 1, warband - 1) + 1
    return i --[[@as warband_recruiter_id]]
end
---@param i warband_recruiter_id
function DATA.delete_warband_recruiter(i)
    assert(DCON.dcon_warband_recruiter_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_warband_recruiter(i - 1)
end
---@param func fun(item: warband_recruiter_id)
function DATA.for_each_warband_recruiter(func)
    ---@type number
    local range = DCON.dcon_warband_recruiter_size()
    for i = 0, range - 1 do
        if DCON.dcon_warband_recruiter_is_valid(i) then func(i + 1 --[[@as warband_recruiter_id]]) end
    end
end
---@param func fun(item: warband_recruiter_id):boolean
---@return table<warband_recruiter_id, warband_recruiter_id>
function DATA.filter_warband_recruiter(func)
    ---@type table<warband_recruiter_id, warband_recruiter_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_warband_recruiter_size()
    for i = 0, range - 1 do
        if DCON.dcon_warband_recruiter_is_valid(i) and func(i + 1 --[[@as warband_recruiter_id]]) then t[i + 1 --[[@as warband_recruiter_id]]] = t[i + 1 --[[@as warband_recruiter_id]]] end
    end
    return t
end

---@param recruiter warband_recruiter_id valid pop_id
---@return pop_id Data retrieved from warband_recruiter
function DATA.warband_recruiter_get_recruiter(recruiter)
    return DCON.dcon_warband_recruiter_get_recruiter(recruiter - 1) + 1
end
---@param recruiter pop_id valid pop_id
---@return warband_recruiter_id warband_recruiter
function DATA.get_warband_recruiter_from_recruiter(recruiter)
    return DCON.dcon_pop_get_warband_recruiter_as_recruiter(recruiter - 1) + 1
end
---@param warband_recruiter_id warband_recruiter_id valid warband_recruiter id
---@param value pop_id valid pop_id
function DATA.warband_recruiter_set_recruiter(warband_recruiter_id, value)
    DCON.dcon_warband_recruiter_set_recruiter(warband_recruiter_id - 1, value - 1)
end
---@param warband warband_recruiter_id valid warband_id
---@return warband_id Data retrieved from warband_recruiter
function DATA.warband_recruiter_get_warband(warband)
    return DCON.dcon_warband_recruiter_get_warband(warband - 1) + 1
end
---@param warband warband_id valid warband_id
---@return warband_recruiter_id warband_recruiter
function DATA.get_warband_recruiter_from_warband(warband)
    return DCON.dcon_warband_get_warband_recruiter_as_warband(warband - 1) + 1
end
---@param warband_recruiter_id warband_recruiter_id valid warband_recruiter id
---@param value warband_id valid warband_id
function DATA.warband_recruiter_set_warband(warband_recruiter_id, value)
    DCON.dcon_warband_recruiter_set_warband(warband_recruiter_id - 1, value - 1)
end

local fat_warband_recruiter_id_metatable = {
    __index = function (t,k)
        if (k == "recruiter") then return DATA.warband_recruiter_get_recruiter(t.id) end
        if (k == "warband") then return DATA.warband_recruiter_get_warband(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "recruiter") then
            DATA.warband_recruiter_set_recruiter(t.id, v)
            return
        end
        if (k == "warband") then
            DATA.warband_recruiter_set_warband(t.id, v)
            return
        end
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
---@class (exact) warband_commander_id : number
---@field is_warband_commander nil

---@class (exact) fat_warband_commander_id
---@field id warband_commander_id Unique warband_commander id
---@field commander pop_id
---@field warband warband_id

---@class struct_warband_commander


ffi.cdef[[
void dcon_delete_warband_commander(int32_t j);
int32_t dcon_force_create_warband_commander(int32_t commander, int32_t warband);
void dcon_warband_commander_set_commander(int32_t, int32_t);
int32_t dcon_warband_commander_get_commander(int32_t);
int32_t dcon_pop_get_warband_commander_as_commander(int32_t);
void dcon_warband_commander_set_warband(int32_t, int32_t);
int32_t dcon_warband_commander_get_warband(int32_t);
int32_t dcon_warband_get_warband_commander_as_warband(int32_t);
bool dcon_warband_commander_is_valid(int32_t);
void dcon_warband_commander_resize(uint32_t sz);
uint32_t dcon_warband_commander_size();
]]

---warband_commander: FFI arrays---

---warband_commander: LUA bindings---

DATA.warband_commander_size = 50000
---@param commander pop_id
---@param warband warband_id
---@return warband_commander_id
function DATA.force_create_warband_commander(commander, warband)
    ---@type warband_commander_id
    local i = DCON.dcon_force_create_warband_commander(commander - 1, warband - 1) + 1
    return i --[[@as warband_commander_id]]
end
---@param i warband_commander_id
function DATA.delete_warband_commander(i)
    assert(DCON.dcon_warband_commander_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_warband_commander(i - 1)
end
---@param func fun(item: warband_commander_id)
function DATA.for_each_warband_commander(func)
    ---@type number
    local range = DCON.dcon_warband_commander_size()
    for i = 0, range - 1 do
        if DCON.dcon_warband_commander_is_valid(i) then func(i + 1 --[[@as warband_commander_id]]) end
    end
end
---@param func fun(item: warband_commander_id):boolean
---@return table<warband_commander_id, warband_commander_id>
function DATA.filter_warband_commander(func)
    ---@type table<warband_commander_id, warband_commander_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_warband_commander_size()
    for i = 0, range - 1 do
        if DCON.dcon_warband_commander_is_valid(i) and func(i + 1 --[[@as warband_commander_id]]) then t[i + 1 --[[@as warband_commander_id]]] = t[i + 1 --[[@as warband_commander_id]]] end
    end
    return t
end

---@param commander warband_commander_id valid pop_id
---@return pop_id Data retrieved from warband_commander
function DATA.warband_commander_get_commander(commander)
    return DCON.dcon_warband_commander_get_commander(commander - 1) + 1
end
---@param commander pop_id valid pop_id
---@return warband_commander_id warband_commander
function DATA.get_warband_commander_from_commander(commander)
    return DCON.dcon_pop_get_warband_commander_as_commander(commander - 1) + 1
end
---@param warband_commander_id warband_commander_id valid warband_commander id
---@param value pop_id valid pop_id
function DATA.warband_commander_set_commander(warband_commander_id, value)
    DCON.dcon_warband_commander_set_commander(warband_commander_id - 1, value - 1)
end
---@param warband warband_commander_id valid warband_id
---@return warband_id Data retrieved from warband_commander
function DATA.warband_commander_get_warband(warband)
    return DCON.dcon_warband_commander_get_warband(warband - 1) + 1
end
---@param warband warband_id valid warband_id
---@return warband_commander_id warband_commander
function DATA.get_warband_commander_from_warband(warband)
    return DCON.dcon_warband_get_warband_commander_as_warband(warband - 1) + 1
end
---@param warband_commander_id warband_commander_id valid warband_commander id
---@param value warband_id valid warband_id
function DATA.warband_commander_set_warband(warband_commander_id, value)
    DCON.dcon_warband_commander_set_warband(warband_commander_id - 1, value - 1)
end

local fat_warband_commander_id_metatable = {
    __index = function (t,k)
        if (k == "commander") then return DATA.warband_commander_get_commander(t.id) end
        if (k == "warband") then return DATA.warband_commander_get_warband(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "commander") then
            DATA.warband_commander_set_commander(t.id, v)
            return
        end
        if (k == "warband") then
            DATA.warband_commander_set_warband(t.id, v)
            return
        end
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
---@class (exact) warband_location_id : number
---@field is_warband_location nil

---@class (exact) fat_warband_location_id
---@field id warband_location_id Unique warband_location id
---@field location province_id location of warband
---@field warband warband_id

---@class struct_warband_location


ffi.cdef[[
void dcon_delete_warband_location(int32_t j);
int32_t dcon_force_create_warband_location(int32_t location, int32_t warband);
void dcon_warband_location_set_location(int32_t, int32_t);
int32_t dcon_warband_location_get_location(int32_t);
int32_t dcon_province_get_range_warband_location_as_location(int32_t);
int32_t dcon_province_get_index_warband_location_as_location(int32_t, int32_t);
void dcon_warband_location_set_warband(int32_t, int32_t);
int32_t dcon_warband_location_get_warband(int32_t);
int32_t dcon_warband_get_warband_location_as_warband(int32_t);
bool dcon_warband_location_is_valid(int32_t);
void dcon_warband_location_resize(uint32_t sz);
uint32_t dcon_warband_location_size();
]]

---warband_location: FFI arrays---

---warband_location: LUA bindings---

DATA.warband_location_size = 50000
---@param location province_id
---@param warband warband_id
---@return warband_location_id
function DATA.force_create_warband_location(location, warband)
    ---@type warband_location_id
    local i = DCON.dcon_force_create_warband_location(location - 1, warband - 1) + 1
    return i --[[@as warband_location_id]]
end
---@param i warband_location_id
function DATA.delete_warband_location(i)
    assert(DCON.dcon_warband_location_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_warband_location(i - 1)
end
---@param func fun(item: warband_location_id)
function DATA.for_each_warband_location(func)
    ---@type number
    local range = DCON.dcon_warband_location_size()
    for i = 0, range - 1 do
        if DCON.dcon_warband_location_is_valid(i) then func(i + 1 --[[@as warband_location_id]]) end
    end
end
---@param func fun(item: warband_location_id):boolean
---@return table<warband_location_id, warband_location_id>
function DATA.filter_warband_location(func)
    ---@type table<warband_location_id, warband_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_warband_location_size()
    for i = 0, range - 1 do
        if DCON.dcon_warband_location_is_valid(i) and func(i + 1 --[[@as warband_location_id]]) then t[i + 1 --[[@as warband_location_id]]] = t[i + 1 --[[@as warband_location_id]]] end
    end
    return t
end

---@param location warband_location_id valid province_id
---@return province_id Data retrieved from warband_location
function DATA.warband_location_get_location(location)
    return DCON.dcon_warband_location_get_location(location - 1) + 1
end
---@param location province_id valid province_id
---@return warband_location_id[] An array of warband_location
function DATA.get_warband_location_from_location(location)
    local result = {}
    DATA.for_each_warband_location_from_location(location, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param location province_id valid province_id
---@param func fun(item: warband_location_id) valid province_id
function DATA.for_each_warband_location_from_location(location, func)
    ---@type number
    local range = DCON.dcon_province_get_range_warband_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type warband_location_id
        local accessed_element = DCON.dcon_province_get_index_warband_location_as_location(location - 1, i) + 1
        if DCON.dcon_warband_location_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param location province_id valid province_id
---@param func fun(item: warband_location_id):boolean
---@return warband_location_id[]
function DATA.filter_array_warband_location_from_location(location, func)
    ---@type table<warband_location_id, warband_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_warband_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type warband_location_id
        local accessed_element = DCON.dcon_province_get_index_warband_location_as_location(location - 1, i) + 1
        if DCON.dcon_warband_location_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param location province_id valid province_id
---@param func fun(item: warband_location_id):boolean
---@return table<warband_location_id, warband_location_id>
function DATA.filter_warband_location_from_location(location, func)
    ---@type table<warband_location_id, warband_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_warband_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type warband_location_id
        local accessed_element = DCON.dcon_province_get_index_warband_location_as_location(location - 1, i) + 1
        if DCON.dcon_warband_location_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param warband_location_id warband_location_id valid warband_location id
---@param value province_id valid province_id
function DATA.warband_location_set_location(warband_location_id, value)
    DCON.dcon_warband_location_set_location(warband_location_id - 1, value - 1)
end
---@param warband warband_location_id valid warband_id
---@return warband_id Data retrieved from warband_location
function DATA.warband_location_get_warband(warband)
    return DCON.dcon_warband_location_get_warband(warband - 1) + 1
end
---@param warband warband_id valid warband_id
---@return warband_location_id warband_location
function DATA.get_warband_location_from_warband(warband)
    return DCON.dcon_warband_get_warband_location_as_warband(warband - 1) + 1
end
---@param warband_location_id warband_location_id valid warband_location id
---@param value warband_id valid warband_id
function DATA.warband_location_set_warband(warband_location_id, value)
    DCON.dcon_warband_location_set_warband(warband_location_id - 1, value - 1)
end

local fat_warband_location_id_metatable = {
    __index = function (t,k)
        if (k == "location") then return DATA.warband_location_get_location(t.id) end
        if (k == "warband") then return DATA.warband_location_get_warband(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "location") then
            DATA.warband_location_set_location(t.id, v)
            return
        end
        if (k == "warband") then
            DATA.warband_location_set_warband(t.id, v)
            return
        end
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
---@class (exact) warband_unit_id : number
---@field is_warband_unit nil

---@class (exact) fat_warband_unit_id
---@field id warband_unit_id Unique warband_unit id
---@field type unit_type_id Current unit type
---@field unit pop_id
---@field warband warband_id

---@class struct_warband_unit
---@field type unit_type_id Current unit type


ffi.cdef[[
void dcon_warband_unit_set_type(int32_t, uint32_t);
uint32_t dcon_warband_unit_get_type(int32_t);
void dcon_delete_warband_unit(int32_t j);
int32_t dcon_force_create_warband_unit(int32_t unit, int32_t warband);
void dcon_warband_unit_set_unit(int32_t, int32_t);
int32_t dcon_warband_unit_get_unit(int32_t);
int32_t dcon_pop_get_warband_unit_as_unit(int32_t);
void dcon_warband_unit_set_warband(int32_t, int32_t);
int32_t dcon_warband_unit_get_warband(int32_t);
int32_t dcon_warband_get_range_warband_unit_as_warband(int32_t);
int32_t dcon_warband_get_index_warband_unit_as_warband(int32_t, int32_t);
bool dcon_warband_unit_is_valid(int32_t);
void dcon_warband_unit_resize(uint32_t sz);
uint32_t dcon_warband_unit_size();
]]

---warband_unit: FFI arrays---

---warband_unit: LUA bindings---

DATA.warband_unit_size = 50000
---@param unit pop_id
---@param warband warband_id
---@return warband_unit_id
function DATA.force_create_warband_unit(unit, warband)
    ---@type warband_unit_id
    local i = DCON.dcon_force_create_warband_unit(unit - 1, warband - 1) + 1
    return i --[[@as warband_unit_id]]
end
---@param i warband_unit_id
function DATA.delete_warband_unit(i)
    assert(DCON.dcon_warband_unit_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_warband_unit(i - 1)
end
---@param func fun(item: warband_unit_id)
function DATA.for_each_warband_unit(func)
    ---@type number
    local range = DCON.dcon_warband_unit_size()
    for i = 0, range - 1 do
        if DCON.dcon_warband_unit_is_valid(i) then func(i + 1 --[[@as warband_unit_id]]) end
    end
end
---@param func fun(item: warband_unit_id):boolean
---@return table<warband_unit_id, warband_unit_id>
function DATA.filter_warband_unit(func)
    ---@type table<warband_unit_id, warband_unit_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_warband_unit_size()
    for i = 0, range - 1 do
        if DCON.dcon_warband_unit_is_valid(i) and func(i + 1 --[[@as warband_unit_id]]) then t[i + 1 --[[@as warband_unit_id]]] = t[i + 1 --[[@as warband_unit_id]]] end
    end
    return t
end

---@param warband_unit_id warband_unit_id valid warband_unit id
---@return unit_type_id type Current unit type
function DATA.warband_unit_get_type(warband_unit_id)
    return DCON.dcon_warband_unit_get_type(warband_unit_id - 1) + 1
end
---@param warband_unit_id warband_unit_id valid warband_unit id
---@param value unit_type_id valid unit_type_id
function DATA.warband_unit_set_type(warband_unit_id, value)
    DCON.dcon_warband_unit_set_type(warband_unit_id - 1, value - 1)
end
---@param unit warband_unit_id valid pop_id
---@return pop_id Data retrieved from warband_unit
function DATA.warband_unit_get_unit(unit)
    return DCON.dcon_warband_unit_get_unit(unit - 1) + 1
end
---@param unit pop_id valid pop_id
---@return warband_unit_id warband_unit
function DATA.get_warband_unit_from_unit(unit)
    return DCON.dcon_pop_get_warband_unit_as_unit(unit - 1) + 1
end
---@param warband_unit_id warband_unit_id valid warband_unit id
---@param value pop_id valid pop_id
function DATA.warband_unit_set_unit(warband_unit_id, value)
    DCON.dcon_warband_unit_set_unit(warband_unit_id - 1, value - 1)
end
---@param warband warband_unit_id valid warband_id
---@return warband_id Data retrieved from warband_unit
function DATA.warband_unit_get_warband(warband)
    return DCON.dcon_warband_unit_get_warband(warband - 1) + 1
end
---@param warband warband_id valid warband_id
---@return warband_unit_id[] An array of warband_unit
function DATA.get_warband_unit_from_warband(warband)
    local result = {}
    DATA.for_each_warband_unit_from_warband(warband, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param warband warband_id valid warband_id
---@param func fun(item: warband_unit_id) valid warband_id
function DATA.for_each_warband_unit_from_warband(warband, func)
    ---@type number
    local range = DCON.dcon_warband_get_range_warband_unit_as_warband(warband - 1)
    for i = 0, range - 1 do
        ---@type warband_unit_id
        local accessed_element = DCON.dcon_warband_get_index_warband_unit_as_warband(warband - 1, i) + 1
        if DCON.dcon_warband_unit_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param warband warband_id valid warband_id
---@param func fun(item: warband_unit_id):boolean
---@return warband_unit_id[]
function DATA.filter_array_warband_unit_from_warband(warband, func)
    ---@type table<warband_unit_id, warband_unit_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_warband_get_range_warband_unit_as_warband(warband - 1)
    for i = 0, range - 1 do
        ---@type warband_unit_id
        local accessed_element = DCON.dcon_warband_get_index_warband_unit_as_warband(warband - 1, i) + 1
        if DCON.dcon_warband_unit_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param warband warband_id valid warband_id
---@param func fun(item: warband_unit_id):boolean
---@return table<warband_unit_id, warband_unit_id>
function DATA.filter_warband_unit_from_warband(warband, func)
    ---@type table<warband_unit_id, warband_unit_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_warband_get_range_warband_unit_as_warband(warband - 1)
    for i = 0, range - 1 do
        ---@type warband_unit_id
        local accessed_element = DCON.dcon_warband_get_index_warband_unit_as_warband(warband - 1, i) + 1
        if DCON.dcon_warband_unit_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param warband_unit_id warband_unit_id valid warband_unit id
---@param value warband_id valid warband_id
function DATA.warband_unit_set_warband(warband_unit_id, value)
    DCON.dcon_warband_unit_set_warband(warband_unit_id - 1, value - 1)
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
        if (k == "unit") then
            DATA.warband_unit_set_unit(t.id, v)
            return
        end
        if (k == "warband") then
            DATA.warband_unit_set_warband(t.id, v)
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
---@class (exact) character_location_id : number
---@field is_character_location nil

---@class (exact) fat_character_location_id
---@field id character_location_id Unique character_location id
---@field location province_id location of character
---@field character pop_id

---@class struct_character_location


ffi.cdef[[
void dcon_delete_character_location(int32_t j);
int32_t dcon_force_create_character_location(int32_t location, int32_t character);
void dcon_character_location_set_location(int32_t, int32_t);
int32_t dcon_character_location_get_location(int32_t);
int32_t dcon_province_get_range_character_location_as_location(int32_t);
int32_t dcon_province_get_index_character_location_as_location(int32_t, int32_t);
void dcon_character_location_set_character(int32_t, int32_t);
int32_t dcon_character_location_get_character(int32_t);
int32_t dcon_pop_get_character_location_as_character(int32_t);
bool dcon_character_location_is_valid(int32_t);
void dcon_character_location_resize(uint32_t sz);
uint32_t dcon_character_location_size();
]]

---character_location: FFI arrays---

---character_location: LUA bindings---

DATA.character_location_size = 100000
---@param location province_id
---@param character pop_id
---@return character_location_id
function DATA.force_create_character_location(location, character)
    ---@type character_location_id
    local i = DCON.dcon_force_create_character_location(location - 1, character - 1) + 1
    return i --[[@as character_location_id]]
end
---@param i character_location_id
function DATA.delete_character_location(i)
    assert(DCON.dcon_character_location_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_character_location(i - 1)
end
---@param func fun(item: character_location_id)
function DATA.for_each_character_location(func)
    ---@type number
    local range = DCON.dcon_character_location_size()
    for i = 0, range - 1 do
        if DCON.dcon_character_location_is_valid(i) then func(i + 1 --[[@as character_location_id]]) end
    end
end
---@param func fun(item: character_location_id):boolean
---@return table<character_location_id, character_location_id>
function DATA.filter_character_location(func)
    ---@type table<character_location_id, character_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_character_location_size()
    for i = 0, range - 1 do
        if DCON.dcon_character_location_is_valid(i) and func(i + 1 --[[@as character_location_id]]) then t[i + 1 --[[@as character_location_id]]] = t[i + 1 --[[@as character_location_id]]] end
    end
    return t
end

---@param location character_location_id valid province_id
---@return province_id Data retrieved from character_location
function DATA.character_location_get_location(location)
    return DCON.dcon_character_location_get_location(location - 1) + 1
end
---@param location province_id valid province_id
---@return character_location_id[] An array of character_location
function DATA.get_character_location_from_location(location)
    local result = {}
    DATA.for_each_character_location_from_location(location, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param location province_id valid province_id
---@param func fun(item: character_location_id) valid province_id
function DATA.for_each_character_location_from_location(location, func)
    ---@type number
    local range = DCON.dcon_province_get_range_character_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type character_location_id
        local accessed_element = DCON.dcon_province_get_index_character_location_as_location(location - 1, i) + 1
        if DCON.dcon_character_location_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param location province_id valid province_id
---@param func fun(item: character_location_id):boolean
---@return character_location_id[]
function DATA.filter_array_character_location_from_location(location, func)
    ---@type table<character_location_id, character_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_character_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type character_location_id
        local accessed_element = DCON.dcon_province_get_index_character_location_as_location(location - 1, i) + 1
        if DCON.dcon_character_location_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param location province_id valid province_id
---@param func fun(item: character_location_id):boolean
---@return table<character_location_id, character_location_id>
function DATA.filter_character_location_from_location(location, func)
    ---@type table<character_location_id, character_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_character_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type character_location_id
        local accessed_element = DCON.dcon_province_get_index_character_location_as_location(location - 1, i) + 1
        if DCON.dcon_character_location_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param character_location_id character_location_id valid character_location id
---@param value province_id valid province_id
function DATA.character_location_set_location(character_location_id, value)
    DCON.dcon_character_location_set_location(character_location_id - 1, value - 1)
end
---@param character character_location_id valid pop_id
---@return pop_id Data retrieved from character_location
function DATA.character_location_get_character(character)
    return DCON.dcon_character_location_get_character(character - 1) + 1
end
---@param character pop_id valid pop_id
---@return character_location_id character_location
function DATA.get_character_location_from_character(character)
    return DCON.dcon_pop_get_character_location_as_character(character - 1) + 1
end
---@param character_location_id character_location_id valid character_location id
---@param value pop_id valid pop_id
function DATA.character_location_set_character(character_location_id, value)
    DCON.dcon_character_location_set_character(character_location_id - 1, value - 1)
end

local fat_character_location_id_metatable = {
    __index = function (t,k)
        if (k == "location") then return DATA.character_location_get_location(t.id) end
        if (k == "character") then return DATA.character_location_get_character(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "location") then
            DATA.character_location_set_location(t.id, v)
            return
        end
        if (k == "character") then
            DATA.character_location_set_character(t.id, v)
            return
        end
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
---@class (exact) home_id : number
---@field is_home nil

---@class (exact) fat_home_id
---@field id home_id Unique home id
---@field home province_id home of pop
---@field pop pop_id characters and pops which think of this province as their home

---@class struct_home


ffi.cdef[[
void dcon_delete_home(int32_t j);
int32_t dcon_force_create_home(int32_t home, int32_t pop);
void dcon_home_set_home(int32_t, int32_t);
int32_t dcon_home_get_home(int32_t);
int32_t dcon_province_get_range_home_as_home(int32_t);
int32_t dcon_province_get_index_home_as_home(int32_t, int32_t);
void dcon_home_set_pop(int32_t, int32_t);
int32_t dcon_home_get_pop(int32_t);
int32_t dcon_pop_get_home_as_pop(int32_t);
bool dcon_home_is_valid(int32_t);
void dcon_home_resize(uint32_t sz);
uint32_t dcon_home_size();
]]

---home: FFI arrays---

---home: LUA bindings---

DATA.home_size = 300000
---@param home province_id
---@param pop pop_id
---@return home_id
function DATA.force_create_home(home, pop)
    ---@type home_id
    local i = DCON.dcon_force_create_home(home - 1, pop - 1) + 1
    return i --[[@as home_id]]
end
---@param i home_id
function DATA.delete_home(i)
    assert(DCON.dcon_home_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_home(i - 1)
end
---@param func fun(item: home_id)
function DATA.for_each_home(func)
    ---@type number
    local range = DCON.dcon_home_size()
    for i = 0, range - 1 do
        if DCON.dcon_home_is_valid(i) then func(i + 1 --[[@as home_id]]) end
    end
end
---@param func fun(item: home_id):boolean
---@return table<home_id, home_id>
function DATA.filter_home(func)
    ---@type table<home_id, home_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_home_size()
    for i = 0, range - 1 do
        if DCON.dcon_home_is_valid(i) and func(i + 1 --[[@as home_id]]) then t[i + 1 --[[@as home_id]]] = t[i + 1 --[[@as home_id]]] end
    end
    return t
end

---@param home home_id valid province_id
---@return province_id Data retrieved from home
function DATA.home_get_home(home)
    return DCON.dcon_home_get_home(home - 1) + 1
end
---@param home province_id valid province_id
---@return home_id[] An array of home
function DATA.get_home_from_home(home)
    local result = {}
    DATA.for_each_home_from_home(home, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param home province_id valid province_id
---@param func fun(item: home_id) valid province_id
function DATA.for_each_home_from_home(home, func)
    ---@type number
    local range = DCON.dcon_province_get_range_home_as_home(home - 1)
    for i = 0, range - 1 do
        ---@type home_id
        local accessed_element = DCON.dcon_province_get_index_home_as_home(home - 1, i) + 1
        if DCON.dcon_home_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param home province_id valid province_id
---@param func fun(item: home_id):boolean
---@return home_id[]
function DATA.filter_array_home_from_home(home, func)
    ---@type table<home_id, home_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_home_as_home(home - 1)
    for i = 0, range - 1 do
        ---@type home_id
        local accessed_element = DCON.dcon_province_get_index_home_as_home(home - 1, i) + 1
        if DCON.dcon_home_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param home province_id valid province_id
---@param func fun(item: home_id):boolean
---@return table<home_id, home_id>
function DATA.filter_home_from_home(home, func)
    ---@type table<home_id, home_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_home_as_home(home - 1)
    for i = 0, range - 1 do
        ---@type home_id
        local accessed_element = DCON.dcon_province_get_index_home_as_home(home - 1, i) + 1
        if DCON.dcon_home_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param home_id home_id valid home id
---@param value province_id valid province_id
function DATA.home_set_home(home_id, value)
    DCON.dcon_home_set_home(home_id - 1, value - 1)
end
---@param pop home_id valid pop_id
---@return pop_id Data retrieved from home
function DATA.home_get_pop(pop)
    return DCON.dcon_home_get_pop(pop - 1) + 1
end
---@param pop pop_id valid pop_id
---@return home_id home
function DATA.get_home_from_pop(pop)
    return DCON.dcon_pop_get_home_as_pop(pop - 1) + 1
end
---@param home_id home_id valid home id
---@param value pop_id valid pop_id
function DATA.home_set_pop(home_id, value)
    DCON.dcon_home_set_pop(home_id - 1, value - 1)
end

local fat_home_id_metatable = {
    __index = function (t,k)
        if (k == "home") then return DATA.home_get_home(t.id) end
        if (k == "pop") then return DATA.home_get_pop(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "home") then
            DATA.home_set_home(t.id, v)
            return
        end
        if (k == "pop") then
            DATA.home_set_pop(t.id, v)
            return
        end
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
---@class (exact) pop_location_id : number
---@field is_pop_location nil

---@class (exact) fat_pop_location_id
---@field id pop_location_id Unique pop_location id
---@field location province_id location of pop
---@field pop pop_id

---@class struct_pop_location


ffi.cdef[[
void dcon_delete_pop_location(int32_t j);
int32_t dcon_force_create_pop_location(int32_t location, int32_t pop);
void dcon_pop_location_set_location(int32_t, int32_t);
int32_t dcon_pop_location_get_location(int32_t);
int32_t dcon_province_get_range_pop_location_as_location(int32_t);
int32_t dcon_province_get_index_pop_location_as_location(int32_t, int32_t);
void dcon_pop_location_set_pop(int32_t, int32_t);
int32_t dcon_pop_location_get_pop(int32_t);
int32_t dcon_pop_get_pop_location_as_pop(int32_t);
bool dcon_pop_location_is_valid(int32_t);
void dcon_pop_location_resize(uint32_t sz);
uint32_t dcon_pop_location_size();
]]

---pop_location: FFI arrays---

---pop_location: LUA bindings---

DATA.pop_location_size = 300000
---@param location province_id
---@param pop pop_id
---@return pop_location_id
function DATA.force_create_pop_location(location, pop)
    ---@type pop_location_id
    local i = DCON.dcon_force_create_pop_location(location - 1, pop - 1) + 1
    return i --[[@as pop_location_id]]
end
---@param i pop_location_id
function DATA.delete_pop_location(i)
    assert(DCON.dcon_pop_location_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_pop_location(i - 1)
end
---@param func fun(item: pop_location_id)
function DATA.for_each_pop_location(func)
    ---@type number
    local range = DCON.dcon_pop_location_size()
    for i = 0, range - 1 do
        if DCON.dcon_pop_location_is_valid(i) then func(i + 1 --[[@as pop_location_id]]) end
    end
end
---@param func fun(item: pop_location_id):boolean
---@return table<pop_location_id, pop_location_id>
function DATA.filter_pop_location(func)
    ---@type table<pop_location_id, pop_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_location_size()
    for i = 0, range - 1 do
        if DCON.dcon_pop_location_is_valid(i) and func(i + 1 --[[@as pop_location_id]]) then t[i + 1 --[[@as pop_location_id]]] = t[i + 1 --[[@as pop_location_id]]] end
    end
    return t
end

---@param location pop_location_id valid province_id
---@return province_id Data retrieved from pop_location
function DATA.pop_location_get_location(location)
    return DCON.dcon_pop_location_get_location(location - 1) + 1
end
---@param location province_id valid province_id
---@return pop_location_id[] An array of pop_location
function DATA.get_pop_location_from_location(location)
    local result = {}
    DATA.for_each_pop_location_from_location(location, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param location province_id valid province_id
---@param func fun(item: pop_location_id) valid province_id
function DATA.for_each_pop_location_from_location(location, func)
    ---@type number
    local range = DCON.dcon_province_get_range_pop_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type pop_location_id
        local accessed_element = DCON.dcon_province_get_index_pop_location_as_location(location - 1, i) + 1
        if DCON.dcon_pop_location_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param location province_id valid province_id
---@param func fun(item: pop_location_id):boolean
---@return pop_location_id[]
function DATA.filter_array_pop_location_from_location(location, func)
    ---@type table<pop_location_id, pop_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_pop_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type pop_location_id
        local accessed_element = DCON.dcon_province_get_index_pop_location_as_location(location - 1, i) + 1
        if DCON.dcon_pop_location_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param location province_id valid province_id
---@param func fun(item: pop_location_id):boolean
---@return table<pop_location_id, pop_location_id>
function DATA.filter_pop_location_from_location(location, func)
    ---@type table<pop_location_id, pop_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_pop_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type pop_location_id
        local accessed_element = DCON.dcon_province_get_index_pop_location_as_location(location - 1, i) + 1
        if DCON.dcon_pop_location_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param pop_location_id pop_location_id valid pop_location id
---@param value province_id valid province_id
function DATA.pop_location_set_location(pop_location_id, value)
    DCON.dcon_pop_location_set_location(pop_location_id - 1, value - 1)
end
---@param pop pop_location_id valid pop_id
---@return pop_id Data retrieved from pop_location
function DATA.pop_location_get_pop(pop)
    return DCON.dcon_pop_location_get_pop(pop - 1) + 1
end
---@param pop pop_id valid pop_id
---@return pop_location_id pop_location
function DATA.get_pop_location_from_pop(pop)
    return DCON.dcon_pop_get_pop_location_as_pop(pop - 1) + 1
end
---@param pop_location_id pop_location_id valid pop_location id
---@param value pop_id valid pop_id
function DATA.pop_location_set_pop(pop_location_id, value)
    DCON.dcon_pop_location_set_pop(pop_location_id - 1, value - 1)
end

local fat_pop_location_id_metatable = {
    __index = function (t,k)
        if (k == "location") then return DATA.pop_location_get_location(t.id) end
        if (k == "pop") then return DATA.pop_location_get_pop(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "location") then
            DATA.pop_location_set_location(t.id, v)
            return
        end
        if (k == "pop") then
            DATA.pop_location_set_pop(t.id, v)
            return
        end
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
---@class (exact) outlaw_location_id : number
---@field is_outlaw_location nil

---@class (exact) fat_outlaw_location_id
---@field id outlaw_location_id Unique outlaw_location id
---@field location province_id location of the outlaw
---@field outlaw pop_id

---@class struct_outlaw_location


ffi.cdef[[
void dcon_delete_outlaw_location(int32_t j);
int32_t dcon_force_create_outlaw_location(int32_t location, int32_t outlaw);
void dcon_outlaw_location_set_location(int32_t, int32_t);
int32_t dcon_outlaw_location_get_location(int32_t);
int32_t dcon_province_get_range_outlaw_location_as_location(int32_t);
int32_t dcon_province_get_index_outlaw_location_as_location(int32_t, int32_t);
void dcon_outlaw_location_set_outlaw(int32_t, int32_t);
int32_t dcon_outlaw_location_get_outlaw(int32_t);
int32_t dcon_pop_get_outlaw_location_as_outlaw(int32_t);
bool dcon_outlaw_location_is_valid(int32_t);
void dcon_outlaw_location_resize(uint32_t sz);
uint32_t dcon_outlaw_location_size();
]]

---outlaw_location: FFI arrays---

---outlaw_location: LUA bindings---

DATA.outlaw_location_size = 300000
---@param location province_id
---@param outlaw pop_id
---@return outlaw_location_id
function DATA.force_create_outlaw_location(location, outlaw)
    ---@type outlaw_location_id
    local i = DCON.dcon_force_create_outlaw_location(location - 1, outlaw - 1) + 1
    return i --[[@as outlaw_location_id]]
end
---@param i outlaw_location_id
function DATA.delete_outlaw_location(i)
    assert(DCON.dcon_outlaw_location_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_outlaw_location(i - 1)
end
---@param func fun(item: outlaw_location_id)
function DATA.for_each_outlaw_location(func)
    ---@type number
    local range = DCON.dcon_outlaw_location_size()
    for i = 0, range - 1 do
        if DCON.dcon_outlaw_location_is_valid(i) then func(i + 1 --[[@as outlaw_location_id]]) end
    end
end
---@param func fun(item: outlaw_location_id):boolean
---@return table<outlaw_location_id, outlaw_location_id>
function DATA.filter_outlaw_location(func)
    ---@type table<outlaw_location_id, outlaw_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_outlaw_location_size()
    for i = 0, range - 1 do
        if DCON.dcon_outlaw_location_is_valid(i) and func(i + 1 --[[@as outlaw_location_id]]) then t[i + 1 --[[@as outlaw_location_id]]] = t[i + 1 --[[@as outlaw_location_id]]] end
    end
    return t
end

---@param location outlaw_location_id valid province_id
---@return province_id Data retrieved from outlaw_location
function DATA.outlaw_location_get_location(location)
    return DCON.dcon_outlaw_location_get_location(location - 1) + 1
end
---@param location province_id valid province_id
---@return outlaw_location_id[] An array of outlaw_location
function DATA.get_outlaw_location_from_location(location)
    local result = {}
    DATA.for_each_outlaw_location_from_location(location, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param location province_id valid province_id
---@param func fun(item: outlaw_location_id) valid province_id
function DATA.for_each_outlaw_location_from_location(location, func)
    ---@type number
    local range = DCON.dcon_province_get_range_outlaw_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type outlaw_location_id
        local accessed_element = DCON.dcon_province_get_index_outlaw_location_as_location(location - 1, i) + 1
        if DCON.dcon_outlaw_location_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param location province_id valid province_id
---@param func fun(item: outlaw_location_id):boolean
---@return outlaw_location_id[]
function DATA.filter_array_outlaw_location_from_location(location, func)
    ---@type table<outlaw_location_id, outlaw_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_outlaw_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type outlaw_location_id
        local accessed_element = DCON.dcon_province_get_index_outlaw_location_as_location(location - 1, i) + 1
        if DCON.dcon_outlaw_location_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param location province_id valid province_id
---@param func fun(item: outlaw_location_id):boolean
---@return table<outlaw_location_id, outlaw_location_id>
function DATA.filter_outlaw_location_from_location(location, func)
    ---@type table<outlaw_location_id, outlaw_location_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_outlaw_location_as_location(location - 1)
    for i = 0, range - 1 do
        ---@type outlaw_location_id
        local accessed_element = DCON.dcon_province_get_index_outlaw_location_as_location(location - 1, i) + 1
        if DCON.dcon_outlaw_location_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param outlaw_location_id outlaw_location_id valid outlaw_location id
---@param value province_id valid province_id
function DATA.outlaw_location_set_location(outlaw_location_id, value)
    DCON.dcon_outlaw_location_set_location(outlaw_location_id - 1, value - 1)
end
---@param outlaw outlaw_location_id valid pop_id
---@return pop_id Data retrieved from outlaw_location
function DATA.outlaw_location_get_outlaw(outlaw)
    return DCON.dcon_outlaw_location_get_outlaw(outlaw - 1) + 1
end
---@param outlaw pop_id valid pop_id
---@return outlaw_location_id outlaw_location
function DATA.get_outlaw_location_from_outlaw(outlaw)
    return DCON.dcon_pop_get_outlaw_location_as_outlaw(outlaw - 1) + 1
end
---@param outlaw_location_id outlaw_location_id valid outlaw_location id
---@param value pop_id valid pop_id
function DATA.outlaw_location_set_outlaw(outlaw_location_id, value)
    DCON.dcon_outlaw_location_set_outlaw(outlaw_location_id - 1, value - 1)
end

local fat_outlaw_location_id_metatable = {
    __index = function (t,k)
        if (k == "location") then return DATA.outlaw_location_get_location(t.id) end
        if (k == "outlaw") then return DATA.outlaw_location_get_outlaw(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "location") then
            DATA.outlaw_location_set_location(t.id, v)
            return
        end
        if (k == "outlaw") then
            DATA.outlaw_location_set_outlaw(t.id, v)
            return
        end
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
---@class (exact) tile_province_membership_id : number
---@field is_tile_province_membership nil

---@class (exact) fat_tile_province_membership_id
---@field id tile_province_membership_id Unique tile_province_membership id
---@field province province_id
---@field tile tile_id

---@class struct_tile_province_membership


ffi.cdef[[
void dcon_delete_tile_province_membership(int32_t j);
int32_t dcon_force_create_tile_province_membership(int32_t province, int32_t tile);
void dcon_tile_province_membership_set_province(int32_t, int32_t);
int32_t dcon_tile_province_membership_get_province(int32_t);
int32_t dcon_province_get_range_tile_province_membership_as_province(int32_t);
int32_t dcon_province_get_index_tile_province_membership_as_province(int32_t, int32_t);
void dcon_tile_province_membership_set_tile(int32_t, int32_t);
int32_t dcon_tile_province_membership_get_tile(int32_t);
int32_t dcon_tile_get_tile_province_membership_as_tile(int32_t);
bool dcon_tile_province_membership_is_valid(int32_t);
void dcon_tile_province_membership_resize(uint32_t sz);
uint32_t dcon_tile_province_membership_size();
]]

---tile_province_membership: FFI arrays---

---tile_province_membership: LUA bindings---

DATA.tile_province_membership_size = 1500000
---@param province province_id
---@param tile tile_id
---@return tile_province_membership_id
function DATA.force_create_tile_province_membership(province, tile)
    ---@type tile_province_membership_id
    local i = DCON.dcon_force_create_tile_province_membership(province - 1, tile - 1) + 1
    return i --[[@as tile_province_membership_id]]
end
---@param i tile_province_membership_id
function DATA.delete_tile_province_membership(i)
    assert(DCON.dcon_tile_province_membership_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_tile_province_membership(i - 1)
end
---@param func fun(item: tile_province_membership_id)
function DATA.for_each_tile_province_membership(func)
    ---@type number
    local range = DCON.dcon_tile_province_membership_size()
    for i = 0, range - 1 do
        if DCON.dcon_tile_province_membership_is_valid(i) then func(i + 1 --[[@as tile_province_membership_id]]) end
    end
end
---@param func fun(item: tile_province_membership_id):boolean
---@return table<tile_province_membership_id, tile_province_membership_id>
function DATA.filter_tile_province_membership(func)
    ---@type table<tile_province_membership_id, tile_province_membership_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_tile_province_membership_size()
    for i = 0, range - 1 do
        if DCON.dcon_tile_province_membership_is_valid(i) and func(i + 1 --[[@as tile_province_membership_id]]) then t[i + 1 --[[@as tile_province_membership_id]]] = t[i + 1 --[[@as tile_province_membership_id]]] end
    end
    return t
end

---@param province tile_province_membership_id valid province_id
---@return province_id Data retrieved from tile_province_membership
function DATA.tile_province_membership_get_province(province)
    return DCON.dcon_tile_province_membership_get_province(province - 1) + 1
end
---@param province province_id valid province_id
---@return tile_province_membership_id[] An array of tile_province_membership
function DATA.get_tile_province_membership_from_province(province)
    local result = {}
    DATA.for_each_tile_province_membership_from_province(province, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param province province_id valid province_id
---@param func fun(item: tile_province_membership_id) valid province_id
function DATA.for_each_tile_province_membership_from_province(province, func)
    ---@type number
    local range = DCON.dcon_province_get_range_tile_province_membership_as_province(province - 1)
    for i = 0, range - 1 do
        ---@type tile_province_membership_id
        local accessed_element = DCON.dcon_province_get_index_tile_province_membership_as_province(province - 1, i) + 1
        if DCON.dcon_tile_province_membership_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param province province_id valid province_id
---@param func fun(item: tile_province_membership_id):boolean
---@return tile_province_membership_id[]
function DATA.filter_array_tile_province_membership_from_province(province, func)
    ---@type table<tile_province_membership_id, tile_province_membership_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_tile_province_membership_as_province(province - 1)
    for i = 0, range - 1 do
        ---@type tile_province_membership_id
        local accessed_element = DCON.dcon_province_get_index_tile_province_membership_as_province(province - 1, i) + 1
        if DCON.dcon_tile_province_membership_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param province province_id valid province_id
---@param func fun(item: tile_province_membership_id):boolean
---@return table<tile_province_membership_id, tile_province_membership_id>
function DATA.filter_tile_province_membership_from_province(province, func)
    ---@type table<tile_province_membership_id, tile_province_membership_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_tile_province_membership_as_province(province - 1)
    for i = 0, range - 1 do
        ---@type tile_province_membership_id
        local accessed_element = DCON.dcon_province_get_index_tile_province_membership_as_province(province - 1, i) + 1
        if DCON.dcon_tile_province_membership_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param tile_province_membership_id tile_province_membership_id valid tile_province_membership id
---@param value province_id valid province_id
function DATA.tile_province_membership_set_province(tile_province_membership_id, value)
    DCON.dcon_tile_province_membership_set_province(tile_province_membership_id - 1, value - 1)
end
---@param tile tile_province_membership_id valid tile_id
---@return tile_id Data retrieved from tile_province_membership
function DATA.tile_province_membership_get_tile(tile)
    return DCON.dcon_tile_province_membership_get_tile(tile - 1) + 1
end
---@param tile tile_id valid tile_id
---@return tile_province_membership_id tile_province_membership
function DATA.get_tile_province_membership_from_tile(tile)
    return DCON.dcon_tile_get_tile_province_membership_as_tile(tile - 1) + 1
end
---@param tile_province_membership_id tile_province_membership_id valid tile_province_membership id
---@param value tile_id valid tile_id
function DATA.tile_province_membership_set_tile(tile_province_membership_id, value)
    DCON.dcon_tile_province_membership_set_tile(tile_province_membership_id - 1, value - 1)
end

local fat_tile_province_membership_id_metatable = {
    __index = function (t,k)
        if (k == "province") then return DATA.tile_province_membership_get_province(t.id) end
        if (k == "tile") then return DATA.tile_province_membership_get_tile(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "province") then
            DATA.tile_province_membership_set_province(t.id, v)
            return
        end
        if (k == "tile") then
            DATA.tile_province_membership_set_tile(t.id, v)
            return
        end
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
---@class (exact) province_neighborhood_id : number
---@field is_province_neighborhood nil

---@class (exact) fat_province_neighborhood_id
---@field id province_neighborhood_id Unique province_neighborhood id
---@field origin province_id
---@field target province_id

---@class struct_province_neighborhood


ffi.cdef[[
void dcon_delete_province_neighborhood(int32_t j);
int32_t dcon_force_create_province_neighborhood(int32_t origin, int32_t target);
void dcon_province_neighborhood_set_origin(int32_t, int32_t);
int32_t dcon_province_neighborhood_get_origin(int32_t);
int32_t dcon_province_get_range_province_neighborhood_as_origin(int32_t);
int32_t dcon_province_get_index_province_neighborhood_as_origin(int32_t, int32_t);
void dcon_province_neighborhood_set_target(int32_t, int32_t);
int32_t dcon_province_neighborhood_get_target(int32_t);
int32_t dcon_province_get_range_province_neighborhood_as_target(int32_t);
int32_t dcon_province_get_index_province_neighborhood_as_target(int32_t, int32_t);
bool dcon_province_neighborhood_is_valid(int32_t);
void dcon_province_neighborhood_resize(uint32_t sz);
uint32_t dcon_province_neighborhood_size();
]]

---province_neighborhood: FFI arrays---

---province_neighborhood: LUA bindings---

DATA.province_neighborhood_size = 250000
---@param origin province_id
---@param target province_id
---@return province_neighborhood_id
function DATA.force_create_province_neighborhood(origin, target)
    ---@type province_neighborhood_id
    local i = DCON.dcon_force_create_province_neighborhood(origin - 1, target - 1) + 1
    return i --[[@as province_neighborhood_id]]
end
---@param i province_neighborhood_id
function DATA.delete_province_neighborhood(i)
    assert(DCON.dcon_province_neighborhood_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_province_neighborhood(i - 1)
end
---@param func fun(item: province_neighborhood_id)
function DATA.for_each_province_neighborhood(func)
    ---@type number
    local range = DCON.dcon_province_neighborhood_size()
    for i = 0, range - 1 do
        if DCON.dcon_province_neighborhood_is_valid(i) then func(i + 1 --[[@as province_neighborhood_id]]) end
    end
end
---@param func fun(item: province_neighborhood_id):boolean
---@return table<province_neighborhood_id, province_neighborhood_id>
function DATA.filter_province_neighborhood(func)
    ---@type table<province_neighborhood_id, province_neighborhood_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_neighborhood_size()
    for i = 0, range - 1 do
        if DCON.dcon_province_neighborhood_is_valid(i) and func(i + 1 --[[@as province_neighborhood_id]]) then t[i + 1 --[[@as province_neighborhood_id]]] = t[i + 1 --[[@as province_neighborhood_id]]] end
    end
    return t
end

---@param origin province_neighborhood_id valid province_id
---@return province_id Data retrieved from province_neighborhood
function DATA.province_neighborhood_get_origin(origin)
    return DCON.dcon_province_neighborhood_get_origin(origin - 1) + 1
end
---@param origin province_id valid province_id
---@return province_neighborhood_id[] An array of province_neighborhood
function DATA.get_province_neighborhood_from_origin(origin)
    local result = {}
    DATA.for_each_province_neighborhood_from_origin(origin, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param origin province_id valid province_id
---@param func fun(item: province_neighborhood_id) valid province_id
function DATA.for_each_province_neighborhood_from_origin(origin, func)
    ---@type number
    local range = DCON.dcon_province_get_range_province_neighborhood_as_origin(origin - 1)
    for i = 0, range - 1 do
        ---@type province_neighborhood_id
        local accessed_element = DCON.dcon_province_get_index_province_neighborhood_as_origin(origin - 1, i) + 1
        if DCON.dcon_province_neighborhood_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param origin province_id valid province_id
---@param func fun(item: province_neighborhood_id):boolean
---@return province_neighborhood_id[]
function DATA.filter_array_province_neighborhood_from_origin(origin, func)
    ---@type table<province_neighborhood_id, province_neighborhood_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_province_neighborhood_as_origin(origin - 1)
    for i = 0, range - 1 do
        ---@type province_neighborhood_id
        local accessed_element = DCON.dcon_province_get_index_province_neighborhood_as_origin(origin - 1, i) + 1
        if DCON.dcon_province_neighborhood_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param origin province_id valid province_id
---@param func fun(item: province_neighborhood_id):boolean
---@return table<province_neighborhood_id, province_neighborhood_id>
function DATA.filter_province_neighborhood_from_origin(origin, func)
    ---@type table<province_neighborhood_id, province_neighborhood_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_province_neighborhood_as_origin(origin - 1)
    for i = 0, range - 1 do
        ---@type province_neighborhood_id
        local accessed_element = DCON.dcon_province_get_index_province_neighborhood_as_origin(origin - 1, i) + 1
        if DCON.dcon_province_neighborhood_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param province_neighborhood_id province_neighborhood_id valid province_neighborhood id
---@param value province_id valid province_id
function DATA.province_neighborhood_set_origin(province_neighborhood_id, value)
    DCON.dcon_province_neighborhood_set_origin(province_neighborhood_id - 1, value - 1)
end
---@param target province_neighborhood_id valid province_id
---@return province_id Data retrieved from province_neighborhood
function DATA.province_neighborhood_get_target(target)
    return DCON.dcon_province_neighborhood_get_target(target - 1) + 1
end
---@param target province_id valid province_id
---@return province_neighborhood_id[] An array of province_neighborhood
function DATA.get_province_neighborhood_from_target(target)
    local result = {}
    DATA.for_each_province_neighborhood_from_target(target, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param target province_id valid province_id
---@param func fun(item: province_neighborhood_id) valid province_id
function DATA.for_each_province_neighborhood_from_target(target, func)
    ---@type number
    local range = DCON.dcon_province_get_range_province_neighborhood_as_target(target - 1)
    for i = 0, range - 1 do
        ---@type province_neighborhood_id
        local accessed_element = DCON.dcon_province_get_index_province_neighborhood_as_target(target - 1, i) + 1
        if DCON.dcon_province_neighborhood_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param target province_id valid province_id
---@param func fun(item: province_neighborhood_id):boolean
---@return province_neighborhood_id[]
function DATA.filter_array_province_neighborhood_from_target(target, func)
    ---@type table<province_neighborhood_id, province_neighborhood_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_province_neighborhood_as_target(target - 1)
    for i = 0, range - 1 do
        ---@type province_neighborhood_id
        local accessed_element = DCON.dcon_province_get_index_province_neighborhood_as_target(target - 1, i) + 1
        if DCON.dcon_province_neighborhood_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param target province_id valid province_id
---@param func fun(item: province_neighborhood_id):boolean
---@return table<province_neighborhood_id, province_neighborhood_id>
function DATA.filter_province_neighborhood_from_target(target, func)
    ---@type table<province_neighborhood_id, province_neighborhood_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_province_get_range_province_neighborhood_as_target(target - 1)
    for i = 0, range - 1 do
        ---@type province_neighborhood_id
        local accessed_element = DCON.dcon_province_get_index_province_neighborhood_as_target(target - 1, i) + 1
        if DCON.dcon_province_neighborhood_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param province_neighborhood_id province_neighborhood_id valid province_neighborhood id
---@param value province_id valid province_id
function DATA.province_neighborhood_set_target(province_neighborhood_id, value)
    DCON.dcon_province_neighborhood_set_target(province_neighborhood_id - 1, value - 1)
end

local fat_province_neighborhood_id_metatable = {
    __index = function (t,k)
        if (k == "origin") then return DATA.province_neighborhood_get_origin(t.id) end
        if (k == "target") then return DATA.province_neighborhood_get_target(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "origin") then
            DATA.province_neighborhood_set_origin(t.id, v)
            return
        end
        if (k == "target") then
            DATA.province_neighborhood_set_target(t.id, v)
            return
        end
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
---@class (exact) parent_child_relation_id : number
---@field is_parent_child_relation nil

---@class (exact) fat_parent_child_relation_id
---@field id parent_child_relation_id Unique parent_child_relation id
---@field parent pop_id
---@field child pop_id

---@class struct_parent_child_relation


ffi.cdef[[
void dcon_delete_parent_child_relation(int32_t j);
int32_t dcon_force_create_parent_child_relation(int32_t parent, int32_t child);
void dcon_parent_child_relation_set_parent(int32_t, int32_t);
int32_t dcon_parent_child_relation_get_parent(int32_t);
int32_t dcon_pop_get_range_parent_child_relation_as_parent(int32_t);
int32_t dcon_pop_get_index_parent_child_relation_as_parent(int32_t, int32_t);
void dcon_parent_child_relation_set_child(int32_t, int32_t);
int32_t dcon_parent_child_relation_get_child(int32_t);
int32_t dcon_pop_get_parent_child_relation_as_child(int32_t);
bool dcon_parent_child_relation_is_valid(int32_t);
void dcon_parent_child_relation_resize(uint32_t sz);
uint32_t dcon_parent_child_relation_size();
]]

---parent_child_relation: FFI arrays---

---parent_child_relation: LUA bindings---

DATA.parent_child_relation_size = 900000
---@param parent pop_id
---@param child pop_id
---@return parent_child_relation_id
function DATA.force_create_parent_child_relation(parent, child)
    ---@type parent_child_relation_id
    local i = DCON.dcon_force_create_parent_child_relation(parent - 1, child - 1) + 1
    return i --[[@as parent_child_relation_id]]
end
---@param i parent_child_relation_id
function DATA.delete_parent_child_relation(i)
    assert(DCON.dcon_parent_child_relation_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_parent_child_relation(i - 1)
end
---@param func fun(item: parent_child_relation_id)
function DATA.for_each_parent_child_relation(func)
    ---@type number
    local range = DCON.dcon_parent_child_relation_size()
    for i = 0, range - 1 do
        if DCON.dcon_parent_child_relation_is_valid(i) then func(i + 1 --[[@as parent_child_relation_id]]) end
    end
end
---@param func fun(item: parent_child_relation_id):boolean
---@return table<parent_child_relation_id, parent_child_relation_id>
function DATA.filter_parent_child_relation(func)
    ---@type table<parent_child_relation_id, parent_child_relation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_parent_child_relation_size()
    for i = 0, range - 1 do
        if DCON.dcon_parent_child_relation_is_valid(i) and func(i + 1 --[[@as parent_child_relation_id]]) then t[i + 1 --[[@as parent_child_relation_id]]] = t[i + 1 --[[@as parent_child_relation_id]]] end
    end
    return t
end

---@param parent parent_child_relation_id valid pop_id
---@return pop_id Data retrieved from parent_child_relation
function DATA.parent_child_relation_get_parent(parent)
    return DCON.dcon_parent_child_relation_get_parent(parent - 1) + 1
end
---@param parent pop_id valid pop_id
---@return parent_child_relation_id[] An array of parent_child_relation
function DATA.get_parent_child_relation_from_parent(parent)
    local result = {}
    DATA.for_each_parent_child_relation_from_parent(parent, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param parent pop_id valid pop_id
---@param func fun(item: parent_child_relation_id) valid pop_id
function DATA.for_each_parent_child_relation_from_parent(parent, func)
    ---@type number
    local range = DCON.dcon_pop_get_range_parent_child_relation_as_parent(parent - 1)
    for i = 0, range - 1 do
        ---@type parent_child_relation_id
        local accessed_element = DCON.dcon_pop_get_index_parent_child_relation_as_parent(parent - 1, i) + 1
        if DCON.dcon_parent_child_relation_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param parent pop_id valid pop_id
---@param func fun(item: parent_child_relation_id):boolean
---@return parent_child_relation_id[]
function DATA.filter_array_parent_child_relation_from_parent(parent, func)
    ---@type table<parent_child_relation_id, parent_child_relation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_parent_child_relation_as_parent(parent - 1)
    for i = 0, range - 1 do
        ---@type parent_child_relation_id
        local accessed_element = DCON.dcon_pop_get_index_parent_child_relation_as_parent(parent - 1, i) + 1
        if DCON.dcon_parent_child_relation_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param parent pop_id valid pop_id
---@param func fun(item: parent_child_relation_id):boolean
---@return table<parent_child_relation_id, parent_child_relation_id>
function DATA.filter_parent_child_relation_from_parent(parent, func)
    ---@type table<parent_child_relation_id, parent_child_relation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_parent_child_relation_as_parent(parent - 1)
    for i = 0, range - 1 do
        ---@type parent_child_relation_id
        local accessed_element = DCON.dcon_pop_get_index_parent_child_relation_as_parent(parent - 1, i) + 1
        if DCON.dcon_parent_child_relation_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param parent_child_relation_id parent_child_relation_id valid parent_child_relation id
---@param value pop_id valid pop_id
function DATA.parent_child_relation_set_parent(parent_child_relation_id, value)
    DCON.dcon_parent_child_relation_set_parent(parent_child_relation_id - 1, value - 1)
end
---@param child parent_child_relation_id valid pop_id
---@return pop_id Data retrieved from parent_child_relation
function DATA.parent_child_relation_get_child(child)
    return DCON.dcon_parent_child_relation_get_child(child - 1) + 1
end
---@param child pop_id valid pop_id
---@return parent_child_relation_id parent_child_relation
function DATA.get_parent_child_relation_from_child(child)
    return DCON.dcon_pop_get_parent_child_relation_as_child(child - 1) + 1
end
---@param parent_child_relation_id parent_child_relation_id valid parent_child_relation id
---@param value pop_id valid pop_id
function DATA.parent_child_relation_set_child(parent_child_relation_id, value)
    DCON.dcon_parent_child_relation_set_child(parent_child_relation_id - 1, value - 1)
end

local fat_parent_child_relation_id_metatable = {
    __index = function (t,k)
        if (k == "parent") then return DATA.parent_child_relation_get_parent(t.id) end
        if (k == "child") then return DATA.parent_child_relation_get_child(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "parent") then
            DATA.parent_child_relation_set_parent(t.id, v)
            return
        end
        if (k == "child") then
            DATA.parent_child_relation_set_child(t.id, v)
            return
        end
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
---@class (exact) loyalty_id : number
---@field is_loyalty nil

---@class (exact) fat_loyalty_id
---@field id loyalty_id Unique loyalty id
---@field top pop_id
---@field bottom pop_id

---@class struct_loyalty


ffi.cdef[[
void dcon_delete_loyalty(int32_t j);
int32_t dcon_force_create_loyalty(int32_t top, int32_t bottom);
void dcon_loyalty_set_top(int32_t, int32_t);
int32_t dcon_loyalty_get_top(int32_t);
int32_t dcon_pop_get_range_loyalty_as_top(int32_t);
int32_t dcon_pop_get_index_loyalty_as_top(int32_t, int32_t);
void dcon_loyalty_set_bottom(int32_t, int32_t);
int32_t dcon_loyalty_get_bottom(int32_t);
int32_t dcon_pop_get_loyalty_as_bottom(int32_t);
bool dcon_loyalty_is_valid(int32_t);
void dcon_loyalty_resize(uint32_t sz);
uint32_t dcon_loyalty_size();
]]

---loyalty: FFI arrays---

---loyalty: LUA bindings---

DATA.loyalty_size = 200000
---@param top pop_id
---@param bottom pop_id
---@return loyalty_id
function DATA.force_create_loyalty(top, bottom)
    ---@type loyalty_id
    local i = DCON.dcon_force_create_loyalty(top - 1, bottom - 1) + 1
    return i --[[@as loyalty_id]]
end
---@param i loyalty_id
function DATA.delete_loyalty(i)
    assert(DCON.dcon_loyalty_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_loyalty(i - 1)
end
---@param func fun(item: loyalty_id)
function DATA.for_each_loyalty(func)
    ---@type number
    local range = DCON.dcon_loyalty_size()
    for i = 0, range - 1 do
        if DCON.dcon_loyalty_is_valid(i) then func(i + 1 --[[@as loyalty_id]]) end
    end
end
---@param func fun(item: loyalty_id):boolean
---@return table<loyalty_id, loyalty_id>
function DATA.filter_loyalty(func)
    ---@type table<loyalty_id, loyalty_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_loyalty_size()
    for i = 0, range - 1 do
        if DCON.dcon_loyalty_is_valid(i) and func(i + 1 --[[@as loyalty_id]]) then t[i + 1 --[[@as loyalty_id]]] = t[i + 1 --[[@as loyalty_id]]] end
    end
    return t
end

---@param top loyalty_id valid pop_id
---@return pop_id Data retrieved from loyalty
function DATA.loyalty_get_top(top)
    return DCON.dcon_loyalty_get_top(top - 1) + 1
end
---@param top pop_id valid pop_id
---@return loyalty_id[] An array of loyalty
function DATA.get_loyalty_from_top(top)
    local result = {}
    DATA.for_each_loyalty_from_top(top, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param top pop_id valid pop_id
---@param func fun(item: loyalty_id) valid pop_id
function DATA.for_each_loyalty_from_top(top, func)
    ---@type number
    local range = DCON.dcon_pop_get_range_loyalty_as_top(top - 1)
    for i = 0, range - 1 do
        ---@type loyalty_id
        local accessed_element = DCON.dcon_pop_get_index_loyalty_as_top(top - 1, i) + 1
        if DCON.dcon_loyalty_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param top pop_id valid pop_id
---@param func fun(item: loyalty_id):boolean
---@return loyalty_id[]
function DATA.filter_array_loyalty_from_top(top, func)
    ---@type table<loyalty_id, loyalty_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_loyalty_as_top(top - 1)
    for i = 0, range - 1 do
        ---@type loyalty_id
        local accessed_element = DCON.dcon_pop_get_index_loyalty_as_top(top - 1, i) + 1
        if DCON.dcon_loyalty_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param top pop_id valid pop_id
---@param func fun(item: loyalty_id):boolean
---@return table<loyalty_id, loyalty_id>
function DATA.filter_loyalty_from_top(top, func)
    ---@type table<loyalty_id, loyalty_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_loyalty_as_top(top - 1)
    for i = 0, range - 1 do
        ---@type loyalty_id
        local accessed_element = DCON.dcon_pop_get_index_loyalty_as_top(top - 1, i) + 1
        if DCON.dcon_loyalty_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param loyalty_id loyalty_id valid loyalty id
---@param value pop_id valid pop_id
function DATA.loyalty_set_top(loyalty_id, value)
    DCON.dcon_loyalty_set_top(loyalty_id - 1, value - 1)
end
---@param bottom loyalty_id valid pop_id
---@return pop_id Data retrieved from loyalty
function DATA.loyalty_get_bottom(bottom)
    return DCON.dcon_loyalty_get_bottom(bottom - 1) + 1
end
---@param bottom pop_id valid pop_id
---@return loyalty_id loyalty
function DATA.get_loyalty_from_bottom(bottom)
    return DCON.dcon_pop_get_loyalty_as_bottom(bottom - 1) + 1
end
---@param loyalty_id loyalty_id valid loyalty id
---@param value pop_id valid pop_id
function DATA.loyalty_set_bottom(loyalty_id, value)
    DCON.dcon_loyalty_set_bottom(loyalty_id - 1, value - 1)
end

local fat_loyalty_id_metatable = {
    __index = function (t,k)
        if (k == "top") then return DATA.loyalty_get_top(t.id) end
        if (k == "bottom") then return DATA.loyalty_get_bottom(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "top") then
            DATA.loyalty_set_top(t.id, v)
            return
        end
        if (k == "bottom") then
            DATA.loyalty_set_bottom(t.id, v)
            return
        end
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
---@class (exact) succession_id : number
---@field is_succession nil

---@class (exact) fat_succession_id
---@field id succession_id Unique succession id
---@field successor_of pop_id
---@field successor pop_id

---@class struct_succession


ffi.cdef[[
void dcon_delete_succession(int32_t j);
int32_t dcon_force_create_succession(int32_t successor_of, int32_t successor);
void dcon_succession_set_successor_of(int32_t, int32_t);
int32_t dcon_succession_get_successor_of(int32_t);
int32_t dcon_pop_get_succession_as_successor_of(int32_t);
void dcon_succession_set_successor(int32_t, int32_t);
int32_t dcon_succession_get_successor(int32_t);
int32_t dcon_pop_get_range_succession_as_successor(int32_t);
int32_t dcon_pop_get_index_succession_as_successor(int32_t, int32_t);
bool dcon_succession_is_valid(int32_t);
void dcon_succession_resize(uint32_t sz);
uint32_t dcon_succession_size();
]]

---succession: FFI arrays---

---succession: LUA bindings---

DATA.succession_size = 200000
---@param successor_of pop_id
---@param successor pop_id
---@return succession_id
function DATA.force_create_succession(successor_of, successor)
    ---@type succession_id
    local i = DCON.dcon_force_create_succession(successor_of - 1, successor - 1) + 1
    return i --[[@as succession_id]]
end
---@param i succession_id
function DATA.delete_succession(i)
    assert(DCON.dcon_succession_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_succession(i - 1)
end
---@param func fun(item: succession_id)
function DATA.for_each_succession(func)
    ---@type number
    local range = DCON.dcon_succession_size()
    for i = 0, range - 1 do
        if DCON.dcon_succession_is_valid(i) then func(i + 1 --[[@as succession_id]]) end
    end
end
---@param func fun(item: succession_id):boolean
---@return table<succession_id, succession_id>
function DATA.filter_succession(func)
    ---@type table<succession_id, succession_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_succession_size()
    for i = 0, range - 1 do
        if DCON.dcon_succession_is_valid(i) and func(i + 1 --[[@as succession_id]]) then t[i + 1 --[[@as succession_id]]] = t[i + 1 --[[@as succession_id]]] end
    end
    return t
end

---@param successor_of succession_id valid pop_id
---@return pop_id Data retrieved from succession
function DATA.succession_get_successor_of(successor_of)
    return DCON.dcon_succession_get_successor_of(successor_of - 1) + 1
end
---@param successor_of pop_id valid pop_id
---@return succession_id succession
function DATA.get_succession_from_successor_of(successor_of)
    return DCON.dcon_pop_get_succession_as_successor_of(successor_of - 1) + 1
end
---@param succession_id succession_id valid succession id
---@param value pop_id valid pop_id
function DATA.succession_set_successor_of(succession_id, value)
    DCON.dcon_succession_set_successor_of(succession_id - 1, value - 1)
end
---@param successor succession_id valid pop_id
---@return pop_id Data retrieved from succession
function DATA.succession_get_successor(successor)
    return DCON.dcon_succession_get_successor(successor - 1) + 1
end
---@param successor pop_id valid pop_id
---@return succession_id[] An array of succession
function DATA.get_succession_from_successor(successor)
    local result = {}
    DATA.for_each_succession_from_successor(successor, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param successor pop_id valid pop_id
---@param func fun(item: succession_id) valid pop_id
function DATA.for_each_succession_from_successor(successor, func)
    ---@type number
    local range = DCON.dcon_pop_get_range_succession_as_successor(successor - 1)
    for i = 0, range - 1 do
        ---@type succession_id
        local accessed_element = DCON.dcon_pop_get_index_succession_as_successor(successor - 1, i) + 1
        if DCON.dcon_succession_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param successor pop_id valid pop_id
---@param func fun(item: succession_id):boolean
---@return succession_id[]
function DATA.filter_array_succession_from_successor(successor, func)
    ---@type table<succession_id, succession_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_succession_as_successor(successor - 1)
    for i = 0, range - 1 do
        ---@type succession_id
        local accessed_element = DCON.dcon_pop_get_index_succession_as_successor(successor - 1, i) + 1
        if DCON.dcon_succession_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param successor pop_id valid pop_id
---@param func fun(item: succession_id):boolean
---@return table<succession_id, succession_id>
function DATA.filter_succession_from_successor(successor, func)
    ---@type table<succession_id, succession_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_succession_as_successor(successor - 1)
    for i = 0, range - 1 do
        ---@type succession_id
        local accessed_element = DCON.dcon_pop_get_index_succession_as_successor(successor - 1, i) + 1
        if DCON.dcon_succession_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param succession_id succession_id valid succession id
---@param value pop_id valid pop_id
function DATA.succession_set_successor(succession_id, value)
    DCON.dcon_succession_set_successor(succession_id - 1, value - 1)
end

local fat_succession_id_metatable = {
    __index = function (t,k)
        if (k == "successor_of") then return DATA.succession_get_successor_of(t.id) end
        if (k == "successor") then return DATA.succession_get_successor(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "successor_of") then
            DATA.succession_set_successor_of(t.id, v)
            return
        end
        if (k == "successor") then
            DATA.succession_set_successor(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id succession_id
---@return fat_succession_id fat_id
function DATA.fatten_succession(id)
    local result = {id = id}
    setmetatable(result, fat_succession_id_metatable)    return result
end
----------realm_armies----------


---realm_armies: LSP types---

---Unique identificator for realm_armies entity
---@class (exact) realm_armies_id : number
---@field is_realm_armies nil

---@class (exact) fat_realm_armies_id
---@field id realm_armies_id Unique realm_armies id
---@field realm realm_id
---@field army army_id

---@class struct_realm_armies


ffi.cdef[[
void dcon_delete_realm_armies(int32_t j);
int32_t dcon_force_create_realm_armies(int32_t realm, int32_t army);
void dcon_realm_armies_set_realm(int32_t, int32_t);
int32_t dcon_realm_armies_get_realm(int32_t);
int32_t dcon_realm_get_range_realm_armies_as_realm(int32_t);
int32_t dcon_realm_get_index_realm_armies_as_realm(int32_t, int32_t);
void dcon_realm_armies_set_army(int32_t, int32_t);
int32_t dcon_realm_armies_get_army(int32_t);
int32_t dcon_army_get_realm_armies_as_army(int32_t);
bool dcon_realm_armies_is_valid(int32_t);
void dcon_realm_armies_resize(uint32_t sz);
uint32_t dcon_realm_armies_size();
]]

---realm_armies: FFI arrays---

---realm_armies: LUA bindings---

DATA.realm_armies_size = 15000
---@param realm realm_id
---@param army army_id
---@return realm_armies_id
function DATA.force_create_realm_armies(realm, army)
    ---@type realm_armies_id
    local i = DCON.dcon_force_create_realm_armies(realm - 1, army - 1) + 1
    return i --[[@as realm_armies_id]]
end
---@param i realm_armies_id
function DATA.delete_realm_armies(i)
    assert(DCON.dcon_realm_armies_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_realm_armies(i - 1)
end
---@param func fun(item: realm_armies_id)
function DATA.for_each_realm_armies(func)
    ---@type number
    local range = DCON.dcon_realm_armies_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_armies_is_valid(i) then func(i + 1 --[[@as realm_armies_id]]) end
    end
end
---@param func fun(item: realm_armies_id):boolean
---@return table<realm_armies_id, realm_armies_id>
function DATA.filter_realm_armies(func)
    ---@type table<realm_armies_id, realm_armies_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_armies_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_armies_is_valid(i) and func(i + 1 --[[@as realm_armies_id]]) then t[i + 1 --[[@as realm_armies_id]]] = t[i + 1 --[[@as realm_armies_id]]] end
    end
    return t
end

---@param realm realm_armies_id valid realm_id
---@return realm_id Data retrieved from realm_armies
function DATA.realm_armies_get_realm(realm)
    return DCON.dcon_realm_armies_get_realm(realm - 1) + 1
end
---@param realm realm_id valid realm_id
---@return realm_armies_id[] An array of realm_armies
function DATA.get_realm_armies_from_realm(realm)
    local result = {}
    DATA.for_each_realm_armies_from_realm(realm, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param realm realm_id valid realm_id
---@param func fun(item: realm_armies_id) valid realm_id
function DATA.for_each_realm_armies_from_realm(realm, func)
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_armies_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type realm_armies_id
        local accessed_element = DCON.dcon_realm_get_index_realm_armies_as_realm(realm - 1, i) + 1
        if DCON.dcon_realm_armies_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param realm realm_id valid realm_id
---@param func fun(item: realm_armies_id):boolean
---@return realm_armies_id[]
function DATA.filter_array_realm_armies_from_realm(realm, func)
    ---@type table<realm_armies_id, realm_armies_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_armies_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type realm_armies_id
        local accessed_element = DCON.dcon_realm_get_index_realm_armies_as_realm(realm - 1, i) + 1
        if DCON.dcon_realm_armies_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param realm realm_id valid realm_id
---@param func fun(item: realm_armies_id):boolean
---@return table<realm_armies_id, realm_armies_id>
function DATA.filter_realm_armies_from_realm(realm, func)
    ---@type table<realm_armies_id, realm_armies_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_armies_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type realm_armies_id
        local accessed_element = DCON.dcon_realm_get_index_realm_armies_as_realm(realm - 1, i) + 1
        if DCON.dcon_realm_armies_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param realm_armies_id realm_armies_id valid realm_armies id
---@param value realm_id valid realm_id
function DATA.realm_armies_set_realm(realm_armies_id, value)
    DCON.dcon_realm_armies_set_realm(realm_armies_id - 1, value - 1)
end
---@param army realm_armies_id valid army_id
---@return army_id Data retrieved from realm_armies
function DATA.realm_armies_get_army(army)
    return DCON.dcon_realm_armies_get_army(army - 1) + 1
end
---@param army army_id valid army_id
---@return realm_armies_id realm_armies
function DATA.get_realm_armies_from_army(army)
    return DCON.dcon_army_get_realm_armies_as_army(army - 1) + 1
end
---@param realm_armies_id realm_armies_id valid realm_armies id
---@param value army_id valid army_id
function DATA.realm_armies_set_army(realm_armies_id, value)
    DCON.dcon_realm_armies_set_army(realm_armies_id - 1, value - 1)
end

local fat_realm_armies_id_metatable = {
    __index = function (t,k)
        if (k == "realm") then return DATA.realm_armies_get_realm(t.id) end
        if (k == "army") then return DATA.realm_armies_get_army(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "realm") then
            DATA.realm_armies_set_realm(t.id, v)
            return
        end
        if (k == "army") then
            DATA.realm_armies_set_army(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id realm_armies_id
---@return fat_realm_armies_id fat_id
function DATA.fatten_realm_armies(id)
    local result = {id = id}
    setmetatable(result, fat_realm_armies_id_metatable)    return result
end
----------realm_guard----------


---realm_guard: LSP types---

---Unique identificator for realm_guard entity
---@class (exact) realm_guard_id : number
---@field is_realm_guard nil

---@class (exact) fat_realm_guard_id
---@field id realm_guard_id Unique realm_guard id
---@field guard warband_id
---@field realm realm_id

---@class struct_realm_guard


ffi.cdef[[
void dcon_delete_realm_guard(int32_t j);
int32_t dcon_force_create_realm_guard(int32_t guard, int32_t realm);
void dcon_realm_guard_set_guard(int32_t, int32_t);
int32_t dcon_realm_guard_get_guard(int32_t);
int32_t dcon_warband_get_realm_guard_as_guard(int32_t);
void dcon_realm_guard_set_realm(int32_t, int32_t);
int32_t dcon_realm_guard_get_realm(int32_t);
int32_t dcon_realm_get_realm_guard_as_realm(int32_t);
bool dcon_realm_guard_is_valid(int32_t);
void dcon_realm_guard_resize(uint32_t sz);
uint32_t dcon_realm_guard_size();
]]

---realm_guard: FFI arrays---

---realm_guard: LUA bindings---

DATA.realm_guard_size = 15000
---@param guard warband_id
---@param realm realm_id
---@return realm_guard_id
function DATA.force_create_realm_guard(guard, realm)
    ---@type realm_guard_id
    local i = DCON.dcon_force_create_realm_guard(guard - 1, realm - 1) + 1
    return i --[[@as realm_guard_id]]
end
---@param i realm_guard_id
function DATA.delete_realm_guard(i)
    assert(DCON.dcon_realm_guard_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_realm_guard(i - 1)
end
---@param func fun(item: realm_guard_id)
function DATA.for_each_realm_guard(func)
    ---@type number
    local range = DCON.dcon_realm_guard_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_guard_is_valid(i) then func(i + 1 --[[@as realm_guard_id]]) end
    end
end
---@param func fun(item: realm_guard_id):boolean
---@return table<realm_guard_id, realm_guard_id>
function DATA.filter_realm_guard(func)
    ---@type table<realm_guard_id, realm_guard_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_guard_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_guard_is_valid(i) and func(i + 1 --[[@as realm_guard_id]]) then t[i + 1 --[[@as realm_guard_id]]] = t[i + 1 --[[@as realm_guard_id]]] end
    end
    return t
end

---@param guard realm_guard_id valid warband_id
---@return warband_id Data retrieved from realm_guard
function DATA.realm_guard_get_guard(guard)
    return DCON.dcon_realm_guard_get_guard(guard - 1) + 1
end
---@param guard warband_id valid warband_id
---@return realm_guard_id realm_guard
function DATA.get_realm_guard_from_guard(guard)
    return DCON.dcon_warband_get_realm_guard_as_guard(guard - 1) + 1
end
---@param realm_guard_id realm_guard_id valid realm_guard id
---@param value warband_id valid warband_id
function DATA.realm_guard_set_guard(realm_guard_id, value)
    DCON.dcon_realm_guard_set_guard(realm_guard_id - 1, value - 1)
end
---@param realm realm_guard_id valid realm_id
---@return realm_id Data retrieved from realm_guard
function DATA.realm_guard_get_realm(realm)
    return DCON.dcon_realm_guard_get_realm(realm - 1) + 1
end
---@param realm realm_id valid realm_id
---@return realm_guard_id realm_guard
function DATA.get_realm_guard_from_realm(realm)
    return DCON.dcon_realm_get_realm_guard_as_realm(realm - 1) + 1
end
---@param realm_guard_id realm_guard_id valid realm_guard id
---@param value realm_id valid realm_id
function DATA.realm_guard_set_realm(realm_guard_id, value)
    DCON.dcon_realm_guard_set_realm(realm_guard_id - 1, value - 1)
end

local fat_realm_guard_id_metatable = {
    __index = function (t,k)
        if (k == "guard") then return DATA.realm_guard_get_guard(t.id) end
        if (k == "realm") then return DATA.realm_guard_get_realm(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "guard") then
            DATA.realm_guard_set_guard(t.id, v)
            return
        end
        if (k == "realm") then
            DATA.realm_guard_set_realm(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id realm_guard_id
---@return fat_realm_guard_id fat_id
function DATA.fatten_realm_guard(id)
    local result = {id = id}
    setmetatable(result, fat_realm_guard_id_metatable)    return result
end
----------realm_overseer----------


---realm_overseer: LSP types---

---Unique identificator for realm_overseer entity
---@class (exact) realm_overseer_id : number
---@field is_realm_overseer nil

---@class (exact) fat_realm_overseer_id
---@field id realm_overseer_id Unique realm_overseer id
---@field overseer pop_id
---@field realm realm_id

---@class struct_realm_overseer


ffi.cdef[[
void dcon_delete_realm_overseer(int32_t j);
int32_t dcon_force_create_realm_overseer(int32_t overseer, int32_t realm);
void dcon_realm_overseer_set_overseer(int32_t, int32_t);
int32_t dcon_realm_overseer_get_overseer(int32_t);
int32_t dcon_pop_get_realm_overseer_as_overseer(int32_t);
void dcon_realm_overseer_set_realm(int32_t, int32_t);
int32_t dcon_realm_overseer_get_realm(int32_t);
int32_t dcon_realm_get_realm_overseer_as_realm(int32_t);
bool dcon_realm_overseer_is_valid(int32_t);
void dcon_realm_overseer_resize(uint32_t sz);
uint32_t dcon_realm_overseer_size();
]]

---realm_overseer: FFI arrays---

---realm_overseer: LUA bindings---

DATA.realm_overseer_size = 15000
---@param overseer pop_id
---@param realm realm_id
---@return realm_overseer_id
function DATA.force_create_realm_overseer(overseer, realm)
    ---@type realm_overseer_id
    local i = DCON.dcon_force_create_realm_overseer(overseer - 1, realm - 1) + 1
    return i --[[@as realm_overseer_id]]
end
---@param i realm_overseer_id
function DATA.delete_realm_overseer(i)
    assert(DCON.dcon_realm_overseer_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_realm_overseer(i - 1)
end
---@param func fun(item: realm_overseer_id)
function DATA.for_each_realm_overseer(func)
    ---@type number
    local range = DCON.dcon_realm_overseer_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_overseer_is_valid(i) then func(i + 1 --[[@as realm_overseer_id]]) end
    end
end
---@param func fun(item: realm_overseer_id):boolean
---@return table<realm_overseer_id, realm_overseer_id>
function DATA.filter_realm_overseer(func)
    ---@type table<realm_overseer_id, realm_overseer_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_overseer_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_overseer_is_valid(i) and func(i + 1 --[[@as realm_overseer_id]]) then t[i + 1 --[[@as realm_overseer_id]]] = t[i + 1 --[[@as realm_overseer_id]]] end
    end
    return t
end

---@param overseer realm_overseer_id valid pop_id
---@return pop_id Data retrieved from realm_overseer
function DATA.realm_overseer_get_overseer(overseer)
    return DCON.dcon_realm_overseer_get_overseer(overseer - 1) + 1
end
---@param overseer pop_id valid pop_id
---@return realm_overseer_id realm_overseer
function DATA.get_realm_overseer_from_overseer(overseer)
    return DCON.dcon_pop_get_realm_overseer_as_overseer(overseer - 1) + 1
end
---@param realm_overseer_id realm_overseer_id valid realm_overseer id
---@param value pop_id valid pop_id
function DATA.realm_overseer_set_overseer(realm_overseer_id, value)
    DCON.dcon_realm_overseer_set_overseer(realm_overseer_id - 1, value - 1)
end
---@param realm realm_overseer_id valid realm_id
---@return realm_id Data retrieved from realm_overseer
function DATA.realm_overseer_get_realm(realm)
    return DCON.dcon_realm_overseer_get_realm(realm - 1) + 1
end
---@param realm realm_id valid realm_id
---@return realm_overseer_id realm_overseer
function DATA.get_realm_overseer_from_realm(realm)
    return DCON.dcon_realm_get_realm_overseer_as_realm(realm - 1) + 1
end
---@param realm_overseer_id realm_overseer_id valid realm_overseer id
---@param value realm_id valid realm_id
function DATA.realm_overseer_set_realm(realm_overseer_id, value)
    DCON.dcon_realm_overseer_set_realm(realm_overseer_id - 1, value - 1)
end

local fat_realm_overseer_id_metatable = {
    __index = function (t,k)
        if (k == "overseer") then return DATA.realm_overseer_get_overseer(t.id) end
        if (k == "realm") then return DATA.realm_overseer_get_realm(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "overseer") then
            DATA.realm_overseer_set_overseer(t.id, v)
            return
        end
        if (k == "realm") then
            DATA.realm_overseer_set_realm(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id realm_overseer_id
---@return fat_realm_overseer_id fat_id
function DATA.fatten_realm_overseer(id)
    local result = {id = id}
    setmetatable(result, fat_realm_overseer_id_metatable)    return result
end
----------realm_leadership----------


---realm_leadership: LSP types---

---Unique identificator for realm_leadership entity
---@class (exact) realm_leadership_id : number
---@field is_realm_leadership nil

---@class (exact) fat_realm_leadership_id
---@field id realm_leadership_id Unique realm_leadership id
---@field leader pop_id
---@field realm realm_id

---@class struct_realm_leadership


ffi.cdef[[
void dcon_delete_realm_leadership(int32_t j);
int32_t dcon_force_create_realm_leadership(int32_t leader, int32_t realm);
void dcon_realm_leadership_set_leader(int32_t, int32_t);
int32_t dcon_realm_leadership_get_leader(int32_t);
int32_t dcon_pop_get_range_realm_leadership_as_leader(int32_t);
int32_t dcon_pop_get_index_realm_leadership_as_leader(int32_t, int32_t);
void dcon_realm_leadership_set_realm(int32_t, int32_t);
int32_t dcon_realm_leadership_get_realm(int32_t);
int32_t dcon_realm_get_realm_leadership_as_realm(int32_t);
bool dcon_realm_leadership_is_valid(int32_t);
void dcon_realm_leadership_resize(uint32_t sz);
uint32_t dcon_realm_leadership_size();
]]

---realm_leadership: FFI arrays---

---realm_leadership: LUA bindings---

DATA.realm_leadership_size = 15000
---@param leader pop_id
---@param realm realm_id
---@return realm_leadership_id
function DATA.force_create_realm_leadership(leader, realm)
    ---@type realm_leadership_id
    local i = DCON.dcon_force_create_realm_leadership(leader - 1, realm - 1) + 1
    return i --[[@as realm_leadership_id]]
end
---@param i realm_leadership_id
function DATA.delete_realm_leadership(i)
    assert(DCON.dcon_realm_leadership_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_realm_leadership(i - 1)
end
---@param func fun(item: realm_leadership_id)
function DATA.for_each_realm_leadership(func)
    ---@type number
    local range = DCON.dcon_realm_leadership_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_leadership_is_valid(i) then func(i + 1 --[[@as realm_leadership_id]]) end
    end
end
---@param func fun(item: realm_leadership_id):boolean
---@return table<realm_leadership_id, realm_leadership_id>
function DATA.filter_realm_leadership(func)
    ---@type table<realm_leadership_id, realm_leadership_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_leadership_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_leadership_is_valid(i) and func(i + 1 --[[@as realm_leadership_id]]) then t[i + 1 --[[@as realm_leadership_id]]] = t[i + 1 --[[@as realm_leadership_id]]] end
    end
    return t
end

---@param leader realm_leadership_id valid pop_id
---@return pop_id Data retrieved from realm_leadership
function DATA.realm_leadership_get_leader(leader)
    return DCON.dcon_realm_leadership_get_leader(leader - 1) + 1
end
---@param leader pop_id valid pop_id
---@return realm_leadership_id[] An array of realm_leadership
function DATA.get_realm_leadership_from_leader(leader)
    local result = {}
    DATA.for_each_realm_leadership_from_leader(leader, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param leader pop_id valid pop_id
---@param func fun(item: realm_leadership_id) valid pop_id
function DATA.for_each_realm_leadership_from_leader(leader, func)
    ---@type number
    local range = DCON.dcon_pop_get_range_realm_leadership_as_leader(leader - 1)
    for i = 0, range - 1 do
        ---@type realm_leadership_id
        local accessed_element = DCON.dcon_pop_get_index_realm_leadership_as_leader(leader - 1, i) + 1
        if DCON.dcon_realm_leadership_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param leader pop_id valid pop_id
---@param func fun(item: realm_leadership_id):boolean
---@return realm_leadership_id[]
function DATA.filter_array_realm_leadership_from_leader(leader, func)
    ---@type table<realm_leadership_id, realm_leadership_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_realm_leadership_as_leader(leader - 1)
    for i = 0, range - 1 do
        ---@type realm_leadership_id
        local accessed_element = DCON.dcon_pop_get_index_realm_leadership_as_leader(leader - 1, i) + 1
        if DCON.dcon_realm_leadership_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param leader pop_id valid pop_id
---@param func fun(item: realm_leadership_id):boolean
---@return table<realm_leadership_id, realm_leadership_id>
function DATA.filter_realm_leadership_from_leader(leader, func)
    ---@type table<realm_leadership_id, realm_leadership_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_realm_leadership_as_leader(leader - 1)
    for i = 0, range - 1 do
        ---@type realm_leadership_id
        local accessed_element = DCON.dcon_pop_get_index_realm_leadership_as_leader(leader - 1, i) + 1
        if DCON.dcon_realm_leadership_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param realm_leadership_id realm_leadership_id valid realm_leadership id
---@param value pop_id valid pop_id
function DATA.realm_leadership_set_leader(realm_leadership_id, value)
    DCON.dcon_realm_leadership_set_leader(realm_leadership_id - 1, value - 1)
end
---@param realm realm_leadership_id valid realm_id
---@return realm_id Data retrieved from realm_leadership
function DATA.realm_leadership_get_realm(realm)
    return DCON.dcon_realm_leadership_get_realm(realm - 1) + 1
end
---@param realm realm_id valid realm_id
---@return realm_leadership_id realm_leadership
function DATA.get_realm_leadership_from_realm(realm)
    return DCON.dcon_realm_get_realm_leadership_as_realm(realm - 1) + 1
end
---@param realm_leadership_id realm_leadership_id valid realm_leadership id
---@param value realm_id valid realm_id
function DATA.realm_leadership_set_realm(realm_leadership_id, value)
    DCON.dcon_realm_leadership_set_realm(realm_leadership_id - 1, value - 1)
end

local fat_realm_leadership_id_metatable = {
    __index = function (t,k)
        if (k == "leader") then return DATA.realm_leadership_get_leader(t.id) end
        if (k == "realm") then return DATA.realm_leadership_get_realm(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "leader") then
            DATA.realm_leadership_set_leader(t.id, v)
            return
        end
        if (k == "realm") then
            DATA.realm_leadership_set_realm(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id realm_leadership_id
---@return fat_realm_leadership_id fat_id
function DATA.fatten_realm_leadership(id)
    local result = {id = id}
    setmetatable(result, fat_realm_leadership_id_metatable)    return result
end
----------realm_subject_relation----------


---realm_subject_relation: LSP types---

---Unique identificator for realm_subject_relation entity
---@class (exact) realm_subject_relation_id : number
---@field is_realm_subject_relation nil

---@class (exact) fat_realm_subject_relation_id
---@field id realm_subject_relation_id Unique realm_subject_relation id
---@field wealth_transfer boolean
---@field goods_transfer boolean
---@field warriors_contribution boolean
---@field protection boolean
---@field local_ruler boolean
---@field overlord realm_id
---@field subject realm_id

---@class struct_realm_subject_relation
---@field wealth_transfer boolean
---@field goods_transfer boolean
---@field warriors_contribution boolean
---@field protection boolean
---@field local_ruler boolean


ffi.cdef[[
void dcon_realm_subject_relation_set_wealth_transfer(int32_t, bool);
bool dcon_realm_subject_relation_get_wealth_transfer(int32_t);
void dcon_realm_subject_relation_set_goods_transfer(int32_t, bool);
bool dcon_realm_subject_relation_get_goods_transfer(int32_t);
void dcon_realm_subject_relation_set_warriors_contribution(int32_t, bool);
bool dcon_realm_subject_relation_get_warriors_contribution(int32_t);
void dcon_realm_subject_relation_set_protection(int32_t, bool);
bool dcon_realm_subject_relation_get_protection(int32_t);
void dcon_realm_subject_relation_set_local_ruler(int32_t, bool);
bool dcon_realm_subject_relation_get_local_ruler(int32_t);
void dcon_delete_realm_subject_relation(int32_t j);
int32_t dcon_force_create_realm_subject_relation(int32_t overlord, int32_t subject);
void dcon_realm_subject_relation_set_overlord(int32_t, int32_t);
int32_t dcon_realm_subject_relation_get_overlord(int32_t);
int32_t dcon_realm_get_range_realm_subject_relation_as_overlord(int32_t);
int32_t dcon_realm_get_index_realm_subject_relation_as_overlord(int32_t, int32_t);
void dcon_realm_subject_relation_set_subject(int32_t, int32_t);
int32_t dcon_realm_subject_relation_get_subject(int32_t);
int32_t dcon_realm_get_range_realm_subject_relation_as_subject(int32_t);
int32_t dcon_realm_get_index_realm_subject_relation_as_subject(int32_t, int32_t);
bool dcon_realm_subject_relation_is_valid(int32_t);
void dcon_realm_subject_relation_resize(uint32_t sz);
uint32_t dcon_realm_subject_relation_size();
]]

---realm_subject_relation: FFI arrays---

---realm_subject_relation: LUA bindings---

DATA.realm_subject_relation_size = 15000
---@param overlord realm_id
---@param subject realm_id
---@return realm_subject_relation_id
function DATA.force_create_realm_subject_relation(overlord, subject)
    ---@type realm_subject_relation_id
    local i = DCON.dcon_force_create_realm_subject_relation(overlord - 1, subject - 1) + 1
    return i --[[@as realm_subject_relation_id]]
end
---@param i realm_subject_relation_id
function DATA.delete_realm_subject_relation(i)
    assert(DCON.dcon_realm_subject_relation_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_realm_subject_relation(i - 1)
end
---@param func fun(item: realm_subject_relation_id)
function DATA.for_each_realm_subject_relation(func)
    ---@type number
    local range = DCON.dcon_realm_subject_relation_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_subject_relation_is_valid(i) then func(i + 1 --[[@as realm_subject_relation_id]]) end
    end
end
---@param func fun(item: realm_subject_relation_id):boolean
---@return table<realm_subject_relation_id, realm_subject_relation_id>
function DATA.filter_realm_subject_relation(func)
    ---@type table<realm_subject_relation_id, realm_subject_relation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_subject_relation_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_subject_relation_is_valid(i) and func(i + 1 --[[@as realm_subject_relation_id]]) then t[i + 1 --[[@as realm_subject_relation_id]]] = t[i + 1 --[[@as realm_subject_relation_id]]] end
    end
    return t
end

---@param realm_subject_relation_id realm_subject_relation_id valid realm_subject_relation id
---@return boolean wealth_transfer
function DATA.realm_subject_relation_get_wealth_transfer(realm_subject_relation_id)
    return DCON.dcon_realm_subject_relation_get_wealth_transfer(realm_subject_relation_id - 1)
end
---@param realm_subject_relation_id realm_subject_relation_id valid realm_subject_relation id
---@param value boolean valid boolean
function DATA.realm_subject_relation_set_wealth_transfer(realm_subject_relation_id, value)
    DCON.dcon_realm_subject_relation_set_wealth_transfer(realm_subject_relation_id - 1, value)
end
---@param realm_subject_relation_id realm_subject_relation_id valid realm_subject_relation id
---@return boolean goods_transfer
function DATA.realm_subject_relation_get_goods_transfer(realm_subject_relation_id)
    return DCON.dcon_realm_subject_relation_get_goods_transfer(realm_subject_relation_id - 1)
end
---@param realm_subject_relation_id realm_subject_relation_id valid realm_subject_relation id
---@param value boolean valid boolean
function DATA.realm_subject_relation_set_goods_transfer(realm_subject_relation_id, value)
    DCON.dcon_realm_subject_relation_set_goods_transfer(realm_subject_relation_id - 1, value)
end
---@param realm_subject_relation_id realm_subject_relation_id valid realm_subject_relation id
---@return boolean warriors_contribution
function DATA.realm_subject_relation_get_warriors_contribution(realm_subject_relation_id)
    return DCON.dcon_realm_subject_relation_get_warriors_contribution(realm_subject_relation_id - 1)
end
---@param realm_subject_relation_id realm_subject_relation_id valid realm_subject_relation id
---@param value boolean valid boolean
function DATA.realm_subject_relation_set_warriors_contribution(realm_subject_relation_id, value)
    DCON.dcon_realm_subject_relation_set_warriors_contribution(realm_subject_relation_id - 1, value)
end
---@param realm_subject_relation_id realm_subject_relation_id valid realm_subject_relation id
---@return boolean protection
function DATA.realm_subject_relation_get_protection(realm_subject_relation_id)
    return DCON.dcon_realm_subject_relation_get_protection(realm_subject_relation_id - 1)
end
---@param realm_subject_relation_id realm_subject_relation_id valid realm_subject_relation id
---@param value boolean valid boolean
function DATA.realm_subject_relation_set_protection(realm_subject_relation_id, value)
    DCON.dcon_realm_subject_relation_set_protection(realm_subject_relation_id - 1, value)
end
---@param realm_subject_relation_id realm_subject_relation_id valid realm_subject_relation id
---@return boolean local_ruler
function DATA.realm_subject_relation_get_local_ruler(realm_subject_relation_id)
    return DCON.dcon_realm_subject_relation_get_local_ruler(realm_subject_relation_id - 1)
end
---@param realm_subject_relation_id realm_subject_relation_id valid realm_subject_relation id
---@param value boolean valid boolean
function DATA.realm_subject_relation_set_local_ruler(realm_subject_relation_id, value)
    DCON.dcon_realm_subject_relation_set_local_ruler(realm_subject_relation_id - 1, value)
end
---@param overlord realm_subject_relation_id valid realm_id
---@return realm_id Data retrieved from realm_subject_relation
function DATA.realm_subject_relation_get_overlord(overlord)
    return DCON.dcon_realm_subject_relation_get_overlord(overlord - 1) + 1
end
---@param overlord realm_id valid realm_id
---@return realm_subject_relation_id[] An array of realm_subject_relation
function DATA.get_realm_subject_relation_from_overlord(overlord)
    local result = {}
    DATA.for_each_realm_subject_relation_from_overlord(overlord, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param overlord realm_id valid realm_id
---@param func fun(item: realm_subject_relation_id) valid realm_id
function DATA.for_each_realm_subject_relation_from_overlord(overlord, func)
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_subject_relation_as_overlord(overlord - 1)
    for i = 0, range - 1 do
        ---@type realm_subject_relation_id
        local accessed_element = DCON.dcon_realm_get_index_realm_subject_relation_as_overlord(overlord - 1, i) + 1
        if DCON.dcon_realm_subject_relation_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param overlord realm_id valid realm_id
---@param func fun(item: realm_subject_relation_id):boolean
---@return realm_subject_relation_id[]
function DATA.filter_array_realm_subject_relation_from_overlord(overlord, func)
    ---@type table<realm_subject_relation_id, realm_subject_relation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_subject_relation_as_overlord(overlord - 1)
    for i = 0, range - 1 do
        ---@type realm_subject_relation_id
        local accessed_element = DCON.dcon_realm_get_index_realm_subject_relation_as_overlord(overlord - 1, i) + 1
        if DCON.dcon_realm_subject_relation_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param overlord realm_id valid realm_id
---@param func fun(item: realm_subject_relation_id):boolean
---@return table<realm_subject_relation_id, realm_subject_relation_id>
function DATA.filter_realm_subject_relation_from_overlord(overlord, func)
    ---@type table<realm_subject_relation_id, realm_subject_relation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_subject_relation_as_overlord(overlord - 1)
    for i = 0, range - 1 do
        ---@type realm_subject_relation_id
        local accessed_element = DCON.dcon_realm_get_index_realm_subject_relation_as_overlord(overlord - 1, i) + 1
        if DCON.dcon_realm_subject_relation_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param realm_subject_relation_id realm_subject_relation_id valid realm_subject_relation id
---@param value realm_id valid realm_id
function DATA.realm_subject_relation_set_overlord(realm_subject_relation_id, value)
    DCON.dcon_realm_subject_relation_set_overlord(realm_subject_relation_id - 1, value - 1)
end
---@param subject realm_subject_relation_id valid realm_id
---@return realm_id Data retrieved from realm_subject_relation
function DATA.realm_subject_relation_get_subject(subject)
    return DCON.dcon_realm_subject_relation_get_subject(subject - 1) + 1
end
---@param subject realm_id valid realm_id
---@return realm_subject_relation_id[] An array of realm_subject_relation
function DATA.get_realm_subject_relation_from_subject(subject)
    local result = {}
    DATA.for_each_realm_subject_relation_from_subject(subject, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param subject realm_id valid realm_id
---@param func fun(item: realm_subject_relation_id) valid realm_id
function DATA.for_each_realm_subject_relation_from_subject(subject, func)
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_subject_relation_as_subject(subject - 1)
    for i = 0, range - 1 do
        ---@type realm_subject_relation_id
        local accessed_element = DCON.dcon_realm_get_index_realm_subject_relation_as_subject(subject - 1, i) + 1
        if DCON.dcon_realm_subject_relation_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param subject realm_id valid realm_id
---@param func fun(item: realm_subject_relation_id):boolean
---@return realm_subject_relation_id[]
function DATA.filter_array_realm_subject_relation_from_subject(subject, func)
    ---@type table<realm_subject_relation_id, realm_subject_relation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_subject_relation_as_subject(subject - 1)
    for i = 0, range - 1 do
        ---@type realm_subject_relation_id
        local accessed_element = DCON.dcon_realm_get_index_realm_subject_relation_as_subject(subject - 1, i) + 1
        if DCON.dcon_realm_subject_relation_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param subject realm_id valid realm_id
---@param func fun(item: realm_subject_relation_id):boolean
---@return table<realm_subject_relation_id, realm_subject_relation_id>
function DATA.filter_realm_subject_relation_from_subject(subject, func)
    ---@type table<realm_subject_relation_id, realm_subject_relation_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_subject_relation_as_subject(subject - 1)
    for i = 0, range - 1 do
        ---@type realm_subject_relation_id
        local accessed_element = DCON.dcon_realm_get_index_realm_subject_relation_as_subject(subject - 1, i) + 1
        if DCON.dcon_realm_subject_relation_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param realm_subject_relation_id realm_subject_relation_id valid realm_subject_relation id
---@param value realm_id valid realm_id
function DATA.realm_subject_relation_set_subject(realm_subject_relation_id, value)
    DCON.dcon_realm_subject_relation_set_subject(realm_subject_relation_id - 1, value - 1)
end

local fat_realm_subject_relation_id_metatable = {
    __index = function (t,k)
        if (k == "wealth_transfer") then return DATA.realm_subject_relation_get_wealth_transfer(t.id) end
        if (k == "goods_transfer") then return DATA.realm_subject_relation_get_goods_transfer(t.id) end
        if (k == "warriors_contribution") then return DATA.realm_subject_relation_get_warriors_contribution(t.id) end
        if (k == "protection") then return DATA.realm_subject_relation_get_protection(t.id) end
        if (k == "local_ruler") then return DATA.realm_subject_relation_get_local_ruler(t.id) end
        if (k == "overlord") then return DATA.realm_subject_relation_get_overlord(t.id) end
        if (k == "subject") then return DATA.realm_subject_relation_get_subject(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "wealth_transfer") then
            DATA.realm_subject_relation_set_wealth_transfer(t.id, v)
            return
        end
        if (k == "goods_transfer") then
            DATA.realm_subject_relation_set_goods_transfer(t.id, v)
            return
        end
        if (k == "warriors_contribution") then
            DATA.realm_subject_relation_set_warriors_contribution(t.id, v)
            return
        end
        if (k == "protection") then
            DATA.realm_subject_relation_set_protection(t.id, v)
            return
        end
        if (k == "local_ruler") then
            DATA.realm_subject_relation_set_local_ruler(t.id, v)
            return
        end
        if (k == "overlord") then
            DATA.realm_subject_relation_set_overlord(t.id, v)
            return
        end
        if (k == "subject") then
            DATA.realm_subject_relation_set_subject(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id realm_subject_relation_id
---@return fat_realm_subject_relation_id fat_id
function DATA.fatten_realm_subject_relation(id)
    local result = {id = id}
    setmetatable(result, fat_realm_subject_relation_id_metatable)    return result
end
----------tax_collector----------


---tax_collector: LSP types---

---Unique identificator for tax_collector entity
---@class (exact) tax_collector_id : number
---@field is_tax_collector nil

---@class (exact) fat_tax_collector_id
---@field id tax_collector_id Unique tax_collector id
---@field collector pop_id
---@field realm realm_id

---@class struct_tax_collector


ffi.cdef[[
void dcon_delete_tax_collector(int32_t j);
int32_t dcon_force_create_tax_collector(int32_t collector, int32_t realm);
void dcon_tax_collector_set_collector(int32_t, int32_t);
int32_t dcon_tax_collector_get_collector(int32_t);
int32_t dcon_pop_get_tax_collector_as_collector(int32_t);
void dcon_tax_collector_set_realm(int32_t, int32_t);
int32_t dcon_tax_collector_get_realm(int32_t);
int32_t dcon_realm_get_range_tax_collector_as_realm(int32_t);
int32_t dcon_realm_get_index_tax_collector_as_realm(int32_t, int32_t);
bool dcon_tax_collector_is_valid(int32_t);
void dcon_tax_collector_resize(uint32_t sz);
uint32_t dcon_tax_collector_size();
]]

---tax_collector: FFI arrays---

---tax_collector: LUA bindings---

DATA.tax_collector_size = 45000
---@param collector pop_id
---@param realm realm_id
---@return tax_collector_id
function DATA.force_create_tax_collector(collector, realm)
    ---@type tax_collector_id
    local i = DCON.dcon_force_create_tax_collector(collector - 1, realm - 1) + 1
    return i --[[@as tax_collector_id]]
end
---@param i tax_collector_id
function DATA.delete_tax_collector(i)
    assert(DCON.dcon_tax_collector_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_tax_collector(i - 1)
end
---@param func fun(item: tax_collector_id)
function DATA.for_each_tax_collector(func)
    ---@type number
    local range = DCON.dcon_tax_collector_size()
    for i = 0, range - 1 do
        if DCON.dcon_tax_collector_is_valid(i) then func(i + 1 --[[@as tax_collector_id]]) end
    end
end
---@param func fun(item: tax_collector_id):boolean
---@return table<tax_collector_id, tax_collector_id>
function DATA.filter_tax_collector(func)
    ---@type table<tax_collector_id, tax_collector_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_tax_collector_size()
    for i = 0, range - 1 do
        if DCON.dcon_tax_collector_is_valid(i) and func(i + 1 --[[@as tax_collector_id]]) then t[i + 1 --[[@as tax_collector_id]]] = t[i + 1 --[[@as tax_collector_id]]] end
    end
    return t
end

---@param collector tax_collector_id valid pop_id
---@return pop_id Data retrieved from tax_collector
function DATA.tax_collector_get_collector(collector)
    return DCON.dcon_tax_collector_get_collector(collector - 1) + 1
end
---@param collector pop_id valid pop_id
---@return tax_collector_id tax_collector
function DATA.get_tax_collector_from_collector(collector)
    return DCON.dcon_pop_get_tax_collector_as_collector(collector - 1) + 1
end
---@param tax_collector_id tax_collector_id valid tax_collector id
---@param value pop_id valid pop_id
function DATA.tax_collector_set_collector(tax_collector_id, value)
    DCON.dcon_tax_collector_set_collector(tax_collector_id - 1, value - 1)
end
---@param realm tax_collector_id valid realm_id
---@return realm_id Data retrieved from tax_collector
function DATA.tax_collector_get_realm(realm)
    return DCON.dcon_tax_collector_get_realm(realm - 1) + 1
end
---@param realm realm_id valid realm_id
---@return tax_collector_id[] An array of tax_collector
function DATA.get_tax_collector_from_realm(realm)
    local result = {}
    DATA.for_each_tax_collector_from_realm(realm, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param realm realm_id valid realm_id
---@param func fun(item: tax_collector_id) valid realm_id
function DATA.for_each_tax_collector_from_realm(realm, func)
    ---@type number
    local range = DCON.dcon_realm_get_range_tax_collector_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type tax_collector_id
        local accessed_element = DCON.dcon_realm_get_index_tax_collector_as_realm(realm - 1, i) + 1
        if DCON.dcon_tax_collector_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param realm realm_id valid realm_id
---@param func fun(item: tax_collector_id):boolean
---@return tax_collector_id[]
function DATA.filter_array_tax_collector_from_realm(realm, func)
    ---@type table<tax_collector_id, tax_collector_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_tax_collector_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type tax_collector_id
        local accessed_element = DCON.dcon_realm_get_index_tax_collector_as_realm(realm - 1, i) + 1
        if DCON.dcon_tax_collector_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param realm realm_id valid realm_id
---@param func fun(item: tax_collector_id):boolean
---@return table<tax_collector_id, tax_collector_id>
function DATA.filter_tax_collector_from_realm(realm, func)
    ---@type table<tax_collector_id, tax_collector_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_tax_collector_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type tax_collector_id
        local accessed_element = DCON.dcon_realm_get_index_tax_collector_as_realm(realm - 1, i) + 1
        if DCON.dcon_tax_collector_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param tax_collector_id tax_collector_id valid tax_collector id
---@param value realm_id valid realm_id
function DATA.tax_collector_set_realm(tax_collector_id, value)
    DCON.dcon_tax_collector_set_realm(tax_collector_id - 1, value - 1)
end

local fat_tax_collector_id_metatable = {
    __index = function (t,k)
        if (k == "collector") then return DATA.tax_collector_get_collector(t.id) end
        if (k == "realm") then return DATA.tax_collector_get_realm(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "collector") then
            DATA.tax_collector_set_collector(t.id, v)
            return
        end
        if (k == "realm") then
            DATA.tax_collector_set_realm(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id tax_collector_id
---@return fat_tax_collector_id fat_id
function DATA.fatten_tax_collector(id)
    local result = {id = id}
    setmetatable(result, fat_tax_collector_id_metatable)    return result
end
----------personal_rights----------


---personal_rights: LSP types---

---Unique identificator for personal_rights entity
---@class (exact) personal_rights_id : number
---@field is_personal_rights nil

---@class (exact) fat_personal_rights_id
---@field id personal_rights_id Unique personal_rights id
---@field can_trade boolean
---@field can_build boolean
---@field person pop_id
---@field realm realm_id

---@class struct_personal_rights
---@field can_trade boolean
---@field can_build boolean


ffi.cdef[[
void dcon_personal_rights_set_can_trade(int32_t, bool);
bool dcon_personal_rights_get_can_trade(int32_t);
void dcon_personal_rights_set_can_build(int32_t, bool);
bool dcon_personal_rights_get_can_build(int32_t);
void dcon_delete_personal_rights(int32_t j);
int32_t dcon_force_create_personal_rights(int32_t person, int32_t realm);
void dcon_personal_rights_set_person(int32_t, int32_t);
int32_t dcon_personal_rights_get_person(int32_t);
int32_t dcon_pop_get_range_personal_rights_as_person(int32_t);
int32_t dcon_pop_get_index_personal_rights_as_person(int32_t, int32_t);
void dcon_personal_rights_set_realm(int32_t, int32_t);
int32_t dcon_personal_rights_get_realm(int32_t);
int32_t dcon_realm_get_range_personal_rights_as_realm(int32_t);
int32_t dcon_realm_get_index_personal_rights_as_realm(int32_t, int32_t);
bool dcon_personal_rights_is_valid(int32_t);
void dcon_personal_rights_resize(uint32_t sz);
uint32_t dcon_personal_rights_size();
]]

---personal_rights: FFI arrays---

---personal_rights: LUA bindings---

DATA.personal_rights_size = 450000
---@param person pop_id
---@param realm realm_id
---@return personal_rights_id
function DATA.force_create_personal_rights(person, realm)
    ---@type personal_rights_id
    local i = DCON.dcon_force_create_personal_rights(person - 1, realm - 1) + 1
    return i --[[@as personal_rights_id]]
end
---@param i personal_rights_id
function DATA.delete_personal_rights(i)
    assert(DCON.dcon_personal_rights_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_personal_rights(i - 1)
end
---@param func fun(item: personal_rights_id)
function DATA.for_each_personal_rights(func)
    ---@type number
    local range = DCON.dcon_personal_rights_size()
    for i = 0, range - 1 do
        if DCON.dcon_personal_rights_is_valid(i) then func(i + 1 --[[@as personal_rights_id]]) end
    end
end
---@param func fun(item: personal_rights_id):boolean
---@return table<personal_rights_id, personal_rights_id>
function DATA.filter_personal_rights(func)
    ---@type table<personal_rights_id, personal_rights_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_personal_rights_size()
    for i = 0, range - 1 do
        if DCON.dcon_personal_rights_is_valid(i) and func(i + 1 --[[@as personal_rights_id]]) then t[i + 1 --[[@as personal_rights_id]]] = t[i + 1 --[[@as personal_rights_id]]] end
    end
    return t
end

---@param personal_rights_id personal_rights_id valid personal_rights id
---@return boolean can_trade
function DATA.personal_rights_get_can_trade(personal_rights_id)
    return DCON.dcon_personal_rights_get_can_trade(personal_rights_id - 1)
end
---@param personal_rights_id personal_rights_id valid personal_rights id
---@param value boolean valid boolean
function DATA.personal_rights_set_can_trade(personal_rights_id, value)
    DCON.dcon_personal_rights_set_can_trade(personal_rights_id - 1, value)
end
---@param personal_rights_id personal_rights_id valid personal_rights id
---@return boolean can_build
function DATA.personal_rights_get_can_build(personal_rights_id)
    return DCON.dcon_personal_rights_get_can_build(personal_rights_id - 1)
end
---@param personal_rights_id personal_rights_id valid personal_rights id
---@param value boolean valid boolean
function DATA.personal_rights_set_can_build(personal_rights_id, value)
    DCON.dcon_personal_rights_set_can_build(personal_rights_id - 1, value)
end
---@param person personal_rights_id valid pop_id
---@return pop_id Data retrieved from personal_rights
function DATA.personal_rights_get_person(person)
    return DCON.dcon_personal_rights_get_person(person - 1) + 1
end
---@param person pop_id valid pop_id
---@return personal_rights_id[] An array of personal_rights
function DATA.get_personal_rights_from_person(person)
    local result = {}
    DATA.for_each_personal_rights_from_person(person, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param person pop_id valid pop_id
---@param func fun(item: personal_rights_id) valid pop_id
function DATA.for_each_personal_rights_from_person(person, func)
    ---@type number
    local range = DCON.dcon_pop_get_range_personal_rights_as_person(person - 1)
    for i = 0, range - 1 do
        ---@type personal_rights_id
        local accessed_element = DCON.dcon_pop_get_index_personal_rights_as_person(person - 1, i) + 1
        if DCON.dcon_personal_rights_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param person pop_id valid pop_id
---@param func fun(item: personal_rights_id):boolean
---@return personal_rights_id[]
function DATA.filter_array_personal_rights_from_person(person, func)
    ---@type table<personal_rights_id, personal_rights_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_personal_rights_as_person(person - 1)
    for i = 0, range - 1 do
        ---@type personal_rights_id
        local accessed_element = DCON.dcon_pop_get_index_personal_rights_as_person(person - 1, i) + 1
        if DCON.dcon_personal_rights_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param person pop_id valid pop_id
---@param func fun(item: personal_rights_id):boolean
---@return table<personal_rights_id, personal_rights_id>
function DATA.filter_personal_rights_from_person(person, func)
    ---@type table<personal_rights_id, personal_rights_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_personal_rights_as_person(person - 1)
    for i = 0, range - 1 do
        ---@type personal_rights_id
        local accessed_element = DCON.dcon_pop_get_index_personal_rights_as_person(person - 1, i) + 1
        if DCON.dcon_personal_rights_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param personal_rights_id personal_rights_id valid personal_rights id
---@param value pop_id valid pop_id
function DATA.personal_rights_set_person(personal_rights_id, value)
    DCON.dcon_personal_rights_set_person(personal_rights_id - 1, value - 1)
end
---@param realm personal_rights_id valid realm_id
---@return realm_id Data retrieved from personal_rights
function DATA.personal_rights_get_realm(realm)
    return DCON.dcon_personal_rights_get_realm(realm - 1) + 1
end
---@param realm realm_id valid realm_id
---@return personal_rights_id[] An array of personal_rights
function DATA.get_personal_rights_from_realm(realm)
    local result = {}
    DATA.for_each_personal_rights_from_realm(realm, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param realm realm_id valid realm_id
---@param func fun(item: personal_rights_id) valid realm_id
function DATA.for_each_personal_rights_from_realm(realm, func)
    ---@type number
    local range = DCON.dcon_realm_get_range_personal_rights_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type personal_rights_id
        local accessed_element = DCON.dcon_realm_get_index_personal_rights_as_realm(realm - 1, i) + 1
        if DCON.dcon_personal_rights_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param realm realm_id valid realm_id
---@param func fun(item: personal_rights_id):boolean
---@return personal_rights_id[]
function DATA.filter_array_personal_rights_from_realm(realm, func)
    ---@type table<personal_rights_id, personal_rights_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_personal_rights_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type personal_rights_id
        local accessed_element = DCON.dcon_realm_get_index_personal_rights_as_realm(realm - 1, i) + 1
        if DCON.dcon_personal_rights_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param realm realm_id valid realm_id
---@param func fun(item: personal_rights_id):boolean
---@return table<personal_rights_id, personal_rights_id>
function DATA.filter_personal_rights_from_realm(realm, func)
    ---@type table<personal_rights_id, personal_rights_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_personal_rights_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type personal_rights_id
        local accessed_element = DCON.dcon_realm_get_index_personal_rights_as_realm(realm - 1, i) + 1
        if DCON.dcon_personal_rights_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param personal_rights_id personal_rights_id valid personal_rights id
---@param value realm_id valid realm_id
function DATA.personal_rights_set_realm(personal_rights_id, value)
    DCON.dcon_personal_rights_set_realm(personal_rights_id - 1, value - 1)
end

local fat_personal_rights_id_metatable = {
    __index = function (t,k)
        if (k == "can_trade") then return DATA.personal_rights_get_can_trade(t.id) end
        if (k == "can_build") then return DATA.personal_rights_get_can_build(t.id) end
        if (k == "person") then return DATA.personal_rights_get_person(t.id) end
        if (k == "realm") then return DATA.personal_rights_get_realm(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "can_trade") then
            DATA.personal_rights_set_can_trade(t.id, v)
            return
        end
        if (k == "can_build") then
            DATA.personal_rights_set_can_build(t.id, v)
            return
        end
        if (k == "person") then
            DATA.personal_rights_set_person(t.id, v)
            return
        end
        if (k == "realm") then
            DATA.personal_rights_set_realm(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id personal_rights_id
---@return fat_personal_rights_id fat_id
function DATA.fatten_personal_rights(id)
    local result = {id = id}
    setmetatable(result, fat_personal_rights_id_metatable)    return result
end
----------realm_provinces----------


---realm_provinces: LSP types---

---Unique identificator for realm_provinces entity
---@class (exact) realm_provinces_id : number
---@field is_realm_provinces nil

---@class (exact) fat_realm_provinces_id
---@field id realm_provinces_id Unique realm_provinces id
---@field province province_id
---@field realm realm_id

---@class struct_realm_provinces


ffi.cdef[[
void dcon_delete_realm_provinces(int32_t j);
int32_t dcon_force_create_realm_provinces(int32_t province, int32_t realm);
void dcon_realm_provinces_set_province(int32_t, int32_t);
int32_t dcon_realm_provinces_get_province(int32_t);
int32_t dcon_province_get_realm_provinces_as_province(int32_t);
void dcon_realm_provinces_set_realm(int32_t, int32_t);
int32_t dcon_realm_provinces_get_realm(int32_t);
int32_t dcon_realm_get_range_realm_provinces_as_realm(int32_t);
int32_t dcon_realm_get_index_realm_provinces_as_realm(int32_t, int32_t);
bool dcon_realm_provinces_is_valid(int32_t);
void dcon_realm_provinces_resize(uint32_t sz);
uint32_t dcon_realm_provinces_size();
]]

---realm_provinces: FFI arrays---

---realm_provinces: LUA bindings---

DATA.realm_provinces_size = 30000
---@param province province_id
---@param realm realm_id
---@return realm_provinces_id
function DATA.force_create_realm_provinces(province, realm)
    ---@type realm_provinces_id
    local i = DCON.dcon_force_create_realm_provinces(province - 1, realm - 1) + 1
    return i --[[@as realm_provinces_id]]
end
---@param i realm_provinces_id
function DATA.delete_realm_provinces(i)
    assert(DCON.dcon_realm_provinces_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_realm_provinces(i - 1)
end
---@param func fun(item: realm_provinces_id)
function DATA.for_each_realm_provinces(func)
    ---@type number
    local range = DCON.dcon_realm_provinces_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_provinces_is_valid(i) then func(i + 1 --[[@as realm_provinces_id]]) end
    end
end
---@param func fun(item: realm_provinces_id):boolean
---@return table<realm_provinces_id, realm_provinces_id>
function DATA.filter_realm_provinces(func)
    ---@type table<realm_provinces_id, realm_provinces_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_provinces_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_provinces_is_valid(i) and func(i + 1 --[[@as realm_provinces_id]]) then t[i + 1 --[[@as realm_provinces_id]]] = t[i + 1 --[[@as realm_provinces_id]]] end
    end
    return t
end

---@param province realm_provinces_id valid province_id
---@return province_id Data retrieved from realm_provinces
function DATA.realm_provinces_get_province(province)
    return DCON.dcon_realm_provinces_get_province(province - 1) + 1
end
---@param province province_id valid province_id
---@return realm_provinces_id realm_provinces
function DATA.get_realm_provinces_from_province(province)
    return DCON.dcon_province_get_realm_provinces_as_province(province - 1) + 1
end
---@param realm_provinces_id realm_provinces_id valid realm_provinces id
---@param value province_id valid province_id
function DATA.realm_provinces_set_province(realm_provinces_id, value)
    DCON.dcon_realm_provinces_set_province(realm_provinces_id - 1, value - 1)
end
---@param realm realm_provinces_id valid realm_id
---@return realm_id Data retrieved from realm_provinces
function DATA.realm_provinces_get_realm(realm)
    return DCON.dcon_realm_provinces_get_realm(realm - 1) + 1
end
---@param realm realm_id valid realm_id
---@return realm_provinces_id[] An array of realm_provinces
function DATA.get_realm_provinces_from_realm(realm)
    local result = {}
    DATA.for_each_realm_provinces_from_realm(realm, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param realm realm_id valid realm_id
---@param func fun(item: realm_provinces_id) valid realm_id
function DATA.for_each_realm_provinces_from_realm(realm, func)
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_provinces_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type realm_provinces_id
        local accessed_element = DCON.dcon_realm_get_index_realm_provinces_as_realm(realm - 1, i) + 1
        if DCON.dcon_realm_provinces_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param realm realm_id valid realm_id
---@param func fun(item: realm_provinces_id):boolean
---@return realm_provinces_id[]
function DATA.filter_array_realm_provinces_from_realm(realm, func)
    ---@type table<realm_provinces_id, realm_provinces_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_provinces_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type realm_provinces_id
        local accessed_element = DCON.dcon_realm_get_index_realm_provinces_as_realm(realm - 1, i) + 1
        if DCON.dcon_realm_provinces_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param realm realm_id valid realm_id
---@param func fun(item: realm_provinces_id):boolean
---@return table<realm_provinces_id, realm_provinces_id>
function DATA.filter_realm_provinces_from_realm(realm, func)
    ---@type table<realm_provinces_id, realm_provinces_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_provinces_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type realm_provinces_id
        local accessed_element = DCON.dcon_realm_get_index_realm_provinces_as_realm(realm - 1, i) + 1
        if DCON.dcon_realm_provinces_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param realm_provinces_id realm_provinces_id valid realm_provinces id
---@param value realm_id valid realm_id
function DATA.realm_provinces_set_realm(realm_provinces_id, value)
    DCON.dcon_realm_provinces_set_realm(realm_provinces_id - 1, value - 1)
end

local fat_realm_provinces_id_metatable = {
    __index = function (t,k)
        if (k == "province") then return DATA.realm_provinces_get_province(t.id) end
        if (k == "realm") then return DATA.realm_provinces_get_realm(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "province") then
            DATA.realm_provinces_set_province(t.id, v)
            return
        end
        if (k == "realm") then
            DATA.realm_provinces_set_realm(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id realm_provinces_id
---@return fat_realm_provinces_id fat_id
function DATA.fatten_realm_provinces(id)
    local result = {id = id}
    setmetatable(result, fat_realm_provinces_id_metatable)    return result
end
----------popularity----------


---popularity: LSP types---

---Unique identificator for popularity entity
---@class (exact) popularity_id : number
---@field is_popularity nil

---@class (exact) fat_popularity_id
---@field id popularity_id Unique popularity id
---@field value number efficiency of this relation
---@field who pop_id
---@field where realm_id popularity where

---@class struct_popularity
---@field value number efficiency of this relation


ffi.cdef[[
void dcon_popularity_set_value(int32_t, float);
float dcon_popularity_get_value(int32_t);
void dcon_delete_popularity(int32_t j);
int32_t dcon_force_create_popularity(int32_t who, int32_t where);
void dcon_popularity_set_who(int32_t, int32_t);
int32_t dcon_popularity_get_who(int32_t);
int32_t dcon_pop_get_range_popularity_as_who(int32_t);
int32_t dcon_pop_get_index_popularity_as_who(int32_t, int32_t);
void dcon_popularity_set_where(int32_t, int32_t);
int32_t dcon_popularity_get_where(int32_t);
int32_t dcon_realm_get_range_popularity_as_where(int32_t);
int32_t dcon_realm_get_index_popularity_as_where(int32_t, int32_t);
bool dcon_popularity_is_valid(int32_t);
void dcon_popularity_resize(uint32_t sz);
uint32_t dcon_popularity_size();
]]

---popularity: FFI arrays---

---popularity: LUA bindings---

DATA.popularity_size = 450000
---@param who pop_id
---@param where realm_id
---@return popularity_id
function DATA.force_create_popularity(who, where)
    ---@type popularity_id
    local i = DCON.dcon_force_create_popularity(who - 1, where - 1) + 1
    return i --[[@as popularity_id]]
end
---@param i popularity_id
function DATA.delete_popularity(i)
    assert(DCON.dcon_popularity_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_popularity(i - 1)
end
---@param func fun(item: popularity_id)
function DATA.for_each_popularity(func)
    ---@type number
    local range = DCON.dcon_popularity_size()
    for i = 0, range - 1 do
        if DCON.dcon_popularity_is_valid(i) then func(i + 1 --[[@as popularity_id]]) end
    end
end
---@param func fun(item: popularity_id):boolean
---@return table<popularity_id, popularity_id>
function DATA.filter_popularity(func)
    ---@type table<popularity_id, popularity_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_popularity_size()
    for i = 0, range - 1 do
        if DCON.dcon_popularity_is_valid(i) and func(i + 1 --[[@as popularity_id]]) then t[i + 1 --[[@as popularity_id]]] = t[i + 1 --[[@as popularity_id]]] end
    end
    return t
end

---@param popularity_id popularity_id valid popularity id
---@return number value efficiency of this relation
function DATA.popularity_get_value(popularity_id)
    return DCON.dcon_popularity_get_value(popularity_id - 1)
end
---@param popularity_id popularity_id valid popularity id
---@param value number valid number
function DATA.popularity_set_value(popularity_id, value)
    DCON.dcon_popularity_set_value(popularity_id - 1, value)
end
---@param popularity_id popularity_id valid popularity id
---@param value number valid number
function DATA.popularity_inc_value(popularity_id, value)
    ---@type number
    local current = DCON.dcon_popularity_get_value(popularity_id - 1)
    DCON.dcon_popularity_set_value(popularity_id - 1, current + value)
end
---@param who popularity_id valid pop_id
---@return pop_id Data retrieved from popularity
function DATA.popularity_get_who(who)
    return DCON.dcon_popularity_get_who(who - 1) + 1
end
---@param who pop_id valid pop_id
---@return popularity_id[] An array of popularity
function DATA.get_popularity_from_who(who)
    local result = {}
    DATA.for_each_popularity_from_who(who, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param who pop_id valid pop_id
---@param func fun(item: popularity_id) valid pop_id
function DATA.for_each_popularity_from_who(who, func)
    ---@type number
    local range = DCON.dcon_pop_get_range_popularity_as_who(who - 1)
    for i = 0, range - 1 do
        ---@type popularity_id
        local accessed_element = DCON.dcon_pop_get_index_popularity_as_who(who - 1, i) + 1
        if DCON.dcon_popularity_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param who pop_id valid pop_id
---@param func fun(item: popularity_id):boolean
---@return popularity_id[]
function DATA.filter_array_popularity_from_who(who, func)
    ---@type table<popularity_id, popularity_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_popularity_as_who(who - 1)
    for i = 0, range - 1 do
        ---@type popularity_id
        local accessed_element = DCON.dcon_pop_get_index_popularity_as_who(who - 1, i) + 1
        if DCON.dcon_popularity_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param who pop_id valid pop_id
---@param func fun(item: popularity_id):boolean
---@return table<popularity_id, popularity_id>
function DATA.filter_popularity_from_who(who, func)
    ---@type table<popularity_id, popularity_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_pop_get_range_popularity_as_who(who - 1)
    for i = 0, range - 1 do
        ---@type popularity_id
        local accessed_element = DCON.dcon_pop_get_index_popularity_as_who(who - 1, i) + 1
        if DCON.dcon_popularity_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param popularity_id popularity_id valid popularity id
---@param value pop_id valid pop_id
function DATA.popularity_set_who(popularity_id, value)
    DCON.dcon_popularity_set_who(popularity_id - 1, value - 1)
end
---@param where popularity_id valid realm_id
---@return realm_id Data retrieved from popularity
function DATA.popularity_get_where(where)
    return DCON.dcon_popularity_get_where(where - 1) + 1
end
---@param where realm_id valid realm_id
---@return popularity_id[] An array of popularity
function DATA.get_popularity_from_where(where)
    local result = {}
    DATA.for_each_popularity_from_where(where, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param where realm_id valid realm_id
---@param func fun(item: popularity_id) valid realm_id
function DATA.for_each_popularity_from_where(where, func)
    ---@type number
    local range = DCON.dcon_realm_get_range_popularity_as_where(where - 1)
    for i = 0, range - 1 do
        ---@type popularity_id
        local accessed_element = DCON.dcon_realm_get_index_popularity_as_where(where - 1, i) + 1
        if DCON.dcon_popularity_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param where realm_id valid realm_id
---@param func fun(item: popularity_id):boolean
---@return popularity_id[]
function DATA.filter_array_popularity_from_where(where, func)
    ---@type table<popularity_id, popularity_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_popularity_as_where(where - 1)
    for i = 0, range - 1 do
        ---@type popularity_id
        local accessed_element = DCON.dcon_realm_get_index_popularity_as_where(where - 1, i) + 1
        if DCON.dcon_popularity_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param where realm_id valid realm_id
---@param func fun(item: popularity_id):boolean
---@return table<popularity_id, popularity_id>
function DATA.filter_popularity_from_where(where, func)
    ---@type table<popularity_id, popularity_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_popularity_as_where(where - 1)
    for i = 0, range - 1 do
        ---@type popularity_id
        local accessed_element = DCON.dcon_realm_get_index_popularity_as_where(where - 1, i) + 1
        if DCON.dcon_popularity_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param popularity_id popularity_id valid popularity id
---@param value realm_id valid realm_id
function DATA.popularity_set_where(popularity_id, value)
    DCON.dcon_popularity_set_where(popularity_id - 1, value - 1)
end

local fat_popularity_id_metatable = {
    __index = function (t,k)
        if (k == "value") then return DATA.popularity_get_value(t.id) end
        if (k == "who") then return DATA.popularity_get_who(t.id) end
        if (k == "where") then return DATA.popularity_get_where(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "value") then
            DATA.popularity_set_value(t.id, v)
            return
        end
        if (k == "who") then
            DATA.popularity_set_who(t.id, v)
            return
        end
        if (k == "where") then
            DATA.popularity_set_where(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id popularity_id
---@return fat_popularity_id fat_id
function DATA.fatten_popularity(id)
    local result = {id = id}
    setmetatable(result, fat_popularity_id_metatable)    return result
end
----------realm_pop----------


---realm_pop: LSP types---

---Unique identificator for realm_pop entity
---@class (exact) realm_pop_id : number
---@field is_realm_pop nil

---@class (exact) fat_realm_pop_id
---@field id realm_pop_id Unique realm_pop id
---@field realm realm_id Represents the home realm of the character
---@field pop pop_id

---@class struct_realm_pop


ffi.cdef[[
void dcon_delete_realm_pop(int32_t j);
int32_t dcon_force_create_realm_pop(int32_t realm, int32_t pop);
void dcon_realm_pop_set_realm(int32_t, int32_t);
int32_t dcon_realm_pop_get_realm(int32_t);
int32_t dcon_realm_get_range_realm_pop_as_realm(int32_t);
int32_t dcon_realm_get_index_realm_pop_as_realm(int32_t, int32_t);
void dcon_realm_pop_set_pop(int32_t, int32_t);
int32_t dcon_realm_pop_get_pop(int32_t);
int32_t dcon_pop_get_realm_pop_as_pop(int32_t);
bool dcon_realm_pop_is_valid(int32_t);
void dcon_realm_pop_resize(uint32_t sz);
uint32_t dcon_realm_pop_size();
]]

---realm_pop: FFI arrays---

---realm_pop: LUA bindings---

DATA.realm_pop_size = 300000
---@param realm realm_id
---@param pop pop_id
---@return realm_pop_id
function DATA.force_create_realm_pop(realm, pop)
    ---@type realm_pop_id
    local i = DCON.dcon_force_create_realm_pop(realm - 1, pop - 1) + 1
    return i --[[@as realm_pop_id]]
end
---@param i realm_pop_id
function DATA.delete_realm_pop(i)
    assert(DCON.dcon_realm_pop_is_valid(i - 1), " ATTEMPT TO DELETE INVALID OBJECT ")
    return DCON.dcon_delete_realm_pop(i - 1)
end
---@param func fun(item: realm_pop_id)
function DATA.for_each_realm_pop(func)
    ---@type number
    local range = DCON.dcon_realm_pop_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_pop_is_valid(i) then func(i + 1 --[[@as realm_pop_id]]) end
    end
end
---@param func fun(item: realm_pop_id):boolean
---@return table<realm_pop_id, realm_pop_id>
function DATA.filter_realm_pop(func)
    ---@type table<realm_pop_id, realm_pop_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_pop_size()
    for i = 0, range - 1 do
        if DCON.dcon_realm_pop_is_valid(i) and func(i + 1 --[[@as realm_pop_id]]) then t[i + 1 --[[@as realm_pop_id]]] = t[i + 1 --[[@as realm_pop_id]]] end
    end
    return t
end

---@param realm realm_pop_id valid realm_id
---@return realm_id Data retrieved from realm_pop
function DATA.realm_pop_get_realm(realm)
    return DCON.dcon_realm_pop_get_realm(realm - 1) + 1
end
---@param realm realm_id valid realm_id
---@return realm_pop_id[] An array of realm_pop
function DATA.get_realm_pop_from_realm(realm)
    local result = {}
    DATA.for_each_realm_pop_from_realm(realm, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param realm realm_id valid realm_id
---@param func fun(item: realm_pop_id) valid realm_id
function DATA.for_each_realm_pop_from_realm(realm, func)
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_pop_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type realm_pop_id
        local accessed_element = DCON.dcon_realm_get_index_realm_pop_as_realm(realm - 1, i) + 1
        if DCON.dcon_realm_pop_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param realm realm_id valid realm_id
---@param func fun(item: realm_pop_id):boolean
---@return realm_pop_id[]
function DATA.filter_array_realm_pop_from_realm(realm, func)
    ---@type table<realm_pop_id, realm_pop_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_pop_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type realm_pop_id
        local accessed_element = DCON.dcon_realm_get_index_realm_pop_as_realm(realm - 1, i) + 1
        if DCON.dcon_realm_pop_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param realm realm_id valid realm_id
---@param func fun(item: realm_pop_id):boolean
---@return table<realm_pop_id, realm_pop_id>
function DATA.filter_realm_pop_from_realm(realm, func)
    ---@type table<realm_pop_id, realm_pop_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_realm_get_range_realm_pop_as_realm(realm - 1)
    for i = 0, range - 1 do
        ---@type realm_pop_id
        local accessed_element = DCON.dcon_realm_get_index_realm_pop_as_realm(realm - 1, i) + 1
        if DCON.dcon_realm_pop_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param realm_pop_id realm_pop_id valid realm_pop id
---@param value realm_id valid realm_id
function DATA.realm_pop_set_realm(realm_pop_id, value)
    DCON.dcon_realm_pop_set_realm(realm_pop_id - 1, value - 1)
end
---@param pop realm_pop_id valid pop_id
---@return pop_id Data retrieved from realm_pop
function DATA.realm_pop_get_pop(pop)
    return DCON.dcon_realm_pop_get_pop(pop - 1) + 1
end
---@param pop pop_id valid pop_id
---@return realm_pop_id realm_pop
function DATA.get_realm_pop_from_pop(pop)
    return DCON.dcon_pop_get_realm_pop_as_pop(pop - 1) + 1
end
---@param realm_pop_id realm_pop_id valid realm_pop id
---@param value pop_id valid pop_id
function DATA.realm_pop_set_pop(realm_pop_id, value)
    DCON.dcon_realm_pop_set_pop(realm_pop_id - 1, value - 1)
end

local fat_realm_pop_id_metatable = {
    __index = function (t,k)
        if (k == "realm") then return DATA.realm_pop_get_realm(t.id) end
        if (k == "pop") then return DATA.realm_pop_get_pop(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "realm") then
            DATA.realm_pop_set_realm(t.id, v)
            return
        end
        if (k == "pop") then
            DATA.realm_pop_set_pop(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id realm_pop_id
---@return fat_realm_pop_id fat_id
function DATA.fatten_realm_pop(id)
    local result = {id = id}
    setmetatable(result, fat_realm_pop_id_metatable)    return result
end
----------jobtype----------


---jobtype: LSP types---

---Unique identificator for jobtype entity
---@class (exact) jobtype_id : number
---@field is_jobtype nil

---@class (exact) fat_jobtype_id
---@field id jobtype_id Unique jobtype id
---@field name string
---@field action_word string

---@class struct_jobtype

---@class (exact) jobtype_id_data_blob_definition
---@field name string
---@field action_word string
---Sets values of jobtype for given id
---@param id jobtype_id
---@param data jobtype_id_data_blob_definition
function DATA.setup_jobtype(id, data)
    DATA.jobtype_set_name(id, data.name)
    DATA.jobtype_set_action_word(id, data.action_word)
end

ffi.cdef[[
int32_t dcon_create_jobtype();
bool dcon_jobtype_is_valid(int32_t);
void dcon_jobtype_resize(uint32_t sz);
uint32_t dcon_jobtype_size();
]]

---jobtype: FFI arrays---
---@type (string)[]
DATA.jobtype_name= {}
---@type (string)[]
DATA.jobtype_action_word= {}

---jobtype: LUA bindings---

DATA.jobtype_size = 10
---@return jobtype_id
function DATA.create_jobtype()
    ---@type jobtype_id
    local i  = DCON.dcon_create_jobtype() + 1
    return i --[[@as jobtype_id]]
end
---@param func fun(item: jobtype_id)
function DATA.for_each_jobtype(func)
    ---@type number
    local range = DCON.dcon_jobtype_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as jobtype_id]])
    end
end
---@param func fun(item: jobtype_id):boolean
---@return table<jobtype_id, jobtype_id>
function DATA.filter_jobtype(func)
    ---@type table<jobtype_id, jobtype_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_jobtype_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as jobtype_id]]) then t[i + 1 --[[@as jobtype_id]]] = t[i + 1 --[[@as jobtype_id]]] end
    end
    return t
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
---@param jobtype_id jobtype_id valid jobtype id
---@return string action_word
function DATA.jobtype_get_action_word(jobtype_id)
    return DATA.jobtype_action_word[jobtype_id]
end
---@param jobtype_id jobtype_id valid jobtype id
---@param value string valid string
function DATA.jobtype_set_action_word(jobtype_id, value)
    DATA.jobtype_action_word[jobtype_id] = value
end

local fat_jobtype_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.jobtype_get_name(t.id) end
        if (k == "action_word") then return DATA.jobtype_get_action_word(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.jobtype_set_name(t.id, v)
            return
        end
        if (k == "action_word") then
            DATA.jobtype_set_action_word(t.id, v)
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
DATA.jobtype_set_action_word(index_jobtype, "foraging")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "FARMER")
DATA.jobtype_set_action_word(index_jobtype, "farming")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "LABOURER")
DATA.jobtype_set_action_word(index_jobtype, "labouring")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "ARTISAN")
DATA.jobtype_set_action_word(index_jobtype, "artisianship")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "CLERK")
DATA.jobtype_set_action_word(index_jobtype, "recalling")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "WARRIOR")
DATA.jobtype_set_action_word(index_jobtype, "fighting")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "HAULING")
DATA.jobtype_set_action_word(index_jobtype, "hauling")
index_jobtype = DATA.create_jobtype()
DATA.jobtype_set_name(index_jobtype, "HUNTING")
DATA.jobtype_set_action_word(index_jobtype, "hunting")
----------need----------


---need: LSP types---

---Unique identificator for need entity
---@class (exact) need_id : number
---@field is_need nil

---@class (exact) fat_need_id
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
void dcon_need_set_age_independent(int32_t, bool);
bool dcon_need_get_age_independent(int32_t);
void dcon_need_set_life_need(int32_t, bool);
bool dcon_need_get_life_need(int32_t);
void dcon_need_set_tool(int32_t, bool);
bool dcon_need_get_tool(int32_t);
void dcon_need_set_container(int32_t, bool);
bool dcon_need_get_container(int32_t);
void dcon_need_set_time_to_satisfy(int32_t, float);
float dcon_need_get_time_to_satisfy(int32_t);
void dcon_need_set_job_to_satisfy(int32_t, uint8_t);
uint8_t dcon_need_get_job_to_satisfy(int32_t);
int32_t dcon_create_need();
bool dcon_need_is_valid(int32_t);
void dcon_need_resize(uint32_t sz);
uint32_t dcon_need_size();
]]

---need: FFI arrays---
---@type (string)[]
DATA.need_name= {}

---need: LUA bindings---

DATA.need_size = 9
---@return need_id
function DATA.create_need()
    ---@type need_id
    local i  = DCON.dcon_create_need() + 1
    return i --[[@as need_id]]
end
---@param func fun(item: need_id)
function DATA.for_each_need(func)
    ---@type number
    local range = DCON.dcon_need_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as need_id]])
    end
end
---@param func fun(item: need_id):boolean
---@return table<need_id, need_id>
function DATA.filter_need(func)
    ---@type table<need_id, need_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_need_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as need_id]]) then t[i + 1 --[[@as need_id]]] = t[i + 1 --[[@as need_id]]] end
    end
    return t
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
    return DCON.dcon_need_get_age_independent(need_id - 1)
end
---@param need_id need_id valid need id
---@param value boolean valid boolean
function DATA.need_set_age_independent(need_id, value)
    DCON.dcon_need_set_age_independent(need_id - 1, value)
end
---@param need_id need_id valid need id
---@return boolean life_need
function DATA.need_get_life_need(need_id)
    return DCON.dcon_need_get_life_need(need_id - 1)
end
---@param need_id need_id valid need id
---@param value boolean valid boolean
function DATA.need_set_life_need(need_id, value)
    DCON.dcon_need_set_life_need(need_id - 1, value)
end
---@param need_id need_id valid need id
---@return boolean tool can we use satisfaction of this need in calculations related to production
function DATA.need_get_tool(need_id)
    return DCON.dcon_need_get_tool(need_id - 1)
end
---@param need_id need_id valid need id
---@param value boolean valid boolean
function DATA.need_set_tool(need_id, value)
    DCON.dcon_need_set_tool(need_id - 1, value)
end
---@param need_id need_id valid need id
---@return boolean container can we use satisfaction of this need in calculations related to gathering
function DATA.need_get_container(need_id)
    return DCON.dcon_need_get_container(need_id - 1)
end
---@param need_id need_id valid need id
---@param value boolean valid boolean
function DATA.need_set_container(need_id, value)
    DCON.dcon_need_set_container(need_id - 1, value)
end
---@param need_id need_id valid need id
---@return number time_to_satisfy Represents amount of time a pop should spend to satisfy a unit of this need.
function DATA.need_get_time_to_satisfy(need_id)
    return DCON.dcon_need_get_time_to_satisfy(need_id - 1)
end
---@param need_id need_id valid need id
---@param value number valid number
function DATA.need_set_time_to_satisfy(need_id, value)
    DCON.dcon_need_set_time_to_satisfy(need_id - 1, value)
end
---@param need_id need_id valid need id
---@param value number valid number
function DATA.need_inc_time_to_satisfy(need_id, value)
    ---@type number
    local current = DCON.dcon_need_get_time_to_satisfy(need_id - 1)
    DCON.dcon_need_set_time_to_satisfy(need_id - 1, current + value)
end
---@param need_id need_id valid need id
---@return JOBTYPE job_to_satisfy represents a job type required to satisfy the need on your own
function DATA.need_get_job_to_satisfy(need_id)
    return DCON.dcon_need_get_job_to_satisfy(need_id - 1)
end
---@param need_id need_id valid need id
---@param value JOBTYPE valid JOBTYPE
function DATA.need_set_job_to_satisfy(need_id, value)
    DCON.dcon_need_set_job_to_satisfy(need_id - 1, value)
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
---@class (exact) character_rank_id : number
---@field is_character_rank nil

---@class (exact) fat_character_rank_id
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
int32_t dcon_create_character_rank();
bool dcon_character_rank_is_valid(int32_t);
void dcon_character_rank_resize(uint32_t sz);
uint32_t dcon_character_rank_size();
]]

---character_rank: FFI arrays---
---@type (string)[]
DATA.character_rank_name= {}
---@type (string)[]
DATA.character_rank_localisation= {}

---character_rank: LUA bindings---

DATA.character_rank_size = 5
---@return character_rank_id
function DATA.create_character_rank()
    ---@type character_rank_id
    local i  = DCON.dcon_create_character_rank() + 1
    return i --[[@as character_rank_id]]
end
---@param func fun(item: character_rank_id)
function DATA.for_each_character_rank(func)
    ---@type number
    local range = DCON.dcon_character_rank_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as character_rank_id]])
    end
end
---@param func fun(item: character_rank_id):boolean
---@return table<character_rank_id, character_rank_id>
function DATA.filter_character_rank(func)
    ---@type table<character_rank_id, character_rank_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_character_rank_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as character_rank_id]]) then t[i + 1 --[[@as character_rank_id]]] = t[i + 1 --[[@as character_rank_id]]] end
    end
    return t
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
---@class (exact) trait_id : number
---@field is_trait nil

---@class (exact) fat_trait_id
---@field id trait_id Unique trait id
---@field name string
---@field ambition number
---@field greed number
---@field admin number
---@field traveller number
---@field aggression number
---@field short_description string
---@field full_description string
---@field icon string

---@class struct_trait
---@field ambition number
---@field greed number
---@field admin number
---@field traveller number
---@field aggression number

---@class (exact) trait_id_data_blob_definition
---@field name string
---@field ambition number
---@field greed number
---@field admin number
---@field traveller number
---@field aggression number
---@field short_description string
---@field full_description string
---@field icon string
---Sets values of trait for given id
---@param id trait_id
---@param data trait_id_data_blob_definition
function DATA.setup_trait(id, data)
    DATA.trait_set_name(id, data.name)
    DATA.trait_set_ambition(id, data.ambition)
    DATA.trait_set_greed(id, data.greed)
    DATA.trait_set_admin(id, data.admin)
    DATA.trait_set_traveller(id, data.traveller)
    DATA.trait_set_aggression(id, data.aggression)
    DATA.trait_set_short_description(id, data.short_description)
    DATA.trait_set_full_description(id, data.full_description)
    DATA.trait_set_icon(id, data.icon)
end

ffi.cdef[[
void dcon_trait_set_ambition(int32_t, float);
float dcon_trait_get_ambition(int32_t);
void dcon_trait_set_greed(int32_t, float);
float dcon_trait_get_greed(int32_t);
void dcon_trait_set_admin(int32_t, float);
float dcon_trait_get_admin(int32_t);
void dcon_trait_set_traveller(int32_t, float);
float dcon_trait_get_traveller(int32_t);
void dcon_trait_set_aggression(int32_t, float);
float dcon_trait_get_aggression(int32_t);
int32_t dcon_create_trait();
bool dcon_trait_is_valid(int32_t);
void dcon_trait_resize(uint32_t sz);
uint32_t dcon_trait_size();
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

---trait: LUA bindings---

DATA.trait_size = 12
---@return trait_id
function DATA.create_trait()
    ---@type trait_id
    local i  = DCON.dcon_create_trait() + 1
    return i --[[@as trait_id]]
end
---@param func fun(item: trait_id)
function DATA.for_each_trait(func)
    ---@type number
    local range = DCON.dcon_trait_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as trait_id]])
    end
end
---@param func fun(item: trait_id):boolean
---@return table<trait_id, trait_id>
function DATA.filter_trait(func)
    ---@type table<trait_id, trait_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_trait_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as trait_id]]) then t[i + 1 --[[@as trait_id]]] = t[i + 1 --[[@as trait_id]]] end
    end
    return t
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
---@return number ambition
function DATA.trait_get_ambition(trait_id)
    return DCON.dcon_trait_get_ambition(trait_id - 1)
end
---@param trait_id trait_id valid trait id
---@param value number valid number
function DATA.trait_set_ambition(trait_id, value)
    DCON.dcon_trait_set_ambition(trait_id - 1, value)
end
---@param trait_id trait_id valid trait id
---@param value number valid number
function DATA.trait_inc_ambition(trait_id, value)
    ---@type number
    local current = DCON.dcon_trait_get_ambition(trait_id - 1)
    DCON.dcon_trait_set_ambition(trait_id - 1, current + value)
end
---@param trait_id trait_id valid trait id
---@return number greed
function DATA.trait_get_greed(trait_id)
    return DCON.dcon_trait_get_greed(trait_id - 1)
end
---@param trait_id trait_id valid trait id
---@param value number valid number
function DATA.trait_set_greed(trait_id, value)
    DCON.dcon_trait_set_greed(trait_id - 1, value)
end
---@param trait_id trait_id valid trait id
---@param value number valid number
function DATA.trait_inc_greed(trait_id, value)
    ---@type number
    local current = DCON.dcon_trait_get_greed(trait_id - 1)
    DCON.dcon_trait_set_greed(trait_id - 1, current + value)
end
---@param trait_id trait_id valid trait id
---@return number admin
function DATA.trait_get_admin(trait_id)
    return DCON.dcon_trait_get_admin(trait_id - 1)
end
---@param trait_id trait_id valid trait id
---@param value number valid number
function DATA.trait_set_admin(trait_id, value)
    DCON.dcon_trait_set_admin(trait_id - 1, value)
end
---@param trait_id trait_id valid trait id
---@param value number valid number
function DATA.trait_inc_admin(trait_id, value)
    ---@type number
    local current = DCON.dcon_trait_get_admin(trait_id - 1)
    DCON.dcon_trait_set_admin(trait_id - 1, current + value)
end
---@param trait_id trait_id valid trait id
---@return number traveller
function DATA.trait_get_traveller(trait_id)
    return DCON.dcon_trait_get_traveller(trait_id - 1)
end
---@param trait_id trait_id valid trait id
---@param value number valid number
function DATA.trait_set_traveller(trait_id, value)
    DCON.dcon_trait_set_traveller(trait_id - 1, value)
end
---@param trait_id trait_id valid trait id
---@param value number valid number
function DATA.trait_inc_traveller(trait_id, value)
    ---@type number
    local current = DCON.dcon_trait_get_traveller(trait_id - 1)
    DCON.dcon_trait_set_traveller(trait_id - 1, current + value)
end
---@param trait_id trait_id valid trait id
---@return number aggression
function DATA.trait_get_aggression(trait_id)
    return DCON.dcon_trait_get_aggression(trait_id - 1)
end
---@param trait_id trait_id valid trait id
---@param value number valid number
function DATA.trait_set_aggression(trait_id, value)
    DCON.dcon_trait_set_aggression(trait_id - 1, value)
end
---@param trait_id trait_id valid trait id
---@param value number valid number
function DATA.trait_inc_aggression(trait_id, value)
    ---@type number
    local current = DCON.dcon_trait_get_aggression(trait_id - 1)
    DCON.dcon_trait_set_aggression(trait_id - 1, current + value)
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
        if (k == "ambition") then return DATA.trait_get_ambition(t.id) end
        if (k == "greed") then return DATA.trait_get_greed(t.id) end
        if (k == "admin") then return DATA.trait_get_admin(t.id) end
        if (k == "traveller") then return DATA.trait_get_traveller(t.id) end
        if (k == "aggression") then return DATA.trait_get_aggression(t.id) end
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
        if (k == "ambition") then
            DATA.trait_set_ambition(t.id, v)
            return
        end
        if (k == "greed") then
            DATA.trait_set_greed(t.id, v)
            return
        end
        if (k == "admin") then
            DATA.trait_set_admin(t.id, v)
            return
        end
        if (k == "traveller") then
            DATA.trait_set_traveller(t.id, v)
            return
        end
        if (k == "aggression") then
            DATA.trait_set_aggression(t.id, v)
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
DATA.trait_set_ambition(index_trait, 1)
DATA.trait_set_greed(index_trait, 0.05)
DATA.trait_set_admin(index_trait, 0)
DATA.trait_set_traveller(index_trait, 0)
DATA.trait_set_aggression(index_trait, 0.2)
DATA.trait_set_short_description(index_trait, "ambitious")
DATA.trait_set_full_description(index_trait, "TODO")
DATA.trait_set_icon(index_trait, "mountaintop.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "CONTENT")
DATA.trait_set_ambition(index_trait, -0.5)
DATA.trait_set_greed(index_trait, 0)
DATA.trait_set_admin(index_trait, 0)
DATA.trait_set_traveller(index_trait, 0)
DATA.trait_set_aggression(index_trait, -0.1)
DATA.trait_set_short_description(index_trait, "content")
DATA.trait_set_full_description(index_trait, "This person has no ambitions: it would be hard to persuade them to change occupation")
DATA.trait_set_icon(index_trait, "inner-self.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "LOYAL")
DATA.trait_set_ambition(index_trait, -0.02)
DATA.trait_set_greed(index_trait, 0)
DATA.trait_set_admin(index_trait, 0)
DATA.trait_set_traveller(index_trait, 0)
DATA.trait_set_aggression(index_trait, 0)
DATA.trait_set_short_description(index_trait, "loyal")
DATA.trait_set_full_description(index_trait, "This person rarely betrays people")
DATA.trait_set_icon(index_trait, "check-mark.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "GREEDY")
DATA.trait_set_ambition(index_trait, 0)
DATA.trait_set_greed(index_trait, 0.5)
DATA.trait_set_admin(index_trait, 0)
DATA.trait_set_traveller(index_trait, 0)
DATA.trait_set_aggression(index_trait, 0)
DATA.trait_set_short_description(index_trait, "greedy")
DATA.trait_set_full_description(index_trait, "Desire for money drives this person's actions")
DATA.trait_set_icon(index_trait, "receive-money.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "WARLIKE")
DATA.trait_set_ambition(index_trait, 0.1)
DATA.trait_set_greed(index_trait, 0)
DATA.trait_set_admin(index_trait, 0)
DATA.trait_set_traveller(index_trait, 0)
DATA.trait_set_aggression(index_trait, 1)
DATA.trait_set_short_description(index_trait, "warlike")
DATA.trait_set_full_description(index_trait, "TODO")
DATA.trait_set_icon(index_trait, "barbute.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "BAD_ORGANISER")
DATA.trait_set_ambition(index_trait, 0)
DATA.trait_set_greed(index_trait, 0)
DATA.trait_set_admin(index_trait, -0.2)
DATA.trait_set_traveller(index_trait, 0)
DATA.trait_set_aggression(index_trait, 0)
DATA.trait_set_short_description(index_trait, "bad organiser")
DATA.trait_set_full_description(index_trait, "TODO")
DATA.trait_set_icon(index_trait, "shrug.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "GOOD_ORGANISER")
DATA.trait_set_ambition(index_trait, 0.01)
DATA.trait_set_greed(index_trait, 0)
DATA.trait_set_admin(index_trait, 0.2)
DATA.trait_set_traveller(index_trait, 0)
DATA.trait_set_aggression(index_trait, 0)
DATA.trait_set_short_description(index_trait, "good organiser")
DATA.trait_set_full_description(index_trait, "TODO")
DATA.trait_set_icon(index_trait, "pitchfork.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "LAZY")
DATA.trait_set_ambition(index_trait, -0.5)
DATA.trait_set_greed(index_trait, 0)
DATA.trait_set_admin(index_trait, -0.1)
DATA.trait_set_traveller(index_trait, 0)
DATA.trait_set_aggression(index_trait, -0.1)
DATA.trait_set_short_description(index_trait, "lazy")
DATA.trait_set_full_description(index_trait, "This person prefers to do nothing")
DATA.trait_set_icon(index_trait, "parmecia.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "HARDWORKER")
DATA.trait_set_ambition(index_trait, 0.01)
DATA.trait_set_greed(index_trait, 0)
DATA.trait_set_admin(index_trait, 0.1)
DATA.trait_set_traveller(index_trait, 0)
DATA.trait_set_aggression(index_trait, 0)
DATA.trait_set_short_description(index_trait, "hard worker")
DATA.trait_set_full_description(index_trait, "TODO")
DATA.trait_set_icon(index_trait, "miner.png")
index_trait = DATA.create_trait()
DATA.trait_set_name(index_trait, "TRADER")
DATA.trait_set_ambition(index_trait, -0.5)
DATA.trait_set_greed(index_trait, 0.2)
DATA.trait_set_admin(index_trait, 0.05)
DATA.trait_set_traveller(index_trait, 1)
DATA.trait_set_aggression(index_trait, -0.1)
DATA.trait_set_short_description(index_trait, "trader")
DATA.trait_set_full_description(index_trait, "TODO")
DATA.trait_set_icon(index_trait, "scales.png")
----------trade_good_category----------


---trade_good_category: LSP types---

---Unique identificator for trade_good_category entity
---@class (exact) trade_good_category_id : number
---@field is_trade_good_category nil

---@class (exact) fat_trade_good_category_id
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
int32_t dcon_create_trade_good_category();
bool dcon_trade_good_category_is_valid(int32_t);
void dcon_trade_good_category_resize(uint32_t sz);
uint32_t dcon_trade_good_category_size();
]]

---trade_good_category: FFI arrays---
---@type (string)[]
DATA.trade_good_category_name= {}

---trade_good_category: LUA bindings---

DATA.trade_good_category_size = 5
---@return trade_good_category_id
function DATA.create_trade_good_category()
    ---@type trade_good_category_id
    local i  = DCON.dcon_create_trade_good_category() + 1
    return i --[[@as trade_good_category_id]]
end
---@param func fun(item: trade_good_category_id)
function DATA.for_each_trade_good_category(func)
    ---@type number
    local range = DCON.dcon_trade_good_category_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as trade_good_category_id]])
    end
end
---@param func fun(item: trade_good_category_id):boolean
---@return table<trade_good_category_id, trade_good_category_id>
function DATA.filter_trade_good_category(func)
    ---@type table<trade_good_category_id, trade_good_category_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_trade_good_category_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as trade_good_category_id]]) then t[i + 1 --[[@as trade_good_category_id]]] = t[i + 1 --[[@as trade_good_category_id]]] end
    end
    return t
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
---@class (exact) warband_status_id : number
---@field is_warband_status nil

---@class (exact) fat_warband_status_id
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
int32_t dcon_create_warband_status();
bool dcon_warband_status_is_valid(int32_t);
void dcon_warband_status_resize(uint32_t sz);
uint32_t dcon_warband_status_size();
]]

---warband_status: FFI arrays---
---@type (string)[]
DATA.warband_status_name= {}

---warband_status: LUA bindings---

DATA.warband_status_size = 10
---@return warband_status_id
function DATA.create_warband_status()
    ---@type warband_status_id
    local i  = DCON.dcon_create_warband_status() + 1
    return i --[[@as warband_status_id]]
end
---@param func fun(item: warband_status_id)
function DATA.for_each_warband_status(func)
    ---@type number
    local range = DCON.dcon_warband_status_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as warband_status_id]])
    end
end
---@param func fun(item: warband_status_id):boolean
---@return table<warband_status_id, warband_status_id>
function DATA.filter_warband_status(func)
    ---@type table<warband_status_id, warband_status_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_warband_status_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as warband_status_id]]) then t[i + 1 --[[@as warband_status_id]]] = t[i + 1 --[[@as warband_status_id]]] end
    end
    return t
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
---@class (exact) warband_stance_id : number
---@field is_warband_stance nil

---@class (exact) fat_warband_stance_id
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
int32_t dcon_create_warband_stance();
bool dcon_warband_stance_is_valid(int32_t);
void dcon_warband_stance_resize(uint32_t sz);
uint32_t dcon_warband_stance_size();
]]

---warband_stance: FFI arrays---
---@type (string)[]
DATA.warband_stance_name= {}

---warband_stance: LUA bindings---

DATA.warband_stance_size = 4
---@return warband_stance_id
function DATA.create_warband_stance()
    ---@type warband_stance_id
    local i  = DCON.dcon_create_warband_stance() + 1
    return i --[[@as warband_stance_id]]
end
---@param func fun(item: warband_stance_id)
function DATA.for_each_warband_stance(func)
    ---@type number
    local range = DCON.dcon_warband_stance_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as warband_stance_id]])
    end
end
---@param func fun(item: warband_stance_id):boolean
---@return table<warband_stance_id, warband_stance_id>
function DATA.filter_warband_stance(func)
    ---@type table<warband_stance_id, warband_stance_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_warband_stance_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as warband_stance_id]]) then t[i + 1 --[[@as warband_stance_id]]] = t[i + 1 --[[@as warband_stance_id]]] end
    end
    return t
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
----------building_archetype----------


---building_archetype: LSP types---

---Unique identificator for building_archetype entity
---@class (exact) building_archetype_id : number
---@field is_building_archetype nil

---@class (exact) fat_building_archetype_id
---@field id building_archetype_id Unique building_archetype id
---@field name string

---@class struct_building_archetype

---@class (exact) building_archetype_id_data_blob_definition
---@field name string
---Sets values of building_archetype for given id
---@param id building_archetype_id
---@param data building_archetype_id_data_blob_definition
function DATA.setup_building_archetype(id, data)
    DATA.building_archetype_set_name(id, data.name)
end

ffi.cdef[[
int32_t dcon_create_building_archetype();
bool dcon_building_archetype_is_valid(int32_t);
void dcon_building_archetype_resize(uint32_t sz);
uint32_t dcon_building_archetype_size();
]]

---building_archetype: FFI arrays---
---@type (string)[]
DATA.building_archetype_name= {}

---building_archetype: LUA bindings---

DATA.building_archetype_size = 7
---@return building_archetype_id
function DATA.create_building_archetype()
    ---@type building_archetype_id
    local i  = DCON.dcon_create_building_archetype() + 1
    return i --[[@as building_archetype_id]]
end
---@param func fun(item: building_archetype_id)
function DATA.for_each_building_archetype(func)
    ---@type number
    local range = DCON.dcon_building_archetype_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as building_archetype_id]])
    end
end
---@param func fun(item: building_archetype_id):boolean
---@return table<building_archetype_id, building_archetype_id>
function DATA.filter_building_archetype(func)
    ---@type table<building_archetype_id, building_archetype_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_building_archetype_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as building_archetype_id]]) then t[i + 1 --[[@as building_archetype_id]]] = t[i + 1 --[[@as building_archetype_id]]] end
    end
    return t
end

---@param building_archetype_id building_archetype_id valid building_archetype id
---@return string name
function DATA.building_archetype_get_name(building_archetype_id)
    return DATA.building_archetype_name[building_archetype_id]
end
---@param building_archetype_id building_archetype_id valid building_archetype id
---@param value string valid string
function DATA.building_archetype_set_name(building_archetype_id, value)
    DATA.building_archetype_name[building_archetype_id] = value
end

local fat_building_archetype_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.building_archetype_get_name(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.building_archetype_set_name(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id building_archetype_id
---@return fat_building_archetype_id fat_id
function DATA.fatten_building_archetype(id)
    local result = {id = id}
    setmetatable(result, fat_building_archetype_id_metatable)    return result
end
---@enum BUILDING_ARCHETYPE
BUILDING_ARCHETYPE = {
    INVALID = 0,
    GROUNDS = 1,
    FARM = 2,
    MINE = 3,
    WORKSHOP = 4,
    DEFENSE = 5,
}
local index_building_archetype
index_building_archetype = DATA.create_building_archetype()
DATA.building_archetype_set_name(index_building_archetype, "GROUNDS")
index_building_archetype = DATA.create_building_archetype()
DATA.building_archetype_set_name(index_building_archetype, "FARM")
index_building_archetype = DATA.create_building_archetype()
DATA.building_archetype_set_name(index_building_archetype, "MINE")
index_building_archetype = DATA.create_building_archetype()
DATA.building_archetype_set_name(index_building_archetype, "WORKSHOP")
index_building_archetype = DATA.create_building_archetype()
DATA.building_archetype_set_name(index_building_archetype, "DEFENSE")
----------forage_resource----------


---forage_resource: LSP types---

---Unique identificator for forage_resource entity
---@class (exact) forage_resource_id : number
---@field is_forage_resource nil

---@class (exact) fat_forage_resource_id
---@field id forage_resource_id Unique forage_resource id
---@field name string
---@field description string
---@field icon string
---@field handle JOBTYPE

---@class struct_forage_resource
---@field handle JOBTYPE

---@class (exact) forage_resource_id_data_blob_definition
---@field name string
---@field description string
---@field icon string
---@field handle JOBTYPE
---Sets values of forage_resource for given id
---@param id forage_resource_id
---@param data forage_resource_id_data_blob_definition
function DATA.setup_forage_resource(id, data)
    DATA.forage_resource_set_name(id, data.name)
    DATA.forage_resource_set_description(id, data.description)
    DATA.forage_resource_set_icon(id, data.icon)
    DATA.forage_resource_set_handle(id, data.handle)
end

ffi.cdef[[
void dcon_forage_resource_set_handle(int32_t, uint8_t);
uint8_t dcon_forage_resource_get_handle(int32_t);
int32_t dcon_create_forage_resource();
bool dcon_forage_resource_is_valid(int32_t);
void dcon_forage_resource_resize(uint32_t sz);
uint32_t dcon_forage_resource_size();
]]

---forage_resource: FFI arrays---
---@type (string)[]
DATA.forage_resource_name= {}
---@type (string)[]
DATA.forage_resource_description= {}
---@type (string)[]
DATA.forage_resource_icon= {}

---forage_resource: LUA bindings---

DATA.forage_resource_size = 10
---@return forage_resource_id
function DATA.create_forage_resource()
    ---@type forage_resource_id
    local i  = DCON.dcon_create_forage_resource() + 1
    return i --[[@as forage_resource_id]]
end
---@param func fun(item: forage_resource_id)
function DATA.for_each_forage_resource(func)
    ---@type number
    local range = DCON.dcon_forage_resource_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as forage_resource_id]])
    end
end
---@param func fun(item: forage_resource_id):boolean
---@return table<forage_resource_id, forage_resource_id>
function DATA.filter_forage_resource(func)
    ---@type table<forage_resource_id, forage_resource_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_forage_resource_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as forage_resource_id]]) then t[i + 1 --[[@as forage_resource_id]]] = t[i + 1 --[[@as forage_resource_id]]] end
    end
    return t
end

---@param forage_resource_id forage_resource_id valid forage_resource id
---@return string name
function DATA.forage_resource_get_name(forage_resource_id)
    return DATA.forage_resource_name[forage_resource_id]
end
---@param forage_resource_id forage_resource_id valid forage_resource id
---@param value string valid string
function DATA.forage_resource_set_name(forage_resource_id, value)
    DATA.forage_resource_name[forage_resource_id] = value
end
---@param forage_resource_id forage_resource_id valid forage_resource id
---@return string description
function DATA.forage_resource_get_description(forage_resource_id)
    return DATA.forage_resource_description[forage_resource_id]
end
---@param forage_resource_id forage_resource_id valid forage_resource id
---@param value string valid string
function DATA.forage_resource_set_description(forage_resource_id, value)
    DATA.forage_resource_description[forage_resource_id] = value
end
---@param forage_resource_id forage_resource_id valid forage_resource id
---@return string icon
function DATA.forage_resource_get_icon(forage_resource_id)
    return DATA.forage_resource_icon[forage_resource_id]
end
---@param forage_resource_id forage_resource_id valid forage_resource id
---@param value string valid string
function DATA.forage_resource_set_icon(forage_resource_id, value)
    DATA.forage_resource_icon[forage_resource_id] = value
end
---@param forage_resource_id forage_resource_id valid forage_resource id
---@return JOBTYPE handle
function DATA.forage_resource_get_handle(forage_resource_id)
    return DCON.dcon_forage_resource_get_handle(forage_resource_id - 1)
end
---@param forage_resource_id forage_resource_id valid forage_resource id
---@param value JOBTYPE valid JOBTYPE
function DATA.forage_resource_set_handle(forage_resource_id, value)
    DCON.dcon_forage_resource_set_handle(forage_resource_id - 1, value)
end

local fat_forage_resource_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.forage_resource_get_name(t.id) end
        if (k == "description") then return DATA.forage_resource_get_description(t.id) end
        if (k == "icon") then return DATA.forage_resource_get_icon(t.id) end
        if (k == "handle") then return DATA.forage_resource_get_handle(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.forage_resource_set_name(t.id, v)
            return
        end
        if (k == "description") then
            DATA.forage_resource_set_description(t.id, v)
            return
        end
        if (k == "icon") then
            DATA.forage_resource_set_icon(t.id, v)
            return
        end
        if (k == "handle") then
            DATA.forage_resource_set_handle(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id forage_resource_id
---@return fat_forage_resource_id fat_id
function DATA.fatten_forage_resource(id)
    local result = {id = id}
    setmetatable(result, fat_forage_resource_id_metatable)    return result
end
---@enum FORAGE_RESOURCE
FORAGE_RESOURCE = {
    INVALID = 0,
    WATER = 1,
    FRUIT = 2,
    GRAIN = 3,
    GAME = 4,
    FUNGI = 5,
    SHELL = 6,
    FISH = 7,
    WOOD = 8,
}
local index_forage_resource
index_forage_resource = DATA.create_forage_resource()
DATA.forage_resource_set_name(index_forage_resource, "Water")
DATA.forage_resource_set_description(index_forage_resource, "water")
DATA.forage_resource_set_icon(index_forage_resource, "droplets.png")
DATA.forage_resource_set_handle(index_forage_resource, JOBTYPE.HAULING)
index_forage_resource = DATA.create_forage_resource()
DATA.forage_resource_set_name(index_forage_resource, "Fruit")
DATA.forage_resource_set_description(index_forage_resource, "berries")
DATA.forage_resource_set_icon(index_forage_resource, "berries-bowl.png")
DATA.forage_resource_set_handle(index_forage_resource, JOBTYPE.FORAGER)
index_forage_resource = DATA.create_forage_resource()
DATA.forage_resource_set_name(index_forage_resource, "Grain")
DATA.forage_resource_set_description(index_forage_resource, "seeds")
DATA.forage_resource_set_icon(index_forage_resource, "wheat.png")
DATA.forage_resource_set_handle(index_forage_resource, JOBTYPE.FARMER)
index_forage_resource = DATA.create_forage_resource()
DATA.forage_resource_set_name(index_forage_resource, "Game")
DATA.forage_resource_set_description(index_forage_resource, "game")
DATA.forage_resource_set_icon(index_forage_resource, "bison.png")
DATA.forage_resource_set_handle(index_forage_resource, JOBTYPE.HUNTING)
index_forage_resource = DATA.create_forage_resource()
DATA.forage_resource_set_name(index_forage_resource, "Fungi")
DATA.forage_resource_set_description(index_forage_resource, "mushrooms")
DATA.forage_resource_set_icon(index_forage_resource, "chanterelles.png")
DATA.forage_resource_set_handle(index_forage_resource, JOBTYPE.CLERK)
index_forage_resource = DATA.create_forage_resource()
DATA.forage_resource_set_name(index_forage_resource, "Shell")
DATA.forage_resource_set_description(index_forage_resource, "shellfish")
DATA.forage_resource_set_icon(index_forage_resource, "oyster.png")
DATA.forage_resource_set_handle(index_forage_resource, JOBTYPE.HAULING)
index_forage_resource = DATA.create_forage_resource()
DATA.forage_resource_set_name(index_forage_resource, "Fish")
DATA.forage_resource_set_description(index_forage_resource, "fish")
DATA.forage_resource_set_icon(index_forage_resource, "salmon.png")
DATA.forage_resource_set_handle(index_forage_resource, JOBTYPE.LABOURER)
index_forage_resource = DATA.create_forage_resource()
DATA.forage_resource_set_name(index_forage_resource, "Wood")
DATA.forage_resource_set_description(index_forage_resource, "timber")
DATA.forage_resource_set_icon(index_forage_resource, "pine-tree.png")
DATA.forage_resource_set_handle(index_forage_resource, JOBTYPE.ARTISAN)
----------budget_category----------


---budget_category: LSP types---

---Unique identificator for budget_category entity
---@class (exact) budget_category_id : number
---@field is_budget_category nil

---@class (exact) fat_budget_category_id
---@field id budget_category_id Unique budget_category id
---@field name string

---@class struct_budget_category

---@class (exact) budget_category_id_data_blob_definition
---@field name string
---Sets values of budget_category for given id
---@param id budget_category_id
---@param data budget_category_id_data_blob_definition
function DATA.setup_budget_category(id, data)
    DATA.budget_category_set_name(id, data.name)
end

ffi.cdef[[
int32_t dcon_create_budget_category();
bool dcon_budget_category_is_valid(int32_t);
void dcon_budget_category_resize(uint32_t sz);
uint32_t dcon_budget_category_size();
]]

---budget_category: FFI arrays---
---@type (string)[]
DATA.budget_category_name= {}

---budget_category: LUA bindings---

DATA.budget_category_size = 7
---@return budget_category_id
function DATA.create_budget_category()
    ---@type budget_category_id
    local i  = DCON.dcon_create_budget_category() + 1
    return i --[[@as budget_category_id]]
end
---@param func fun(item: budget_category_id)
function DATA.for_each_budget_category(func)
    ---@type number
    local range = DCON.dcon_budget_category_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as budget_category_id]])
    end
end
---@param func fun(item: budget_category_id):boolean
---@return table<budget_category_id, budget_category_id>
function DATA.filter_budget_category(func)
    ---@type table<budget_category_id, budget_category_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_budget_category_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as budget_category_id]]) then t[i + 1 --[[@as budget_category_id]]] = t[i + 1 --[[@as budget_category_id]]] end
    end
    return t
end

---@param budget_category_id budget_category_id valid budget_category id
---@return string name
function DATA.budget_category_get_name(budget_category_id)
    return DATA.budget_category_name[budget_category_id]
end
---@param budget_category_id budget_category_id valid budget_category id
---@param value string valid string
function DATA.budget_category_set_name(budget_category_id, value)
    DATA.budget_category_name[budget_category_id] = value
end

local fat_budget_category_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.budget_category_get_name(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.budget_category_set_name(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id budget_category_id
---@return fat_budget_category_id fat_id
function DATA.fatten_budget_category(id)
    local result = {id = id}
    setmetatable(result, fat_budget_category_id_metatable)    return result
end
---@enum BUDGET_CATEGORY
BUDGET_CATEGORY = {
    INVALID = 0,
    EDUCATION = 1,
    COURT = 2,
    INFRASTRUCTURE = 3,
    MILITARY = 4,
    TRIBUTE = 5,
}
local index_budget_category
index_budget_category = DATA.create_budget_category()
DATA.budget_category_set_name(index_budget_category, "education")
index_budget_category = DATA.create_budget_category()
DATA.budget_category_set_name(index_budget_category, "court")
index_budget_category = DATA.create_budget_category()
DATA.budget_category_set_name(index_budget_category, "infrastructure")
index_budget_category = DATA.create_budget_category()
DATA.budget_category_set_name(index_budget_category, "military")
index_budget_category = DATA.create_budget_category()
DATA.budget_category_set_name(index_budget_category, "tribute")
----------economy_reason----------


---economy_reason: LSP types---

---Unique identificator for economy_reason entity
---@class (exact) economy_reason_id : number
---@field is_economy_reason nil

---@class (exact) fat_economy_reason_id
---@field id economy_reason_id Unique economy_reason id
---@field name string
---@field description string

---@class struct_economy_reason

---@class (exact) economy_reason_id_data_blob_definition
---@field name string
---@field description string
---Sets values of economy_reason for given id
---@param id economy_reason_id
---@param data economy_reason_id_data_blob_definition
function DATA.setup_economy_reason(id, data)
    DATA.economy_reason_set_name(id, data.name)
    DATA.economy_reason_set_description(id, data.description)
end

ffi.cdef[[
int32_t dcon_create_economy_reason();
bool dcon_economy_reason_is_valid(int32_t);
void dcon_economy_reason_resize(uint32_t sz);
uint32_t dcon_economy_reason_size();
]]

---economy_reason: FFI arrays---
---@type (string)[]
DATA.economy_reason_name= {}
---@type (string)[]
DATA.economy_reason_description= {}

---economy_reason: LUA bindings---

DATA.economy_reason_size = 38
---@return economy_reason_id
function DATA.create_economy_reason()
    ---@type economy_reason_id
    local i  = DCON.dcon_create_economy_reason() + 1
    return i --[[@as economy_reason_id]]
end
---@param func fun(item: economy_reason_id)
function DATA.for_each_economy_reason(func)
    ---@type number
    local range = DCON.dcon_economy_reason_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as economy_reason_id]])
    end
end
---@param func fun(item: economy_reason_id):boolean
---@return table<economy_reason_id, economy_reason_id>
function DATA.filter_economy_reason(func)
    ---@type table<economy_reason_id, economy_reason_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_economy_reason_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as economy_reason_id]]) then t[i + 1 --[[@as economy_reason_id]]] = t[i + 1 --[[@as economy_reason_id]]] end
    end
    return t
end

---@param economy_reason_id economy_reason_id valid economy_reason id
---@return string name
function DATA.economy_reason_get_name(economy_reason_id)
    return DATA.economy_reason_name[economy_reason_id]
end
---@param economy_reason_id economy_reason_id valid economy_reason id
---@param value string valid string
function DATA.economy_reason_set_name(economy_reason_id, value)
    DATA.economy_reason_name[economy_reason_id] = value
end
---@param economy_reason_id economy_reason_id valid economy_reason id
---@return string description
function DATA.economy_reason_get_description(economy_reason_id)
    return DATA.economy_reason_description[economy_reason_id]
end
---@param economy_reason_id economy_reason_id valid economy_reason id
---@param value string valid string
function DATA.economy_reason_set_description(economy_reason_id, value)
    DATA.economy_reason_description[economy_reason_id] = value
end

local fat_economy_reason_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.economy_reason_get_name(t.id) end
        if (k == "description") then return DATA.economy_reason_get_description(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.economy_reason_set_name(t.id, v)
            return
        end
        if (k == "description") then
            DATA.economy_reason_set_description(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id economy_reason_id
---@return fat_economy_reason_id fat_id
function DATA.fatten_economy_reason(id)
    local result = {id = id}
    setmetatable(result, fat_economy_reason_id_metatable)    return result
end
---@enum ECONOMY_REASON
ECONOMY_REASON = {
    INVALID = 0,
    BASIC_NEEDS = 1,
    WELFARE = 2,
    RAID = 3,
    DONATION = 4,
    MONTHLY_CHANGE = 5,
    YEARLY_CHANGE = 6,
    INFRASTRUCTURE = 7,
    EDUCATION = 8,
    COURT = 9,
    MILITARY = 10,
    EXPLORATION = 11,
    UPKEEP = 12,
    NEW_MONTH = 13,
    LOYALTY_GIFT = 14,
    BUILDING = 15,
    BUILDING_INCOME = 16,
    TREASURY = 17,
    BUDGET = 18,
    WASTE = 19,
    TRIBUTE = 20,
    INHERITANCE = 21,
    TRADE = 22,
    WARBAND = 23,
    WATER = 24,
    FOOD = 25,
    OTHER_NEEDS = 26,
    FORAGE = 27,
    WORK = 28,
    OTHER = 29,
    SIPHON = 30,
    TRADE_SIPHON = 31,
    QUEST = 32,
    NEIGHBOR_SIPHON = 33,
    COLONISATION = 34,
    TAX = 35,
    NEGOTIATIONS = 36,
}
local index_economy_reason
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Basic_Needs")
DATA.economy_reason_set_description(index_economy_reason, "Basic needs")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Welfare")
DATA.economy_reason_set_description(index_economy_reason, "Welfare")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Raid")
DATA.economy_reason_set_description(index_economy_reason, "Eaid")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Donation")
DATA.economy_reason_set_description(index_economy_reason, "Donation")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Monthly_Change")
DATA.economy_reason_set_description(index_economy_reason, "Monthly change")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Yearly_Change")
DATA.economy_reason_set_description(index_economy_reason, "Yearly change")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Infrastructure")
DATA.economy_reason_set_description(index_economy_reason, "Infrastructure")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Education")
DATA.economy_reason_set_description(index_economy_reason, "Education")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Court")
DATA.economy_reason_set_description(index_economy_reason, "Court")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Military")
DATA.economy_reason_set_description(index_economy_reason, "Military")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Exploration")
DATA.economy_reason_set_description(index_economy_reason, "Exploration")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Upkeep")
DATA.economy_reason_set_description(index_economy_reason, "Upkeep")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "New_Month")
DATA.economy_reason_set_description(index_economy_reason, "New month")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Loyalty_Gift")
DATA.economy_reason_set_description(index_economy_reason, "Loyalty gift")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Building")
DATA.economy_reason_set_description(index_economy_reason, "Building")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Building_Income")
DATA.economy_reason_set_description(index_economy_reason, "Building income")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Treasury")
DATA.economy_reason_set_description(index_economy_reason, "Treasury")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Budget")
DATA.economy_reason_set_description(index_economy_reason, "Budget")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Waste")
DATA.economy_reason_set_description(index_economy_reason, "Waste")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Tribute")
DATA.economy_reason_set_description(index_economy_reason, "Tribute")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Inheritance")
DATA.economy_reason_set_description(index_economy_reason, "Inheritance")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Trade")
DATA.economy_reason_set_description(index_economy_reason, "Trade")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Warband")
DATA.economy_reason_set_description(index_economy_reason, "Warband")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Water")
DATA.economy_reason_set_description(index_economy_reason, "Water")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Food")
DATA.economy_reason_set_description(index_economy_reason, "Food")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Other_Needs")
DATA.economy_reason_set_description(index_economy_reason, "Other needs")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Forage")
DATA.economy_reason_set_description(index_economy_reason, "Forage")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Work")
DATA.economy_reason_set_description(index_economy_reason, "Work")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Other")
DATA.economy_reason_set_description(index_economy_reason, "Other")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Siphon")
DATA.economy_reason_set_description(index_economy_reason, "Siphon")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Trade_Siphon")
DATA.economy_reason_set_description(index_economy_reason, "Trade siphon")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Quest")
DATA.economy_reason_set_description(index_economy_reason, "Quest")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Neighbor_Siphon")
DATA.economy_reason_set_description(index_economy_reason, "Neigbour siphon")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Colonisation")
DATA.economy_reason_set_description(index_economy_reason, "Colonisation")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Tax")
DATA.economy_reason_set_description(index_economy_reason, "Tax")
index_economy_reason = DATA.create_economy_reason()
DATA.economy_reason_set_name(index_economy_reason, "Negotiations")
DATA.economy_reason_set_description(index_economy_reason, "Negotiations")
----------politics_reason----------


---politics_reason: LSP types---

---Unique identificator for politics_reason entity
---@class (exact) politics_reason_id : number
---@field is_politics_reason nil

---@class (exact) fat_politics_reason_id
---@field id politics_reason_id Unique politics_reason id
---@field name string
---@field description string

---@class struct_politics_reason

---@class (exact) politics_reason_id_data_blob_definition
---@field name string
---@field description string
---Sets values of politics_reason for given id
---@param id politics_reason_id
---@param data politics_reason_id_data_blob_definition
function DATA.setup_politics_reason(id, data)
    DATA.politics_reason_set_name(id, data.name)
    DATA.politics_reason_set_description(id, data.description)
end

ffi.cdef[[
int32_t dcon_create_politics_reason();
bool dcon_politics_reason_is_valid(int32_t);
void dcon_politics_reason_resize(uint32_t sz);
uint32_t dcon_politics_reason_size();
]]

---politics_reason: FFI arrays---
---@type (string)[]
DATA.politics_reason_name= {}
---@type (string)[]
DATA.politics_reason_description= {}

---politics_reason: LUA bindings---

DATA.politics_reason_size = 10
---@return politics_reason_id
function DATA.create_politics_reason()
    ---@type politics_reason_id
    local i  = DCON.dcon_create_politics_reason() + 1
    return i --[[@as politics_reason_id]]
end
---@param func fun(item: politics_reason_id)
function DATA.for_each_politics_reason(func)
    ---@type number
    local range = DCON.dcon_politics_reason_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as politics_reason_id]])
    end
end
---@param func fun(item: politics_reason_id):boolean
---@return table<politics_reason_id, politics_reason_id>
function DATA.filter_politics_reason(func)
    ---@type table<politics_reason_id, politics_reason_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_politics_reason_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as politics_reason_id]]) then t[i + 1 --[[@as politics_reason_id]]] = t[i + 1 --[[@as politics_reason_id]]] end
    end
    return t
end

---@param politics_reason_id politics_reason_id valid politics_reason id
---@return string name
function DATA.politics_reason_get_name(politics_reason_id)
    return DATA.politics_reason_name[politics_reason_id]
end
---@param politics_reason_id politics_reason_id valid politics_reason id
---@param value string valid string
function DATA.politics_reason_set_name(politics_reason_id, value)
    DATA.politics_reason_name[politics_reason_id] = value
end
---@param politics_reason_id politics_reason_id valid politics_reason id
---@return string description
function DATA.politics_reason_get_description(politics_reason_id)
    return DATA.politics_reason_description[politics_reason_id]
end
---@param politics_reason_id politics_reason_id valid politics_reason id
---@param value string valid string
function DATA.politics_reason_set_description(politics_reason_id, value)
    DATA.politics_reason_description[politics_reason_id] = value
end

local fat_politics_reason_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.politics_reason_get_name(t.id) end
        if (k == "description") then return DATA.politics_reason_get_description(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.politics_reason_set_name(t.id, v)
            return
        end
        if (k == "description") then
            DATA.politics_reason_set_description(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id politics_reason_id
---@return fat_politics_reason_id fat_id
function DATA.fatten_politics_reason(id)
    local result = {id = id}
    setmetatable(result, fat_politics_reason_id_metatable)    return result
end
---@enum POLITICS_REASON
POLITICS_REASON = {
    INVALID = 0,
    NOTENOUGHNOBLES = 1,
    INITIALNOBLE = 2,
    POPULATIONGROWTH = 3,
    EXPEDITIONLEADER = 4,
    SUCCESSION = 5,
    COUP = 6,
    INITIALRULER = 7,
    OTHER = 8,
}
local index_politics_reason
index_politics_reason = DATA.create_politics_reason()
DATA.politics_reason_set_name(index_politics_reason, "NotEnoughNobles")
DATA.politics_reason_set_description(index_politics_reason, "Political vacuum")
index_politics_reason = DATA.create_politics_reason()
DATA.politics_reason_set_name(index_politics_reason, "InitialNoble")
DATA.politics_reason_set_description(index_politics_reason, "Initial noble")
index_politics_reason = DATA.create_politics_reason()
DATA.politics_reason_set_name(index_politics_reason, "PopulationGrowth")
DATA.politics_reason_set_description(index_politics_reason, "Population growth")
index_politics_reason = DATA.create_politics_reason()
DATA.politics_reason_set_name(index_politics_reason, "ExpeditionLeader")
DATA.politics_reason_set_description(index_politics_reason, "Expedition leader")
index_politics_reason = DATA.create_politics_reason()
DATA.politics_reason_set_name(index_politics_reason, "Succession")
DATA.politics_reason_set_description(index_politics_reason, "Succession")
index_politics_reason = DATA.create_politics_reason()
DATA.politics_reason_set_name(index_politics_reason, "Coup")
DATA.politics_reason_set_description(index_politics_reason, "Coup")
index_politics_reason = DATA.create_politics_reason()
DATA.politics_reason_set_name(index_politics_reason, "InitialRuler")
DATA.politics_reason_set_description(index_politics_reason, "First ruler")
index_politics_reason = DATA.create_politics_reason()
DATA.politics_reason_set_name(index_politics_reason, "Other")
DATA.politics_reason_set_description(index_politics_reason, "Other")
----------law_trade----------


---law_trade: LSP types---

---Unique identificator for law_trade entity
---@class (exact) law_trade_id : number
---@field is_law_trade nil

---@class (exact) fat_law_trade_id
---@field id law_trade_id Unique law_trade id
---@field name string

---@class struct_law_trade

---@class (exact) law_trade_id_data_blob_definition
---@field name string
---Sets values of law_trade for given id
---@param id law_trade_id
---@param data law_trade_id_data_blob_definition
function DATA.setup_law_trade(id, data)
    DATA.law_trade_set_name(id, data.name)
end

ffi.cdef[[
int32_t dcon_create_law_trade();
bool dcon_law_trade_is_valid(int32_t);
void dcon_law_trade_resize(uint32_t sz);
uint32_t dcon_law_trade_size();
]]

---law_trade: FFI arrays---
---@type (string)[]
DATA.law_trade_name= {}

---law_trade: LUA bindings---

DATA.law_trade_size = 5
---@return law_trade_id
function DATA.create_law_trade()
    ---@type law_trade_id
    local i  = DCON.dcon_create_law_trade() + 1
    return i --[[@as law_trade_id]]
end
---@param func fun(item: law_trade_id)
function DATA.for_each_law_trade(func)
    ---@type number
    local range = DCON.dcon_law_trade_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as law_trade_id]])
    end
end
---@param func fun(item: law_trade_id):boolean
---@return table<law_trade_id, law_trade_id>
function DATA.filter_law_trade(func)
    ---@type table<law_trade_id, law_trade_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_law_trade_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as law_trade_id]]) then t[i + 1 --[[@as law_trade_id]]] = t[i + 1 --[[@as law_trade_id]]] end
    end
    return t
end

---@param law_trade_id law_trade_id valid law_trade id
---@return string name
function DATA.law_trade_get_name(law_trade_id)
    return DATA.law_trade_name[law_trade_id]
end
---@param law_trade_id law_trade_id valid law_trade id
---@param value string valid string
function DATA.law_trade_set_name(law_trade_id, value)
    DATA.law_trade_name[law_trade_id] = value
end

local fat_law_trade_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.law_trade_get_name(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.law_trade_set_name(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id law_trade_id
---@return fat_law_trade_id fat_id
function DATA.fatten_law_trade(id)
    local result = {id = id}
    setmetatable(result, fat_law_trade_id_metatable)    return result
end
---@enum LAW_TRADE
LAW_TRADE = {
    INVALID = 0,
    NO_REGULATION = 1,
    LOCALS_ONLY = 2,
    PERMISSION_ONLY = 3,
}
local index_law_trade
index_law_trade = DATA.create_law_trade()
DATA.law_trade_set_name(index_law_trade, "NO_REGULATION")
index_law_trade = DATA.create_law_trade()
DATA.law_trade_set_name(index_law_trade, "LOCALS_ONLY")
index_law_trade = DATA.create_law_trade()
DATA.law_trade_set_name(index_law_trade, "PERMISSION_ONLY")
----------law_building----------


---law_building: LSP types---

---Unique identificator for law_building entity
---@class (exact) law_building_id : number
---@field is_law_building nil

---@class (exact) fat_law_building_id
---@field id law_building_id Unique law_building id
---@field name string

---@class struct_law_building

---@class (exact) law_building_id_data_blob_definition
---@field name string
---Sets values of law_building for given id
---@param id law_building_id
---@param data law_building_id_data_blob_definition
function DATA.setup_law_building(id, data)
    DATA.law_building_set_name(id, data.name)
end

ffi.cdef[[
int32_t dcon_create_law_building();
bool dcon_law_building_is_valid(int32_t);
void dcon_law_building_resize(uint32_t sz);
uint32_t dcon_law_building_size();
]]

---law_building: FFI arrays---
---@type (string)[]
DATA.law_building_name= {}

---law_building: LUA bindings---

DATA.law_building_size = 5
---@return law_building_id
function DATA.create_law_building()
    ---@type law_building_id
    local i  = DCON.dcon_create_law_building() + 1
    return i --[[@as law_building_id]]
end
---@param func fun(item: law_building_id)
function DATA.for_each_law_building(func)
    ---@type number
    local range = DCON.dcon_law_building_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as law_building_id]])
    end
end
---@param func fun(item: law_building_id):boolean
---@return table<law_building_id, law_building_id>
function DATA.filter_law_building(func)
    ---@type table<law_building_id, law_building_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_law_building_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as law_building_id]]) then t[i + 1 --[[@as law_building_id]]] = t[i + 1 --[[@as law_building_id]]] end
    end
    return t
end

---@param law_building_id law_building_id valid law_building id
---@return string name
function DATA.law_building_get_name(law_building_id)
    return DATA.law_building_name[law_building_id]
end
---@param law_building_id law_building_id valid law_building id
---@param value string valid string
function DATA.law_building_set_name(law_building_id, value)
    DATA.law_building_name[law_building_id] = value
end

local fat_law_building_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.law_building_get_name(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.law_building_set_name(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id law_building_id
---@return fat_law_building_id fat_id
function DATA.fatten_law_building(id)
    local result = {id = id}
    setmetatable(result, fat_law_building_id_metatable)    return result
end
---@enum LAW_BUILDING
LAW_BUILDING = {
    INVALID = 0,
    NO_REGULATION = 1,
    LOCALS_ONLY = 2,
    PERMISSION_ONLY = 3,
}
local index_law_building
index_law_building = DATA.create_law_building()
DATA.law_building_set_name(index_law_building, "NO_REGULATION")
index_law_building = DATA.create_law_building()
DATA.law_building_set_name(index_law_building, "LOCALS_ONLY")
index_law_building = DATA.create_law_building()
DATA.law_building_set_name(index_law_building, "PERMISSION_ONLY")
----------trade_good----------


---trade_good: LSP types---

---Unique identificator for trade_good entity
---@class (exact) trade_good_id : number
---@field is_trade_good nil

---@class (exact) fat_trade_good_id
---@field id trade_good_id Unique trade_good id
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field belongs_to_category TRADE_GOOD_CATEGORY
---@field base_price number

---@class struct_trade_good
---@field r number
---@field g number
---@field b number
---@field belongs_to_category TRADE_GOOD_CATEGORY
---@field base_price number

---@class (exact) trade_good_id_data_blob_definition
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field belongs_to_category TRADE_GOOD_CATEGORY
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
    DATA.trade_good_set_belongs_to_category(id, data.belongs_to_category)
    DATA.trade_good_set_base_price(id, data.base_price)
end

ffi.cdef[[
void dcon_trade_good_set_r(int32_t, float);
float dcon_trade_good_get_r(int32_t);
void dcon_trade_good_set_g(int32_t, float);
float dcon_trade_good_get_g(int32_t);
void dcon_trade_good_set_b(int32_t, float);
float dcon_trade_good_get_b(int32_t);
void dcon_trade_good_set_belongs_to_category(int32_t, uint8_t);
uint8_t dcon_trade_good_get_belongs_to_category(int32_t);
void dcon_trade_good_set_base_price(int32_t, float);
float dcon_trade_good_get_base_price(int32_t);
int32_t dcon_create_trade_good();
bool dcon_trade_good_is_valid(int32_t);
void dcon_trade_good_resize(uint32_t sz);
uint32_t dcon_trade_good_size();
]]

---trade_good: FFI arrays---
---@type (string)[]
DATA.trade_good_name= {}
---@type (string)[]
DATA.trade_good_icon= {}
---@type (string)[]
DATA.trade_good_description= {}

---trade_good: LUA bindings---

DATA.trade_good_size = 100
---@return trade_good_id
function DATA.create_trade_good()
    ---@type trade_good_id
    local i  = DCON.dcon_create_trade_good() + 1
    return i --[[@as trade_good_id]]
end
---@param func fun(item: trade_good_id)
function DATA.for_each_trade_good(func)
    ---@type number
    local range = DCON.dcon_trade_good_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as trade_good_id]])
    end
end
---@param func fun(item: trade_good_id):boolean
---@return table<trade_good_id, trade_good_id>
function DATA.filter_trade_good(func)
    ---@type table<trade_good_id, trade_good_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_trade_good_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as trade_good_id]]) then t[i + 1 --[[@as trade_good_id]]] = t[i + 1 --[[@as trade_good_id]]] end
    end
    return t
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
    return DCON.dcon_trade_good_get_r(trade_good_id - 1)
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value number valid number
function DATA.trade_good_set_r(trade_good_id, value)
    DCON.dcon_trade_good_set_r(trade_good_id - 1, value)
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value number valid number
function DATA.trade_good_inc_r(trade_good_id, value)
    ---@type number
    local current = DCON.dcon_trade_good_get_r(trade_good_id - 1)
    DCON.dcon_trade_good_set_r(trade_good_id - 1, current + value)
end
---@param trade_good_id trade_good_id valid trade_good id
---@return number g
function DATA.trade_good_get_g(trade_good_id)
    return DCON.dcon_trade_good_get_g(trade_good_id - 1)
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value number valid number
function DATA.trade_good_set_g(trade_good_id, value)
    DCON.dcon_trade_good_set_g(trade_good_id - 1, value)
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value number valid number
function DATA.trade_good_inc_g(trade_good_id, value)
    ---@type number
    local current = DCON.dcon_trade_good_get_g(trade_good_id - 1)
    DCON.dcon_trade_good_set_g(trade_good_id - 1, current + value)
end
---@param trade_good_id trade_good_id valid trade_good id
---@return number b
function DATA.trade_good_get_b(trade_good_id)
    return DCON.dcon_trade_good_get_b(trade_good_id - 1)
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value number valid number
function DATA.trade_good_set_b(trade_good_id, value)
    DCON.dcon_trade_good_set_b(trade_good_id - 1, value)
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value number valid number
function DATA.trade_good_inc_b(trade_good_id, value)
    ---@type number
    local current = DCON.dcon_trade_good_get_b(trade_good_id - 1)
    DCON.dcon_trade_good_set_b(trade_good_id - 1, current + value)
end
---@param trade_good_id trade_good_id valid trade_good id
---@return TRADE_GOOD_CATEGORY belongs_to_category
function DATA.trade_good_get_belongs_to_category(trade_good_id)
    return DCON.dcon_trade_good_get_belongs_to_category(trade_good_id - 1)
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value TRADE_GOOD_CATEGORY valid TRADE_GOOD_CATEGORY
function DATA.trade_good_set_belongs_to_category(trade_good_id, value)
    DCON.dcon_trade_good_set_belongs_to_category(trade_good_id - 1, value)
end
---@param trade_good_id trade_good_id valid trade_good id
---@return number base_price
function DATA.trade_good_get_base_price(trade_good_id)
    return DCON.dcon_trade_good_get_base_price(trade_good_id - 1)
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value number valid number
function DATA.trade_good_set_base_price(trade_good_id, value)
    DCON.dcon_trade_good_set_base_price(trade_good_id - 1, value)
end
---@param trade_good_id trade_good_id valid trade_good id
---@param value number valid number
function DATA.trade_good_inc_base_price(trade_good_id, value)
    ---@type number
    local current = DCON.dcon_trade_good_get_base_price(trade_good_id - 1)
    DCON.dcon_trade_good_set_base_price(trade_good_id - 1, current + value)
end

local fat_trade_good_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.trade_good_get_name(t.id) end
        if (k == "icon") then return DATA.trade_good_get_icon(t.id) end
        if (k == "description") then return DATA.trade_good_get_description(t.id) end
        if (k == "r") then return DATA.trade_good_get_r(t.id) end
        if (k == "g") then return DATA.trade_good_get_g(t.id) end
        if (k == "b") then return DATA.trade_good_get_b(t.id) end
        if (k == "belongs_to_category") then return DATA.trade_good_get_belongs_to_category(t.id) end
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
        if (k == "belongs_to_category") then
            DATA.trade_good_set_belongs_to_category(t.id, v)
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
---@class (exact) use_case_id : number
---@field is_use_case nil

---@class (exact) fat_use_case_id
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
void dcon_use_case_set_r(int32_t, float);
float dcon_use_case_get_r(int32_t);
void dcon_use_case_set_g(int32_t, float);
float dcon_use_case_get_g(int32_t);
void dcon_use_case_set_b(int32_t, float);
float dcon_use_case_get_b(int32_t);
int32_t dcon_create_use_case();
bool dcon_use_case_is_valid(int32_t);
void dcon_use_case_resize(uint32_t sz);
uint32_t dcon_use_case_size();
]]

---use_case: FFI arrays---
---@type (string)[]
DATA.use_case_name= {}
---@type (string)[]
DATA.use_case_icon= {}
---@type (string)[]
DATA.use_case_description= {}

---use_case: LUA bindings---

DATA.use_case_size = 100
---@return use_case_id
function DATA.create_use_case()
    ---@type use_case_id
    local i  = DCON.dcon_create_use_case() + 1
    return i --[[@as use_case_id]]
end
---@param func fun(item: use_case_id)
function DATA.for_each_use_case(func)
    ---@type number
    local range = DCON.dcon_use_case_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as use_case_id]])
    end
end
---@param func fun(item: use_case_id):boolean
---@return table<use_case_id, use_case_id>
function DATA.filter_use_case(func)
    ---@type table<use_case_id, use_case_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_use_case_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as use_case_id]]) then t[i + 1 --[[@as use_case_id]]] = t[i + 1 --[[@as use_case_id]]] end
    end
    return t
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
    return DCON.dcon_use_case_get_r(use_case_id - 1)
end
---@param use_case_id use_case_id valid use_case id
---@param value number valid number
function DATA.use_case_set_r(use_case_id, value)
    DCON.dcon_use_case_set_r(use_case_id - 1, value)
end
---@param use_case_id use_case_id valid use_case id
---@param value number valid number
function DATA.use_case_inc_r(use_case_id, value)
    ---@type number
    local current = DCON.dcon_use_case_get_r(use_case_id - 1)
    DCON.dcon_use_case_set_r(use_case_id - 1, current + value)
end
---@param use_case_id use_case_id valid use_case id
---@return number g
function DATA.use_case_get_g(use_case_id)
    return DCON.dcon_use_case_get_g(use_case_id - 1)
end
---@param use_case_id use_case_id valid use_case id
---@param value number valid number
function DATA.use_case_set_g(use_case_id, value)
    DCON.dcon_use_case_set_g(use_case_id - 1, value)
end
---@param use_case_id use_case_id valid use_case id
---@param value number valid number
function DATA.use_case_inc_g(use_case_id, value)
    ---@type number
    local current = DCON.dcon_use_case_get_g(use_case_id - 1)
    DCON.dcon_use_case_set_g(use_case_id - 1, current + value)
end
---@param use_case_id use_case_id valid use_case id
---@return number b
function DATA.use_case_get_b(use_case_id)
    return DCON.dcon_use_case_get_b(use_case_id - 1)
end
---@param use_case_id use_case_id valid use_case id
---@param value number valid number
function DATA.use_case_set_b(use_case_id, value)
    DCON.dcon_use_case_set_b(use_case_id - 1, value)
end
---@param use_case_id use_case_id valid use_case id
---@param value number valid number
function DATA.use_case_inc_b(use_case_id, value)
    ---@type number
    local current = DCON.dcon_use_case_get_b(use_case_id - 1)
    DCON.dcon_use_case_set_b(use_case_id - 1, current + value)
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
---@class (exact) use_weight_id : number
---@field is_use_weight nil

---@class (exact) fat_use_weight_id
---@field id use_weight_id Unique use_weight id
---@field weight number efficiency of this relation
---@field trade_good trade_good_id index of trade good
---@field use_case use_case_id index of use case

---@class struct_use_weight
---@field weight number efficiency of this relation

---@class (exact) use_weight_id_data_blob_definition
---@field weight number efficiency of this relation
---Sets values of use_weight for given id
---@param id use_weight_id
---@param data use_weight_id_data_blob_definition
function DATA.setup_use_weight(id, data)
    DATA.use_weight_set_weight(id, data.weight)
end

ffi.cdef[[
void dcon_use_weight_set_weight(int32_t, float);
float dcon_use_weight_get_weight(int32_t);
int32_t dcon_force_create_use_weight(int32_t trade_good, int32_t use_case);
void dcon_use_weight_set_trade_good(int32_t, int32_t);
int32_t dcon_use_weight_get_trade_good(int32_t);
int32_t dcon_trade_good_get_range_use_weight_as_trade_good(int32_t);
int32_t dcon_trade_good_get_index_use_weight_as_trade_good(int32_t, int32_t);
void dcon_use_weight_set_use_case(int32_t, int32_t);
int32_t dcon_use_weight_get_use_case(int32_t);
int32_t dcon_use_case_get_range_use_weight_as_use_case(int32_t);
int32_t dcon_use_case_get_index_use_weight_as_use_case(int32_t, int32_t);
bool dcon_use_weight_is_valid(int32_t);
void dcon_use_weight_resize(uint32_t sz);
uint32_t dcon_use_weight_size();
]]

---use_weight: FFI arrays---

---use_weight: LUA bindings---

DATA.use_weight_size = 300
---@param trade_good trade_good_id
---@param use_case use_case_id
---@return use_weight_id
function DATA.force_create_use_weight(trade_good, use_case)
    ---@type use_weight_id
    local i = DCON.dcon_force_create_use_weight(trade_good - 1, use_case - 1) + 1
    return i --[[@as use_weight_id]]
end
---@param func fun(item: use_weight_id)
function DATA.for_each_use_weight(func)
    ---@type number
    local range = DCON.dcon_use_weight_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as use_weight_id]])
    end
end
---@param func fun(item: use_weight_id):boolean
---@return table<use_weight_id, use_weight_id>
function DATA.filter_use_weight(func)
    ---@type table<use_weight_id, use_weight_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_use_weight_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as use_weight_id]]) then t[i + 1 --[[@as use_weight_id]]] = t[i + 1 --[[@as use_weight_id]]] end
    end
    return t
end

---@param use_weight_id use_weight_id valid use_weight id
---@return number weight efficiency of this relation
function DATA.use_weight_get_weight(use_weight_id)
    return DCON.dcon_use_weight_get_weight(use_weight_id - 1)
end
---@param use_weight_id use_weight_id valid use_weight id
---@param value number valid number
function DATA.use_weight_set_weight(use_weight_id, value)
    DCON.dcon_use_weight_set_weight(use_weight_id - 1, value)
end
---@param use_weight_id use_weight_id valid use_weight id
---@param value number valid number
function DATA.use_weight_inc_weight(use_weight_id, value)
    ---@type number
    local current = DCON.dcon_use_weight_get_weight(use_weight_id - 1)
    DCON.dcon_use_weight_set_weight(use_weight_id - 1, current + value)
end
---@param trade_good use_weight_id valid trade_good_id
---@return trade_good_id Data retrieved from use_weight
function DATA.use_weight_get_trade_good(trade_good)
    return DCON.dcon_use_weight_get_trade_good(trade_good - 1) + 1
end
---@param trade_good trade_good_id valid trade_good_id
---@return use_weight_id[] An array of use_weight
function DATA.get_use_weight_from_trade_good(trade_good)
    local result = {}
    DATA.for_each_use_weight_from_trade_good(trade_good, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param trade_good trade_good_id valid trade_good_id
---@param func fun(item: use_weight_id) valid trade_good_id
function DATA.for_each_use_weight_from_trade_good(trade_good, func)
    ---@type number
    local range = DCON.dcon_trade_good_get_range_use_weight_as_trade_good(trade_good - 1)
    for i = 0, range - 1 do
        ---@type use_weight_id
        local accessed_element = DCON.dcon_trade_good_get_index_use_weight_as_trade_good(trade_good - 1, i) + 1
        if DCON.dcon_use_weight_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param trade_good trade_good_id valid trade_good_id
---@param func fun(item: use_weight_id):boolean
---@return use_weight_id[]
function DATA.filter_array_use_weight_from_trade_good(trade_good, func)
    ---@type table<use_weight_id, use_weight_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_trade_good_get_range_use_weight_as_trade_good(trade_good - 1)
    for i = 0, range - 1 do
        ---@type use_weight_id
        local accessed_element = DCON.dcon_trade_good_get_index_use_weight_as_trade_good(trade_good - 1, i) + 1
        if DCON.dcon_use_weight_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param trade_good trade_good_id valid trade_good_id
---@param func fun(item: use_weight_id):boolean
---@return table<use_weight_id, use_weight_id>
function DATA.filter_use_weight_from_trade_good(trade_good, func)
    ---@type table<use_weight_id, use_weight_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_trade_good_get_range_use_weight_as_trade_good(trade_good - 1)
    for i = 0, range - 1 do
        ---@type use_weight_id
        local accessed_element = DCON.dcon_trade_good_get_index_use_weight_as_trade_good(trade_good - 1, i) + 1
        if DCON.dcon_use_weight_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param use_weight_id use_weight_id valid use_weight id
---@param value trade_good_id valid trade_good_id
function DATA.use_weight_set_trade_good(use_weight_id, value)
    DCON.dcon_use_weight_set_trade_good(use_weight_id - 1, value - 1)
end
---@param use_case use_weight_id valid use_case_id
---@return use_case_id Data retrieved from use_weight
function DATA.use_weight_get_use_case(use_case)
    return DCON.dcon_use_weight_get_use_case(use_case - 1) + 1
end
---@param use_case use_case_id valid use_case_id
---@return use_weight_id[] An array of use_weight
function DATA.get_use_weight_from_use_case(use_case)
    local result = {}
    DATA.for_each_use_weight_from_use_case(use_case, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param use_case use_case_id valid use_case_id
---@param func fun(item: use_weight_id) valid use_case_id
function DATA.for_each_use_weight_from_use_case(use_case, func)
    ---@type number
    local range = DCON.dcon_use_case_get_range_use_weight_as_use_case(use_case - 1)
    for i = 0, range - 1 do
        ---@type use_weight_id
        local accessed_element = DCON.dcon_use_case_get_index_use_weight_as_use_case(use_case - 1, i) + 1
        if DCON.dcon_use_weight_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param use_case use_case_id valid use_case_id
---@param func fun(item: use_weight_id):boolean
---@return use_weight_id[]
function DATA.filter_array_use_weight_from_use_case(use_case, func)
    ---@type table<use_weight_id, use_weight_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_use_case_get_range_use_weight_as_use_case(use_case - 1)
    for i = 0, range - 1 do
        ---@type use_weight_id
        local accessed_element = DCON.dcon_use_case_get_index_use_weight_as_use_case(use_case - 1, i) + 1
        if DCON.dcon_use_weight_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param use_case use_case_id valid use_case_id
---@param func fun(item: use_weight_id):boolean
---@return table<use_weight_id, use_weight_id>
function DATA.filter_use_weight_from_use_case(use_case, func)
    ---@type table<use_weight_id, use_weight_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_use_case_get_range_use_weight_as_use_case(use_case - 1)
    for i = 0, range - 1 do
        ---@type use_weight_id
        local accessed_element = DCON.dcon_use_case_get_index_use_weight_as_use_case(use_case - 1, i) + 1
        if DCON.dcon_use_weight_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param use_weight_id use_weight_id valid use_weight id
---@param value use_case_id valid use_case_id
function DATA.use_weight_set_use_case(use_weight_id, value)
    DCON.dcon_use_weight_set_use_case(use_weight_id - 1, value - 1)
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
        if (k == "trade_good") then
            DATA.use_weight_set_trade_good(t.id, v)
            return
        end
        if (k == "use_case") then
            DATA.use_weight_set_use_case(t.id, v)
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
---@class (exact) biome_id : number
---@field is_biome nil

---@class (exact) fat_biome_id
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
    DATA.biome_set_aquatic(id, false)
    DATA.biome_set_marsh(id, false)
    DATA.biome_set_icy(id, false)
    DATA.biome_set_minimum_slope(id, -99999999)
    DATA.biome_set_maximum_slope(id, 99999999)
    DATA.biome_set_minimum_elevation(id, -99999999)
    DATA.biome_set_maximum_elevation(id, 99999999)
    DATA.biome_set_minimum_temperature(id, -99999999)
    DATA.biome_set_maximum_temperature(id, 99999999)
    DATA.biome_set_minimum_summer_temperature(id, -99999999)
    DATA.biome_set_maximum_summer_temperature(id, 99999999)
    DATA.biome_set_minimum_winter_temperature(id, -99999999)
    DATA.biome_set_maximum_winter_temperature(id, 99999999)
    DATA.biome_set_minimum_rain(id, -99999999)
    DATA.biome_set_maximum_rain(id, 99999999)
    DATA.biome_set_minimum_available_water(id, -99999999)
    DATA.biome_set_maximum_available_water(id, 99999999)
    DATA.biome_set_minimum_trees(id, -99999999)
    DATA.biome_set_maximum_trees(id, 99999999)
    DATA.biome_set_minimum_grass(id, -99999999)
    DATA.biome_set_maximum_grass(id, 99999999)
    DATA.biome_set_minimum_shrubs(id, -99999999)
    DATA.biome_set_maximum_shrubs(id, 99999999)
    DATA.biome_set_minimum_conifer_fraction(id, -99999999)
    DATA.biome_set_maximum_conifer_fraction(id, 99999999)
    DATA.biome_set_minimum_dead_land(id, -99999999)
    DATA.biome_set_maximum_dead_land(id, 99999999)
    DATA.biome_set_minimum_soil_depth(id, -99999999)
    DATA.biome_set_maximum_soil_depth(id, 99999999)
    DATA.biome_set_minimum_soil_richness(id, -99999999)
    DATA.biome_set_maximum_soil_richness(id, 99999999)
    DATA.biome_set_minimum_sand(id, -99999999)
    DATA.biome_set_maximum_sand(id, 99999999)
    DATA.biome_set_minimum_clay(id, -99999999)
    DATA.biome_set_maximum_clay(id, 99999999)
    DATA.biome_set_minimum_silt(id, -99999999)
    DATA.biome_set_maximum_silt(id, 99999999)
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
void dcon_biome_set_r(int32_t, float);
float dcon_biome_get_r(int32_t);
void dcon_biome_set_g(int32_t, float);
float dcon_biome_get_g(int32_t);
void dcon_biome_set_b(int32_t, float);
float dcon_biome_get_b(int32_t);
void dcon_biome_set_aquatic(int32_t, bool);
bool dcon_biome_get_aquatic(int32_t);
void dcon_biome_set_marsh(int32_t, bool);
bool dcon_biome_get_marsh(int32_t);
void dcon_biome_set_icy(int32_t, bool);
bool dcon_biome_get_icy(int32_t);
void dcon_biome_set_minimum_slope(int32_t, float);
float dcon_biome_get_minimum_slope(int32_t);
void dcon_biome_set_maximum_slope(int32_t, float);
float dcon_biome_get_maximum_slope(int32_t);
void dcon_biome_set_minimum_elevation(int32_t, float);
float dcon_biome_get_minimum_elevation(int32_t);
void dcon_biome_set_maximum_elevation(int32_t, float);
float dcon_biome_get_maximum_elevation(int32_t);
void dcon_biome_set_minimum_temperature(int32_t, float);
float dcon_biome_get_minimum_temperature(int32_t);
void dcon_biome_set_maximum_temperature(int32_t, float);
float dcon_biome_get_maximum_temperature(int32_t);
void dcon_biome_set_minimum_summer_temperature(int32_t, float);
float dcon_biome_get_minimum_summer_temperature(int32_t);
void dcon_biome_set_maximum_summer_temperature(int32_t, float);
float dcon_biome_get_maximum_summer_temperature(int32_t);
void dcon_biome_set_minimum_winter_temperature(int32_t, float);
float dcon_biome_get_minimum_winter_temperature(int32_t);
void dcon_biome_set_maximum_winter_temperature(int32_t, float);
float dcon_biome_get_maximum_winter_temperature(int32_t);
void dcon_biome_set_minimum_rain(int32_t, float);
float dcon_biome_get_minimum_rain(int32_t);
void dcon_biome_set_maximum_rain(int32_t, float);
float dcon_biome_get_maximum_rain(int32_t);
void dcon_biome_set_minimum_available_water(int32_t, float);
float dcon_biome_get_minimum_available_water(int32_t);
void dcon_biome_set_maximum_available_water(int32_t, float);
float dcon_biome_get_maximum_available_water(int32_t);
void dcon_biome_set_minimum_trees(int32_t, float);
float dcon_biome_get_minimum_trees(int32_t);
void dcon_biome_set_maximum_trees(int32_t, float);
float dcon_biome_get_maximum_trees(int32_t);
void dcon_biome_set_minimum_grass(int32_t, float);
float dcon_biome_get_minimum_grass(int32_t);
void dcon_biome_set_maximum_grass(int32_t, float);
float dcon_biome_get_maximum_grass(int32_t);
void dcon_biome_set_minimum_shrubs(int32_t, float);
float dcon_biome_get_minimum_shrubs(int32_t);
void dcon_biome_set_maximum_shrubs(int32_t, float);
float dcon_biome_get_maximum_shrubs(int32_t);
void dcon_biome_set_minimum_conifer_fraction(int32_t, float);
float dcon_biome_get_minimum_conifer_fraction(int32_t);
void dcon_biome_set_maximum_conifer_fraction(int32_t, float);
float dcon_biome_get_maximum_conifer_fraction(int32_t);
void dcon_biome_set_minimum_dead_land(int32_t, float);
float dcon_biome_get_minimum_dead_land(int32_t);
void dcon_biome_set_maximum_dead_land(int32_t, float);
float dcon_biome_get_maximum_dead_land(int32_t);
void dcon_biome_set_minimum_soil_depth(int32_t, float);
float dcon_biome_get_minimum_soil_depth(int32_t);
void dcon_biome_set_maximum_soil_depth(int32_t, float);
float dcon_biome_get_maximum_soil_depth(int32_t);
void dcon_biome_set_minimum_soil_richness(int32_t, float);
float dcon_biome_get_minimum_soil_richness(int32_t);
void dcon_biome_set_maximum_soil_richness(int32_t, float);
float dcon_biome_get_maximum_soil_richness(int32_t);
void dcon_biome_set_minimum_sand(int32_t, float);
float dcon_biome_get_minimum_sand(int32_t);
void dcon_biome_set_maximum_sand(int32_t, float);
float dcon_biome_get_maximum_sand(int32_t);
void dcon_biome_set_minimum_clay(int32_t, float);
float dcon_biome_get_minimum_clay(int32_t);
void dcon_biome_set_maximum_clay(int32_t, float);
float dcon_biome_get_maximum_clay(int32_t);
void dcon_biome_set_minimum_silt(int32_t, float);
float dcon_biome_get_minimum_silt(int32_t);
void dcon_biome_set_maximum_silt(int32_t, float);
float dcon_biome_get_maximum_silt(int32_t);
int32_t dcon_create_biome();
bool dcon_biome_is_valid(int32_t);
void dcon_biome_resize(uint32_t sz);
uint32_t dcon_biome_size();
]]

---biome: FFI arrays---
---@type (string)[]
DATA.biome_name= {}

---biome: LUA bindings---

DATA.biome_size = 100
---@return biome_id
function DATA.create_biome()
    ---@type biome_id
    local i  = DCON.dcon_create_biome() + 1
    return i --[[@as biome_id]]
end
---@param func fun(item: biome_id)
function DATA.for_each_biome(func)
    ---@type number
    local range = DCON.dcon_biome_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as biome_id]])
    end
end
---@param func fun(item: biome_id):boolean
---@return table<biome_id, biome_id>
function DATA.filter_biome(func)
    ---@type table<biome_id, biome_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_biome_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as biome_id]]) then t[i + 1 --[[@as biome_id]]] = t[i + 1 --[[@as biome_id]]] end
    end
    return t
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
    return DCON.dcon_biome_get_r(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_r(biome_id, value)
    DCON.dcon_biome_set_r(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_r(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_r(biome_id - 1)
    DCON.dcon_biome_set_r(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number g
function DATA.biome_get_g(biome_id)
    return DCON.dcon_biome_get_g(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_g(biome_id, value)
    DCON.dcon_biome_set_g(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_g(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_g(biome_id - 1)
    DCON.dcon_biome_set_g(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number b
function DATA.biome_get_b(biome_id)
    return DCON.dcon_biome_get_b(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_b(biome_id, value)
    DCON.dcon_biome_set_b(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_b(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_b(biome_id - 1)
    DCON.dcon_biome_set_b(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return boolean aquatic
function DATA.biome_get_aquatic(biome_id)
    return DCON.dcon_biome_get_aquatic(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value boolean valid boolean
function DATA.biome_set_aquatic(biome_id, value)
    DCON.dcon_biome_set_aquatic(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@return boolean marsh
function DATA.biome_get_marsh(biome_id)
    return DCON.dcon_biome_get_marsh(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value boolean valid boolean
function DATA.biome_set_marsh(biome_id, value)
    DCON.dcon_biome_set_marsh(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@return boolean icy
function DATA.biome_get_icy(biome_id)
    return DCON.dcon_biome_get_icy(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value boolean valid boolean
function DATA.biome_set_icy(biome_id, value)
    DCON.dcon_biome_set_icy(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_slope m
function DATA.biome_get_minimum_slope(biome_id)
    return DCON.dcon_biome_get_minimum_slope(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_slope(biome_id, value)
    DCON.dcon_biome_set_minimum_slope(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_slope(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_slope(biome_id - 1)
    DCON.dcon_biome_set_minimum_slope(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_slope m
function DATA.biome_get_maximum_slope(biome_id)
    return DCON.dcon_biome_get_maximum_slope(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_slope(biome_id, value)
    DCON.dcon_biome_set_maximum_slope(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_slope(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_slope(biome_id - 1)
    DCON.dcon_biome_set_maximum_slope(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_elevation m
function DATA.biome_get_minimum_elevation(biome_id)
    return DCON.dcon_biome_get_minimum_elevation(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_elevation(biome_id, value)
    DCON.dcon_biome_set_minimum_elevation(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_elevation(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_elevation(biome_id - 1)
    DCON.dcon_biome_set_minimum_elevation(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_elevation m
function DATA.biome_get_maximum_elevation(biome_id)
    return DCON.dcon_biome_get_maximum_elevation(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_elevation(biome_id, value)
    DCON.dcon_biome_set_maximum_elevation(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_elevation(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_elevation(biome_id - 1)
    DCON.dcon_biome_set_maximum_elevation(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_temperature C
function DATA.biome_get_minimum_temperature(biome_id)
    return DCON.dcon_biome_get_minimum_temperature(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_temperature(biome_id, value)
    DCON.dcon_biome_set_minimum_temperature(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_temperature(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_temperature(biome_id - 1)
    DCON.dcon_biome_set_minimum_temperature(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_temperature C
function DATA.biome_get_maximum_temperature(biome_id)
    return DCON.dcon_biome_get_maximum_temperature(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_temperature(biome_id, value)
    DCON.dcon_biome_set_maximum_temperature(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_temperature(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_temperature(biome_id - 1)
    DCON.dcon_biome_set_maximum_temperature(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_summer_temperature C
function DATA.biome_get_minimum_summer_temperature(biome_id)
    return DCON.dcon_biome_get_minimum_summer_temperature(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_summer_temperature(biome_id, value)
    DCON.dcon_biome_set_minimum_summer_temperature(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_summer_temperature(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_summer_temperature(biome_id - 1)
    DCON.dcon_biome_set_minimum_summer_temperature(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_summer_temperature C
function DATA.biome_get_maximum_summer_temperature(biome_id)
    return DCON.dcon_biome_get_maximum_summer_temperature(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_summer_temperature(biome_id, value)
    DCON.dcon_biome_set_maximum_summer_temperature(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_summer_temperature(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_summer_temperature(biome_id - 1)
    DCON.dcon_biome_set_maximum_summer_temperature(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_winter_temperature C
function DATA.biome_get_minimum_winter_temperature(biome_id)
    return DCON.dcon_biome_get_minimum_winter_temperature(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_winter_temperature(biome_id, value)
    DCON.dcon_biome_set_minimum_winter_temperature(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_winter_temperature(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_winter_temperature(biome_id - 1)
    DCON.dcon_biome_set_minimum_winter_temperature(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_winter_temperature C
function DATA.biome_get_maximum_winter_temperature(biome_id)
    return DCON.dcon_biome_get_maximum_winter_temperature(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_winter_temperature(biome_id, value)
    DCON.dcon_biome_set_maximum_winter_temperature(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_winter_temperature(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_winter_temperature(biome_id - 1)
    DCON.dcon_biome_set_maximum_winter_temperature(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_rain mm
function DATA.biome_get_minimum_rain(biome_id)
    return DCON.dcon_biome_get_minimum_rain(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_rain(biome_id, value)
    DCON.dcon_biome_set_minimum_rain(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_rain(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_rain(biome_id - 1)
    DCON.dcon_biome_set_minimum_rain(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_rain mm
function DATA.biome_get_maximum_rain(biome_id)
    return DCON.dcon_biome_get_maximum_rain(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_rain(biome_id, value)
    DCON.dcon_biome_set_maximum_rain(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_rain(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_rain(biome_id - 1)
    DCON.dcon_biome_set_maximum_rain(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_available_water abstract, adjusted for permeability
function DATA.biome_get_minimum_available_water(biome_id)
    return DCON.dcon_biome_get_minimum_available_water(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_available_water(biome_id, value)
    DCON.dcon_biome_set_minimum_available_water(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_available_water(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_available_water(biome_id - 1)
    DCON.dcon_biome_set_minimum_available_water(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_available_water abstract, adjusted for permeability
function DATA.biome_get_maximum_available_water(biome_id)
    return DCON.dcon_biome_get_maximum_available_water(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_available_water(biome_id, value)
    DCON.dcon_biome_set_maximum_available_water(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_available_water(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_available_water(biome_id - 1)
    DCON.dcon_biome_set_maximum_available_water(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_trees %
function DATA.biome_get_minimum_trees(biome_id)
    return DCON.dcon_biome_get_minimum_trees(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_trees(biome_id, value)
    DCON.dcon_biome_set_minimum_trees(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_trees(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_trees(biome_id - 1)
    DCON.dcon_biome_set_minimum_trees(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_trees %
function DATA.biome_get_maximum_trees(biome_id)
    return DCON.dcon_biome_get_maximum_trees(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_trees(biome_id, value)
    DCON.dcon_biome_set_maximum_trees(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_trees(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_trees(biome_id - 1)
    DCON.dcon_biome_set_maximum_trees(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_grass %
function DATA.biome_get_minimum_grass(biome_id)
    return DCON.dcon_biome_get_minimum_grass(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_grass(biome_id, value)
    DCON.dcon_biome_set_minimum_grass(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_grass(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_grass(biome_id - 1)
    DCON.dcon_biome_set_minimum_grass(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_grass %
function DATA.biome_get_maximum_grass(biome_id)
    return DCON.dcon_biome_get_maximum_grass(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_grass(biome_id, value)
    DCON.dcon_biome_set_maximum_grass(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_grass(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_grass(biome_id - 1)
    DCON.dcon_biome_set_maximum_grass(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_shrubs %
function DATA.biome_get_minimum_shrubs(biome_id)
    return DCON.dcon_biome_get_minimum_shrubs(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_shrubs(biome_id, value)
    DCON.dcon_biome_set_minimum_shrubs(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_shrubs(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_shrubs(biome_id - 1)
    DCON.dcon_biome_set_minimum_shrubs(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_shrubs %
function DATA.biome_get_maximum_shrubs(biome_id)
    return DCON.dcon_biome_get_maximum_shrubs(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_shrubs(biome_id, value)
    DCON.dcon_biome_set_maximum_shrubs(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_shrubs(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_shrubs(biome_id - 1)
    DCON.dcon_biome_set_maximum_shrubs(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_conifer_fraction %
function DATA.biome_get_minimum_conifer_fraction(biome_id)
    return DCON.dcon_biome_get_minimum_conifer_fraction(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_conifer_fraction(biome_id, value)
    DCON.dcon_biome_set_minimum_conifer_fraction(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_conifer_fraction(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_conifer_fraction(biome_id - 1)
    DCON.dcon_biome_set_minimum_conifer_fraction(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_conifer_fraction %
function DATA.biome_get_maximum_conifer_fraction(biome_id)
    return DCON.dcon_biome_get_maximum_conifer_fraction(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_conifer_fraction(biome_id, value)
    DCON.dcon_biome_set_maximum_conifer_fraction(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_conifer_fraction(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_conifer_fraction(biome_id - 1)
    DCON.dcon_biome_set_maximum_conifer_fraction(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_dead_land %
function DATA.biome_get_minimum_dead_land(biome_id)
    return DCON.dcon_biome_get_minimum_dead_land(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_dead_land(biome_id, value)
    DCON.dcon_biome_set_minimum_dead_land(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_dead_land(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_dead_land(biome_id - 1)
    DCON.dcon_biome_set_minimum_dead_land(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_dead_land %
function DATA.biome_get_maximum_dead_land(biome_id)
    return DCON.dcon_biome_get_maximum_dead_land(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_dead_land(biome_id, value)
    DCON.dcon_biome_set_maximum_dead_land(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_dead_land(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_dead_land(biome_id - 1)
    DCON.dcon_biome_set_maximum_dead_land(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_soil_depth m
function DATA.biome_get_minimum_soil_depth(biome_id)
    return DCON.dcon_biome_get_minimum_soil_depth(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_soil_depth(biome_id, value)
    DCON.dcon_biome_set_minimum_soil_depth(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_soil_depth(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_soil_depth(biome_id - 1)
    DCON.dcon_biome_set_minimum_soil_depth(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_soil_depth m
function DATA.biome_get_maximum_soil_depth(biome_id)
    return DCON.dcon_biome_get_maximum_soil_depth(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_soil_depth(biome_id, value)
    DCON.dcon_biome_set_maximum_soil_depth(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_soil_depth(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_soil_depth(biome_id - 1)
    DCON.dcon_biome_set_maximum_soil_depth(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_soil_richness %
function DATA.biome_get_minimum_soil_richness(biome_id)
    return DCON.dcon_biome_get_minimum_soil_richness(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_soil_richness(biome_id, value)
    DCON.dcon_biome_set_minimum_soil_richness(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_soil_richness(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_soil_richness(biome_id - 1)
    DCON.dcon_biome_set_minimum_soil_richness(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_soil_richness %
function DATA.biome_get_maximum_soil_richness(biome_id)
    return DCON.dcon_biome_get_maximum_soil_richness(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_soil_richness(biome_id, value)
    DCON.dcon_biome_set_maximum_soil_richness(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_soil_richness(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_soil_richness(biome_id - 1)
    DCON.dcon_biome_set_maximum_soil_richness(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_sand %
function DATA.biome_get_minimum_sand(biome_id)
    return DCON.dcon_biome_get_minimum_sand(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_sand(biome_id, value)
    DCON.dcon_biome_set_minimum_sand(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_sand(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_sand(biome_id - 1)
    DCON.dcon_biome_set_minimum_sand(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_sand %
function DATA.biome_get_maximum_sand(biome_id)
    return DCON.dcon_biome_get_maximum_sand(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_sand(biome_id, value)
    DCON.dcon_biome_set_maximum_sand(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_sand(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_sand(biome_id - 1)
    DCON.dcon_biome_set_maximum_sand(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_clay %
function DATA.biome_get_minimum_clay(biome_id)
    return DCON.dcon_biome_get_minimum_clay(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_clay(biome_id, value)
    DCON.dcon_biome_set_minimum_clay(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_clay(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_clay(biome_id - 1)
    DCON.dcon_biome_set_minimum_clay(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_clay %
function DATA.biome_get_maximum_clay(biome_id)
    return DCON.dcon_biome_get_maximum_clay(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_clay(biome_id, value)
    DCON.dcon_biome_set_maximum_clay(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_clay(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_clay(biome_id - 1)
    DCON.dcon_biome_set_maximum_clay(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number minimum_silt %
function DATA.biome_get_minimum_silt(biome_id)
    return DCON.dcon_biome_get_minimum_silt(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_minimum_silt(biome_id, value)
    DCON.dcon_biome_set_minimum_silt(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_minimum_silt(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_minimum_silt(biome_id - 1)
    DCON.dcon_biome_set_minimum_silt(biome_id - 1, current + value)
end
---@param biome_id biome_id valid biome id
---@return number maximum_silt %
function DATA.biome_get_maximum_silt(biome_id)
    return DCON.dcon_biome_get_maximum_silt(biome_id - 1)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_set_maximum_silt(biome_id, value)
    DCON.dcon_biome_set_maximum_silt(biome_id - 1, value)
end
---@param biome_id biome_id valid biome id
---@param value number valid number
function DATA.biome_inc_maximum_silt(biome_id, value)
    ---@type number
    local current = DCON.dcon_biome_get_maximum_silt(biome_id - 1)
    DCON.dcon_biome_set_maximum_silt(biome_id - 1, current + value)
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
---@class (exact) bedrock_id : number
---@field is_bedrock nil

---@class (exact) fat_bedrock_id
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
    DATA.bedrock_set_grain_size(id, 0.0)
    DATA.bedrock_set_acidity(id, 0.0)
    DATA.bedrock_set_igneous_extrusive(id, false)
    DATA.bedrock_set_igneous_intrusive(id, false)
    DATA.bedrock_set_sedimentary(id, false)
    DATA.bedrock_set_clastic(id, false)
    DATA.bedrock_set_evaporative(id, false)
    DATA.bedrock_set_metamorphic_marble(id, false)
    DATA.bedrock_set_metamorphic_slate(id, false)
    DATA.bedrock_set_oceanic(id, false)
    DATA.bedrock_set_sedimentary_ocean_deep(id, false)
    DATA.bedrock_set_sedimentary_ocean_shallow(id, false)
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
void dcon_bedrock_set_r(int32_t, float);
float dcon_bedrock_get_r(int32_t);
void dcon_bedrock_set_g(int32_t, float);
float dcon_bedrock_get_g(int32_t);
void dcon_bedrock_set_b(int32_t, float);
float dcon_bedrock_get_b(int32_t);
void dcon_bedrock_set_color_id(int32_t, uint32_t);
uint32_t dcon_bedrock_get_color_id(int32_t);
void dcon_bedrock_set_sand(int32_t, float);
float dcon_bedrock_get_sand(int32_t);
void dcon_bedrock_set_silt(int32_t, float);
float dcon_bedrock_get_silt(int32_t);
void dcon_bedrock_set_clay(int32_t, float);
float dcon_bedrock_get_clay(int32_t);
void dcon_bedrock_set_organics(int32_t, float);
float dcon_bedrock_get_organics(int32_t);
void dcon_bedrock_set_minerals(int32_t, float);
float dcon_bedrock_get_minerals(int32_t);
void dcon_bedrock_set_weathering(int32_t, float);
float dcon_bedrock_get_weathering(int32_t);
void dcon_bedrock_set_grain_size(int32_t, float);
float dcon_bedrock_get_grain_size(int32_t);
void dcon_bedrock_set_acidity(int32_t, float);
float dcon_bedrock_get_acidity(int32_t);
void dcon_bedrock_set_igneous_extrusive(int32_t, bool);
bool dcon_bedrock_get_igneous_extrusive(int32_t);
void dcon_bedrock_set_igneous_intrusive(int32_t, bool);
bool dcon_bedrock_get_igneous_intrusive(int32_t);
void dcon_bedrock_set_sedimentary(int32_t, bool);
bool dcon_bedrock_get_sedimentary(int32_t);
void dcon_bedrock_set_clastic(int32_t, bool);
bool dcon_bedrock_get_clastic(int32_t);
void dcon_bedrock_set_evaporative(int32_t, bool);
bool dcon_bedrock_get_evaporative(int32_t);
void dcon_bedrock_set_metamorphic_marble(int32_t, bool);
bool dcon_bedrock_get_metamorphic_marble(int32_t);
void dcon_bedrock_set_metamorphic_slate(int32_t, bool);
bool dcon_bedrock_get_metamorphic_slate(int32_t);
void dcon_bedrock_set_oceanic(int32_t, bool);
bool dcon_bedrock_get_oceanic(int32_t);
void dcon_bedrock_set_sedimentary_ocean_deep(int32_t, bool);
bool dcon_bedrock_get_sedimentary_ocean_deep(int32_t);
void dcon_bedrock_set_sedimentary_ocean_shallow(int32_t, bool);
bool dcon_bedrock_get_sedimentary_ocean_shallow(int32_t);
int32_t dcon_create_bedrock();
bool dcon_bedrock_is_valid(int32_t);
void dcon_bedrock_resize(uint32_t sz);
uint32_t dcon_bedrock_size();
]]

---bedrock: FFI arrays---
---@type (string)[]
DATA.bedrock_name= {}

---bedrock: LUA bindings---

DATA.bedrock_size = 150
---@return bedrock_id
function DATA.create_bedrock()
    ---@type bedrock_id
    local i  = DCON.dcon_create_bedrock() + 1
    return i --[[@as bedrock_id]]
end
---@param func fun(item: bedrock_id)
function DATA.for_each_bedrock(func)
    ---@type number
    local range = DCON.dcon_bedrock_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as bedrock_id]])
    end
end
---@param func fun(item: bedrock_id):boolean
---@return table<bedrock_id, bedrock_id>
function DATA.filter_bedrock(func)
    ---@type table<bedrock_id, bedrock_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_bedrock_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as bedrock_id]]) then t[i + 1 --[[@as bedrock_id]]] = t[i + 1 --[[@as bedrock_id]]] end
    end
    return t
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
    return DCON.dcon_bedrock_get_r(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_r(bedrock_id, value)
    DCON.dcon_bedrock_set_r(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_inc_r(bedrock_id, value)
    ---@type number
    local current = DCON.dcon_bedrock_get_r(bedrock_id - 1)
    DCON.dcon_bedrock_set_r(bedrock_id - 1, current + value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number g
function DATA.bedrock_get_g(bedrock_id)
    return DCON.dcon_bedrock_get_g(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_g(bedrock_id, value)
    DCON.dcon_bedrock_set_g(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_inc_g(bedrock_id, value)
    ---@type number
    local current = DCON.dcon_bedrock_get_g(bedrock_id - 1)
    DCON.dcon_bedrock_set_g(bedrock_id - 1, current + value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number b
function DATA.bedrock_get_b(bedrock_id)
    return DCON.dcon_bedrock_get_b(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_b(bedrock_id, value)
    DCON.dcon_bedrock_set_b(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_inc_b(bedrock_id, value)
    ---@type number
    local current = DCON.dcon_bedrock_get_b(bedrock_id - 1)
    DCON.dcon_bedrock_set_b(bedrock_id - 1, current + value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number color_id
function DATA.bedrock_get_color_id(bedrock_id)
    return DCON.dcon_bedrock_get_color_id(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_color_id(bedrock_id, value)
    DCON.dcon_bedrock_set_color_id(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_inc_color_id(bedrock_id, value)
    ---@type number
    local current = DCON.dcon_bedrock_get_color_id(bedrock_id - 1)
    DCON.dcon_bedrock_set_color_id(bedrock_id - 1, current + value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number sand
function DATA.bedrock_get_sand(bedrock_id)
    return DCON.dcon_bedrock_get_sand(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_sand(bedrock_id, value)
    DCON.dcon_bedrock_set_sand(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_inc_sand(bedrock_id, value)
    ---@type number
    local current = DCON.dcon_bedrock_get_sand(bedrock_id - 1)
    DCON.dcon_bedrock_set_sand(bedrock_id - 1, current + value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number silt
function DATA.bedrock_get_silt(bedrock_id)
    return DCON.dcon_bedrock_get_silt(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_silt(bedrock_id, value)
    DCON.dcon_bedrock_set_silt(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_inc_silt(bedrock_id, value)
    ---@type number
    local current = DCON.dcon_bedrock_get_silt(bedrock_id - 1)
    DCON.dcon_bedrock_set_silt(bedrock_id - 1, current + value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number clay
function DATA.bedrock_get_clay(bedrock_id)
    return DCON.dcon_bedrock_get_clay(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_clay(bedrock_id, value)
    DCON.dcon_bedrock_set_clay(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_inc_clay(bedrock_id, value)
    ---@type number
    local current = DCON.dcon_bedrock_get_clay(bedrock_id - 1)
    DCON.dcon_bedrock_set_clay(bedrock_id - 1, current + value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number organics
function DATA.bedrock_get_organics(bedrock_id)
    return DCON.dcon_bedrock_get_organics(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_organics(bedrock_id, value)
    DCON.dcon_bedrock_set_organics(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_inc_organics(bedrock_id, value)
    ---@type number
    local current = DCON.dcon_bedrock_get_organics(bedrock_id - 1)
    DCON.dcon_bedrock_set_organics(bedrock_id - 1, current + value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number minerals
function DATA.bedrock_get_minerals(bedrock_id)
    return DCON.dcon_bedrock_get_minerals(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_minerals(bedrock_id, value)
    DCON.dcon_bedrock_set_minerals(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_inc_minerals(bedrock_id, value)
    ---@type number
    local current = DCON.dcon_bedrock_get_minerals(bedrock_id - 1)
    DCON.dcon_bedrock_set_minerals(bedrock_id - 1, current + value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number weathering
function DATA.bedrock_get_weathering(bedrock_id)
    return DCON.dcon_bedrock_get_weathering(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_weathering(bedrock_id, value)
    DCON.dcon_bedrock_set_weathering(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_inc_weathering(bedrock_id, value)
    ---@type number
    local current = DCON.dcon_bedrock_get_weathering(bedrock_id - 1)
    DCON.dcon_bedrock_set_weathering(bedrock_id - 1, current + value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number grain_size
function DATA.bedrock_get_grain_size(bedrock_id)
    return DCON.dcon_bedrock_get_grain_size(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_grain_size(bedrock_id, value)
    DCON.dcon_bedrock_set_grain_size(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_inc_grain_size(bedrock_id, value)
    ---@type number
    local current = DCON.dcon_bedrock_get_grain_size(bedrock_id - 1)
    DCON.dcon_bedrock_set_grain_size(bedrock_id - 1, current + value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return number acidity
function DATA.bedrock_get_acidity(bedrock_id)
    return DCON.dcon_bedrock_get_acidity(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_set_acidity(bedrock_id, value)
    DCON.dcon_bedrock_set_acidity(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value number valid number
function DATA.bedrock_inc_acidity(bedrock_id, value)
    ---@type number
    local current = DCON.dcon_bedrock_get_acidity(bedrock_id - 1)
    DCON.dcon_bedrock_set_acidity(bedrock_id - 1, current + value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean igneous_extrusive
function DATA.bedrock_get_igneous_extrusive(bedrock_id)
    return DCON.dcon_bedrock_get_igneous_extrusive(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_igneous_extrusive(bedrock_id, value)
    DCON.dcon_bedrock_set_igneous_extrusive(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean igneous_intrusive
function DATA.bedrock_get_igneous_intrusive(bedrock_id)
    return DCON.dcon_bedrock_get_igneous_intrusive(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_igneous_intrusive(bedrock_id, value)
    DCON.dcon_bedrock_set_igneous_intrusive(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean sedimentary
function DATA.bedrock_get_sedimentary(bedrock_id)
    return DCON.dcon_bedrock_get_sedimentary(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_sedimentary(bedrock_id, value)
    DCON.dcon_bedrock_set_sedimentary(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean clastic
function DATA.bedrock_get_clastic(bedrock_id)
    return DCON.dcon_bedrock_get_clastic(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_clastic(bedrock_id, value)
    DCON.dcon_bedrock_set_clastic(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean evaporative
function DATA.bedrock_get_evaporative(bedrock_id)
    return DCON.dcon_bedrock_get_evaporative(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_evaporative(bedrock_id, value)
    DCON.dcon_bedrock_set_evaporative(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean metamorphic_marble
function DATA.bedrock_get_metamorphic_marble(bedrock_id)
    return DCON.dcon_bedrock_get_metamorphic_marble(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_metamorphic_marble(bedrock_id, value)
    DCON.dcon_bedrock_set_metamorphic_marble(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean metamorphic_slate
function DATA.bedrock_get_metamorphic_slate(bedrock_id)
    return DCON.dcon_bedrock_get_metamorphic_slate(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_metamorphic_slate(bedrock_id, value)
    DCON.dcon_bedrock_set_metamorphic_slate(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean oceanic
function DATA.bedrock_get_oceanic(bedrock_id)
    return DCON.dcon_bedrock_get_oceanic(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_oceanic(bedrock_id, value)
    DCON.dcon_bedrock_set_oceanic(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean sedimentary_ocean_deep
function DATA.bedrock_get_sedimentary_ocean_deep(bedrock_id)
    return DCON.dcon_bedrock_get_sedimentary_ocean_deep(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_sedimentary_ocean_deep(bedrock_id, value)
    DCON.dcon_bedrock_set_sedimentary_ocean_deep(bedrock_id - 1, value)
end
---@param bedrock_id bedrock_id valid bedrock id
---@return boolean sedimentary_ocean_shallow
function DATA.bedrock_get_sedimentary_ocean_shallow(bedrock_id)
    return DCON.dcon_bedrock_get_sedimentary_ocean_shallow(bedrock_id - 1)
end
---@param bedrock_id bedrock_id valid bedrock id
---@param value boolean valid boolean
function DATA.bedrock_set_sedimentary_ocean_shallow(bedrock_id, value)
    DCON.dcon_bedrock_set_sedimentary_ocean_shallow(bedrock_id - 1, value)
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
---@class (exact) resource_id : number
---@field is_resource nil

---@class (exact) fat_resource_id
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
    DATA.resource_set_base_frequency(id, 1000)
    DATA.resource_set_coastal(id, false)
    DATA.resource_set_land(id, true)
    DATA.resource_set_water(id, false)
    DATA.resource_set_ice_age(id, false)
    DATA.resource_set_minimum_trees(id, 0)
    DATA.resource_set_maximum_trees(id, 1)
    DATA.resource_set_minimum_elevation(id, -math.huge)
    DATA.resource_set_maximum_elevation(id, math.huge)
    DATA.resource_set_name(id, data.name)
    DATA.resource_set_icon(id, data.icon)
    DATA.resource_set_description(id, data.description)
    DATA.resource_set_r(id, data.r)
    DATA.resource_set_g(id, data.g)
    DATA.resource_set_b(id, data.b)
    for i, value in pairs(data.required_biome) do
        DATA.resource_set_required_biome(id, i - 1, value)
    end
    for i, value in pairs(data.required_bedrock) do
        DATA.resource_set_required_bedrock(id, i - 1, value)
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
void dcon_resource_set_r(int32_t, float);
float dcon_resource_get_r(int32_t);
void dcon_resource_set_g(int32_t, float);
float dcon_resource_get_g(int32_t);
void dcon_resource_set_b(int32_t, float);
float dcon_resource_get_b(int32_t);
void dcon_resource_resize_required_biome(uint32_t);
void dcon_resource_set_required_biome(int32_t, int32_t, uint32_t);
uint32_t dcon_resource_get_required_biome(int32_t, int32_t);
void dcon_resource_resize_required_bedrock(uint32_t);
void dcon_resource_set_required_bedrock(int32_t, int32_t, uint32_t);
uint32_t dcon_resource_get_required_bedrock(int32_t, int32_t);
void dcon_resource_set_base_frequency(int32_t, float);
float dcon_resource_get_base_frequency(int32_t);
void dcon_resource_set_minimum_trees(int32_t, float);
float dcon_resource_get_minimum_trees(int32_t);
void dcon_resource_set_maximum_trees(int32_t, float);
float dcon_resource_get_maximum_trees(int32_t);
void dcon_resource_set_minimum_elevation(int32_t, float);
float dcon_resource_get_minimum_elevation(int32_t);
void dcon_resource_set_maximum_elevation(int32_t, float);
float dcon_resource_get_maximum_elevation(int32_t);
int32_t dcon_create_resource();
bool dcon_resource_is_valid(int32_t);
void dcon_resource_resize(uint32_t sz);
uint32_t dcon_resource_size();
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

---resource: LUA bindings---

DATA.resource_size = 300
DCON.dcon_resource_resize_required_biome(21)
DCON.dcon_resource_resize_required_bedrock(21)
---@return resource_id
function DATA.create_resource()
    ---@type resource_id
    local i  = DCON.dcon_create_resource() + 1
    return i --[[@as resource_id]]
end
---@param func fun(item: resource_id)
function DATA.for_each_resource(func)
    ---@type number
    local range = DCON.dcon_resource_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as resource_id]])
    end
end
---@param func fun(item: resource_id):boolean
---@return table<resource_id, resource_id>
function DATA.filter_resource(func)
    ---@type table<resource_id, resource_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_resource_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as resource_id]]) then t[i + 1 --[[@as resource_id]]] = t[i + 1 --[[@as resource_id]]] end
    end
    return t
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
    return DCON.dcon_resource_get_r(resource_id - 1)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_r(resource_id, value)
    DCON.dcon_resource_set_r(resource_id - 1, value)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_inc_r(resource_id, value)
    ---@type number
    local current = DCON.dcon_resource_get_r(resource_id - 1)
    DCON.dcon_resource_set_r(resource_id - 1, current + value)
end
---@param resource_id resource_id valid resource id
---@return number g
function DATA.resource_get_g(resource_id)
    return DCON.dcon_resource_get_g(resource_id - 1)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_g(resource_id, value)
    DCON.dcon_resource_set_g(resource_id - 1, value)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_inc_g(resource_id, value)
    ---@type number
    local current = DCON.dcon_resource_get_g(resource_id - 1)
    DCON.dcon_resource_set_g(resource_id - 1, current + value)
end
---@param resource_id resource_id valid resource id
---@return number b
function DATA.resource_get_b(resource_id)
    return DCON.dcon_resource_get_b(resource_id - 1)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_b(resource_id, value)
    DCON.dcon_resource_set_b(resource_id - 1, value)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_inc_b(resource_id, value)
    ---@type number
    local current = DCON.dcon_resource_get_b(resource_id - 1)
    DCON.dcon_resource_set_b(resource_id - 1, current + value)
end
---@param resource_id resource_id valid resource id
---@param index number valid
---@return biome_id required_biome
function DATA.resource_get_required_biome(resource_id, index)
    assert(index ~= 0)
    return DCON.dcon_resource_get_required_biome(resource_id - 1, index - 1) + 1
end
---@param resource_id resource_id valid resource id
---@param index number valid index
---@param value biome_id valid biome_id
function DATA.resource_set_required_biome(resource_id, index, value)
    DCON.dcon_resource_set_required_biome(resource_id - 1, index - 1, value)
end
---@param resource_id resource_id valid resource id
---@param index number valid
---@return bedrock_id required_bedrock
function DATA.resource_get_required_bedrock(resource_id, index)
    assert(index ~= 0)
    return DCON.dcon_resource_get_required_bedrock(resource_id - 1, index - 1) + 1
end
---@param resource_id resource_id valid resource id
---@param index number valid index
---@param value bedrock_id valid bedrock_id
function DATA.resource_set_required_bedrock(resource_id, index, value)
    DCON.dcon_resource_set_required_bedrock(resource_id - 1, index - 1, value)
end
---@param resource_id resource_id valid resource id
---@return number base_frequency number of tiles per which this resource is spawned
function DATA.resource_get_base_frequency(resource_id)
    return DCON.dcon_resource_get_base_frequency(resource_id - 1)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_base_frequency(resource_id, value)
    DCON.dcon_resource_set_base_frequency(resource_id - 1, value)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_inc_base_frequency(resource_id, value)
    ---@type number
    local current = DCON.dcon_resource_get_base_frequency(resource_id - 1)
    DCON.dcon_resource_set_base_frequency(resource_id - 1, current + value)
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
    return DCON.dcon_resource_get_minimum_trees(resource_id - 1)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_minimum_trees(resource_id, value)
    DCON.dcon_resource_set_minimum_trees(resource_id - 1, value)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_inc_minimum_trees(resource_id, value)
    ---@type number
    local current = DCON.dcon_resource_get_minimum_trees(resource_id - 1)
    DCON.dcon_resource_set_minimum_trees(resource_id - 1, current + value)
end
---@param resource_id resource_id valid resource id
---@return number maximum_trees
function DATA.resource_get_maximum_trees(resource_id)
    return DCON.dcon_resource_get_maximum_trees(resource_id - 1)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_maximum_trees(resource_id, value)
    DCON.dcon_resource_set_maximum_trees(resource_id - 1, value)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_inc_maximum_trees(resource_id, value)
    ---@type number
    local current = DCON.dcon_resource_get_maximum_trees(resource_id - 1)
    DCON.dcon_resource_set_maximum_trees(resource_id - 1, current + value)
end
---@param resource_id resource_id valid resource id
---@return number minimum_elevation
function DATA.resource_get_minimum_elevation(resource_id)
    return DCON.dcon_resource_get_minimum_elevation(resource_id - 1)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_minimum_elevation(resource_id, value)
    DCON.dcon_resource_set_minimum_elevation(resource_id - 1, value)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_inc_minimum_elevation(resource_id, value)
    ---@type number
    local current = DCON.dcon_resource_get_minimum_elevation(resource_id - 1)
    DCON.dcon_resource_set_minimum_elevation(resource_id - 1, current + value)
end
---@param resource_id resource_id valid resource id
---@return number maximum_elevation
function DATA.resource_get_maximum_elevation(resource_id)
    return DCON.dcon_resource_get_maximum_elevation(resource_id - 1)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_set_maximum_elevation(resource_id, value)
    DCON.dcon_resource_set_maximum_elevation(resource_id - 1, value)
end
---@param resource_id resource_id valid resource id
---@param value number valid number
function DATA.resource_inc_maximum_elevation(resource_id, value)
    ---@type number
    local current = DCON.dcon_resource_get_maximum_elevation(resource_id - 1)
    DCON.dcon_resource_set_maximum_elevation(resource_id - 1, current + value)
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
---@class (exact) unit_type_id : number
---@field is_unit_type nil

---@class (exact) fat_unit_type_id
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
---@field base_health number?
---@field base_attack number?
---@field base_armor number?
---@field speed number?
---@field foraging number? how much food does this unit forage from the local province?
---@field bonuses table<unit_type_id, number>
---@field supply_capacity number? how much food can this unit carry
---@field unlocked_by technology_id
---@field spotting number?
---@field visibility number?
---Sets values of unit_type for given id
---@param id unit_type_id
---@param data unit_type_id_data_blob_definition
function DATA.setup_unit_type(id, data)
    DATA.unit_type_set_base_price(id, 10)
    DATA.unit_type_set_upkeep(id, 0.5)
    DATA.unit_type_set_supply_used(id, 1)
    DATA.unit_type_set_base_health(id, 50)
    DATA.unit_type_set_base_attack(id, 5)
    DATA.unit_type_set_base_armor(id, 1)
    DATA.unit_type_set_speed(id, 1)
    DATA.unit_type_set_foraging(id, 0.1)
    DATA.unit_type_set_supply_capacity(id, 5)
    DATA.unit_type_set_spotting(id, 1)
    DATA.unit_type_set_visibility(id, 1)
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
    for i, value in pairs(data.bonuses) do
        DATA.unit_type_set_bonuses(id, i, value)
    end
    if data.supply_capacity ~= nil then
        DATA.unit_type_set_supply_capacity(id, data.supply_capacity)
    end
    if data.spotting ~= nil then
        DATA.unit_type_set_spotting(id, data.spotting)
    end
    if data.visibility ~= nil then
        DATA.unit_type_set_visibility(id, data.visibility)
    end
end

ffi.cdef[[
void dcon_unit_type_set_r(int32_t, float);
float dcon_unit_type_get_r(int32_t);
void dcon_unit_type_set_g(int32_t, float);
float dcon_unit_type_get_g(int32_t);
void dcon_unit_type_set_b(int32_t, float);
float dcon_unit_type_get_b(int32_t);
void dcon_unit_type_set_base_price(int32_t, float);
float dcon_unit_type_get_base_price(int32_t);
void dcon_unit_type_set_upkeep(int32_t, float);
float dcon_unit_type_get_upkeep(int32_t);
void dcon_unit_type_set_supply_used(int32_t, float);
float dcon_unit_type_get_supply_used(int32_t);
void dcon_unit_type_resize_trade_good_requirements(uint32_t);
trade_good_container* dcon_unit_type_get_trade_good_requirements(int32_t, int32_t);
void dcon_unit_type_set_base_health(int32_t, float);
float dcon_unit_type_get_base_health(int32_t);
void dcon_unit_type_set_base_attack(int32_t, float);
float dcon_unit_type_get_base_attack(int32_t);
void dcon_unit_type_set_base_armor(int32_t, float);
float dcon_unit_type_get_base_armor(int32_t);
void dcon_unit_type_set_speed(int32_t, float);
float dcon_unit_type_get_speed(int32_t);
void dcon_unit_type_set_foraging(int32_t, float);
float dcon_unit_type_get_foraging(int32_t);
void dcon_unit_type_resize_bonuses(uint32_t);
void dcon_unit_type_set_bonuses(int32_t, int32_t, float);
float dcon_unit_type_get_bonuses(int32_t, int32_t);
void dcon_unit_type_set_supply_capacity(int32_t, float);
float dcon_unit_type_get_supply_capacity(int32_t);
void dcon_unit_type_set_spotting(int32_t, float);
float dcon_unit_type_get_spotting(int32_t);
void dcon_unit_type_set_visibility(int32_t, float);
float dcon_unit_type_get_visibility(int32_t);
int32_t dcon_create_unit_type();
bool dcon_unit_type_is_valid(int32_t);
void dcon_unit_type_resize(uint32_t sz);
uint32_t dcon_unit_type_size();
]]

---unit_type: FFI arrays---
---@type (string)[]
DATA.unit_type_name= {}
---@type (string)[]
DATA.unit_type_icon= {}
---@type (string)[]
DATA.unit_type_description= {}

---unit_type: LUA bindings---

DATA.unit_type_size = 20
DCON.dcon_unit_type_resize_trade_good_requirements(11)
DCON.dcon_unit_type_resize_bonuses(21)
---@return unit_type_id
function DATA.create_unit_type()
    ---@type unit_type_id
    local i  = DCON.dcon_create_unit_type() + 1
    return i --[[@as unit_type_id]]
end
---@param func fun(item: unit_type_id)
function DATA.for_each_unit_type(func)
    ---@type number
    local range = DCON.dcon_unit_type_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as unit_type_id]])
    end
end
---@param func fun(item: unit_type_id):boolean
---@return table<unit_type_id, unit_type_id>
function DATA.filter_unit_type(func)
    ---@type table<unit_type_id, unit_type_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_unit_type_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as unit_type_id]]) then t[i + 1 --[[@as unit_type_id]]] = t[i + 1 --[[@as unit_type_id]]] end
    end
    return t
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
    return DCON.dcon_unit_type_get_r(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_r(unit_type_id, value)
    DCON.dcon_unit_type_set_r(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_r(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_r(unit_type_id - 1)
    DCON.dcon_unit_type_set_r(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number g
function DATA.unit_type_get_g(unit_type_id)
    return DCON.dcon_unit_type_get_g(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_g(unit_type_id, value)
    DCON.dcon_unit_type_set_g(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_g(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_g(unit_type_id - 1)
    DCON.dcon_unit_type_set_g(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number b
function DATA.unit_type_get_b(unit_type_id)
    return DCON.dcon_unit_type_get_b(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_b(unit_type_id, value)
    DCON.dcon_unit_type_set_b(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_b(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_b(unit_type_id - 1)
    DCON.dcon_unit_type_set_b(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number base_price
function DATA.unit_type_get_base_price(unit_type_id)
    return DCON.dcon_unit_type_get_base_price(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_base_price(unit_type_id, value)
    DCON.dcon_unit_type_set_base_price(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_base_price(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_base_price(unit_type_id - 1)
    DCON.dcon_unit_type_set_base_price(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number upkeep
function DATA.unit_type_get_upkeep(unit_type_id)
    return DCON.dcon_unit_type_get_upkeep(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_upkeep(unit_type_id, value)
    DCON.dcon_unit_type_set_upkeep(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_upkeep(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_upkeep(unit_type_id - 1)
    DCON.dcon_unit_type_set_upkeep(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number supply_used how much food does this unit consume each month
function DATA.unit_type_get_supply_used(unit_type_id)
    return DCON.dcon_unit_type_get_supply_used(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_supply_used(unit_type_id, value)
    DCON.dcon_unit_type_set_supply_used(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_supply_used(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_supply_used(unit_type_id - 1)
    DCON.dcon_unit_type_set_supply_used(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index number valid
---@return trade_good_id trade_good_requirements
function DATA.unit_type_get_trade_good_requirements_good(unit_type_id, index)
    assert(index ~= 0)
    return DCON.dcon_unit_type_get_trade_good_requirements(unit_type_id - 1, index - 1)[0].good
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index number valid
---@return number trade_good_requirements
function DATA.unit_type_get_trade_good_requirements_amount(unit_type_id, index)
    assert(index ~= 0)
    return DCON.dcon_unit_type_get_trade_good_requirements(unit_type_id - 1, index - 1)[0].amount
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index number valid index
---@param value trade_good_id valid trade_good_id
function DATA.unit_type_set_trade_good_requirements_good(unit_type_id, index, value)
    DCON.dcon_unit_type_get_trade_good_requirements(unit_type_id - 1, index - 1)[0].good = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index number valid index
---@param value number valid number
function DATA.unit_type_set_trade_good_requirements_amount(unit_type_id, index, value)
    DCON.dcon_unit_type_get_trade_good_requirements(unit_type_id - 1, index - 1)[0].amount = value
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index number valid index
---@param value number valid number
function DATA.unit_type_inc_trade_good_requirements_amount(unit_type_id, index, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_trade_good_requirements(unit_type_id - 1, index - 1)[0].amount
    DCON.dcon_unit_type_get_trade_good_requirements(unit_type_id - 1, index - 1)[0].amount = current + value
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number base_health
function DATA.unit_type_get_base_health(unit_type_id)
    return DCON.dcon_unit_type_get_base_health(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_base_health(unit_type_id, value)
    DCON.dcon_unit_type_set_base_health(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_base_health(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_base_health(unit_type_id - 1)
    DCON.dcon_unit_type_set_base_health(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number base_attack
function DATA.unit_type_get_base_attack(unit_type_id)
    return DCON.dcon_unit_type_get_base_attack(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_base_attack(unit_type_id, value)
    DCON.dcon_unit_type_set_base_attack(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_base_attack(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_base_attack(unit_type_id - 1)
    DCON.dcon_unit_type_set_base_attack(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number base_armor
function DATA.unit_type_get_base_armor(unit_type_id)
    return DCON.dcon_unit_type_get_base_armor(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_base_armor(unit_type_id, value)
    DCON.dcon_unit_type_set_base_armor(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_base_armor(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_base_armor(unit_type_id - 1)
    DCON.dcon_unit_type_set_base_armor(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number speed
function DATA.unit_type_get_speed(unit_type_id)
    return DCON.dcon_unit_type_get_speed(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_speed(unit_type_id, value)
    DCON.dcon_unit_type_set_speed(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_speed(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_speed(unit_type_id - 1)
    DCON.dcon_unit_type_set_speed(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number foraging how much food does this unit forage from the local province?
function DATA.unit_type_get_foraging(unit_type_id)
    return DCON.dcon_unit_type_get_foraging(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_foraging(unit_type_id, value)
    DCON.dcon_unit_type_set_foraging(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_foraging(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_foraging(unit_type_id - 1)
    DCON.dcon_unit_type_set_foraging(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index unit_type_id valid
---@return number bonuses
function DATA.unit_type_get_bonuses(unit_type_id, index)
    assert(index ~= 0)
    return DCON.dcon_unit_type_get_bonuses(unit_type_id - 1, index - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index unit_type_id valid index
---@param value number valid number
function DATA.unit_type_set_bonuses(unit_type_id, index, value)
    DCON.dcon_unit_type_set_bonuses(unit_type_id - 1, index - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param index unit_type_id valid index
---@param value number valid number
function DATA.unit_type_inc_bonuses(unit_type_id, index, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_bonuses(unit_type_id - 1, index - 1)
    DCON.dcon_unit_type_set_bonuses(unit_type_id - 1, index - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number supply_capacity how much food can this unit carry
function DATA.unit_type_get_supply_capacity(unit_type_id)
    return DCON.dcon_unit_type_get_supply_capacity(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_supply_capacity(unit_type_id, value)
    DCON.dcon_unit_type_set_supply_capacity(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_supply_capacity(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_supply_capacity(unit_type_id - 1)
    DCON.dcon_unit_type_set_supply_capacity(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number spotting
function DATA.unit_type_get_spotting(unit_type_id)
    return DCON.dcon_unit_type_get_spotting(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_spotting(unit_type_id, value)
    DCON.dcon_unit_type_set_spotting(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_spotting(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_spotting(unit_type_id - 1)
    DCON.dcon_unit_type_set_spotting(unit_type_id - 1, current + value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@return number visibility
function DATA.unit_type_get_visibility(unit_type_id)
    return DCON.dcon_unit_type_get_visibility(unit_type_id - 1)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_set_visibility(unit_type_id, value)
    DCON.dcon_unit_type_set_visibility(unit_type_id - 1, value)
end
---@param unit_type_id unit_type_id valid unit_type id
---@param value number valid number
function DATA.unit_type_inc_visibility(unit_type_id, value)
    ---@type number
    local current = DCON.dcon_unit_type_get_visibility(unit_type_id - 1)
    DCON.dcon_unit_type_set_visibility(unit_type_id - 1, current + value)
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
----------job----------


---job: LSP types---

---Unique identificator for job entity
---@class (exact) job_id : number
---@field is_job nil

---@class (exact) fat_job_id
---@field id job_id Unique job id
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number

---@class struct_job
---@field r number
---@field g number
---@field b number

---@class (exact) job_id_data_blob_definition
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---Sets values of job for given id
---@param id job_id
---@param data job_id_data_blob_definition
function DATA.setup_job(id, data)
    DATA.job_set_name(id, data.name)
    DATA.job_set_icon(id, data.icon)
    DATA.job_set_description(id, data.description)
    DATA.job_set_r(id, data.r)
    DATA.job_set_g(id, data.g)
    DATA.job_set_b(id, data.b)
end

ffi.cdef[[
void dcon_job_set_r(int32_t, float);
float dcon_job_get_r(int32_t);
void dcon_job_set_g(int32_t, float);
float dcon_job_get_g(int32_t);
void dcon_job_set_b(int32_t, float);
float dcon_job_get_b(int32_t);
int32_t dcon_create_job();
bool dcon_job_is_valid(int32_t);
void dcon_job_resize(uint32_t sz);
uint32_t dcon_job_size();
]]

---job: FFI arrays---
---@type (string)[]
DATA.job_name= {}
---@type (string)[]
DATA.job_icon= {}
---@type (string)[]
DATA.job_description= {}

---job: LUA bindings---

DATA.job_size = 250
---@return job_id
function DATA.create_job()
    ---@type job_id
    local i  = DCON.dcon_create_job() + 1
    return i --[[@as job_id]]
end
---@param func fun(item: job_id)
function DATA.for_each_job(func)
    ---@type number
    local range = DCON.dcon_job_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as job_id]])
    end
end
---@param func fun(item: job_id):boolean
---@return table<job_id, job_id>
function DATA.filter_job(func)
    ---@type table<job_id, job_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_job_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as job_id]]) then t[i + 1 --[[@as job_id]]] = t[i + 1 --[[@as job_id]]] end
    end
    return t
end

---@param job_id job_id valid job id
---@return string name
function DATA.job_get_name(job_id)
    return DATA.job_name[job_id]
end
---@param job_id job_id valid job id
---@param value string valid string
function DATA.job_set_name(job_id, value)
    DATA.job_name[job_id] = value
end
---@param job_id job_id valid job id
---@return string icon
function DATA.job_get_icon(job_id)
    return DATA.job_icon[job_id]
end
---@param job_id job_id valid job id
---@param value string valid string
function DATA.job_set_icon(job_id, value)
    DATA.job_icon[job_id] = value
end
---@param job_id job_id valid job id
---@return string description
function DATA.job_get_description(job_id)
    return DATA.job_description[job_id]
end
---@param job_id job_id valid job id
---@param value string valid string
function DATA.job_set_description(job_id, value)
    DATA.job_description[job_id] = value
end
---@param job_id job_id valid job id
---@return number r
function DATA.job_get_r(job_id)
    return DCON.dcon_job_get_r(job_id - 1)
end
---@param job_id job_id valid job id
---@param value number valid number
function DATA.job_set_r(job_id, value)
    DCON.dcon_job_set_r(job_id - 1, value)
end
---@param job_id job_id valid job id
---@param value number valid number
function DATA.job_inc_r(job_id, value)
    ---@type number
    local current = DCON.dcon_job_get_r(job_id - 1)
    DCON.dcon_job_set_r(job_id - 1, current + value)
end
---@param job_id job_id valid job id
---@return number g
function DATA.job_get_g(job_id)
    return DCON.dcon_job_get_g(job_id - 1)
end
---@param job_id job_id valid job id
---@param value number valid number
function DATA.job_set_g(job_id, value)
    DCON.dcon_job_set_g(job_id - 1, value)
end
---@param job_id job_id valid job id
---@param value number valid number
function DATA.job_inc_g(job_id, value)
    ---@type number
    local current = DCON.dcon_job_get_g(job_id - 1)
    DCON.dcon_job_set_g(job_id - 1, current + value)
end
---@param job_id job_id valid job id
---@return number b
function DATA.job_get_b(job_id)
    return DCON.dcon_job_get_b(job_id - 1)
end
---@param job_id job_id valid job id
---@param value number valid number
function DATA.job_set_b(job_id, value)
    DCON.dcon_job_set_b(job_id - 1, value)
end
---@param job_id job_id valid job id
---@param value number valid number
function DATA.job_inc_b(job_id, value)
    ---@type number
    local current = DCON.dcon_job_get_b(job_id - 1)
    DCON.dcon_job_set_b(job_id - 1, current + value)
end

local fat_job_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.job_get_name(t.id) end
        if (k == "icon") then return DATA.job_get_icon(t.id) end
        if (k == "description") then return DATA.job_get_description(t.id) end
        if (k == "r") then return DATA.job_get_r(t.id) end
        if (k == "g") then return DATA.job_get_g(t.id) end
        if (k == "b") then return DATA.job_get_b(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.job_set_name(t.id, v)
            return
        end
        if (k == "icon") then
            DATA.job_set_icon(t.id, v)
            return
        end
        if (k == "description") then
            DATA.job_set_description(t.id, v)
            return
        end
        if (k == "r") then
            DATA.job_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.job_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.job_set_b(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id job_id
---@return fat_job_id fat_id
function DATA.fatten_job(id)
    local result = {id = id}
    setmetatable(result, fat_job_id_metatable)    return result
end
----------production_method----------


---production_method: LSP types---

---Unique identificator for production_method entity
---@class (exact) production_method_id : number
---@field is_production_method nil

---@class (exact) fat_production_method_id
---@field id production_method_id Unique production_method id
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field job_type JOBTYPE
---@field foraging boolean If true, worktime counts towards the foragers count
---@field hydration boolean If true, worktime counts towards the foragers_water count
---@field nature_yield_dependence number How much does the local flora and fauna impact this buildings yield? Defaults to 0
---@field forest_dependence number Set to 1 if building consumes local forests
---@field crop boolean If true, the building will periodically change its yield for a season.
---@field temperature_ideal_min number
---@field temperature_ideal_max number
---@field temperature_extreme_min number
---@field temperature_extreme_max number
---@field rainfall_ideal_min number
---@field rainfall_ideal_max number
---@field rainfall_extreme_min number
---@field rainfall_extreme_max number
---@field clay_ideal_min number
---@field clay_ideal_max number
---@field clay_extreme_min number
---@field clay_extreme_max number

---@class struct_production_method
---@field r number
---@field g number
---@field b number
---@field job_type JOBTYPE
---@field jobs table<number, struct_job_container>
---@field inputs table<number, struct_use_case_container>
---@field outputs table<number, struct_trade_good_container>
---@field foraging boolean If true, worktime counts towards the foragers count
---@field hydration boolean If true, worktime counts towards the foragers_water count
---@field nature_yield_dependence number How much does the local flora and fauna impact this buildings yield? Defaults to 0
---@field forest_dependence number Set to 1 if building consumes local forests
---@field crop boolean If true, the building will periodically change its yield for a season.
---@field temperature_ideal_min number
---@field temperature_ideal_max number
---@field temperature_extreme_min number
---@field temperature_extreme_max number
---@field rainfall_ideal_min number
---@field rainfall_ideal_max number
---@field rainfall_extreme_min number
---@field rainfall_extreme_max number
---@field clay_ideal_min number
---@field clay_ideal_max number
---@field clay_extreme_min number
---@field clay_extreme_max number

---@class (exact) production_method_id_data_blob_definition
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field job_type JOBTYPE
---@field foraging boolean? If true, worktime counts towards the foragers count
---@field hydration boolean? If true, worktime counts towards the foragers_water count
---@field nature_yield_dependence number? How much does the local flora and fauna impact this buildings yield? Defaults to 0
---@field forest_dependence number? Set to 1 if building consumes local forests
---@field crop boolean? If true, the building will periodically change its yield for a season.
---@field temperature_ideal_min number?
---@field temperature_ideal_max number?
---@field temperature_extreme_min number?
---@field temperature_extreme_max number?
---@field rainfall_ideal_min number?
---@field rainfall_ideal_max number?
---@field rainfall_extreme_min number?
---@field rainfall_extreme_max number?
---@field clay_ideal_min number?
---@field clay_ideal_max number?
---@field clay_extreme_min number?
---@field clay_extreme_max number?
---Sets values of production_method for given id
---@param id production_method_id
---@param data production_method_id_data_blob_definition
function DATA.setup_production_method(id, data)
    DATA.production_method_set_foraging(id, false)
    DATA.production_method_set_hydration(id, false)
    DATA.production_method_set_nature_yield_dependence(id, 0)
    DATA.production_method_set_forest_dependence(id, 0)
    DATA.production_method_set_crop(id, false)
    DATA.production_method_set_temperature_ideal_min(id, 10)
    DATA.production_method_set_temperature_ideal_max(id, 30)
    DATA.production_method_set_temperature_extreme_min(id, 0)
    DATA.production_method_set_temperature_extreme_max(id, 50)
    DATA.production_method_set_rainfall_ideal_min(id, 50)
    DATA.production_method_set_rainfall_ideal_max(id, 100)
    DATA.production_method_set_rainfall_extreme_min(id, 5)
    DATA.production_method_set_rainfall_extreme_max(id, 350)
    DATA.production_method_set_clay_ideal_min(id, 0)
    DATA.production_method_set_clay_ideal_max(id, 1)
    DATA.production_method_set_clay_extreme_min(id, 0)
    DATA.production_method_set_clay_extreme_max(id, 1)
    DATA.production_method_set_name(id, data.name)
    DATA.production_method_set_icon(id, data.icon)
    DATA.production_method_set_description(id, data.description)
    DATA.production_method_set_r(id, data.r)
    DATA.production_method_set_g(id, data.g)
    DATA.production_method_set_b(id, data.b)
    DATA.production_method_set_job_type(id, data.job_type)
    if data.foraging ~= nil then
        DATA.production_method_set_foraging(id, data.foraging)
    end
    if data.hydration ~= nil then
        DATA.production_method_set_hydration(id, data.hydration)
    end
    if data.nature_yield_dependence ~= nil then
        DATA.production_method_set_nature_yield_dependence(id, data.nature_yield_dependence)
    end
    if data.forest_dependence ~= nil then
        DATA.production_method_set_forest_dependence(id, data.forest_dependence)
    end
    if data.crop ~= nil then
        DATA.production_method_set_crop(id, data.crop)
    end
    if data.temperature_ideal_min ~= nil then
        DATA.production_method_set_temperature_ideal_min(id, data.temperature_ideal_min)
    end
    if data.temperature_ideal_max ~= nil then
        DATA.production_method_set_temperature_ideal_max(id, data.temperature_ideal_max)
    end
    if data.temperature_extreme_min ~= nil then
        DATA.production_method_set_temperature_extreme_min(id, data.temperature_extreme_min)
    end
    if data.temperature_extreme_max ~= nil then
        DATA.production_method_set_temperature_extreme_max(id, data.temperature_extreme_max)
    end
    if data.rainfall_ideal_min ~= nil then
        DATA.production_method_set_rainfall_ideal_min(id, data.rainfall_ideal_min)
    end
    if data.rainfall_ideal_max ~= nil then
        DATA.production_method_set_rainfall_ideal_max(id, data.rainfall_ideal_max)
    end
    if data.rainfall_extreme_min ~= nil then
        DATA.production_method_set_rainfall_extreme_min(id, data.rainfall_extreme_min)
    end
    if data.rainfall_extreme_max ~= nil then
        DATA.production_method_set_rainfall_extreme_max(id, data.rainfall_extreme_max)
    end
    if data.clay_ideal_min ~= nil then
        DATA.production_method_set_clay_ideal_min(id, data.clay_ideal_min)
    end
    if data.clay_ideal_max ~= nil then
        DATA.production_method_set_clay_ideal_max(id, data.clay_ideal_max)
    end
    if data.clay_extreme_min ~= nil then
        DATA.production_method_set_clay_extreme_min(id, data.clay_extreme_min)
    end
    if data.clay_extreme_max ~= nil then
        DATA.production_method_set_clay_extreme_max(id, data.clay_extreme_max)
    end
end

ffi.cdef[[
void dcon_production_method_set_r(int32_t, float);
float dcon_production_method_get_r(int32_t);
void dcon_production_method_set_g(int32_t, float);
float dcon_production_method_get_g(int32_t);
void dcon_production_method_set_b(int32_t, float);
float dcon_production_method_get_b(int32_t);
void dcon_production_method_set_job_type(int32_t, uint8_t);
uint8_t dcon_production_method_get_job_type(int32_t);
void dcon_production_method_resize_jobs(uint32_t);
job_container* dcon_production_method_get_jobs(int32_t, int32_t);
void dcon_production_method_resize_inputs(uint32_t);
use_case_container* dcon_production_method_get_inputs(int32_t, int32_t);
void dcon_production_method_resize_outputs(uint32_t);
trade_good_container* dcon_production_method_get_outputs(int32_t, int32_t);
void dcon_production_method_set_foraging(int32_t, bool);
bool dcon_production_method_get_foraging(int32_t);
void dcon_production_method_set_hydration(int32_t, bool);
bool dcon_production_method_get_hydration(int32_t);
void dcon_production_method_set_nature_yield_dependence(int32_t, float);
float dcon_production_method_get_nature_yield_dependence(int32_t);
void dcon_production_method_set_forest_dependence(int32_t, float);
float dcon_production_method_get_forest_dependence(int32_t);
void dcon_production_method_set_crop(int32_t, bool);
bool dcon_production_method_get_crop(int32_t);
void dcon_production_method_set_temperature_ideal_min(int32_t, float);
float dcon_production_method_get_temperature_ideal_min(int32_t);
void dcon_production_method_set_temperature_ideal_max(int32_t, float);
float dcon_production_method_get_temperature_ideal_max(int32_t);
void dcon_production_method_set_temperature_extreme_min(int32_t, float);
float dcon_production_method_get_temperature_extreme_min(int32_t);
void dcon_production_method_set_temperature_extreme_max(int32_t, float);
float dcon_production_method_get_temperature_extreme_max(int32_t);
void dcon_production_method_set_rainfall_ideal_min(int32_t, float);
float dcon_production_method_get_rainfall_ideal_min(int32_t);
void dcon_production_method_set_rainfall_ideal_max(int32_t, float);
float dcon_production_method_get_rainfall_ideal_max(int32_t);
void dcon_production_method_set_rainfall_extreme_min(int32_t, float);
float dcon_production_method_get_rainfall_extreme_min(int32_t);
void dcon_production_method_set_rainfall_extreme_max(int32_t, float);
float dcon_production_method_get_rainfall_extreme_max(int32_t);
void dcon_production_method_set_clay_ideal_min(int32_t, float);
float dcon_production_method_get_clay_ideal_min(int32_t);
void dcon_production_method_set_clay_ideal_max(int32_t, float);
float dcon_production_method_get_clay_ideal_max(int32_t);
void dcon_production_method_set_clay_extreme_min(int32_t, float);
float dcon_production_method_get_clay_extreme_min(int32_t);
void dcon_production_method_set_clay_extreme_max(int32_t, float);
float dcon_production_method_get_clay_extreme_max(int32_t);
int32_t dcon_create_production_method();
bool dcon_production_method_is_valid(int32_t);
void dcon_production_method_resize(uint32_t sz);
uint32_t dcon_production_method_size();
]]

---production_method: FFI arrays---
---@type (string)[]
DATA.production_method_name= {}
---@type (string)[]
DATA.production_method_icon= {}
---@type (string)[]
DATA.production_method_description= {}

---production_method: LUA bindings---

DATA.production_method_size = 250
DCON.dcon_production_method_resize_jobs(9)
DCON.dcon_production_method_resize_inputs(9)
DCON.dcon_production_method_resize_outputs(9)
---@return production_method_id
function DATA.create_production_method()
    ---@type production_method_id
    local i  = DCON.dcon_create_production_method() + 1
    return i --[[@as production_method_id]]
end
---@param func fun(item: production_method_id)
function DATA.for_each_production_method(func)
    ---@type number
    local range = DCON.dcon_production_method_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as production_method_id]])
    end
end
---@param func fun(item: production_method_id):boolean
---@return table<production_method_id, production_method_id>
function DATA.filter_production_method(func)
    ---@type table<production_method_id, production_method_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_production_method_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as production_method_id]]) then t[i + 1 --[[@as production_method_id]]] = t[i + 1 --[[@as production_method_id]]] end
    end
    return t
end

---@param production_method_id production_method_id valid production_method id
---@return string name
function DATA.production_method_get_name(production_method_id)
    return DATA.production_method_name[production_method_id]
end
---@param production_method_id production_method_id valid production_method id
---@param value string valid string
function DATA.production_method_set_name(production_method_id, value)
    DATA.production_method_name[production_method_id] = value
end
---@param production_method_id production_method_id valid production_method id
---@return string icon
function DATA.production_method_get_icon(production_method_id)
    return DATA.production_method_icon[production_method_id]
end
---@param production_method_id production_method_id valid production_method id
---@param value string valid string
function DATA.production_method_set_icon(production_method_id, value)
    DATA.production_method_icon[production_method_id] = value
end
---@param production_method_id production_method_id valid production_method id
---@return string description
function DATA.production_method_get_description(production_method_id)
    return DATA.production_method_description[production_method_id]
end
---@param production_method_id production_method_id valid production_method id
---@param value string valid string
function DATA.production_method_set_description(production_method_id, value)
    DATA.production_method_description[production_method_id] = value
end
---@param production_method_id production_method_id valid production_method id
---@return number r
function DATA.production_method_get_r(production_method_id)
    return DCON.dcon_production_method_get_r(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_r(production_method_id, value)
    DCON.dcon_production_method_set_r(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_r(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_r(production_method_id - 1)
    DCON.dcon_production_method_set_r(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number g
function DATA.production_method_get_g(production_method_id)
    return DCON.dcon_production_method_get_g(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_g(production_method_id, value)
    DCON.dcon_production_method_set_g(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_g(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_g(production_method_id - 1)
    DCON.dcon_production_method_set_g(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number b
function DATA.production_method_get_b(production_method_id)
    return DCON.dcon_production_method_get_b(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_b(production_method_id, value)
    DCON.dcon_production_method_set_b(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_b(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_b(production_method_id - 1)
    DCON.dcon_production_method_set_b(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return JOBTYPE job_type
function DATA.production_method_get_job_type(production_method_id)
    return DCON.dcon_production_method_get_job_type(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value JOBTYPE valid JOBTYPE
function DATA.production_method_set_job_type(production_method_id, value)
    DCON.dcon_production_method_set_job_type(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid
---@return job_id jobs
function DATA.production_method_get_jobs_job(production_method_id, index)
    assert(index ~= 0)
    return DCON.dcon_production_method_get_jobs(production_method_id - 1, index - 1)[0].job
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid
---@return number jobs
function DATA.production_method_get_jobs_amount(production_method_id, index)
    assert(index ~= 0)
    return DCON.dcon_production_method_get_jobs(production_method_id - 1, index - 1)[0].amount
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid index
---@param value job_id valid job_id
function DATA.production_method_set_jobs_job(production_method_id, index, value)
    DCON.dcon_production_method_get_jobs(production_method_id - 1, index - 1)[0].job = value
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid index
---@param value number valid number
function DATA.production_method_set_jobs_amount(production_method_id, index, value)
    DCON.dcon_production_method_get_jobs(production_method_id - 1, index - 1)[0].amount = value
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid index
---@param value number valid number
function DATA.production_method_inc_jobs_amount(production_method_id, index, value)
    ---@type number
    local current = DCON.dcon_production_method_get_jobs(production_method_id - 1, index - 1)[0].amount
    DCON.dcon_production_method_get_jobs(production_method_id - 1, index - 1)[0].amount = current + value
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid
---@return use_case_id inputs
function DATA.production_method_get_inputs_use(production_method_id, index)
    assert(index ~= 0)
    return DCON.dcon_production_method_get_inputs(production_method_id - 1, index - 1)[0].use
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid
---@return number inputs
function DATA.production_method_get_inputs_amount(production_method_id, index)
    assert(index ~= 0)
    return DCON.dcon_production_method_get_inputs(production_method_id - 1, index - 1)[0].amount
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid index
---@param value use_case_id valid use_case_id
function DATA.production_method_set_inputs_use(production_method_id, index, value)
    DCON.dcon_production_method_get_inputs(production_method_id - 1, index - 1)[0].use = value
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid index
---@param value number valid number
function DATA.production_method_set_inputs_amount(production_method_id, index, value)
    DCON.dcon_production_method_get_inputs(production_method_id - 1, index - 1)[0].amount = value
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid index
---@param value number valid number
function DATA.production_method_inc_inputs_amount(production_method_id, index, value)
    ---@type number
    local current = DCON.dcon_production_method_get_inputs(production_method_id - 1, index - 1)[0].amount
    DCON.dcon_production_method_get_inputs(production_method_id - 1, index - 1)[0].amount = current + value
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid
---@return trade_good_id outputs
function DATA.production_method_get_outputs_good(production_method_id, index)
    assert(index ~= 0)
    return DCON.dcon_production_method_get_outputs(production_method_id - 1, index - 1)[0].good
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid
---@return number outputs
function DATA.production_method_get_outputs_amount(production_method_id, index)
    assert(index ~= 0)
    return DCON.dcon_production_method_get_outputs(production_method_id - 1, index - 1)[0].amount
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid index
---@param value trade_good_id valid trade_good_id
function DATA.production_method_set_outputs_good(production_method_id, index, value)
    DCON.dcon_production_method_get_outputs(production_method_id - 1, index - 1)[0].good = value
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid index
---@param value number valid number
function DATA.production_method_set_outputs_amount(production_method_id, index, value)
    DCON.dcon_production_method_get_outputs(production_method_id - 1, index - 1)[0].amount = value
end
---@param production_method_id production_method_id valid production_method id
---@param index number valid index
---@param value number valid number
function DATA.production_method_inc_outputs_amount(production_method_id, index, value)
    ---@type number
    local current = DCON.dcon_production_method_get_outputs(production_method_id - 1, index - 1)[0].amount
    DCON.dcon_production_method_get_outputs(production_method_id - 1, index - 1)[0].amount = current + value
end
---@param production_method_id production_method_id valid production_method id
---@return boolean foraging If true, worktime counts towards the foragers count
function DATA.production_method_get_foraging(production_method_id)
    return DCON.dcon_production_method_get_foraging(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value boolean valid boolean
function DATA.production_method_set_foraging(production_method_id, value)
    DCON.dcon_production_method_set_foraging(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@return boolean hydration If true, worktime counts towards the foragers_water count
function DATA.production_method_get_hydration(production_method_id)
    return DCON.dcon_production_method_get_hydration(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value boolean valid boolean
function DATA.production_method_set_hydration(production_method_id, value)
    DCON.dcon_production_method_set_hydration(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@return number nature_yield_dependence How much does the local flora and fauna impact this buildings yield? Defaults to 0
function DATA.production_method_get_nature_yield_dependence(production_method_id)
    return DCON.dcon_production_method_get_nature_yield_dependence(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_nature_yield_dependence(production_method_id, value)
    DCON.dcon_production_method_set_nature_yield_dependence(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_nature_yield_dependence(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_nature_yield_dependence(production_method_id - 1)
    DCON.dcon_production_method_set_nature_yield_dependence(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number forest_dependence Set to 1 if building consumes local forests
function DATA.production_method_get_forest_dependence(production_method_id)
    return DCON.dcon_production_method_get_forest_dependence(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_forest_dependence(production_method_id, value)
    DCON.dcon_production_method_set_forest_dependence(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_forest_dependence(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_forest_dependence(production_method_id - 1)
    DCON.dcon_production_method_set_forest_dependence(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return boolean crop If true, the building will periodically change its yield for a season.
function DATA.production_method_get_crop(production_method_id)
    return DCON.dcon_production_method_get_crop(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value boolean valid boolean
function DATA.production_method_set_crop(production_method_id, value)
    DCON.dcon_production_method_set_crop(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@return number temperature_ideal_min
function DATA.production_method_get_temperature_ideal_min(production_method_id)
    return DCON.dcon_production_method_get_temperature_ideal_min(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_temperature_ideal_min(production_method_id, value)
    DCON.dcon_production_method_set_temperature_ideal_min(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_temperature_ideal_min(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_temperature_ideal_min(production_method_id - 1)
    DCON.dcon_production_method_set_temperature_ideal_min(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number temperature_ideal_max
function DATA.production_method_get_temperature_ideal_max(production_method_id)
    return DCON.dcon_production_method_get_temperature_ideal_max(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_temperature_ideal_max(production_method_id, value)
    DCON.dcon_production_method_set_temperature_ideal_max(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_temperature_ideal_max(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_temperature_ideal_max(production_method_id - 1)
    DCON.dcon_production_method_set_temperature_ideal_max(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number temperature_extreme_min
function DATA.production_method_get_temperature_extreme_min(production_method_id)
    return DCON.dcon_production_method_get_temperature_extreme_min(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_temperature_extreme_min(production_method_id, value)
    DCON.dcon_production_method_set_temperature_extreme_min(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_temperature_extreme_min(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_temperature_extreme_min(production_method_id - 1)
    DCON.dcon_production_method_set_temperature_extreme_min(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number temperature_extreme_max
function DATA.production_method_get_temperature_extreme_max(production_method_id)
    return DCON.dcon_production_method_get_temperature_extreme_max(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_temperature_extreme_max(production_method_id, value)
    DCON.dcon_production_method_set_temperature_extreme_max(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_temperature_extreme_max(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_temperature_extreme_max(production_method_id - 1)
    DCON.dcon_production_method_set_temperature_extreme_max(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number rainfall_ideal_min
function DATA.production_method_get_rainfall_ideal_min(production_method_id)
    return DCON.dcon_production_method_get_rainfall_ideal_min(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_rainfall_ideal_min(production_method_id, value)
    DCON.dcon_production_method_set_rainfall_ideal_min(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_rainfall_ideal_min(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_rainfall_ideal_min(production_method_id - 1)
    DCON.dcon_production_method_set_rainfall_ideal_min(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number rainfall_ideal_max
function DATA.production_method_get_rainfall_ideal_max(production_method_id)
    return DCON.dcon_production_method_get_rainfall_ideal_max(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_rainfall_ideal_max(production_method_id, value)
    DCON.dcon_production_method_set_rainfall_ideal_max(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_rainfall_ideal_max(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_rainfall_ideal_max(production_method_id - 1)
    DCON.dcon_production_method_set_rainfall_ideal_max(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number rainfall_extreme_min
function DATA.production_method_get_rainfall_extreme_min(production_method_id)
    return DCON.dcon_production_method_get_rainfall_extreme_min(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_rainfall_extreme_min(production_method_id, value)
    DCON.dcon_production_method_set_rainfall_extreme_min(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_rainfall_extreme_min(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_rainfall_extreme_min(production_method_id - 1)
    DCON.dcon_production_method_set_rainfall_extreme_min(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number rainfall_extreme_max
function DATA.production_method_get_rainfall_extreme_max(production_method_id)
    return DCON.dcon_production_method_get_rainfall_extreme_max(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_rainfall_extreme_max(production_method_id, value)
    DCON.dcon_production_method_set_rainfall_extreme_max(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_rainfall_extreme_max(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_rainfall_extreme_max(production_method_id - 1)
    DCON.dcon_production_method_set_rainfall_extreme_max(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number clay_ideal_min
function DATA.production_method_get_clay_ideal_min(production_method_id)
    return DCON.dcon_production_method_get_clay_ideal_min(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_clay_ideal_min(production_method_id, value)
    DCON.dcon_production_method_set_clay_ideal_min(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_clay_ideal_min(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_clay_ideal_min(production_method_id - 1)
    DCON.dcon_production_method_set_clay_ideal_min(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number clay_ideal_max
function DATA.production_method_get_clay_ideal_max(production_method_id)
    return DCON.dcon_production_method_get_clay_ideal_max(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_clay_ideal_max(production_method_id, value)
    DCON.dcon_production_method_set_clay_ideal_max(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_clay_ideal_max(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_clay_ideal_max(production_method_id - 1)
    DCON.dcon_production_method_set_clay_ideal_max(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number clay_extreme_min
function DATA.production_method_get_clay_extreme_min(production_method_id)
    return DCON.dcon_production_method_get_clay_extreme_min(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_clay_extreme_min(production_method_id, value)
    DCON.dcon_production_method_set_clay_extreme_min(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_clay_extreme_min(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_clay_extreme_min(production_method_id - 1)
    DCON.dcon_production_method_set_clay_extreme_min(production_method_id - 1, current + value)
end
---@param production_method_id production_method_id valid production_method id
---@return number clay_extreme_max
function DATA.production_method_get_clay_extreme_max(production_method_id)
    return DCON.dcon_production_method_get_clay_extreme_max(production_method_id - 1)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_set_clay_extreme_max(production_method_id, value)
    DCON.dcon_production_method_set_clay_extreme_max(production_method_id - 1, value)
end
---@param production_method_id production_method_id valid production_method id
---@param value number valid number
function DATA.production_method_inc_clay_extreme_max(production_method_id, value)
    ---@type number
    local current = DCON.dcon_production_method_get_clay_extreme_max(production_method_id - 1)
    DCON.dcon_production_method_set_clay_extreme_max(production_method_id - 1, current + value)
end

local fat_production_method_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.production_method_get_name(t.id) end
        if (k == "icon") then return DATA.production_method_get_icon(t.id) end
        if (k == "description") then return DATA.production_method_get_description(t.id) end
        if (k == "r") then return DATA.production_method_get_r(t.id) end
        if (k == "g") then return DATA.production_method_get_g(t.id) end
        if (k == "b") then return DATA.production_method_get_b(t.id) end
        if (k == "job_type") then return DATA.production_method_get_job_type(t.id) end
        if (k == "foraging") then return DATA.production_method_get_foraging(t.id) end
        if (k == "hydration") then return DATA.production_method_get_hydration(t.id) end
        if (k == "nature_yield_dependence") then return DATA.production_method_get_nature_yield_dependence(t.id) end
        if (k == "forest_dependence") then return DATA.production_method_get_forest_dependence(t.id) end
        if (k == "crop") then return DATA.production_method_get_crop(t.id) end
        if (k == "temperature_ideal_min") then return DATA.production_method_get_temperature_ideal_min(t.id) end
        if (k == "temperature_ideal_max") then return DATA.production_method_get_temperature_ideal_max(t.id) end
        if (k == "temperature_extreme_min") then return DATA.production_method_get_temperature_extreme_min(t.id) end
        if (k == "temperature_extreme_max") then return DATA.production_method_get_temperature_extreme_max(t.id) end
        if (k == "rainfall_ideal_min") then return DATA.production_method_get_rainfall_ideal_min(t.id) end
        if (k == "rainfall_ideal_max") then return DATA.production_method_get_rainfall_ideal_max(t.id) end
        if (k == "rainfall_extreme_min") then return DATA.production_method_get_rainfall_extreme_min(t.id) end
        if (k == "rainfall_extreme_max") then return DATA.production_method_get_rainfall_extreme_max(t.id) end
        if (k == "clay_ideal_min") then return DATA.production_method_get_clay_ideal_min(t.id) end
        if (k == "clay_ideal_max") then return DATA.production_method_get_clay_ideal_max(t.id) end
        if (k == "clay_extreme_min") then return DATA.production_method_get_clay_extreme_min(t.id) end
        if (k == "clay_extreme_max") then return DATA.production_method_get_clay_extreme_max(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.production_method_set_name(t.id, v)
            return
        end
        if (k == "icon") then
            DATA.production_method_set_icon(t.id, v)
            return
        end
        if (k == "description") then
            DATA.production_method_set_description(t.id, v)
            return
        end
        if (k == "r") then
            DATA.production_method_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.production_method_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.production_method_set_b(t.id, v)
            return
        end
        if (k == "job_type") then
            DATA.production_method_set_job_type(t.id, v)
            return
        end
        if (k == "foraging") then
            DATA.production_method_set_foraging(t.id, v)
            return
        end
        if (k == "hydration") then
            DATA.production_method_set_hydration(t.id, v)
            return
        end
        if (k == "nature_yield_dependence") then
            DATA.production_method_set_nature_yield_dependence(t.id, v)
            return
        end
        if (k == "forest_dependence") then
            DATA.production_method_set_forest_dependence(t.id, v)
            return
        end
        if (k == "crop") then
            DATA.production_method_set_crop(t.id, v)
            return
        end
        if (k == "temperature_ideal_min") then
            DATA.production_method_set_temperature_ideal_min(t.id, v)
            return
        end
        if (k == "temperature_ideal_max") then
            DATA.production_method_set_temperature_ideal_max(t.id, v)
            return
        end
        if (k == "temperature_extreme_min") then
            DATA.production_method_set_temperature_extreme_min(t.id, v)
            return
        end
        if (k == "temperature_extreme_max") then
            DATA.production_method_set_temperature_extreme_max(t.id, v)
            return
        end
        if (k == "rainfall_ideal_min") then
            DATA.production_method_set_rainfall_ideal_min(t.id, v)
            return
        end
        if (k == "rainfall_ideal_max") then
            DATA.production_method_set_rainfall_ideal_max(t.id, v)
            return
        end
        if (k == "rainfall_extreme_min") then
            DATA.production_method_set_rainfall_extreme_min(t.id, v)
            return
        end
        if (k == "rainfall_extreme_max") then
            DATA.production_method_set_rainfall_extreme_max(t.id, v)
            return
        end
        if (k == "clay_ideal_min") then
            DATA.production_method_set_clay_ideal_min(t.id, v)
            return
        end
        if (k == "clay_ideal_max") then
            DATA.production_method_set_clay_ideal_max(t.id, v)
            return
        end
        if (k == "clay_extreme_min") then
            DATA.production_method_set_clay_extreme_min(t.id, v)
            return
        end
        if (k == "clay_extreme_max") then
            DATA.production_method_set_clay_extreme_max(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id production_method_id
---@return fat_production_method_id fat_id
function DATA.fatten_production_method(id)
    local result = {id = id}
    setmetatable(result, fat_production_method_id_metatable)    return result
end
----------technology----------


---technology: LSP types---

---Unique identificator for technology entity
---@class (exact) technology_id : number
---@field is_technology nil

---@class (exact) fat_technology_id
---@field id technology_id Unique technology id
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field research_cost number Amount of research points (education_endowment) per pop needed for the technology
---@field associated_job job_id The job that is needed to perform this research. Without it, the research odds will be significantly lower. We'll be using this to make technology implicitly tied to player decisions

---@class struct_technology
---@field r number
---@field g number
---@field b number
---@field research_cost number Amount of research points (education_endowment) per pop needed for the technology
---@field required_biome table<number, biome_id>
---@field required_resource table<number, resource_id>
---@field associated_job job_id The job that is needed to perform this research. Without it, the research odds will be significantly lower. We'll be using this to make technology implicitly tied to player decisions
---@field throughput_boosts table<production_method_id, number>
---@field input_efficiency_boosts table<production_method_id, number>
---@field output_efficiency_boosts table<production_method_id, number>

---@class (exact) technology_id_data_blob_definition
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field research_cost number Amount of research points (education_endowment) per pop needed for the technology
---@field required_biome biome_id[]
---@field required_race race_id[]
---@field required_resource resource_id[]
---@field associated_job job_id The job that is needed to perform this research. Without it, the research odds will be significantly lower. We'll be using this to make technology implicitly tied to player decisions
---@field throughput_boosts table<production_method_id, number>
---@field input_efficiency_boosts table<production_method_id, number>
---@field output_efficiency_boosts table<production_method_id, number>
---Sets values of technology for given id
---@param id technology_id
---@param data technology_id_data_blob_definition
function DATA.setup_technology(id, data)
    DATA.technology_set_name(id, data.name)
    DATA.technology_set_icon(id, data.icon)
    DATA.technology_set_description(id, data.description)
    DATA.technology_set_r(id, data.r)
    DATA.technology_set_g(id, data.g)
    DATA.technology_set_b(id, data.b)
    DATA.technology_set_research_cost(id, data.research_cost)
    for i, value in pairs(data.required_biome) do
        DATA.technology_set_required_biome(id, i - 1, value)
    end
    for i, value in pairs(data.required_race) do
        DATA.technology_set_required_race(id, i - 1, value)
    end
    for i, value in pairs(data.required_resource) do
        DATA.technology_set_required_resource(id, i - 1, value)
    end
    DATA.technology_set_associated_job(id, data.associated_job)
    for i, value in pairs(data.throughput_boosts) do
        DATA.technology_set_throughput_boosts(id, i, value)
    end
    for i, value in pairs(data.input_efficiency_boosts) do
        DATA.technology_set_input_efficiency_boosts(id, i, value)
    end
    for i, value in pairs(data.output_efficiency_boosts) do
        DATA.technology_set_output_efficiency_boosts(id, i, value)
    end
end

ffi.cdef[[
void dcon_technology_set_r(int32_t, float);
float dcon_technology_get_r(int32_t);
void dcon_technology_set_g(int32_t, float);
float dcon_technology_get_g(int32_t);
void dcon_technology_set_b(int32_t, float);
float dcon_technology_get_b(int32_t);
void dcon_technology_set_research_cost(int32_t, float);
float dcon_technology_get_research_cost(int32_t);
void dcon_technology_resize_required_biome(uint32_t);
void dcon_technology_set_required_biome(int32_t, int32_t, uint32_t);
uint32_t dcon_technology_get_required_biome(int32_t, int32_t);
void dcon_technology_resize_required_resource(uint32_t);
void dcon_technology_set_required_resource(int32_t, int32_t, uint32_t);
uint32_t dcon_technology_get_required_resource(int32_t, int32_t);
void dcon_technology_set_associated_job(int32_t, uint32_t);
uint32_t dcon_technology_get_associated_job(int32_t);
void dcon_technology_resize_throughput_boosts(uint32_t);
void dcon_technology_set_throughput_boosts(int32_t, int32_t, float);
float dcon_technology_get_throughput_boosts(int32_t, int32_t);
void dcon_technology_resize_input_efficiency_boosts(uint32_t);
void dcon_technology_set_input_efficiency_boosts(int32_t, int32_t, float);
float dcon_technology_get_input_efficiency_boosts(int32_t, int32_t);
void dcon_technology_resize_output_efficiency_boosts(uint32_t);
void dcon_technology_set_output_efficiency_boosts(int32_t, int32_t, float);
float dcon_technology_get_output_efficiency_boosts(int32_t, int32_t);
int32_t dcon_create_technology();
bool dcon_technology_is_valid(int32_t);
void dcon_technology_resize(uint32_t sz);
uint32_t dcon_technology_size();
]]

---technology: FFI arrays---
---@type (string)[]
DATA.technology_name= {}
---@type (string)[]
DATA.technology_icon= {}
---@type (string)[]
DATA.technology_description= {}
---@type (table<number, race_id>)[]
DATA.technology_required_race= {}

---technology: LUA bindings---

DATA.technology_size = 400
DCON.dcon_technology_resize_required_biome(21)
DCON.dcon_technology_resize_required_resource(21)
DCON.dcon_technology_resize_throughput_boosts(251)
DCON.dcon_technology_resize_input_efficiency_boosts(251)
DCON.dcon_technology_resize_output_efficiency_boosts(251)
---@return technology_id
function DATA.create_technology()
    ---@type technology_id
    local i  = DCON.dcon_create_technology() + 1
    return i --[[@as technology_id]]
end
---@param func fun(item: technology_id)
function DATA.for_each_technology(func)
    ---@type number
    local range = DCON.dcon_technology_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as technology_id]])
    end
end
---@param func fun(item: technology_id):boolean
---@return table<technology_id, technology_id>
function DATA.filter_technology(func)
    ---@type table<technology_id, technology_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_technology_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as technology_id]]) then t[i + 1 --[[@as technology_id]]] = t[i + 1 --[[@as technology_id]]] end
    end
    return t
end

---@param technology_id technology_id valid technology id
---@return string name
function DATA.technology_get_name(technology_id)
    return DATA.technology_name[technology_id]
end
---@param technology_id technology_id valid technology id
---@param value string valid string
function DATA.technology_set_name(technology_id, value)
    DATA.technology_name[technology_id] = value
end
---@param technology_id technology_id valid technology id
---@return string icon
function DATA.technology_get_icon(technology_id)
    return DATA.technology_icon[technology_id]
end
---@param technology_id technology_id valid technology id
---@param value string valid string
function DATA.technology_set_icon(technology_id, value)
    DATA.technology_icon[technology_id] = value
end
---@param technology_id technology_id valid technology id
---@return string description
function DATA.technology_get_description(technology_id)
    return DATA.technology_description[technology_id]
end
---@param technology_id technology_id valid technology id
---@param value string valid string
function DATA.technology_set_description(technology_id, value)
    DATA.technology_description[technology_id] = value
end
---@param technology_id technology_id valid technology id
---@return number r
function DATA.technology_get_r(technology_id)
    return DCON.dcon_technology_get_r(technology_id - 1)
end
---@param technology_id technology_id valid technology id
---@param value number valid number
function DATA.technology_set_r(technology_id, value)
    DCON.dcon_technology_set_r(technology_id - 1, value)
end
---@param technology_id technology_id valid technology id
---@param value number valid number
function DATA.technology_inc_r(technology_id, value)
    ---@type number
    local current = DCON.dcon_technology_get_r(technology_id - 1)
    DCON.dcon_technology_set_r(technology_id - 1, current + value)
end
---@param technology_id technology_id valid technology id
---@return number g
function DATA.technology_get_g(technology_id)
    return DCON.dcon_technology_get_g(technology_id - 1)
end
---@param technology_id technology_id valid technology id
---@param value number valid number
function DATA.technology_set_g(technology_id, value)
    DCON.dcon_technology_set_g(technology_id - 1, value)
end
---@param technology_id technology_id valid technology id
---@param value number valid number
function DATA.technology_inc_g(technology_id, value)
    ---@type number
    local current = DCON.dcon_technology_get_g(technology_id - 1)
    DCON.dcon_technology_set_g(technology_id - 1, current + value)
end
---@param technology_id technology_id valid technology id
---@return number b
function DATA.technology_get_b(technology_id)
    return DCON.dcon_technology_get_b(technology_id - 1)
end
---@param technology_id technology_id valid technology id
---@param value number valid number
function DATA.technology_set_b(technology_id, value)
    DCON.dcon_technology_set_b(technology_id - 1, value)
end
---@param technology_id technology_id valid technology id
---@param value number valid number
function DATA.technology_inc_b(technology_id, value)
    ---@type number
    local current = DCON.dcon_technology_get_b(technology_id - 1)
    DCON.dcon_technology_set_b(technology_id - 1, current + value)
end
---@param technology_id technology_id valid technology id
---@return number research_cost Amount of research points (education_endowment) per pop needed for the technology
function DATA.technology_get_research_cost(technology_id)
    return DCON.dcon_technology_get_research_cost(technology_id - 1)
end
---@param technology_id technology_id valid technology id
---@param value number valid number
function DATA.technology_set_research_cost(technology_id, value)
    DCON.dcon_technology_set_research_cost(technology_id - 1, value)
end
---@param technology_id technology_id valid technology id
---@param value number valid number
function DATA.technology_inc_research_cost(technology_id, value)
    ---@type number
    local current = DCON.dcon_technology_get_research_cost(technology_id - 1)
    DCON.dcon_technology_set_research_cost(technology_id - 1, current + value)
end
---@param technology_id technology_id valid technology id
---@param index number valid
---@return biome_id required_biome
function DATA.technology_get_required_biome(technology_id, index)
    assert(index ~= 0)
    return DCON.dcon_technology_get_required_biome(technology_id - 1, index - 1) + 1
end
---@param technology_id technology_id valid technology id
---@param index number valid index
---@param value biome_id valid biome_id
function DATA.technology_set_required_biome(technology_id, index, value)
    DCON.dcon_technology_set_required_biome(technology_id - 1, index - 1, value)
end
---@param technology_id technology_id valid technology id
---@param index number valid
---@return race_id required_race
function DATA.technology_get_required_race(technology_id, index)
    if DATA.technology_required_race[technology_id] == nil then return 0 end
    return DATA.technology_required_race[technology_id][index]
end
---@param technology_id technology_id valid technology id
---@param index number valid index
---@param value race_id valid race_id
function DATA.technology_set_required_race(technology_id, index, value)
    DATA.technology_required_race[technology_id][index] = value
end
---@param technology_id technology_id valid technology id
---@param index number valid
---@return resource_id required_resource
function DATA.technology_get_required_resource(technology_id, index)
    assert(index ~= 0)
    return DCON.dcon_technology_get_required_resource(technology_id - 1, index - 1) + 1
end
---@param technology_id technology_id valid technology id
---@param index number valid index
---@param value resource_id valid resource_id
function DATA.technology_set_required_resource(technology_id, index, value)
    DCON.dcon_technology_set_required_resource(technology_id - 1, index - 1, value)
end
---@param technology_id technology_id valid technology id
---@return job_id associated_job The job that is needed to perform this research. Without it, the research odds will be significantly lower. We'll be using this to make technology implicitly tied to player decisions
function DATA.technology_get_associated_job(technology_id)
    return DCON.dcon_technology_get_associated_job(technology_id - 1) + 1
end
---@param technology_id technology_id valid technology id
---@param value job_id valid job_id
function DATA.technology_set_associated_job(technology_id, value)
    DCON.dcon_technology_set_associated_job(technology_id - 1, value - 1)
end
---@param technology_id technology_id valid technology id
---@param index production_method_id valid
---@return number throughput_boosts
function DATA.technology_get_throughput_boosts(technology_id, index)
    assert(index ~= 0)
    return DCON.dcon_technology_get_throughput_boosts(technology_id - 1, index - 1)
end
---@param technology_id technology_id valid technology id
---@param index production_method_id valid index
---@param value number valid number
function DATA.technology_set_throughput_boosts(technology_id, index, value)
    DCON.dcon_technology_set_throughput_boosts(technology_id - 1, index - 1, value)
end
---@param technology_id technology_id valid technology id
---@param index production_method_id valid index
---@param value number valid number
function DATA.technology_inc_throughput_boosts(technology_id, index, value)
    ---@type number
    local current = DCON.dcon_technology_get_throughput_boosts(technology_id - 1, index - 1)
    DCON.dcon_technology_set_throughput_boosts(technology_id - 1, index - 1, current + value)
end
---@param technology_id technology_id valid technology id
---@param index production_method_id valid
---@return number input_efficiency_boosts
function DATA.technology_get_input_efficiency_boosts(technology_id, index)
    assert(index ~= 0)
    return DCON.dcon_technology_get_input_efficiency_boosts(technology_id - 1, index - 1)
end
---@param technology_id technology_id valid technology id
---@param index production_method_id valid index
---@param value number valid number
function DATA.technology_set_input_efficiency_boosts(technology_id, index, value)
    DCON.dcon_technology_set_input_efficiency_boosts(technology_id - 1, index - 1, value)
end
---@param technology_id technology_id valid technology id
---@param index production_method_id valid index
---@param value number valid number
function DATA.technology_inc_input_efficiency_boosts(technology_id, index, value)
    ---@type number
    local current = DCON.dcon_technology_get_input_efficiency_boosts(technology_id - 1, index - 1)
    DCON.dcon_technology_set_input_efficiency_boosts(technology_id - 1, index - 1, current + value)
end
---@param technology_id technology_id valid technology id
---@param index production_method_id valid
---@return number output_efficiency_boosts
function DATA.technology_get_output_efficiency_boosts(technology_id, index)
    assert(index ~= 0)
    return DCON.dcon_technology_get_output_efficiency_boosts(technology_id - 1, index - 1)
end
---@param technology_id technology_id valid technology id
---@param index production_method_id valid index
---@param value number valid number
function DATA.technology_set_output_efficiency_boosts(technology_id, index, value)
    DCON.dcon_technology_set_output_efficiency_boosts(technology_id - 1, index - 1, value)
end
---@param technology_id technology_id valid technology id
---@param index production_method_id valid index
---@param value number valid number
function DATA.technology_inc_output_efficiency_boosts(technology_id, index, value)
    ---@type number
    local current = DCON.dcon_technology_get_output_efficiency_boosts(technology_id - 1, index - 1)
    DCON.dcon_technology_set_output_efficiency_boosts(technology_id - 1, index - 1, current + value)
end

local fat_technology_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.technology_get_name(t.id) end
        if (k == "icon") then return DATA.technology_get_icon(t.id) end
        if (k == "description") then return DATA.technology_get_description(t.id) end
        if (k == "r") then return DATA.technology_get_r(t.id) end
        if (k == "g") then return DATA.technology_get_g(t.id) end
        if (k == "b") then return DATA.technology_get_b(t.id) end
        if (k == "research_cost") then return DATA.technology_get_research_cost(t.id) end
        if (k == "associated_job") then return DATA.technology_get_associated_job(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.technology_set_name(t.id, v)
            return
        end
        if (k == "icon") then
            DATA.technology_set_icon(t.id, v)
            return
        end
        if (k == "description") then
            DATA.technology_set_description(t.id, v)
            return
        end
        if (k == "r") then
            DATA.technology_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.technology_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.technology_set_b(t.id, v)
            return
        end
        if (k == "research_cost") then
            DATA.technology_set_research_cost(t.id, v)
            return
        end
        if (k == "associated_job") then
            DATA.technology_set_associated_job(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id technology_id
---@return fat_technology_id fat_id
function DATA.fatten_technology(id)
    local result = {id = id}
    setmetatable(result, fat_technology_id_metatable)    return result
end
----------technology_unlock----------


---technology_unlock: LSP types---

---Unique identificator for technology_unlock entity
---@class (exact) technology_unlock_id : number
---@field is_technology_unlock nil

---@class (exact) fat_technology_unlock_id
---@field id technology_unlock_id Unique technology_unlock id
---@field origin technology_id
---@field unlocked technology_id

---@class struct_technology_unlock

---@class (exact) technology_unlock_id_data_blob_definition
---Sets values of technology_unlock for given id
---@param id technology_unlock_id
---@param data technology_unlock_id_data_blob_definition
function DATA.setup_technology_unlock(id, data)
end

ffi.cdef[[
int32_t dcon_force_create_technology_unlock(int32_t origin, int32_t unlocked);
void dcon_technology_unlock_set_origin(int32_t, int32_t);
int32_t dcon_technology_unlock_get_origin(int32_t);
int32_t dcon_technology_get_range_technology_unlock_as_origin(int32_t);
int32_t dcon_technology_get_index_technology_unlock_as_origin(int32_t, int32_t);
void dcon_technology_unlock_set_unlocked(int32_t, int32_t);
int32_t dcon_technology_unlock_get_unlocked(int32_t);
int32_t dcon_technology_get_range_technology_unlock_as_unlocked(int32_t);
int32_t dcon_technology_get_index_technology_unlock_as_unlocked(int32_t, int32_t);
bool dcon_technology_unlock_is_valid(int32_t);
void dcon_technology_unlock_resize(uint32_t sz);
uint32_t dcon_technology_unlock_size();
]]

---technology_unlock: FFI arrays---

---technology_unlock: LUA bindings---

DATA.technology_unlock_size = 800
---@param origin technology_id
---@param unlocked technology_id
---@return technology_unlock_id
function DATA.force_create_technology_unlock(origin, unlocked)
    ---@type technology_unlock_id
    local i = DCON.dcon_force_create_technology_unlock(origin - 1, unlocked - 1) + 1
    return i --[[@as technology_unlock_id]]
end
---@param func fun(item: technology_unlock_id)
function DATA.for_each_technology_unlock(func)
    ---@type number
    local range = DCON.dcon_technology_unlock_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as technology_unlock_id]])
    end
end
---@param func fun(item: technology_unlock_id):boolean
---@return table<technology_unlock_id, technology_unlock_id>
function DATA.filter_technology_unlock(func)
    ---@type table<technology_unlock_id, technology_unlock_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_technology_unlock_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as technology_unlock_id]]) then t[i + 1 --[[@as technology_unlock_id]]] = t[i + 1 --[[@as technology_unlock_id]]] end
    end
    return t
end

---@param origin technology_unlock_id valid technology_id
---@return technology_id Data retrieved from technology_unlock
function DATA.technology_unlock_get_origin(origin)
    return DCON.dcon_technology_unlock_get_origin(origin - 1) + 1
end
---@param origin technology_id valid technology_id
---@return technology_unlock_id[] An array of technology_unlock
function DATA.get_technology_unlock_from_origin(origin)
    local result = {}
    DATA.for_each_technology_unlock_from_origin(origin, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param origin technology_id valid technology_id
---@param func fun(item: technology_unlock_id) valid technology_id
function DATA.for_each_technology_unlock_from_origin(origin, func)
    ---@type number
    local range = DCON.dcon_technology_get_range_technology_unlock_as_origin(origin - 1)
    for i = 0, range - 1 do
        ---@type technology_unlock_id
        local accessed_element = DCON.dcon_technology_get_index_technology_unlock_as_origin(origin - 1, i) + 1
        if DCON.dcon_technology_unlock_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param origin technology_id valid technology_id
---@param func fun(item: technology_unlock_id):boolean
---@return technology_unlock_id[]
function DATA.filter_array_technology_unlock_from_origin(origin, func)
    ---@type table<technology_unlock_id, technology_unlock_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_technology_get_range_technology_unlock_as_origin(origin - 1)
    for i = 0, range - 1 do
        ---@type technology_unlock_id
        local accessed_element = DCON.dcon_technology_get_index_technology_unlock_as_origin(origin - 1, i) + 1
        if DCON.dcon_technology_unlock_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param origin technology_id valid technology_id
---@param func fun(item: technology_unlock_id):boolean
---@return table<technology_unlock_id, technology_unlock_id>
function DATA.filter_technology_unlock_from_origin(origin, func)
    ---@type table<technology_unlock_id, technology_unlock_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_technology_get_range_technology_unlock_as_origin(origin - 1)
    for i = 0, range - 1 do
        ---@type technology_unlock_id
        local accessed_element = DCON.dcon_technology_get_index_technology_unlock_as_origin(origin - 1, i) + 1
        if DCON.dcon_technology_unlock_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param technology_unlock_id technology_unlock_id valid technology_unlock id
---@param value technology_id valid technology_id
function DATA.technology_unlock_set_origin(technology_unlock_id, value)
    DCON.dcon_technology_unlock_set_origin(technology_unlock_id - 1, value - 1)
end
---@param unlocked technology_unlock_id valid technology_id
---@return technology_id Data retrieved from technology_unlock
function DATA.technology_unlock_get_unlocked(unlocked)
    return DCON.dcon_technology_unlock_get_unlocked(unlocked - 1) + 1
end
---@param unlocked technology_id valid technology_id
---@return technology_unlock_id[] An array of technology_unlock
function DATA.get_technology_unlock_from_unlocked(unlocked)
    local result = {}
    DATA.for_each_technology_unlock_from_unlocked(unlocked, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param unlocked technology_id valid technology_id
---@param func fun(item: technology_unlock_id) valid technology_id
function DATA.for_each_technology_unlock_from_unlocked(unlocked, func)
    ---@type number
    local range = DCON.dcon_technology_get_range_technology_unlock_as_unlocked(unlocked - 1)
    for i = 0, range - 1 do
        ---@type technology_unlock_id
        local accessed_element = DCON.dcon_technology_get_index_technology_unlock_as_unlocked(unlocked - 1, i) + 1
        if DCON.dcon_technology_unlock_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param unlocked technology_id valid technology_id
---@param func fun(item: technology_unlock_id):boolean
---@return technology_unlock_id[]
function DATA.filter_array_technology_unlock_from_unlocked(unlocked, func)
    ---@type table<technology_unlock_id, technology_unlock_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_technology_get_range_technology_unlock_as_unlocked(unlocked - 1)
    for i = 0, range - 1 do
        ---@type technology_unlock_id
        local accessed_element = DCON.dcon_technology_get_index_technology_unlock_as_unlocked(unlocked - 1, i) + 1
        if DCON.dcon_technology_unlock_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param unlocked technology_id valid technology_id
---@param func fun(item: technology_unlock_id):boolean
---@return table<technology_unlock_id, technology_unlock_id>
function DATA.filter_technology_unlock_from_unlocked(unlocked, func)
    ---@type table<technology_unlock_id, technology_unlock_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_technology_get_range_technology_unlock_as_unlocked(unlocked - 1)
    for i = 0, range - 1 do
        ---@type technology_unlock_id
        local accessed_element = DCON.dcon_technology_get_index_technology_unlock_as_unlocked(unlocked - 1, i) + 1
        if DCON.dcon_technology_unlock_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param technology_unlock_id technology_unlock_id valid technology_unlock id
---@param value technology_id valid technology_id
function DATA.technology_unlock_set_unlocked(technology_unlock_id, value)
    DCON.dcon_technology_unlock_set_unlocked(technology_unlock_id - 1, value - 1)
end

local fat_technology_unlock_id_metatable = {
    __index = function (t,k)
        if (k == "origin") then return DATA.technology_unlock_get_origin(t.id) end
        if (k == "unlocked") then return DATA.technology_unlock_get_unlocked(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "origin") then
            DATA.technology_unlock_set_origin(t.id, v)
            return
        end
        if (k == "unlocked") then
            DATA.technology_unlock_set_unlocked(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id technology_unlock_id
---@return fat_technology_unlock_id fat_id
function DATA.fatten_technology_unlock(id)
    local result = {id = id}
    setmetatable(result, fat_technology_unlock_id_metatable)    return result
end
----------building_type----------


---building_type: LSP types---

---Unique identificator for building_type entity
---@class (exact) building_type_id : number
---@field is_building_type nil

---@class (exact) fat_building_type_id
---@field id building_type_id Unique building_type id
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field production_method production_method_id
---@field construction_cost number
---@field upkeep number
---@field unique boolean only one per province!
---@field movable boolean is it possible to migrate with this building?
---@field government boolean only the government can build this building!
---@field needed_infrastructure number
---@field spotting number The amount of "spotting" a building provides. Spotting is used in warfare. Higher spotting makes it more difficult for foreign armies to sneak in.

---@class struct_building_type
---@field r number
---@field g number
---@field b number
---@field production_method production_method_id
---@field construction_cost number
---@field upkeep number
---@field required_biome table<number, biome_id>
---@field required_resource table<number, resource_id>
---@field unique boolean only one per province!
---@field movable boolean is it possible to migrate with this building?
---@field government boolean only the government can build this building!
---@field needed_infrastructure number
---@field spotting number The amount of "spotting" a building provides. Spotting is used in warfare. Higher spotting makes it more difficult for foreign armies to sneak in.

---@class (exact) building_type_id_data_blob_definition
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field production_method production_method_id
---@field archetype BUILDING_ARCHETYPE
---@field unlocked_by technology_id
---@field construction_cost number
---@field upkeep number?
---@field required_biome biome_id[]
---@field required_resource resource_id[]
---@field unique boolean? only one per province!
---@field movable boolean? is it possible to migrate with this building?
---@field government boolean? only the government can build this building!
---@field needed_infrastructure number?
---@field spotting number? The amount of "spotting" a building provides. Spotting is used in warfare. Higher spotting makes it more difficult for foreign armies to sneak in.
---Sets values of building_type for given id
---@param id building_type_id
---@param data building_type_id_data_blob_definition
function DATA.setup_building_type(id, data)
    DATA.building_type_set_upkeep(id, 0)
    DATA.building_type_set_unique(id, false)
    DATA.building_type_set_movable(id, false)
    DATA.building_type_set_government(id, false)
    DATA.building_type_set_needed_infrastructure(id, 0)
    DATA.building_type_set_spotting(id, 0)
    DATA.building_type_set_name(id, data.name)
    DATA.building_type_set_icon(id, data.icon)
    DATA.building_type_set_description(id, data.description)
    DATA.building_type_set_r(id, data.r)
    DATA.building_type_set_g(id, data.g)
    DATA.building_type_set_b(id, data.b)
    DATA.building_type_set_production_method(id, data.production_method)
    DATA.building_type_set_construction_cost(id, data.construction_cost)
    if data.upkeep ~= nil then
        DATA.building_type_set_upkeep(id, data.upkeep)
    end
    for i, value in pairs(data.required_biome) do
        DATA.building_type_set_required_biome(id, i - 1, value)
    end
    for i, value in pairs(data.required_resource) do
        DATA.building_type_set_required_resource(id, i - 1, value)
    end
    if data.unique ~= nil then
        DATA.building_type_set_unique(id, data.unique)
    end
    if data.movable ~= nil then
        DATA.building_type_set_movable(id, data.movable)
    end
    if data.government ~= nil then
        DATA.building_type_set_government(id, data.government)
    end
    if data.needed_infrastructure ~= nil then
        DATA.building_type_set_needed_infrastructure(id, data.needed_infrastructure)
    end
    if data.spotting ~= nil then
        DATA.building_type_set_spotting(id, data.spotting)
    end
end

ffi.cdef[[
void dcon_building_type_set_r(int32_t, float);
float dcon_building_type_get_r(int32_t);
void dcon_building_type_set_g(int32_t, float);
float dcon_building_type_get_g(int32_t);
void dcon_building_type_set_b(int32_t, float);
float dcon_building_type_get_b(int32_t);
void dcon_building_type_set_production_method(int32_t, uint32_t);
uint32_t dcon_building_type_get_production_method(int32_t);
void dcon_building_type_set_archetype(int32_t, uint8_t);
uint8_t dcon_building_type_get_archetype(int32_t);
void dcon_building_type_set_unlocked_by(int32_t, uint32_t);
uint32_t dcon_building_type_get_unlocked_by(int32_t);
void dcon_building_type_set_construction_cost(int32_t, float);
float dcon_building_type_get_construction_cost(int32_t);
void dcon_building_type_set_upkeep(int32_t, float);
float dcon_building_type_get_upkeep(int32_t);
void dcon_building_type_resize_required_biome(uint32_t);
void dcon_building_type_set_required_biome(int32_t, int32_t, uint32_t);
uint32_t dcon_building_type_get_required_biome(int32_t, int32_t);
void dcon_building_type_resize_required_resource(uint32_t);
void dcon_building_type_set_required_resource(int32_t, int32_t, uint32_t);
uint32_t dcon_building_type_get_required_resource(int32_t, int32_t);
void dcon_building_type_set_unique(int32_t, bool);
bool dcon_building_type_get_unique(int32_t);
void dcon_building_type_set_movable(int32_t, bool);
bool dcon_building_type_get_movable(int32_t);
void dcon_building_type_set_government(int32_t, bool);
bool dcon_building_type_get_government(int32_t);
void dcon_building_type_set_needed_infrastructure(int32_t, float);
float dcon_building_type_get_needed_infrastructure(int32_t);
void dcon_building_type_set_spotting(int32_t, float);
float dcon_building_type_get_spotting(int32_t);
int32_t dcon_create_building_type();
bool dcon_building_type_is_valid(int32_t);
void dcon_building_type_resize(uint32_t sz);
uint32_t dcon_building_type_size();
]]

---building_type: FFI arrays---
---@type (string)[]
DATA.building_type_name= {}
---@type (string)[]
DATA.building_type_icon= {}
---@type (string)[]
DATA.building_type_description= {}

---building_type: LUA bindings---

DATA.building_type_size = 250
DCON.dcon_building_type_resize_required_biome(21)
DCON.dcon_building_type_resize_required_resource(21)
---@return building_type_id
function DATA.create_building_type()
    ---@type building_type_id
    local i  = DCON.dcon_create_building_type() + 1
    return i --[[@as building_type_id]]
end
---@param func fun(item: building_type_id)
function DATA.for_each_building_type(func)
    ---@type number
    local range = DCON.dcon_building_type_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as building_type_id]])
    end
end
---@param func fun(item: building_type_id):boolean
---@return table<building_type_id, building_type_id>
function DATA.filter_building_type(func)
    ---@type table<building_type_id, building_type_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_building_type_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as building_type_id]]) then t[i + 1 --[[@as building_type_id]]] = t[i + 1 --[[@as building_type_id]]] end
    end
    return t
end

---@param building_type_id building_type_id valid building_type id
---@return string name
function DATA.building_type_get_name(building_type_id)
    return DATA.building_type_name[building_type_id]
end
---@param building_type_id building_type_id valid building_type id
---@param value string valid string
function DATA.building_type_set_name(building_type_id, value)
    DATA.building_type_name[building_type_id] = value
end
---@param building_type_id building_type_id valid building_type id
---@return string icon
function DATA.building_type_get_icon(building_type_id)
    return DATA.building_type_icon[building_type_id]
end
---@param building_type_id building_type_id valid building_type id
---@param value string valid string
function DATA.building_type_set_icon(building_type_id, value)
    DATA.building_type_icon[building_type_id] = value
end
---@param building_type_id building_type_id valid building_type id
---@return string description
function DATA.building_type_get_description(building_type_id)
    return DATA.building_type_description[building_type_id]
end
---@param building_type_id building_type_id valid building_type id
---@param value string valid string
function DATA.building_type_set_description(building_type_id, value)
    DATA.building_type_description[building_type_id] = value
end
---@param building_type_id building_type_id valid building_type id
---@return number r
function DATA.building_type_get_r(building_type_id)
    return DCON.dcon_building_type_get_r(building_type_id - 1)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_set_r(building_type_id, value)
    DCON.dcon_building_type_set_r(building_type_id - 1, value)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_inc_r(building_type_id, value)
    ---@type number
    local current = DCON.dcon_building_type_get_r(building_type_id - 1)
    DCON.dcon_building_type_set_r(building_type_id - 1, current + value)
end
---@param building_type_id building_type_id valid building_type id
---@return number g
function DATA.building_type_get_g(building_type_id)
    return DCON.dcon_building_type_get_g(building_type_id - 1)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_set_g(building_type_id, value)
    DCON.dcon_building_type_set_g(building_type_id - 1, value)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_inc_g(building_type_id, value)
    ---@type number
    local current = DCON.dcon_building_type_get_g(building_type_id - 1)
    DCON.dcon_building_type_set_g(building_type_id - 1, current + value)
end
---@param building_type_id building_type_id valid building_type id
---@return number b
function DATA.building_type_get_b(building_type_id)
    return DCON.dcon_building_type_get_b(building_type_id - 1)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_set_b(building_type_id, value)
    DCON.dcon_building_type_set_b(building_type_id - 1, value)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_inc_b(building_type_id, value)
    ---@type number
    local current = DCON.dcon_building_type_get_b(building_type_id - 1)
    DCON.dcon_building_type_set_b(building_type_id - 1, current + value)
end
---@param building_type_id building_type_id valid building_type id
---@return production_method_id production_method
function DATA.building_type_get_production_method(building_type_id)
    return DCON.dcon_building_type_get_production_method(building_type_id - 1) + 1
end
---@param building_type_id building_type_id valid building_type id
---@param value production_method_id valid production_method_id
function DATA.building_type_set_production_method(building_type_id, value)
    DCON.dcon_building_type_set_production_method(building_type_id - 1, value - 1)
end
---@param building_type_id building_type_id valid building_type id
---@return number construction_cost
function DATA.building_type_get_construction_cost(building_type_id)
    return DCON.dcon_building_type_get_construction_cost(building_type_id - 1)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_set_construction_cost(building_type_id, value)
    DCON.dcon_building_type_set_construction_cost(building_type_id - 1, value)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_inc_construction_cost(building_type_id, value)
    ---@type number
    local current = DCON.dcon_building_type_get_construction_cost(building_type_id - 1)
    DCON.dcon_building_type_set_construction_cost(building_type_id - 1, current + value)
end
---@param building_type_id building_type_id valid building_type id
---@return number upkeep
function DATA.building_type_get_upkeep(building_type_id)
    return DCON.dcon_building_type_get_upkeep(building_type_id - 1)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_set_upkeep(building_type_id, value)
    DCON.dcon_building_type_set_upkeep(building_type_id - 1, value)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_inc_upkeep(building_type_id, value)
    ---@type number
    local current = DCON.dcon_building_type_get_upkeep(building_type_id - 1)
    DCON.dcon_building_type_set_upkeep(building_type_id - 1, current + value)
end
---@param building_type_id building_type_id valid building_type id
---@param index number valid
---@return biome_id required_biome
function DATA.building_type_get_required_biome(building_type_id, index)
    assert(index ~= 0)
    return DCON.dcon_building_type_get_required_biome(building_type_id - 1, index - 1) + 1
end
---@param building_type_id building_type_id valid building_type id
---@param index number valid index
---@param value biome_id valid biome_id
function DATA.building_type_set_required_biome(building_type_id, index, value)
    DCON.dcon_building_type_set_required_biome(building_type_id - 1, index - 1, value)
end
---@param building_type_id building_type_id valid building_type id
---@param index number valid
---@return resource_id required_resource
function DATA.building_type_get_required_resource(building_type_id, index)
    assert(index ~= 0)
    return DCON.dcon_building_type_get_required_resource(building_type_id - 1, index - 1) + 1
end
---@param building_type_id building_type_id valid building_type id
---@param index number valid index
---@param value resource_id valid resource_id
function DATA.building_type_set_required_resource(building_type_id, index, value)
    DCON.dcon_building_type_set_required_resource(building_type_id - 1, index - 1, value)
end
---@param building_type_id building_type_id valid building_type id
---@return boolean unique only one per province!
function DATA.building_type_get_unique(building_type_id)
    return DCON.dcon_building_type_get_unique(building_type_id - 1)
end
---@param building_type_id building_type_id valid building_type id
---@param value boolean valid boolean
function DATA.building_type_set_unique(building_type_id, value)
    DCON.dcon_building_type_set_unique(building_type_id - 1, value)
end
---@param building_type_id building_type_id valid building_type id
---@return boolean movable is it possible to migrate with this building?
function DATA.building_type_get_movable(building_type_id)
    return DCON.dcon_building_type_get_movable(building_type_id - 1)
end
---@param building_type_id building_type_id valid building_type id
---@param value boolean valid boolean
function DATA.building_type_set_movable(building_type_id, value)
    DCON.dcon_building_type_set_movable(building_type_id - 1, value)
end
---@param building_type_id building_type_id valid building_type id
---@return boolean government only the government can build this building!
function DATA.building_type_get_government(building_type_id)
    return DCON.dcon_building_type_get_government(building_type_id - 1)
end
---@param building_type_id building_type_id valid building_type id
---@param value boolean valid boolean
function DATA.building_type_set_government(building_type_id, value)
    DCON.dcon_building_type_set_government(building_type_id - 1, value)
end
---@param building_type_id building_type_id valid building_type id
---@return number needed_infrastructure
function DATA.building_type_get_needed_infrastructure(building_type_id)
    return DCON.dcon_building_type_get_needed_infrastructure(building_type_id - 1)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_set_needed_infrastructure(building_type_id, value)
    DCON.dcon_building_type_set_needed_infrastructure(building_type_id - 1, value)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_inc_needed_infrastructure(building_type_id, value)
    ---@type number
    local current = DCON.dcon_building_type_get_needed_infrastructure(building_type_id - 1)
    DCON.dcon_building_type_set_needed_infrastructure(building_type_id - 1, current + value)
end
---@param building_type_id building_type_id valid building_type id
---@return number spotting The amount of "spotting" a building provides. Spotting is used in warfare. Higher spotting makes it more difficult for foreign armies to sneak in.
function DATA.building_type_get_spotting(building_type_id)
    return DCON.dcon_building_type_get_spotting(building_type_id - 1)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_set_spotting(building_type_id, value)
    DCON.dcon_building_type_set_spotting(building_type_id - 1, value)
end
---@param building_type_id building_type_id valid building_type id
---@param value number valid number
function DATA.building_type_inc_spotting(building_type_id, value)
    ---@type number
    local current = DCON.dcon_building_type_get_spotting(building_type_id - 1)
    DCON.dcon_building_type_set_spotting(building_type_id - 1, current + value)
end

local fat_building_type_id_metatable = {
    __index = function (t,k)
        if (k == "name") then return DATA.building_type_get_name(t.id) end
        if (k == "icon") then return DATA.building_type_get_icon(t.id) end
        if (k == "description") then return DATA.building_type_get_description(t.id) end
        if (k == "r") then return DATA.building_type_get_r(t.id) end
        if (k == "g") then return DATA.building_type_get_g(t.id) end
        if (k == "b") then return DATA.building_type_get_b(t.id) end
        if (k == "production_method") then return DATA.building_type_get_production_method(t.id) end
        if (k == "construction_cost") then return DATA.building_type_get_construction_cost(t.id) end
        if (k == "upkeep") then return DATA.building_type_get_upkeep(t.id) end
        if (k == "unique") then return DATA.building_type_get_unique(t.id) end
        if (k == "movable") then return DATA.building_type_get_movable(t.id) end
        if (k == "government") then return DATA.building_type_get_government(t.id) end
        if (k == "needed_infrastructure") then return DATA.building_type_get_needed_infrastructure(t.id) end
        if (k == "spotting") then return DATA.building_type_get_spotting(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "name") then
            DATA.building_type_set_name(t.id, v)
            return
        end
        if (k == "icon") then
            DATA.building_type_set_icon(t.id, v)
            return
        end
        if (k == "description") then
            DATA.building_type_set_description(t.id, v)
            return
        end
        if (k == "r") then
            DATA.building_type_set_r(t.id, v)
            return
        end
        if (k == "g") then
            DATA.building_type_set_g(t.id, v)
            return
        end
        if (k == "b") then
            DATA.building_type_set_b(t.id, v)
            return
        end
        if (k == "production_method") then
            DATA.building_type_set_production_method(t.id, v)
            return
        end
        if (k == "construction_cost") then
            DATA.building_type_set_construction_cost(t.id, v)
            return
        end
        if (k == "upkeep") then
            DATA.building_type_set_upkeep(t.id, v)
            return
        end
        if (k == "unique") then
            DATA.building_type_set_unique(t.id, v)
            return
        end
        if (k == "movable") then
            DATA.building_type_set_movable(t.id, v)
            return
        end
        if (k == "government") then
            DATA.building_type_set_government(t.id, v)
            return
        end
        if (k == "needed_infrastructure") then
            DATA.building_type_set_needed_infrastructure(t.id, v)
            return
        end
        if (k == "spotting") then
            DATA.building_type_set_spotting(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id building_type_id
---@return fat_building_type_id fat_id
function DATA.fatten_building_type(id)
    local result = {id = id}
    setmetatable(result, fat_building_type_id_metatable)    return result
end
----------technology_building----------


---technology_building: LSP types---

---Unique identificator for technology_building entity
---@class (exact) technology_building_id : number
---@field is_technology_building nil

---@class (exact) fat_technology_building_id
---@field id technology_building_id Unique technology_building id
---@field technology technology_id
---@field unlocked building_type_id

---@class struct_technology_building

---@class (exact) technology_building_id_data_blob_definition
---Sets values of technology_building for given id
---@param id technology_building_id
---@param data technology_building_id_data_blob_definition
function DATA.setup_technology_building(id, data)
end

ffi.cdef[[
int32_t dcon_force_create_technology_building(int32_t technology, int32_t unlocked);
void dcon_technology_building_set_technology(int32_t, int32_t);
int32_t dcon_technology_building_get_technology(int32_t);
int32_t dcon_technology_get_range_technology_building_as_technology(int32_t);
int32_t dcon_technology_get_index_technology_building_as_technology(int32_t, int32_t);
void dcon_technology_building_set_unlocked(int32_t, int32_t);
int32_t dcon_technology_building_get_unlocked(int32_t);
int32_t dcon_building_type_get_technology_building_as_unlocked(int32_t);
bool dcon_technology_building_is_valid(int32_t);
void dcon_technology_building_resize(uint32_t sz);
uint32_t dcon_technology_building_size();
]]

---technology_building: FFI arrays---

---technology_building: LUA bindings---

DATA.technology_building_size = 400
---@param technology technology_id
---@param unlocked building_type_id
---@return technology_building_id
function DATA.force_create_technology_building(technology, unlocked)
    ---@type technology_building_id
    local i = DCON.dcon_force_create_technology_building(technology - 1, unlocked - 1) + 1
    return i --[[@as technology_building_id]]
end
---@param func fun(item: technology_building_id)
function DATA.for_each_technology_building(func)
    ---@type number
    local range = DCON.dcon_technology_building_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as technology_building_id]])
    end
end
---@param func fun(item: technology_building_id):boolean
---@return table<technology_building_id, technology_building_id>
function DATA.filter_technology_building(func)
    ---@type table<technology_building_id, technology_building_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_technology_building_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as technology_building_id]]) then t[i + 1 --[[@as technology_building_id]]] = t[i + 1 --[[@as technology_building_id]]] end
    end
    return t
end

---@param technology technology_building_id valid technology_id
---@return technology_id Data retrieved from technology_building
function DATA.technology_building_get_technology(technology)
    return DCON.dcon_technology_building_get_technology(technology - 1) + 1
end
---@param technology technology_id valid technology_id
---@return technology_building_id[] An array of technology_building
function DATA.get_technology_building_from_technology(technology)
    local result = {}
    DATA.for_each_technology_building_from_technology(technology, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param technology technology_id valid technology_id
---@param func fun(item: technology_building_id) valid technology_id
function DATA.for_each_technology_building_from_technology(technology, func)
    ---@type number
    local range = DCON.dcon_technology_get_range_technology_building_as_technology(technology - 1)
    for i = 0, range - 1 do
        ---@type technology_building_id
        local accessed_element = DCON.dcon_technology_get_index_technology_building_as_technology(technology - 1, i) + 1
        if DCON.dcon_technology_building_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param technology technology_id valid technology_id
---@param func fun(item: technology_building_id):boolean
---@return technology_building_id[]
function DATA.filter_array_technology_building_from_technology(technology, func)
    ---@type table<technology_building_id, technology_building_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_technology_get_range_technology_building_as_technology(technology - 1)
    for i = 0, range - 1 do
        ---@type technology_building_id
        local accessed_element = DCON.dcon_technology_get_index_technology_building_as_technology(technology - 1, i) + 1
        if DCON.dcon_technology_building_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param technology technology_id valid technology_id
---@param func fun(item: technology_building_id):boolean
---@return table<technology_building_id, technology_building_id>
function DATA.filter_technology_building_from_technology(technology, func)
    ---@type table<technology_building_id, technology_building_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_technology_get_range_technology_building_as_technology(technology - 1)
    for i = 0, range - 1 do
        ---@type technology_building_id
        local accessed_element = DCON.dcon_technology_get_index_technology_building_as_technology(technology - 1, i) + 1
        if DCON.dcon_technology_building_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param technology_building_id technology_building_id valid technology_building id
---@param value technology_id valid technology_id
function DATA.technology_building_set_technology(technology_building_id, value)
    DCON.dcon_technology_building_set_technology(technology_building_id - 1, value - 1)
end
---@param unlocked technology_building_id valid building_type_id
---@return building_type_id Data retrieved from technology_building
function DATA.technology_building_get_unlocked(unlocked)
    return DCON.dcon_technology_building_get_unlocked(unlocked - 1) + 1
end
---@param unlocked building_type_id valid building_type_id
---@return technology_building_id technology_building
function DATA.get_technology_building_from_unlocked(unlocked)
    return DCON.dcon_building_type_get_technology_building_as_unlocked(unlocked - 1) + 1
end
---@param technology_building_id technology_building_id valid technology_building id
---@param value building_type_id valid building_type_id
function DATA.technology_building_set_unlocked(technology_building_id, value)
    DCON.dcon_technology_building_set_unlocked(technology_building_id - 1, value - 1)
end

local fat_technology_building_id_metatable = {
    __index = function (t,k)
        if (k == "technology") then return DATA.technology_building_get_technology(t.id) end
        if (k == "unlocked") then return DATA.technology_building_get_unlocked(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "technology") then
            DATA.technology_building_set_technology(t.id, v)
            return
        end
        if (k == "unlocked") then
            DATA.technology_building_set_unlocked(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id technology_building_id
---@return fat_technology_building_id fat_id
function DATA.fatten_technology_building(id)
    local result = {id = id}
    setmetatable(result, fat_technology_building_id_metatable)    return result
end
----------technology_unit----------


---technology_unit: LSP types---

---Unique identificator for technology_unit entity
---@class (exact) technology_unit_id : number
---@field is_technology_unit nil

---@class (exact) fat_technology_unit_id
---@field id technology_unit_id Unique technology_unit id
---@field technology technology_id
---@field unlocked unit_type_id

---@class struct_technology_unit

---@class (exact) technology_unit_id_data_blob_definition
---Sets values of technology_unit for given id
---@param id technology_unit_id
---@param data technology_unit_id_data_blob_definition
function DATA.setup_technology_unit(id, data)
end

ffi.cdef[[
int32_t dcon_force_create_technology_unit(int32_t technology, int32_t unlocked);
void dcon_technology_unit_set_technology(int32_t, int32_t);
int32_t dcon_technology_unit_get_technology(int32_t);
int32_t dcon_technology_get_range_technology_unit_as_technology(int32_t);
int32_t dcon_technology_get_index_technology_unit_as_technology(int32_t, int32_t);
void dcon_technology_unit_set_unlocked(int32_t, int32_t);
int32_t dcon_technology_unit_get_unlocked(int32_t);
int32_t dcon_unit_type_get_technology_unit_as_unlocked(int32_t);
bool dcon_technology_unit_is_valid(int32_t);
void dcon_technology_unit_resize(uint32_t sz);
uint32_t dcon_technology_unit_size();
]]

---technology_unit: FFI arrays---

---technology_unit: LUA bindings---

DATA.technology_unit_size = 400
---@param technology technology_id
---@param unlocked unit_type_id
---@return technology_unit_id
function DATA.force_create_technology_unit(technology, unlocked)
    ---@type technology_unit_id
    local i = DCON.dcon_force_create_technology_unit(technology - 1, unlocked - 1) + 1
    return i --[[@as technology_unit_id]]
end
---@param func fun(item: technology_unit_id)
function DATA.for_each_technology_unit(func)
    ---@type number
    local range = DCON.dcon_technology_unit_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as technology_unit_id]])
    end
end
---@param func fun(item: technology_unit_id):boolean
---@return table<technology_unit_id, technology_unit_id>
function DATA.filter_technology_unit(func)
    ---@type table<technology_unit_id, technology_unit_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_technology_unit_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as technology_unit_id]]) then t[i + 1 --[[@as technology_unit_id]]] = t[i + 1 --[[@as technology_unit_id]]] end
    end
    return t
end

---@param technology technology_unit_id valid technology_id
---@return technology_id Data retrieved from technology_unit
function DATA.technology_unit_get_technology(technology)
    return DCON.dcon_technology_unit_get_technology(technology - 1) + 1
end
---@param technology technology_id valid technology_id
---@return technology_unit_id[] An array of technology_unit
function DATA.get_technology_unit_from_technology(technology)
    local result = {}
    DATA.for_each_technology_unit_from_technology(technology, function(item)
        table.insert(result, item)
    end)
    return result
end
---@param technology technology_id valid technology_id
---@param func fun(item: technology_unit_id) valid technology_id
function DATA.for_each_technology_unit_from_technology(technology, func)
    ---@type number
    local range = DCON.dcon_technology_get_range_technology_unit_as_technology(technology - 1)
    for i = 0, range - 1 do
        ---@type technology_unit_id
        local accessed_element = DCON.dcon_technology_get_index_technology_unit_as_technology(technology - 1, i) + 1
        if DCON.dcon_technology_unit_is_valid(accessed_element - 1) then func(accessed_element) end
    end
end
---@param technology technology_id valid technology_id
---@param func fun(item: technology_unit_id):boolean
---@return technology_unit_id[]
function DATA.filter_array_technology_unit_from_technology(technology, func)
    ---@type table<technology_unit_id, technology_unit_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_technology_get_range_technology_unit_as_technology(technology - 1)
    for i = 0, range - 1 do
        ---@type technology_unit_id
        local accessed_element = DCON.dcon_technology_get_index_technology_unit_as_technology(technology - 1, i) + 1
        if DCON.dcon_technology_unit_is_valid(accessed_element - 1) and func(accessed_element) then table.insert(t, accessed_element) end
    end
    return t
end
---@param technology technology_id valid technology_id
---@param func fun(item: technology_unit_id):boolean
---@return table<technology_unit_id, technology_unit_id>
function DATA.filter_technology_unit_from_technology(technology, func)
    ---@type table<technology_unit_id, technology_unit_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_technology_get_range_technology_unit_as_technology(technology - 1)
    for i = 0, range - 1 do
        ---@type technology_unit_id
        local accessed_element = DCON.dcon_technology_get_index_technology_unit_as_technology(technology - 1, i) + 1
        if DCON.dcon_technology_unit_is_valid(accessed_element - 1) and func(accessed_element) then t[accessed_element] = accessed_element end
    end
    return t
end
---@param technology_unit_id technology_unit_id valid technology_unit id
---@param value technology_id valid technology_id
function DATA.technology_unit_set_technology(technology_unit_id, value)
    DCON.dcon_technology_unit_set_technology(technology_unit_id - 1, value - 1)
end
---@param unlocked technology_unit_id valid unit_type_id
---@return unit_type_id Data retrieved from technology_unit
function DATA.technology_unit_get_unlocked(unlocked)
    return DCON.dcon_technology_unit_get_unlocked(unlocked - 1) + 1
end
---@param unlocked unit_type_id valid unit_type_id
---@return technology_unit_id technology_unit
function DATA.get_technology_unit_from_unlocked(unlocked)
    return DCON.dcon_unit_type_get_technology_unit_as_unlocked(unlocked - 1) + 1
end
---@param technology_unit_id technology_unit_id valid technology_unit id
---@param value unit_type_id valid unit_type_id
function DATA.technology_unit_set_unlocked(technology_unit_id, value)
    DCON.dcon_technology_unit_set_unlocked(technology_unit_id - 1, value - 1)
end

local fat_technology_unit_id_metatable = {
    __index = function (t,k)
        if (k == "technology") then return DATA.technology_unit_get_technology(t.id) end
        if (k == "unlocked") then return DATA.technology_unit_get_unlocked(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "technology") then
            DATA.technology_unit_set_technology(t.id, v)
            return
        end
        if (k == "unlocked") then
            DATA.technology_unit_set_unlocked(t.id, v)
            return
        end
        rawset(t, k, v)
    end
}
---@param id technology_unit_id
---@return fat_technology_unit_id fat_id
function DATA.fatten_technology_unit(id)
    local result = {id = id}
    setmetatable(result, fat_technology_unit_id_metatable)    return result
end
----------race----------


---race: LSP types---

---Unique identificator for race entity
---@class (exact) race_id : number
---@field is_race nil

---@class (exact) fat_race_id
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

---@class (exact) race_id_data_blob_definition
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
---@field minimum_comfortable_elevation number?
---@field female_body_size number
---@field male_body_size number
---@field female_efficiency number[]
---@field male_efficiency number[]
---@field female_infrastructure_needs number
---@field male_infrastructure_needs number
---@field requires_large_river boolean?
---@field requires_large_forest boolean?
---Sets values of race for given id
---@param id race_id
---@param data race_id_data_blob_definition
function DATA.setup_race(id, data)
    DATA.race_set_minimum_comfortable_elevation(id, 0.0)
    DATA.race_set_requires_large_river(id, false)
    DATA.race_set_requires_large_forest(id, false)
    DATA.race_set_name(id, data.name)
    DATA.race_set_icon(id, data.icon)
    DATA.race_set_female_portrait(id, data.female_portrait)
    DATA.race_set_male_portrait(id, data.male_portrait)
    DATA.race_set_description(id, data.description)
    DATA.race_set_r(id, data.r)
    DATA.race_set_g(id, data.g)
    DATA.race_set_b(id, data.b)
    DATA.race_set_carrying_capacity_weight(id, data.carrying_capacity_weight)
    DATA.race_set_fecundity(id, data.fecundity)
    DATA.race_set_spotting(id, data.spotting)
    DATA.race_set_visibility(id, data.visibility)
    DATA.race_set_males_per_hundred_females(id, data.males_per_hundred_females)
    DATA.race_set_child_age(id, data.child_age)
    DATA.race_set_teen_age(id, data.teen_age)
    DATA.race_set_adult_age(id, data.adult_age)
    DATA.race_set_middle_age(id, data.middle_age)
    DATA.race_set_elder_age(id, data.elder_age)
    DATA.race_set_max_age(id, data.max_age)
    DATA.race_set_minimum_comfortable_temperature(id, data.minimum_comfortable_temperature)
    DATA.race_set_minimum_absolute_temperature(id, data.minimum_absolute_temperature)
    if data.minimum_comfortable_elevation ~= nil then
        DATA.race_set_minimum_comfortable_elevation(id, data.minimum_comfortable_elevation)
    end
    DATA.race_set_female_body_size(id, data.female_body_size)
    DATA.race_set_male_body_size(id, data.male_body_size)
    for i, value in pairs(data.female_efficiency) do
        DATA.race_set_female_efficiency(id, i, value)
    end
    for i, value in pairs(data.male_efficiency) do
        DATA.race_set_male_efficiency(id, i, value)
    end
    DATA.race_set_female_infrastructure_needs(id, data.female_infrastructure_needs)
    DATA.race_set_male_infrastructure_needs(id, data.male_infrastructure_needs)
    if data.requires_large_river ~= nil then
        DATA.race_set_requires_large_river(id, data.requires_large_river)
    end
    if data.requires_large_forest ~= nil then
        DATA.race_set_requires_large_forest(id, data.requires_large_forest)
    end
end

ffi.cdef[[
void dcon_race_set_r(int32_t, float);
float dcon_race_get_r(int32_t);
void dcon_race_set_g(int32_t, float);
float dcon_race_get_g(int32_t);
void dcon_race_set_b(int32_t, float);
float dcon_race_get_b(int32_t);
void dcon_race_set_carrying_capacity_weight(int32_t, float);
float dcon_race_get_carrying_capacity_weight(int32_t);
void dcon_race_set_fecundity(int32_t, float);
float dcon_race_get_fecundity(int32_t);
void dcon_race_set_spotting(int32_t, float);
float dcon_race_get_spotting(int32_t);
void dcon_race_set_visibility(int32_t, float);
float dcon_race_get_visibility(int32_t);
void dcon_race_set_males_per_hundred_females(int32_t, float);
float dcon_race_get_males_per_hundred_females(int32_t);
void dcon_race_set_child_age(int32_t, float);
float dcon_race_get_child_age(int32_t);
void dcon_race_set_teen_age(int32_t, float);
float dcon_race_get_teen_age(int32_t);
void dcon_race_set_adult_age(int32_t, float);
float dcon_race_get_adult_age(int32_t);
void dcon_race_set_middle_age(int32_t, float);
float dcon_race_get_middle_age(int32_t);
void dcon_race_set_elder_age(int32_t, float);
float dcon_race_get_elder_age(int32_t);
void dcon_race_set_max_age(int32_t, float);
float dcon_race_get_max_age(int32_t);
void dcon_race_set_minimum_comfortable_temperature(int32_t, float);
float dcon_race_get_minimum_comfortable_temperature(int32_t);
void dcon_race_set_minimum_absolute_temperature(int32_t, float);
float dcon_race_get_minimum_absolute_temperature(int32_t);
void dcon_race_set_minimum_comfortable_elevation(int32_t, float);
float dcon_race_get_minimum_comfortable_elevation(int32_t);
void dcon_race_set_female_body_size(int32_t, float);
float dcon_race_get_female_body_size(int32_t);
void dcon_race_set_male_body_size(int32_t, float);
float dcon_race_get_male_body_size(int32_t);
void dcon_race_resize_female_efficiency(uint32_t);
void dcon_race_set_female_efficiency(int32_t, int32_t, float);
float dcon_race_get_female_efficiency(int32_t, int32_t);
void dcon_race_resize_male_efficiency(uint32_t);
void dcon_race_set_male_efficiency(int32_t, int32_t, float);
float dcon_race_get_male_efficiency(int32_t, int32_t);
void dcon_race_set_female_infrastructure_needs(int32_t, float);
float dcon_race_get_female_infrastructure_needs(int32_t);
void dcon_race_set_male_infrastructure_needs(int32_t, float);
float dcon_race_get_male_infrastructure_needs(int32_t);
void dcon_race_resize_female_needs(uint32_t);
need_definition* dcon_race_get_female_needs(int32_t, int32_t);
void dcon_race_resize_male_needs(uint32_t);
need_definition* dcon_race_get_male_needs(int32_t, int32_t);
void dcon_race_set_requires_large_river(int32_t, bool);
bool dcon_race_get_requires_large_river(int32_t);
void dcon_race_set_requires_large_forest(int32_t, bool);
bool dcon_race_get_requires_large_forest(int32_t);
int32_t dcon_create_race();
bool dcon_race_is_valid(int32_t);
void dcon_race_resize(uint32_t sz);
uint32_t dcon_race_size();
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

---race: LUA bindings---

DATA.race_size = 15
DCON.dcon_race_resize_female_efficiency(11)
DCON.dcon_race_resize_male_efficiency(11)
DCON.dcon_race_resize_female_needs(21)
DCON.dcon_race_resize_male_needs(21)
---@return race_id
function DATA.create_race()
    ---@type race_id
    local i  = DCON.dcon_create_race() + 1
    return i --[[@as race_id]]
end
---@param func fun(item: race_id)
function DATA.for_each_race(func)
    ---@type number
    local range = DCON.dcon_race_size()
    for i = 0, range - 1 do
        func(i + 1 --[[@as race_id]])
    end
end
---@param func fun(item: race_id):boolean
---@return table<race_id, race_id>
function DATA.filter_race(func)
    ---@type table<race_id, race_id>
    local t = {}
    ---@type number
    local range = DCON.dcon_race_size()
    for i = 0, range - 1 do
        if func(i + 1 --[[@as race_id]]) then t[i + 1 --[[@as race_id]]] = t[i + 1 --[[@as race_id]]] end
    end
    return t
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
    return DCON.dcon_race_get_r(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_r(race_id, value)
    DCON.dcon_race_set_r(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_r(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_r(race_id - 1)
    DCON.dcon_race_set_r(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number g
function DATA.race_get_g(race_id)
    return DCON.dcon_race_get_g(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_g(race_id, value)
    DCON.dcon_race_set_g(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_g(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_g(race_id - 1)
    DCON.dcon_race_set_g(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number b
function DATA.race_get_b(race_id)
    return DCON.dcon_race_get_b(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_b(race_id, value)
    DCON.dcon_race_set_b(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_b(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_b(race_id - 1)
    DCON.dcon_race_set_b(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number carrying_capacity_weight
function DATA.race_get_carrying_capacity_weight(race_id)
    return DCON.dcon_race_get_carrying_capacity_weight(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_carrying_capacity_weight(race_id, value)
    DCON.dcon_race_set_carrying_capacity_weight(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_carrying_capacity_weight(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_carrying_capacity_weight(race_id - 1)
    DCON.dcon_race_set_carrying_capacity_weight(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number fecundity
function DATA.race_get_fecundity(race_id)
    return DCON.dcon_race_get_fecundity(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_fecundity(race_id, value)
    DCON.dcon_race_set_fecundity(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_fecundity(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_fecundity(race_id - 1)
    DCON.dcon_race_set_fecundity(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number spotting How good is this unit at scouting
function DATA.race_get_spotting(race_id)
    return DCON.dcon_race_get_spotting(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_spotting(race_id, value)
    DCON.dcon_race_set_spotting(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_spotting(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_spotting(race_id - 1)
    DCON.dcon_race_set_spotting(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number visibility How visible is this unit in battles
function DATA.race_get_visibility(race_id)
    return DCON.dcon_race_get_visibility(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_visibility(race_id, value)
    DCON.dcon_race_set_visibility(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_visibility(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_visibility(race_id - 1)
    DCON.dcon_race_set_visibility(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number males_per_hundred_females
function DATA.race_get_males_per_hundred_females(race_id)
    return DCON.dcon_race_get_males_per_hundred_females(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_males_per_hundred_females(race_id, value)
    DCON.dcon_race_set_males_per_hundred_females(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_males_per_hundred_females(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_males_per_hundred_females(race_id - 1)
    DCON.dcon_race_set_males_per_hundred_females(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number child_age
function DATA.race_get_child_age(race_id)
    return DCON.dcon_race_get_child_age(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_child_age(race_id, value)
    DCON.dcon_race_set_child_age(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_child_age(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_child_age(race_id - 1)
    DCON.dcon_race_set_child_age(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number teen_age
function DATA.race_get_teen_age(race_id)
    return DCON.dcon_race_get_teen_age(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_teen_age(race_id, value)
    DCON.dcon_race_set_teen_age(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_teen_age(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_teen_age(race_id - 1)
    DCON.dcon_race_set_teen_age(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number adult_age
function DATA.race_get_adult_age(race_id)
    return DCON.dcon_race_get_adult_age(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_adult_age(race_id, value)
    DCON.dcon_race_set_adult_age(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_adult_age(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_adult_age(race_id - 1)
    DCON.dcon_race_set_adult_age(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number middle_age
function DATA.race_get_middle_age(race_id)
    return DCON.dcon_race_get_middle_age(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_middle_age(race_id, value)
    DCON.dcon_race_set_middle_age(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_middle_age(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_middle_age(race_id - 1)
    DCON.dcon_race_set_middle_age(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number elder_age
function DATA.race_get_elder_age(race_id)
    return DCON.dcon_race_get_elder_age(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_elder_age(race_id, value)
    DCON.dcon_race_set_elder_age(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_elder_age(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_elder_age(race_id - 1)
    DCON.dcon_race_set_elder_age(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number max_age
function DATA.race_get_max_age(race_id)
    return DCON.dcon_race_get_max_age(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_max_age(race_id, value)
    DCON.dcon_race_set_max_age(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_max_age(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_max_age(race_id - 1)
    DCON.dcon_race_set_max_age(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number minimum_comfortable_temperature
function DATA.race_get_minimum_comfortable_temperature(race_id)
    return DCON.dcon_race_get_minimum_comfortable_temperature(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_minimum_comfortable_temperature(race_id, value)
    DCON.dcon_race_set_minimum_comfortable_temperature(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_minimum_comfortable_temperature(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_minimum_comfortable_temperature(race_id - 1)
    DCON.dcon_race_set_minimum_comfortable_temperature(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number minimum_absolute_temperature
function DATA.race_get_minimum_absolute_temperature(race_id)
    return DCON.dcon_race_get_minimum_absolute_temperature(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_minimum_absolute_temperature(race_id, value)
    DCON.dcon_race_set_minimum_absolute_temperature(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_minimum_absolute_temperature(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_minimum_absolute_temperature(race_id - 1)
    DCON.dcon_race_set_minimum_absolute_temperature(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number minimum_comfortable_elevation
function DATA.race_get_minimum_comfortable_elevation(race_id)
    return DCON.dcon_race_get_minimum_comfortable_elevation(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_minimum_comfortable_elevation(race_id, value)
    DCON.dcon_race_set_minimum_comfortable_elevation(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_minimum_comfortable_elevation(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_minimum_comfortable_elevation(race_id - 1)
    DCON.dcon_race_set_minimum_comfortable_elevation(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number female_body_size
function DATA.race_get_female_body_size(race_id)
    return DCON.dcon_race_get_female_body_size(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_female_body_size(race_id, value)
    DCON.dcon_race_set_female_body_size(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_female_body_size(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_female_body_size(race_id - 1)
    DCON.dcon_race_set_female_body_size(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number male_body_size
function DATA.race_get_male_body_size(race_id)
    return DCON.dcon_race_get_male_body_size(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_male_body_size(race_id, value)
    DCON.dcon_race_set_male_body_size(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_male_body_size(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_male_body_size(race_id - 1)
    DCON.dcon_race_set_male_body_size(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@param index JOBTYPE valid
---@return number female_efficiency
function DATA.race_get_female_efficiency(race_id, index)
    assert(index ~= 0)
    return DCON.dcon_race_get_female_efficiency(race_id - 1, index - 1)
end
---@param race_id race_id valid race id
---@param index JOBTYPE valid index
---@param value number valid number
function DATA.race_set_female_efficiency(race_id, index, value)
    DCON.dcon_race_set_female_efficiency(race_id - 1, index - 1, value)
end
---@param race_id race_id valid race id
---@param index JOBTYPE valid index
---@param value number valid number
function DATA.race_inc_female_efficiency(race_id, index, value)
    ---@type number
    local current = DCON.dcon_race_get_female_efficiency(race_id - 1, index - 1)
    DCON.dcon_race_set_female_efficiency(race_id - 1, index - 1, current + value)
end
---@param race_id race_id valid race id
---@param index JOBTYPE valid
---@return number male_efficiency
function DATA.race_get_male_efficiency(race_id, index)
    assert(index ~= 0)
    return DCON.dcon_race_get_male_efficiency(race_id - 1, index - 1)
end
---@param race_id race_id valid race id
---@param index JOBTYPE valid index
---@param value number valid number
function DATA.race_set_male_efficiency(race_id, index, value)
    DCON.dcon_race_set_male_efficiency(race_id - 1, index - 1, value)
end
---@param race_id race_id valid race id
---@param index JOBTYPE valid index
---@param value number valid number
function DATA.race_inc_male_efficiency(race_id, index, value)
    ---@type number
    local current = DCON.dcon_race_get_male_efficiency(race_id - 1, index - 1)
    DCON.dcon_race_set_male_efficiency(race_id - 1, index - 1, current + value)
end
---@param race_id race_id valid race id
---@return number female_infrastructure_needs
function DATA.race_get_female_infrastructure_needs(race_id)
    return DCON.dcon_race_get_female_infrastructure_needs(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_female_infrastructure_needs(race_id, value)
    DCON.dcon_race_set_female_infrastructure_needs(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_female_infrastructure_needs(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_female_infrastructure_needs(race_id - 1)
    DCON.dcon_race_set_female_infrastructure_needs(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@return number male_infrastructure_needs
function DATA.race_get_male_infrastructure_needs(race_id)
    return DCON.dcon_race_get_male_infrastructure_needs(race_id - 1)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_set_male_infrastructure_needs(race_id, value)
    DCON.dcon_race_set_male_infrastructure_needs(race_id - 1, value)
end
---@param race_id race_id valid race id
---@param value number valid number
function DATA.race_inc_male_infrastructure_needs(race_id, value)
    ---@type number
    local current = DCON.dcon_race_get_male_infrastructure_needs(race_id - 1)
    DCON.dcon_race_set_male_infrastructure_needs(race_id - 1, current + value)
end
---@param race_id race_id valid race id
---@param index number valid
---@return NEED female_needs
function DATA.race_get_female_needs_need(race_id, index)
    assert(index ~= 0)
    return DCON.dcon_race_get_female_needs(race_id - 1, index - 1)[0].need
end
---@param race_id race_id valid race id
---@param index number valid
---@return use_case_id female_needs
function DATA.race_get_female_needs_use_case(race_id, index)
    assert(index ~= 0)
    return DCON.dcon_race_get_female_needs(race_id - 1, index - 1)[0].use_case
end
---@param race_id race_id valid race id
---@param index number valid
---@return number female_needs
function DATA.race_get_female_needs_required(race_id, index)
    assert(index ~= 0)
    return DCON.dcon_race_get_female_needs(race_id - 1, index - 1)[0].required
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value NEED valid NEED
function DATA.race_set_female_needs_need(race_id, index, value)
    DCON.dcon_race_get_female_needs(race_id - 1, index - 1)[0].need = value
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value use_case_id valid use_case_id
function DATA.race_set_female_needs_use_case(race_id, index, value)
    DCON.dcon_race_get_female_needs(race_id - 1, index - 1)[0].use_case = value
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value number valid number
function DATA.race_set_female_needs_required(race_id, index, value)
    DCON.dcon_race_get_female_needs(race_id - 1, index - 1)[0].required = value
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value number valid number
function DATA.race_inc_female_needs_required(race_id, index, value)
    ---@type number
    local current = DCON.dcon_race_get_female_needs(race_id - 1, index - 1)[0].required
    DCON.dcon_race_get_female_needs(race_id - 1, index - 1)[0].required = current + value
end
---@param race_id race_id valid race id
---@param index number valid
---@return NEED male_needs
function DATA.race_get_male_needs_need(race_id, index)
    assert(index ~= 0)
    return DCON.dcon_race_get_male_needs(race_id - 1, index - 1)[0].need
end
---@param race_id race_id valid race id
---@param index number valid
---@return use_case_id male_needs
function DATA.race_get_male_needs_use_case(race_id, index)
    assert(index ~= 0)
    return DCON.dcon_race_get_male_needs(race_id - 1, index - 1)[0].use_case
end
---@param race_id race_id valid race id
---@param index number valid
---@return number male_needs
function DATA.race_get_male_needs_required(race_id, index)
    assert(index ~= 0)
    return DCON.dcon_race_get_male_needs(race_id - 1, index - 1)[0].required
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value NEED valid NEED
function DATA.race_set_male_needs_need(race_id, index, value)
    DCON.dcon_race_get_male_needs(race_id - 1, index - 1)[0].need = value
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value use_case_id valid use_case_id
function DATA.race_set_male_needs_use_case(race_id, index, value)
    DCON.dcon_race_get_male_needs(race_id - 1, index - 1)[0].use_case = value
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value number valid number
function DATA.race_set_male_needs_required(race_id, index, value)
    DCON.dcon_race_get_male_needs(race_id - 1, index - 1)[0].required = value
end
---@param race_id race_id valid race id
---@param index number valid index
---@param value number valid number
function DATA.race_inc_male_needs_required(race_id, index, value)
    ---@type number
    local current = DCON.dcon_race_get_male_needs(race_id - 1, index - 1)[0].required
    DCON.dcon_race_get_male_needs(race_id - 1, index - 1)[0].required = current + value
end
---@param race_id race_id valid race id
---@return boolean requires_large_river
function DATA.race_get_requires_large_river(race_id)
    return DCON.dcon_race_get_requires_large_river(race_id - 1)
end
---@param race_id race_id valid race id
---@param value boolean valid boolean
function DATA.race_set_requires_large_river(race_id, value)
    DCON.dcon_race_set_requires_large_river(race_id - 1, value)
end
---@param race_id race_id valid race id
---@return boolean requires_large_forest
function DATA.race_get_requires_large_forest(race_id)
    return DCON.dcon_race_get_requires_large_forest(race_id - 1)
end
---@param race_id race_id valid race id
---@param value boolean valid boolean
function DATA.race_set_requires_large_forest(race_id, value)
    DCON.dcon_race_set_requires_large_forest(race_id - 1, value)
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


function DATA.save_state()
    local current_lua_state = {}
    current_lua_state.pop_faith = DATA.pop_faith
    current_lua_state.pop_culture = DATA.pop_culture
    current_lua_state.pop_name = DATA.pop_name
    current_lua_state.pop_busy = DATA.pop_busy
    current_lua_state.pop_dead = DATA.pop_dead
    current_lua_state.pop_former_pop = DATA.pop_former_pop
    current_lua_state.province_name = DATA.province_name
    current_lua_state.warband_name = DATA.warband_name
    current_lua_state.warband_guard_of = DATA.warband_guard_of
    current_lua_state.realm_exists = DATA.realm_exists
    current_lua_state.realm_name = DATA.realm_name
    current_lua_state.realm_primary_culture = DATA.realm_primary_culture
    current_lua_state.realm_primary_faith = DATA.realm_primary_faith
    current_lua_state.realm_quests_raid = DATA.realm_quests_raid
    current_lua_state.realm_quests_explore = DATA.realm_quests_explore
    current_lua_state.realm_quests_patrol = DATA.realm_quests_patrol
    current_lua_state.realm_patrols = DATA.realm_patrols
    current_lua_state.realm_known_provinces = DATA.realm_known_provinces

    bitser.dumpLoveFile("gamestatesave.bitserbeaver", current_lua_state)

end
function DATA.load_state()
    local data_love, error = love.filesystem.newFileData("gamestatesave.binbeaver")
    assert(data_love, error)
    local data = ffi.cast("uint8_t*", data_love:getPointer())
    local current_offset = 0
    local current_shift = 0
    local total_ffi_size = 0
    total_ffi_size = total_ffi_size + ffi.sizeof("tile") * 1500000
    total_ffi_size = total_ffi_size + ffi.sizeof("pop") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("province") * 20000
    total_ffi_size = total_ffi_size + ffi.sizeof("army") * 5000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband") * 50000
    total_ffi_size = total_ffi_size + ffi.sizeof("realm") * 15000
    total_ffi_size = total_ffi_size + ffi.sizeof("negotiation") * 2500
    total_ffi_size = total_ffi_size + ffi.sizeof("building") * 200000
    total_ffi_size = total_ffi_size + ffi.sizeof("ownership") * 200000
    total_ffi_size = total_ffi_size + ffi.sizeof("employment") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("building_location") * 200000
    total_ffi_size = total_ffi_size + ffi.sizeof("army_membership") * 50000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_leader") * 50000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_recruiter") * 50000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_commander") * 50000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_location") * 50000
    total_ffi_size = total_ffi_size + ffi.sizeof("warband_unit") * 50000
    total_ffi_size = total_ffi_size + ffi.sizeof("character_location") * 100000
    total_ffi_size = total_ffi_size + ffi.sizeof("home") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("pop_location") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("outlaw_location") * 300000
    total_ffi_size = total_ffi_size + ffi.sizeof("tile_province_membership") * 1500000
    total_ffi_size = total_ffi_size + ffi.sizeof("province_neighborhood") * 250000
    total_ffi_size = total_ffi_size + ffi.sizeof("parent_child_relation") * 900000
    total_ffi_size = total_ffi_size + ffi.sizeof("loyalty") * 200000
    total_ffi_size = total_ffi_size + ffi.sizeof("succession") * 200000
    total_ffi_size = total_ffi_size + ffi.sizeof("realm_armies") * 15000
    total_ffi_size = total_ffi_size + ffi.sizeof("realm_guard") * 15000
    total_ffi_size = total_ffi_size + ffi.sizeof("realm_overseer") * 15000
    total_ffi_size = total_ffi_size + ffi.sizeof("realm_leadership") * 15000
    total_ffi_size = total_ffi_size + ffi.sizeof("realm_subject_relation") * 15000
    total_ffi_size = total_ffi_size + ffi.sizeof("tax_collector") * 45000
    total_ffi_size = total_ffi_size + ffi.sizeof("personal_rights") * 450000
    total_ffi_size = total_ffi_size + ffi.sizeof("realm_provinces") * 30000
    total_ffi_size = total_ffi_size + ffi.sizeof("popularity") * 450000
    total_ffi_size = total_ffi_size + ffi.sizeof("realm_pop") * 300000
    current_shift = ffi.sizeof("tile") * 1500000
    ffi.copy(DATA.tile, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("pop") * 300000
    ffi.copy(DATA.pop, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("province") * 20000
    ffi.copy(DATA.province, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("army") * 5000
    ffi.copy(DATA.army, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband") * 50000
    ffi.copy(DATA.warband, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("realm") * 15000
    ffi.copy(DATA.realm, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("negotiation") * 2500
    ffi.copy(DATA.negotiation, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("building") * 200000
    ffi.copy(DATA.building, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("ownership") * 200000
    ffi.copy(DATA.ownership, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("employment") * 300000
    ffi.copy(DATA.employment, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("building_location") * 200000
    ffi.copy(DATA.building_location, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("army_membership") * 50000
    ffi.copy(DATA.army_membership, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_leader") * 50000
    ffi.copy(DATA.warband_leader, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_recruiter") * 50000
    ffi.copy(DATA.warband_recruiter, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_commander") * 50000
    ffi.copy(DATA.warband_commander, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("warband_location") * 50000
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
    current_shift = ffi.sizeof("province_neighborhood") * 250000
    ffi.copy(DATA.province_neighborhood, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("parent_child_relation") * 900000
    ffi.copy(DATA.parent_child_relation, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("loyalty") * 200000
    ffi.copy(DATA.loyalty, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("succession") * 200000
    ffi.copy(DATA.succession, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("realm_armies") * 15000
    ffi.copy(DATA.realm_armies, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("realm_guard") * 15000
    ffi.copy(DATA.realm_guard, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("realm_overseer") * 15000
    ffi.copy(DATA.realm_overseer, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("realm_leadership") * 15000
    ffi.copy(DATA.realm_leadership, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("realm_subject_relation") * 15000
    ffi.copy(DATA.realm_subject_relation, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("tax_collector") * 45000
    ffi.copy(DATA.tax_collector, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("personal_rights") * 450000
    ffi.copy(DATA.personal_rights, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("realm_provinces") * 30000
    ffi.copy(DATA.realm_provinces, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("popularity") * 450000
    ffi.copy(DATA.popularity, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("realm_pop") * 300000
    ffi.copy(DATA.realm_pop, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
end
function DATA.test_set_get_0()
    local id = DATA.create_tile()
    local fat_id = DATA.fatten_tile(id)
    fat_id.world_id = 12
    fat_id.is_land = false
    fat_id.is_fresh = true
    fat_id.is_border = false
    fat_id.elevation = 12
    fat_id.slope = 11
    fat_id.grass = 5
    fat_id.shrub = -1
    fat_id.conifer = 10
    fat_id.broadleaf = 2
    fat_id.ideal_grass = 17
    fat_id.ideal_shrub = -7
    fat_id.ideal_conifer = 12
    fat_id.ideal_broadleaf = -12
    fat_id.silt = -2
    fat_id.clay = -12
    fat_id.sand = -14
    fat_id.soil_minerals = 19
    fat_id.soil_organics = -4
    fat_id.january_waterflow = 14
    fat_id.january_rain = 18
    fat_id.january_temperature = -11
    fat_id.july_waterflow = -1
    fat_id.july_rain = -14
    fat_id.july_temperature = -16
    fat_id.waterlevel = 1
    fat_id.has_river = false
    fat_id.has_marsh = true
    fat_id.ice = 2
    fat_id.ice_age_ice = 7
    fat_id.debug_r = 0
    fat_id.debug_g = 19
    fat_id.debug_b = 20
    fat_id.real_r = -7
    fat_id.real_g = 15
    fat_id.real_b = 10
    fat_id.pathfinding_index = 14
    fat_id.resource = 16
    fat_id.bedrock = 8
    fat_id.biome = 1
    local test_passed = true
    test_passed = test_passed and fat_id.world_id == 12
    if not test_passed then print("world_id", 12, fat_id.world_id) end
    test_passed = test_passed and fat_id.is_land == false
    if not test_passed then print("is_land", false, fat_id.is_land) end
    test_passed = test_passed and fat_id.is_fresh == true
    if not test_passed then print("is_fresh", true, fat_id.is_fresh) end
    test_passed = test_passed and fat_id.is_border == false
    if not test_passed then print("is_border", false, fat_id.is_border) end
    test_passed = test_passed and fat_id.elevation == 12
    if not test_passed then print("elevation", 12, fat_id.elevation) end
    test_passed = test_passed and fat_id.slope == 11
    if not test_passed then print("slope", 11, fat_id.slope) end
    test_passed = test_passed and fat_id.grass == 5
    if not test_passed then print("grass", 5, fat_id.grass) end
    test_passed = test_passed and fat_id.shrub == -1
    if not test_passed then print("shrub", -1, fat_id.shrub) end
    test_passed = test_passed and fat_id.conifer == 10
    if not test_passed then print("conifer", 10, fat_id.conifer) end
    test_passed = test_passed and fat_id.broadleaf == 2
    if not test_passed then print("broadleaf", 2, fat_id.broadleaf) end
    test_passed = test_passed and fat_id.ideal_grass == 17
    if not test_passed then print("ideal_grass", 17, fat_id.ideal_grass) end
    test_passed = test_passed and fat_id.ideal_shrub == -7
    if not test_passed then print("ideal_shrub", -7, fat_id.ideal_shrub) end
    test_passed = test_passed and fat_id.ideal_conifer == 12
    if not test_passed then print("ideal_conifer", 12, fat_id.ideal_conifer) end
    test_passed = test_passed and fat_id.ideal_broadleaf == -12
    if not test_passed then print("ideal_broadleaf", -12, fat_id.ideal_broadleaf) end
    test_passed = test_passed and fat_id.silt == -2
    if not test_passed then print("silt", -2, fat_id.silt) end
    test_passed = test_passed and fat_id.clay == -12
    if not test_passed then print("clay", -12, fat_id.clay) end
    test_passed = test_passed and fat_id.sand == -14
    if not test_passed then print("sand", -14, fat_id.sand) end
    test_passed = test_passed and fat_id.soil_minerals == 19
    if not test_passed then print("soil_minerals", 19, fat_id.soil_minerals) end
    test_passed = test_passed and fat_id.soil_organics == -4
    if not test_passed then print("soil_organics", -4, fat_id.soil_organics) end
    test_passed = test_passed and fat_id.january_waterflow == 14
    if not test_passed then print("january_waterflow", 14, fat_id.january_waterflow) end
    test_passed = test_passed and fat_id.january_rain == 18
    if not test_passed then print("january_rain", 18, fat_id.january_rain) end
    test_passed = test_passed and fat_id.january_temperature == -11
    if not test_passed then print("january_temperature", -11, fat_id.january_temperature) end
    test_passed = test_passed and fat_id.july_waterflow == -1
    if not test_passed then print("july_waterflow", -1, fat_id.july_waterflow) end
    test_passed = test_passed and fat_id.july_rain == -14
    if not test_passed then print("july_rain", -14, fat_id.july_rain) end
    test_passed = test_passed and fat_id.july_temperature == -16
    if not test_passed then print("july_temperature", -16, fat_id.july_temperature) end
    test_passed = test_passed and fat_id.waterlevel == 1
    if not test_passed then print("waterlevel", 1, fat_id.waterlevel) end
    test_passed = test_passed and fat_id.has_river == false
    if not test_passed then print("has_river", false, fat_id.has_river) end
    test_passed = test_passed and fat_id.has_marsh == true
    if not test_passed then print("has_marsh", true, fat_id.has_marsh) end
    test_passed = test_passed and fat_id.ice == 2
    if not test_passed then print("ice", 2, fat_id.ice) end
    test_passed = test_passed and fat_id.ice_age_ice == 7
    if not test_passed then print("ice_age_ice", 7, fat_id.ice_age_ice) end
    test_passed = test_passed and fat_id.debug_r == 0
    if not test_passed then print("debug_r", 0, fat_id.debug_r) end
    test_passed = test_passed and fat_id.debug_g == 19
    if not test_passed then print("debug_g", 19, fat_id.debug_g) end
    test_passed = test_passed and fat_id.debug_b == 20
    if not test_passed then print("debug_b", 20, fat_id.debug_b) end
    test_passed = test_passed and fat_id.real_r == -7
    if not test_passed then print("real_r", -7, fat_id.real_r) end
    test_passed = test_passed and fat_id.real_g == 15
    if not test_passed then print("real_g", 15, fat_id.real_g) end
    test_passed = test_passed and fat_id.real_b == 10
    if not test_passed then print("real_b", 10, fat_id.real_b) end
    test_passed = test_passed and fat_id.pathfinding_index == 14
    if not test_passed then print("pathfinding_index", 14, fat_id.pathfinding_index) end
    test_passed = test_passed and fat_id.resource == 16
    if not test_passed then print("resource", 16, fat_id.resource) end
    test_passed = test_passed and fat_id.bedrock == 8
    if not test_passed then print("bedrock", 8, fat_id.bedrock) end
    test_passed = test_passed and fat_id.biome == 1
    if not test_passed then print("biome", 1, fat_id.biome) end
    print("SET_GET_TEST_0_tile:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_pop()
    local fat_id = DATA.fatten_pop(id)
    fat_id.race = 12
    fat_id.female = false
    fat_id.age = 1
    fat_id.savings = -4
    fat_id.life_needs_satisfaction = 12
    fat_id.basic_needs_satisfaction = 11
    for j = 1, 20 do
        DATA.pop_set_need_satisfaction_need(id, j, 6)
    end
    for j = 1, 20 do
        DATA.pop_set_need_satisfaction_use_case(id, j, 9)
    end
    for j = 1, 20 do
        DATA.pop_set_need_satisfaction_consumed(id, j, 10)
    end
    for j = 1, 20 do
        DATA.pop_set_need_satisfaction_demanded(id, j, 2)
    end
    for j = 1, 10 do
        DATA.pop_set_traits(id, j --[[@as number]],  9)    end
    for j = 1, 100 do
        DATA.pop_set_inventory(id, j --[[@as trade_good_id]],  -7)    end
    for j = 1, 100 do
        DATA.pop_set_price_memory(id, j --[[@as trade_good_id]],  12)    end
    fat_id.pending_economy_income = -12
    fat_id.forage_ratio = -2
    fat_id.work_ratio = -12
    fat_id.rank = 0
    for j = 1, 20 do
        DATA.pop_set_dna(id, j --[[@as number]],  19)    end
    local test_passed = true
    test_passed = test_passed and fat_id.race == 12
    if not test_passed then print("race", 12, fat_id.race) end
    test_passed = test_passed and fat_id.female == false
    if not test_passed then print("female", false, fat_id.female) end
    test_passed = test_passed and fat_id.age == 1
    if not test_passed then print("age", 1, fat_id.age) end
    test_passed = test_passed and fat_id.savings == -4
    if not test_passed then print("savings", -4, fat_id.savings) end
    test_passed = test_passed and fat_id.life_needs_satisfaction == 12
    if not test_passed then print("life_needs_satisfaction", 12, fat_id.life_needs_satisfaction) end
    test_passed = test_passed and fat_id.basic_needs_satisfaction == 11
    if not test_passed then print("basic_needs_satisfaction", 11, fat_id.basic_needs_satisfaction) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_need_satisfaction_need(id, j) == 6
    end
    if not test_passed then print("need_satisfaction.need", 6, DATA.pop[id].need_satisfaction[0].need) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_need_satisfaction_use_case(id, j) == 9
    end
    if not test_passed then print("need_satisfaction.use_case", 9, DATA.pop[id].need_satisfaction[0].use_case) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_need_satisfaction_consumed(id, j) == 10
    end
    if not test_passed then print("need_satisfaction.consumed", 10, DATA.pop[id].need_satisfaction[0].consumed) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_need_satisfaction_demanded(id, j) == 2
    end
    if not test_passed then print("need_satisfaction.demanded", 2, DATA.pop[id].need_satisfaction[0].demanded) end
    for j = 1, 10 do
        test_passed = test_passed and DATA.pop_get_traits(id, j --[[@as number]]) == 9
    end
    if not test_passed then print("traits", 9, DATA.pop[id].traits[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.pop_get_inventory(id, j --[[@as trade_good_id]]) == -7
    end
    if not test_passed then print("inventory", -7, DATA.pop[id].inventory[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.pop_get_price_memory(id, j --[[@as trade_good_id]]) == 12
    end
    if not test_passed then print("price_memory", 12, DATA.pop[id].price_memory[0]) end
    test_passed = test_passed and fat_id.pending_economy_income == -12
    if not test_passed then print("pending_economy_income", -12, fat_id.pending_economy_income) end
    test_passed = test_passed and fat_id.forage_ratio == -2
    if not test_passed then print("forage_ratio", -2, fat_id.forage_ratio) end
    test_passed = test_passed and fat_id.work_ratio == -12
    if not test_passed then print("work_ratio", -12, fat_id.work_ratio) end
    test_passed = test_passed and fat_id.rank == 0
    if not test_passed then print("rank", 0, fat_id.rank) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_dna(id, j --[[@as number]]) == 19
    end
    if not test_passed then print("dna", 19, DATA.pop[id].dna[0]) end
    print("SET_GET_TEST_0_pop:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_province()
    local fat_id = DATA.fatten_province(id)
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
    fat_id.infrastructure_efficiency = 12
    for j = 1, 400 do
        DATA.province_set_technologies_present(id, j --[[@as technology_id]],  4)    end
    for j = 1, 400 do
        DATA.province_set_technologies_researchable(id, j --[[@as technology_id]],  9)    end
    for j = 1, 250 do
        DATA.province_set_buildable_buildings(id, j --[[@as building_type_id]],  4)    end
    for j = 1, 100 do
        DATA.province_set_local_production(id, j --[[@as trade_good_id]],  -14)    end
    for j = 1, 100 do
        DATA.province_set_temp_buffer_0(id, j --[[@as trade_good_id]],  19)    end
    for j = 1, 100 do
        DATA.province_set_local_consumption(id, j --[[@as trade_good_id]],  -4)    end
    for j = 1, 100 do
        DATA.province_set_local_demand(id, j --[[@as trade_good_id]],  14)    end
    for j = 1, 100 do
        DATA.province_set_local_satisfaction(id, j --[[@as trade_good_id]],  18)    end
    for j = 1, 100 do
        DATA.province_set_temp_buffer_use_0(id, j --[[@as use_case_id]],  -11)    end
    for j = 1, 100 do
        DATA.province_set_temp_buffer_use_grad(id, j --[[@as use_case_id]],  -1)    end
    for j = 1, 100 do
        DATA.province_set_local_use_satisfaction(id, j --[[@as use_case_id]],  -14)    end
    for j = 1, 100 do
        DATA.province_set_local_use_buffer_demand(id, j --[[@as use_case_id]],  -16)    end
    for j = 1, 100 do
        DATA.province_set_local_use_buffer_supply(id, j --[[@as use_case_id]],  1)    end
    for j = 1, 100 do
        DATA.province_set_local_use_buffer_cost(id, j --[[@as use_case_id]],  10)    end
    for j = 1, 100 do
        DATA.province_set_local_storage(id, j --[[@as trade_good_id]],  15)    end
    for j = 1, 100 do
        DATA.province_set_local_prices(id, j --[[@as trade_good_id]],  -14)    end
    fat_id.local_wealth = 2
    fat_id.trade_wealth = 7
    fat_id.local_income = 0
    fat_id.local_building_upkeep = 19
    fat_id.foragers = 20
    fat_id.foragers_water = -7
    fat_id.foragers_limit = 15
    for j = 1, 25 do
        DATA.province_set_foragers_targets_output_good(id, j, 15)
    end
    for j = 1, 25 do
        DATA.province_set_foragers_targets_output_value(id, j, 8)
    end
    for j = 1, 25 do
        DATA.province_set_foragers_targets_amount(id, j, 13)
    end
    for j = 1, 25 do
        DATA.province_set_foragers_targets_forage(id, j, 4)
    end
    for j = 1, 25 do
        DATA.province_set_local_resources_resource(id, j, 1)
    end
    for j = 1, 25 do
        DATA.province_set_local_resources_location(id, j, 17)
    end
    fat_id.mood = -20
    for j = 1, 20 do
        DATA.province_set_unit_types(id, j --[[@as unit_type_id]],  2)    end
    for j = 1, 250 do
        DATA.province_set_throughput_boosts(id, j --[[@as production_method_id]],  5)    end
    for j = 1, 250 do
        DATA.province_set_input_efficiency_boosts(id, j --[[@as production_method_id]],  20)    end
    for j = 1, 250 do
        DATA.province_set_output_efficiency_boosts(id, j --[[@as production_method_id]],  -20)    end
    fat_id.on_a_river = false
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
    test_passed = test_passed and fat_id.infrastructure_efficiency == 12
    if not test_passed then print("infrastructure_efficiency", 12, fat_id.infrastructure_efficiency) end
    for j = 1, 400 do
        test_passed = test_passed and DATA.province_get_technologies_present(id, j --[[@as technology_id]]) == 4
    end
    if not test_passed then print("technologies_present", 4, DATA.province[id].technologies_present[0]) end
    for j = 1, 400 do
        test_passed = test_passed and DATA.province_get_technologies_researchable(id, j --[[@as technology_id]]) == 9
    end
    if not test_passed then print("technologies_researchable", 9, DATA.province[id].technologies_researchable[0]) end
    for j = 1, 250 do
        test_passed = test_passed and DATA.province_get_buildable_buildings(id, j --[[@as building_type_id]]) == 4
    end
    if not test_passed then print("buildable_buildings", 4, DATA.province[id].buildable_buildings[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_production(id, j --[[@as trade_good_id]]) == -14
    end
    if not test_passed then print("local_production", -14, DATA.province[id].local_production[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_temp_buffer_0(id, j --[[@as trade_good_id]]) == 19
    end
    if not test_passed then print("temp_buffer_0", 19, DATA.province[id].temp_buffer_0[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_consumption(id, j --[[@as trade_good_id]]) == -4
    end
    if not test_passed then print("local_consumption", -4, DATA.province[id].local_consumption[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_demand(id, j --[[@as trade_good_id]]) == 14
    end
    if not test_passed then print("local_demand", 14, DATA.province[id].local_demand[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_satisfaction(id, j --[[@as trade_good_id]]) == 18
    end
    if not test_passed then print("local_satisfaction", 18, DATA.province[id].local_satisfaction[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_temp_buffer_use_0(id, j --[[@as use_case_id]]) == -11
    end
    if not test_passed then print("temp_buffer_use_0", -11, DATA.province[id].temp_buffer_use_0[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_temp_buffer_use_grad(id, j --[[@as use_case_id]]) == -1
    end
    if not test_passed then print("temp_buffer_use_grad", -1, DATA.province[id].temp_buffer_use_grad[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_use_satisfaction(id, j --[[@as use_case_id]]) == -14
    end
    if not test_passed then print("local_use_satisfaction", -14, DATA.province[id].local_use_satisfaction[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_use_buffer_demand(id, j --[[@as use_case_id]]) == -16
    end
    if not test_passed then print("local_use_buffer_demand", -16, DATA.province[id].local_use_buffer_demand[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_use_buffer_supply(id, j --[[@as use_case_id]]) == 1
    end
    if not test_passed then print("local_use_buffer_supply", 1, DATA.province[id].local_use_buffer_supply[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_use_buffer_cost(id, j --[[@as use_case_id]]) == 10
    end
    if not test_passed then print("local_use_buffer_cost", 10, DATA.province[id].local_use_buffer_cost[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_storage(id, j --[[@as trade_good_id]]) == 15
    end
    if not test_passed then print("local_storage", 15, DATA.province[id].local_storage[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_prices(id, j --[[@as trade_good_id]]) == -14
    end
    if not test_passed then print("local_prices", -14, DATA.province[id].local_prices[0]) end
    test_passed = test_passed and fat_id.local_wealth == 2
    if not test_passed then print("local_wealth", 2, fat_id.local_wealth) end
    test_passed = test_passed and fat_id.trade_wealth == 7
    if not test_passed then print("trade_wealth", 7, fat_id.trade_wealth) end
    test_passed = test_passed and fat_id.local_income == 0
    if not test_passed then print("local_income", 0, fat_id.local_income) end
    test_passed = test_passed and fat_id.local_building_upkeep == 19
    if not test_passed then print("local_building_upkeep", 19, fat_id.local_building_upkeep) end
    test_passed = test_passed and fat_id.foragers == 20
    if not test_passed then print("foragers", 20, fat_id.foragers) end
    test_passed = test_passed and fat_id.foragers_water == -7
    if not test_passed then print("foragers_water", -7, fat_id.foragers_water) end
    test_passed = test_passed and fat_id.foragers_limit == 15
    if not test_passed then print("foragers_limit", 15, fat_id.foragers_limit) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_foragers_targets_output_good(id, j) == 15
    end
    if not test_passed then print("foragers_targets.output_good", 15, DATA.province[id].foragers_targets[0].output_good) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_foragers_targets_output_value(id, j) == 8
    end
    if not test_passed then print("foragers_targets.output_value", 8, DATA.province[id].foragers_targets[0].output_value) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_foragers_targets_amount(id, j) == 13
    end
    if not test_passed then print("foragers_targets.amount", 13, DATA.province[id].foragers_targets[0].amount) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_foragers_targets_forage(id, j) == 4
    end
    if not test_passed then print("foragers_targets.forage", 4, DATA.province[id].foragers_targets[0].forage) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_local_resources_resource(id, j) == 1
    end
    if not test_passed then print("local_resources.resource", 1, DATA.province[id].local_resources[0].resource) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_local_resources_location(id, j) == 17
    end
    if not test_passed then print("local_resources.location", 17, DATA.province[id].local_resources[0].location) end
    test_passed = test_passed and fat_id.mood == -20
    if not test_passed then print("mood", -20, fat_id.mood) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.province_get_unit_types(id, j --[[@as unit_type_id]]) == 2
    end
    if not test_passed then print("unit_types", 2, DATA.province[id].unit_types[0]) end
    for j = 1, 250 do
        test_passed = test_passed and DATA.province_get_throughput_boosts(id, j --[[@as production_method_id]]) == 5
    end
    if not test_passed then print("throughput_boosts", 5, DATA.province[id].throughput_boosts[0]) end
    for j = 1, 250 do
        test_passed = test_passed and DATA.province_get_input_efficiency_boosts(id, j --[[@as production_method_id]]) == 20
    end
    if not test_passed then print("input_efficiency_boosts", 20, DATA.province[id].input_efficiency_boosts[0]) end
    for j = 1, 250 do
        test_passed = test_passed and DATA.province_get_output_efficiency_boosts(id, j --[[@as production_method_id]]) == -20
    end
    if not test_passed then print("output_efficiency_boosts", -20, DATA.province[id].output_efficiency_boosts[0]) end
    test_passed = test_passed and fat_id.on_a_river == false
    if not test_passed then print("on_a_river", false, fat_id.on_a_river) end
    test_passed = test_passed and fat_id.on_a_forest == false
    if not test_passed then print("on_a_forest", false, fat_id.on_a_forest) end
    print("SET_GET_TEST_0_province:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_army()
    local fat_id = DATA.fatten_army(id)
    fat_id.destination = 12
    local test_passed = true
    test_passed = test_passed and fat_id.destination == 12
    if not test_passed then print("destination", 12, fat_id.destination) end
    print("SET_GET_TEST_0_army:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_warband()
    local fat_id = DATA.fatten_warband(id)
    for j = 1, 20 do
        DATA.warband_set_units_current(id, j --[[@as unit_type_id]],  4)    end
    for j = 1, 20 do
        DATA.warband_set_units_target(id, j --[[@as unit_type_id]],  6)    end
    fat_id.current_status = 0
    fat_id.idle_stance = 1
    fat_id.current_free_time_ratio = 12
    fat_id.treasury = 11
    fat_id.total_upkeep = 5
    fat_id.predicted_upkeep = -1
    fat_id.supplies = 10
    fat_id.supplies_target_days = 2
    fat_id.morale = 17
    local test_passed = true
    for j = 1, 20 do
        test_passed = test_passed and DATA.warband_get_units_current(id, j --[[@as unit_type_id]]) == 4
    end
    if not test_passed then print("units_current", 4, DATA.warband[id].units_current[0]) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.warband_get_units_target(id, j --[[@as unit_type_id]]) == 6
    end
    if not test_passed then print("units_target", 6, DATA.warband[id].units_target[0]) end
    test_passed = test_passed and fat_id.current_status == 0
    if not test_passed then print("current_status", 0, fat_id.current_status) end
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
    local id = DATA.create_realm()
    local fat_id = DATA.fatten_realm(id)
    fat_id.budget_change = 4
    fat_id.budget_saved_change = 6
    for j = 1, 38 do
        DATA.realm_set_budget_spending_by_category(id, j --[[@as ECONOMY_REASON]],  -18)    end
    for j = 1, 38 do
        DATA.realm_set_budget_income_by_category(id, j --[[@as ECONOMY_REASON]],  -4)    end
    for j = 1, 38 do
        DATA.realm_set_budget_treasury_change_by_category(id, j --[[@as ECONOMY_REASON]],  12)    end
    fat_id.budget_treasury = 11
    fat_id.budget_treasury_target = 5
    for j = 1, 7 do
        DATA.realm_set_budget_ratio(id, j, -1)
    end
    for j = 1, 7 do
        DATA.realm_set_budget_budget(id, j, 10)
    end
    for j = 1, 7 do
        DATA.realm_set_budget_to_be_invested(id, j, 2)
    end
    for j = 1, 7 do
        DATA.realm_set_budget_target(id, j, 17)
    end
    fat_id.budget_tax_target = -7
    fat_id.budget_tax_collected_this_year = 12
    fat_id.r = -12
    fat_id.g = -2
    fat_id.b = -12
    fat_id.primary_race = 3
    fat_id.capitol = 19
    fat_id.trading_right_cost = -4
    fat_id.building_right_cost = 14
    fat_id.law_trade = 1
    fat_id.law_building = 2
    fat_id.prepare_attack_flag = true
    fat_id.coa_base_r = -16
    fat_id.coa_base_g = 1
    fat_id.coa_base_b = 10
    fat_id.coa_background_r = 15
    fat_id.coa_background_g = -14
    fat_id.coa_background_b = 2
    fat_id.coa_foreground_r = 7
    fat_id.coa_foreground_g = 0
    fat_id.coa_foreground_b = 19
    fat_id.coa_emblem_r = 20
    fat_id.coa_emblem_g = -7
    fat_id.coa_emblem_b = 15
    fat_id.coa_background_image = 15
    fat_id.coa_foreground_image = 14
    fat_id.coa_emblem_image = 16
    for j = 1, 100 do
        DATA.realm_set_resources(id, j --[[@as trade_good_id]],  -4)    end
    for j = 1, 100 do
        DATA.realm_set_production(id, j --[[@as trade_good_id]],  -17)    end
    for j = 1, 100 do
        DATA.realm_set_bought(id, j --[[@as trade_good_id]],  15)    end
    for j = 1, 100 do
        DATA.realm_set_sold(id, j --[[@as trade_good_id]],  -20)    end
    fat_id.expected_food_consumption = -15
    local test_passed = true
    test_passed = test_passed and fat_id.budget_change == 4
    if not test_passed then print("budget_change", 4, fat_id.budget_change) end
    test_passed = test_passed and fat_id.budget_saved_change == 6
    if not test_passed then print("budget_saved_change", 6, fat_id.budget_saved_change) end
    for j = 1, 38 do
        test_passed = test_passed and DATA.realm_get_budget_spending_by_category(id, j --[[@as ECONOMY_REASON]]) == -18
    end
    if not test_passed then print("budget_spending_by_category", -18, DATA.realm[id].budget_spending_by_category[0]) end
    for j = 1, 38 do
        test_passed = test_passed and DATA.realm_get_budget_income_by_category(id, j --[[@as ECONOMY_REASON]]) == -4
    end
    if not test_passed then print("budget_income_by_category", -4, DATA.realm[id].budget_income_by_category[0]) end
    for j = 1, 38 do
        test_passed = test_passed and DATA.realm_get_budget_treasury_change_by_category(id, j --[[@as ECONOMY_REASON]]) == 12
    end
    if not test_passed then print("budget_treasury_change_by_category", 12, DATA.realm[id].budget_treasury_change_by_category[0]) end
    test_passed = test_passed and fat_id.budget_treasury == 11
    if not test_passed then print("budget_treasury", 11, fat_id.budget_treasury) end
    test_passed = test_passed and fat_id.budget_treasury_target == 5
    if not test_passed then print("budget_treasury_target", 5, fat_id.budget_treasury_target) end
    for j = 1, 7 do
        test_passed = test_passed and DATA.realm_get_budget_ratio(id, j) == -1
    end
    if not test_passed then print("budget.ratio", -1, DATA.realm[id].budget[0].ratio) end
    for j = 1, 7 do
        test_passed = test_passed and DATA.realm_get_budget_budget(id, j) == 10
    end
    if not test_passed then print("budget.budget", 10, DATA.realm[id].budget[0].budget) end
    for j = 1, 7 do
        test_passed = test_passed and DATA.realm_get_budget_to_be_invested(id, j) == 2
    end
    if not test_passed then print("budget.to_be_invested", 2, DATA.realm[id].budget[0].to_be_invested) end
    for j = 1, 7 do
        test_passed = test_passed and DATA.realm_get_budget_target(id, j) == 17
    end
    if not test_passed then print("budget.target", 17, DATA.realm[id].budget[0].target) end
    test_passed = test_passed and fat_id.budget_tax_target == -7
    if not test_passed then print("budget_tax_target", -7, fat_id.budget_tax_target) end
    test_passed = test_passed and fat_id.budget_tax_collected_this_year == 12
    if not test_passed then print("budget_tax_collected_this_year", 12, fat_id.budget_tax_collected_this_year) end
    test_passed = test_passed and fat_id.r == -12
    if not test_passed then print("r", -12, fat_id.r) end
    test_passed = test_passed and fat_id.g == -2
    if not test_passed then print("g", -2, fat_id.g) end
    test_passed = test_passed and fat_id.b == -12
    if not test_passed then print("b", -12, fat_id.b) end
    test_passed = test_passed and fat_id.primary_race == 3
    if not test_passed then print("primary_race", 3, fat_id.primary_race) end
    test_passed = test_passed and fat_id.capitol == 19
    if not test_passed then print("capitol", 19, fat_id.capitol) end
    test_passed = test_passed and fat_id.trading_right_cost == -4
    if not test_passed then print("trading_right_cost", -4, fat_id.trading_right_cost) end
    test_passed = test_passed and fat_id.building_right_cost == 14
    if not test_passed then print("building_right_cost", 14, fat_id.building_right_cost) end
    test_passed = test_passed and fat_id.law_trade == 1
    if not test_passed then print("law_trade", 1, fat_id.law_trade) end
    test_passed = test_passed and fat_id.law_building == 2
    if not test_passed then print("law_building", 2, fat_id.law_building) end
    test_passed = test_passed and fat_id.prepare_attack_flag == true
    if not test_passed then print("prepare_attack_flag", true, fat_id.prepare_attack_flag) end
    test_passed = test_passed and fat_id.coa_base_r == -16
    if not test_passed then print("coa_base_r", -16, fat_id.coa_base_r) end
    test_passed = test_passed and fat_id.coa_base_g == 1
    if not test_passed then print("coa_base_g", 1, fat_id.coa_base_g) end
    test_passed = test_passed and fat_id.coa_base_b == 10
    if not test_passed then print("coa_base_b", 10, fat_id.coa_base_b) end
    test_passed = test_passed and fat_id.coa_background_r == 15
    if not test_passed then print("coa_background_r", 15, fat_id.coa_background_r) end
    test_passed = test_passed and fat_id.coa_background_g == -14
    if not test_passed then print("coa_background_g", -14, fat_id.coa_background_g) end
    test_passed = test_passed and fat_id.coa_background_b == 2
    if not test_passed then print("coa_background_b", 2, fat_id.coa_background_b) end
    test_passed = test_passed and fat_id.coa_foreground_r == 7
    if not test_passed then print("coa_foreground_r", 7, fat_id.coa_foreground_r) end
    test_passed = test_passed and fat_id.coa_foreground_g == 0
    if not test_passed then print("coa_foreground_g", 0, fat_id.coa_foreground_g) end
    test_passed = test_passed and fat_id.coa_foreground_b == 19
    if not test_passed then print("coa_foreground_b", 19, fat_id.coa_foreground_b) end
    test_passed = test_passed and fat_id.coa_emblem_r == 20
    if not test_passed then print("coa_emblem_r", 20, fat_id.coa_emblem_r) end
    test_passed = test_passed and fat_id.coa_emblem_g == -7
    if not test_passed then print("coa_emblem_g", -7, fat_id.coa_emblem_g) end
    test_passed = test_passed and fat_id.coa_emblem_b == 15
    if not test_passed then print("coa_emblem_b", 15, fat_id.coa_emblem_b) end
    test_passed = test_passed and fat_id.coa_background_image == 15
    if not test_passed then print("coa_background_image", 15, fat_id.coa_background_image) end
    test_passed = test_passed and fat_id.coa_foreground_image == 14
    if not test_passed then print("coa_foreground_image", 14, fat_id.coa_foreground_image) end
    test_passed = test_passed and fat_id.coa_emblem_image == 16
    if not test_passed then print("coa_emblem_image", 16, fat_id.coa_emblem_image) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.realm_get_resources(id, j --[[@as trade_good_id]]) == -4
    end
    if not test_passed then print("resources", -4, DATA.realm[id].resources[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.realm_get_production(id, j --[[@as trade_good_id]]) == -17
    end
    if not test_passed then print("production", -17, DATA.realm[id].production[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.realm_get_bought(id, j --[[@as trade_good_id]]) == 15
    end
    if not test_passed then print("bought", 15, DATA.realm[id].bought[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.realm_get_sold(id, j --[[@as trade_good_id]]) == -20
    end
    if not test_passed then print("sold", -20, DATA.realm[id].sold[0]) end
    test_passed = test_passed and fat_id.expected_food_consumption == -15
    if not test_passed then print("expected_food_consumption", -15, fat_id.expected_food_consumption) end
    print("SET_GET_TEST_0_realm:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_building()
    local fat_id = DATA.fatten_building(id)
    fat_id.current_type = 12
    fat_id.savings = 6
    fat_id.subsidy = -18
    fat_id.subsidy_last = -4
    fat_id.income_mean = 12
    fat_id.last_income = 11
    fat_id.last_donation_to_owner = 5
    fat_id.unused = -1
    fat_id.work_ratio = 10
    fat_id.production_scale = 2
    for j = 1, 8 do
        DATA.building_set_spent_on_inputs_use(id, j, 18)
    end
    for j = 1, 8 do
        DATA.building_set_spent_on_inputs_amount(id, j, -7)
    end
    for j = 1, 8 do
        DATA.building_set_earn_from_outputs_good(id, j, 16)
    end
    for j = 1, 8 do
        DATA.building_set_earn_from_outputs_amount(id, j, -12)
    end
    for j = 1, 8 do
        DATA.building_set_amount_of_inputs_use(id, j, 9)
    end
    for j = 1, 8 do
        DATA.building_set_amount_of_inputs_amount(id, j, -12)
    end
    for j = 1, 8 do
        DATA.building_set_amount_of_outputs_good(id, j, 3)
    end
    for j = 1, 8 do
        DATA.building_set_amount_of_outputs_amount(id, j, 19)
    end
    for j = 1, 100 do
        DATA.building_set_inventory(id, j --[[@as trade_good_id]],  -4)    end
    local test_passed = true
    test_passed = test_passed and fat_id.current_type == 12
    if not test_passed then print("current_type", 12, fat_id.current_type) end
    test_passed = test_passed and fat_id.savings == 6
    if not test_passed then print("savings", 6, fat_id.savings) end
    test_passed = test_passed and fat_id.subsidy == -18
    if not test_passed then print("subsidy", -18, fat_id.subsidy) end
    test_passed = test_passed and fat_id.subsidy_last == -4
    if not test_passed then print("subsidy_last", -4, fat_id.subsidy_last) end
    test_passed = test_passed and fat_id.income_mean == 12
    if not test_passed then print("income_mean", 12, fat_id.income_mean) end
    test_passed = test_passed and fat_id.last_income == 11
    if not test_passed then print("last_income", 11, fat_id.last_income) end
    test_passed = test_passed and fat_id.last_donation_to_owner == 5
    if not test_passed then print("last_donation_to_owner", 5, fat_id.last_donation_to_owner) end
    test_passed = test_passed and fat_id.unused == -1
    if not test_passed then print("unused", -1, fat_id.unused) end
    test_passed = test_passed and fat_id.work_ratio == 10
    if not test_passed then print("work_ratio", 10, fat_id.work_ratio) end
    test_passed = test_passed and fat_id.production_scale == 2
    if not test_passed then print("production_scale", 2, fat_id.production_scale) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_spent_on_inputs_use(id, j) == 18
    end
    if not test_passed then print("spent_on_inputs.use", 18, DATA.building[id].spent_on_inputs[0].use) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_spent_on_inputs_amount(id, j) == -7
    end
    if not test_passed then print("spent_on_inputs.amount", -7, DATA.building[id].spent_on_inputs[0].amount) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_earn_from_outputs_good(id, j) == 16
    end
    if not test_passed then print("earn_from_outputs.good", 16, DATA.building[id].earn_from_outputs[0].good) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_earn_from_outputs_amount(id, j) == -12
    end
    if not test_passed then print("earn_from_outputs.amount", -12, DATA.building[id].earn_from_outputs[0].amount) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_amount_of_inputs_use(id, j) == 9
    end
    if not test_passed then print("amount_of_inputs.use", 9, DATA.building[id].amount_of_inputs[0].use) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_amount_of_inputs_amount(id, j) == -12
    end
    if not test_passed then print("amount_of_inputs.amount", -12, DATA.building[id].amount_of_inputs[0].amount) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_amount_of_outputs_good(id, j) == 3
    end
    if not test_passed then print("amount_of_outputs.good", 3, DATA.building[id].amount_of_outputs[0].good) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_amount_of_outputs_amount(id, j) == 19
    end
    if not test_passed then print("amount_of_outputs.amount", 19, DATA.building[id].amount_of_outputs[0].amount) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.building_get_inventory(id, j --[[@as trade_good_id]]) == -4
    end
    if not test_passed then print("inventory", -4, DATA.building[id].inventory[0]) end
    print("SET_GET_TEST_0_building:")
    if test_passed then print("PASSED") else print("ERROR") end
end
function DATA.test_set_get_1()
    local id = DATA.create_tile()
    local fat_id = DATA.fatten_tile(id)
    fat_id.world_id = 4
    fat_id.is_land = true
    fat_id.is_fresh = false
    fat_id.is_border = true
    fat_id.elevation = 11
    fat_id.slope = 8
    fat_id.grass = 10
    fat_id.shrub = 4
    fat_id.conifer = -7
    fat_id.broadleaf = -14
    fat_id.ideal_grass = 11
    fat_id.ideal_shrub = -19
    fat_id.ideal_conifer = 4
    fat_id.ideal_broadleaf = 7
    fat_id.silt = 18
    fat_id.clay = -20
    fat_id.sand = 8
    fat_id.soil_minerals = -3
    fat_id.soil_organics = -6
    fat_id.january_waterflow = 17
    fat_id.january_rain = -14
    fat_id.january_temperature = 0
    fat_id.july_waterflow = -19
    fat_id.july_rain = -19
    fat_id.july_temperature = -19
    fat_id.waterlevel = 14
    fat_id.has_river = true
    fat_id.has_marsh = false
    fat_id.ice = -7
    fat_id.ice_age_ice = 7
    fat_id.debug_r = -19
    fat_id.debug_g = 13
    fat_id.debug_b = -6
    fat_id.real_r = 8
    fat_id.real_g = 11
    fat_id.real_b = 15
    fat_id.pathfinding_index = 7
    fat_id.resource = 11
    fat_id.bedrock = 7
    fat_id.biome = 7
    local test_passed = true
    test_passed = test_passed and fat_id.world_id == 4
    if not test_passed then print("world_id", 4, fat_id.world_id) end
    test_passed = test_passed and fat_id.is_land == true
    if not test_passed then print("is_land", true, fat_id.is_land) end
    test_passed = test_passed and fat_id.is_fresh == false
    if not test_passed then print("is_fresh", false, fat_id.is_fresh) end
    test_passed = test_passed and fat_id.is_border == true
    if not test_passed then print("is_border", true, fat_id.is_border) end
    test_passed = test_passed and fat_id.elevation == 11
    if not test_passed then print("elevation", 11, fat_id.elevation) end
    test_passed = test_passed and fat_id.slope == 8
    if not test_passed then print("slope", 8, fat_id.slope) end
    test_passed = test_passed and fat_id.grass == 10
    if not test_passed then print("grass", 10, fat_id.grass) end
    test_passed = test_passed and fat_id.shrub == 4
    if not test_passed then print("shrub", 4, fat_id.shrub) end
    test_passed = test_passed and fat_id.conifer == -7
    if not test_passed then print("conifer", -7, fat_id.conifer) end
    test_passed = test_passed and fat_id.broadleaf == -14
    if not test_passed then print("broadleaf", -14, fat_id.broadleaf) end
    test_passed = test_passed and fat_id.ideal_grass == 11
    if not test_passed then print("ideal_grass", 11, fat_id.ideal_grass) end
    test_passed = test_passed and fat_id.ideal_shrub == -19
    if not test_passed then print("ideal_shrub", -19, fat_id.ideal_shrub) end
    test_passed = test_passed and fat_id.ideal_conifer == 4
    if not test_passed then print("ideal_conifer", 4, fat_id.ideal_conifer) end
    test_passed = test_passed and fat_id.ideal_broadleaf == 7
    if not test_passed then print("ideal_broadleaf", 7, fat_id.ideal_broadleaf) end
    test_passed = test_passed and fat_id.silt == 18
    if not test_passed then print("silt", 18, fat_id.silt) end
    test_passed = test_passed and fat_id.clay == -20
    if not test_passed then print("clay", -20, fat_id.clay) end
    test_passed = test_passed and fat_id.sand == 8
    if not test_passed then print("sand", 8, fat_id.sand) end
    test_passed = test_passed and fat_id.soil_minerals == -3
    if not test_passed then print("soil_minerals", -3, fat_id.soil_minerals) end
    test_passed = test_passed and fat_id.soil_organics == -6
    if not test_passed then print("soil_organics", -6, fat_id.soil_organics) end
    test_passed = test_passed and fat_id.january_waterflow == 17
    if not test_passed then print("january_waterflow", 17, fat_id.january_waterflow) end
    test_passed = test_passed and fat_id.january_rain == -14
    if not test_passed then print("january_rain", -14, fat_id.january_rain) end
    test_passed = test_passed and fat_id.january_temperature == 0
    if not test_passed then print("january_temperature", 0, fat_id.january_temperature) end
    test_passed = test_passed and fat_id.july_waterflow == -19
    if not test_passed then print("july_waterflow", -19, fat_id.july_waterflow) end
    test_passed = test_passed and fat_id.july_rain == -19
    if not test_passed then print("july_rain", -19, fat_id.july_rain) end
    test_passed = test_passed and fat_id.july_temperature == -19
    if not test_passed then print("july_temperature", -19, fat_id.july_temperature) end
    test_passed = test_passed and fat_id.waterlevel == 14
    if not test_passed then print("waterlevel", 14, fat_id.waterlevel) end
    test_passed = test_passed and fat_id.has_river == true
    if not test_passed then print("has_river", true, fat_id.has_river) end
    test_passed = test_passed and fat_id.has_marsh == false
    if not test_passed then print("has_marsh", false, fat_id.has_marsh) end
    test_passed = test_passed and fat_id.ice == -7
    if not test_passed then print("ice", -7, fat_id.ice) end
    test_passed = test_passed and fat_id.ice_age_ice == 7
    if not test_passed then print("ice_age_ice", 7, fat_id.ice_age_ice) end
    test_passed = test_passed and fat_id.debug_r == -19
    if not test_passed then print("debug_r", -19, fat_id.debug_r) end
    test_passed = test_passed and fat_id.debug_g == 13
    if not test_passed then print("debug_g", 13, fat_id.debug_g) end
    test_passed = test_passed and fat_id.debug_b == -6
    if not test_passed then print("debug_b", -6, fat_id.debug_b) end
    test_passed = test_passed and fat_id.real_r == 8
    if not test_passed then print("real_r", 8, fat_id.real_r) end
    test_passed = test_passed and fat_id.real_g == 11
    if not test_passed then print("real_g", 11, fat_id.real_g) end
    test_passed = test_passed and fat_id.real_b == 15
    if not test_passed then print("real_b", 15, fat_id.real_b) end
    test_passed = test_passed and fat_id.pathfinding_index == 7
    if not test_passed then print("pathfinding_index", 7, fat_id.pathfinding_index) end
    test_passed = test_passed and fat_id.resource == 11
    if not test_passed then print("resource", 11, fat_id.resource) end
    test_passed = test_passed and fat_id.bedrock == 7
    if not test_passed then print("bedrock", 7, fat_id.bedrock) end
    test_passed = test_passed and fat_id.biome == 7
    if not test_passed then print("biome", 7, fat_id.biome) end
    print("SET_GET_TEST_1_tile:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_pop()
    local fat_id = DATA.fatten_pop(id)
    fat_id.race = 4
    fat_id.female = true
    fat_id.age = 8
    fat_id.savings = -13
    fat_id.life_needs_satisfaction = 11
    fat_id.basic_needs_satisfaction = 8
    for j = 1, 20 do
        DATA.pop_set_need_satisfaction_need(id, j, 7)
    end
    for j = 1, 20 do
        DATA.pop_set_need_satisfaction_use_case(id, j, 20)
    end
    for j = 1, 20 do
        DATA.pop_set_need_satisfaction_consumed(id, j, 4)
    end
    for j = 1, 20 do
        DATA.pop_set_need_satisfaction_demanded(id, j, -7)
    end
    for j = 1, 10 do
        DATA.pop_set_traits(id, j --[[@as number]],  1)    end
    for j = 1, 100 do
        DATA.pop_set_inventory(id, j --[[@as trade_good_id]],  11)    end
    for j = 1, 100 do
        DATA.pop_set_price_memory(id, j --[[@as trade_good_id]],  -19)    end
    fat_id.pending_economy_income = 4
    fat_id.forage_ratio = 7
    fat_id.work_ratio = 18
    fat_id.rank = 0
    for j = 1, 20 do
        DATA.pop_set_dna(id, j --[[@as number]],  8)    end
    local test_passed = true
    test_passed = test_passed and fat_id.race == 4
    if not test_passed then print("race", 4, fat_id.race) end
    test_passed = test_passed and fat_id.female == true
    if not test_passed then print("female", true, fat_id.female) end
    test_passed = test_passed and fat_id.age == 8
    if not test_passed then print("age", 8, fat_id.age) end
    test_passed = test_passed and fat_id.savings == -13
    if not test_passed then print("savings", -13, fat_id.savings) end
    test_passed = test_passed and fat_id.life_needs_satisfaction == 11
    if not test_passed then print("life_needs_satisfaction", 11, fat_id.life_needs_satisfaction) end
    test_passed = test_passed and fat_id.basic_needs_satisfaction == 8
    if not test_passed then print("basic_needs_satisfaction", 8, fat_id.basic_needs_satisfaction) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_need_satisfaction_need(id, j) == 7
    end
    if not test_passed then print("need_satisfaction.need", 7, DATA.pop[id].need_satisfaction[0].need) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_need_satisfaction_use_case(id, j) == 20
    end
    if not test_passed then print("need_satisfaction.use_case", 20, DATA.pop[id].need_satisfaction[0].use_case) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_need_satisfaction_consumed(id, j) == 4
    end
    if not test_passed then print("need_satisfaction.consumed", 4, DATA.pop[id].need_satisfaction[0].consumed) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_need_satisfaction_demanded(id, j) == -7
    end
    if not test_passed then print("need_satisfaction.demanded", -7, DATA.pop[id].need_satisfaction[0].demanded) end
    for j = 1, 10 do
        test_passed = test_passed and DATA.pop_get_traits(id, j --[[@as number]]) == 1
    end
    if not test_passed then print("traits", 1, DATA.pop[id].traits[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.pop_get_inventory(id, j --[[@as trade_good_id]]) == 11
    end
    if not test_passed then print("inventory", 11, DATA.pop[id].inventory[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.pop_get_price_memory(id, j --[[@as trade_good_id]]) == -19
    end
    if not test_passed then print("price_memory", -19, DATA.pop[id].price_memory[0]) end
    test_passed = test_passed and fat_id.pending_economy_income == 4
    if not test_passed then print("pending_economy_income", 4, fat_id.pending_economy_income) end
    test_passed = test_passed and fat_id.forage_ratio == 7
    if not test_passed then print("forage_ratio", 7, fat_id.forage_ratio) end
    test_passed = test_passed and fat_id.work_ratio == 18
    if not test_passed then print("work_ratio", 18, fat_id.work_ratio) end
    test_passed = test_passed and fat_id.rank == 0
    if not test_passed then print("rank", 0, fat_id.rank) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_dna(id, j --[[@as number]]) == 8
    end
    if not test_passed then print("dna", 8, DATA.pop[id].dna[0]) end
    print("SET_GET_TEST_1_pop:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_province()
    local fat_id = DATA.fatten_province(id)
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
    fat_id.infrastructure_efficiency = 11
    for j = 1, 400 do
        DATA.province_set_technologies_present(id, j --[[@as technology_id]],  0)    end
    for j = 1, 400 do
        DATA.province_set_technologies_researchable(id, j --[[@as technology_id]],  12)    end
    for j = 1, 250 do
        DATA.province_set_buildable_buildings(id, j --[[@as building_type_id]],  13)    end
    for j = 1, 100 do
        DATA.province_set_local_production(id, j --[[@as trade_good_id]],  18)    end
    for j = 1, 100 do
        DATA.province_set_temp_buffer_0(id, j --[[@as trade_good_id]],  -20)    end
    for j = 1, 100 do
        DATA.province_set_local_consumption(id, j --[[@as trade_good_id]],  8)    end
    for j = 1, 100 do
        DATA.province_set_local_demand(id, j --[[@as trade_good_id]],  -3)    end
    for j = 1, 100 do
        DATA.province_set_local_satisfaction(id, j --[[@as trade_good_id]],  -6)    end
    for j = 1, 100 do
        DATA.province_set_temp_buffer_use_0(id, j --[[@as use_case_id]],  17)    end
    for j = 1, 100 do
        DATA.province_set_temp_buffer_use_grad(id, j --[[@as use_case_id]],  -14)    end
    for j = 1, 100 do
        DATA.province_set_local_use_satisfaction(id, j --[[@as use_case_id]],  0)    end
    for j = 1, 100 do
        DATA.province_set_local_use_buffer_demand(id, j --[[@as use_case_id]],  -19)    end
    for j = 1, 100 do
        DATA.province_set_local_use_buffer_supply(id, j --[[@as use_case_id]],  -19)    end
    for j = 1, 100 do
        DATA.province_set_local_use_buffer_cost(id, j --[[@as use_case_id]],  -19)    end
    for j = 1, 100 do
        DATA.province_set_local_storage(id, j --[[@as trade_good_id]],  14)    end
    for j = 1, 100 do
        DATA.province_set_local_prices(id, j --[[@as trade_good_id]],  -20)    end
    fat_id.local_wealth = 4
    fat_id.trade_wealth = -7
    fat_id.local_income = 7
    fat_id.local_building_upkeep = -19
    fat_id.foragers = 13
    fat_id.foragers_water = -6
    fat_id.foragers_limit = 8
    for j = 1, 25 do
        DATA.province_set_foragers_targets_output_good(id, j, 15)
    end
    for j = 1, 25 do
        DATA.province_set_foragers_targets_output_value(id, j, 15)
    end
    for j = 1, 25 do
        DATA.province_set_foragers_targets_amount(id, j, -6)
    end
    for j = 1, 25 do
        DATA.province_set_foragers_targets_forage(id, j, 5)
    end
    for j = 1, 25 do
        DATA.province_set_local_resources_resource(id, j, 7)
    end
    for j = 1, 25 do
        DATA.province_set_local_resources_location(id, j, 7)
    end
    fat_id.mood = 9
    for j = 1, 20 do
        DATA.province_set_unit_types(id, j --[[@as unit_type_id]],  9)    end
    for j = 1, 250 do
        DATA.province_set_throughput_boosts(id, j --[[@as production_method_id]],  -19)    end
    for j = 1, 250 do
        DATA.province_set_input_efficiency_boosts(id, j --[[@as production_method_id]],  6)    end
    for j = 1, 250 do
        DATA.province_set_output_efficiency_boosts(id, j --[[@as production_method_id]],  15)    end
    fat_id.on_a_river = true
    fat_id.on_a_forest = true
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
    test_passed = test_passed and fat_id.infrastructure_efficiency == 11
    if not test_passed then print("infrastructure_efficiency", 11, fat_id.infrastructure_efficiency) end
    for j = 1, 400 do
        test_passed = test_passed and DATA.province_get_technologies_present(id, j --[[@as technology_id]]) == 0
    end
    if not test_passed then print("technologies_present", 0, DATA.province[id].technologies_present[0]) end
    for j = 1, 400 do
        test_passed = test_passed and DATA.province_get_technologies_researchable(id, j --[[@as technology_id]]) == 12
    end
    if not test_passed then print("technologies_researchable", 12, DATA.province[id].technologies_researchable[0]) end
    for j = 1, 250 do
        test_passed = test_passed and DATA.province_get_buildable_buildings(id, j --[[@as building_type_id]]) == 13
    end
    if not test_passed then print("buildable_buildings", 13, DATA.province[id].buildable_buildings[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_production(id, j --[[@as trade_good_id]]) == 18
    end
    if not test_passed then print("local_production", 18, DATA.province[id].local_production[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_temp_buffer_0(id, j --[[@as trade_good_id]]) == -20
    end
    if not test_passed then print("temp_buffer_0", -20, DATA.province[id].temp_buffer_0[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_consumption(id, j --[[@as trade_good_id]]) == 8
    end
    if not test_passed then print("local_consumption", 8, DATA.province[id].local_consumption[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_demand(id, j --[[@as trade_good_id]]) == -3
    end
    if not test_passed then print("local_demand", -3, DATA.province[id].local_demand[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_satisfaction(id, j --[[@as trade_good_id]]) == -6
    end
    if not test_passed then print("local_satisfaction", -6, DATA.province[id].local_satisfaction[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_temp_buffer_use_0(id, j --[[@as use_case_id]]) == 17
    end
    if not test_passed then print("temp_buffer_use_0", 17, DATA.province[id].temp_buffer_use_0[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_temp_buffer_use_grad(id, j --[[@as use_case_id]]) == -14
    end
    if not test_passed then print("temp_buffer_use_grad", -14, DATA.province[id].temp_buffer_use_grad[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_use_satisfaction(id, j --[[@as use_case_id]]) == 0
    end
    if not test_passed then print("local_use_satisfaction", 0, DATA.province[id].local_use_satisfaction[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_use_buffer_demand(id, j --[[@as use_case_id]]) == -19
    end
    if not test_passed then print("local_use_buffer_demand", -19, DATA.province[id].local_use_buffer_demand[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_use_buffer_supply(id, j --[[@as use_case_id]]) == -19
    end
    if not test_passed then print("local_use_buffer_supply", -19, DATA.province[id].local_use_buffer_supply[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_use_buffer_cost(id, j --[[@as use_case_id]]) == -19
    end
    if not test_passed then print("local_use_buffer_cost", -19, DATA.province[id].local_use_buffer_cost[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_storage(id, j --[[@as trade_good_id]]) == 14
    end
    if not test_passed then print("local_storage", 14, DATA.province[id].local_storage[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_prices(id, j --[[@as trade_good_id]]) == -20
    end
    if not test_passed then print("local_prices", -20, DATA.province[id].local_prices[0]) end
    test_passed = test_passed and fat_id.local_wealth == 4
    if not test_passed then print("local_wealth", 4, fat_id.local_wealth) end
    test_passed = test_passed and fat_id.trade_wealth == -7
    if not test_passed then print("trade_wealth", -7, fat_id.trade_wealth) end
    test_passed = test_passed and fat_id.local_income == 7
    if not test_passed then print("local_income", 7, fat_id.local_income) end
    test_passed = test_passed and fat_id.local_building_upkeep == -19
    if not test_passed then print("local_building_upkeep", -19, fat_id.local_building_upkeep) end
    test_passed = test_passed and fat_id.foragers == 13
    if not test_passed then print("foragers", 13, fat_id.foragers) end
    test_passed = test_passed and fat_id.foragers_water == -6
    if not test_passed then print("foragers_water", -6, fat_id.foragers_water) end
    test_passed = test_passed and fat_id.foragers_limit == 8
    if not test_passed then print("foragers_limit", 8, fat_id.foragers_limit) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_foragers_targets_output_good(id, j) == 15
    end
    if not test_passed then print("foragers_targets.output_good", 15, DATA.province[id].foragers_targets[0].output_good) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_foragers_targets_output_value(id, j) == 15
    end
    if not test_passed then print("foragers_targets.output_value", 15, DATA.province[id].foragers_targets[0].output_value) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_foragers_targets_amount(id, j) == -6
    end
    if not test_passed then print("foragers_targets.amount", -6, DATA.province[id].foragers_targets[0].amount) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_foragers_targets_forage(id, j) == 5
    end
    if not test_passed then print("foragers_targets.forage", 5, DATA.province[id].foragers_targets[0].forage) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_local_resources_resource(id, j) == 7
    end
    if not test_passed then print("local_resources.resource", 7, DATA.province[id].local_resources[0].resource) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_local_resources_location(id, j) == 7
    end
    if not test_passed then print("local_resources.location", 7, DATA.province[id].local_resources[0].location) end
    test_passed = test_passed and fat_id.mood == 9
    if not test_passed then print("mood", 9, fat_id.mood) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.province_get_unit_types(id, j --[[@as unit_type_id]]) == 9
    end
    if not test_passed then print("unit_types", 9, DATA.province[id].unit_types[0]) end
    for j = 1, 250 do
        test_passed = test_passed and DATA.province_get_throughput_boosts(id, j --[[@as production_method_id]]) == -19
    end
    if not test_passed then print("throughput_boosts", -19, DATA.province[id].throughput_boosts[0]) end
    for j = 1, 250 do
        test_passed = test_passed and DATA.province_get_input_efficiency_boosts(id, j --[[@as production_method_id]]) == 6
    end
    if not test_passed then print("input_efficiency_boosts", 6, DATA.province[id].input_efficiency_boosts[0]) end
    for j = 1, 250 do
        test_passed = test_passed and DATA.province_get_output_efficiency_boosts(id, j --[[@as production_method_id]]) == 15
    end
    if not test_passed then print("output_efficiency_boosts", 15, DATA.province[id].output_efficiency_boosts[0]) end
    test_passed = test_passed and fat_id.on_a_river == true
    if not test_passed then print("on_a_river", true, fat_id.on_a_river) end
    test_passed = test_passed and fat_id.on_a_forest == true
    if not test_passed then print("on_a_forest", true, fat_id.on_a_forest) end
    print("SET_GET_TEST_1_province:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_army()
    local fat_id = DATA.fatten_army(id)
    fat_id.destination = 4
    local test_passed = true
    test_passed = test_passed and fat_id.destination == 4
    if not test_passed then print("destination", 4, fat_id.destination) end
    print("SET_GET_TEST_1_army:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_warband()
    local fat_id = DATA.fatten_warband(id)
    for j = 1, 20 do
        DATA.warband_set_units_current(id, j --[[@as unit_type_id]],  -12)    end
    for j = 1, 20 do
        DATA.warband_set_units_target(id, j --[[@as unit_type_id]],  16)    end
    fat_id.current_status = 1
    fat_id.idle_stance = 1
    fat_id.current_free_time_ratio = -13
    fat_id.treasury = 11
    fat_id.total_upkeep = 8
    fat_id.predicted_upkeep = 10
    fat_id.supplies = 4
    fat_id.supplies_target_days = -7
    fat_id.morale = -14
    local test_passed = true
    for j = 1, 20 do
        test_passed = test_passed and DATA.warband_get_units_current(id, j --[[@as unit_type_id]]) == -12
    end
    if not test_passed then print("units_current", -12, DATA.warband[id].units_current[0]) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.warband_get_units_target(id, j --[[@as unit_type_id]]) == 16
    end
    if not test_passed then print("units_target", 16, DATA.warband[id].units_target[0]) end
    test_passed = test_passed and fat_id.current_status == 1
    if not test_passed then print("current_status", 1, fat_id.current_status) end
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
    local id = DATA.create_realm()
    local fat_id = DATA.fatten_realm(id)
    fat_id.budget_change = -12
    fat_id.budget_saved_change = 16
    for j = 1, 38 do
        DATA.realm_set_budget_spending_by_category(id, j --[[@as ECONOMY_REASON]],  -16)    end
    for j = 1, 38 do
        DATA.realm_set_budget_income_by_category(id, j --[[@as ECONOMY_REASON]],  -4)    end
    for j = 1, 38 do
        DATA.realm_set_budget_treasury_change_by_category(id, j --[[@as ECONOMY_REASON]],  -13)    end
    fat_id.budget_treasury = 11
    fat_id.budget_treasury_target = 8
    for j = 1, 7 do
        DATA.realm_set_budget_ratio(id, j, 10)
    end
    for j = 1, 7 do
        DATA.realm_set_budget_budget(id, j, 4)
    end
    for j = 1, 7 do
        DATA.realm_set_budget_to_be_invested(id, j, -7)
    end
    for j = 1, 7 do
        DATA.realm_set_budget_target(id, j, -14)
    end
    fat_id.budget_tax_target = 11
    fat_id.budget_tax_collected_this_year = -19
    fat_id.r = 4
    fat_id.g = 7
    fat_id.b = 18
    fat_id.primary_race = 0
    fat_id.capitol = 14
    fat_id.trading_right_cost = -3
    fat_id.building_right_cost = -6
    fat_id.law_trade = 0
    fat_id.law_building = 2
    fat_id.prepare_attack_flag = true
    fat_id.coa_base_r = -19
    fat_id.coa_base_g = -19
    fat_id.coa_base_b = 14
    fat_id.coa_background_r = -20
    fat_id.coa_background_g = 4
    fat_id.coa_background_b = -7
    fat_id.coa_foreground_r = 7
    fat_id.coa_foreground_g = -19
    fat_id.coa_foreground_b = 13
    fat_id.coa_emblem_r = -6
    fat_id.coa_emblem_g = 8
    fat_id.coa_emblem_b = 11
    fat_id.coa_background_image = 17
    fat_id.coa_foreground_image = 7
    fat_id.coa_emblem_image = 11
    for j = 1, 100 do
        DATA.realm_set_resources(id, j --[[@as trade_good_id]],  -6)    end
    for j = 1, 100 do
        DATA.realm_set_production(id, j --[[@as trade_good_id]],  -6)    end
    for j = 1, 100 do
        DATA.realm_set_bought(id, j --[[@as trade_good_id]],  9)    end
    for j = 1, 100 do
        DATA.realm_set_sold(id, j --[[@as trade_good_id]],  -2)    end
    fat_id.expected_food_consumption = -19
    local test_passed = true
    test_passed = test_passed and fat_id.budget_change == -12
    if not test_passed then print("budget_change", -12, fat_id.budget_change) end
    test_passed = test_passed and fat_id.budget_saved_change == 16
    if not test_passed then print("budget_saved_change", 16, fat_id.budget_saved_change) end
    for j = 1, 38 do
        test_passed = test_passed and DATA.realm_get_budget_spending_by_category(id, j --[[@as ECONOMY_REASON]]) == -16
    end
    if not test_passed then print("budget_spending_by_category", -16, DATA.realm[id].budget_spending_by_category[0]) end
    for j = 1, 38 do
        test_passed = test_passed and DATA.realm_get_budget_income_by_category(id, j --[[@as ECONOMY_REASON]]) == -4
    end
    if not test_passed then print("budget_income_by_category", -4, DATA.realm[id].budget_income_by_category[0]) end
    for j = 1, 38 do
        test_passed = test_passed and DATA.realm_get_budget_treasury_change_by_category(id, j --[[@as ECONOMY_REASON]]) == -13
    end
    if not test_passed then print("budget_treasury_change_by_category", -13, DATA.realm[id].budget_treasury_change_by_category[0]) end
    test_passed = test_passed and fat_id.budget_treasury == 11
    if not test_passed then print("budget_treasury", 11, fat_id.budget_treasury) end
    test_passed = test_passed and fat_id.budget_treasury_target == 8
    if not test_passed then print("budget_treasury_target", 8, fat_id.budget_treasury_target) end
    for j = 1, 7 do
        test_passed = test_passed and DATA.realm_get_budget_ratio(id, j) == 10
    end
    if not test_passed then print("budget.ratio", 10, DATA.realm[id].budget[0].ratio) end
    for j = 1, 7 do
        test_passed = test_passed and DATA.realm_get_budget_budget(id, j) == 4
    end
    if not test_passed then print("budget.budget", 4, DATA.realm[id].budget[0].budget) end
    for j = 1, 7 do
        test_passed = test_passed and DATA.realm_get_budget_to_be_invested(id, j) == -7
    end
    if not test_passed then print("budget.to_be_invested", -7, DATA.realm[id].budget[0].to_be_invested) end
    for j = 1, 7 do
        test_passed = test_passed and DATA.realm_get_budget_target(id, j) == -14
    end
    if not test_passed then print("budget.target", -14, DATA.realm[id].budget[0].target) end
    test_passed = test_passed and fat_id.budget_tax_target == 11
    if not test_passed then print("budget_tax_target", 11, fat_id.budget_tax_target) end
    test_passed = test_passed and fat_id.budget_tax_collected_this_year == -19
    if not test_passed then print("budget_tax_collected_this_year", -19, fat_id.budget_tax_collected_this_year) end
    test_passed = test_passed and fat_id.r == 4
    if not test_passed then print("r", 4, fat_id.r) end
    test_passed = test_passed and fat_id.g == 7
    if not test_passed then print("g", 7, fat_id.g) end
    test_passed = test_passed and fat_id.b == 18
    if not test_passed then print("b", 18, fat_id.b) end
    test_passed = test_passed and fat_id.primary_race == 0
    if not test_passed then print("primary_race", 0, fat_id.primary_race) end
    test_passed = test_passed and fat_id.capitol == 14
    if not test_passed then print("capitol", 14, fat_id.capitol) end
    test_passed = test_passed and fat_id.trading_right_cost == -3
    if not test_passed then print("trading_right_cost", -3, fat_id.trading_right_cost) end
    test_passed = test_passed and fat_id.building_right_cost == -6
    if not test_passed then print("building_right_cost", -6, fat_id.building_right_cost) end
    test_passed = test_passed and fat_id.law_trade == 0
    if not test_passed then print("law_trade", 0, fat_id.law_trade) end
    test_passed = test_passed and fat_id.law_building == 2
    if not test_passed then print("law_building", 2, fat_id.law_building) end
    test_passed = test_passed and fat_id.prepare_attack_flag == true
    if not test_passed then print("prepare_attack_flag", true, fat_id.prepare_attack_flag) end
    test_passed = test_passed and fat_id.coa_base_r == -19
    if not test_passed then print("coa_base_r", -19, fat_id.coa_base_r) end
    test_passed = test_passed and fat_id.coa_base_g == -19
    if not test_passed then print("coa_base_g", -19, fat_id.coa_base_g) end
    test_passed = test_passed and fat_id.coa_base_b == 14
    if not test_passed then print("coa_base_b", 14, fat_id.coa_base_b) end
    test_passed = test_passed and fat_id.coa_background_r == -20
    if not test_passed then print("coa_background_r", -20, fat_id.coa_background_r) end
    test_passed = test_passed and fat_id.coa_background_g == 4
    if not test_passed then print("coa_background_g", 4, fat_id.coa_background_g) end
    test_passed = test_passed and fat_id.coa_background_b == -7
    if not test_passed then print("coa_background_b", -7, fat_id.coa_background_b) end
    test_passed = test_passed and fat_id.coa_foreground_r == 7
    if not test_passed then print("coa_foreground_r", 7, fat_id.coa_foreground_r) end
    test_passed = test_passed and fat_id.coa_foreground_g == -19
    if not test_passed then print("coa_foreground_g", -19, fat_id.coa_foreground_g) end
    test_passed = test_passed and fat_id.coa_foreground_b == 13
    if not test_passed then print("coa_foreground_b", 13, fat_id.coa_foreground_b) end
    test_passed = test_passed and fat_id.coa_emblem_r == -6
    if not test_passed then print("coa_emblem_r", -6, fat_id.coa_emblem_r) end
    test_passed = test_passed and fat_id.coa_emblem_g == 8
    if not test_passed then print("coa_emblem_g", 8, fat_id.coa_emblem_g) end
    test_passed = test_passed and fat_id.coa_emblem_b == 11
    if not test_passed then print("coa_emblem_b", 11, fat_id.coa_emblem_b) end
    test_passed = test_passed and fat_id.coa_background_image == 17
    if not test_passed then print("coa_background_image", 17, fat_id.coa_background_image) end
    test_passed = test_passed and fat_id.coa_foreground_image == 7
    if not test_passed then print("coa_foreground_image", 7, fat_id.coa_foreground_image) end
    test_passed = test_passed and fat_id.coa_emblem_image == 11
    if not test_passed then print("coa_emblem_image", 11, fat_id.coa_emblem_image) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.realm_get_resources(id, j --[[@as trade_good_id]]) == -6
    end
    if not test_passed then print("resources", -6, DATA.realm[id].resources[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.realm_get_production(id, j --[[@as trade_good_id]]) == -6
    end
    if not test_passed then print("production", -6, DATA.realm[id].production[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.realm_get_bought(id, j --[[@as trade_good_id]]) == 9
    end
    if not test_passed then print("bought", 9, DATA.realm[id].bought[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.realm_get_sold(id, j --[[@as trade_good_id]]) == -2
    end
    if not test_passed then print("sold", -2, DATA.realm[id].sold[0]) end
    test_passed = test_passed and fat_id.expected_food_consumption == -19
    if not test_passed then print("expected_food_consumption", -19, fat_id.expected_food_consumption) end
    print("SET_GET_TEST_1_realm:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_building()
    local fat_id = DATA.fatten_building(id)
    fat_id.current_type = 4
    fat_id.savings = 16
    fat_id.subsidy = -16
    fat_id.subsidy_last = -4
    fat_id.income_mean = -13
    fat_id.last_income = 11
    fat_id.last_donation_to_owner = 8
    fat_id.unused = 10
    fat_id.work_ratio = 4
    fat_id.production_scale = -7
    for j = 1, 8 do
        DATA.building_set_spent_on_inputs_use(id, j, 3)
    end
    for j = 1, 8 do
        DATA.building_set_spent_on_inputs_amount(id, j, 11)
    end
    for j = 1, 8 do
        DATA.building_set_earn_from_outputs_good(id, j, 0)
    end
    for j = 1, 8 do
        DATA.building_set_earn_from_outputs_amount(id, j, 4)
    end
    for j = 1, 8 do
        DATA.building_set_amount_of_inputs_use(id, j, 13)
    end
    for j = 1, 8 do
        DATA.building_set_amount_of_inputs_amount(id, j, 18)
    end
    for j = 1, 8 do
        DATA.building_set_amount_of_outputs_good(id, j, 0)
    end
    for j = 1, 8 do
        DATA.building_set_amount_of_outputs_amount(id, j, 8)
    end
    for j = 1, 100 do
        DATA.building_set_inventory(id, j --[[@as trade_good_id]],  -3)    end
    local test_passed = true
    test_passed = test_passed and fat_id.current_type == 4
    if not test_passed then print("current_type", 4, fat_id.current_type) end
    test_passed = test_passed and fat_id.savings == 16
    if not test_passed then print("savings", 16, fat_id.savings) end
    test_passed = test_passed and fat_id.subsidy == -16
    if not test_passed then print("subsidy", -16, fat_id.subsidy) end
    test_passed = test_passed and fat_id.subsidy_last == -4
    if not test_passed then print("subsidy_last", -4, fat_id.subsidy_last) end
    test_passed = test_passed and fat_id.income_mean == -13
    if not test_passed then print("income_mean", -13, fat_id.income_mean) end
    test_passed = test_passed and fat_id.last_income == 11
    if not test_passed then print("last_income", 11, fat_id.last_income) end
    test_passed = test_passed and fat_id.last_donation_to_owner == 8
    if not test_passed then print("last_donation_to_owner", 8, fat_id.last_donation_to_owner) end
    test_passed = test_passed and fat_id.unused == 10
    if not test_passed then print("unused", 10, fat_id.unused) end
    test_passed = test_passed and fat_id.work_ratio == 4
    if not test_passed then print("work_ratio", 4, fat_id.work_ratio) end
    test_passed = test_passed and fat_id.production_scale == -7
    if not test_passed then print("production_scale", -7, fat_id.production_scale) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_spent_on_inputs_use(id, j) == 3
    end
    if not test_passed then print("spent_on_inputs.use", 3, DATA.building[id].spent_on_inputs[0].use) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_spent_on_inputs_amount(id, j) == 11
    end
    if not test_passed then print("spent_on_inputs.amount", 11, DATA.building[id].spent_on_inputs[0].amount) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_earn_from_outputs_good(id, j) == 0
    end
    if not test_passed then print("earn_from_outputs.good", 0, DATA.building[id].earn_from_outputs[0].good) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_earn_from_outputs_amount(id, j) == 4
    end
    if not test_passed then print("earn_from_outputs.amount", 4, DATA.building[id].earn_from_outputs[0].amount) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_amount_of_inputs_use(id, j) == 13
    end
    if not test_passed then print("amount_of_inputs.use", 13, DATA.building[id].amount_of_inputs[0].use) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_amount_of_inputs_amount(id, j) == 18
    end
    if not test_passed then print("amount_of_inputs.amount", 18, DATA.building[id].amount_of_inputs[0].amount) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_amount_of_outputs_good(id, j) == 0
    end
    if not test_passed then print("amount_of_outputs.good", 0, DATA.building[id].amount_of_outputs[0].good) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_amount_of_outputs_amount(id, j) == 8
    end
    if not test_passed then print("amount_of_outputs.amount", 8, DATA.building[id].amount_of_outputs[0].amount) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.building_get_inventory(id, j --[[@as trade_good_id]]) == -3
    end
    if not test_passed then print("inventory", -3, DATA.building[id].inventory[0]) end
    print("SET_GET_TEST_1_building:")
    if test_passed then print("PASSED") else print("ERROR") end
end
function DATA.test_set_get_2()
    local id = DATA.create_tile()
    local fat_id = DATA.fatten_tile(id)
    fat_id.world_id = 1
    fat_id.is_land = true
    fat_id.is_fresh = true
    fat_id.is_border = false
    fat_id.elevation = -10
    fat_id.slope = -1
    fat_id.grass = -4
    fat_id.shrub = 18
    fat_id.conifer = -7
    fat_id.broadleaf = 18
    fat_id.ideal_grass = -18
    fat_id.ideal_shrub = 17
    fat_id.ideal_conifer = -10
    fat_id.ideal_broadleaf = 7
    fat_id.silt = 20
    fat_id.clay = 5
    fat_id.sand = 12
    fat_id.soil_minerals = 3
    fat_id.soil_organics = 14
    fat_id.january_waterflow = 8
    fat_id.january_rain = 12
    fat_id.january_temperature = -3
    fat_id.july_waterflow = -18
    fat_id.july_rain = -19
    fat_id.july_temperature = 3
    fat_id.waterlevel = 9
    fat_id.has_river = false
    fat_id.has_marsh = false
    fat_id.ice = 7
    fat_id.ice_age_ice = 13
    fat_id.debug_r = -10
    fat_id.debug_g = 15
    fat_id.debug_b = -9
    fat_id.real_r = -5
    fat_id.real_g = -6
    fat_id.real_b = -19
    fat_id.pathfinding_index = 5
    fat_id.resource = 10
    fat_id.bedrock = 5
    fat_id.biome = 4
    local test_passed = true
    test_passed = test_passed and fat_id.world_id == 1
    if not test_passed then print("world_id", 1, fat_id.world_id) end
    test_passed = test_passed and fat_id.is_land == true
    if not test_passed then print("is_land", true, fat_id.is_land) end
    test_passed = test_passed and fat_id.is_fresh == true
    if not test_passed then print("is_fresh", true, fat_id.is_fresh) end
    test_passed = test_passed and fat_id.is_border == false
    if not test_passed then print("is_border", false, fat_id.is_border) end
    test_passed = test_passed and fat_id.elevation == -10
    if not test_passed then print("elevation", -10, fat_id.elevation) end
    test_passed = test_passed and fat_id.slope == -1
    if not test_passed then print("slope", -1, fat_id.slope) end
    test_passed = test_passed and fat_id.grass == -4
    if not test_passed then print("grass", -4, fat_id.grass) end
    test_passed = test_passed and fat_id.shrub == 18
    if not test_passed then print("shrub", 18, fat_id.shrub) end
    test_passed = test_passed and fat_id.conifer == -7
    if not test_passed then print("conifer", -7, fat_id.conifer) end
    test_passed = test_passed and fat_id.broadleaf == 18
    if not test_passed then print("broadleaf", 18, fat_id.broadleaf) end
    test_passed = test_passed and fat_id.ideal_grass == -18
    if not test_passed then print("ideal_grass", -18, fat_id.ideal_grass) end
    test_passed = test_passed and fat_id.ideal_shrub == 17
    if not test_passed then print("ideal_shrub", 17, fat_id.ideal_shrub) end
    test_passed = test_passed and fat_id.ideal_conifer == -10
    if not test_passed then print("ideal_conifer", -10, fat_id.ideal_conifer) end
    test_passed = test_passed and fat_id.ideal_broadleaf == 7
    if not test_passed then print("ideal_broadleaf", 7, fat_id.ideal_broadleaf) end
    test_passed = test_passed and fat_id.silt == 20
    if not test_passed then print("silt", 20, fat_id.silt) end
    test_passed = test_passed and fat_id.clay == 5
    if not test_passed then print("clay", 5, fat_id.clay) end
    test_passed = test_passed and fat_id.sand == 12
    if not test_passed then print("sand", 12, fat_id.sand) end
    test_passed = test_passed and fat_id.soil_minerals == 3
    if not test_passed then print("soil_minerals", 3, fat_id.soil_minerals) end
    test_passed = test_passed and fat_id.soil_organics == 14
    if not test_passed then print("soil_organics", 14, fat_id.soil_organics) end
    test_passed = test_passed and fat_id.january_waterflow == 8
    if not test_passed then print("january_waterflow", 8, fat_id.january_waterflow) end
    test_passed = test_passed and fat_id.january_rain == 12
    if not test_passed then print("january_rain", 12, fat_id.january_rain) end
    test_passed = test_passed and fat_id.january_temperature == -3
    if not test_passed then print("january_temperature", -3, fat_id.january_temperature) end
    test_passed = test_passed and fat_id.july_waterflow == -18
    if not test_passed then print("july_waterflow", -18, fat_id.july_waterflow) end
    test_passed = test_passed and fat_id.july_rain == -19
    if not test_passed then print("july_rain", -19, fat_id.july_rain) end
    test_passed = test_passed and fat_id.july_temperature == 3
    if not test_passed then print("july_temperature", 3, fat_id.july_temperature) end
    test_passed = test_passed and fat_id.waterlevel == 9
    if not test_passed then print("waterlevel", 9, fat_id.waterlevel) end
    test_passed = test_passed and fat_id.has_river == false
    if not test_passed then print("has_river", false, fat_id.has_river) end
    test_passed = test_passed and fat_id.has_marsh == false
    if not test_passed then print("has_marsh", false, fat_id.has_marsh) end
    test_passed = test_passed and fat_id.ice == 7
    if not test_passed then print("ice", 7, fat_id.ice) end
    test_passed = test_passed and fat_id.ice_age_ice == 13
    if not test_passed then print("ice_age_ice", 13, fat_id.ice_age_ice) end
    test_passed = test_passed and fat_id.debug_r == -10
    if not test_passed then print("debug_r", -10, fat_id.debug_r) end
    test_passed = test_passed and fat_id.debug_g == 15
    if not test_passed then print("debug_g", 15, fat_id.debug_g) end
    test_passed = test_passed and fat_id.debug_b == -9
    if not test_passed then print("debug_b", -9, fat_id.debug_b) end
    test_passed = test_passed and fat_id.real_r == -5
    if not test_passed then print("real_r", -5, fat_id.real_r) end
    test_passed = test_passed and fat_id.real_g == -6
    if not test_passed then print("real_g", -6, fat_id.real_g) end
    test_passed = test_passed and fat_id.real_b == -19
    if not test_passed then print("real_b", -19, fat_id.real_b) end
    test_passed = test_passed and fat_id.pathfinding_index == 5
    if not test_passed then print("pathfinding_index", 5, fat_id.pathfinding_index) end
    test_passed = test_passed and fat_id.resource == 10
    if not test_passed then print("resource", 10, fat_id.resource) end
    test_passed = test_passed and fat_id.bedrock == 5
    if not test_passed then print("bedrock", 5, fat_id.bedrock) end
    test_passed = test_passed and fat_id.biome == 4
    if not test_passed then print("biome", 4, fat_id.biome) end
    print("SET_GET_TEST_2_tile:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_pop()
    local fat_id = DATA.fatten_pop(id)
    fat_id.race = 1
    fat_id.female = true
    fat_id.age = 2
    fat_id.savings = 3
    fat_id.life_needs_satisfaction = -10
    fat_id.basic_needs_satisfaction = -1
    for j = 1, 20 do
        DATA.pop_set_need_satisfaction_need(id, j, 4)
    end
    for j = 1, 20 do
        DATA.pop_set_need_satisfaction_use_case(id, j, 19)
    end
    for j = 1, 20 do
        DATA.pop_set_need_satisfaction_consumed(id, j, -7)
    end
    for j = 1, 20 do
        DATA.pop_set_need_satisfaction_demanded(id, j, 18)
    end
    for j = 1, 10 do
        DATA.pop_set_traits(id, j --[[@as number]],  0)    end
    for j = 1, 100 do
        DATA.pop_set_inventory(id, j --[[@as trade_good_id]],  17)    end
    for j = 1, 100 do
        DATA.pop_set_price_memory(id, j --[[@as trade_good_id]],  -10)    end
    fat_id.pending_economy_income = 7
    fat_id.forage_ratio = 20
    fat_id.work_ratio = 5
    fat_id.rank = 2
    for j = 1, 20 do
        DATA.pop_set_dna(id, j --[[@as number]],  14)    end
    local test_passed = true
    test_passed = test_passed and fat_id.race == 1
    if not test_passed then print("race", 1, fat_id.race) end
    test_passed = test_passed and fat_id.female == true
    if not test_passed then print("female", true, fat_id.female) end
    test_passed = test_passed and fat_id.age == 2
    if not test_passed then print("age", 2, fat_id.age) end
    test_passed = test_passed and fat_id.savings == 3
    if not test_passed then print("savings", 3, fat_id.savings) end
    test_passed = test_passed and fat_id.life_needs_satisfaction == -10
    if not test_passed then print("life_needs_satisfaction", -10, fat_id.life_needs_satisfaction) end
    test_passed = test_passed and fat_id.basic_needs_satisfaction == -1
    if not test_passed then print("basic_needs_satisfaction", -1, fat_id.basic_needs_satisfaction) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_need_satisfaction_need(id, j) == 4
    end
    if not test_passed then print("need_satisfaction.need", 4, DATA.pop[id].need_satisfaction[0].need) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_need_satisfaction_use_case(id, j) == 19
    end
    if not test_passed then print("need_satisfaction.use_case", 19, DATA.pop[id].need_satisfaction[0].use_case) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_need_satisfaction_consumed(id, j) == -7
    end
    if not test_passed then print("need_satisfaction.consumed", -7, DATA.pop[id].need_satisfaction[0].consumed) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_need_satisfaction_demanded(id, j) == 18
    end
    if not test_passed then print("need_satisfaction.demanded", 18, DATA.pop[id].need_satisfaction[0].demanded) end
    for j = 1, 10 do
        test_passed = test_passed and DATA.pop_get_traits(id, j --[[@as number]]) == 0
    end
    if not test_passed then print("traits", 0, DATA.pop[id].traits[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.pop_get_inventory(id, j --[[@as trade_good_id]]) == 17
    end
    if not test_passed then print("inventory", 17, DATA.pop[id].inventory[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.pop_get_price_memory(id, j --[[@as trade_good_id]]) == -10
    end
    if not test_passed then print("price_memory", -10, DATA.pop[id].price_memory[0]) end
    test_passed = test_passed and fat_id.pending_economy_income == 7
    if not test_passed then print("pending_economy_income", 7, fat_id.pending_economy_income) end
    test_passed = test_passed and fat_id.forage_ratio == 20
    if not test_passed then print("forage_ratio", 20, fat_id.forage_ratio) end
    test_passed = test_passed and fat_id.work_ratio == 5
    if not test_passed then print("work_ratio", 5, fat_id.work_ratio) end
    test_passed = test_passed and fat_id.rank == 2
    if not test_passed then print("rank", 2, fat_id.rank) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.pop_get_dna(id, j --[[@as number]]) == 14
    end
    if not test_passed then print("dna", 14, DATA.pop[id].dna[0]) end
    print("SET_GET_TEST_2_pop:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_province()
    local fat_id = DATA.fatten_province(id)
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
    fat_id.infrastructure_efficiency = -10
    for j = 1, 400 do
        DATA.province_set_technologies_present(id, j --[[@as technology_id]],  13)    end
    for j = 1, 400 do
        DATA.province_set_technologies_researchable(id, j --[[@as technology_id]],  20)    end
    for j = 1, 250 do
        DATA.province_set_buildable_buildings(id, j --[[@as building_type_id]],  12)    end
    for j = 1, 100 do
        DATA.province_set_local_production(id, j --[[@as trade_good_id]],  12)    end
    for j = 1, 100 do
        DATA.province_set_temp_buffer_0(id, j --[[@as trade_good_id]],  3)    end
    for j = 1, 100 do
        DATA.province_set_local_consumption(id, j --[[@as trade_good_id]],  14)    end
    for j = 1, 100 do
        DATA.province_set_local_demand(id, j --[[@as trade_good_id]],  8)    end
    for j = 1, 100 do
        DATA.province_set_local_satisfaction(id, j --[[@as trade_good_id]],  12)    end
    for j = 1, 100 do
        DATA.province_set_temp_buffer_use_0(id, j --[[@as use_case_id]],  -3)    end
    for j = 1, 100 do
        DATA.province_set_temp_buffer_use_grad(id, j --[[@as use_case_id]],  -18)    end
    for j = 1, 100 do
        DATA.province_set_local_use_satisfaction(id, j --[[@as use_case_id]],  -19)    end
    for j = 1, 100 do
        DATA.province_set_local_use_buffer_demand(id, j --[[@as use_case_id]],  3)    end
    for j = 1, 100 do
        DATA.province_set_local_use_buffer_supply(id, j --[[@as use_case_id]],  9)    end
    for j = 1, 100 do
        DATA.province_set_local_use_buffer_cost(id, j --[[@as use_case_id]],  0)    end
    for j = 1, 100 do
        DATA.province_set_local_storage(id, j --[[@as trade_good_id]],  4)    end
    for j = 1, 100 do
        DATA.province_set_local_prices(id, j --[[@as trade_good_id]],  7)    end
    fat_id.local_wealth = 13
    fat_id.trade_wealth = -10
    fat_id.local_income = 15
    fat_id.local_building_upkeep = -9
    fat_id.foragers = -5
    fat_id.foragers_water = -6
    fat_id.foragers_limit = -19
    for j = 1, 25 do
        DATA.province_set_foragers_targets_output_good(id, j, 5)
    end
    for j = 1, 25 do
        DATA.province_set_foragers_targets_output_value(id, j, 0)
    end
    for j = 1, 25 do
        DATA.province_set_foragers_targets_amount(id, j, -9)
    end
    for j = 1, 25 do
        DATA.province_set_foragers_targets_forage(id, j, 2)
    end
    for j = 1, 25 do
        DATA.province_set_local_resources_resource(id, j, 16)
    end
    for j = 1, 25 do
        DATA.province_set_local_resources_location(id, j, 16)
    end
    fat_id.mood = 3
    for j = 1, 20 do
        DATA.province_set_unit_types(id, j --[[@as unit_type_id]],  16)    end
    for j = 1, 250 do
        DATA.province_set_throughput_boosts(id, j --[[@as production_method_id]],  15)    end
    for j = 1, 250 do
        DATA.province_set_input_efficiency_boosts(id, j --[[@as production_method_id]],  -9)    end
    for j = 1, 250 do
        DATA.province_set_output_efficiency_boosts(id, j --[[@as production_method_id]],  8)    end
    fat_id.on_a_river = false
    fat_id.on_a_forest = false
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
    test_passed = test_passed and fat_id.infrastructure_efficiency == -10
    if not test_passed then print("infrastructure_efficiency", -10, fat_id.infrastructure_efficiency) end
    for j = 1, 400 do
        test_passed = test_passed and DATA.province_get_technologies_present(id, j --[[@as technology_id]]) == 13
    end
    if not test_passed then print("technologies_present", 13, DATA.province[id].technologies_present[0]) end
    for j = 1, 400 do
        test_passed = test_passed and DATA.province_get_technologies_researchable(id, j --[[@as technology_id]]) == 20
    end
    if not test_passed then print("technologies_researchable", 20, DATA.province[id].technologies_researchable[0]) end
    for j = 1, 250 do
        test_passed = test_passed and DATA.province_get_buildable_buildings(id, j --[[@as building_type_id]]) == 12
    end
    if not test_passed then print("buildable_buildings", 12, DATA.province[id].buildable_buildings[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_production(id, j --[[@as trade_good_id]]) == 12
    end
    if not test_passed then print("local_production", 12, DATA.province[id].local_production[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_temp_buffer_0(id, j --[[@as trade_good_id]]) == 3
    end
    if not test_passed then print("temp_buffer_0", 3, DATA.province[id].temp_buffer_0[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_consumption(id, j --[[@as trade_good_id]]) == 14
    end
    if not test_passed then print("local_consumption", 14, DATA.province[id].local_consumption[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_demand(id, j --[[@as trade_good_id]]) == 8
    end
    if not test_passed then print("local_demand", 8, DATA.province[id].local_demand[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_satisfaction(id, j --[[@as trade_good_id]]) == 12
    end
    if not test_passed then print("local_satisfaction", 12, DATA.province[id].local_satisfaction[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_temp_buffer_use_0(id, j --[[@as use_case_id]]) == -3
    end
    if not test_passed then print("temp_buffer_use_0", -3, DATA.province[id].temp_buffer_use_0[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_temp_buffer_use_grad(id, j --[[@as use_case_id]]) == -18
    end
    if not test_passed then print("temp_buffer_use_grad", -18, DATA.province[id].temp_buffer_use_grad[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_use_satisfaction(id, j --[[@as use_case_id]]) == -19
    end
    if not test_passed then print("local_use_satisfaction", -19, DATA.province[id].local_use_satisfaction[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_use_buffer_demand(id, j --[[@as use_case_id]]) == 3
    end
    if not test_passed then print("local_use_buffer_demand", 3, DATA.province[id].local_use_buffer_demand[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_use_buffer_supply(id, j --[[@as use_case_id]]) == 9
    end
    if not test_passed then print("local_use_buffer_supply", 9, DATA.province[id].local_use_buffer_supply[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_use_buffer_cost(id, j --[[@as use_case_id]]) == 0
    end
    if not test_passed then print("local_use_buffer_cost", 0, DATA.province[id].local_use_buffer_cost[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_storage(id, j --[[@as trade_good_id]]) == 4
    end
    if not test_passed then print("local_storage", 4, DATA.province[id].local_storage[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.province_get_local_prices(id, j --[[@as trade_good_id]]) == 7
    end
    if not test_passed then print("local_prices", 7, DATA.province[id].local_prices[0]) end
    test_passed = test_passed and fat_id.local_wealth == 13
    if not test_passed then print("local_wealth", 13, fat_id.local_wealth) end
    test_passed = test_passed and fat_id.trade_wealth == -10
    if not test_passed then print("trade_wealth", -10, fat_id.trade_wealth) end
    test_passed = test_passed and fat_id.local_income == 15
    if not test_passed then print("local_income", 15, fat_id.local_income) end
    test_passed = test_passed and fat_id.local_building_upkeep == -9
    if not test_passed then print("local_building_upkeep", -9, fat_id.local_building_upkeep) end
    test_passed = test_passed and fat_id.foragers == -5
    if not test_passed then print("foragers", -5, fat_id.foragers) end
    test_passed = test_passed and fat_id.foragers_water == -6
    if not test_passed then print("foragers_water", -6, fat_id.foragers_water) end
    test_passed = test_passed and fat_id.foragers_limit == -19
    if not test_passed then print("foragers_limit", -19, fat_id.foragers_limit) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_foragers_targets_output_good(id, j) == 5
    end
    if not test_passed then print("foragers_targets.output_good", 5, DATA.province[id].foragers_targets[0].output_good) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_foragers_targets_output_value(id, j) == 0
    end
    if not test_passed then print("foragers_targets.output_value", 0, DATA.province[id].foragers_targets[0].output_value) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_foragers_targets_amount(id, j) == -9
    end
    if not test_passed then print("foragers_targets.amount", -9, DATA.province[id].foragers_targets[0].amount) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_foragers_targets_forage(id, j) == 2
    end
    if not test_passed then print("foragers_targets.forage", 2, DATA.province[id].foragers_targets[0].forage) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_local_resources_resource(id, j) == 16
    end
    if not test_passed then print("local_resources.resource", 16, DATA.province[id].local_resources[0].resource) end
    for j = 1, 25 do
        test_passed = test_passed and DATA.province_get_local_resources_location(id, j) == 16
    end
    if not test_passed then print("local_resources.location", 16, DATA.province[id].local_resources[0].location) end
    test_passed = test_passed and fat_id.mood == 3
    if not test_passed then print("mood", 3, fat_id.mood) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.province_get_unit_types(id, j --[[@as unit_type_id]]) == 16
    end
    if not test_passed then print("unit_types", 16, DATA.province[id].unit_types[0]) end
    for j = 1, 250 do
        test_passed = test_passed and DATA.province_get_throughput_boosts(id, j --[[@as production_method_id]]) == 15
    end
    if not test_passed then print("throughput_boosts", 15, DATA.province[id].throughput_boosts[0]) end
    for j = 1, 250 do
        test_passed = test_passed and DATA.province_get_input_efficiency_boosts(id, j --[[@as production_method_id]]) == -9
    end
    if not test_passed then print("input_efficiency_boosts", -9, DATA.province[id].input_efficiency_boosts[0]) end
    for j = 1, 250 do
        test_passed = test_passed and DATA.province_get_output_efficiency_boosts(id, j --[[@as production_method_id]]) == 8
    end
    if not test_passed then print("output_efficiency_boosts", 8, DATA.province[id].output_efficiency_boosts[0]) end
    test_passed = test_passed and fat_id.on_a_river == false
    if not test_passed then print("on_a_river", false, fat_id.on_a_river) end
    test_passed = test_passed and fat_id.on_a_forest == false
    if not test_passed then print("on_a_forest", false, fat_id.on_a_forest) end
    print("SET_GET_TEST_2_province:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_army()
    local fat_id = DATA.fatten_army(id)
    fat_id.destination = 1
    local test_passed = true
    test_passed = test_passed and fat_id.destination == 1
    if not test_passed then print("destination", 1, fat_id.destination) end
    print("SET_GET_TEST_2_army:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_warband()
    local fat_id = DATA.fatten_warband(id)
    for j = 1, 20 do
        DATA.warband_set_units_current(id, j --[[@as unit_type_id]],  -17)    end
    for j = 1, 20 do
        DATA.warband_set_units_target(id, j --[[@as unit_type_id]],  -15)    end
    fat_id.current_status = 1
    fat_id.idle_stance = 1
    fat_id.current_free_time_ratio = -10
    fat_id.treasury = -1
    fat_id.total_upkeep = -4
    fat_id.predicted_upkeep = 18
    fat_id.supplies = -7
    fat_id.supplies_target_days = 18
    fat_id.morale = -18
    local test_passed = true
    for j = 1, 20 do
        test_passed = test_passed and DATA.warband_get_units_current(id, j --[[@as unit_type_id]]) == -17
    end
    if not test_passed then print("units_current", -17, DATA.warband[id].units_current[0]) end
    for j = 1, 20 do
        test_passed = test_passed and DATA.warband_get_units_target(id, j --[[@as unit_type_id]]) == -15
    end
    if not test_passed then print("units_target", -15, DATA.warband[id].units_target[0]) end
    test_passed = test_passed and fat_id.current_status == 1
    if not test_passed then print("current_status", 1, fat_id.current_status) end
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
    local id = DATA.create_realm()
    local fat_id = DATA.fatten_realm(id)
    fat_id.budget_change = -17
    fat_id.budget_saved_change = -15
    for j = 1, 38 do
        DATA.realm_set_budget_spending_by_category(id, j --[[@as ECONOMY_REASON]],  -15)    end
    for j = 1, 38 do
        DATA.realm_set_budget_income_by_category(id, j --[[@as ECONOMY_REASON]],  3)    end
    for j = 1, 38 do
        DATA.realm_set_budget_treasury_change_by_category(id, j --[[@as ECONOMY_REASON]],  -10)    end
    fat_id.budget_treasury = -1
    fat_id.budget_treasury_target = -4
    for j = 1, 7 do
        DATA.realm_set_budget_ratio(id, j, 18)
    end
    for j = 1, 7 do
        DATA.realm_set_budget_budget(id, j, -7)
    end
    for j = 1, 7 do
        DATA.realm_set_budget_to_be_invested(id, j, 18)
    end
    for j = 1, 7 do
        DATA.realm_set_budget_target(id, j, -18)
    end
    fat_id.budget_tax_target = 17
    fat_id.budget_tax_collected_this_year = -10
    fat_id.r = 7
    fat_id.g = 20
    fat_id.b = 5
    fat_id.primary_race = 16
    fat_id.capitol = 11
    fat_id.trading_right_cost = 14
    fat_id.building_right_cost = 8
    fat_id.law_trade = 2
    fat_id.law_building = 0
    fat_id.prepare_attack_flag = true
    fat_id.coa_base_r = 3
    fat_id.coa_base_g = 9
    fat_id.coa_base_b = 0
    fat_id.coa_background_r = 4
    fat_id.coa_background_g = 7
    fat_id.coa_background_b = 13
    fat_id.coa_foreground_r = -10
    fat_id.coa_foreground_g = 15
    fat_id.coa_foreground_b = -9
    fat_id.coa_emblem_r = -5
    fat_id.coa_emblem_g = -6
    fat_id.coa_emblem_b = -19
    fat_id.coa_background_image = 5
    fat_id.coa_foreground_image = 10
    fat_id.coa_emblem_image = 5
    for j = 1, 100 do
        DATA.realm_set_resources(id, j --[[@as trade_good_id]],  -12)    end
    for j = 1, 100 do
        DATA.realm_set_production(id, j --[[@as trade_good_id]],  12)    end
    for j = 1, 100 do
        DATA.realm_set_bought(id, j --[[@as trade_good_id]],  12)    end
    for j = 1, 100 do
        DATA.realm_set_sold(id, j --[[@as trade_good_id]],  3)    end
    fat_id.expected_food_consumption = 12
    local test_passed = true
    test_passed = test_passed and fat_id.budget_change == -17
    if not test_passed then print("budget_change", -17, fat_id.budget_change) end
    test_passed = test_passed and fat_id.budget_saved_change == -15
    if not test_passed then print("budget_saved_change", -15, fat_id.budget_saved_change) end
    for j = 1, 38 do
        test_passed = test_passed and DATA.realm_get_budget_spending_by_category(id, j --[[@as ECONOMY_REASON]]) == -15
    end
    if not test_passed then print("budget_spending_by_category", -15, DATA.realm[id].budget_spending_by_category[0]) end
    for j = 1, 38 do
        test_passed = test_passed and DATA.realm_get_budget_income_by_category(id, j --[[@as ECONOMY_REASON]]) == 3
    end
    if not test_passed then print("budget_income_by_category", 3, DATA.realm[id].budget_income_by_category[0]) end
    for j = 1, 38 do
        test_passed = test_passed and DATA.realm_get_budget_treasury_change_by_category(id, j --[[@as ECONOMY_REASON]]) == -10
    end
    if not test_passed then print("budget_treasury_change_by_category", -10, DATA.realm[id].budget_treasury_change_by_category[0]) end
    test_passed = test_passed and fat_id.budget_treasury == -1
    if not test_passed then print("budget_treasury", -1, fat_id.budget_treasury) end
    test_passed = test_passed and fat_id.budget_treasury_target == -4
    if not test_passed then print("budget_treasury_target", -4, fat_id.budget_treasury_target) end
    for j = 1, 7 do
        test_passed = test_passed and DATA.realm_get_budget_ratio(id, j) == 18
    end
    if not test_passed then print("budget.ratio", 18, DATA.realm[id].budget[0].ratio) end
    for j = 1, 7 do
        test_passed = test_passed and DATA.realm_get_budget_budget(id, j) == -7
    end
    if not test_passed then print("budget.budget", -7, DATA.realm[id].budget[0].budget) end
    for j = 1, 7 do
        test_passed = test_passed and DATA.realm_get_budget_to_be_invested(id, j) == 18
    end
    if not test_passed then print("budget.to_be_invested", 18, DATA.realm[id].budget[0].to_be_invested) end
    for j = 1, 7 do
        test_passed = test_passed and DATA.realm_get_budget_target(id, j) == -18
    end
    if not test_passed then print("budget.target", -18, DATA.realm[id].budget[0].target) end
    test_passed = test_passed and fat_id.budget_tax_target == 17
    if not test_passed then print("budget_tax_target", 17, fat_id.budget_tax_target) end
    test_passed = test_passed and fat_id.budget_tax_collected_this_year == -10
    if not test_passed then print("budget_tax_collected_this_year", -10, fat_id.budget_tax_collected_this_year) end
    test_passed = test_passed and fat_id.r == 7
    if not test_passed then print("r", 7, fat_id.r) end
    test_passed = test_passed and fat_id.g == 20
    if not test_passed then print("g", 20, fat_id.g) end
    test_passed = test_passed and fat_id.b == 5
    if not test_passed then print("b", 5, fat_id.b) end
    test_passed = test_passed and fat_id.primary_race == 16
    if not test_passed then print("primary_race", 16, fat_id.primary_race) end
    test_passed = test_passed and fat_id.capitol == 11
    if not test_passed then print("capitol", 11, fat_id.capitol) end
    test_passed = test_passed and fat_id.trading_right_cost == 14
    if not test_passed then print("trading_right_cost", 14, fat_id.trading_right_cost) end
    test_passed = test_passed and fat_id.building_right_cost == 8
    if not test_passed then print("building_right_cost", 8, fat_id.building_right_cost) end
    test_passed = test_passed and fat_id.law_trade == 2
    if not test_passed then print("law_trade", 2, fat_id.law_trade) end
    test_passed = test_passed and fat_id.law_building == 0
    if not test_passed then print("law_building", 0, fat_id.law_building) end
    test_passed = test_passed and fat_id.prepare_attack_flag == true
    if not test_passed then print("prepare_attack_flag", true, fat_id.prepare_attack_flag) end
    test_passed = test_passed and fat_id.coa_base_r == 3
    if not test_passed then print("coa_base_r", 3, fat_id.coa_base_r) end
    test_passed = test_passed and fat_id.coa_base_g == 9
    if not test_passed then print("coa_base_g", 9, fat_id.coa_base_g) end
    test_passed = test_passed and fat_id.coa_base_b == 0
    if not test_passed then print("coa_base_b", 0, fat_id.coa_base_b) end
    test_passed = test_passed and fat_id.coa_background_r == 4
    if not test_passed then print("coa_background_r", 4, fat_id.coa_background_r) end
    test_passed = test_passed and fat_id.coa_background_g == 7
    if not test_passed then print("coa_background_g", 7, fat_id.coa_background_g) end
    test_passed = test_passed and fat_id.coa_background_b == 13
    if not test_passed then print("coa_background_b", 13, fat_id.coa_background_b) end
    test_passed = test_passed and fat_id.coa_foreground_r == -10
    if not test_passed then print("coa_foreground_r", -10, fat_id.coa_foreground_r) end
    test_passed = test_passed and fat_id.coa_foreground_g == 15
    if not test_passed then print("coa_foreground_g", 15, fat_id.coa_foreground_g) end
    test_passed = test_passed and fat_id.coa_foreground_b == -9
    if not test_passed then print("coa_foreground_b", -9, fat_id.coa_foreground_b) end
    test_passed = test_passed and fat_id.coa_emblem_r == -5
    if not test_passed then print("coa_emblem_r", -5, fat_id.coa_emblem_r) end
    test_passed = test_passed and fat_id.coa_emblem_g == -6
    if not test_passed then print("coa_emblem_g", -6, fat_id.coa_emblem_g) end
    test_passed = test_passed and fat_id.coa_emblem_b == -19
    if not test_passed then print("coa_emblem_b", -19, fat_id.coa_emblem_b) end
    test_passed = test_passed and fat_id.coa_background_image == 5
    if not test_passed then print("coa_background_image", 5, fat_id.coa_background_image) end
    test_passed = test_passed and fat_id.coa_foreground_image == 10
    if not test_passed then print("coa_foreground_image", 10, fat_id.coa_foreground_image) end
    test_passed = test_passed and fat_id.coa_emblem_image == 5
    if not test_passed then print("coa_emblem_image", 5, fat_id.coa_emblem_image) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.realm_get_resources(id, j --[[@as trade_good_id]]) == -12
    end
    if not test_passed then print("resources", -12, DATA.realm[id].resources[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.realm_get_production(id, j --[[@as trade_good_id]]) == 12
    end
    if not test_passed then print("production", 12, DATA.realm[id].production[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.realm_get_bought(id, j --[[@as trade_good_id]]) == 12
    end
    if not test_passed then print("bought", 12, DATA.realm[id].bought[0]) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.realm_get_sold(id, j --[[@as trade_good_id]]) == 3
    end
    if not test_passed then print("sold", 3, DATA.realm[id].sold[0]) end
    test_passed = test_passed and fat_id.expected_food_consumption == 12
    if not test_passed then print("expected_food_consumption", 12, fat_id.expected_food_consumption) end
    print("SET_GET_TEST_2_realm:")
    if test_passed then print("PASSED") else print("ERROR") end
    local id = DATA.create_building()
    local fat_id = DATA.fatten_building(id)
    fat_id.current_type = 1
    fat_id.savings = -15
    fat_id.subsidy = -15
    fat_id.subsidy_last = 3
    fat_id.income_mean = -10
    fat_id.last_income = -1
    fat_id.last_donation_to_owner = -4
    fat_id.unused = 18
    fat_id.work_ratio = -7
    fat_id.production_scale = 18
    for j = 1, 8 do
        DATA.building_set_spent_on_inputs_use(id, j, 1)
    end
    for j = 1, 8 do
        DATA.building_set_spent_on_inputs_amount(id, j, 17)
    end
    for j = 1, 8 do
        DATA.building_set_earn_from_outputs_good(id, j, 5)
    end
    for j = 1, 8 do
        DATA.building_set_earn_from_outputs_amount(id, j, 7)
    end
    for j = 1, 8 do
        DATA.building_set_amount_of_inputs_use(id, j, 20)
    end
    for j = 1, 8 do
        DATA.building_set_amount_of_inputs_amount(id, j, 5)
    end
    for j = 1, 8 do
        DATA.building_set_amount_of_outputs_good(id, j, 16)
    end
    for j = 1, 8 do
        DATA.building_set_amount_of_outputs_amount(id, j, 3)
    end
    for j = 1, 100 do
        DATA.building_set_inventory(id, j --[[@as trade_good_id]],  14)    end
    local test_passed = true
    test_passed = test_passed and fat_id.current_type == 1
    if not test_passed then print("current_type", 1, fat_id.current_type) end
    test_passed = test_passed and fat_id.savings == -15
    if not test_passed then print("savings", -15, fat_id.savings) end
    test_passed = test_passed and fat_id.subsidy == -15
    if not test_passed then print("subsidy", -15, fat_id.subsidy) end
    test_passed = test_passed and fat_id.subsidy_last == 3
    if not test_passed then print("subsidy_last", 3, fat_id.subsidy_last) end
    test_passed = test_passed and fat_id.income_mean == -10
    if not test_passed then print("income_mean", -10, fat_id.income_mean) end
    test_passed = test_passed and fat_id.last_income == -1
    if not test_passed then print("last_income", -1, fat_id.last_income) end
    test_passed = test_passed and fat_id.last_donation_to_owner == -4
    if not test_passed then print("last_donation_to_owner", -4, fat_id.last_donation_to_owner) end
    test_passed = test_passed and fat_id.unused == 18
    if not test_passed then print("unused", 18, fat_id.unused) end
    test_passed = test_passed and fat_id.work_ratio == -7
    if not test_passed then print("work_ratio", -7, fat_id.work_ratio) end
    test_passed = test_passed and fat_id.production_scale == 18
    if not test_passed then print("production_scale", 18, fat_id.production_scale) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_spent_on_inputs_use(id, j) == 1
    end
    if not test_passed then print("spent_on_inputs.use", 1, DATA.building[id].spent_on_inputs[0].use) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_spent_on_inputs_amount(id, j) == 17
    end
    if not test_passed then print("spent_on_inputs.amount", 17, DATA.building[id].spent_on_inputs[0].amount) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_earn_from_outputs_good(id, j) == 5
    end
    if not test_passed then print("earn_from_outputs.good", 5, DATA.building[id].earn_from_outputs[0].good) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_earn_from_outputs_amount(id, j) == 7
    end
    if not test_passed then print("earn_from_outputs.amount", 7, DATA.building[id].earn_from_outputs[0].amount) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_amount_of_inputs_use(id, j) == 20
    end
    if not test_passed then print("amount_of_inputs.use", 20, DATA.building[id].amount_of_inputs[0].use) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_amount_of_inputs_amount(id, j) == 5
    end
    if not test_passed then print("amount_of_inputs.amount", 5, DATA.building[id].amount_of_inputs[0].amount) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_amount_of_outputs_good(id, j) == 16
    end
    if not test_passed then print("amount_of_outputs.good", 16, DATA.building[id].amount_of_outputs[0].good) end
    for j = 1, 8 do
        test_passed = test_passed and DATA.building_get_amount_of_outputs_amount(id, j) == 3
    end
    if not test_passed then print("amount_of_outputs.amount", 3, DATA.building[id].amount_of_outputs[0].amount) end
    for j = 1, 100 do
        test_passed = test_passed and DATA.building_get_inventory(id, j --[[@as trade_good_id]]) == 14
    end
    if not test_passed then print("inventory", 14, DATA.building[id].inventory[0]) end
    print("SET_GET_TEST_2_building:")
    if test_passed then print("PASSED") else print("ERROR") end
end
return DATA
