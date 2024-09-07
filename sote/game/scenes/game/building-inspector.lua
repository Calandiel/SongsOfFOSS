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

		local topbar = ui.layout_builder()
			:position(panel.x, panel.y)
			:horizontal()
			:spacing(5)
			:build()
		ui.image(ASSETS.icons[building.type.icon], topbar:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT))
		ui.left_text(building.type.name, topbar:next(10 * ut.BASE_HEIGHT, ut.BASE_HEIGHT))

		local pan = panel:subrect(5, 5 + ut.BASE_HEIGHT, panel.width - 10, ut.BASE_HEIGHT * 3, "left", "up")
		ui.panel(pan)
		pan:shrink(5)
		ui.text(building.type.description, pan, "left", "up")
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
		if building.owner ~= nil then
			-- target character
			ib.icon_button_to_character(gam, building.owner, owner_icon)
			ib.text_button_to_character(gam, building.owner, owner_button,
				building.owner.name, building.owner.name .. " owns this building.")
		else
			-- target realm if possible
			if building.province.realm then
				ib.icon_button_to_realm(gam, building.province.realm, owner_icon)
			else
				ut.render_icon(owner_icon, "world.png", 1, 1, 1, 1)
			end
			ib.text_button_to_province(gam, building.province, owner_button,
				building.province.name, "Public builing in" .. building.province.name .. ".")
		end
		owner_icon.y = owner_icon.y + ut.BASE_HEIGHT * 2 + 10

		-- next subsity, changing values and destory, only seen by owner (or realm leader if public)
		if (not building.owner and WORLD.player_character == building.province.realm.leader)
			or (building.owner and WORLD.player_character == building.owner)
		then
			owner_button.y = owner_button.y + ut.BASE_HEIGHT + 5
			owner_button.width = ut.BASE_HEIGHT * 4
			ui.centered_text("Next subsidies", owner_button)
			owner_button.y = owner_button.y + ut.BASE_HEIGHT + 5
			ut.money_entry_icon(building.subsidy, owner_button, ut.to_fixed_point2(building.subsidy)
				.. MONEY_SYMBOL .. " to be paid to each worker next month.", true)
			owner_button.x = owner_button.x + ut.BASE_HEIGHT * 4 + 5
			owner_button.width = ut.BASE_HEIGHT
			if ut.icon_button(ASSETS.icons["plus.png"], owner_button,
				"Increase next month's subsidies by " .. ut.to_fixed_point2(BUILDING_SUBSIDY_AMOUNT) .. " per worker."
				.. "\nPress Ctrl and/or Shift to modify amount."
			) then
				building.subsidy = building.subsidy + BUILDING_SUBSIDY_AMOUNT
			end
			if ut.icon_button(
				ASSETS.icons["minus.png"], owner_icon,
				"Decrease next month's subsidies by ".. ut.to_fixed_point2(-BUILDING_SUBSIDY_AMOUNT).." per worker."
				.. "\nPress Ctrl and/or Shift to modify amount."
			) then
				building.subsidy = building.subsidy - BUILDING_SUBSIDY_AMOUNT
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

		local forage_efficiency = dbm.foraging_efficiency(building.province.foragers_limit, building.province.foragers)

		-- WORK TIME, INPUT COST, OUTPUT REVENUE

		-- ROW #1
		-- tile efficiency
		local building_efficiency = building.type.production_method:get_efficiency(building.province)
		local tooltip = "The building's production efficiency is " .. ut.to_fixed_point2(building_efficiency * 100) .. "%."
		if building.type.production_method.foraging then
			tooltip = tooltip .. " Workers forages natural resources, increasing province foragers by total working time while local foraging competition modify efficiency by " .. ut.to_fixed_point2(forage_efficiency * 100) .. "%."
		end
		local nature_yield_dependence = building.type.production_method.nature_yield_dependence
		if nature_yield_dependence > 0 then
			local nature_yield = nature_yield_dependence * building.province.foragers_limit / building.province.size
			tooltip = tooltip .. " Production is depenedent on harvesting natrual resources, as such the local resource density modify efficiency by " .. ut.to_fixed_point2(nature_yield * 100) .. "%."
		end
		local forest_dependence = building.type.production_method.forest_dependence
		if forest_dependence > 0 then
			local nature_yield = (building.province.foragers_targets[dbm.ForageResource.Wood].amount / building.province.size) * forest_dependence
			tooltip = tooltip .. " Output is harvested from available forest resources, as such the local foliage density modify efficiency by " .. ut.to_fixed_point2(nature_yield * 100) .. "% and deforests tiles."
		end
		ui.centered_text("Building efficiency", left_text_rect)
		ut.color_coded_percentage(building_efficiency, left_value_rect, true, tooltip)
		-- infra efficiency
		local inf = building.province:get_infrastructure_efficiency()
		local efficiency_from_infrastructure = math.min(1.5, 0.5 + 0.5 * math.sqrt(2 * inf))
		ui.centered_text("Infra efficiency", middle_text_rect)
		ut.color_coded_percentage(efficiency_from_infrastructure, middle_value_rect, true, "Production efficiency from province infrastructure.")
		-- worker count out of max
		local worker_cur = tabb.size(building.workers)
		local worker_max = building.type.production_method:total_jobs()
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
		ut.money_entry_icon(building.subsidy_last, left_value_rect, ut.to_fixed_point2(building.subsidy_last)
			.. MONEY_SYMBOL .. " paid to each worker last month.", true)
		-- last_donation_to_owner
		ui.centered_text("Last donation", middle_text_rect)
		ut.money_entry_icon(building.last_donation_to_owner, middle_value_rect, ut.to_fixed_point2(building.last_donation_to_owner)
			.. MONEY_SYMBOL .. " paid to the owner last month.")
		-- mean income
		ui.centered_text("Mean income", right_text_rect)
		ut.money_entry_icon(building.income_mean, right_value_rect, ut.to_fixed_point2(building.income_mean)
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
		local input_total = tabb.accumulate(building.spent_on_inputs, 0, function (a, _, v)
			return a + v
		end)
		ui.centered_text("Input costs", left_text_rect)
		ut.money_entry_icon(input_total, left_value_rect, ut.to_fixed_point2(input_total)
			.. MONEY_SYMBOL  .. " spent on inputs last month.", true)
		-- output profits
		local output_total = tabb.accumulate(building.earn_from_outputs, 0, function (a, _, v)
			return a + v
		end)
		ui.centered_text("Output revenue", middle_text_rect)
		ut.money_entry_icon(output_total, middle_value_rect,ut.to_fixed_point2(output_total)
			..  MONEY_SYMBOL .. " earned from outputs last month.")
		-- average revinue per worker
		ui.centered_text("Total profits", right_text_rect)
		ut.money_entry_icon(output_total, right_value_rect,ut.to_fixed_point2((output_total - input_total))
			..  MONEY_SYMBOL .. " earned after paying for inputs.")

		-- INPUT OUTPUT AND WORKER TABLES

		---@param k string
		---@param v number
		local function render_good_icon(rect, k , v)
			local good = trade_good(k)
                ut.render_icon(rect:copy():shrink(-1), good.icon, 1, 1, 1, 1)
                ut.render_icon(rect, good.icon, good.r, good.g, good.b, 1)
		end
		---@param k string
		---@param v number
		local function render_use_case_icon(rect, k , v)
			local case = use_case(k)
                ut.render_icon(rect:copy():shrink(-1), case.icon, 1, 1, 1, 1)
                ut.render_icon(rect, case.icon, case.r, case.g, case.b, 1)
		end

		local next_panel = owner_icon:subrect(0, ut.BASE_HEIGHT * 4 + 5, pan.width, ut.BASE_HEIGHT * 6, "left", "up")

		-- list of outputs
		local outputs = building.amount_of_outputs
		if not building.amount_of_outputs or tabb.size(outputs) < 1 then
			outputs = building.type.production_method.outputs
		end
		output_list_state = list_widget(next_panel, outputs, {
			{
				header = ".",
				render_closure = render_good_icon,
				width = 1,
				---@param k string
				---@param v number
				value = function(k, v)
					return trade_good(k).name
				end
			},
			{
				header = "name",
				---@param k string
				---@param v number
				render_closure = function(rect, k, v)
					ui.centered_text(k, rect)
				end,
				width = 8,
				---@param k string
				---@param v number
				value = function(k, v)
					return k
				end
			},
			{
				header = "base",
				---@param k string
				---@param v number
				render_closure = function(rect, k, v)
					ui.centered_text(ut.to_fixed_point2(building.type.production_method.outputs[k] or 0), rect)
				end,
				width = 3,
				---@param k string
				---@param v number
				value = function(k, v)
					return building.type.production_method.outputs[v] or 0
				end,
			},
			{
				header = "amount",
				---@param k string
				---@param v number
				render_closure = function(rect, k, v)
					ui.centered_text(ut.to_fixed_point2(building.amount_of_outputs[k] or 0), rect)
				end,
				width = 3,
				---@param k string
				---@param v number
				value = function(k, v)
					return building.amount_of_outputs[k] or 0
				end,
			},
			{
				header = "price",
				---@param k string
				---@param v number
				render_closure = function(rect, k, v)
					local price = economical.get_local_price(building.province, k) or 0
					ut.money_entry("", price, rect, ut.to_fixed_point2(price)
					.. MONEY_SYMBOL .. " earned per unit of " .. k .. " outputs")
				end,
				width = 2,
				---@param k string
				---@param v number
				value = function(k, v)
					local price = economical.get_local_price(building.province, k) or 0
					return price
				end,
			},
			{
				header = "profit",
				---@param k string
				---@param v number
				render_closure = function(rect, k, v)
					local earnings = building.earn_from_outputs[k] or 0
					ut.money_entry("", earnings, rect, ut.to_fixed_point2(earnings)
					.. MONEY_SYMBOL .. " earned from " .. k .. " outputs")
				end,
				width = 2,
				---@param k string
				---@param v number
				value = function(k, v)
					return building.earn_from_outputs[k] or 0
				end
			},
			{
				header = "map",
				---@param k string
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
				---@param k string
				---@param v number
				value = function(k, v)
					return economical.get_local_price(building.province, k) or 0
				end
			}
		}, output_list_state, "Outputs")()

		next_panel.y = next_panel.y + 5 + next_panel.height

		-- list of inputs
		input_list_state = list_widget(next_panel, building.type.production_method.inputs, {
			{
				header = ".",
				render_closure = render_use_case_icon,
				width = 1,
				---@param k string
				---@param v number
				value = function(k, v)
					return use_case(k).name
				end
			},
			{
				header = "name",
				---@param k string
				---@param v number
				render_closure = function(rect, k, v)
					ui.centered_text(k, rect)
				end,
				width = 8,
				---@param k string
				---@param v number
				value = function(k, v)
					return k
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
					ui.centered_text(ut.to_fixed_point2(building.amount_of_inputs[k] or 0), rect)
				end,
				width = 3,
				---@param k string
				---@param v number
				value = function(k, v)
					return building.amount_of_inputs[k] or 0
				end,
			},
			{
				header = "price",
				---@param k string
				---@param v number
				render_closure = function(rect, k, v)
					local price = economical.get_local_price_of_use(building.province, k) or 0
					ut.money_entry("", price, rect, ut.to_fixed_point2(price)
					.. MONEY_SYMBOL .. " spent per unit of " .. k .. " inputs", true)
				end,
				width = 2,
				---@param k string
				---@param v number
				value = function(k, v)
					local price = economical.get_local_price_of_use(building.province, k) or 0
					return price
				end,
			},
			{
				header = "spent",
				---@param k string
				---@param v number
				render_closure = function(rect, k, v)
					local spendings = building.spent_on_inputs[k] or 0
					ut.money_entry("", spendings, rect, ut.to_fixed_point2(spendings)
					.. MONEY_SYMBOL .. " spent on " .. k .. " inputs", true)
				end,
				width = 2,
				---@param k string
				---@param v number
				value = function(k, v)
					return building.spent_on_inputs[k] or 0
				end
			},
			{
				header = "map",
				---@param k string
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
				---@param k string
				---@param v number
				value = function(k, v)
					return economical.get_local_price_of_use(building.province, k) or 0
				end
			}
		}, input_list_state, "Inputs")()

		---comment
		---@param pop POP
		---@return string
		local function pop_display_occupation(pop)
			local job = "unemployed"
			if pop.job then
				job = pop.job.name
			elseif pop.age < pop.race.teen_age then
				job = "child"
			elseif pop.unit_of_warband then
				job = "warrior"
			end
			return job
		end

		next_panel.y = next_panel.y + 5 + next_panel.height

		-- list of employees
		worker_list_state = list_widget(next_panel, building.workers, {
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
					return k.race.name
				end
			},
			{
				header = "name",
				---@param k POP
				render_closure = function(rect, k, v)
					ui.centered_text(k.name, rect)
				end,
				width = 4,
				---@param k POP
				value = function(k, v)
					return k.name
				end
			},
			{
				header = "age",
				---@param k POP
				render_closure = function (rect, k, v)
					ui.centered_text(tostring(k.age), rect)
				end,
				width = 2,
				---@param k POP
				value = function(k, v)
					return k.age
				end
			},
			{
				header = "sex",
				---@param k POP
				render_closure = function (rect, k, v)
					local f = "m"
					if k.female then
						f = "f"
					end
					ui.centered_text(f, rect)
				end,
				width = 1,
				---@param k POP
				value = function(k, v)
					local f = "m"
					if k.female then
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
					return k.basic_needs_satisfaction
				end
			},
			{
				header = "savings",
				---@param k POP
				render_closure = function (rect, k, v)
					ut.money_entry(
						"",
						k.savings,
						rect,
						"Savings of this character. "
						.. "Characters spend them on buying food and other commodities."
					)
				end,
				width = 2,
				---@param k POP
				value = function(k, v)
					return k.savings
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
					v.work_ratio,
					rect,
					"Percentage of time workers spent toiling.",
					ut.NUMBER_MODE.PERCENTAGE,
					ut.NAME_MODE.ICON)
				end,
				width = 2,
				---@param k POP
				value = function(k, v)
					return k.basic_needs_satisfaction
				end
			},
			{
				header = "efficiency",
				---@param k POP
				render_closure = function (rect, k, v)
					local tooltip = "Base productivity of this character."
					local job_efficiency = k:job_efficiency(building.type.production_method.job_type)
					tooltip = tooltip .. " The character's base job efficiency is ".. ut.to_fixed_point2(job_efficiency * 100) .. "%."
						.. " Province infrastructure modifies this by ".. ut.to_fixed_point2(efficiency_from_infrastructure * 100) .. "%."
					local tile_efficiency = 1
						tile_efficiency = building.type.production_method:get_efficiency(building.province)
						tooltip = tooltip .. " This is further changed by ".. ut.to_fixed_point2(tile_efficiency * 100) .. "% based on the building's province."
					ut.generic_number_field(
						"",
						job_efficiency * efficiency_from_infrastructure * forage_efficiency,
						rect,
						tooltip,
						ut.NUMBER_MODE.PERCENTAGE,
						ut.NAME_MODE.NAME
					)
				end,
				width = 2,
				---@param k POP
				value = function(k, v)
					local job_efficiency = k:job_efficiency(building.type.production_method.job_type)
					job_efficiency = job_efficiency * building.type.production_method:get_efficiency(building.province)
					if building.type.production_method.foraging then
						job_efficiency = job_efficiency * forage_efficiency
					end
					return job_efficiency * efficiency_from_infrastructure
				end
			},
			{
				header = "income",
				---@param k POP
				render_closure = function (rect, k, v)
					ut.money_entry(
						"",
						building.worker_income[k] or 0,
						rect,
						"Net profit character made from toiling. "
					)
				end,
				width = 2,
				---@param k POP
				value = function(k, v)
					return building.worker_income[k] or 0
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
						(building.owner and building.owner == character)
							or (not building.owner and character == building.province.realm.leader)
					) then
						building.province:fire_pop(k)
					end
				end,
				width = 1,
				---@param k POP
				value = function(k, v)

					return building.worker_income[k] or 0
				end
			}
		}, worker_list_state, "Workers:")()

	end
end

return re