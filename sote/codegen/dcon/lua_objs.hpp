#pragma once

//
// This file was automatically generated from: objs.txt
// EDIT AT YOUR OWN RISK; all changes will be lost upon regeneration
// NOT SUITABLE FOR USE IN CRITICAL SOFTWARE WHERE LIVES OR LIVELIHOODS DEPEND ON THE CORRECT OPERATION
//

#include <stdint.h>
using lua_reference_type = int32_t;
#include "objs.hpp"
#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"
#ifdef DCON_LUADLL_EXPORTS
#define DCON_LUADLL_API __declspec(dllexport)
#else
#define DCON_LUADLL_API __declspec(dllimport)
#endif

extern DCON_LUADLL_API dcon::data_container state;

LUALIB_API int32_t luaopen_lua_objs(lua_State *L); 
