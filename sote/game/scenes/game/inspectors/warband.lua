local tabb = require "engine.table"
local job_types = require "game.raws.job_types"

local ui = require "engine.ui";
local ut = require "game.ui-utils"

local ib = require "game.scenes.game.widgets.to-inspector-buttons"
local list_widget = require "game.scenes.game.widgets.list-widget"

local economic_effects = require "game.raws.effects.economic"

local window = {}

---@type "RECRUIT" | "WARRIOR"
local unit_panel_tab = "RECRUIT"
local type_list_state = nil
local unit_list_state = nil

---@return Rect
function window.rect()
    local fs = ui.fullscreen()
    return fs:subrect(ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 45, ut.BASE_HEIGHT * 15, "left", "up")
end

---Returns whether or not clicks on the planet can be registered.
---@return boolean
function window.mask()
	if ui.trigger(window.rect()) then
		return false
	else
		return true
	end
end

local WARBAND_SIPHON_AMOUNT = 1;
local spacing = 5

---actually draw the inspector panel
---@param gamescene GameScene
function window.draw(gamescene)

	local player_character = WORLD.player_character

	--- combining key presses for increments of 1, 5, 10, and 50
	WARBAND_SIPHON_AMOUNT = 1
	if ui.is_key_held("lshift") or ui.is_key_held("rshift") then
		WARBAND_SIPHON_AMOUNT = WARBAND_SIPHON_AMOUNT * 5
	end
	if ui.is_key_held("lctrl") or ui.is_key_held("rctrl") then
		WARBAND_SIPHON_AMOUNT = WARBAND_SIPHON_AMOUNT * 10
	end

	local panel = window.rect()

	local warband = gamescene.selected.warband
	if not warband then
		return
	end

	--- TOP BAR: REALM BUTTON, NAME TEXT, CLOSE WINDOW BUTTON
	---@param rect Rect
	local function draw_top_panel(rect)
		local top_bar_layout = ui.layout_builder()
			:horizontal()
			:position(rect.x, rect.y)
			:spacing(spacing)
			:build()

		local realm = warband:realm()
		local desc = "warriors from " .. realm.name
		local realm_rect = top_bar_layout:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT)
		ui.panel(realm_rect)
		-- warband realm inspector button
		ib.icon_button_to_realm(gamescene, realm, realm_rect)
		-- warband name
		ui.centered_text(warband.name .. ", " .. desc, top_bar_layout:next(rect.width - (ut.BASE_HEIGHT + spacing) * 2, ut.BASE_HEIGHT))
		-- close button
		ib.icon_button_to_close(gamescene, top_bar_layout:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT))
	end

	ui.panel(panel)
	local top_panel = panel:subrect(
		0,
		0,
		panel.width,
		ut.BASE_HEIGHT,
		"left",
		'up'
	)
	draw_top_panel(top_panel)

	--- utitlity to draw characters with portrait and realm buttons
	---@param gam GameScene
	---@param rect Rect
	---@param office_title string
	---@param office_action string
	---@param character Character?
	---@param extra_rect_space fun(rect:Rect, character:Character?)?
	local function draw_office_panel(gam, rect, office_title, office_action, character, extra_rect_space)
		ui.panel(rect)
		rect:shrink(spacing)
		ui.text(office_title .. ":  ", rect:subrect(ut.BASE_HEIGHT * 2, 0, rect.width - ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT, "left", "up"), "left", "up")
		local button_rect = rect:subrect(0, 0, rect.width - ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT, "right", "center")
		local portrait_rect = rect:subrect(0, 0, ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, "left", "up")
		local realm_rect = rect:subrect(0, 0, ut.BASE_HEIGHT, ut.BASE_HEIGHT, "right", "up")
		local bottom_rect = rect:subrect(0, 0, rect.width, ut.BASE_HEIGHT, "center", "down")
		if extra_rect_space then
			extra_rect_space(bottom_rect, character)
		else
			ui.panel(bottom_rect, 1, true)
		end
		if character then
			ui.panel(realm_rect, 1, true)
			ib.icon_button_to_realm(gam, character.realm, realm_rect)
			ib.icon_button_to_character(gam, character, portrait_rect)
			ib.text_button_to_character(gam, character, button_rect,
				character.name, character.name .. " is currently " .. office_action .. " this warband.")
		else
			ui.panel(portrait_rect, 1, true)
			ut.render_icon(portrait_rect, "uncertainty.png", 1, 1, 1, 1)
			ut.text_button("empty", button_rect, nil, false)
		end
	end

	local panel_width = panel.width - spacing * 2
	local panel_layout = ui.layout_builder()
		:vertical()
		:position(panel.x + spacing, top_panel.x + top_panel.height + spacing)
		:spacing(spacing)
		:build()

	local leader_supply_panels = panel_layout:next(panel_width, ut.BASE_HEIGHT * 3 + spacing * 2)
	local officer_layout = ui.layout_builder()
		:horizontal()
		:position(leader_supply_panels.x, leader_supply_panels.y)
		:spacing(spacing)
		:build()

	---@param rect Rect
	---@param character Character
	local function draw_noncombatant_stats(rect, character)
		if character then
			local unit_icon_rect = rect:subrect(-ut.BASE_HEIGHT, -ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT, ut.BASE_HEIGHT, "right", "up")
			local width_fraction = rect.width / 5
			-- declare variables and intialize as a male noncombatant character
			local unit_name = "noncombatant"
			local race_spot, race_vis, race_size = character.race.spotting, character.race.visibility, character.race.male_body_size
			local race_food, race_carry = character.race.male_needs[NEED.FOOD]['food'] / 30, character.race.male_efficiency[job_types.HAULING]
			local female, her = "male", "his"
			-- check if female match gender and racial modifiers
			if character.female then
				female, her = "female", "her"
				race_food = character.race.female_needs[NEED.FOOD]['food'] / 30
				race_size = character.race.female_body_size
				race_carry = character.race.female_efficiency[job_types.HAULING]
			end
			-- definition of noncombatant stats
			local base_speed, speed = 1, 1
			local base_spot, spot = 1, race_spot
			local base_vis, vis = 1, race_vis * race_size
			local base_food, food = 0, race_food
			local base_carry, carry = 0, race_carry
			-- override with unit stats if character is commander
			if warband.commander and character == warband.commander then
				local unit = warband.units[character]
				unit_name = unit.name
				base_speed, speed = unit.speed, unit:get_speed(character)
				base_spot, spot = unit.spotting, unit:get_spotting(character)
				base_vis, vis = unit.visibility, unit:get_visibility(character)
				base_food, food = unit.supply_useds / 30, unit:get_supply_use(character)
				base_carry, carry = unit.supply_capacity / 4, unit:get_supply_capacity(character)
				ui.panel(unit_icon_rect)
				ut.render_icon(unit_icon_rect, unit.icon, 1, 1, 1, 1)
				unit_icon_rect:shrink(-1)
				ut.render_icon(unit_icon_rect, unit.icon, unit.r, unit.g, unit.b, 1)
			else
				ui.panel(unit_icon_rect)
				ut.render_icon(unit_icon_rect, "inner-self.png", 1, 1, 1, 1)
				unit_icon_rect:shrink(-1)
				ut.render_icon(unit_icon_rect, "inner-self.png", 1, 1, 1, 1)
			end
			-- actually draw stats in rect
			ut.generic_number_field(
				"fast-forward-button.png",
				speed,
				rect:subrect(0, 0, width_fraction, rect.height, "left", "center"),
				character.name .. " has a speed of " .. ut.to_fixed_point2(speed) .. "."
					.. "\n - As a " .. unit_name .. ", " .. character.name .. " has a base speed of " .. ut.to_fixed_point2(base_speed) .. ".",
				ut.NUMBER_MODE.PERCENTAGE,
				ut.NAME_MODE.ICON)
			ut.generic_number_field(
				"magnifying-glass.png",
				spot,
				rect:subrect(width_fraction, 0, width_fraction, rect.height, "left", "center"),
				character.name .. " has a spotting bonus of " .. ut.to_fixed_point2(spot) .. "."
					.. "\n - As a " .. unit_name .. ", " .. character.name .. " has a base spotting bonus of " .. ut.to_fixed_point2(base_spot) .. "."
					.. "\n - Being a " .. female.. " " .. character.race.name .. " modifies this by " .. her .." racial spotting of " .. ut.to_fixed_point2(character.race.spotting * 100) .. "%.",
				ut.NUMBER_MODE.NUMBER,
				ut.NAME_MODE.ICON)
			ut.generic_number_field(
				"high-grass.png",
				vis,
				rect:subrect(0, 0, width_fraction, rect.height, "center", "center"),
				character.name .. " has a visibility of " .. ut.to_fixed_point2(vis) .. "."
					.. "\n - As a " ..  unit_name .. ", " .. character.name .. " has a base visibility of " .. ut.to_fixed_point2(base_vis) .. "."
					.. "\n - Being a " .. female.. " " .. character.race.name .. " modifies this by " .. her .." racial visibility of " .. ut.to_fixed_point2(character.race.visibility * 100) .. "% and a size of " .. ut.to_fixed_point2(race_size) ..".",
				ut.NUMBER_MODE.NUMBER,
				ut.NAME_MODE.ICON)
			ut.generic_number_field(
				"sliced-bread.png",
				food,
				rect:subrect(-width_fraction, 0, width_fraction, rect.height, "right", "center"),
				character.name .. " uses " .. ut.to_fixed_point2(food) .. " units of food per day of traveling."
					.. "\n - As a " ..  unit_name .. ", " .. character.name .. " has a base daily supply use of " .. ut.to_fixed_point2(base_food) .. "."
					.. "\n - Being a " .. female.. " " .. character.race.name .. " adds " .. her .. " daily racial food consumption of " .. ut.to_fixed_point2(race_food) .. " units per day.",
				ut.NUMBER_MODE.NUMBER,
				ut.NAME_MODE.ICON)
			ut.generic_number_field(
				"cardboard-box.png",
				carry,
				rect:subrect(0, 0, width_fraction, rect.height, "right", "center"),
				character.name .. " has a hauling capacity of " .. ut.to_fixed_point2(base_carry) .. "."
					.. "\n - As a " ..  unit_name .. ", " .. character.name .. " has a base of " .. ut.to_fixed_point2(base_carry) .. "."
					.. "\n - Being a " .. female.. " " .. character.race.name .. " adds " .. her .." racial hauling job efficiency of " .. ut.to_fixed_point2(race_carry) .. ".",
				ut.NUMBER_MODE.NUMBER,
				ut.NAME_MODE.ICON)
		else
			ui.panel(rect)
		end
	end

	-- noncombatant officer panels
	local leader_rect = officer_layout:next(ut.BASE_HEIGHT * 15 + spacing * 2, ut.BASE_HEIGHT * 3 + spacing * 2)
	draw_office_panel(gamescene, leader_rect, "Leader", "leading", warband.leader, draw_noncombatant_stats)
	local recruiter_rect = officer_layout:next(ut.BASE_HEIGHT * 15 + spacing * 2, ut.BASE_HEIGHT * 3 + spacing * 2)
	draw_office_panel(gamescene, recruiter_rect, "Recruiter", "recruiting for", warband.recruiter, draw_noncombatant_stats)

	-- SUPPLIES AND TREASURY PANELS
	local resource_rect = leader_supply_panels:subrect(0, 0, ut.BASE_HEIGHT * 13, ut.BASE_HEIGHT * 3 + spacing * 2, "right", "up")
	local resource_layout = ui.layout_builder()
		:vertical()
		:position(resource_rect.x, resource_rect.y)
		:spacing(spacing)
		:build()

	--- draws supplies info panel with stance buttons
	---@param rect Rect
	local function draw_supplies_panel(rect)

		ui.panel(rect)
		rect:shrink(spacing)

		local rect_width = rect.width
		local rect_height = rect.height
		ui.text("Supplies:  ", rect:subrect(0, 0, rect_width, rect_height / 3, "center", "up"), "center", "up")

		---@param x WarbandIdleStance
		local function set_stance(rect, x)
			if ut.text_button(
				x,
				rect,
				"Order your party to "
				.. x .. ".",
				(player_character and player_character == warband.leader)
					or (player_character and player_character == warband.recruiter),
				warband.idle_stance == x
			) then
				warband.idle_stance = x
			end
		end

		-- warband status
		ut.generic_string_field(
			"shrug.png",
			warband.status,
			rect:subrect(0, 0, rect_width / 3, rect_height / 3, "left", "center"),
			"This warband is currently " .. warband.status ..  ".",
			ut.NAME_MODE.ICON,
			true)
		-- supplies / day
		local daily_supply_consumption = warband:daily_supply_consumption()
		ut.generic_number_field(
			"sliced-bread.png",
			daily_supply_consumption,
			rect:subrect(0, 0, rect_width / 3, rect_height / 3, "left", "down"),
			"This warband cosumes " .. ut.to_fixed_point2(daily_supply_consumption) .. " units of food per day of traveling.",
			ut.NUMBER_MODE.NUMBER,
			ut.NAME_MODE.ICON
		)
		-- work time ratio
		ut.generic_number_field(
			"chart.png",
			warband.current_free_time_ratio,
			rect:subrect(0, 0, rect_width / 3, rect_height / 3, "center", "center"),
			"Warriors in this warband are free for " .. ut.to_fixed_point2(warband.current_free_time_ratio * 100) .. "% of their time.",
			ut.NUMBER_MODE.PERCENTAGE,
			ut.NAME_MODE.ICON
		)
		-- days of travel time
		local days_of_supply_consumption = warband:days_of_travel()
		ut.generic_number_field(
			"horizon-road.png",
			days_of_supply_consumption,
			rect:subrect(0, 0, rect_width / 3, rect_height / 3, "center", "down"),
			"With " .. ut.to_fixed_point2(warband:get_supply_available()) .. " units of food available,"
				.. " this warband has enough supplies for " .. ut.to_fixed_point2(days_of_supply_consumption) .. " days of travel"
				.. " while using " .. ut.to_fixed_point2(daily_supply_consumption) .. " units each day.",
			ut.NUMBER_MODE.NUMBER,
			ut.NAME_MODE.ICON
		)
		-- work button
		set_stance(rect:subrect(0, 0, rect_width / 3, rect_height / 3, "right", "center"), "work")
		-- forage button
		set_stance(rect:subrect(0, 0, rect_width / 3, rect_height / 3, "right", "down"), "forage")
	end
	local supplies_rect = resource_layout:next(ut.BASE_HEIGHT * 13, ut.BASE_HEIGHT * 3 + spacing * 2)
	draw_supplies_panel(supplies_rect)

	local location = warband:location()

	--- draws treasury info panel with +/- buttons
	---@param rect Rect
	local function draw_treasury_panel(rect)
		-- leaders can take and give, other warband characters can only give
		local can_transfer_money, can_gift_money = false, false
		if player_character then
			if warband.leader and warband.leader == player_character then
				can_transfer_money, can_gift_money = true, true
			elseif (warband.guard_of and warband.guard_of.leader == player_character)
				or (warband.recruiter and warband.recruiter == player_character)
				or (warband == player_character.unit_of_warband)
			then
				can_gift_money = true
			elseif warband.recruiter and warband.recruiter == player_character then
			end
		end

		ui.panel(rect)
		rect:shrink(spacing)
		local rect_height = rect.height / 3
		local half_width = rect.width / 2
		local third_width = rect.width / 3

		ui.text("Treasury:  ", rect:subrect(0, 0, rect.width, ut.BASE_HEIGHT, "center", "up"), "center", "up")

		---@param x number
		local function gift_to_treasury_target(rect, x)
			local preposition = 'from'
			local tooltip = "Take "

			local amount = x * WARBAND_SIPHON_AMOUNT

			if x > 0 then
				tooltip = "Give "
				preposition = 'to'
				amount = math.min(amount, WORLD.player_character.savings)
			elseif x < 0 then
				amount = math.max(amount, -warband.treasury)
			end

			if x < 0 and can_gift_money and not can_transfer_money then
				tooltip = "You do not have permision to take funds from this warband treasury!"
			elseif not can_transfer_money then
				tooltip = "You do not have permision to transfer funds " .. preposition .. " this warband treasury!"
			else
				tooltip = tooltip
				.. ut.to_fixed_point2(math.abs(amount))
				.. MONEY_SYMBOL
				.. " of wealth "
				.. preposition
				.. " warband's treasury."
				.. "\nPress Ctrl and/or Shift to modify amount."
			end

			if ut.money_button(
				"",
				amount,
				rect,
				tooltip,
				can_transfer_money or (x > 0 and can_gift_money)
			) then
				economic_effects.gift_to_warband(warband, WORLD.player_character, amount)
			end
		end

		local treasury = warband.treasury
		local upkeep = warband:predict_upkeep()

		local months_of_upkeep = 9999
		if upkeep > 0 then
			months_of_upkeep = math.ceil(treasury / upkeep)
		end

		ut.money_entry_icon(warband.treasury, rect:subrect(0, 0, third_width, rect_height, "center", "center"),
			"This warband currently has " .. ut.to_fixed_point2(warband.treasury) .. MONEY_SYMBOL .. " in its treasury.")
		gift_to_treasury_target(rect:subrect(0, 0, third_width, rect_height, "left", "center"), -1)
		gift_to_treasury_target(rect:subrect(0, 0, third_width, rect_height, "right", "center"), 1)

		ut.generic_number_field(
			"two-coins.png",
			upkeep,
			rect:subrect(0, 0, half_width, rect_height, "left", "down"),
			"The warband is predicted to cost " .. ut.to_fixed_point2(-upkeep) .. MONEY_SYMBOL .. " each month.",
			ut.NUMBER_MODE.BALANCE,
			ut.NAME_MODE.ICON,
			true,
			true
		)
		ut.generic_number_field(
			"receive-money.png",
			months_of_upkeep,
			rect:subrect(0, 0, half_width, rect_height, "right", "down"),
			"The warbands treasury can afford ".. months_of_upkeep .. " months of upkeep.",
			ut.NUMBER_MODE.INTEGER,
			ut.NAME_MODE.ICON
		)
	end
	local treasury_rect = resource_layout:next(ut.BASE_HEIGHT * 10, ut.BASE_HEIGHT * 3 + spacing * 2)
	treasury_rect.x = treasury_rect.x + ut.BASE_HEIGHT * 3
	draw_treasury_panel(treasury_rect)

	-- STATUS AND STRENGTH PANEL

	--- draws row with comander and stats (if there is one) and the warband location
	---@param rect Rect
	local function draw_commander_panel(rect)

		---@param rect Rect
		local function draw_location_panel(rect)
			ui.panel(rect)
			rect:shrink(spacing)
			ui.text("Location:", rect:subrect(0, 0, rect.width - ut.BASE_HEIGHT, ut.BASE_HEIGHT, "right", "up"), "center", "up")
			local realm_icon_rect = rect:subrect(0, 0, ut.BASE_HEIGHT, ut.BASE_HEIGHT, "left", "down")
			local province_name_rect = rect:subrect(0, 0, rect.width - ut.BASE_HEIGHT, ut.BASE_HEIGHT, "right", "down")
			local province_realm = nil
			if location then
				province_realm = location.realm
				ib.text_button_to_province(gamescene, location, province_name_rect,
					location.name, "The warband is currently in the province of " .. location.name .. ".")
			else
				ut.text_button("unknown", province_name_rect, nil, false)
			end
			ui.panel(realm_icon_rect)
			if province_realm then
				ib.icon_button_to_realm(gamescene, province_realm, realm_icon_rect)
			else
				ut.render_icon(realm_icon_rect, "uncertainty.png", 1, 1, 1,1)
			end
		end

		-- draw commander name and portrait
		local layout_width = ut.BASE_HEIGHT * 3
		local commander_rect = rect:subrect(0, 0, ut.BASE_HEIGHT * 10 + spacing * 2, rect.height, "left", "up")
		draw_office_panel(gamescene, commander_rect, "Commander", "commanding", warband.commander, function (rect, character)
			if character then
				---@type UnitType, Race
				local commander_unit = warband.units[character]
				local unit_icon_rect = commander_rect:subrect(rect.height, 0, ut.BASE_HEIGHT, ut.BASE_HEIGHT, "left", "down" )
				ui.panel(unit_icon_rect)
				ut.render_icon(unit_icon_rect, commander_unit.icon, 1, 1, 1, 1)
				unit_icon_rect:shrink(-1)
				ut.render_icon(unit_icon_rect, commander_unit.icon, commander_unit.r, commander_unit.g, commander_unit.b, 1)
				ui.text_panel(commander_unit.name, commander_rect:subrect(0, 0, rect.width - ut.BASE_HEIGHT, ut.BASE_HEIGHT, "right", "down"))
			else

			end
		end)

		--TODO FIGURE OUT WHAT TO DO ABOUT THIS BUTTON WHEN RAIDING
		local location_rect = rect:subrect(commander_rect.width + spacing * 3, 0, ut.BASE_HEIGHT * 10 + spacing * 2, ut.BASE_HEIGHT * 2 + spacing * 2, "left", "up")
		draw_location_panel(location_rect)

		local commander = warband.commander
		if commander then
		--draw commander unit stats
			local commander_unit, commander_race = warband.units[commander], commander.race
			local commander_her, commander_female = "his", "male "
			local commander_size, commander_job = commander_race.male_body_size, commander_race.male_efficiency
			local commander_food = commander_race.male_needs[NEED.FOOD]['food']
			if commander.female then
				commander_her, commander_female = "her", "female "
				commander_size, commander_job = commander_race.female_body_size, commander_race.female_efficiency
			end
			local c_hp, c_armor, c_attack, c_speed = commander_unit:get_strength(commander)
			local c_spot, c_vis = commander_unit:get_spotting(commander) or 0, commander_unit:get_visibility(commander)
			local c_supply, c_loot = commander_unit:get_supply_use(commander), commander_unit:get_supply_capacity(commander)

			local strength_layout = ui.layout_builder()
				:horizontal()
				:position(commander_rect.x + commander_rect.width, commander_rect.y + ut.BASE_HEIGHT * 2 + spacing)
				:spacing(0)
				:build()

			ut.generic_number_field(
				"plus.png",
				c_hp,
				strength_layout:next(layout_width, ut.BASE_HEIGHT),
				commander.name .. " has " .. ut.to_fixed_point2(c_hp) .. " health. As a " 
					..  commander_unit.name .. ", " .. commander.name .. " has a base health of "
					.. ut.to_fixed_point2(commander_unit.base_health) .. ". Being a "
					.. commander_female .. commander.race.name .. " modifies this by "
					.. commander_her .." size of " .. ut.to_fixed_point2(commander_size) .. ".",
				ut.NUMBER_MODE.NUMBER,
				ut.NAME_MODE.ICON)
			ut.generic_number_field(
				"stone-axe.png",
				c_attack,
				strength_layout:next(layout_width, ut.BASE_HEIGHT),
				warband.commander.name .. " has " .. ut.to_fixed_point2(c_attack) .. " attack. As a "
				..  commander_unit.name .. ", " .. commander.name .. " has a base attack of "
				.. ut.to_fixed_point2(commander_unit.base_attack) .. ". Being a "
				.. commander_female .. commander.race.name .. " modifies this by "
				.. commander_her .." racial warrior job efficiency of " .. ut.to_fixed_point2(commander_job[job_types.WARRIOR] * 100) .. "%.",
				ut.NUMBER_MODE.NUMBER,
				ut.NAME_MODE.ICON)
			ut.generic_number_field(
				"round-shield.png",
				c_armor,
				strength_layout:next(layout_width, ut.BASE_HEIGHT),
				warband.commander.name .. " has " .. ut.to_fixed_point2(c_armor) .. " armor.",
				ut.NUMBER_MODE.NUMBER,
				ut.NAME_MODE.ICON)
			ut.generic_number_field(
				"fast-forward-button.png",
				c_speed,
				strength_layout:next(layout_width, ut.BASE_HEIGHT),
				warband.commander.name .. " has a speed of " .. ut.to_fixed_point2(c_speed) .. ".",
				ut.NUMBER_MODE.PERCENTAGE,
				ut.NAME_MODE.ICON)
			ut.generic_number_field(
				"magnifying-glass.png",
				c_spot,
				strength_layout:next(layout_width, ut.BASE_HEIGHT),
				warband.commander.name .. " has a spotting bonus of " .. ut.to_fixed_point2(c_spot) .. ".\nAs a "
				..  commander_unit.name .. ", " .. commander.name .. " has a base spotting bonus of "
				.. ut.to_fixed_point2(commander_unit.spotting) .. ". Being a "
				.. commander_female .. commander.race.name .. " modifies this by "
				.. commander_her .." racial efficiency of " .. ut.to_fixed_point2(commander_race.spotting * 100) .. "%.",
				ut.NUMBER_MODE.NUMBER,
				ut.NAME_MODE.ICON)
			ut.generic_number_field(
				"high-grass.png",
				c_vis,
				strength_layout:next(layout_width, ut.BASE_HEIGHT),
				warband.commander.name .. " has a visibility of " .. ut.to_fixed_point2(c_vis) .. ".\nAs a "
				..  commander_unit.name .. ", " .. commander.name .. " has a base visibility of "
				.. ut.to_fixed_point2(commander_unit.visibility) .. ". Being a "
				.. commander_female .. commander.race.name .. " modifies this by "
				.. commander_her .." racial efficiency of " .. ut.to_fixed_point2(commander_race.visibility * 100) .. "%.",
				ut.NUMBER_MODE.NUMBER,
				ut.NAME_MODE.ICON)
			ut.generic_number_field(
				"sliced-bread.png",
				c_supply,
				strength_layout:next(layout_width, ut.BASE_HEIGHT),
				warband.commander.name .. " uses " .. ut.to_fixed_point2(c_supply) .. " units of food per day of traveling.\nAs a "
				..  commander_unit.name .. ", " .. commander.name .. " has a base supply use of "
				.. ut.to_fixed_point2(commander_unit.supply_useds) .. ". Being a "
				.. commander_female .. commander.race.name .. " modifies this by "
				.. commander_her .." racial food consumption of " .. ut.to_fixed_point2(commander_food) .. " units per month.",
				ut.NUMBER_MODE.NUMBER,
				ut.NAME_MODE.ICON)
			ut.generic_number_field(
				"cardboard-box.png",
				c_loot,
				strength_layout:next(layout_width, ut.BASE_HEIGHT),
				warband.commander.name .. " has a hauling capacity of " .. ut.to_fixed_point2(c_loot) .. ".\nAs a "
				..  commander_unit.name .. ", " .. commander.name .. " has a base of "
				.. ut.to_fixed_point2(commander_unit.visibility) .. ". Being a "
				.. commander_female .. commander.race.name .. " adds "
				.. commander_her .." racial hauling job efficiency of " .. ut.to_fixed_point2(commander_job[job_types.HAULING]) .. ".",
				ut.NUMBER_MODE.NUMBER,
				ut.NAME_MODE.ICON)
		end
	end

	local commander_panel = panel_layout:next(panel_width, ut.BASE_HEIGHT * 3 + spacing * 2)
	draw_commander_panel(commander_panel)


	--- draws total strength values for warband based on warriors and officers
	---@param rect Rect
	local function draw_strength_panel(rect)
		-- warband count and target and strength calculations
		local total_health, total_attack, total_armor, _, count = warband:get_total_strength()
		local plural = "s"
		if count == 1 then
			plural = ""
		end

		local noncombatants = warband:pop_size() - warband:size()
		local non_plural = "s"
		if noncombatants == 1 then
			non_plural = ""
		end

		-- WARBAND STRENGTH
		local avg_health, avg_armor, avg_attack  = math.max(total_health / count, 0), math.max(total_armor / count, 0), math.max(total_attack / count, 0)
		local total_speed, avg_speed = warband:get_speed()

		local strength_width = ut.BASE_HEIGHT * 3
		local strength_height = ut.BASE_HEIGHT
		local strength_layout = ui.layout_builder()
			:horizontal()
			:position(rect.x, rect.y)
			:spacing(0)
			:build()

		ui.text_panel("Strength: ", strength_layout:next(ut.BASE_HEIGHT * 4 + spacing * 2, strength_height))

		-- warband moral
		ut.generic_number_field(
			"musical-notes.png",
			warband.morale,
			strength_layout:next(strength_width, strength_height),
			"This warband is currently at " .. ut.to_fixed_point2(warband.morale * 100) .. "% morale.",
			ut.NUMBER_MODE.PERCENTAGE,
			ut.NAME_MODE.ICON)

		-- warband count and target
		local target_count = tabb.accumulate(warband.units_target, 0, function (a, k, v)
			return a + v
		end)
		local warband_count = count .. " / " .. target_count
		local target_plural = "s"
		if target_count == 1 then
			target_plural = ""
		end
		ut.generic_string_field(
			"minions.png",
			warband_count,
			strength_layout:next(strength_width, strength_height),
			"This warband is currently at " .. warband_count .. " warrior" .. target_plural ..".",
			ut.NAME_MODE.ICON,
			true)

		-- total health
		ut.generic_number_field(
			"plus.png",
			total_health,
			strength_layout:next(strength_width, strength_height),
			"Each unit has an average of " .. ut.to_fixed_point2(avg_health)
				.. " from a total of " .. ut.to_fixed_point2(total_health)
				.. " from " .. count .. " warrior" .. plural .. ".",
			ut.NUMBER_MODE.NUMBER,
			ut.NAME_MODE.ICON)
		-- total attack
		ut.generic_number_field(
			"stone-axe.png",
			total_attack,
			strength_layout:next(strength_width, strength_height),
			"Each unit has an average of " .. ut.to_fixed_point2(avg_attack)
				.. " from a total of " .. ut.to_fixed_point2(total_attack)
				.. " from " .. count .. " warrior" .. plural .. ".",
			ut.NUMBER_MODE.NUMBER,
			ut.NAME_MODE.ICON)
		-- total armor
		ut.generic_number_field(
			"round-shield.png",
			total_armor,
			strength_layout:next(strength_width, strength_height),
			"Each unit has an average of " .. ut.to_fixed_point2(avg_armor)
				.. " from a total of " .. ut.to_fixed_point2(total_armor)
				.. " from " .. count .. " warrior" .. plural .. ".",
			ut.NUMBER_MODE.NUMBER,
			ut.NAME_MODE.ICON)
		-- mean speed
		ut.generic_number_field(
			"fast-forward-button.png",
			avg_speed,
			strength_layout:next(strength_width, strength_height),
			"This warband has an speed of " .. ut.to_fixed_point2(avg_speed)
				.. ". This is a calculated average from a total of " .. ut.to_fixed_point2(total_speed)
				.. " from " .. count .. " warrior" .. plural .. " and " .. noncombatants .. " noncombatant" .. non_plural .. ".",
			ut.NUMBER_MODE.PERCENTAGE,
			ut.NAME_MODE.ICON)

		-- spotting and visibility
		local status = ""
		if warband.status == "idle" then
			status = "\n - While the warband is idle, this bonus is multiplied by 5."
		end
		if warband.status == "patrol" then
			status = "\n - While the warband is on patrol, this bonus is multiplied by 10."
		end
		local unit_spotting = tabb.accumulate(warband.units, 0, function (a, k, v)
			return a + v:get_spotting(k)
		end)
		if warband.recruiter and warband.recruiter ~= warband.commander then
			unit_spotting = unit_spotting + warband.recruiter.race.spotting
		end
		if warband.leader and warband.leader ~= warband.recruiter and warband.leader ~= warband.commander then
			unit_spotting = unit_spotting + warband.leader.race.spotting
		end
		ut.generic_number_field(
			"magnifying-glass.png",
			warband:spotting(),
			strength_layout:next(strength_width, strength_height),
			"This warband has normal spotting bonus of " .. ut.to_fixed_point2(unit_spotting)
				.. " from " .. count .. " warrior" .. plural .. " and " .. noncombatants .. " noncombatant" .. non_plural .. "."
				.. " This is weighted against opposing visibility for spotting other warbands and armies." .. status,
			ut.NUMBER_MODE.NUMBER,
			ut.NAME_MODE.ICON)
		local visibility = warband:get_visibility()
		ut.generic_number_field(
			"high-grass.png",
			visibility,
			strength_layout:next(strength_width, strength_height),
			"This warband has visibility of " .. ut.to_fixed_point2(visibility)
				.. " from " .. count .. " warrior" .. plural .. " and " .. noncombatants .. " noncombatant" .. non_plural .. "."
				.. " This is weighted against an opposing spotting bonus to avoid being spotted by other warbands and armies.",
			ut.NUMBER_MODE.NUMBER,
			ut.NAME_MODE.ICON)

		-- supply cost and loot capacity
		local supply_use = warband:daily_supply_consumption()
		ut.generic_number_field(
			"sliced-bread.png",
			supply_use,
			strength_layout:next(strength_width, strength_height),
			"This warband uses " .. ut.to_fixed_point2(supply_use)
				.. " units of food per day of travel from " .. count .. " warrior" .. plural .. " and " .. noncombatants .. " noncombatant" .. non_plural .. ".",
			ut.NUMBER_MODE.NUMBER,
			ut.NAME_MODE.ICON
		)
		local loot_capacity = warband:get_loot_capacity()
		ut.generic_number_field(
			"cardboard-box.png",
			loot_capacity,
			strength_layout:next(strength_width, strength_height),
			"This warband can haul up to " .. ut.to_fixed_point2(loot_capacity)
				.. " units of goods from " .. count .. " warrior" .. plural .. " and " .. noncombatants .. " noncombatant" .. non_plural .. ".",
			ut.NUMBER_MODE.NUMBER,
			ut.NAME_MODE.ICON
		)

	end

	local strength_panel = panel_layout:next(panel_width, ut.BASE_HEIGHT)
	draw_strength_panel(strength_panel)

	-- WARRIORS AND UNIT TYPES

	--- builds and draws list of recruitable unit types
	---@param rect Rect
	local function draw_recuit_panel(rect)

		-- UNIT TYPE RECRUIT PANEL
		---@type table<UnitType, UnitType>
		local unit_types = {}

		for _, unit in pairs(location.unit_types) do
			unit_types[unit] = unit
		end

		for _, unit in pairs(warband.units) do
			unit_types[unit] = unit
		end
		unit_list_state = list_widget(
			rect,
			unit_types,
			{
				{
					header = ".",
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.render_icon(rect, v.icon, v.r, v.g, v.b, 1)
						rect:shrink(-1)
						ut.render_icon(rect, v.icon, v.r, v.g, v.b, 1)
					end,
					width = 1,
					---@param v UnitType
					value = function (k, v)
						return v.icon
					end
				},
				{
					header = "name",
					---@param v UnitType
					render_closure = function (rect, k, v)
						ui.text(v.name, rect, "center", "center")
					end,
					width = 5.25,
					---@param v UnitType
					value = function (k, v)
						return v.name
					end
				},
				{
					header = "cost",
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.generic_number_field(
							"coins.png",
							v.base_price,
							rect,
							"The base hiring cost of this unit type.",
							ut.NUMBER_MODE.MONEY,
							ut.NAME_MODE.ICON)
					end,
					width = 4,
					---@param v UnitType
					value = function (k, v)
						return v.base_price
					end
				},
				{
					header = "health",
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.generic_number_field(
							"plus.png",
							v.base_health,
							rect,
							"The base value of health this unit type has.",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param v UnitType
					value = function (k, v)
						return v.base_health
					end
				},
				{
					header = "attack",
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.generic_number_field(
							"stone-axe.png",
							v.base_attack,
							rect,
							"The base attack strength of this unit type.",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param v UnitType
					value = function (k, v)
						return v.base_attack
					end
				},
				{
					header = "armor",
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.generic_number_field(
							"round-shield.png",
							v.base_armor,
							rect,
							"The base value for this unit type's armor.",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param v UnitType
					value = function (k, v)
						return v.base_armor
					end
				},
				{
					header = "speed",
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.generic_number_field(
							"fast-forward-button.png",
							v.speed,
							rect,
							"How fast this unit type moves.",
							ut.NUMBER_MODE.PERCENTAGE,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param v UnitType
					value = function (k, v)
						return v.speed
					end
				},
				{
					header = "spot",
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.generic_number_field(
							"magnifying-glass.png",
							v.visibility,
							rect,
							"How good this unit type is at spotting. Affects the chance of this warband spotting other warbands and armies.",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param v UnitType
					value = function (k, v)
						return v.spotting
					end
				},
				{
					header = "visibility",
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.generic_number_field(
							"high-grass.png",
							v.visibility,
							rect,
							"How easy it is to spot this unit type. Affects the chance of warbands and armies being spotted.",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param v UnitType
					value = function (k, v)
						return v.visibility
					end
				},
				{
					header = "supply",
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.generic_number_field(
							"sliced-bread.png",
							v.supply_useds / 30,
							rect,
							"Base supply used by unit type per day. Affects how much food the unit spends when traveling.",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param v UnitType
					value = function (k, v)
						return v.supply_useds / 30
					end
				},
				{
					header = "hauling",
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.generic_number_field(
							"cardboard-box.png",
							v.supply_capacity / 4,
							rect,
							"Base carrying capacity of unit type. Affects how much is looted when raiding.",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param v UnitType
					value = function (k, v)
						return v.supply_capacity / 4
					end
				},
				{
					header = "upkeep",
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.generic_number_field(
							"receive-money.png",
							v.upkeep,
							rect,
							"The base monthly upkeep price for this unit type.",
							ut.NUMBER_MODE.MONEY,
							ut.NAME_MODE.ICON,
							true)
					end,
					width = 4,
					---@param v UnitType
					value = function (k, v)
						return v.upkeep
					end
				},
				{
					header = "target",
					---@param v UnitType
					render_closure = function (rect, k, v)
						local can_recruit = player_character and (warband == player_character.leading_warband 
							or warband == player_character.recruiter_for_warband
							or warband.guard_of and player_character == warband.guard_of.leader)

						local target = warband.units_target[v] or 0
						local current = warband.units_current[v] or 0

						local dec_but = rect:subrect(0,0, rect.height, rect.height, "left", "center")
						if can_recruit then
							if target > 0 then
								if ut.text_button('-1', dec_but, "Decrease the number of units to recrut by one.") then
									warband.units_target[v] = math.max(0, target - 1)
								end
							else
								ut.text_button('X', dec_but, "No unit to disband!", false)
							end
						end

						ui.centered_text(tostring(current) .. '/' .. tostring(target), rect:subrect(0, 0, rect.width - 2 * rect.height, rect.height, "center", "center"))


						local current_budget = warband:monthly_budget()
						local target_budget = warband:predict_upkeep()

						local inc_but = rect:subrect(0,0, rect.height, rect.height, "right", "center")
						if can_recruit then
							if current_budget > target_budget + v.upkeep then
								if ut.text_button('+1', inc_but, "Increase the number of units to recrut by one.") then
									warband.units_target[v] = math.max(0, target + 1)
								end
							else
								ut.text_button('X', inc_but, "Not enough military funding!", false)
							end
						end
					end,
					width = 5,
					---@param v UnitType
					value = function (k, v)
						return warband.units_current[v] or 0
					end
				},
			},
			unit_list_state, nil, true
		)()
	end

	--- draws list of all warriors in warband
	---@param rect Rect
	local function draw_warrior_panel(rect)

		-- CURRENT WARRIORS PANEL
		type_list_state = list_widget(
			rect,
			warband.units,
			{
				{
					header = ".",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.render_icon(rect, v.icon, v.r, v.g, v.b, 1)
						rect:shrink(-1)
						ut.render_icon(rect, v.icon, v.r, v.g, v.b, 1)
					end,
					width = 1,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return v.name
					end
				},
				{
					header = "name",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						ui.text(k.name, rect, "center", "center")
					end,
					width = 5.25,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return k.name
					end
				},
				{
					header = ".",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						if k:is_character() then
							ib.icon_button_to_character(gamescene, k, rect)
						else
							require "game.scenes.game.widgets.portrait"(rect, k)
						end
					end,
					width = 1,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return k.race.name
					end
				},
				{
					header = "age",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						ui.text(tostring(k.age), rect, "center", "center")
					end,
					width = 2,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return k.age
					end
				},
				{
					header = "sex",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						local f = "m"
						if k.female then
							f = "f"
						end
						ui.text(f, rect, "center", "center")
					end,
					width = 1,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return tostring(k.female)
					end
				},
				{
					header = "health",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						local base, stat = v.base_health, v:get_health(k)
						local size = k.race.male_body_size
						local female, her = "male", "his"
						if k.female then
							female, her = "female", "her"
							size = k.race.female_body_size
						end
						ut.generic_number_field(
							"plus.png",
							stat,
							rect,
							k.name .. " has " .. ut.to_fixed_point2(stat) .. " health."
								.. "\n - As a "  ..  v.name .. ", " .. k.name .. " has a base health of " .. ut.to_fixed_point2(base) .. "."
								.. "\n - Being a " .. female.. " " .. k.race.name .. " modifies this by " .. her .." size of " .. ut.to_fixed_point2(size) .. ".",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return v:get_health(k)
					end
				},
				{
					header = "attack",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						local base, stat = v.base_attack, v:get_attack(k)
						local job = k.race.male_efficiency[job_types.WARRIOR]
						local female, her = "male", "his"
						if k.female then
							female, her = "female", "her"
							job = k.race.female_efficiency[job_types.WARRIOR]
						end
						ut.generic_number_field(
							"stone-axe.png",
							stat,
							rect,
							k.name .. " has " .. ut.to_fixed_point2(stat) .. " attack."
								.. "\n - As a " ..  v.name .. ", " .. k.name .. " has a base attack of " .. ut.to_fixed_point2(base) .. "."
								.. "\n - Being a " .. female.. " " .. k.race.name .. " modifies this by " .. her .." racial warrior efficiency of " .. ut.to_fixed_point2(job * 100) .. "%.",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return v:get_attack(k)
					end
				},
				{
					header = "armor",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						local base, stat = v.base_armor, v:get_armor(k)
						local female, her = "male", "his"
						if k.female then
							female, her = "female", "her"
						end
						ut.generic_number_field(
							"round-shield.png",
							stat,
							rect,
							k.name .. " has " .. ut.to_fixed_point2(stat) .. " armor."
								.. "\n - As a " ..  v.name .. ", " .. k.name .. " has a base armor of " .. ut.to_fixed_point2(base) .. ".",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return v:get_armor(k)
					end
				},
				{
					header = "speed",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						local base, stat = v.speed, v:get_speed(k)
						ut.generic_number_field(
							"fast-forward-button.png",
							stat,
							rect,
							k.name .. " has a speed of " .. ut.to_fixed_point2(stat) .. "."
							.. "\n - As a " ..  v.name .. ", " .. k.name .. " has a base speed of " .. ut.to_fixed_point2(base) .. ".",
							ut.NUMBER_MODE.PERCENTAGE,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return v:get_speed(k)
					end
				},
				{
					header = "spot",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						local base, stat = v.spotting, v:get_spotting(k)
						local female, her = "male", "his"
						if k.female then
							female, her = "female", "her"
						end
						ut.generic_number_field(
							"magnifying-glass.png",
							stat,
							rect,
							k.name .. " has a spotting bonus of " .. ut.to_fixed_point2(stat) .. "."
								.. "\n - As a " .. v.name .. ", " .. k.name .. " has a base spotting bonus of " .. ut.to_fixed_point2(base) .. "."
								.. "\n - Being a " .. female.. " " .. k.race.name .. " modifies this by " .. her .." racial spotting of " .. ut.to_fixed_point2(k.race.spotting * 100)
								.. "%.",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return v:get_spotting(k)
					end
				},
				{
					header = "visibility",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						local base, stat = v.visibility, v:get_visibility(k)
						local female, her = "male", "his"
						local size = k.race.male_body_size
						if k.female then
							female, her = "female", "her"
							size = k.race.female_body_size
						end
						ut.generic_number_field(
							"high-grass.png",
							stat,
							rect,
							k.name .. " has a visibility of " .. ut.to_fixed_point2(stat) .. "."
								.. "\n - As a " ..  v.name .. ", " .. k.name .. " has a base visibility of " .. ut.to_fixed_point2(base) .. "."
								.. "\n - Being a " .. female.. " " .. k.race.name .. " modifies this by " .. her .." racial visibility of " .. ut.to_fixed_point2(k.race.visibility * 100) .. "% and a size of " .. ut.to_fixed_point2(size) ..".",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return v:get_visibility(k)
					end
				},
				{
					header = "supply",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						local base, stat = v.supply_useds / 30, v:get_supply_use(k)
						local food_need = k.race.male_needs[NEED.FOOD]['food']
						local female, her = "male", "his"
						if k.female then
							female, her = "female", "her"
							food_need = k.race.female_needs[NEED.FOOD]['food']
						end
						ut.generic_number_field(
							"sliced-bread.png",
							stat,
							rect,
							k.name .. " uses " .. ut.to_fixed_point2(stat) .. " units of food per day of traveling."
								.. "\n - As a " ..  v.name .. ", " .. k.name .. " has a base daily supply use of " .. ut.to_fixed_point2(base) .. "."
								.. "\n - Being a " .. female.. " " .. k.race.name .. " adds " .. her .. " daily racial food consumption of " .. ut.to_fixed_point2(food_need / 30) .. " units per day.",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return v:get_supply_use(k) / 30
					end
				},
				{
					header = "hauling",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						local base, stat = v.supply_capacity / 4, v:get_supply_capacity(k)
						local job = k.race.male_efficiency[job_types.HAULING]
						local female, her = "male", "his"
						if k.female then
							female, her = "female", "her"
							job = k.race.female_efficiency[job_types.HAULING]
						end
						ut.generic_number_field(
							"cardboard-box.png",
							stat,
							rect,
							k.name .. " has a hauling capacity of " .. ut.to_fixed_point2(stat) .. "."
								.. "\n - As a " ..  v.name .. ", " .. k.name .. " has a base of " .. ut.to_fixed_point2(base) .. "."
								.. "\n - Being a " .. female.. " " .. k.race.name .. " adds " .. her .." racial hauling job efficiency of " .. ut.to_fixed_point2(job) .. ".",
							ut.NUMBER_MODE.NUMBER,
							ut.NAME_MODE.ICON)
					end,
					width = 3,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return  v:get_supply_capacity(k)
					end
				},
				{
					header = "savings",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						ut.money_entry(
							"",
							k.savings,
							rect,
							"Savings of this character. "
							.. "Characters spend them on buying food and other commodities."
						)
					end,
					width = 4,
					---@param v UnitType
					---@param k POP
					value = function (k, v)
						return v.upkeep
					end
				},
				{
					header = "satisfac.",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						local needs_tooltip = ""
						for need, values in pairs(k.need_satisfaction) do
							local tooltip = ""
							for case, value in pairs(values) do
								if value.demanded > 0 then
									tooltip = tooltip .. "\n  " .. case .. ": "
										.. ut.to_fixed_point2(value.consumed) .. " / " .. ut.to_fixed_point2(value.demanded)
										.. " (" .. ut.to_fixed_point2(value.consumed / value.demanded * 100) .. "%)"
								end
							end
							if tooltip ~= "" then
								needs_tooltip = needs_tooltip .. "\n".. NEED_NAME[need] .. ": " .. tooltip
							end
						end

						ut.data_entry_percentage(
							"",
							k.basic_needs_satisfaction,
							rect,
							"Satisfaction of needs of this character. \n" .. needs_tooltip
						)
					end,
					width = 4,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return k.basic_needs_satisfaction
					end
				},
				{
					header = "X",
					---@param k POP
					---@param v UnitType
					render_closure = function (rect, k, v)
						local icon = ASSETS.icons["cancel.png"]
						local player_character = WORLD.player_character
						local text = "You do not have any control over this warband."
						if player_character then
							text = "Unrecruit this warrior!?"
						end
						if ut.icon_button(icon,
							rect,
							text,
							player_character and ( player_character == warband.leader
								or (warband.recruiter and player_character == warband.recruiter)
							-- hackish: 'let the realm leader fire warriors they want to'
								or (not warband.leader and warband.recruiter and player_character == warband.recruiter.realm.leader))
						) then
							-- check if trying to fire commander first
							if warband.commander and warband.commander == k then
								warband:unset_commander()
							else
								warband:fire_unit(k)
							end
						end
					end,
					width = 1,
					---@param k POP
					---@param v UnitType
					value = function (k, v)
						return k.name
					end
				},
			},
			type_list_state, nil, true
		)()
	end
	local unit_panel = panel_layout:next(panel_width, ut.BASE_HEIGHT * 5 - spacing)

	local unit_panel_layout = ui.layout_builder()
		:horizontal()
		:position(panel_width - ut.BASE_HEIGHT * 8 + spacing, strength_panel.y)
		:build()
	unit_panel = unit_panel:subrect(0, 0, unit_panel.width, unit_panel.height, "left", "down")
	ui.panel(unit_panel)
	unit_panel:shrink(spacing)
	unit_panel_tab = ut.tabs(unit_panel_tab, unit_panel_layout, {
		{
			text = "RECRUIT",
			tooltip = "Show all recuitable units in this province.",
			closure = function ()
				draw_recuit_panel(unit_panel)
			end
		},
		{
			text = "WARRIOR",
			tooltip = "Show all warriors in this warband.",
			closure = function ()
				draw_warrior_panel(unit_panel)
			end
		}
	}, 1, ut.BASE_HEIGHT * 5)
end


return window