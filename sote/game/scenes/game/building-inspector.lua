local re = {}
local tabb = require "engine.table"
local trade_good = require "game.raws.raws-utils".trade_good
local use_case = require "game.raws.raws-utils".trade_good_use_case
local ui = require "engine.ui"
local ut = require "game.ui-utils"
local ib = require "game.scenes.game.widgets.inspector-redirect-buttons"
local portrait_widget = require "game.scenes.game.widgets.portrait"
local list_widget = require "game.scenes.game.widgets.list-widget"
local economical = require "game.raws.values.economy"
local economic_effects = require "game.raws.effects.economy"
local dbm = require "game.economy.diet-breadth-model"
local production_method_utils = require "game.raws.production-methods"
local province_utils = require "game.entities.province".Province
local pop_utils = require "game.entities.pop".POP
local demography_effects = require "game.raws.effects.demography"

local BUILDING_SUBSIDY_AMOUNT = 0.125

local output_list_state = nil
local input_list_state = nil
local worker_list_state = nil

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
	local panel = fs:subrect(ut.BASE_HEIGHT * 2, 0, 600, 680, "left", "down")
	return panel
end

---Returns whether or not clicks on the planet can be registered.
---@return boolean
function re.mask()
	if ui.trigger(get_main_panel()) then
		return false
	else
		return true
	end
end

---@param gam GameScene
function re.draw(gam)

	--- combining key presses for increments of 1, 5, 10, and 50
	BUILDING_SUBSIDY_AMOUNT = 0.125
	if ui.is_key_held("lshift") or ui.is_key_held("rshift") then
		BUILDING_SUBSIDY_AMOUNT = BUILDING_SUBSIDY_AMOUNT * 2
	end
	if ui.is_key_held("lctrl") or ui.is_key_held("rctrl") then
		BUILDING_SUBSIDY_AMOUNT = BUILDING_SUBSIDY_AMOUNT * 4
	end

	local bbuild = gam.selected.building
	if bbuild ~= nil then
		---@type Building
		local building = bbuild
		local panel = get_main_panel()
		ui.panel(panel)

		ib.icon_button_to_close(gam, panel:subrect(0, 0, ut.BASE_HEIGHT, ut.BASE_HEIGHT, "right", "up"))

		local btype = DATA.building_get_current_type(building)
		local method = DATA.building_type_get_production_method(btype)

		local name = DATA.building_type_get_name(btype)
		local description = DATA.building_type_get_description(btype)
		local icon = DATA.building_type_get_icon(btype)

		local owner = OWNER(building)
		local location = DATA.get_building_location_from_building(building)
		local province = DATA.building_location_get_location(location)
		local realm = PROVINCE_REALM(province)

		local topbar = ui.layout_builder()
			:position(panel.x, panel.y)
			:horizontal()
			:spacing(5)
			:build()
		ui.image(ASSETS.icons[icon], topbar:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT))
		ui.left_text(name, topbar:next(10 * ut.BASE_HEIGHT, ut.BASE_HEIGHT))

		local pan = panel:subrect(5, 5 + ut.BASE_HEIGHT, panel.width - 10, ut.BASE_HEIGHT * 3, "left", "up")
		ui.panel(pan)
		pan:shrink(5)
		ui.text(description, pan, "left", "up")
		-- button to owner
		local owner_button = pan:subrect(0, 5 + ut.BASE_HEIGHT * 3, ut.BASE_HEIGHT * 6, ut.BASE_HEIGHT, "left", "up")
		-- location of leftmost item label
		local left_text_rect = owner_button:subrect(5 + ut.BASE_HEIGHT * 9, 0, ut.BASE_HEIGHT * 6, ut.BASE_HEIGHT, "left", "up")
		-- location of leftmost item value
		local left_value_rect = owner_button:subrect(5 + ut.BASE_HEIGHT * 9, 5 + ut.BASE_HEIGHT, left_text_rect.width, left_text_rect.height, "left", "up")
		-- location of middle item label
		local middle_text_rect = left_text_rect:subrect(5 + left_text_rect.width, 0, left_text_rect.width, left_text_rect.height, "left", "up")
		-- location of middel item value
		local middle_value_rect = left_value_rect:subrect(5 + left_text_rect.width, 0, left_text_rect.width, left_text_rect.height, "left", "up")
		-- location of rightmost item label
		local right_text_rect = middle_text_rect:subrect(5 + left_text_rect.width, 0, left_text_rect.width, left_text_rect.height, "left", "up")
		-- location of rightmost item value
		local right_value_rect = middle_value_rect:subrect(5 + left_text_rect.width, 0, left_text_rect.width, left_text_rect.height, "left", "up")

		-- OWNER ICON, NAME, LAST SUBSIDY, DONATIONS, INCOME

		ui.centered_text("Building owner", owner_button)
		owner_button.y = owner_button.y + 5 + ut.BASE_HEIGHT
		local owner_icon = owner_button:subrect(0, 0, ut.BASE_HEIGHT, ut.BASE_HEIGHT, "left", "up")
		owner_button.x = owner_icon.x + owner_icon.width + 5
		if owner ~= INVALID_ID then
			-- target character
			ib.icon_button_to_character(gam, owner, owner_icon)
			ib.text_button_to_character(gam, owner, owner_button,
				NAME(owner), NAME(owner) .. " owns this building.")
		else
			-- target realm if possible
			if realm then
				ib.icon_button_to_realm(gam, realm, owner_icon)
			else
				ut.render_icon(owner_icon, "world.png", 1, 1, 1, 1)
			end
			ib.text_button_to_province(gam, province, owner_button,
				PROVINCE_NAME(province), "Public builing in" .. PROVINCE_NAME(province) .. ".")
		end
		owner_icon.y = owner_icon.y + ut.BASE_HEIGHT * 2 + 10

		-- next subsidy, changing values and destory, only seen by owner (or realm leader if public)
		if (owner == INVALID_ID and WORLD.player_character == LEADER(PROVINCE_REALM(province)))
			or (owner ~= INVALID_ID and WORLD.player_character == owner)
		then
			owner_button.y = owner_button.y + ut.BASE_HEIGHT + 5
			owner_button.width = ut.BASE_HEIGHT * 4
			ui.centered_text("Next subsidies", owner_button)
			owner_button.y = owner_button.y + ut.BASE_HEIGHT + 5
			ut.money_entry_icon(DATA.building_get_subsidy(building), owner_button, ut.to_fixed_point2(DATA.building_get_subsidy(building))
				.. MONEY_SYMBOL .. " to be paid to each worker next month.", true)
			owner_button.x = owner_button.x + ut.BASE_HEIGHT * 4 + 5
			owner_button.width = ut.BASE_HEIGHT
			if ut.icon_button(ASSETS.icons["plus.png"], owner_button,
				"Increase next month's subsidies by " .. ut.to_fixed_point2(BUILDING_SUBSIDY_AMOUNT) .. " per worker."
				.. "\nPress Ctrl and/or Shift to modify amount."
			) then
				DATA.building_inc_subsidy(building, BUILDING_SUBSIDY_AMOUNT)
			end
			if ut.icon_button(
				ASSETS.icons["minus.png"], owner_icon,
				"Decrease next month's subsidies by ".. ut.to_fixed_point2(-BUILDING_SUBSIDY_AMOUNT).." per worker."
				.. "\nPress Ctrl and/or Shift to modify amount."
			) then
				DATA.building_inc_subsidy(building, -BUILDING_SUBSIDY_AMOUNT)
			end
			local destory_button = owner_button:subrect(ut.BASE_HEIGHT + 10, 0, ut.BASE_HEIGHT, ut.BASE_HEIGHT, "left", "up")
			if ut.icon_button(
				ASSETS.icons["hammer-drop.png"],
				destory_button, "Destory this building? WARNING; It can't be taken back!"
			) then
				economic_effects.destroy_building(building)
				gam.click_tile(0)
				gam.selected.building = nil
				gam.inspector = nil
			end
		end

		local foragers = DATA.province_get_foragers(province)
		local foragers_limit = DATA.province_get_foragers_limit(province)
		local province_size = DATA.province_get_size(province)
		local forage_efficiency = 1
		if DATA.production_method_get_foraging(method) then
			forage_efficiency = dbm.foraging_efficiency(foragers_limit, foragers)
		end
		local wood_amount = 0
		for i = 1, MAX_RESOURCES_IN_PROVINCE_INDEX do
			local resource = DATA.province_get_foragers_targets_forage(province, i)
			if resource == INVALID_ID then
				break
			end

			if resource == FORAGE_RESOURCE.WOOD then
				wood_amount = wood_amount + DATA.province_get_foragers_targets_amount(province, i)
			end
		end

		-- WORK TIME, INPUT COST, OUTPUT REVENUE

		-- ROW #1
		-- tile efficiency
		local building_efficiency = production_method_utils.get_efficiency(method, province)
		local tooltip = "The building's production efficiency is " .. ut.to_fixed_point2(building_efficiency * 100) .. "%."
		if DATA.production_method_get_foraging(method) then
			tooltip = tooltip .. " Workers forages natural resources, increasing province foragers by total working time while local foraging competition modify efficiency by " .. ut.to_fixed_point2(forage_efficiency * 100) .. "%."
		end
		local nature_yield_dependence = DATA.production_method_get_nature_yield_dependence(method)
		if nature_yield_dependence > 0 then
			local nature_yield = nature_yield_dependence * foragers_limit / province_size
			tooltip = tooltip .. " Production is depenedent on harvesting natrual resources, as such the local resource density modify efficiency by " .. ut.to_fixed_point2(nature_yield * 100) .. "%."
		end
		local forest_dependence = DATA.production_method_get_forest_dependence(method)
		if forest_dependence > 0 then
			local nature_yield = (wood_amount / province_size) * forest_dependence
			tooltip = tooltip .. " Output is harvested from available forest resources, as such the local foliage density modify efficiency by " .. ut.to_fixed_point2(nature_yield * 100) .. "% and deforests tiles."
		end
		ui.centered_text("Building efficiency", left_text_rect)
		ut.color_coded_percentage(building_efficiency, left_value_rect, true, tooltip)
		-- infra efficiency
		local inf = province_utils.get_infrastructure_efficiency(province)
		local efficiency_from_infrastructure = math.min(1.5, 0.5 + 0.5 * math.sqrt(2 * inf))

		local local_method_efficiency = production_method_utils.get_efficiency(method, province)

		ui.centered_text("Infra efficiency", middle_text_rect)
		ut.color_coded_percentage(efficiency_from_infrastructure, middle_value_rect, true, "Production efficiency from province infrastructure.")
		-- worker count out of max
		local worker_cur = tabb.size(DATA.get_employment_from_building(building))
		local worker_max = production_method_utils.total_jobs(method)
		local worker_count = worker_cur .. " / " .. worker_max
		ui.centered_text("Worker count", right_text_rect)
		ut.generic_string_field("", worker_count, right_value_rect, "Curently employing "
			.. worker_cur .. " workers out of a maximum of " .. worker_max .. ".",
			ut.NAME_MODE.NAME)

		-- shift rect locations down
		left_text_rect.y = left_text_rect.y + ut.BASE_HEIGHT * 2  + 10
		left_value_rect.y = left_value_rect.y + ut.BASE_HEIGHT * 2  + 10
		middle_text_rect.y = left_text_rect.y
		middle_value_rect.y = left_value_rect.y
		right_text_rect.y = left_text_rect.y
		right_value_rect.y = left_value_rect.y

		-- ROW #2
		-- subsidy_last
		ui.centered_text("Last subsidies", left_text_rect)
		local last_subsidy = DATA.building_get_subsidy_last(building)
		local last_donation = DATA.building_get_last_donation_to_owner(building)
		local mean_income = DATA.building_get_income_mean(building)

		-- prepare inventory tooltip:
		local inventory_tooltip = "Current inventory: "
		DATA.for_each_trade_good(function (item)
			inventory_tooltip = inventory_tooltip .. "\n" .. DATA.trade_good_get_name(item) .. ": " .. ut.to_fixed_point2(DATA.building_get_inventory(building, item))
		end)

		ut.money_entry_icon(last_subsidy, left_value_rect, ut.to_fixed_point2(last_subsidy)
			.. MONEY_SYMBOL .. " paid to each worker last month.", true)
		-- last_donation_to_owner
		ui.centered_text("Last donation", middle_text_rect)
		ut.money_entry_icon(last_donation, middle_value_rect, ut.to_fixed_point2(last_donation)
			.. MONEY_SYMBOL .. " paid to the owner last month.")
		-- mean income
		ui.centered_text("Mean income", right_text_rect)
		ut.money_entry_icon(mean_income, right_value_rect, ut.to_fixed_point2(mean_income)
			.. MONEY_SYMBOL .. " average income over building lifetime.")

		-- shift rect locations down
		left_text_rect.y = left_text_rect.y + ut.BASE_HEIGHT * 2  + 10
		left_value_rect.y = left_value_rect.y + ut.BASE_HEIGHT * 2  + 10
		middle_text_rect.y = left_text_rect.y
		middle_value_rect.y = left_value_rect.y
		right_text_rect.y = left_text_rect.y
		right_value_rect.y = left_value_rect.y

		-- ROW #3
		-- spent_on_inputs
		local input_spent_total = 0
		---@type table<use_case_id, number>
		local amount_inputs = {}
		---@type table<use_case_id, number>
		local spent_inputs = {}
		---@type table<use_case_id, number>
		local base_inputs = {}
		for i = 1, MAX_SIZE_ARRAYS_PRODUCTION_METHOD do
			local spent = DATA.building_get_spent_on_inputs_amount(building, i)
			local use = DATA.building_get_spent_on_inputs_use(building, i)

			if use == INVALID_ID then
				break
			end
			input_spent_total = input_spent_total + spent

			spent_inputs[use] = spent
			amount_inputs[use] = DATA.building_get_amount_of_inputs_amount(building, i)
			base_inputs[use] = DATA.production_method_get_inputs_amount(method, i)
		end

		ui.centered_text("Input costs", left_text_rect)
		ut.money_entry_icon(input_spent_total, left_value_rect, ut.to_fixed_point2(input_spent_total)
			.. MONEY_SYMBOL  .. " spent on inputs last month.\n" .. inventory_tooltip, true)



		-- output profits
		local output_earn_total = 0

		---@type table<trade_good_id, number>
		local amount_outputs = {}
		---@type table<trade_good_id, number>
		local earn_outputs = {}
		---@type table<trade_good_id, number>
		local base_outputs = {}
		for i = 1, MAX_SIZE_ARRAYS_PRODUCTION_METHOD do
			local earn = DATA.building_get_earn_from_outputs_amount(building, i)
			local good = DATA.building_get_earn_from_outputs_good(building, i)

			if good == INVALID_ID then
				break
			end
			output_earn_total = output_earn_total + earn

			amount_outputs[good] = DATA.building_get_amount_of_outputs_amount(building, i)
			base_outputs[good] = DATA.production_method_get_outputs_amount(method, i)
			earn_outputs[good] = earn
		end
		ui.centered_text("Output revenue", middle_text_rect)
		ut.money_entry_icon(output_earn_total, middle_value_rect,ut.to_fixed_point2(output_earn_total)
			..  MONEY_SYMBOL .. " earned from outputs last month.")



		-- average revenue per worker
		ui.centered_text("Total profits", right_text_rect)
		ut.money_entry_icon(output_earn_total, right_value_rect, ut.to_fixed_point2((output_earn_total - input_spent_total))
			..  MONEY_SYMBOL .. " earned after paying for inputs. " .. ut.to_fixed_point2(DATA.building_get_savings(building)) .. MONEY_SYMBOL .. " currently saved by a building")

		-- INPUT OUTPUT AND WORKER TABLES

		---@param k trade_good_id
		---@param v number
		local function render_good_icon(rect, k, v)
			local good = DATA.fatten_trade_good(k)
			ut.render_icon(rect:copy():shrink(-1), good.icon, 1, 1, 1, 1)
			ut.render_icon(rect, good.icon, good.r, good.g, good.b, 1)
		end
		---@param k use_case_id
		---@param v number
		local function render_use_case_icon(rect, k, v)
			local case = DATA.fatten_use_case(k)
			ut.render_icon(rect:copy():shrink(-1), case.icon, 1, 1, 1, 1)
			ut.render_icon(rect, case.icon, case.r, case.g, case.b, 1)
		end

		local next_panel = owner_icon:subrect(0, ut.BASE_HEIGHT * 4 + 5, pan.width, ut.BASE_HEIGHT * 6, "left", "up")

		-- list of outputs
		output_list_state = list_widget(next_panel, base_outputs, {
			{
				header = ".",
				render_closure = render_good_icon,
				width = 1,
				---@param k trade_good_id
				---@param v number
				value = function(k, v)
					return DATA.trade_good_get_name(k)
				end
			},
			{
				header = "name",
				---@param k trade_good_id
				---@param v number
				render_closure = function(rect, k, v)
					ui.centered_text(DATA.trade_good_get_name(k), rect)
				end,
				width = 8,
				---@param k trade_good_id
				---@param v number
				value = function(k, v)
					return DATA.trade_good_get_name(k)
				end
			},
			{
				header = "base",
				---@param k trade_good_id
				---@param v number
				render_closure = function(rect, k, v)
					ui.centered_text(ut.to_fixed_point2(base_outputs[k] or 0), rect)
				end,
				width = 3,
				---@param k trade_good_id
				---@param v number
				value = function(k, v)
					return base_outputs[k]
				end,
			},
			{
				header = "amount",
				---@param k trade_good_id
				---@param v number
				render_closure = function(rect, k, v)
					ui.centered_text(ut.to_fixed_point2(amount_outputs[k] or 0), rect)
				end,
				width = 3,
				---@param k trade_good_id
				---@param v number
				value = function(k, v)
					return amount_outputs[k] or 0
				end,
			},
			{
				header = "price",
				---@param k trade_good_id
				---@param v number
				render_closure = function(rect, k, v)
					local price = economical.get_local_price(province, k) or 0
					ut.money_entry("", price, rect, ut.to_fixed_point2(price)
					.. MONEY_SYMBOL .. " earned per unit of " .. k .. " outputs")
				end,
				width = 2,
				---@param k trade_good_id
				---@param v number
				value = function(k, v)
					local price = economical.get_local_price(province, k) or 0
					return price
				end,
			},
			{
				header = "profit",
				---@param k trade_good_id
				---@param v number
				render_closure = function(rect, k, v)
					local earnings = earn_outputs[k] or 0
					ut.money_entry("", earnings, rect, ut.to_fixed_point2(earnings)
					.. MONEY_SYMBOL .. " earned from " .. k .. " outputs")
				end,
				width = 2,
				---@param k trade_good_id
				---@param v number
				value = function(k, v)
					return earn_outputs[k] or 0
				end
			},
			{
				header = "map",
				---@param k trade_good_id
				---@param v number
				render_closure = function(rect, k, v)
					if ut.icon_button(ASSETS.icons["mesh-ball.png"], rect,
						"Show price of ".. k .. " on map")
					then
						HACKY_MAP_MODE_CONTEXT_TRADE_CATEGORY = k
						gam.update_map_mode("prices")
					end
				end,
				width = 1,
				---@param k trade_good_id
				---@param v number
				value = function(k, v)
					return economical.get_local_price(province, k) or 0
				end
			}
		}, output_list_state, "Outputs")()

		next_panel.y = next_panel.y + 5 + next_panel.height

		-- list of inputs
		input_list_state = list_widget(next_panel, base_inputs, {
			{
				header = ".",
				render_closure = render_use_case_icon,
				width = 1,
				---@param k use_case_id
				---@param v number
				value = function(k, v)
					return DATA.use_case_get_name(k)
				end
			},
			{
				header = "name",
				---@param k string
				---@param v number
				render_closure = function(rect, k, v)
					ui.centered_text(DATA.use_case_get_name(k), rect)
				end,
				width = 8,
				---@param k use_case_id
				---@param v number
				value = function(k, v)
					return DATA.use_case_get_name(k)
				end
			},
			{
				header = "base",
				---@param k string
				---@param v number
				render_closure = function(rect, k, v)
					ui.centered_text(ut.to_fixed_point2(v), rect)
				end,
				width = 3,
				---@param k string
				---@param v number
				value = function(k, v)
					return v
				end
			},
			{
				header = "amount",
				---@param k string
				---@param v number
				render_closure = function(rect, k, v)
					ui.centered_text(ut.to_fixed_point2(amount_inputs[k] or 0), rect)
					ui.tooltip(inventory_tooltip, rect)
				end,
				width = 3,
				---@param k string
				---@param v number
				value = function(k, v)
					return amount_inputs[k] or 0
				end,
			},
			{
				header = "price",
				---@param k use_case_id
				---@param v number
				render_closure = function(rect, k, v)
					local price = economical.get_local_price_of_use(province, k) or 0
					ut.money_entry("", price, rect, ut.to_fixed_point2(price)
					.. MONEY_SYMBOL .. " spent per unit of " .. k .. " inputs", true)
				end,
				width = 2,
				---@param k use_case_id
				---@param v number
				value = function(k, v)
					local price = economical.get_local_price_of_use(province, k) or 0
					return price
				end,
			},
			{
				header = "spent",
				---@param k use_case_id
				---@param v number
				render_closure = function(rect, k, v)
					local spendings = spent_inputs[k] or 0
					ut.money_entry(
						"",
						spendings,
						rect,
						ut.to_fixed_point2(spendings) .. MONEY_SYMBOL
						.. " spent on " .. DATA.use_case_get_name(k) .. " inputs\n",
						true
					)
				end,
				width = 2,
				---@param k use_case_id
				---@param v number
				value = function(k, v)
					return spent_inputs[k] or 0
				end
			},
			{
				header = "map",
				---@param k use_case_id
				---@param v number
				render_closure = function(rect, k, v)
					if ut.icon_button(ASSETS.icons["mesh-ball.png"], rect,
					"Show price of ".. k .. " on map")
					then
						HACKY_MAP_MODE_CONTEXT_TRADE_CATEGORY = k
						gam.update_map_mode("prices_use")
					end
				end,
				width = 1,
				---@param k use_case_id
				---@param v number
				value = function(k, v)
					return economical.get_local_price_of_use(province, k) or 0
				end
			}
		}, input_list_state, "Inputs")()

		---comment
		---@param pop POP
		---@return string
		local function pop_display_occupation(pop)
			local display_name = "unemployed"
			local occupation = DATA.employment_get_job(DATA.get_employment_from_worker(pop))
			local warband = UNIT_OF(pop)
			if occupation ~= INVALID_ID then
				display_name = DATA.job_get_name(occupation)
			elseif AGE(pop) < F_RACE(pop).teen_age then
				display_name = "child"
			elseif warband ~= INVALID_ID then
				display_name = "warrior"
			end
			return display_name
		end

		next_panel.y = next_panel.y + 5 + next_panel.height

		---@type table<POP, POP>
		local workers = {}
		---@type table<POP, number>
		local workers_income = {}

		DATA.for_each_employment_from_building(building, function (item)
			local worker = DATA.employment_get_worker(item)
			workers[worker] = worker
			workers_income[worker] = DATA.employment_get_worker_income(item)
		end)

		-- list of employees
		worker_list_state = list_widget(next_panel, workers, {
			{
				header = ".",
				---@param k POP
				render_closure = function(rect, k, v)
					--ui.image(ASSETS.get_icon(v.race.icon)
					portrait_widget(rect, k)
				end,
				width = 1,
				---@param k POP
				value = function(k, v)
					return F_RACE(k).name
				end
			},
			{
				header = "name",
				---@param k POP
				render_closure = function(rect, k, v)
					ui.centered_text(NAME(k), rect)
				end,
				width = 4,
				---@param k POP
				value = function(k, v)
					return NAME(k)
				end
			},
			{
				header = "age",
				---@param k POP
				render_closure = function (rect, k, v)
					ui.centered_text(tostring(AGE(k)), rect)
				end,
				width = 2,
				---@param k POP
				value = function(k, v)
					return AGE(k)
				end
			},
			{
				header = "sex",
				---@param k POP
				render_closure = function (rect, k, v)
					local f = "m"
					if DATA.pop_get_female(k) then
						f = "f"
					end
					ui.centered_text(f, rect)
				end,
				width = 1,
				---@param k POP
				value = function(k, v)
					local f = "m"
					if DATA.pop_get_female(k) then
						f = "f"
					end
					return f
				end
			},
			{
				header = "satisfac.",
				render_closure = ut.render_pop_satsifaction,
				width = 2,
				---@param k POP
				value = function(k, v)
					return DATA.pop_get_basic_needs_satisfaction(k)
				end
			},
			{
				header = "savings",
				---@param k POP
				render_closure = function (rect, k, v)
					ut.money_entry(
						"",
						SAVINGS(k),
						rect,
						"Savings of this character. "
						.. "Characters spend them on buying food and other commodities."
					)
				end,
				width = 2,
				---@param k POP
				value = function(k, v)
					return SAVINGS(k)
				end
			},
			{
				header = "job",
				---@param k POP
				render_closure = function (rect, k, v)
					ui.centered_text(pop_display_occupation(k), rect)
				end,
				width = 3,
				---@param k POP
				value = function(k, v)
					return pop_display_occupation(k)
				end
			},
			{
				header = "work ratio.",
				render_closure = function (rect, k, v)
				ut.generic_number_field(
					"chart.png",
					DATA.pop_get_work_ratio(k),
					rect,
					"Percentage of time workers spent toiling.",
					ut.NUMBER_MODE.PERCENTAGE,
					ut.NAME_MODE.ICON)
				end,
				width = 2,
				---@param k POP
				value = function(k, v)
					return DATA.pop_get_work_ratio(k)
				end
			},
			{
				header = "efficiency",
				---@param k POP
				render_closure = function (rect, k, v)
					local tooltip = "Base productivity of this character."
					local job_efficiency = pop_utils.job_efficiency(k, DATA.production_method_get_job_type(method))
					tooltip = tooltip .. " The character's base job efficiency is ".. ut.to_fixed_point2(job_efficiency * 100) .. "%."
						.. " Province infrastructure modifies this by ".. ut.to_fixed_point2(efficiency_from_infrastructure * 100) .. "%."
					tooltip = tooltip .. " This is further changed by ".. ut.to_fixed_point2(local_method_efficiency * 100) .. "% based on the building's province."
					ut.generic_number_field(
						"",
						job_efficiency * efficiency_from_infrastructure * forage_efficiency * local_method_efficiency,
						rect,
						tooltip,
						ut.NUMBER_MODE.PERCENTAGE,
						ut.NAME_MODE.NAME
					)
				end,
				width = 2,
				---@param k POP
				value = function(k, v)
					local job_efficiency = pop_utils.job_efficiency(k, DATA.production_method_get_job_type(method))
					return job_efficiency * local_method_efficiency * forage_efficiency * efficiency_from_infrastructure
				end
			},
			{
				header = "income",
				---@param k POP
				render_closure = function (rect, k, v)
					ut.money_entry(
						"",
						workers_income[k] or 0,
						rect,
						"Net profit character made from toiling. "
					)
				end,
				width = 2,
				---@param k POP
				value = function(k, v)
					return workers_income[k] or 0
				end
			},
			{
				header = "fire",
				---@param k POP
				render_closure = function(rect, k, v)
					local icon = ASSETS.icons["cancel.png"]
					local character = WORLD.player_character
					if ut.icon_button(icon,
						rect,
						"Unemploy this character!?",
						(owner ~= INVALID_ID and owner == character)
						or
						(owner == INVALID_ID and character == LEADER(realm))
					) then
						demography_effects.fire_pop(k)
					end
				end,
				width = 1,
				---@param k POP
				value = function(k, v)

					return workers_income[k] or 0
				end
			}
		}, worker_list_state, "Workers:")()

	end
end

return re