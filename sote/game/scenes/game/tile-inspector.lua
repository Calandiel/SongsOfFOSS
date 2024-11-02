-- TODO: this file needs to be split up into smaller, more managable files.
-- Perhaps have a file per "tab"?

local re = {}
local ui = require "engine.ui"
local uit = require "game.ui-utils"
local tabb = require "engine.table"

local ef = require "game.raws.effects.economy"
local btb = require "game.scenes.game.widgets.building-type-buttons"

local dbm = require "game.economy.diet-breadth-model"

local tile_utils = require "game.entities.tile"
local province_utils = require "game.entities.province".Province
local warband_utils = require "game.entities.warband"
local building_type_tooltip = require "game.raws.building-types".get_tooltip
local remove_building = require "game.entities.building".Building.remove_from_province
local military_effects = require "game.raws.effects.military"

re.cached_scrollbar = 0
---@alias TileCharacterTab "All" | "Home" | "Guest"
---@type TileCharacterTab
re.cached_character_tab = "All"

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
	local panel = fs:subrect(uit.BASE_HEIGHT * 2, 0, uit.BASE_HEIGHT * 16, uit.BASE_HEIGHT * 25, "left", "down")
	return panel
end

---Returns whether or not clicks on the planet can be registered.
---@return boolean
function re.mask(gam)
	if ui.trigger(get_main_panel()) then
		return false
	else
		return true
	end
end

---comment
---@param gam GameScene
---@param tile_id tile_id
---@param panel Rect
local function header_panel(gam, tile_id, panel)
	local base_unit = uit.BASE_HEIGHT

	local province_name_rect = panel:subrect(0, 0, panel.width / 2, base_unit, "left", "up")
	local province_id = tile_utils.province(tile_id)
	local province = DATA.fatten_province(province_id)

	uit.data_entry(
		"",
		province.name,
		province_name_rect
	)

	local infra_panel = panel:subrect(0, base_unit, base_unit * 3, base_unit, "left", "up")
	uit.generic_number_field(
		"horizon-road.png",
		province_utils.get_infrastructure_efficiency(province_id),
		infra_panel,
		"Local infrastructure efficiency",
		uit.NUMBER_MODE.PERCENTAGE,
		uit.NAME_MODE.ICON
	)

	local mood_panel = infra_panel
	mood_panel.y = mood_panel.y + mood_panel.height
	uit.generic_number_field(
		"duality-mask.png",
		province.mood,
		infra_panel,
		"Local mood",
		uit.NUMBER_MODE.BALANCE,
		uit.NAME_MODE.ICON
	)

	local population_panel = mood_panel
	population_panel.y = population_panel.y - population_panel.height
	population_panel.x = population_panel.x + population_panel.width
	uit.generic_number_field(
		"minions.png",
		province_utils.local_population(province_id),
		population_panel,
		"Local population",
		uit.NUMBER_MODE.INTEGER,
		uit.NAME_MODE.ICON
	)

	local unemployed_panel = population_panel
	unemployed_panel.y = unemployed_panel.y + unemployed_panel.height
	uit.generic_number_field(
		"shrug.png",
		province_utils.get_unemployment(province_id),
		population_panel,
		"Local unemployed population",
		uit.NUMBER_MODE.INTEGER,
		uit.NAME_MODE.ICON
	)
	local character_panel = unemployed_panel
	character_panel.y = character_panel.y - character_panel.height
	character_panel.x = character_panel.x + character_panel.width

	local characters_count = 0

	DATA.for_each_character_location_from_location(province_id, function (item)
		characters_count = characters_count + 1
	end)

	uit.generic_number_field(
		"inner-self.png",
		characters_count,
		population_panel,
		"Local character count",
		uit.NUMBER_MODE.INTEGER,
		uit.NAME_MODE.ICON
	)

	local warrior_panel = character_panel
	warrior_panel.y = warrior_panel.y + warrior_panel.height
	uit.generic_number_field(
		"barbute.png",
		tabb.accumulate(
			DATA.filter_warband_location_from_location(province_id, function (item)
				return true
			end),
			0,
			function (a, k, v)
				local warband = DATA.warband_location_get_warband(v)
				return a + warband_utils.war_size(warband)
			end
		),
		population_panel,
		"Local warrior count",
		uit.NUMBER_MODE.INTEGER,
		uit.NAME_MODE.ICON
	)
end

local INVESTMENT_AMOUNT = 1

---comment
---@param gam GameScene
---@param tile_id tile_id
---@param panel Rect
local function infrastructure_widget(gam, tile_id, panel)
	if ui.is_key_held("lshift") or ui.is_key_held("rshift") then
		INVESTMENT_AMOUNT = 5
	elseif ui.is_key_held("lctrl") or ui.is_key_held("rctrl") then
		INVESTMENT_AMOUNT = 50
	else
		INVESTMENT_AMOUNT = 1
	end

	panel:shrink(3)
	ui.panel(panel, 3)
	panel:shrink(3)

	local base_unit = uit.BASE_HEIGHT
	local realm_id = tile_utils.realm(tile_id)
	local province_id = tile_utils.province(tile_id)

	if realm_id == INVALID_ID then
		return
	end

	local province = DATA.fatten_province(province_id)
	local realm = DATA.fatten_realm(realm_id)

	---comment
	---@return fun(rect: Rect)
	local function invest_button()
		return function(rect)
			local potential = realm.budget_treasury > INVESTMENT_AMOUNT
			local tooltip =
				"Invest "
				.. tostring(INVESTMENT_AMOUNT)
				.. MONEY_SYMBOL
				.. ". Press Ctrl or Shift to modify invested amount."

			if uit.money_button(
					"Invest",
					INVESTMENT_AMOUNT,
					rect,
					tooltip,
					potential
				) then
				ef.direct_investment_infrastructure(realm_id, province_id, INVESTMENT_AMOUNT)
			end
		end
	end

	uit.rows(
		{
			function(rect)
				uit.money_entry(
					"Inf.: ",
					province.infrastructure,
					rect,
					"Local infrastructure"
				)
			end,
			function(rect)
				uit.money_entry(
					"Inf. inv: ",
					province.infrastructure_investment,
					rect,
					"Infrastructure investment"
				)
			end,
			function(rect)
				uit.money_entry(
					"Req inf.: ",
					province.infrastructure_needed,
					rect,
					"Required infrastructure"
				)
			end,
			function(rect)
				local sat = 0
				if province.infrastructure_needed > 0 then
					sat = province.infrastructure / province.infrastructure_needed
				end
				uit.data_entry_percentage(
					"Inf. sat: ",
					sat,
					rect,
					"Infrastructure satisfaction"
				)
			end,

			function(rect)
				if WORLD:does_player_control_realm(realm_id) then
					invest_button()(rect)
				end
			end,
		},
		panel,
		base_unit
	)
end

---comment
---@param gam GameScene
---@param tile_id tile_id
---@param panel Rect
local function demography_widget(gam, tile_id, panel)
	panel:shrink(3)
	ui.panel(panel, 3)
	panel:shrink(3)

	local base_unit = uit.BASE_HEIGHT
	local realm = tile_utils.realm(tile_id)
	local province = tile_utils.province(tile_id)

	require "game.scenes.game.widgets.demography" ({ province }, panel, true)()
end

---comment
---@param gam GameScene
---@param tile_id tile_id
---@param panel Rect
local function realm_widget(gam, tile_id, panel)
	panel:shrink(3)
	ui.panel(panel, 3)
	panel:shrink(3)

	panel:shrink(5)

	local base_unit = uit.BASE_HEIGHT
	local realm = tile_utils.realm(tile_id)
	local province = tile_utils.province(tile_id)
	local player = WORLD.player_character

	if realm == nil then
		return
	end

	local base_unit = uit.BASE_HEIGHT

	local layout = ui.layout_builder()
		:position(panel.x, panel.y)
		:spacing(0)
		:vertical()
		:build()

	local buttons_grid_panel = layout:next(panel.width, base_unit * 3)

	local buttons_grid = ui.layout_builder()
		:position(buttons_grid_panel.x, buttons_grid_panel.y)
		:grid(2)
		:spacing(5)
		:build()

	if uit.icon_button(
			ASSETS.icons["frog-prince.png"],
			buttons_grid:next(UI_STYLE.square_button_large, UI_STYLE.square_button_large),
			"Take control over character from this country",
			player == INVALID_ID
		) then
		-- gam.refresh_map_mode()
		gam.inspector = "characters"
		gam.selected.province = tile_utils.province(tile_id)
	end

	if player ~= INVALID_ID then
		local raid_rect = buttons_grid:next(UI_STYLE.square_button_large, UI_STYLE.square_button_large)
		local patrol_rect = buttons_grid:next(UI_STYLE.square_button_large, UI_STYLE.square_button_large)

		local patrol = RAWS_MANAGER.decisions_characters_by_name["patrol-target"]
		local raid = RAWS_MANAGER.decisions_characters_by_name["personal-raid"]

		local raid_tooltip = raid.tooltip(player, tile_utils.province(tile_id))
		local patrol_tooltip = patrol.tooltip(player, tile_utils.province(tile_id))

		local raid_potential = raid.clickable(player, tile_utils.province(tile_id)) and raid.pretrigger(player) and
			raid.available(player, tile_utils.province(tile_id))
		local patrol_potential = patrol.clickable(player, tile_utils.province(tile_id)) and patrol.pretrigger(player) and
			patrol.available(player, tile_utils.province(tile_id))

		if uit.icon_button(
				ASSETS.icons["stone-spear.png"],
				raid_rect,
				raid_tooltip,
				raid_potential
			) then
			raid.effect(player, tile_utils.province(tile_id))
		end

		if uit.icon_button(
				ASSETS.icons["round-shield.png"],
				patrol_rect,
				patrol_tooltip,
				patrol_potential
			) then
			patrol.effect(player, tile_utils.province(tile_id))
		end
	end
end

local function main_panel(gam, tile, panel)
	local layout = ui.layout_builder()
		:position(panel.x, panel.y)
		:spacing(0)
		:horizontal()
		:build()

	infrastructure_widget(gam, tile, layout:next(uit.BASE_HEIGHT * 7, panel.height))
	demography_widget(gam, tile, layout:next(uit.BASE_HEIGHT * 4, panel.height))
	realm_widget(gam, tile, layout:next(uit.BASE_HEIGHT * 5, panel.height))
end

local function military_widget(gam, tile_id, panel)
	panel:shrink(3)
	ui.panel(panel, 3)
	panel:shrink(3)

	panel:shrink(5)

	local unit = uit.BASE_HEIGHT
	local province_id = tile_utils.province(tile_id)

	local layout = ui.layout_builder()
		:position(panel.x, panel.y)
		:spacing(0)
		:grid(3)
		:build()

	local visibility = WORLD:base_visibility(1)
	uit.data_entry_percentage(
		"Spot (1): ",
		province_utils.spot_chance(province_id, visibility),
		layout:next(unit * 5, unit * 1),
		"Chance to spot an army of 1 human raider."
	)
	local visibility = WORLD:base_visibility(10)
	uit.data_entry_percentage(
		"Spot (10): ",
		province_utils.spot_chance(province_id, visibility),
		layout:next(unit * 5, unit * 1),
		"Chance to spot an army of 10 human raiders."
	)
	local visibility = WORLD:base_visibility(50)
	uit.data_entry_percentage(
		"Spot (50): ",
		province_utils.spot_chance(province_id, visibility),
		layout:next(unit * 5, unit * 1),
		"Chance to spot an army of 50 human raiders."
	)
	uit.count_entry(
		"Hiding: ",
		province_utils.get_hiding(province_id),
		layout:next(unit * 5, unit * 1),
		"The weighted amount of land that can be hidden in. Expressed as an equivalent number of grassland tiles."
	)
	uit.count_entry(
		"Mov. cost: ",
		DATA.province_get_movement_cost(province_id),
		layout:next(unit * 5, unit * 1),
		"Movement cost, in hours"
	)
end

---comment
---@param gam GameScene
---@param tile_id tile_id
---@param panel Rect
local function trade_widget(gam, tile_id, panel)
	panel:shrink(3)
	ui.panel(panel, 3)
	panel:shrink(3)

	panel:shrink(5)

	local unit = uit.BASE_HEIGHT

	local layout = ui.layout_builder()
		:position(panel.x, panel.y)
		:spacing(5)
		:grid(4)
		:build()

	local province_id = tile_utils.province(tile_id)
	local province = DATA.fatten_province(province_id)

	uit.generic_number_field(
		"fruit-bowl.png",
		province.foragers_limit,
		layout:next(unit * 3.5, unit * 1),
		"The carrying capacity of this province is determined by the amount of energy foragable. The total calories avialable in this province can support about " .. uit.to_fixed_point2(province.foragers_limit)
			.." adult humans from foraging " .. province.size .." tiles.",
		uit.NUMBER_MODE.BALANCE,
		uit.NAME_MODE.ICON
	)

	local pop_weight = province_utils.population_weight(province_id)
	uit.generic_number_field(
		"ages.png",
		pop_weight,
		layout:next(unit * 3.5, unit * 1),
		"This province is currently carrying the equivalent of " .. uit.to_fixed_point2(pop_weight)
			.. " adult humans.",
		uit.NUMBER_MODE.NUMBER,
		uit.NAME_MODE.ICON
	)

	local foraging_efficiency = dbm.foraging_efficiency(province.foragers_limit, province.foragers)
	uit.generic_number_field(
		"basket.png",
		foraging_efficiency,
		layout:next(unit * 3.5, unit * 1),
		"There are currently the equivalent of " .. uit.to_fixed_point2(province.foragers)
			.. " adult human foragers collecting food full-time, pulling "
			.. uit.to_fixed_point2(province.foragers / (province.foragers_limit > 0 and province.foragers_limit or 1) * 100).. "% of avaialable resources.",
		uit.NUMBER_MODE.PERCENTAGE,
		uit.NAME_MODE.ICON
	)

	local hydration_efficiency = dbm.foraging_efficiency(province.hydration * 0.5, province.foragers_water)
	uit.generic_number_field(
		"full-wood-bucket.png",
		hydration_efficiency,
		layout:next(unit * 3.5, unit * 1),
		"There are currently the equivalent of " .. uit.to_fixed_point2(province.foragers_water)
			.. " adult human foragers collecting water full-time, pulling "
			.. uit.to_fixed_point2(province.foragers_water / province.hydration * 100).. "% of avaialable water.",
		uit.NUMBER_MODE.PERCENTAGE,
		uit.NAME_MODE.ICON
	)

	local province_size = DATA.province_get_size(province_id)

	for i = 1, MAX_RESOURCES_IN_PROVINCE_INDEX - 1 do
		local forage_case = DATA.province_get_foragers_targets_forage(province_id, i)

		if forage_case == FORAGE_RESOURCE.INVALID then
			break
		end

		local required_job =  DATA.forage_resource_get_handle(forage_case)
		local amount = DATA.province_get_foragers_targets_amount(province_id, i)
		local output_good = DATA.province_get_foragers_targets_output_good(province_id, i)

		if output_good == INVALID_ID then
			break
		end

		local output_value = DATA.province_get_foragers_targets_output_value(province_id, i)

		---@type number
		local search_time = province_size / amount / 10
		local efficiency = dbm.mean_race_job_efficiency(HUMAN, required_job)
		local handle_time = 1 / efficiency

		local total_time = search_time + handle_time

		local name = DATA.forage_resource_get_name(forage_case)
		local action = DATA.forage_resource_get_handle(forage_case)

		local output_good_name = DATA.trade_good_get_name(output_good)

		uit.generic_number_field(
			DATA.forage_resource_get_icon(forage_case),
			amount,
			layout:next(unit * 3.5, unit * 1),
			"The average adult human can expect to collect " .. uit.to_fixed_point2(1 / total_time) .. " units of "
				.. name .. " " .. action
				.. " for it full time from the total " .. uit.to_fixed_point2(amount)
				.. " spread over of the province's " .. uit.to_fixed_point2(province.size)
				.. " tiles.\n · Foraging one unit of " .. name
				.. " produces:\n  · " .. output_good_name .. " (" .. uit.to_fixed_point2(output_value) .. ")" .. "\n · The output of " .. action .. " " .. name
				.. " is further modified by a pop's racial job efficiencies, age, and needs satisfactions.",
			uit.NUMBER_MODE.BALANCE,
			uit.NAME_MODE.ICON
		)
	end

	---@type string
	local resource_string = ""
	local resource_tooltip = "There is no special resource on this tile."
	local resource_icon = "uncertainty.png"
	local has_resource = false
	for i = 1, MAX_RESOURCES_IN_PROVINCE_INDEX - 1 do
		local resource = DATA.province_get_local_resources_resource(province_id, i)
		if resource == INVALID_ID then
			break
		end
		local name = DATA.resource_get_name(resource)
		has_resource = true

		---@type string
		resource_string = resource_string .. name .. ", "
	end

	if has_resource then
		-- resource_string = resource_string:sub(1, -3)
		resource_tooltip = "This tile has sources of " .. resource_string .. "."
	else
		resource_string = "n/a"
	end

	uit.generic_string_field(
		"Res.",
		resource_string,
		layout:next(unit * 3.5 * 4 + 15, unit * 1),
		resource_tooltip,
		uit.NAME_MODE.NAME
	)
end

---comment
---@param gam GameScene
---@param tile_id tile_id
---@param panel Rect
local function separate_inspectors(gam, tile_id, panel)
	local layout = ui.layout_builder()
		:position(panel.x + 5, panel.y)
		:spacing(5)
		:horizontal()
		:build()

	if uit.icon_button(
			ASSETS.icons["scales.png"],
			layout:next(UI_STYLE.square_button_large, UI_STYLE.square_button_large),
			"Show market"
		) then
		gam.inspector = "market"
	end

	if uit.icon_button(
			ASSETS.icons["minions.png"],
			layout:next(UI_STYLE.square_button_large, UI_STYLE.square_button_large),
			"Show population"
		) then
		gam.inspector = "population"
	end

	if uit.icon_button(
		ASSETS.icons["guards.png"],
		layout:next(UI_STYLE.square_button_large, UI_STYLE.square_button_large),
		"Show local warriors"
	) then
		gam.inspector = "army"
	end
end

local function bottom_panel(gam, tile_id, panel)
	local unit = uit.BASE_HEIGHT

	local layout = ui.layout_builder()
		:position(panel.x, panel.y)
		:spacing(0)
		:vertical()
		:build()

	separate_inspectors(gam, tile_id, layout:next(panel.width, unit * 2))
	military_widget(gam, tile_id, layout:next(panel.width, unit * 3))
	trade_widget(gam, tile_id, layout:next(panel.width, unit * 6))
end

---comment
---@param gam GameScene
---@param tile_id tile_id
---@param panel Rect
local function general_tab(gam, tile_id, panel)
	local unit = uit.BASE_HEIGHT

	local layout = ui.layout_builder()
		:position(panel.x, panel.y)
		:spacing(0)
		:vertical()
		:build()

	header_panel(gam, tile_id, layout:next(panel.width, unit * 4))
	main_panel(gam, tile_id, layout:next(panel.width, unit * 8))
	bottom_panel(gam, tile_id, layout:next(panel.width, unit * 12))
end

---comment
---@param gam GameScene
---@param tile_id tile_id
---@param panel Rect
local function geography_tab(gam, tile_id, panel)
	local lat, lon = tile_utils.latlon(tile_id)
	local jan_r, jan_t, jul_r, jul_t = tile_utils.get_climate_data(tile_id)
	local tile = DATA.fatten_tile(tile_id)
	local province = tile_utils.province(tile_id)
	uit.columns(
		{
			function(rect)
				uit.rows({
					function(rect)
						uit.data_entry("Elevation:", tostring(math.floor(tile.elevation)), rect)
					end,
					function(rect)
						uit.data_entry("Latitude: ", tostring(math.floor(lat * 100) / 100), rect,
							"In radians")
					end,
					function(rect)
						uit.data_entry("Longitude: ", tostring(math.floor(lon * 100) / 100), rect,
							"In radians")
					end,
					function(rect)
						uit.data_entry("Size: ", tostring(DATA.province_get_size(province)), rect, "In tiles")
					end,
					function(rect)
						uit.data_entry("Bedrock:", DATA.bedrock_get_name(tile.bedrock), rect)
					end,
					function(rect)
						ui.centered_text("Soil texture", rect)
					end,
					function(rect)
						uit.graph({
							{
								weight = tile.sand,
								tooltip = "Sand (" .. math.floor(tile.sand * 100) .. "%)",
								r = 1,
								g = 0,
								b = 0,
							},
							{
								weight = tile.clay,
								tooltip = "Clay (" .. math.floor(tile.clay * 100) .. "%)",
								r = 0,
								g = 0,
								b = 1,
							},
							{
								weight = tile.silt,
								tooltip = "Silt (" .. math.floor(tile.silt * 100) .. "%)",
								r = 0,
								g = 1,
								b = 0,
							},
						}, rect)
					end,
					function(rect)
						uit.data_entry("Soil depth:", tostring(math.floor(tile_utils.soil_depth(tile_id) * 100) / 100), rect,
							"In meters")
					end,
					function(rect)
						uit.data_entry("Soil perm.:", tostring(math.floor(tile_utils.soil_permeability(tile_id) * 100) / 100), rect,
							"Soil permeability, abstract unit")
					end,
					function(rect)
						uit.data_entry("Soil minerals:", tostring(math.floor(tile.soil_minerals * 100) / 100), rect,
							"Fraction")
					end,
					function(rect)
						uit.data_entry("Soil organics:", tostring(math.floor(tile.soil_organics * 100) / 100), rect,
							"Fraction")
					end,
				}, rect)
			end,
			function(rect)
				uit.rows(
					{
						function(rect)
							ui.centered_text("Local plants", rect)
						end,
						function(rect)
							uit.graph({
								{
									weight = 1 - tile.grass - tile.shrub - tile.conifer - tile.broadleaf,
									tooltip = "Bare ground (" ..
										math.floor((1 - tile.grass - tile.shrub - tile.conifer - tile.broadleaf) * 100) ..
										"%)",
									r = 0.2,
									g = 0.1,
									b = 0.1
								},
								{
									weight = tile.grass,
									tooltip = "Grass (" .. math.floor(tile.grass * 100) .. "%)",
									r = 0,
									g = 1,
									b = 0
								},
								{
									weight = tile.shrub,
									tooltip = "Shrub (" .. math.floor(tile.shrub * 100) .. "%)",
									r = 1,
									g = 0,
									b = 0
								},
								{
									weight = tile.conifer,
									tooltip = "Conifer (" .. math.floor(tile.conifer * 100) .. "%)",
									r = 0,
									g = 1,
									b = 1
								},
								{
									weight = tile.broadleaf,
									tooltip = "Broadleaf (" .. math.floor(tile.broadleaf * 100) .. "%)",
									r = 0,
									g = 0,
									b = 1
								},
							}, rect)
						end,
						function(rect)
							uit.data_entry("", DATA.biome_get_name(tile.biome), rect, "Biome")
						end,
						function(rect)
							uit.count_entry(
								"LCC:",
								require "game.ecology.carrying-capacity".get_tile_carrying_capacity(tile_id),
								rect,
								"Local carrying capacity expressed in adult humans per tile."
							)
						end,

						function(rect)
							uit.data_entry("Jan. temp:", tostring(math.floor(jan_t)), rect, "January temperature")
						end,
						function(rect)
							uit.data_entry("Jan. rain:", tostring(math.floor(jan_r)), rect, "January rainfall")
						end,
						function(rect)
							uit.data_entry("Jan. flow:", tostring(math.floor(tile.january_waterflow)), rect,
								"January waterflow")
						end,
						function(rect)
							uit.data_entry("Ice:", tostring(math.floor(tile.ice)), rect, "Ice")
						end,
						function(rect)
							local kopp = require "game.climate.koppen"
							local k = kopp.get_koppen(jan_t, jul_t, jan_r, jul_r, DATA.tile_get_is_land(tile_id))
							uit.data_entry("Koppen:", k, rect, "Koppen climate classification")
						end,
						function(rect)
							uit.data_entry("Jul. temp:", tostring(math.floor(jul_t)), rect, "July temperature")
						end,
						function(rect)
							uit.data_entry("Jul. rain:", tostring(math.floor(jul_r)), rect, "July rainfall")
						end,
						function(rect)
							uit.data_entry("Jul. flow:", tostring(math.floor(tile.july_waterflow)), rect,
								"July waterflow")
						end,
						function(rect)
							uit.data_entry("Ice (ice age):", tostring(math.floor(tile.ice_age_ice)), rect,
								"Ice cover during the last glacial maximum")
						end,
					},
					rect
				)
			end
		},
		panel,
		panel.width / 2.1
	)
end

---comment
---@param gam GameScene
---@param tile_id tile_id
---@param panel Rect
local function buildings_construction_tab(gam, tile_id, panel)
	local base_unit = uit.BASE_HEIGHT

	local rr = panel.height
	panel.height = base_unit
	ui.centered_text("Construction", panel)
	panel.height = rr - base_unit
	panel.y = panel.y + base_unit
	re.building_construction_scrollbar = re.building_construction_scrollbar or 0

	local province_id = tile_utils.province(tile_id)

	---@type building_type_id[]
	local building_types = {}
	local amount = 0

	DATA.for_each_building_type(function (item)
		if DATA.province_get_buildable_buildings(province_id, item) == 1 then
			table.insert(building_types, item)
			amount = amount + 1
		end
	end)

	re.building_construction_scrollbar = uit.scrollview(
		panel,
		function(number, rect)
			if number > 0 then
				local building_type = tabb.nth(building_types, number)
				btb.building_type_buttons(
					gam,
					rect,
					building_type,
					tile_id
				)
			end
		end,
		UI_STYLE.scrollable_list_item_height,
		amount,
		UI_STYLE.slider_width,
		re.building_construction_scrollbar
	)
end


---comment
---@param gam GameScene
---@param tile_id tile_id
---@param rect Rect
local function buildings_view_tab(gam, tile_id, rect)
	local base_unit = uit.BASE_HEIGHT

	if re.building_stacks == nil then
		re.building_stacks = true
	end

	local province_id = tile_utils.province(tile_id)

	local rr = rect.height
	local rw = rect.width
	rect.height = base_unit
	ui.centered_text("Buildings", rect)
	rect.width = base_unit
	if re.building_stacks then
		if uit.icon_button(ASSETS.icons["cubes.png"], rect, "Show individual buildings") then
			re.building_stacks = not re.building_stacks
		end
	else
		if uit.icon_button(ASSETS.icons["cubeforce.png"], rect, "Show building types") then
			re.building_stacks = not re.building_stacks
		end
	end
	rect.width = rw

	rect.height = rr - base_unit
	rect.y = rect.y + base_unit

	if re.building_stacks then
		-- Show buildings at stacks
		---@type table<building_type_id, number>
		local stacks = {}
		local size = 0
		DATA.for_each_building_location_from_location(province_id, function (item)
			local building = DATA.building_location_get_building(item)
			local building_type = DATA.building_get_current_type(building)
			if stacks[building_type] == nil then
				stacks[building_type] = 1
				size = size + 1
			else
				stacks[building_type] = stacks[building_type] + 1
			end
		end)

		re.buildings_scrollbar = re.buildings_scrollbar or 0
		re.buildings_scrollbar = uit.scrollview(rect,
			function(number, rect)
				if number > 0 then
					---@type BuildingType
					local building_type, amount = tabb.nth(stacks, number)
					ui.tooltip(building_type_tooltip(building_type), rect)
					---@type Rect
					local r = rect
					local im = r:subrect(0, 0, base_unit, base_unit, "left", "up")
					ui.image(ASSETS.icons[DATA.building_type_get_icon(building_type)], im)
					rect.x = rect.x + base_unit
					rect.width = rect.width - base_unit

					uit.integer_entry(DATA.building_type_get_name(building_type), amount or 1, rect)
				end
			end,
			UI_STYLE.scrollable_list_item_height,
			size,
			UI_STYLE.slider_width,
			re.buildings_scrollbar
		)
	else
		-- Show individual buildings
		re.buildings_scrollbar = re.buildings_scrollbar or 0
		local amount = 0
		local buildings = DATA.filter_building_location_from_location(province_id, function (item)
			amount = amount + 1
			return true
		end)

		re.buildings_scrollbar = uit.scrollview(rect, function(number, rect)
			if number > 0 and number <= amount then
				---@type Building
				local building = DATA.building_location_get_building(tabb.nth(buildings, number))
				local building_type = DATA.building_get_current_type(building)
				local icon = DATA.building_type_get_icon(building_type)
				local description = DATA.building_type_get_description(building_type)
				local owner = DATA.get_ownership_from_building(building)

				ui.tooltip(building_type_tooltip(building_type), rect)
				---@type Rect
				local r = rect
				local im = r:subrect(0, 0, base_unit, base_unit, "left", "up")
				if uit.icon_button(ASSETS.icons[icon], im) then
					gam.inspector = "building"
					gam.selected.building = building
				end
				rect.x = rect.x + base_unit
				ui.left_text(description, rect)
				if WORLD:player_is_owner(building) then
					local button = r:subrect(-base_unit, 0, base_unit, base_unit, "right", "up")
					if uit.icon_button(ASSETS.get_icon("hammer-drop.png"), button, "Destroy the building") then
						-- remove the building!
						remove_building(building)
					end
				else
					-- ???
				end
			end
		end, UI_STYLE.scrollable_list_item_height, amount, UI_STYLE.slider_width,
		re.buildings_scrollbar)
	end
end

local building_tab = "Construction"

---comment
---@param gam GameScene
---@param tile_id tile_id
---@param panel Rect
local function buildings_tab(gam, tile_id, panel)
	local unit = uit.BASE_HEIGHT

	local tab_content = panel:subrect(0, unit, panel.width, panel.height - unit, "left", "up")

	building_tab = building_tab or "Construction"

	local tabs = {
		{
			text = "Construction",
			tooltip = "Construction",
			closure = function()
				buildings_construction_tab(gam, tile_id, tab_content)
			end
		},
		{
			text = "Buildings",
			tooltip = "Buildings",
			closure = function()
				buildings_view_tab(gam, tile_id, tab_content)
			end
		}
	}

	local layout = ui.layout_builder()
		:position(panel.x, panel.y)
		:spacing(2)
		:horizontal()
		:build()

	building_tab = uit.tabs(building_tab, layout, tabs, 1, unit * 5)
end

local function technology_tab(gam, tile_id, panel)
	local base_unit = uit.BASE_HEIGHT
	local province = tile_utils.province(tile_id)

	---@type technology_id[]
	local technologies = {}
	local total = 0

	DATA.for_each_technology(function (item)
		if DATA.province_get_technologies_present(province, item) == 1 then
			table.insert(technologies, item)
			total = total + 1
		end
	end)

	---@type technology_id[]
	local technologies_potential = {}
	local total_potential = 0

	DATA.for_each_technology(function (item)
		if DATA.province_get_technologies_researchable(province, item) == 1 then
			table.insert(technologies_potential, item)
			total_potential = total_potential + 1
		end
	end)

	uit.rows(
		{
			---commenting
			---@param rect Rect
			function(rect)
				uit.rows({
					function(rect)
						ui.centered_text("Researched technologies", rect)
					end,
					function(_)
						rect.y = rect.y + UI_STYLE.table_header_height
						rect.height = rect.height - UI_STYLE.table_header_height
						re.researched_technologies_scrollbar = re.researched_technologies_scrollbar or 0
						re.researched_technologies_scrollbar = uit.scrollview(rect, function(number, rect)
								if number > 0 then
									---@type Technology
									local tech = tabb.nth(technologies, number)
									require "game.scenes.game.widgets.technology" (tech, rect, gam)
								end
							end,
							UI_STYLE.scrollable_list_item_height,
							total,
							UI_STYLE.slider_width,
							re.researched_technologies_scrollbar
						)
					end
				}, rect, base_unit)
			end,
			---commenting
			---@param rect Rect
			function(rect)
				uit.rows({
					function(rect)
						ui.centered_text("Researchable technologies", rect)
					end,
					function(_)
						rect.y = rect.y + base_unit
						rect.height = rect.height - base_unit
						re.researchable_technologies_scrollbar = re.researchable_technologies_scrollbar or 0
						re.researchable_technologies_scrollbar = uit.scrollview(rect, function(number, rect)
								if number > 0 then
									local tech = technologies_potential[number]
									require "game.scenes.game.widgets.technology" (tech, rect, gam)
								end
							end,
							UI_STYLE.scrollable_list_item_height,
							total_potential,
							UI_STYLE.slider_width,
							re.researchable_technologies_scrollbar)
					end
				}, rect, base_unit)
			end
		},
		panel,
		panel.height / 2 - 5
	)
end

local decision_tab = "Province"

---comment
---@param gam GameScene
---@param tile_id tile_id
---@param panel Rect
local function decisions_tab(gam, tile_id, panel)
	local unit = uit.BASE_HEIGHT

	local tab_content = panel:subrect(0, unit, panel.width, panel.height - unit * 2, "left", "up")

	decision_tab = decision_tab or "Province"

	local tabs = {
		{
			text = "Tile",
			tooltip = "Tile decisions",

			on_select = function()
				gam.reset_decision_selection()
			end,
			closure = function()
				require "game.scenes.game.widgets.decision-tab" (
					tab_content,
					tile_id,
					"tile",
					gam
				)
			end
		},
		{
			text = "Province",
			tooltip = "Provincial decisions.",
			on_select = function()
				gam.reset_decision_selection()
			end,
			closure = function()
				require "game.scenes.game.widgets.decision-tab" (
					tab_content,
					tile_utils.province(tile_id),
					"province",
					gam
				)
			end
		}
	}

	local layout = ui.layout_builder()
		:position(panel.x, panel.y)
		:spacing(2)
		:horizontal()
		:build()

	decision_tab = uit.tabs(decision_tab, layout, tabs, 1, unit * 5)
end

---@param gam GameScene
function re.draw(gam)
	local unit = uit.BASE_HEIGHT

	local tile_id = gam.clicked_tile_id

	if tile_id == nil then
		return
	end

	local panel = get_main_panel()
	ui.panel(panel)

	if tile_utils.realm(tile_id) then
		local header = panel:subrect(0, 0, panel.width, unit, "left", "up")
		header.width = header.width / 2
		-- COA
		require "game.scenes.game.widgets.realm-name" (
			gam,
			tile_utils.realm(tile_id),
			header,
			"immediate"
		)
	end

	if uit.icon_button(ASSETS.icons["cancel.png"], panel:subrect(0, 0, unit * 1, unit * 1, "right", "up")) then
		gam.click_tile(0)
		gam.inspector = nil
	end

	panel.y = panel.y + unit
	panel.height = panel.height - unit

	local tab_content = panel:subrect(0, unit, panel.width, panel.height - unit, "left", "up")

	gam.tile_inspector_tab = gam.tile_inspector_tab or "GEN"

	local province = tile_utils.province(tile_id)

	local tabs = {
		{
			text = "GEN",
			icon = ASSETS.icons["horizon-road.png"],
			tooltip = "General",
			closure = function()
				general_tab(gam, tile_id, tab_content)
			end
		},
		{
			text = "BLD",
			icon = ASSETS.icons["village.png"],
			tooltip = "Buildings",
			closure = function()
				buildings_tab(gam, tile_id, tab_content)
			end
		},
		{
			text = "TEC",
			icon = ASSETS.icons["bookmarklet.png"],
			tooltip = "Technology",
			closure = function()
				technology_tab(gam, tile_id, tab_content)
			end
		},
		{
			text = "CHR",
			icon = ASSETS.icons["inner-self.png"],
			tooltip = "List of notable characters",
			closure = function()
				local tab_layout = ui.layout_builder()
					:position(tab_content.x, tab_content.y)
					:spacing(2)
					:horizontal()
					:build()
				tab_content.y = tab_content.y + unit * 1.2
				tab_content.height = tab_content.height - unit * 1.2
				re.cached_character_tab = uit.tabs(re.cached_character_tab, tab_layout, {
					{
						text = "All",
						tooltip = "All characters in province",
						closure = function()
							local response = require "game.scenes.game.widgets.character-list" (
								tab_content,
								tabb.map_array(
									DATA.filter_array_character_location_from_location(
										province,
										function (item) return true end
									),
									DATA.character_location_get_character
								)
							)()
							if response then
								gam.selected.character = response
								gam.inspector = "character"
							end
						end
					},
					{
						text = "Home",
						tooltip = "Characters that are at home.",
						closure = function()
							local response = require "game.scenes.game.widgets.character-list" (
								tab_content,
								tabb.map_array(
									DATA.filter_array_character_location_from_location(
										province,
										function (item)
											local character = DATA.character_location_get_character(item)
											local home_location = DATA.get_home_from_pop(character)
											local home_province = DATA.home_get_home(home_location)
											return home_province == province
										end
									),
									DATA.character_location_get_character
								)
							)()
							if response then
								gam.selected.character = response
								gam.inspector = "character"
							end
						end
					},
					{
						text = "Guest",
						tooltip = "All foreign characters present.",
						closure = function()
							local response = require "game.scenes.game.widgets.character-list" (
								tab_content,
								tabb.map_array(
									DATA.filter_array_character_location_from_location(
										province,
										function (item)
											local character = DATA.character_location_get_character(item)
											local home_location = DATA.get_home_from_pop(character)
											local home_province = DATA.home_get_home(home_location)
											return home_province ~= province
										end
									),
									DATA.character_location_get_character
								)
							)()
							if response then
								gam.selected.character = response
								gam.inspector = "character"
							end
						end
					}
				}, 1.2)
			end
		},
		{
			text = "DCS",
			icon = ASSETS.icons["envelope.png"],
			tooltip = "Local decisions",
			on_select = function()
				gam.reset_decision_selection()
			end,
			closure = function()
				decisions_tab(gam, tile_id, tab_content)
			end,
			visible = WORLD.player_character ~= INVALID_ID
		},
		{
			text = "GEO",
			icon = ASSETS.icons["mountains.png"],
			tooltip = "Geography",
			closure = function()
				geography_tab(gam, tile_id, tab_content)
			end
		}
	}

	local layout = ui.layout_builder()
		:position(panel.x, panel.y)
		:spacing(2)
		:horizontal()
		:build()

	gam.tile_inspector_tab = uit.tabs(gam.tile_inspector_tab, layout, tabs, 1)
end

return re
