//
// This file was automatically generated from: objs.txt
// EDIT AT YOUR OWN RISK; all changes will be lost upon regeneration
// NOT SUITABLE FOR USE IN CRITICAL SOFTWARE WHERE LIVES OR LIVELIHOODS DEPEND ON THE CORRECT OPERATION
//

#include "lua_objs.hpp"

DCON_LUADLL_API dcon::data_container state;

int32_t thingy_is_valid(lua_State *L) { 
	 auto index = dcon::thingy_id{dcon::thingy_id::value_base_t(lua_tointeger(L, 1))};
	 bool result = state.thingy_is_valid(index);
	 lua_pushboolean(L, result);
	 return 1;
 }
int32_t thingy_size(lua_State *L) { 
	 auto result = state.thingy_size();
	 lua_pushinteger(L, lua_Integer(result));
	 return 1;
 }
int32_t thingy_resize(lua_State *L) { 
	 auto sz = uint32_t(lua_tointeger(L, 1));
	 state.thingy_resize(sz);
	 return 0;
 }
int32_t thingy_get_some_value(lua_State *L) { 
	 auto index = dcon::thingy_id{dcon::thingy_id::value_base_t(lua_tointeger(L, 1))};
	 auto result = state.thingy_get_some_value(index);
	 lua_pushinteger(L, lua_Integer(result));
	 return 1;
 }
int32_t thingy_set_some_value(lua_State *L) { 
	 auto index = dcon::thingy_id{dcon::thingy_id::value_base_t(lua_tointeger(L, 1))};
	 auto data = int32_t(lua_tointeger(L, 2));
	 state.thingy_set_some_value(index, data);
	 return 0;
 }
int32_t thingy_get_lua_value(lua_State *L) { 
	 auto index = dcon::thingy_id{dcon::thingy_id::value_base_t(lua_tointeger(L, 1))};
	 auto result = state.thingy_get_lua_value(index);
	 if(result == 0)
		 lua_pushnil(L);
	 else
		 lua_rawgeti(L, LUA_REGISTRYINDEX, result ^ LUA_REFNIL);
	 return 1;
 }
int32_t thingy_set_lua_value(lua_State *L) { 
	 auto index = dcon::thingy_id{dcon::thingy_id::value_base_t(lua_tointeger(L, 1))};
	 auto result = state.thingy_get_lua_value(index);
	 if(result != 0) luaL_unref(L, LUA_REGISTRYINDEX, LUA_REFNIL ^ result);
	 auto data = LUA_REFNIL ^ lua_reference_type(luaL_ref(L, LUA_REGISTRYINDEX));
	 lua_pushnil(L);
	 state.thingy_set_lua_value(index, data);
	 return 0;
 }
int32_t thingy_get_big_array(lua_State *L) { 
	 auto index = dcon::thingy_id{dcon::thingy_id::value_base_t(lua_tointeger(L, 1))};
	 auto sub_index = dcon::thingy_id{dcon::thingy_id::value_base_t(lua_tointeger(L, 2))};
	 auto result = state.thingy_get_big_array(index, sub_index);
	 lua_pushnumber(L, lua_Number(result));
	 return 1;
 }
int32_t thingy_set_big_array(lua_State *L) { 
	 auto index = dcon::thingy_id{dcon::thingy_id::value_base_t(lua_tointeger(L, 1))};
	 auto sub_index = dcon::thingy_id{dcon::thingy_id::value_base_t(lua_tointeger(L, 2))};
	 auto data = float(lua_tonumber(L, 2));
	 state.thingy_set_big_array(index, sub_index, data);
	 return 0;
 }
int32_t thingy_get_big_array_size(lua_State *L) { 
	 bool result = state.thingy_get_big_array_size();
	 lua_pushinteger(L, lua_Integer(result));
	 return 1;
 }
int32_t thingy_resize_big_array(lua_State *L) { 
	 state.thingy_resize_big_array(uint32_t(lua_tointeger(L, 1)));
	 return 0;
 }
int32_t thingy_get_big_array_bf(lua_State *L) { 
	 auto index = dcon::thingy_id{dcon::thingy_id::value_base_t(lua_tointeger(L, 1))};
	 auto sub_index = int32_t(lua_tointeger(L, 2));
	 auto result = state.thingy_get_big_array_bf(index, sub_index);
	 lua_pushboolean(L, result);
	 return 1;
 }
int32_t thingy_set_big_array_bf(lua_State *L) { 
	 auto index = dcon::thingy_id{dcon::thingy_id::value_base_t(lua_tointeger(L, 1))};
	 auto sub_index = int32_t(lua_tointeger(L, 2));
	 auto data = bool(lua_toboolean(L, 2));
	 state.thingy_set_big_array_bf(index, sub_index, data);
	 return 0;
 }
int32_t thingy_get_big_array_bf_size(lua_State *L) { 
	 bool result = state.thingy_get_big_array_bf_size();
	 lua_pushinteger(L, lua_Integer(result));
	 return 1;
 }
int32_t thingy_resize_big_array_bf(lua_State *L) { 
	 state.thingy_resize_big_array_bf(uint32_t(lua_tointeger(L, 1)));
	 return 0;
 }

int32_t pop_back_thingy(lua_State *L) { 
	 if(state.thingy_size() > 0) {
		 auto index = dcon::thingy_id{dcon::thingy_id::value_base_t(state.thingy_size()) - 1};
		 if(auto result = state.thingy_get_lua_value(index); result != 0) luaL_unref(L, LUA_REGISTRYINDEX, LUA_REFNIL ^ result);
	 state.pop_back_thingy();
	 }
	 return 0;
 }
int32_t create_thingy(lua_State* L) { 
	 auto result = state.create_thingy();
	 lua_pushinteger(L, lua_Integer(result.index()));
	 return 1;
 }
int32_t delete_thingy(lua_State *L) { 
	 auto index = dcon::thingy_id{dcon::thingy_id::value_base_t(lua_tointeger(L, 1))};
	 if(auto result = state.thingy_get_lua_value(index); result != 0) luaL_unref(L, LUA_REGISTRYINDEX, LUA_REFNIL ^ result);
	 state.delete_thingy(index);
	 return 0;
 }

int32_t reset(lua_State* L) { 
	 state.reset();
	 return 0;
 }
luaL_Reg lib_contents[] = {
	{"dcon_thingy_is_valid" , thingy_is_valid}, 
	{"dcon_thingy_size" , thingy_size}, 
	{"dcon_thingy_resize" , thingy_resize}, 
	{"dcon_thingy_get_some_value" , thingy_get_some_value}, 
	{"dcon_thingy_set_some_value" , thingy_set_some_value}, 
	{"dcon_thingy_get_lua_value" , thingy_get_lua_value}, 
	{"dcon_thingy_set_lua_value" , thingy_set_lua_value}, 
	{"dcon_thingy_get_big_array" , thingy_get_big_array}, 
	{"dcon_thingy_set_big_array" , thingy_set_big_array}, 
	{"dcon_thingy_get_big_array_size" , thingy_get_big_array_size}, 
	{"dcon_thingy_resize_big_array" , thingy_resize_big_array}, 
	{"dcon_thingy_get_big_array_bf" , thingy_get_big_array_bf}, 
	{"dcon_thingy_set_big_array_bf" , thingy_set_big_array_bf}, 
	{"dcon_thingy_get_big_array_bf_size" , thingy_get_big_array_bf_size}, 
	{"dcon_thingy_resize_big_array_bf" , thingy_resize_big_array_bf}, 
	{"dcon_pop_back_thingy" , pop_back_thingy}, 
	{"dcon_create_thingy" , create_thingy}, 
	{"dcon_delete_thingy" , delete_thingy}, 
	{"dcon_reset" , reset}, 
{nullptr, nullptr} };

LUALIB_API int32_t luaopen_lua_objs(lua_State *L) { 
	 luaL_register(L, "lua_objs", lib_contents);
	 return 1; 
}

