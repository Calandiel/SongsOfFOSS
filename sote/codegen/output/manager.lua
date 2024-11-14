local ffi = require("ffi")
---manage dll loading


if love.system.getOS() == "Windows" then
	local dll_path = love.filesystem.getSourceBaseDirectory() .. "/sote/codegen/dll/win/"
	DCON = ffi.load(dll_path .. "dcon.dll")
else
	local dll_path = love.filesystem.getSourceBaseDirectory() .. "/sote/codegen/dll/linux/"
	DCON = ffi.load(dll_path .. "dcon.so")
end


-- local dll_path = "C:/_projects/dcon/DataContainer/x64/Debug/"
-- DCON = ffi.load(dll_path .. "lua_dll_build_test.dll")

assert(DCON, "FAILED_TO_LOAD_DLL")

-- SHOULD BE CHANGED TOGETHER WITH ACCORDING VALUE IN cpp FILE
POP_BUY_PRICE_MULTIPLIER = 3

ffi.cdef[[
    void* calloc( size_t num, size_t size );
    void update_vegetation(float);
    void update_economy();
    void apply_biome(int32_t);
    float estimate_province_use_price(uint32_t, uint32_t);
    float estimate_building_type_income(int32_t, int32_t, int32_t, bool);
    void dcon_everything_write_file(char const* name);
    void dcon_everything_read_file(char const* name);
    void update_foraging_data(
		int32_t province_raw_id,
		int32_t water_raw_id,
		int32_t berries_raw_id,
		int32_t grain_raw_id,
		int32_t bark_raw_id,
		int32_t timber_raw_id,
		int32_t meat_raw_id,
		int32_t hide_raw_id,
		int32_t mushroom_raw_id,
		int32_t shellfish_raw_id,
		int32_t seaweed_raw_id,
		int32_t fish_raw_id,
		int32_t world_size
	);

    void load_state(char const*);
    int32_t dcon_reset();

    void update_map_mode_pointer(uint8_t* map, uint32_t world_size);
    int32_t get_neighbor(int32_t tile_id, uint8_t neighbor_index, uint32_t world_size);
]]


DATA = require "codegen.output.generated"
require "codegen.output.helpers"

local state_save_path = love.filesystem.getSaveDirectory() .. "_sote_save.binbeaver"
function SAVE_GAME_STATE()
    DCON.dcon_everything_write_file(state_save_path)
    DATA.save_state()
end
function LOAD_GAME_STATE()
    print("loading dll state")
    local start = love.timer.getTime()
    --DCON.dcon_everything_read_file(state_save_path)
    DCON.load_state(state_save_path)
    print(tostring(love.timer.getTime() - start) .. " seconds")

    print("loading lua state")
    start = love.timer.getTime()
    DATA.load_state()
    print(tostring(love.timer.getTime() - start) .. " seconds")

    print("state loaded, restoring unsaved data")
    start = love.timer.getTime()
    RESTORE_UNSAVED_TILES_DATA()
    REGENERATE_RAWS()
    RECALCULATE_WEIGHTS_TABLE()
    print(tostring(love.timer.getTime() - start) .. " seconds")
end
