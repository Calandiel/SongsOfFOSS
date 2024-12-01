#pragma once
#include <stdint.h>
#include "objs.hpp"

#ifdef DCON_LUADLL_EXPORTS
#ifdef _WIN32
#define DCON_LUADLL_API __declspec(dllexport)
#else
#define DCON_LUADLL_API __attribute__((visibility("default")))
#endif
#else
#ifdef _WIN32
#define DCON_LUADLL_API __declspec(dllimport)
#else
#define DCON_LUADLL_API
#endif
#endif

extern "C" {
	DCON_LUADLL_API void update_vegetation(float);
	DCON_LUADLL_API void apply_biome(int32_t);
	DCON_LUADLL_API void apply_resource(int32_t);
	DCON_LUADLL_API void update_economy();
	DCON_LUADLL_API float estimate_province_use_price(uint32_t, uint32_t);
	DCON_LUADLL_API float estimate_province_use_available(uint32_t, uint32_t);
	DCON_LUADLL_API float estimate_building_type_income(int32_t, int32_t, int32_t, bool);
	DCON_LUADLL_API int32_t roll_desired_building_type_for_pop(int32_t);
	DCON_LUADLL_API void update_foraging_data(
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

	DCON_LUADLL_API void load_state(char const*);
	DCON_LUADLL_API void update_map_mode_pointer(uint8_t* map, uint32_t world_size);
	DCON_LUADLL_API int32_t get_neighbor(int32_t tile_id, uint8_t neighbor_index, uint32_t world_size);
}
