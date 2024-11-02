#include <iostream>
#include "objs.hpp"
#include "sote_types.hpp"
#define DCON_LUADLL_EXPORTS
#include "sote_functions.hpp"
#include "lua_objs.hpp"

static auto GOOD_CATEGORY = (uint8_t)((int)(base_types::TRADE_GOOD_CATEGORY::GOOD) - 1);


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

float job_efficiency(dcon::pop_id pop, uint8_t jobtype) {
	auto female = state.pop_get_female(pop);
	auto race = state.pop_get_race(pop);
	auto multiplier = age_multiplier(pop);
	if (female) {
		return state.race_get_female_efficiency(race, jobtype) * multiplier;
	}
	return state.race_get_male_efficiency(race, jobtype) * multiplier;
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
	// std::cout << "forage" << "\n";

	state.for_each_pop([&](auto ids) {
		auto province = state.pop_get_location_from_pop_location(ids);

		auto size = state.province_get_size(province);

		auto forage_time = state.pop_get_forage_ratio(ids);

		// std::cout << "forage ratio: " << forage_time << "\n";

		for (uint32_t i = 0; i < state.province_get_foragers_targets_size(); i++){
			base_types::forage_container& forage_case = state.province_get_foragers_targets(province, i);

			auto output = dcon::trade_good_id{int32_t(forage_case.output_good - 1)};

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
			auto efficiency = job_efficiency(ids, state.forage_resource_get_handle(resource));

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
			);
		}
	});
}

void building_produce() {
	static auto inputs_buffer = state.trade_good_make_vectorizable_float_buffer();
	state.for_each_building([&](auto ids){
		state.execute_serial_over_trade_good([&](auto trade_good){
			inputs_buffer.set(trade_good, 0.f);
		});

		auto building_type = state.building_get_current_type(ids);
		auto production_method = state.building_type_get_production_method(building_type);
		auto current_power = state.building_get_production_scale(ids);
		auto province = state.building_get_location_from_building_location(ids);

		auto min_input = 1.f;

		for (uint32_t i = 0; i < state.production_method_get_inputs_size(); i++) {
			base_types::use_case_container input = state.production_method_get_inputs(production_method, i);
			if (input.use == 0) break;

			auto have_to_satisfy = input.amount * current_power;

			state.use_case_for_each_use_weight_as_use_case(dcon::use_case_id{(uint8_t)(input.use - 1)}, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);

				// try to consume and write consumption to the buffer
				auto inventory = state.building_get_inventory(ids, trade_good) - inputs_buffer.get(trade_good);

				auto can_satisfy = inventory * weight;

				if (have_to_satisfy < can_satisfy) {
					have_to_satisfy = 0.f;
					inputs_buffer.set(trade_good, inputs_buffer.get(trade_good) + inventory * can_satisfy / have_to_satisfy);
				} else {
					have_to_satisfy = have_to_satisfy - can_satisfy;
					inputs_buffer.set(trade_good, inputs_buffer.get(trade_good) + inventory);
				}
			});

			min_input = std::max(0.f, std::min(min_input, 1.f - have_to_satisfy / input.amount));
		}

		// actual consumption:

		auto true_min_input = 1.f;

		for (uint32_t i = 0; i < state.production_method_get_inputs_size(); i++) {
			base_types::use_case_container& input = state.production_method_get_inputs(production_method, i);
			if(!input.use) {
				break;
			}

			auto have_to_satisfy = input.amount * min_input * current_power;
			auto use = dcon::use_case_id {(uint8_t)input.use};
			state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);

				// try to consume and write consumption to the buffer
				auto inventory = state.building_get_inventory(ids, trade_good);

				auto can_satisfy = inventory * weight;

				if (have_to_satisfy < can_satisfy) {
					state.building_set_inventory(ids, trade_good, std::max(0.f, inventory - have_to_satisfy / weight));
					have_to_satisfy = 0.f;
				} else {
					have_to_satisfy = have_to_satisfy - can_satisfy;
					state.building_set_inventory(ids, trade_good, std::max(0.f, 0.f));
				}
			});

			true_min_input = std::max(0.f, std::min(true_min_input, 1.f - have_to_satisfy / input.amount));

			base_types::use_case_container& stats = state.building_get_amount_of_inputs(ids, i);
			stats.amount = true_min_input * current_power * input.amount;
		}

		// actual production

		for (uint32_t i = 0; i < state.production_method_get_outputs_size(); i++) {
			base_types::trade_good_container& output = state.production_method_get_outputs(production_method, i);
			if(!output.good) {
				break;
			}
			auto good = dcon::trade_good_id{dcon::trade_good_id::value_base_t(output.good - 1)};
			auto inventory = state.building_get_inventory(ids, good);

			// assert(inventory >= 0.f);
			// assert(output.amount >= 0.f);
			// assert(current_power >= 0.f);
			// assert(true_min_input >= 0.f);

			// std::cout << "output: " << good.index() << " amount: " << output.amount << " power " << current_power << " min_input " << true_min_input << "\n";

			state.building_set_inventory(ids, good, inventory + output.amount * current_power * true_min_input);

			base_types::trade_good_container& stats = state.building_get_amount_of_outputs(ids, i);
			stats.amount = true_min_input * current_power * output.amount;
			stats.good = output.good;

			base_types::trade_good_container& stats_earning = state.building_get_earn_from_outputs(ids, i);
			stats_earning.good = output.good;
			stats_earning.amount = stats.amount * state.province_get_local_prices(province, good);
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
			// std::cout << need.consumed << " " << need.demanded;
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

		// std::cout << "income: " << income << " \n";
		state.building_set_savings(building, state.building_get_savings(building) + income);
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
			scale = std::min(1.f, budget / total_cost);
		}

		for (uint32_t i = 0; i < state.pop_get_need_satisfaction_size(); i++) {
			base_types::need_satisfaction& need = state.pop_get_need_satisfaction(pop, i);
			auto use = dcon::use_case_id{dcon::use_case_id::value_base_t(need.use_case - 1)};
			// std::cout << " use " << need.use_case << "\n";
			if (!use)	break;
			state.use_case_for_each_use_weight_as_use_case(use, [&](auto weight_id){
				auto weight = state.use_weight_get_weight(weight_id);
				auto trade_good = state.use_weight_get_trade_good(weight_id);
				// auto demand_satisfaction = state.province_get_local_satisfaction(province, trade_good);

				auto price = state.province_get_local_prices(province, trade_good);
				auto score = need.demanded * price_score(price / weight);
				auto distribution = score / total_score;

				auto demand = need.demanded * distribution * scale;

				// std::cout << " trade good " << trade_good.index() << "\n";
				// std::cout << " demand " << demand << "\n";
				// std::cout << " base demand " << need.demanded << "\n";

				// if (!(demand >= 0.f)) {
				// 	std::cout << need.demanded << " " << distribution << " " << scale << "\n";
				// }

				// assert(score >= 0.f);
				// assert(total_score > 0.f);
				// assert(scale >= 0.f);
				// assert(need.demanded >= 0.f);
				// assert(distribution >= 0.f);
				// assert(demand >= 0.f);

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
			scale = std::min(100.f, budget / total_cost);
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
				auto demand_satisfaction = state.province_get_local_satisfaction(province, trade_good);

				auto price = state.province_get_local_prices(province, trade_good);
				auto score = input.amount * price_score(price / weight) * demand_satisfaction;
				total_score += score;
				total_cost = input.amount * score * price * POP_BUY_PRICE_MULTIPLIER;
			});
		};

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

				total_cost += demand * demand_satisfaction * price * POP_BUY_PRICE_MULTIPLIER;
				total_amount += demand * demand_satisfaction;
			});

			base_types::use_case_container stats = state.building_get_amount_of_inputs(building, i);
			stats.use = input.use;
			stats.amount = total_amount;

			base_types::use_case_container stats_spent = state.building_get_amount_of_inputs(building, i);
			stats.use = input.use;
			stats.amount = total_cost;
		};
	});
}

constexpr inline float WORKERS_SHARE = 0.25f;
constexpr inline float OWNER_SHARE = 0.5f;

constexpr inline float LEFTOVERS_SHARE = 1.f - WORKERS_SHARE - OWNER_SHARE;

void buildings_pay() {
	state.for_each_building([&](auto ids) {
		state.building_set_production_scale(ids, 1.f);

		auto savings = state.building_get_savings(ids);

		auto donation = savings * OWNER_SHARE;
		auto wage_budget = savings * WORKERS_SHARE;

		state.building_set_last_donation_to_owner(ids, donation);
		auto owner = state.building_get_owner_from_ownership(ids);
		auto subsidy = state.building_get_subsidy(ids);

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

void update_economy() {
	auto eps = 0.001;

	state.execute_serial_over_pop([&](auto ids){
		state.pop_set_pending_economy_income(ids, 0.f);
	});

	// demand stage
	state.execute_serial_over_province([&](auto ids){
		state.for_each_trade_good([&](auto good){
			state.province_set_local_demand(ids, good, 0.f);
		});
	});
	pops_demand();
	buildings_demand();

	state.execute_serial_over_province([&](auto ids){
		state.for_each_trade_good([&](auto good){
			state.province_set_local_production(ids, good, 0.f);
		});
	});
	pops_sell();
	buildings_sell();

	// supply: calculated
	// demand: calculated
	// update demand satisfaction

	state.execute_serial_over_province([&](auto ids){
		state.for_each_trade_good([&](auto good){
			auto demand = state.province_get_local_demand(ids, good);
			auto supply = state.province_get_local_production(ids, good);
			auto satisfaction = ve::select(demand <= supply, 1.f, supply / demand);

			ve::apply([&](float demand, float supply, float satisfaction){
				if(!std::isfinite(satisfaction)) {
					std::cout << demand << " " << supply << " " << satisfaction << "n";
				}
				assert(std::isfinite(satisfaction));
			}, demand, supply, satisfaction);

			state.province_set_local_satisfaction(ids, good, satisfaction);
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
		});
	});

	state.for_each_trade_good([&](auto trade_good){
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