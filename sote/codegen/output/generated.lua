local ffi = require("ffi")
local bitser = require("engine.bitser")

DATA = {}
----------tile----------


---tile: LSP types---
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
---@field bedrock Bedrock 
---@field biome Biome 
---@field debug_r number between 0 and 1, as per Love2Ds convention...
---@field debug_g number between 0 and 1, as per Love2Ds convention...
---@field debug_b number between 0 and 1, as per Love2Ds convention...
---@field real_r number between 0 and 1, as per Love2Ds convention...
---@field real_g number between 0 and 1, as per Love2Ds convention...
---@field real_b number between 0 and 1, as per Love2Ds convention...
---@field pathfinding_index number 
---@field resource Resource? 

---tile: FFI arrays---
---@type (boolean)[]
local tile_is_land= ffi.new("bool[?]", 2160000)
---@type (boolean)[]
local tile_is_fresh= ffi.new("bool[?]", 2160000)
---@type (number)[]
local tile_elevation= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_grass= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_shrub= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_conifer= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_broadleaf= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_ideal_grass= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_ideal_shrub= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_ideal_conifer= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_ideal_broadleaf= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_silt= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_clay= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_sand= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_soil_minerals= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_soil_organics= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_january_waterflow= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_july_waterflow= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_waterlevel= ffi.new("float[?]", 2160000)
---@type (boolean)[]
local tile_has_river= ffi.new("bool[?]", 2160000)
---@type (boolean)[]
local tile_has_marsh= ffi.new("bool[?]", 2160000)
---@type (number)[]
local tile_ice= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_ice_age_ice= ffi.new("float[?]", 2160000)
---@type (Bedrock)[]
local tile_bedrock= {}
---@type (Biome)[]
local tile_biome= {}
---@type (number)[]
local tile_debug_r= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_debug_g= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_debug_b= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_real_r= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_real_g= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_real_b= ffi.new("float[?]", 2160000)
---@type (number)[]
local tile_pathfinding_index= ffi.new("uint32_t[?]", 2160000)
---@type (Resource?)[]
local tile_resource= {}

---tile: LUA bindings---
---@param tile_id tile_id valid tile id
---@return boolean is_land 
function DATA.tile_get_is_land(tile_id)
    return tile_is_land[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value boolean value
function DATA.tile_set_is_land(tile_id, value)
    tile_is_land[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return boolean is_fresh 
function DATA.tile_get_is_fresh(tile_id)
    return tile_is_fresh[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value boolean value
function DATA.tile_set_is_fresh(tile_id, value)
    tile_is_fresh[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number elevation 
function DATA.tile_get_elevation(tile_id)
    return tile_elevation[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_elevation(tile_id, value)
    tile_elevation[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number grass 
function DATA.tile_get_grass(tile_id)
    return tile_grass[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_grass(tile_id, value)
    tile_grass[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number shrub 
function DATA.tile_get_shrub(tile_id)
    return tile_shrub[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_shrub(tile_id, value)
    tile_shrub[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number conifer 
function DATA.tile_get_conifer(tile_id)
    return tile_conifer[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_conifer(tile_id, value)
    tile_conifer[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number broadleaf 
function DATA.tile_get_broadleaf(tile_id)
    return tile_broadleaf[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_broadleaf(tile_id, value)
    tile_broadleaf[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number ideal_grass 
function DATA.tile_get_ideal_grass(tile_id)
    return tile_ideal_grass[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_ideal_grass(tile_id, value)
    tile_ideal_grass[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number ideal_shrub 
function DATA.tile_get_ideal_shrub(tile_id)
    return tile_ideal_shrub[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_ideal_shrub(tile_id, value)
    tile_ideal_shrub[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number ideal_conifer 
function DATA.tile_get_ideal_conifer(tile_id)
    return tile_ideal_conifer[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_ideal_conifer(tile_id, value)
    tile_ideal_conifer[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number ideal_broadleaf 
function DATA.tile_get_ideal_broadleaf(tile_id)
    return tile_ideal_broadleaf[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_ideal_broadleaf(tile_id, value)
    tile_ideal_broadleaf[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number silt 
function DATA.tile_get_silt(tile_id)
    return tile_silt[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_silt(tile_id, value)
    tile_silt[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number clay 
function DATA.tile_get_clay(tile_id)
    return tile_clay[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_clay(tile_id, value)
    tile_clay[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number sand 
function DATA.tile_get_sand(tile_id)
    return tile_sand[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_sand(tile_id, value)
    tile_sand[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number soil_minerals 
function DATA.tile_get_soil_minerals(tile_id)
    return tile_soil_minerals[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_soil_minerals(tile_id, value)
    tile_soil_minerals[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number soil_organics 
function DATA.tile_get_soil_organics(tile_id)
    return tile_soil_organics[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_soil_organics(tile_id, value)
    tile_soil_organics[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number january_waterflow 
function DATA.tile_get_january_waterflow(tile_id)
    return tile_january_waterflow[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_january_waterflow(tile_id, value)
    tile_january_waterflow[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number july_waterflow 
function DATA.tile_get_july_waterflow(tile_id)
    return tile_july_waterflow[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_july_waterflow(tile_id, value)
    tile_july_waterflow[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number waterlevel 
function DATA.tile_get_waterlevel(tile_id)
    return tile_waterlevel[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_waterlevel(tile_id, value)
    tile_waterlevel[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return boolean has_river 
function DATA.tile_get_has_river(tile_id)
    return tile_has_river[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value boolean value
function DATA.tile_set_has_river(tile_id, value)
    tile_has_river[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return boolean has_marsh 
function DATA.tile_get_has_marsh(tile_id)
    return tile_has_marsh[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value boolean value
function DATA.tile_set_has_marsh(tile_id, value)
    tile_has_marsh[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number ice 
function DATA.tile_get_ice(tile_id)
    return tile_ice[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_ice(tile_id, value)
    tile_ice[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number ice_age_ice 
function DATA.tile_get_ice_age_ice(tile_id)
    return tile_ice_age_ice[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_ice_age_ice(tile_id, value)
    tile_ice_age_ice[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return Bedrock bedrock 
function DATA.tile_get_bedrock(tile_id)
    return tile_bedrock[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value Bedrock value
function DATA.tile_set_bedrock(tile_id, value)
    tile_bedrock[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return Biome biome 
function DATA.tile_get_biome(tile_id)
    return tile_biome[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value Biome value
function DATA.tile_set_biome(tile_id, value)
    tile_biome[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number debug_r between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_debug_r(tile_id)
    return tile_debug_r[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_debug_r(tile_id, value)
    tile_debug_r[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number debug_g between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_debug_g(tile_id)
    return tile_debug_g[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_debug_g(tile_id, value)
    tile_debug_g[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number debug_b between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_debug_b(tile_id)
    return tile_debug_b[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_debug_b(tile_id, value)
    tile_debug_b[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number real_r between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_real_r(tile_id)
    return tile_real_r[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_real_r(tile_id, value)
    tile_real_r[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number real_g between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_real_g(tile_id)
    return tile_real_g[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_real_g(tile_id, value)
    tile_real_g[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number real_b between 0 and 1, as per Love2Ds convention...
function DATA.tile_get_real_b(tile_id)
    return tile_real_b[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_real_b(tile_id, value)
    tile_real_b[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return number pathfinding_index 
function DATA.tile_get_pathfinding_index(tile_id)
    return tile_pathfinding_index[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value number value
function DATA.tile_set_pathfinding_index(tile_id, value)
    tile_pathfinding_index[tile_id] = value
end
---@param tile_id tile_id valid tile id
---@return Resource? resource 
function DATA.tile_get_resource(tile_id)
    return tile_resource[tile_id]
end
---@param tile_id tile_id valid tile id
---@param value Resource? value
function DATA.tile_set_resource(tile_id, value)
    tile_resource[tile_id] = value
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
        if (k == "bedrock") then return DATA.tile_get_bedrock(t.id) end
        if (k == "biome") then return DATA.tile_get_biome(t.id) end
        if (k == "debug_r") then return DATA.tile_get_debug_r(t.id) end
        if (k == "debug_g") then return DATA.tile_get_debug_g(t.id) end
        if (k == "debug_b") then return DATA.tile_get_debug_b(t.id) end
        if (k == "real_r") then return DATA.tile_get_real_r(t.id) end
        if (k == "real_g") then return DATA.tile_get_real_g(t.id) end
        if (k == "real_b") then return DATA.tile_get_real_b(t.id) end
        if (k == "pathfinding_index") then return DATA.tile_get_pathfinding_index(t.id) end
        if (k == "resource") then return DATA.tile_get_resource(t.id) end
        return rawget(t, k)
    end,
    __newindex = function (t,k,v)
        if (k == "is_land") then
            DATA.tile_set_is_land(t.id, v)
        end
        if (k == "is_fresh") then
            DATA.tile_set_is_fresh(t.id, v)
        end
        if (k == "elevation") then
            DATA.tile_set_elevation(t.id, v)
        end
        if (k == "grass") then
            DATA.tile_set_grass(t.id, v)
        end
        if (k == "shrub") then
            DATA.tile_set_shrub(t.id, v)
        end
        if (k == "conifer") then
            DATA.tile_set_conifer(t.id, v)
        end
        if (k == "broadleaf") then
            DATA.tile_set_broadleaf(t.id, v)
        end
        if (k == "ideal_grass") then
            DATA.tile_set_ideal_grass(t.id, v)
        end
        if (k == "ideal_shrub") then
            DATA.tile_set_ideal_shrub(t.id, v)
        end
        if (k == "ideal_conifer") then
            DATA.tile_set_ideal_conifer(t.id, v)
        end
        if (k == "ideal_broadleaf") then
            DATA.tile_set_ideal_broadleaf(t.id, v)
        end
        if (k == "silt") then
            DATA.tile_set_silt(t.id, v)
        end
        if (k == "clay") then
            DATA.tile_set_clay(t.id, v)
        end
        if (k == "sand") then
            DATA.tile_set_sand(t.id, v)
        end
        if (k == "soil_minerals") then
            DATA.tile_set_soil_minerals(t.id, v)
        end
        if (k == "soil_organics") then
            DATA.tile_set_soil_organics(t.id, v)
        end
        if (k == "january_waterflow") then
            DATA.tile_set_january_waterflow(t.id, v)
        end
        if (k == "july_waterflow") then
            DATA.tile_set_july_waterflow(t.id, v)
        end
        if (k == "waterlevel") then
            DATA.tile_set_waterlevel(t.id, v)
        end
        if (k == "has_river") then
            DATA.tile_set_has_river(t.id, v)
        end
        if (k == "has_marsh") then
            DATA.tile_set_has_marsh(t.id, v)
        end
        if (k == "ice") then
            DATA.tile_set_ice(t.id, v)
        end
        if (k == "ice_age_ice") then
            DATA.tile_set_ice_age_ice(t.id, v)
        end
        if (k == "bedrock") then
            DATA.tile_set_bedrock(t.id, v)
        end
        if (k == "biome") then
            DATA.tile_set_biome(t.id, v)
        end
        if (k == "debug_r") then
            DATA.tile_set_debug_r(t.id, v)
        end
        if (k == "debug_g") then
            DATA.tile_set_debug_g(t.id, v)
        end
        if (k == "debug_b") then
            DATA.tile_set_debug_b(t.id, v)
        end
        if (k == "real_r") then
            DATA.tile_set_real_r(t.id, v)
        end
        if (k == "real_g") then
            DATA.tile_set_real_g(t.id, v)
        end
        if (k == "real_b") then
            DATA.tile_set_real_b(t.id, v)
        end
        if (k == "pathfinding_index") then
            DATA.tile_set_pathfinding_index(t.id, v)
        end
        if (k == "resource") then
            DATA.tile_set_resource(t.id, v)
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

---@class LuaDataBlob
---@field tile_bedrock (Bedrock)[]
---@field tile_biome (Biome)[]
---@field tile_resource (Resource?)[]

function DATA.save_state()
    local current_lua_state = {}
    current_lua_state.tile_bedrock = tile_bedrock
    current_lua_state.tile_biome = tile_biome
    current_lua_state.tile_resource = tile_resource

    bitser.dumpLoveFile("gamestatesave.bitserbeaver", current_lua_state)

    local current_offset = 0
    local current_shift = 0
    local total_ffi_size = 0
    total_ffi_size = total_ffi_size + ffi.sizeof("bool") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("bool") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("bool") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("bool") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("uint32_t") * 2160000
    local current_buffer = ffi.new("uint8_t[?]", total_ffi_size)
    current_shift = ffi.sizeof("bool") * 2160000
    ffi.copy(current_buffer + current_offset, tile_is_land, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("bool") * 2160000
    ffi.copy(current_buffer + current_offset, tile_is_fresh, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_elevation, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_grass, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_shrub, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_conifer, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_broadleaf, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_ideal_grass, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_ideal_shrub, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_ideal_conifer, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_ideal_broadleaf, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_silt, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_clay, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_sand, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_soil_minerals, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_soil_organics, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_january_waterflow, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_july_waterflow, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_waterlevel, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("bool") * 2160000
    ffi.copy(current_buffer + current_offset, tile_has_river, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("bool") * 2160000
    ffi.copy(current_buffer + current_offset, tile_has_marsh, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_ice, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_ice_age_ice, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_debug_r, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_debug_g, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_debug_b, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_real_r, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_real_g, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(current_buffer + current_offset, tile_real_b, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("uint32_t") * 2160000
    ffi.copy(current_buffer + current_offset, tile_pathfinding_index, current_shift)
    current_offset = current_offset + current_shift
assert(love.filesystem.write("gamestatesave.binbeaver", ffi.string(current_buffer, total_ffi_size)))end
function DATA.load_state()
    ---@type LuaDataBlob|nil
    local loaded_lua_state = bitser.loadLoveFile("gamestatesave.bitserbeaver")
    assert(loaded_lua_state)
    for key, value in pairs(loaded_lua_state.tile_bedrock) do
        tile_bedrock[key] = value
    end
    for key, value in pairs(loaded_lua_state.tile_biome) do
        tile_biome[key] = value
    end
    for key, value in pairs(loaded_lua_state.tile_resource) do
        tile_resource[key] = value
    end
    local data_love, error = love.filesystem.newFileData("gamestatesave.binbeaver")
    assert(data_love, error)
    local data = ffi.cast("uint8_t*", data_love:getPointer())
    local current_offset = 0
    local current_shift = 0
    local total_ffi_size = 0
    total_ffi_size = total_ffi_size + ffi.sizeof("bool") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("bool") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("bool") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("bool") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("float") * 2160000
    total_ffi_size = total_ffi_size + ffi.sizeof("uint32_t") * 2160000
    current_shift = ffi.sizeof("bool") * 2160000
    ffi.copy(tile_is_land, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("bool") * 2160000
    ffi.copy(tile_is_fresh, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_elevation, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_grass, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_shrub, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_conifer, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_broadleaf, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_ideal_grass, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_ideal_shrub, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_ideal_conifer, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_ideal_broadleaf, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_silt, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_clay, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_sand, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_soil_minerals, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_soil_organics, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_january_waterflow, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_july_waterflow, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_waterlevel, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("bool") * 2160000
    ffi.copy(tile_has_river, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("bool") * 2160000
    ffi.copy(tile_has_marsh, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_ice, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_ice_age_ice, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_debug_r, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_debug_g, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_debug_b, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_real_r, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_real_g, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("float") * 2160000
    ffi.copy(tile_real_b, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
    current_shift = ffi.sizeof("uint32_t") * 2160000
    ffi.copy(tile_pathfinding_index, data + current_offset, current_shift)
    current_offset = current_offset + current_shift
end
function DATA.test_save_load_0()
    for i = 0, 2160000 do
        tile_is_land[i] = false
    end
    for i = 0, 2160000 do
        tile_is_fresh[i] = false
    end
    for i = 0, 2160000 do
        tile_elevation[i] = 20
    end
    for i = 0, 2160000 do
        tile_grass[i] = 132
    end
    for i = 0, 2160000 do
        tile_shrub[i] = 248
    end
    for i = 0, 2160000 do
        tile_conifer[i] = 207
    end
    for i = 0, 2160000 do
        tile_broadleaf[i] = 155
    end
    for i = 0, 2160000 do
        tile_ideal_grass[i] = 244
    end
    for i = 0, 2160000 do
        tile_ideal_shrub[i] = 183
    end
    for i = 0, 2160000 do
        tile_ideal_conifer[i] = 111
    end
    for i = 0, 2160000 do
        tile_ideal_broadleaf[i] = 71
    end
    for i = 0, 2160000 do
        tile_silt[i] = 144
    end
    for i = 0, 2160000 do
        tile_clay[i] = 71
    end
    for i = 0, 2160000 do
        tile_sand[i] = 48
    end
    for i = 0, 2160000 do
        tile_soil_minerals[i] = 128
    end
    for i = 0, 2160000 do
        tile_soil_organics[i] = 75
    end
    for i = 0, 2160000 do
        tile_january_waterflow[i] = 158
    end
    for i = 0, 2160000 do
        tile_july_waterflow[i] = 50
    end
    for i = 0, 2160000 do
        tile_waterlevel[i] = 37
    end
    for i = 0, 2160000 do
        tile_has_river[i] = false
    end
    for i = 0, 2160000 do
        tile_has_marsh[i] = false
    end
    for i = 0, 2160000 do
        tile_ice[i] = 51
    end
    for i = 0, 2160000 do
        tile_ice_age_ice[i] = 181
    end
    for i = 0, 2160000 do
        tile_debug_r[i] = 222
    end
    for i = 0, 2160000 do
        tile_debug_g[i] = 161
    end
    for i = 0, 2160000 do
        tile_debug_b[i] = 104
    end
    for i = 0, 2160000 do
        tile_real_r[i] = 244
    end
    for i = 0, 2160000 do
        tile_real_g[i] = 226
    end
    for i = 0, 2160000 do
        tile_real_b[i] = 133
    end
    for i = 0, 2160000 do
        tile_pathfinding_index[i] = 31
    end
    DATA.save_state()
    DATA.load_state()
    local test_passed = true
    for i = 0, 2160000 do
        test_passed = test_passed or tile_is_land[i] == false
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_is_fresh[i] == false
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_elevation[i] == 20
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_grass[i] == 132
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_shrub[i] == 248
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_conifer[i] == 207
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_broadleaf[i] == 155
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ideal_grass[i] == 244
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ideal_shrub[i] == 183
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ideal_conifer[i] == 111
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ideal_broadleaf[i] == 71
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_silt[i] == 144
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_clay[i] == 71
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_sand[i] == 48
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_soil_minerals[i] == 128
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_soil_organics[i] == 75
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_january_waterflow[i] == 158
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_july_waterflow[i] == 50
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_waterlevel[i] == 37
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_has_river[i] == false
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_has_marsh[i] == false
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ice[i] == 51
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ice_age_ice[i] == 181
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_debug_r[i] == 222
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_debug_g[i] == 161
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_debug_b[i] == 104
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_real_r[i] == 244
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_real_g[i] == 226
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_real_b[i] == 133
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_pathfinding_index[i] == 31
    end
    print("SAVE_LOAD_TEST_0:")
    if test_passed then print("PASSED") else print("ERROR") end
end
function DATA.test_set_get_0()
    local fat_id = DATA.fatten_tile(0)
    fat_id.is_land = false
    fat_id.is_fresh = false
    fat_id.elevation = 20
    fat_id.grass = 132
    fat_id.shrub = 248
    fat_id.conifer = 207
    fat_id.broadleaf = 155
    fat_id.ideal_grass = 244
    fat_id.ideal_shrub = 183
    fat_id.ideal_conifer = 111
    fat_id.ideal_broadleaf = 71
    fat_id.silt = 144
    fat_id.clay = 71
    fat_id.sand = 48
    fat_id.soil_minerals = 128
    fat_id.soil_organics = 75
    fat_id.january_waterflow = 158
    fat_id.july_waterflow = 50
    fat_id.waterlevel = 37
    fat_id.has_river = false
    fat_id.has_marsh = false
    fat_id.ice = 51
    fat_id.ice_age_ice = 181
    fat_id.debug_r = 222
    fat_id.debug_g = 161
    fat_id.debug_b = 104
    fat_id.real_r = 244
    fat_id.real_g = 226
    fat_id.real_b = 133
    fat_id.pathfinding_index = 31
    local test_passed = true
    test_passed = test_passed or fat_id.is_land == false
    test_passed = test_passed or fat_id.is_fresh == false
    test_passed = test_passed or fat_id.elevation == 20
    test_passed = test_passed or fat_id.grass == 132
    test_passed = test_passed or fat_id.shrub == 248
    test_passed = test_passed or fat_id.conifer == 207
    test_passed = test_passed or fat_id.broadleaf == 155
    test_passed = test_passed or fat_id.ideal_grass == 244
    test_passed = test_passed or fat_id.ideal_shrub == 183
    test_passed = test_passed or fat_id.ideal_conifer == 111
    test_passed = test_passed or fat_id.ideal_broadleaf == 71
    test_passed = test_passed or fat_id.silt == 144
    test_passed = test_passed or fat_id.clay == 71
    test_passed = test_passed or fat_id.sand == 48
    test_passed = test_passed or fat_id.soil_minerals == 128
    test_passed = test_passed or fat_id.soil_organics == 75
    test_passed = test_passed or fat_id.january_waterflow == 158
    test_passed = test_passed or fat_id.july_waterflow == 50
    test_passed = test_passed or fat_id.waterlevel == 37
    test_passed = test_passed or fat_id.has_river == false
    test_passed = test_passed or fat_id.has_marsh == false
    test_passed = test_passed or fat_id.ice == 51
    test_passed = test_passed or fat_id.ice_age_ice == 181
    test_passed = test_passed or fat_id.debug_r == 222
    test_passed = test_passed or fat_id.debug_g == 161
    test_passed = test_passed or fat_id.debug_b == 104
    test_passed = test_passed or fat_id.real_r == 244
    test_passed = test_passed or fat_id.real_g == 226
    test_passed = test_passed or fat_id.real_b == 133
    test_passed = test_passed or fat_id.pathfinding_index == 31
    print("SET_GET_TEST_0_tile:")
    if test_passed then print("PASSED") else print("ERROR") end
end
function DATA.test_save_load_1()
    for i = 0, 2160000 do
        tile_is_land[i] = true
    end
    for i = 0, 2160000 do
        tile_is_fresh[i] = true
    end
    for i = 0, 2160000 do
        tile_elevation[i] = 130
    end
    for i = 0, 2160000 do
        tile_grass[i] = 60
    end
    for i = 0, 2160000 do
        tile_shrub[i] = 253
    end
    for i = 0, 2160000 do
        tile_conifer[i] = 230
    end
    for i = 0, 2160000 do
        tile_broadleaf[i] = 241
    end
    for i = 0, 2160000 do
        tile_ideal_grass[i] = 194
    end
    for i = 0, 2160000 do
        tile_ideal_shrub[i] = 107
    end
    for i = 0, 2160000 do
        tile_ideal_conifer[i] = 48
    end
    for i = 0, 2160000 do
        tile_ideal_broadleaf[i] = 249
    end
    for i = 0, 2160000 do
        tile_silt[i] = 14
    end
    for i = 0, 2160000 do
        tile_clay[i] = 199
    end
    for i = 0, 2160000 do
        tile_sand[i] = 221
    end
    for i = 0, 2160000 do
        tile_soil_minerals[i] = 1
    end
    for i = 0, 2160000 do
        tile_soil_organics[i] = 228
    end
    for i = 0, 2160000 do
        tile_january_waterflow[i] = 136
    end
    for i = 0, 2160000 do
        tile_july_waterflow[i] = 117
    end
    for i = 0, 2160000 do
        tile_waterlevel[i] = 52
    end
    for i = 0, 2160000 do
        tile_has_river[i] = true
    end
    for i = 0, 2160000 do
        tile_has_marsh[i] = false
    end
    for i = 0, 2160000 do
        tile_ice[i] = 11
    end
    for i = 0, 2160000 do
        tile_ice_age_ice[i] = 13
    end
    for i = 0, 2160000 do
        tile_debug_r[i] = 4
    end
    for i = 0, 2160000 do
        tile_debug_g[i] = 195
    end
    for i = 0, 2160000 do
        tile_debug_b[i] = 110
    end
    for i = 0, 2160000 do
        tile_real_r[i] = 216
    end
    for i = 0, 2160000 do
        tile_real_g[i] = 14
    end
    for i = 0, 2160000 do
        tile_real_b[i] = 113
    end
    for i = 0, 2160000 do
        tile_pathfinding_index[i] = 224
    end
    DATA.save_state()
    DATA.load_state()
    local test_passed = true
    for i = 0, 2160000 do
        test_passed = test_passed or tile_is_land[i] == true
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_is_fresh[i] == true
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_elevation[i] == 130
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_grass[i] == 60
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_shrub[i] == 253
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_conifer[i] == 230
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_broadleaf[i] == 241
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ideal_grass[i] == 194
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ideal_shrub[i] == 107
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ideal_conifer[i] == 48
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ideal_broadleaf[i] == 249
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_silt[i] == 14
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_clay[i] == 199
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_sand[i] == 221
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_soil_minerals[i] == 1
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_soil_organics[i] == 228
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_january_waterflow[i] == 136
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_july_waterflow[i] == 117
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_waterlevel[i] == 52
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_has_river[i] == true
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_has_marsh[i] == false
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ice[i] == 11
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ice_age_ice[i] == 13
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_debug_r[i] == 4
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_debug_g[i] == 195
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_debug_b[i] == 110
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_real_r[i] == 216
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_real_g[i] == 14
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_real_b[i] == 113
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_pathfinding_index[i] == 224
    end
    print("SAVE_LOAD_TEST_1:")
    if test_passed then print("PASSED") else print("ERROR") end
end
function DATA.test_set_get_1()
    local fat_id = DATA.fatten_tile(0)
    fat_id.is_land = true
    fat_id.is_fresh = true
    fat_id.elevation = 130
    fat_id.grass = 60
    fat_id.shrub = 253
    fat_id.conifer = 230
    fat_id.broadleaf = 241
    fat_id.ideal_grass = 194
    fat_id.ideal_shrub = 107
    fat_id.ideal_conifer = 48
    fat_id.ideal_broadleaf = 249
    fat_id.silt = 14
    fat_id.clay = 199
    fat_id.sand = 221
    fat_id.soil_minerals = 1
    fat_id.soil_organics = 228
    fat_id.january_waterflow = 136
    fat_id.july_waterflow = 117
    fat_id.waterlevel = 52
    fat_id.has_river = true
    fat_id.has_marsh = false
    fat_id.ice = 11
    fat_id.ice_age_ice = 13
    fat_id.debug_r = 4
    fat_id.debug_g = 195
    fat_id.debug_b = 110
    fat_id.real_r = 216
    fat_id.real_g = 14
    fat_id.real_b = 113
    fat_id.pathfinding_index = 224
    local test_passed = true
    test_passed = test_passed or fat_id.is_land == true
    test_passed = test_passed or fat_id.is_fresh == true
    test_passed = test_passed or fat_id.elevation == 130
    test_passed = test_passed or fat_id.grass == 60
    test_passed = test_passed or fat_id.shrub == 253
    test_passed = test_passed or fat_id.conifer == 230
    test_passed = test_passed or fat_id.broadleaf == 241
    test_passed = test_passed or fat_id.ideal_grass == 194
    test_passed = test_passed or fat_id.ideal_shrub == 107
    test_passed = test_passed or fat_id.ideal_conifer == 48
    test_passed = test_passed or fat_id.ideal_broadleaf == 249
    test_passed = test_passed or fat_id.silt == 14
    test_passed = test_passed or fat_id.clay == 199
    test_passed = test_passed or fat_id.sand == 221
    test_passed = test_passed or fat_id.soil_minerals == 1
    test_passed = test_passed or fat_id.soil_organics == 228
    test_passed = test_passed or fat_id.january_waterflow == 136
    test_passed = test_passed or fat_id.july_waterflow == 117
    test_passed = test_passed or fat_id.waterlevel == 52
    test_passed = test_passed or fat_id.has_river == true
    test_passed = test_passed or fat_id.has_marsh == false
    test_passed = test_passed or fat_id.ice == 11
    test_passed = test_passed or fat_id.ice_age_ice == 13
    test_passed = test_passed or fat_id.debug_r == 4
    test_passed = test_passed or fat_id.debug_g == 195
    test_passed = test_passed or fat_id.debug_b == 110
    test_passed = test_passed or fat_id.real_r == 216
    test_passed = test_passed or fat_id.real_g == 14
    test_passed = test_passed or fat_id.real_b == 113
    test_passed = test_passed or fat_id.pathfinding_index == 224
    print("SET_GET_TEST_1_tile:")
    if test_passed then print("PASSED") else print("ERROR") end
end
function DATA.test_save_load_2()
    for i = 0, 2160000 do
        tile_is_land[i] = true
    end
    for i = 0, 2160000 do
        tile_is_fresh[i] = true
    end
    for i = 0, 2160000 do
        tile_elevation[i] = 43
    end
    for i = 0, 2160000 do
        tile_grass[i] = 184
    end
    for i = 0, 2160000 do
        tile_shrub[i] = 86
    end
    for i = 0, 2160000 do
        tile_conifer[i] = 157
    end
    for i = 0, 2160000 do
        tile_broadleaf[i] = 128
    end
    for i = 0, 2160000 do
        tile_ideal_grass[i] = 108
    end
    for i = 0, 2160000 do
        tile_ideal_shrub[i] = 18
    end
    for i = 0, 2160000 do
        tile_ideal_conifer[i] = 81
    end
    for i = 0, 2160000 do
        tile_ideal_broadleaf[i] = 220
    end
    for i = 0, 2160000 do
        tile_silt[i] = 201
    end
    for i = 0, 2160000 do
        tile_clay[i] = 190
    end
    for i = 0, 2160000 do
        tile_sand[i] = 227
    end
    for i = 0, 2160000 do
        tile_soil_minerals[i] = 137
    end
    for i = 0, 2160000 do
        tile_soil_organics[i] = 18
    end
    for i = 0, 2160000 do
        tile_january_waterflow[i] = 14
    end
    for i = 0, 2160000 do
        tile_july_waterflow[i] = 186
    end
    for i = 0, 2160000 do
        tile_waterlevel[i] = 238
    end
    for i = 0, 2160000 do
        tile_has_river[i] = false
    end
    for i = 0, 2160000 do
        tile_has_marsh[i] = true
    end
    for i = 0, 2160000 do
        tile_ice[i] = 216
    end
    for i = 0, 2160000 do
        tile_ice_age_ice[i] = 84
    end
    for i = 0, 2160000 do
        tile_debug_r[i] = 90
    end
    for i = 0, 2160000 do
        tile_debug_g[i] = 120
    end
    for i = 0, 2160000 do
        tile_debug_b[i] = 118
    end
    for i = 0, 2160000 do
        tile_real_r[i] = 12
    end
    for i = 0, 2160000 do
        tile_real_g[i] = 90
    end
    for i = 0, 2160000 do
        tile_real_b[i] = 166
    end
    for i = 0, 2160000 do
        tile_pathfinding_index[i] = 88
    end
    DATA.save_state()
    DATA.load_state()
    local test_passed = true
    for i = 0, 2160000 do
        test_passed = test_passed or tile_is_land[i] == true
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_is_fresh[i] == true
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_elevation[i] == 43
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_grass[i] == 184
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_shrub[i] == 86
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_conifer[i] == 157
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_broadleaf[i] == 128
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ideal_grass[i] == 108
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ideal_shrub[i] == 18
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ideal_conifer[i] == 81
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ideal_broadleaf[i] == 220
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_silt[i] == 201
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_clay[i] == 190
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_sand[i] == 227
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_soil_minerals[i] == 137
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_soil_organics[i] == 18
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_january_waterflow[i] == 14
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_july_waterflow[i] == 186
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_waterlevel[i] == 238
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_has_river[i] == false
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_has_marsh[i] == true
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ice[i] == 216
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_ice_age_ice[i] == 84
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_debug_r[i] == 90
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_debug_g[i] == 120
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_debug_b[i] == 118
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_real_r[i] == 12
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_real_g[i] == 90
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_real_b[i] == 166
    end
    for i = 0, 2160000 do
        test_passed = test_passed or tile_pathfinding_index[i] == 88
    end
    print("SAVE_LOAD_TEST_2:")
    if test_passed then print("PASSED") else print("ERROR") end
end
function DATA.test_set_get_2()
    local fat_id = DATA.fatten_tile(0)
    fat_id.is_land = true
    fat_id.is_fresh = true
    fat_id.elevation = 43
    fat_id.grass = 184
    fat_id.shrub = 86
    fat_id.conifer = 157
    fat_id.broadleaf = 128
    fat_id.ideal_grass = 108
    fat_id.ideal_shrub = 18
    fat_id.ideal_conifer = 81
    fat_id.ideal_broadleaf = 220
    fat_id.silt = 201
    fat_id.clay = 190
    fat_id.sand = 227
    fat_id.soil_minerals = 137
    fat_id.soil_organics = 18
    fat_id.january_waterflow = 14
    fat_id.july_waterflow = 186
    fat_id.waterlevel = 238
    fat_id.has_river = false
    fat_id.has_marsh = true
    fat_id.ice = 216
    fat_id.ice_age_ice = 84
    fat_id.debug_r = 90
    fat_id.debug_g = 120
    fat_id.debug_b = 118
    fat_id.real_r = 12
    fat_id.real_g = 90
    fat_id.real_b = 166
    fat_id.pathfinding_index = 88
    local test_passed = true
    test_passed = test_passed or fat_id.is_land == true
    test_passed = test_passed or fat_id.is_fresh == true
    test_passed = test_passed or fat_id.elevation == 43
    test_passed = test_passed or fat_id.grass == 184
    test_passed = test_passed or fat_id.shrub == 86
    test_passed = test_passed or fat_id.conifer == 157
    test_passed = test_passed or fat_id.broadleaf == 128
    test_passed = test_passed or fat_id.ideal_grass == 108
    test_passed = test_passed or fat_id.ideal_shrub == 18
    test_passed = test_passed or fat_id.ideal_conifer == 81
    test_passed = test_passed or fat_id.ideal_broadleaf == 220
    test_passed = test_passed or fat_id.silt == 201
    test_passed = test_passed or fat_id.clay == 190
    test_passed = test_passed or fat_id.sand == 227
    test_passed = test_passed or fat_id.soil_minerals == 137
    test_passed = test_passed or fat_id.soil_organics == 18
    test_passed = test_passed or fat_id.january_waterflow == 14
    test_passed = test_passed or fat_id.july_waterflow == 186
    test_passed = test_passed or fat_id.waterlevel == 238
    test_passed = test_passed or fat_id.has_river == false
    test_passed = test_passed or fat_id.has_marsh == true
    test_passed = test_passed or fat_id.ice == 216
    test_passed = test_passed or fat_id.ice_age_ice == 84
    test_passed = test_passed or fat_id.debug_r == 90
    test_passed = test_passed or fat_id.debug_g == 120
    test_passed = test_passed or fat_id.debug_b == 118
    test_passed = test_passed or fat_id.real_r == 12
    test_passed = test_passed or fat_id.real_g == 90
    test_passed = test_passed or fat_id.real_b == 166
    test_passed = test_passed or fat_id.pathfinding_index == 88
    print("SET_GET_TEST_2_tile:")
    if test_passed then print("PASSED") else print("ERROR") end
end
return DATA
