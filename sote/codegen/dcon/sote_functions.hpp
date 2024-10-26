#pragma once
#include <stdint.h>
#include "objs.hpp"

#ifdef DCON_LUADLL_EXPORTS
#define DCON_LUADLL_API __declspec(dllexport)
#else
#define DCON_LUADLL_API __declspec(dllimport)
#endif

extern "C" {
	DCON_LUADLL_API void update_vegetation(float);
	DCON_LUADLL_API void apply_biome(int32_t);
	DCON_LUADLL_API void update_economy();
}