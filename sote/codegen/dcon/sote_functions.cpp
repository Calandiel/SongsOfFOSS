#include <cstdint>
#include <iostream>
#include <limits>
#include <ppl.h>
#include "objs.hpp"
#include "sote_types.hpp"
#define DCON_LUADLL_EXPORTS
#include "sote_functions.hpp"
#include "lua_objs.hpp"


// void save_to_file() {
// 	state.make_s
// }

static auto GOOD_CATEGORY = (uint8_t)((base_types::TRADE_GOOD_CATEGORY::GOOD));

constexpr inline float MAX_INDUCED_DEMAND = 100.f;

float forage_efficiency(float foragers, float carrying_capacity) {
	if (foragers > carrying_capacity) {
		return carrying_capacity / (foragers + 1);
	} else {
		return 2 - expf(-0.7*(carrying_capacity - foragers)/carrying_capacity);
	}
}

float age_multiplier(dcon::pop_id pop) {
	auto age_multiplier = 1.f;
	auto age = state.pop_get_age(pop);
	auto race = state.pop_get_race(pop);

	auto child_age = state.race_get_child_age(race);
	auto teen_age = state.race_get_teen_age(race);
	auto adult_age = state.race_get_adult_age(race);
	auto middle_age = state.race_get_middle_age(race);
	auto elder_age = state.race_get_elder_age(race);
	auto max_age = state.race_get_max_age(race);

	if (age < child_age) {
		age_multiplier = 0.25;
	} else if (age < teen_age) {
		age_multiplier = 0.5;
	} else if (age < adult_age) {
		age_multiplier = 0.75;
	} else if (age < middle_age) {
		age_multiplier = 1;
	} else if (age < elder_age) {
		age_multiplier = 0.95;
	} else if (age < max_age) {
		age_multiplier = 0.9;
	}
	return age_multiplier;
}

float job_efficiency(dcon::race_id race, bool female, uint8_t jobtype) {
	if (female) {
		return state.race_get_female_efficiency(race, jobtype) ;
	}
	return state.race_get_male_efficiency(race, jobtype);
}

float job_efficiency(dcon::pop_id pop, uint8_t jobtype) {
	return job_efficiency(
		state.pop_get_race(pop),
		state.pop_get_female(pop),
		jobtype
	) * age_multiplier(pop);
}

void update_vegetation(float speed) {
	state.execute_serial_over_tile([speed](auto ids) {
		auto conifer = state.tile_get_conifer(ids);
		auto broadleaf = state.tile_get_broadleaf(ids);
		auto shrub = state.tile_get_shrub(ids);
		auto grass = state.tile_get_grass(ids);

		auto ideal_conifer = state.tile_get_ideal_conifer(ids);
		auto ideal_broadleaf = state.tile_get_ideal_broadleaf(ids);
		auto ideal_shrub = state.tile_get_ideal_shrub(ids);
		auto ideal_grass = state.tile_get_ideal_grass(ids);

		state.tile_set_conifer(ids, conifer * (1.f - speed) + ideal_conifer * speed);
		state.tile_set_broadleaf(ids, broadleaf * (1.f - speed) + ideal_broadleaf * speed);
		state.tile_set_shrub(ids, shrub * (1.f - speed) + ideal_shrub * speed);
		state.tile_set_grass(ids, grass * (1.f - speed) + ideal_grass * speed);
	});
}

template<typename T>
ve::fp_vector get_permeability(T tile_id) {
	ve::fp_vector tile_perm = 2.5f;
	auto sand = state.tile_get_sand(tile_id);
	auto silt = state.tile_get_silt(tile_id);
	auto clay = state.tile_get_clay(tile_id);

	tile_perm = ve::select(sand > 0.15f, tile_perm - 2.f * (sand - 0.15f) / (1.0f - 0.15f), tile_perm);
	tile_perm = ve::select(silt > 0.85f, tile_perm - 2.f * (sand - 0.15f) / (1.0f - 0.15f), tile_perm);
	tile_perm = ve::select(clay > 0.2f, tile_perm - 1.25f * (clay - 0.2f) / (1.0f - 0.2f), tile_perm);

	return tile_perm / 2.5f;
}

void apply_biome(int32_t biome_index) {
	dcon::biome_fat_id biome = dcon::fatten(state, dcon::biome_id{(uint8_t)biome_index});

	state.execute_parallel_over_tile([&biome](auto ids) {

		auto trees = state.tile_get_broadleaf(ids) + state.tile_get_conifer(ids);
		auto dead_land = 1 - trees - state.tile_get_shrub(ids) - state.tile_get_grass(ids);
		auto conifer_fraction = ve::select(trees == 0, 0.5f, state.tile_get_conifer(ids) / trees);

		auto jan_temp = state.tile_get_january_temperature(ids);
		auto jan_rain = state.tile_get_january_rain(ids);
		auto jul_temp = state.tile_get_july_temperature(ids);
		auto jul_rain = state.tile_get_july_temperature(ids);

		auto rain = (jan_rain + jul_rain) * 0.5f;
		auto temperature = (jan_temp + jul_temp) / 2;
		auto summer_temperature = ve::max(jan_temp, jul_temp);
		auto winter_temperature = ve::min(jan_temp, jul_temp);

		auto permeability = get_permeability(ids);

		auto available_water = rain * 2 * permeability;

		auto soil_depth = state.tile_get_sand(ids) + state.tile_get_silt(ids) + state.tile_get_clay(ids);

		ve::mask_vector biome_mask =
			(
				(
					(
						(
							(
								state.tile_get_slope(ids) > biome.get_minimum_slope()
							&&
								state.tile_get_slope(ids) < biome.get_maximum_slope()
							)
						&&
							(
								state.tile_get_is_land(ids) != biome.get_aquatic()
							&&
								state.tile_get_has_marsh(ids) == biome.get_marsh()
							)
						)
					&&
						(
							(
								state.tile_get_elevation(ids) > biome.get_minimum_elevation()
							&&
								state.tile_get_elevation(ids) < biome.get_maximum_elevation()
							)
						&&
							(
								state.tile_get_sand(ids) > biome.get_minimum_sand()
							&&
								state.tile_get_sand(ids) < biome.get_maximum_sand()
							)
						)
					)
				&&
					(
						(
							(
								state.tile_get_clay(ids) > biome.get_minimum_clay()
							&&
								state.tile_get_clay(ids) < biome.get_maximum_clay()
							)
						&&
							(
								state.tile_get_silt(ids) > biome.get_minimum_silt()
							&&
								state.tile_get_silt(ids) < biome.get_maximum_silt()
							)
						)
					&&
						(
							(
								state.tile_get_shrub(ids) > biome.get_minimum_shrubs()
							&&
								state.tile_get_shrub(ids) < biome.get_maximum_shrubs()
							)
						&&
							(
								state.tile_get_grass(ids) > biome.get_minimum_grass()
							&&
								state.tile_get_grass(ids) < biome.get_maximum_grass()
							)
						)
					)
				)
			&&
				(
					(
						(
							(
								trees > biome.get_minimum_trees()
							&&
								trees < biome.get_maximum_trees()
							)
						&&
							(
								dead_land > biome.get_minimum_dead_land()
							&&
								dead_land < biome.get_maximum_dead_land()
							)
						)
					&&
						(
							(
								conifer_fraction > biome.get_minimum_conifer_fraction()
							&&
								conifer_fraction < biome.get_maximum_conifer_fraction()
							)
						&&
							(
								rain > biome.get_minimum_rain()
							&&
								rain < biome.get_maximum_rain()
							)
						)
					)
				&&
					(
						(
							(
								temperature > biome.get_minimum_temperature()
							&&
								temperature < biome.get_maximum_temperature()
							)
						&&
							(
								summer_temperature > biome.get_minimum_summer_temperature()
							&&
								summer_temperature < biome.get_maximum_summer_temperature()
							)
						)
					&&
						(
							(
								winter_temperature > biome.get_minimum_winter_temperature()
							&&
								winter_temperature < biome.get_maximum_winter_temperature()
							)
						// &&
						// 	(
						// 		state.tile_get_shrub(ids) > biome.get_minimum_grass()
						// 	&&
						// 		state.tile_get_shrub(ids) < biome.get_maximum_grass()
						// 	)
						)
					)
				)
			)
		&&
			(
				(
					(
						(
							available_water > biome.get_minimum_available_water()
						)
						&&
						(
							available_water < biome.get_maximum_available_water()
						)
					)
					&&
					(
						(
							soil_depth > biome.get_minimum_soil_depth()
						)
						&&
						(
							soil_depth < biome.get_maximum_soil_depth()
						)
					)
				)
				&&
				(
					(
						state.tile_get_soil_minerals(ids) > biome.get_minimum_soil_richness()
						&&
						state.tile_get_soil_minerals(ids) < biome.get_maximum_soil_richness()
					)
					&&
					biome.get_icy() == (state.tile_get_ice(ids) > 0.001)
				)
			);

		ve::value_to_vector_type<dcon::biome_id> current = state.tile_get_biome(ids);
		ve::value_to_vector_type<dcon::biome_id> candidate = biome.id;

		state.tile_set_biome(ids, ve::select(biome_mask, candidate, current));
	});
}


// how much of income is siphoned to local wealth pool
constexpr inline float INCOME_TO_LOCAL_WEALTH_MULTIPLIER = 0.125f / 4.f;

// buying prices for pops are multiplied on this number
constexpr inline float POP_BUY_PRICE_MULTIPLIER = 1.5f;

// pops work at least this time
constexpr inline float MINIMAL_WORKING_RATIO = 0.2f;

constexpr inline float spending_ratio = 0.1f;

float price_score(float price) {
	return expf(-price);
}
ve::fp_vector price_score(ve::fp_vector price) {
	return ve::apply<float(float), ve::fp_vector>(price_score, price);
}

float get_normalizing_coefficient_use_case(dcon::use_case_id use, dcon::province_id provinces) {
	auto total_exp = 0.f;
	state.use_case_for_each_use_weight(use, [&](dcon::use_weight_id weight_id) {
		auto trade_good = state.use_weight_get_trade_good(weight_id);
		auto price = state.province_get_local_prices(provinces, trade_good);
		auto weight = state.use_weight_get_weight(weight_id);

		total_exp = total_exp + price_score(price / weight);
	});

	return total_exp;
}

// this function calculates how much money pop is ready to pay for 1 unit of use case
// if price is high, we do not buy this good
// we divide price by weight because $1$ unit of good convers to $weight$ units of use
float get_price_integral_use_case(dcon::use_case_id use, dcon::province_id province) {
	auto integral = 0.f;
	state.use_case_for_each_use_weight(use, [&](dcon::use_weight_id weight_id) {
		auto trade_good = state.use_weight_get_trade_good(weight_id);
		auto price = state.province_get_local_prices(province, trade_good);
		auto weight = state.use_weight_get_weight(weight_id);

		integral = integral + price_score(price / weight);
	});
	return integral;
}

float record_production(dcon::province_id province, dcon::trade_good_id trade_good, float amount) {
	assert(amount >= 0.f);

	auto current = state.province_get_local_production(province, trade_good);
	state.province_set_local_production(province, trade_good, current + amount);

	auto price = state.province_get_local_prices(province, trade_good);
	return price * amount;
}

float record_demand(dcon::province_id province, dcon::trade_good_id trade_good, float amount) {
	assert(amount >= 0.f);

	auto current = state.province_get_local_demand(province, trade_good);
	state.province_set_local_demand(province, trade_good, current + amount);

	auto price = state.province_get_local_prices(province, trade_good);
	return price * amount;
}

void record_use_demand(dcon::province_id province, dcon::use_case_id use_case, float amount) {
	assert(amount >= 0.f);

	auto current = state.province_get_local_use_buffer_demand(province, use_case);
	state.province_set_local_use_buffer_demand(province, use_case, current + amount);
}

void pops_produce() {
	// recalculate buildings-based foragers

	state.for_each_province([&](auto province) {
		state.province_set_foragers(province, 0);
	});

	state.for_each_building([&](auto building) {
		auto btype = state.building_get_current_type(building);
		auto production_method = state.building_type_get_production_method(btype);

		if (state.production_method_get_foraging(production_method)){
			auto province = state.building_get_location_from_building_location(building);
			state.province_get_foragers(province) += state.building_get_production_scale(building);
		}
	});
	state.for_each_pop([&](auto ids) {
		auto province = state.pop_get_location_from_pop_location(ids);
		state.province_get_foragers(province) += state.pop_get_forage_ratio(ids);
	});

	state.for_each_province([&](auto province) {
		state.province_set_forage_efficiency(province, forage_efficiency(
			state.province_get_foragers(province),
			state.province_get_foragers_limit(province)
		));
	});

	state.for_each_pop([&](auto ids) {
		auto province = state.pop_get_location_from_pop_location(ids);

		auto size = state.province_get_size(province);

		auto forage_time = state.pop_get_forage_ratio(ids);

		// std::cout << "forage ratio: " << forage_time << "\n";

		for (uint32_t i = 0; i < state.province_get_foragers_targets_size(); i++){
			base_types::forage_container& forage_case = state.province_get_foragers_targets(province, i);

			auto output = dcon::trade_good_id{dcon::trade_good_id::value_base_t(int32_t(forage_case.output_good - 1))};

			if (!output) {
				break;
			}

			auto current = state.pop_get_inventory(ids, output);

			// std::cout << "forage: " << forage_case.output_value * forage_case.amount * forage_time << "\n";

			// assert(current >= 0.f);
			// assert(forage_case.output_value >= 0.f);
			// assert(forage_case.amount >= 0.f);
			// assert(forage_time >= 0.f);

			auto culture = state.pop_get_culture(ids);
			auto cultural_priority = state.culture_get_traditional_forager_targets(culture, (uint8_t)((int)(forage_case.forage) - 1));

			dcon::forage_resource_id resource {(dcon::forage_resource_id::value_base_t)(forage_case.forage)};
			auto amount = forage_case.amount;

			if (amount == 0) {
				continue;
			}

			auto output_value = forage_case.output_value;
			auto efficiency =
				job_efficiency(ids, state.forage_resource_get_handle(resource));

			auto speed = 10.f;
			// time to find a resource
			auto search_time_per_unit = size / amount / speed;

			// time to gather the resource when it's found
			auto handle_time_per_unit = 1 / efficiency;

			//time required to gather and find one unit of resource
			auto total_time_per_unit = search_time_per_unit + handle_time_per_unit;

			// how many units of goods one unit of resource yields
			auto output_per_unit = forage_case.output_value;

			state.pop_set_inventory(
				ids,
				output,
				current
				+ output_per_unit
				/ total_time_per_unit
				* forage_time
				* cultural_priority
				* state.province_get_forage_efficiency(province)
			);
		}
	});
}

void update_building_scale() {
	state.for_each_building([&](auto ids){
		auto province = state.building_get_location_from_building_location(ids);

		float scale = 0.f;
		float input_scale = 0.f;
		float output_scale = 0.f;

		auto btype = state.building_get_current_type(ids);
		auto production_method = state.building_type_get_production_method(btype);
		auto associated_job = state.production_method_get_job_type(production_method);

		state.building_for_each_employment(ids, [&](auto employment){
			auto worker = state.employment_get_worker(employment);
			auto worktime = state.pop_get_work_ratio(worker);
			auto efficiency = job_efficiency(worker, associated_job);
			scale += worktime * efficiency;
			output_scale += worktime * efficiency * efficiency;
			input_scale += worktime * efficiency;
		});


		state.building_set_production_scale(ids, scale * state.province_get_throughput_boosts(province, production_method));
		state.building_set_output_scale(ids,
			output_scale
			* (1 + state.province_get_output_efficiency_boosts(province, production_method))
		);
		state.building_set_input_scale(ids,
			input_scale
			* (1 - state.province_get_input_efficiency_boosts(province, production_method))
		);
	});
}

void building_produce() {
	static auto inputs_buffer = state.trade_good_make_vectorizable_float_buffer();
	state.for_each_building([&](auto ids){
		auto building_type = state.building_get_current_type(ids);
		auto production_method = state.building_type_get_production_method(building_type);
		auto input_scale = state.building_get_input_scale(ids);
		auto output_scale = state.building_get_output_scale(ids);
		auto province = state.building_get_location_from_building_location(ids);

		auto min_input = 1.f;

		// actual consumption:

		for (uint32_t i = 0; i < state.production_method_get_inputs_size(); i++) {
			base_types::use_case_container input = state.production_method_get_inputs(production_method, i);
			if (input.use == 0) break;

			float use_required = input_scale * input.amount;

			// auto have_to_satisfy = input.amount * input_scale;
			float use_in_inventory = 0.f;

			state.use_case_for_each_use_weight_as_use_case(dcon::use_case_id{(uint8_t)(input.use - 1)}, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);

				// try to consume and write consumption to the buffer
				auto inventory = state.building_get_inventory(ids, trade_good) - inputs_buffer.get(trade_good);

				if (use_in_inventory + inventory * weight < use_required) {
					state.building_set_inventory(ids, trade_good, 0.f);
					use_in_inventory += inventory * weight;
				} else {
					state.building_set_inventory(ids, trade_good, inventory - (use_required - use_in_inventory) / weight);
					use_in_inventory = use_required;
				}
			});

			min_input = std::min(min_input, use_in_inventory / input.amount);

			base_types::use_case_container& stats = state.building_get_amount_of_inputs(ids, i);
			stats.amount = min_input * input_scale * input.amount;
		}

		// actual production

		for (uint32_t i = 0; i < state.production_method_get_outputs_size(); i++) {
			base_types::trade_good_container& output = state.production_method_get_outputs(production_method, i);
			if(!output.good) {
				break;
			}
			auto good = dcon::trade_good_id{dcon::trade_good_id::value_base_t(output.good - 1)};
			auto inventory = state.building_get_inventory(ids, good);


			state.building_set_inventory(ids, good, inventory + output.amount * output_scale * min_input);

			base_types::trade_good_container& stats = state.building_get_amount_of_outputs(ids, i);
			stats.amount = min_input * input_scale * output.amount;
			stats.good = output.good;

			base_types::trade_good_container& stats_earning = state.building_get_earn_from_outputs(ids, i);
			stats_earning.good = output.good;
			stats_earning.amount = output_scale * stats.amount * state.province_get_local_prices(province, good);
		}
	});
}

void pops_consume() {
	static auto uses_buffer = state.trade_good_category_make_vectorizable_float_buffer();

	state.for_each_pop([&](auto pop){
		auto parent = state.parent_child_relation_get_parent(state.pop_get_parent_child_relation_as_child(pop));
		if (parent) return;

		// std::cout << "pop: " << pop.index();

		for (uint32_t i = 0; i < state.pop_get_need_satisfaction_size(); i++) {
			base_types::need_satisfaction& need = state.pop_get_need_satisfaction(pop, i);
			// std::cout << "need: " << i << " " << need.use_case;

			if (need.use_case == 0)	break;

			auto demanded = need.demanded;

			state.pop_for_each_parent_child_relation_as_parent(pop, [&](auto child_rel) {
				auto child = state.parent_child_relation_get_child(child_rel);
				base_types::need_satisfaction& need_child = state.pop_get_need_satisfaction(child, i);
				demanded = demanded + need_child.demanded;
			});

			auto consumed = 0.f;
			auto use = dcon::use_case_id{dcon::use_case_id::value_base_t(need.use_case - 1)};

			state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);

				auto inventory = state.pop_get_inventory(pop, trade_good);
				auto can_consume = inventory * weight;

				if (consumed + can_consume > demanded) {
					assert(inventory >= std::max(0.f, (demanded - consumed) / weight));

					state.pop_set_inventory(pop, trade_good, inventory - std::max(0.f, (demanded - consumed) / weight));
					consumed = demanded;
				} else {
					consumed = consumed + can_consume;
					state.pop_set_inventory(pop, trade_good, 0.f);
				}
			});

			auto satisfaction = consumed / demanded;

			need.consumed = need.demanded * satisfaction;
			state.pop_for_each_parent_child_relation_as_parent(pop, [&](auto child_rel) {
				auto child = state.parent_child_relation_get_child(child_rel);
				base_types::need_satisfaction& need_child = state.pop_get_need_satisfaction(child, i);
				need_child.consumed = need.demanded * satisfaction;
			});
		}
	});
}

void pops_sell() {
	state.for_each_pop([&](auto pop) {
		auto province = state.pop_get_location_from_pop_location(pop);
		if (!province) {
			province = state.pop_get_location_from_pop_location(pop);
		}
		auto income = 0.f;
		state.for_each_trade_good([&](auto trade_good) {
			auto inventory = state.pop_get_inventory(pop, trade_good);
			income += inventory * 0.1f * state.province_get_local_prices(province, trade_good);
			state.pop_set_inventory(pop, trade_good, inventory * 0.9f);
			record_production(province, trade_good, inventory * 0.1f);
		});

		auto race = state.pop_get_race(pop);
		auto max_age = state.race_get_max_age(race);
		auto age = state.pop_get_age(pop);

		auto base_income = age / max_age;

		state.pop_set_pending_economy_income(pop, state.pop_get_pending_economy_income(pop) + income + base_income);
	});
}



void buildings_sell() {
	state.for_each_building([&](dcon::building_id building) {
		auto province = state.building_get_location_from_building_location(building);
		auto income = 0.f;
		state.for_each_trade_good([&](auto trade_good) {
			auto inventory = state.building_get_inventory(building, trade_good);
			auto sell_ratio = 1.f;
			if (state.trade_good_get_belongs_to_category(trade_good) == GOOD_CATEGORY) {
				sell_ratio = 0.1f;
			}

			income += inventory * sell_ratio * state.province_get_local_prices(province, trade_good);
			state.building_set_inventory(building, trade_good, inventory * (1.f - sell_ratio));
			record_production(province, trade_good, inventory * sell_ratio);
		});

		state.building_set_savings(building, state.building_get_savings(building) + income);

		state.building_get_last_income(building) += income;
	});
}

// pops buy everything
// useful for them according to prices
// usefulness depends on weight, price and total according need
void pops_demand() {
	state.for_each_pop([&](auto pop){
		auto province = state.pop_get_location_from_pop_location(pop);
		if (!province) {
			province = state.pop_get_location_from_pop_location(pop);
		}

		auto budget = state.pop_get_savings(pop) * 0.1f;
		auto total_score = 0.01f;
		auto total_cost = 0.f;

		for (uint32_t i = 0; i < state.pop_get_need_satisfaction_size(); i++) {
			base_types::need_satisfaction& need = state.pop_get_need_satisfaction(pop, i);
			if (need.use_case == 0)	break;
			auto use = dcon::use_case_id{dcon::use_case_id::value_base_t(need.use_case - 1)};
			state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);
				// auto demand_satisfaction = state.province_get_local_satisfaction(province, trade_good);

				auto price = state.province_get_local_prices(province, trade_good);
				auto score = need.demanded * price_score(price / weight);
				total_score += score;
				total_cost = need.demanded * score * price * POP_BUY_PRICE_MULTIPLIER;
			});
		};

		if (total_score == 0.f) return;


		auto scale = 1.f;
		if (total_cost > 0.f) {
			scale = std::min(MAX_INDUCED_DEMAND, budget / total_cost);
		}

		for (uint32_t i = 0; i < state.pop_get_need_satisfaction_size(); i++) {
			base_types::need_satisfaction& need = state.pop_get_need_satisfaction(pop, i);
			auto use = dcon::use_case_id{dcon::use_case_id::value_base_t(need.use_case - 1)};
			if (!use)	break;
			state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);
				// auto demand_satisfaction = state.province_get_local_satisfaction(province, trade_good);

				auto price = state.province_get_local_prices(province, trade_good);
				auto score = need.demanded * price_score(price / weight);
				auto distribution = score / total_score;

				auto demand = need.demanded * distribution * scale;

				record_demand(province, trade_good, demand);
			});
		};
	});
}

// same as for pops
void buildings_demand() {
	state.for_each_building([&](auto building){
		auto building_type = state.building_get_current_type(building);
		auto production_method = state.building_type_get_production_method(building_type);

		auto province = state.building_get_location_from_building_location(building);

		auto budget = state.building_get_savings(building) * 0.1f;
		auto total_score = 0.01f;
		auto total_cost = 0.f;

		for (uint32_t i = 0; i < state.production_method_get_inputs_size(); i++) {
			base_types::use_case_container& input = state.production_method_get_inputs(production_method, i);

			if(input.use == 0) break;

			auto use = dcon::use_case_id{dcon::use_case_id::value_base_t(input.use - 1)};

			state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);
				// auto demand_satisfaction = state.province_get_local_satisfaction(province, trade_good);

				auto price = state.province_get_local_prices(province, trade_good);
				auto score = input.amount * price_score(price / weight);
				total_score += score;
				total_cost = input.amount * score * price;
			});
		};

		if (total_score == 0.f) return;

		auto scale = 0.f;
		if (total_cost > 0.f) {
			scale = std::min(1.f, budget / total_cost);
		}

		for (uint32_t i = 0; i < state.production_method_get_inputs_size(); i++) {
			base_types::use_case_container& input = state.production_method_get_inputs(production_method, i);
			if(!input.use) break;
			auto use = dcon::use_case_id{dcon::use_case_id::value_base_t(input.use - 1)};
			state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);
				// auto demand_satisfaction = state.province_get_local_satisfaction(province, trade_good);

				auto price = state.province_get_local_prices(province, trade_good);
				auto score = input.amount * price_score(price / weight);
				auto distribution = score / total_score;
				assert(score >= 0.f);
				assert(total_score > 0.f);
				assert(scale >= 0.f);
				assert(input.amount >= 0.f);
				assert(distribution >= 0.f);

				auto demand = distribution * scale;
				assert(demand >= 0.f);
				record_demand(province, trade_good, demand);
			});
		};
	});
}

void pops_buy() {
	state.for_each_pop([&](auto pop){
		auto province = state.pop_get_location_from_pop_location(pop);
		if (!province) {
			province = state.pop_get_location_from_pop_location(pop);
		}

		auto budget = state.pop_get_savings(pop) * 0.1f;
		auto total_score = 0.01f;
		auto total_cost = 0.f;

		for (uint32_t i = 0; i < state.pop_get_need_satisfaction_size(); i++) {
			base_types::need_satisfaction& need = state.pop_get_need_satisfaction(pop, i);

			if (need.use_case == 0) break;

			auto use = dcon::use_case_id{dcon::use_case_id::value_base_t(need.use_case - 1)};
			state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);
				auto demand_satisfaction = state.province_get_local_satisfaction(province, trade_good);

				auto price = state.province_get_local_prices(province, trade_good);

				assert(need.demanded >= 0.f);
				assert(price_score(price / weight) >= 0.f);
				assert(demand_satisfaction >= 0.f);

				auto score = need.demanded * price_score(price / weight) * demand_satisfaction;

				if (!(score >= 0.f)) {
					std::cout << need.demanded << " " << price_score(price / weight) << " " << demand_satisfaction << "\n";
				}

				assert(score >= 0.f);

				total_score += score;
				total_cost = need.demanded * score * price * POP_BUY_PRICE_MULTIPLIER;
			});
		};

		if (total_score == 0.f) return;

		auto scale = 0.f;
		if (total_cost > 0.f) {
			// buy a lot if price is low
			scale = std::min(MAX_INDUCED_DEMAND, budget / total_cost);
		}

		for (uint32_t i = 0; i < state.pop_get_need_satisfaction_size(); i++) {
			base_types::need_satisfaction& need = state.pop_get_need_satisfaction(pop, i);
			if (need.use_case == 0)	break;

			auto use = dcon::use_case_id{dcon::use_case_id::value_base_t(need.use_case - 1)};
			state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);
				auto demand_satisfaction = state.province_get_local_satisfaction(province, trade_good);

				auto price = state.province_get_local_prices(province, trade_good);

				assert(need.demanded >= 0.f);
				assert(price_score(price / weight) >= 0.f);
				assert(demand_satisfaction >= 0.f);

				auto score = need.demanded * price_score(price / weight) * demand_satisfaction;

				assert(score >= 0.f);
				assert(total_score > 0.f);

				auto distribution = score / total_score;

				assert(distribution >= 0.f);
				assert(scale >= 0.f);

				auto demand = distribution * scale;

				assert(demand >= 0.f);
				assert(demand_satisfaction >= 0.f);

				state.pop_set_inventory(pop, trade_good, state.pop_get_inventory(pop, trade_good) + demand * demand_satisfaction);
				state.pop_set_pending_economy_income(
					pop,
					std::max(0.f, state.pop_get_pending_economy_income(pop)
					- demand * demand_satisfaction * price * POP_BUY_PRICE_MULTIPLIER)
				);
			});
		};
	});
}

void pops_update_stats() {
	state.for_each_pop([&](auto pop) {
		auto total_basic_consumed = 0.f;
		auto total_basic_demanded = 0.f;

		auto total_life_demanded = 0.f;
		auto total_life_consumed = 0.f;

		for (uint32_t i = 0; i < state.pop_get_need_satisfaction_size(); i++) {
			base_types::need_satisfaction& need = state.pop_get_need_satisfaction(pop, i);
			if (need.use_case == 0) break;

			auto need_id = dcon::need_id{dcon::need_id::value_base_t(int(need.need) - 1)};

			if (state.need_get_life_need(need_id)){
				total_life_consumed = total_life_consumed + need.consumed;
				total_life_demanded = total_life_demanded + need.demanded;
			} else {
				total_basic_consumed = total_basic_consumed + need.consumed;
				total_basic_demanded = total_basic_demanded + need.demanded;
			}
		}

		auto life_satisfaction = total_life_consumed / total_life_demanded;
		auto basic_satisfaction = (total_basic_consumed + total_life_consumed) / (total_basic_demanded + total_life_demanded);
		state.pop_set_life_needs_satisfaction(pop, life_satisfaction);
		state.pop_set_basic_needs_satisfaction(pop, basic_satisfaction);
	});
}

// same as for pops
void buildings_buy() {
	state.for_each_building([&](auto building){
		// std::cout << "update building " << building.index() << "\n";

		auto building_type = state.building_get_current_type(building);
		auto production_method = state.building_type_get_production_method(building_type);

		auto province = state.building_get_location_from_building_location(building);

		auto budget = state.building_get_savings(building) * 0.1f;

		// std::cout << "budget: " << budget << "\n";

		auto total_score = 0.01f;
		auto total_cost = 0.f;

		// std::cout << "calculate total costs and score: " << "\n";

		for (uint32_t i = 0; i < state.production_method_get_inputs_size(); i++) {
			base_types::use_case_container& input = state.production_method_get_inputs(production_method, i);
			if(input.use == 0) break;

			auto use = dcon::use_case_id{dcon::use_case_id::value_base_t(input.use - 1)};
			state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);
				auto demand_satisfaction = state.province_get_local_satisfaction(province, trade_good);

				auto price = state.province_get_local_prices(province, trade_good);
				auto score = input.amount * price_score(price / weight) * demand_satisfaction;
				total_score += score;
				total_cost = input.amount * score * price * POP_BUY_PRICE_MULTIPLIER;

				// std::cout
				// 	<< "\t"
				// 	<< price << " "
				// 	<< input.amount << " "
				// 	<< price_score(price / weight) << " "
				// 	<< demand_satisfaction << " => "
				// 	<< score << " "
				// 	<< weight << "\n";
			});
		};

		// std::cout << "total score: " << total_score << "\n";
		// std::cout << "total cost: " << total_cost << "\n";

		if (total_score == 0.f) return ;

		auto scale = 0.f;
		if (total_cost > 0.f) {
			scale = std::min(1.f, budget / total_cost);
		}

		for (uint32_t i = 0; i < state.production_method_get_inputs_size(); i++) {
			base_types::use_case_container& input = state.production_method_get_inputs(production_method, i);
			if(input.use == 0) break;
			auto use = dcon::use_case_id{dcon::use_case_id::value_base_t(input.use - 1)};

			auto total_amount = 0.f;
			auto total_cost = 0.f;
			state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);
				auto demand_satisfaction = state.province_get_local_satisfaction(province, trade_good);

				auto price = state.province_get_local_prices(province, trade_good);
				auto score = input.amount * price_score(price / weight) * demand_satisfaction;
				auto distribution = score / total_score;

				auto demand = distribution * scale;

				assert(demand >= 0.f);
				assert(demand_satisfaction >= 0.f);

				state.building_set_inventory(building, trade_good, state.building_get_inventory(building, trade_good) + demand * demand_satisfaction);
				state.building_set_savings(
					building,
					std::max(0.f, state.building_get_savings(building)
					- demand * demand_satisfaction * price * POP_BUY_PRICE_MULTIPLIER)
				);

				// std::cout
				// 	<< "\t"
				// 	<< budget << " "
				// 	<< total_cost << " "
				// 	<< input.amount << " "
				// 	<< price_score(price / weight) << " "
				// 	<< demand_satisfaction << " => "
				// 	<< demand << " "
				// 	<< price << "\n";

				total_cost += demand * demand_satisfaction * price * POP_BUY_PRICE_MULTIPLIER;
				total_amount += demand * demand_satisfaction;
			});

			// std::cout << input.use << " " << total_amount << " " << total_cost << "\n";

			base_types::use_case_container& stats = state.building_get_amount_of_inputs(building, i);
			stats.use = input.use;
			stats.amount = total_amount;

			base_types::use_case_container& stats_spent = state.building_get_spent_on_inputs(building, i);
			stats_spent.use = input.use;
			stats_spent.amount = total_cost;

			state.building_get_last_income(building) -= total_cost;
		};
	});
}

constexpr inline float WORKERS_SHARE = 0.25f;
constexpr inline float OWNER_SHARE = 0.5f;

constexpr inline float LEFTOVERS_SHARE = 1.f - WORKERS_SHARE - OWNER_SHARE;

void buildings_pay() {
	state.for_each_building([&](auto ids) {
		auto savings = state.building_get_savings(ids);

		auto donation = savings * OWNER_SHARE;
		auto wage_budget = savings * WORKERS_SHARE;

		state.building_get_last_income(ids) -= wage_budget;

		state.building_set_last_donation_to_owner(ids, donation);
		auto owner = state.building_get_owner_from_ownership(ids);
		auto subsidy = state.building_get_subsidy(ids);
		state.building_set_subsidy_last(ids, subsidy);

		if (owner) {
			state.pop_get_pending_economy_income(owner) += donation - subsidy;
		} else {
			auto location = state.building_get_location_from_building_location(ids);
			state.province_get_local_wealth(location) += donation;
		}


		float total_work_time = 0.f;
		state.building_for_each_employment(ids, [&](auto employment){
			total_work_time += state.pop_get_work_ratio(state.employment_get_worker(employment));
		});

		state.building_for_each_employment(ids, [&](auto employment){
			auto pop = state.employment_get_worker(employment);
			auto work_ratio = state.pop_get_work_ratio(pop);

			auto share = wage_budget * work_ratio / total_work_time;

			state.pop_get_pending_economy_income(pop) += share;
			state.employment_set_worker_income(employment, share);
		});

		state.building_get_savings(ids) *= LEFTOVERS_SHARE;
		if (owner) {
			state.building_get_savings(ids) += subsidy;
		}
	});
}

// TODO: rewrite more stuff to parallel loops, as there are a lot of opportunities for parallelisation
void update_economy() {
	uint32_t trade_goods_count = state.trade_good_size();

	state.execute_serial_over_building([&](auto ids){
		auto last_income = state.building_get_last_income(ids);
		auto mean_income = state.building_get_income_mean(ids);
		state.building_set_income_mean(ids, last_income * 0.1f + mean_income * 0.9f);
		state.building_set_last_income(ids, 0.f);
	});

	auto eps = 0.001;

	update_building_scale();

	state.execute_serial_over_pop([&](auto ids){
		state.pop_set_pending_economy_income(ids, 0.f);
	});

	// demand stage
	concurrency::parallel_for(uint32_t(0), trade_goods_count, [&](auto good_id){
		dcon::trade_good_id trade_good{ dcon::trade_good_id::value_base_t(good_id) };
		state.execute_serial_over_province([&](auto ids){
				state.province_set_local_demand(ids, trade_good, 0.f);
		});
	});
	pops_demand();
	buildings_demand();

	concurrency::parallel_for(uint32_t(0), trade_goods_count, [&](auto good_id){
		dcon::trade_good_id trade_good{ dcon::trade_good_id::value_base_t(good_id) };
		state.execute_serial_over_province([&](auto ids){
				state.province_set_local_production(ids, trade_good, 0.f);
		});
	});
	pops_sell();
	buildings_sell();

	// decay inventories of producers
	concurrency::parallel_for(uint32_t(0), trade_goods_count, [&](auto good_id){
		dcon::trade_good_id trade_good{ dcon::trade_good_id::value_base_t(good_id) };
		float inventory_decay = 0.f;
		if (state.trade_good_get_belongs_to_category(trade_good) == GOOD_CATEGORY) {
			inventory_decay = 0.999f;
		}
		state.execute_serial_over_pop([&](auto ids){
			auto inventory = state.pop_get_inventory(ids, trade_good);
			state.pop_set_inventory(ids, trade_good, inventory * inventory_decay);
		});
		state.execute_serial_over_building([&](auto ids){
			auto inventory = state.building_get_inventory(ids, trade_good);
			state.building_set_inventory(ids, trade_good, inventory * inventory_decay);
		});
	});

	// decay inventories in provinces and realms:
	concurrency::parallel_for(uint32_t(0), trade_goods_count, [&](auto good_id){
		dcon::trade_good_id trade_good{ dcon::trade_good_id::value_base_t(good_id) };
		float inventory_decay = 0.f;
		if (state.trade_good_get_belongs_to_category(trade_good) == GOOD_CATEGORY) {
			inventory_decay = 0.999f;
		}
		state.execute_serial_over_province([&](auto ids){
			auto stockpiles = state.province_get_local_storage(ids, trade_good);
			state.province_set_local_storage(ids, trade_good, stockpiles * inventory_decay);
		});
		state.execute_serial_over_realm([&](auto ids){
			auto stockpiles = state.realm_get_resources(ids, trade_good);
			state.realm_set_resources(ids, trade_good, stockpiles * inventory_decay);
		});
	});

	// supply: calculated
	// demand: calculated
	// update demand satisfaction
	concurrency::parallel_for(uint32_t(0), trade_goods_count, [&](auto good_id){
		dcon::trade_good_id trade_good{ dcon::trade_good_id::value_base_t(good_id) };
		state.execute_serial_over_province([&](auto ids){
			auto demand = state.province_get_local_demand(ids, trade_good);
			auto stockpiles = state.province_get_local_storage(ids, trade_good);
			auto production = state.province_get_local_production(ids, trade_good);
			auto supply = stockpiles + production;
			auto satisfaction = ve::select(demand <= supply, 1.f, supply / demand);
			state.province_set_local_satisfaction(ids, trade_good, satisfaction);
			state.province_set_local_storage(ids, trade_good, ve::max(0.f, stockpiles + production - satisfaction * demand));
		});
	});

	// now we are able to execute buyment requests
	buildings_buy();
	pops_buy();

	//interal production, doesn't influence province data:

	pops_produce();
	pops_consume();
	building_produce();

	// now we sum up production and calculate trading balance in savings of local merchants

	state.for_each_trade_good([&](auto trade_good) {
		state.execute_serial_over_province([&](auto province){
			auto demanded = state.province_get_local_demand(province, trade_good);
			auto satisfied = ve::min(1.f, state.province_get_local_satisfaction(province, trade_good));
			auto produced = state.province_get_local_production(province, trade_good);
			auto price = state.province_get_local_prices(province, trade_good);

			auto balance = demanded * satisfied * POP_BUY_PRICE_MULTIPLIER - produced * price;
			auto wealth = state.province_get_trade_wealth(province);

			auto result = ve::select(balance + wealth > 0.f, balance + wealth, 0.f);
			state.province_set_trade_wealth(province, result);
			state.province_set_local_consumption(province, trade_good, demanded * satisfied);
		});
	});

	concurrency::parallel_for(uint32_t(0), trade_goods_count, [&](auto good_id){
		dcon::trade_good_id trade_good{ dcon::trade_good_id::value_base_t(good_id) };
		state.execute_serial_over_province([&](auto ids){
			auto supply = state.province_get_local_production(ids, trade_good) + state.province_get_local_storage(ids, trade_good);
			auto demand = state.province_get_local_demand(ids, trade_good);

			auto current_price = state.province_get_local_prices(ids, trade_good);

			auto oversupply = (supply + 1.f) / (demand + 1.f);
			auto overdemand = (demand + 1.f) / (supply + 1.f);

			auto speed = 0.01f * (overdemand - oversupply);

			auto new_price = ve::max(0.001f, current_price + speed);

			state.province_set_local_prices(ids, trade_good, new_price);
		});
	});

	buildings_pay();
	pops_update_stats();
}

float estimate_province_use_price(dcon::province_id province, dcon::use_case_id use) {
	auto min_adjusted_price = std::numeric_limits<float>::max();

	state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id) {
		auto good = state.use_weight_get_trade_good(weight_id);
		auto weight = state.use_weight_get_weight(weight_id);
		auto price = state.province_get_local_prices(province, good);

		auto adjusted_price = price / weight;

		if (adjusted_price < min_adjusted_price) {
			min_adjusted_price = adjusted_price;
		}
	});

	float integral = 0;
	float integral_of_identity = 0;

	state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id) {
		auto good = state.use_weight_get_trade_good(weight_id);
		auto weight = state.use_weight_get_weight(weight_id);
		auto price = state.province_get_local_prices(province, good);

		auto adjusted_price = price / weight;
		auto predensity = expf(-adjusted_price + min_adjusted_price);

		integral_of_identity = integral_of_identity + predensity;
		integral = integral + adjusted_price * predensity;
	});

	return integral / integral_of_identity;
}

// uses softmax of adjusted prices to calculate distribution used in estimation
float estimate_province_use_price(uint32_t province_lua_id, uint32_t use_lua_id) {
	dcon::province_id province {dcon::province_id::value_base_t(province_lua_id - 1)};
	dcon::use_case_id use {dcon::use_case_id::value_base_t(use_lua_id - 1)};

	return estimate_province_use_price(province, use);
}

float estimate_building_type_income(int32_t province_lua, int32_t building_type_lua, int32_t race_lua, bool female) {
	dcon::province_id province {dcon::province_id::value_base_t(province_lua - 1)};
	dcon::building_type_id building_type {dcon::building_type_id::value_base_t(building_type_lua - 1)};
	dcon::race_id race {dcon::race_id::value_base_t(race_lua - 1)};
	auto method = state.building_type_get_production_method(building_type);
	auto associated_job = state.production_method_get_job_type(method);
	auto efficiency = job_efficiency(race, female, associated_job);

	float throughput_boost =
		(1 + state.province_get_throughput_boosts(province, method))
		* efficiency;
	float input_modifier = std::max(0.f, 1 - state.province_get_input_efficiency_boosts(province, method));
	float output_modifier =
		(1 + state.province_get_output_efficiency_boosts(province, method))
		* efficiency;

	float income = 0;
	for (uint32_t i = 0; i < state.production_method_get_inputs_size(); i++) {
		base_types::use_case_container& input = state.production_method_get_inputs(method, i);
		if(!input.use) {
			break;
		}

		auto use = dcon::use_case_id {dcon::use_case_id::value_base_t(input.use - 1)};
		income -= input_modifier * estimate_province_use_price(province, use) * input.amount;
	}
	for (uint32_t i = 0; i < state.production_method_get_outputs_size(); i++) {
		base_types::trade_good_container& output = state.production_method_get_outputs(method, i);
		if(!output.good) {
			break;
		}
		auto good = dcon::trade_good_id{dcon::trade_good_id::value_base_t(output.good - 1)};
		income += output.amount * output_modifier * state.province_get_local_prices(province, good);
	}

    return income * throughput_boost;
}