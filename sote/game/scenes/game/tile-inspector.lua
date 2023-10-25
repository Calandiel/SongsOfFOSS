-- TODO: this file needs to be split up into smaller, more managable files.
-- Perhaps have a file per "tab"?

local re = {}
local ui = require "engine.ui"
local uit = require "game.ui-utils"
local tabb = require "engine.table"

local ef = require "game.raws.effects.economic"

re.cached_scrollbar = 0

---@param scale number
---@return Rect
local function get_main_panel(scale)
	local fs = ui.fullscreen()
	local base_unit = uit.BASE_HEIGHT * scale
	local panel = fs:subrect(0, 0, base_unit * 30, base_unit * 12, "left", 'down')
	return panel
end

---Returns whether or not clicks on the planet can be registered.
---@return boolean
function re.mask(gam)
	if ui.trigger(get_main_panel(gam.tile_inspector_scale)) then
		return false
	else
		return true
	end
end

---@param gam table
function re.draw(gam)
	local tt = gam.clicked_tile_id
	local mbt = WORLD.tiles[tt]
	if mbt ~= nil then
		---@type Tile
		local tile = mbt
		if tile.province == nil then
			return -- the world isn't fully generated... return
		end
		-- The clicked tile exists!
		local panel = get_main_panel(gam.tile_inspector_scale)
		local scale = gam.tile_inspector_scale
		local base_unit = uit.BASE_HEIGHT * scale
		
		ui.panel(panel)

		if ui.icon_button(ASSETS.icons["cancel.png"], panel:subrect(0, 0, base_unit, base_unit, "right", 'up')) then
			gam.click_tile(-1)
			gam.inspector = nil
		end

		if ui.icon_button(ASSETS.icons["plus.png"], panel:subrect(- 2 * base_unit, 0, base_unit, base_unit, "right", 'up')) then
			if gam.tile_inspector_scale == 1 then
				gam.tile_inspector_scale = 1.3
			elseif gam.tile_inspector_scale == 1.3 then
				gam.tile_inspector_scale = 1.7
			end
		end

		if ui.icon_button(ASSETS.icons["minus.png"], panel:subrect(- 3 * base_unit, 0, base_unit, base_unit, "right", 'up')) then
			if gam.tile_inspector_scale == 1.7 then
				gam.tile_inspector_scale = 1.3
			elseif gam.tile_inspector_scale == 1.3 then
				gam.tile_inspector_scale = 1
			end
		end

		-- COA
		if tile.province.realm then
			if uit.coa(tile.province.realm, panel:subrect(0, 0, base_unit, base_unit, "left", 'up')) then
				gam.inspector = "realm"
				gam.selected_realm = tile.province.realm
			end
			ui.left_text(tile.province.name .. ' (' .. tile.province.realm.name .. ')',
				panel:subrect(base_unit + 5, 0, 10 * base_unit, base_unit, "left", 'up'))
		end
		if tile.province.realm then
			if WORLD.player_character == nil then
				local bp = panel:subrect(-base_unit, 0, base_unit, base_unit, "right", "up")
				if ui.icon_button(ASSETS.icons['frog-prince.png'], bp, "Take control over character from this country") then
					-- gam.refresh_map_mode()
					gam.inspector = "characters"
					gam.selected_province = tile.province
				end
			end
		end


		-- All the other data (as in, tabs)
		local ui_panel = panel:subrect(5, base_unit * 2, panel.width - 10, panel.height - 10 - base_unit * 2,
			"left", 'up')
		ui.panel(ui_panel)
		local origin = ui_panel:subrect(0, 0, base_unit * 3, base_unit, "left", 'up')
		gam.tile_inspector_tab = gam.tile_inspector_tab or "GEN"
		local tabs = {
			{
				text = "GEN",
				tooltip = "General",
				closure = function()
					uit.columns({
						function(rect)
							uit.rows({
								function(rect)
									ui.panel(rect)
									uit.data_entry("Car. cap.: ", tostring(math.floor(tile.province.foragers_limit)), rect, "Carrying capacity")
								end,
								function(rect)
									ui.panel(rect)
									uit.data_entry("Hydration:", tostring(math.floor(100 * tile.province.hydration) / 100), rect,
										"Number of humans that can survive of off natural water resources.")
								end,
								function(rect)
									ui.panel(rect)
									local rr = "n/a"
									if tile.resource then
										rr = tile.resource.name
									end
									uit.data_entry("Local resources:", rr, rect, "Local resources.")
								end,
								function(rect)
									local player_character = WORLD.player_character
									if player_character then
										local player_realm = player_character.realm
										if player_realm and WORLD:does_player_control_realm(player_realm) then
											local explore_cost = player_realm:get_explore_cost(tile.province)
											local explore_cost_string = tostring(math.floor(100 * explore_cost) / 100) .. MONEY_SYMBOL
											if player_realm.budget.treasury > explore_cost then
												if ui.text_button("Explore (" .. explore_cost_string .. ')', rect, "Explore this province") then
													player_realm:explore(tile.province)
													EconomicEffects.change_treasury(player_realm, -explore_cost, EconomicEffects.reasons.Exploration)
													gam.refresh_map_mode()
												end
											else
												if ui.text_button("Explore (n/a)", rect,
													"Not enough funds! (" ..
													explore_cost_string .. " needed)") then
													--
												end
											end
										end
									end
								end
							}, rect)
						end,
						function(rect)
							uit.rows({
								function(rect)
									ui.panel(rect)
									uit.data_entry("Mov. cost: ", tostring(math.floor(tile.province.movement_cost)), rect,
										"Movement cost, in hours")
								end,
								function(rect)
									ui.panel(rect)
									uit.data_entry("Mood: ", tostring(math.floor(tile.province.mood * 100) / 100), rect,
										"How positive of an outlook an average person in this province has about the future. Influences everything from sub-province decision making to voluntary contributions.")
								end
							}, rect)
						end,
						function(rect)
							local lat, lon = tile:latlon()
							uit.rows({
								function(rect)
									ui.panel(rect)
									uit.data_entry("Latitude: ", tostring(math.floor(lat * 100) / 100), rect,
										"In radians")
								end,
								function(rect)
									ui.panel(rect)
									uit.data_entry("Longitude: ", tostring(math.floor(lon * 100) / 100), rect,
										"In radians")
								end,
								function(rect)
									ui.panel(rect)
									uit.data_entry("Size: ", tostring(tabb.size(tile.province.tiles)), rect, "In tiles")
								end,
								function(rect)
									ui.panel(rect)
									local visibility = WORLD:base_visibility(1)
									uit.data_entry_percentage("Spotting (1): ", tile.province:spot_chance(visibility), rect,
										"Chance to spot an army of 1 human raider.")
								end,
								function(rect)
									ui.panel(rect)
									local visibility = WORLD:base_visibility(10)
									uit.data_entry_percentage("Spotting (10): ", tile.province:spot_chance(visibility), rect,
										"Chance to spot an army of 10 human raiders.")
								end,
								function(rect)
									ui.panel(rect)
									local visibility = WORLD:base_visibility(50)
									uit.data_entry_percentage("Spotting (50): ", tile.province:spot_chance(visibility), rect,
										"Chance to spot an army of 50 human raiders.")
								end,
								function(rect)
									ui.panel(rect)
									uit.data_entry("Hiding space: ", tostring(math.floor(tile.province:get_hiding() * 100) / 100), rect,
										"The weighted amount of land that can be hidden in. Expressed as an equivalent number of grassland tiles.")
								end
							}, rect)
						end,
					}, ui_panel, base_unit * 7)
				end
			},
			{
				text = "ECO",
				tooltip = "Ecology",
				closure = function()
					uit.rows({
						function(rect)
							ui.centered_text("Local plants", rect)
						end,
						function(rect)
							uit.graph({
								{
									weight = 1 - tile.grass - tile.shrub - tile.conifer - tile.broadleaf,
									tooltip = "Bare ground (" ..
										math.floor((1 - tile.grass - tile.shrub - tile.conifer - tile.broadleaf) * 100) .. "%)",
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
							uit.columns({
								function(rect)
									uit.data_entry("Biome", tile.biome.name, rect)
								end
							}, rect, base_unit * 10)
						end,
						function(rect)
							uit.data_entry("Local carrying capacity",
								tostring(math.floor(1000 * require "game.ecology.carrying-capacity".get_tile_carrying_capacity(tile)) / 1000),
								rect,
								"Expressed in adult humans per tile.")
						end
					}, ui_panel)
				end
			},
			{
				text = "CLI",
				tooltip = "Climate",
				closure = function()
					local jan_r, jan_t, jul_r, jul_t = tile:get_climate_data()
					uit.columns({
						-- january
						function(rect)
							uit.rows({
								function(rect)
									uit.data_entry("Jan. temp:", tostring(math.floor(jan_t)), rect, "January temperature")
								end,
								function(rect)
									uit.data_entry("Jan. rain:", tostring(math.floor(jan_r)), rect, "January rainfall")
								end,
								function(rect)
									uit.data_entry("Jan. flow:", tostring(math.floor(tile.january_waterflow)), rect, "January waterflow")
								end,
								function(rect)
									uit.data_entry("Ice:", tostring(math.floor(tile.ice)), rect, "Ice")
								end,
								function(rect)
									local kopp = require "game.climate.koppen"
									local k = kopp.get_koppen(jan_t, jul_t, jan_r, jul_r, tile.is_land)
									uit.data_entry("Koppen:", k, rect, "Koppen climate classification")
								end,
							}, rect)
						end,
						-- july
						function(rect)
							uit.rows({
								function(rect)
									uit.data_entry("Jul. temp:", tostring(math.floor(jul_t)), rect, "July temperature")
								end,
								function(rect)
									uit.data_entry("Jul. rain:", tostring(math.floor(jul_r)), rect, "July rainfall")
								end,
								function(rect)
									uit.data_entry("Jul. flow:", tostring(math.floor(tile.july_waterflow)), rect, "July waterflow")
								end,
								function(rect)
									uit.data_entry("Ice (ice age):", tostring(math.floor(tile.ice_age_ice)), rect,
										"Ice cover during the last glacial maximum")
								end,
							}, rect)
						end
					}, ui_panel, base_unit * 7)
				end
			},
			{
				text = "GEO",
				tooltip = "Geology",
				closure = function()
					uit.columns({
						function(rect)
							uit.rows({
								function(rect)
									uit.data_entry("Elevation:", tostring(math.floor(tile.elevation)), rect)
								end,
								function(rect)
									uit.data_entry("Bedrock:", tile.bedrock.name, rect)
								end,
								function(rect)
									ui.centered_text('Soil texture', rect)
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
									uit.data_entry("Soil depth:", tostring(math.floor(tile:soil_depth() * 100) / 100), rect, "In meters")
								end,
								function(rect)
									uit.data_entry("Soil perm.:", tostring(math.floor(tile:soil_permeability() * 100) / 100), rect,
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
						end
					}, ui_panel, ui_panel.width)
				end
			},
			{
				text = "DEM",
				tooltip = "Demographics",
				closure = function()
					uit.rows({
						function(rect)
							ui.centered_text("Races", rect)
						end,
						function(rect)
							local counts = {}
							for _, pop in pairs(tile.province.all_pops) do
								local old = counts[pop.race] or 0
								counts[pop.race] = old + 1
							end
							local entries = {}
							for race, count in pairs(counts) do
								entries[#entries + 1] = {
									weight = count,
									tooltip = race.name .. ' (' .. count .. ')',
									r = race.r,
									g = race.g,
									b = race.b,
								}
							end
							uit.graph(entries, rect)
						end,
						function(rect)
							ui.centered_text("Culture", rect)
						end,
						function(rect)
							local counts = {}
							for _, pop in pairs(tile.province.all_pops) do
								local old = counts[pop.culture] or 0
								counts[pop.culture] = old + 1
							end
							local entries = {}
							for culture, count in pairs(counts) do
								entries[#entries + 1] = {
									weight = count,
									tooltip = culture.name .. ' (' .. count .. ')',
									r = culture.r,
									g = culture.g,
									b = culture.b,
								}
							end
							uit.graph(entries, rect)
						end,
						function(rect)
							ui.centered_text("Faiths", rect)
						end,
						function(rect)
							local counts = {}
							for _, pop in pairs(tile.province.all_pops) do
								local old = counts[pop.faith] or 0
								counts[pop.faith] = old + 1
							end
							local entries = {}
							for faith, count in pairs(counts) do
								entries[#entries + 1] = {
									weight = count,
									tooltip = faith.name .. ' (' .. count .. ')',
									r = faith.r,
									g = faith.g,
									b = faith.b,
								}
							end
							uit.graph(entries, rect)
						end,
						function(rect)
							rect.width = rect.width
							local carr_cap = math.floor(tile.province.foragers_limit)
							uit.data_entry("Population", tostring(tile.province:population()) .. '/' .. tostring(carr_cap), rect)
						end,
						function(rect)
							ui.centered_text("Jobs", rect)
						end,
						function(rect)
							local unemp = {
								name = "Unemployed",
								r = 0.23,
								g = 0.23,
								b = 0.23,
							}
							local warr = {
								name = "Warriors",
								r = 0.43,
								g = 0.23,
								b = 0.13,
							}
							local child = {
								name = "Children",
								r = 0.83,
								g = 0.83,
								b = 0.83,
							}
							local counts = {}
							counts[unemp] = 0
							counts[child] = 0
							counts[warr] = 0
							for _, pop in pairs(tile.province.all_pops) do
								if pop.job then
									if counts[pop.job] then
										counts[pop.job] = counts[pop.job] + 1
									else
										counts[pop.job] = 1
									end
								else
									if pop.age > pop.race.teen_age then
										if pop.drafted then
											counts[warr] = counts[warr] + 1
										else
											counts[unemp] = counts[unemp] + 1
										end
									else
										counts[child] = counts[child] + 1
									end
								end
							end
							local entries = {}
							for job, count in pairs(counts) do
								entries[#entries + 1] = {
									weight = count,
									tooltip = job.name .. ' (' .. count .. ')',
									r = job.r,
									g = job.g,
									b = job.b,
									name = job.name,
								}
							end
							table.sort(entries, function(a, b)
								return a.name < b.name
							end)
							uit.graph(entries, rect)
						end,
					}, ui_panel)
				end
			},
			{
				text = "POP",
				tooltip = "List of POPs ('parts of population')",
				closure = require "game.scenes.game.widgets.pop-list"(ui_panel, base_unit, tile)
			},
			{
				text = "CHR",
				tooltip = "List of notable characters",
				closure = function() 
					local response = require "game.scenes.game.widgets.character-list"(ui_panel, base_unit, tile.province)()
					if response then
						gam.selected_character = response
						gam.inspector = "character"
					end
				end
			},
			{
				text = "BLD",
				tooltip = "Buildings",
				closure = function()
					uit.columns({
						function(rect)
							if re.building_stacks == nil then
								re.building_stacks = true
							end

							local rr = rect.height
							local rw = rect.width
							rect.height = base_unit
							ui.centered_text("Buildings", rect)
							rect.width = base_unit
							if re.building_stacks then
								if ui.icon_button(ASSETS.icons['cubes.png'], rect, "Show individual buildings") then
									re.building_stacks = not re.building_stacks
								end
							else
								if ui.icon_button(ASSETS.icons['cubeforce.png'], rect, "Show building types") then
									re.building_stacks = not re.building_stacks
								end
							end
							rect.width = rw

							rect.height = rr - base_unit
							rect.y = rect.y + base_unit

							if re.building_stacks then
								-- Show buildings at stacks
								local stacks = {}
								for _, building in pairs(tile.province.buildings) do
									if stacks[building.type] == nil then
										stacks[building.type] = 1
									else
										stacks[building.type] = stacks[building.type] + 1
									end
								end
								re.buildings_scrollbar = re.buildings_scrollbar or 0
								re.buildings_scrollbar = ui.scrollview(rect, function(number, rect)
									if number > 0 then
										---@type BuildingType
										local building_type, amount = tabb.nth(stacks, number)
										ui.tooltip(building_type:get_tooltip(), rect)
										---@type Rect
										local r = rect
										local im = r:subrect(0, 0, base_unit, base_unit, "left", 'up')
										ui.image(ASSETS.icons[building_type.icon], im)
										rect.x = rect.x + base_unit
										ui.left_text(building_type.name .. " (" .. tostring(amount) .. ")", rect)
									end
								end, base_unit, tabb.size(stacks), base_unit,
									re.buildings_scrollbar)
							else
								-- Show individual buildings
								re.buildings_scrollbar = re.buildings_scrollbar or 0
								re.buildings_scrollbar = ui.scrollview(rect, function(number, rect)
									if number > 0 and number <= tabb.size(tile.province.buildings) then
										---@type Building
										local building = tabb.nth(tile.province.buildings, number)
										ui.tooltip(building.type:get_tooltip(), rect)
										---@type Rect
										local r = rect
										local im = r:subrect(0, 0, base_unit, base_unit, "left", 'up')
										if ui.icon_button(ASSETS.icons[building.type.icon], im) then
											gam.inspector = 'building'
											gam.selected_building = building
										end
										rect.x = rect.x + base_unit
										ui.left_text(building.type.name, rect)
										if WORLD:does_player_control_realm(tile.province.realm) then
											local button = r:subrect(-base_unit, 0, base_unit, base_unit, "right", 'up')
											if ui.icon_button(ASSETS.get_icon('hammer-drop.png'), button, "Destroy the building") then
												-- remove the building!
												building:remove_from_province(tile.province)
											end
										else
											-- ???
										end
									end
								end, base_unit, tabb.size(tile.province.buildings), base_unit,
									re.buildings_scrollbar)
							end
						end,
						function(rect)
							local rr = rect.height
							rect.height = base_unit
							ui.centered_text("Construction", rect)
							rect.height = rr - base_unit
							rect.y = rect.y + base_unit
							re.building_construction_scrollbar = re.building_construction_scrollbar or 0
							re.building_construction_scrollbar = ui.scrollview(rect, function(number, rect)
								if number > 0 then
									---@type BuildingType
									local building_type = tabb.nth(tile.province.buildable_buildings, number)
									require "game.scenes.game.widgets.building-type-buttons"(gam, rect, base_unit, building_type, tile, false)
								end
							end, base_unit, tabb.size(tile.province.buildable_buildings), base_unit,
								re.building_construction_scrollbar)
						end,
					}, ui_panel, ui_panel.width / 2 - 5)
				end
			},
			{
				text = "INF",
				tooltip = "Infrastructure",
				closure = function()
					uit.columns({
						function(rect)
							uit.rows({
								function(rect)
									uit.money_entry('Infrastructure: ',
										tile.province.infrastructure, rect)
								end,
								function(rect)
									uit.money_entry('Inf. investment: ',
										tile.province.infrastructure_investment, rect)
								end,
								function(rect)
									if WORLD:does_player_control_realm(tile.province.realm) then
										local cinf = tile.province.infrastructure_investment
										local realm = tile.province.realm
										local province = tile.province

										if realm == nil then
											return
										end

										uit.columns({
											function(rect)
												if realm.budget.treasury > 0.1 then
													if ui.text_button('+0.1' .. MONEY_SYMBOL, rect, 'Invest 0.1') then
														ef.direct_investment_infrastructure(realm, province, 0.1)
													end
												else
													ui.centered_text('+0.1' .. MONEY_SYMBOL, rect)
												end
											end,
											function(rect)
												if realm.budget.treasury > 1 then
													if ui.text_button('+1' .. MONEY_SYMBOL, rect, 'Invest 1') then
														ef.direct_investment_infrastructure(realm, province, 1)
													end
												else
													ui.centered_text('+1' .. MONEY_SYMBOL, rect)
												end
											end,
											function(rect)
												if realm.budget.treasury > 10 then
													if ui.text_button('+10' .. MONEY_SYMBOL, rect, 'Invest 10') then
														ef.direct_investment_infrastructure(realm, province, 10)
													end
												else
													ui.centered_text('+10' .. MONEY_SYMBOL, rect)
												end
											end,
											function(rect)
												if realm.budget.treasury > 100 then
													if ui.text_button('+100' .. MONEY_SYMBOL, rect, 'Invest 100') then
														ef.direct_investment_infrastructure(realm, province, 100)
													end
												else
													ui.centered_text('+100' .. MONEY_SYMBOL, rect)
												end
											end,
										}, rect, base_unit * 2)
									end
								end,
								function(rect)
									uit.money_entry('Needed inf.: ',
										tile.province.infrastructure_needed, rect)
								end,
								function(rect)
									local sat = 0
									if tile.province.infrastructure_needed > 0 then
										sat = tile.province.infrastructure / tile.province.infrastructure_needed
									end
									uit.data_entry_percentage('Inf. satisfaction: ',
										sat, rect)
								end,
								function(rect)
									local impr = "none"
									if tile.tile_improvement then
										impr = tile.tile_improvement.type.name
									end
									uit.data_entry("Improvement: ", impr, rect, "Local tile improvement")
								end,
								function(rect)
									if tile.tile_improvement then
										if WORLD:does_player_control_realm(tile.province.realm) then
											if ui.text_button("Destroy", rect, "Destroy the local tile improvement") then
												tile.tile_improvement:remove_from_province(tile.province)
											end
										end
									end
								end
							}, rect, base_unit)
						end,
						function(rect)
							local tile_improvs = {}
							for _, bld in pairs(tile.province.buildable_buildings) do
								if bld.tile_improvement then
									tile_improvs[bld] = bld
								end
							end

							local rr = rect.height
							rect.height = base_unit
							ui.centered_text("Construction", rect)
							rect.height = rr - base_unit
							rect.y = rect.y + base_unit
							re.building_tile_improvements_scrollbar = re.building_tile_improvements_scrollbar or 0
							re.building_tile_improvements_scrollbar = ui.scrollview(rect, function(number, rect)
								if number > 0 then
									---@type BuildingType
									local building_type = tabb.nth(tile_improvs, number)
									require "game.scenes.game.widgets.building-type-buttons"(gam, rect, base_unit, building_type, tile, true)
								end
							end, base_unit, tabb.size(tile_improvs), base_unit,
								re.building_tile_improvements_scrollbar)
						end,
					}, ui_panel, ui_panel.width / 2 - 5)
				end
			},
			{
				text = "TEC",
				tooltip = "Technology",
				closure = function()
					uit.columns({
						function(rect)
							uit.rows({
								function(rect)
									ui.centered_text("Researched technologies", rect)
								end,
								function(_)
									rect.y = rect.y + base_unit
									rect.height = rect.height - base_unit
									re.researched_technologies_scrollbar = re.researched_technologies_scrollbar or 0
									re.researched_technologies_scrollbar = ui.scrollview(rect, function(number, rect)
										if number > 0 then
											---@type Technology
											local tech = tabb.nth(tile.province.technologies_present, number)
											ui.tooltip(tech:get_tooltip(), rect)
											---@type Rect
											local r = rect
											local im = r:subrect(0, 0, base_unit, base_unit, "left", 'up')
											if ui.icon_button(ASSETS.icons[tech.icon], im) then
												gam.cached_selected_tech = tech
												gam.update_map_mode("selected_technology")
											end
											rect.x = rect.x + base_unit
											ui.left_text(tech.name, rect)
										end
									end, base_unit, tabb.size(tile.province.technologies_present), base_unit,
										re.researched_technologies_scrollbar)
								end
							}, rect, base_unit)
						end,
						function(rect)
							uit.rows({
								function(rect)
									ui.centered_text("Researchable technologies", rect)
								end,
								function(_)
									rect.y = rect.y + base_unit
									rect.height = rect.height - base_unit
									re.researchable_technologies_scrollbar = re.researchable_technologies_scrollbar or 0
									re.researchable_technologies_scrollbar = ui.scrollview(rect, function(number, rect)
										if number > 0 then
											---@type Technology
											local tech = tabb.nth(tile.province.technologies_researchable, number)
											ui.tooltip(tech:get_tooltip(), rect)
											---@type Rect
											local r = rect
											local im = r:subrect(0, 0, base_unit, base_unit, "left", 'up')
											if ui.icon_button(ASSETS.icons[tech.icon], im) then
												gam.cached_selected_tech = tech
												gam.update_map_mode("selected_technology")
											end
											rect.x = rect.x + base_unit
											ui.left_text(tech.name, rect)
										end
									end, base_unit, tabb.size(tile.province.technologies_researchable), base_unit,
										re.researchable_technologies_scrollbar)
								end
							}, rect, base_unit)
						end
					}, ui_panel, ui_panel.width / 2 - 5)
				end
			},
			{
				text = "TDC",
				tooltip = "Tile decisions",
				on_select = function()
					gam.reset_decision_selection()
				end,
				closure = function()
					require "game.scenes.game.widgets.decision-tab"(
							ui_panel, tile, 'tile', gam)
				end
			},
			{
				text = "PDC",
				tooltip = "Province decisions",
				on_select = function()
					gam.reset_decision_selection()
				end,
				closure = function()
					require "game.scenes.game.widgets.decision-tab"(
							ui_panel, tile.province, 'province', gam)
				end
			},
			{
				text = "MIL",
				tooltip = "Military",
				closure = function()
					local top = ui_panel:subrect(0, 0, ui_panel.width, base_unit, "left", 'up')
					local bottom = ui_panel:subrect(0, base_unit, ui_panel.width, ui_panel.height - base_unit, "left", 'up')
					ui.centered_text("Military", top)
					re.units_scrollbar = re.units_scrollbar or 0
					local ttab = require "engine.table"
					re.units_scrollbar = ui.scrollview(bottom, function(number, rect)
						if number > 0 then
							--print(number, ttab.size(tile.province.all_pops))
							---@type UnitType
							local unit, pops = ttab.nth(tile.province.units, number)
							local target = tile.province.units_target[unit]
							local current = tabb.size(pops)

							rect.width = rect.height
							ui.image(ASSETS.icons[unit.icon], rect)
							rect.x = rect.x + rect.width + 5
							rect.width = 175
							ui.left_text(unit.name, rect)
							rect.x = rect.x + rect.width
							rect.width = rect.height
							if WORLD:does_player_control_realm(tile.province.realm) then
								if target > 0 then
									if ui.text_button('-1', rect, "Decrease the number of units to recruit by one") then
										tile.province.units_target[unit] = math.max(0, target - 1)
									end
								end
							end
							rect.x = rect.x + rect.width + 5
							rect.width = 65
							ui.centered_text(tostring(current) .. '/' .. tostring(target), rect)
							rect.x = rect.x + rect.width + 5
							rect.width = rect.height

							local realm = tile.province.realm
							if realm and WORLD:does_player_control_realm(tile.province.realm) then								
								local target_budget = realm.budget.military.target
								local current_budget = realm.budget.military.budget
								if current_budget > target_budget + unit.upkeep then
									if ui.text_button('+1', rect, "Increase the number of units to recruit by one") then
										tile.province.units_target[unit] = math.max(0, target + 1)
									end
								else 
									ui.text_button('X', rect, "Not enough military funding")
								end
							end
							rect.x = rect.x + rect.width + 5
							rect.width = 150
							uit.money_entry('Cost', unit.base_price, rect)
						end
					end, base_unit, ttab.size(tile.province.units), base_unit, re.units_scrollbar)
				end
			}
		}
		local layout = ui.layout_builder()
			:position(panel.x, panel.y + base_unit)
			:spacing(2)
			:horizontal()
			:build()
		gam.tile_inspector_tab = uit.tabs(gam.tile_inspector_tab, layout, tabs, scale)
	end
end

return re
