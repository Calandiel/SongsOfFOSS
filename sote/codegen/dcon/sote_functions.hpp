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
	DCON_LUADLL_API float estimate_province_use_price(uint32_t, uint32_t);
	DCON_LUADLL_API float estimate_province_use_available(uint32_t, uint32_t);
	DCON_LUADLL_API float estimate_building_type_income(int32_t, int32_t, int32_t, bool);
	DCON_LUADLL_API int32_t roll_desired_building_type_for_pop(int32_t);
}