local tabb = require "engine.table"

local ui = require "engine.ui";
local ut = require "game.ui-utils"

local pv = require "game.raws.values.political"
local ev = require "game.raws.values.economical"

local economic_effects = require "game.raws.effects.economic"

local inspector = {}

local units_scroll = 0

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
	local panel = fs:subrect(ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT * 2, 600, 680, "left", 'up')
	return panel
end

---Returns whether or not clicks on the planet can be registered.
---@return boolean
function inspector.mask()
	if ui.trigger(get_main_panel()) then
		return false
	else
		return true
	end
end

---comment
---@param rect Rect
---@param unit UnitType
---@param warband Warband
---@param possibility boolean
local function render_unit(rect, unit, warband, possibility)
	rect.width = rect.width / 2.5 - rect.height * 2
	ut.data_entry_icon(unit.icon, unit.description, rect, nil, nil, 'left')
	rect.x = rect.x + rect.width
	ut.money_entry('Unit upkeep: ', unit.upkeep, rect)

	rect.x = rect.x + rect.width
	rect.width = rect.height

	local character = WORLD.player_character
	if character == nil then return end

	local character_warband = character.recruiter_for_warband

	local target = warband.units_target[unit] or 0
	local current = warband.units_current[unit] or 0

	if character_warband == warband then
		if target > 0 then
			if ut.text_button('-1', rect, "Decrease the number of units to recrut by one") then
				warband.units_target[unit] = math.max(0, target - 1)
			end
		else
			ut.text_button('X', rect, "No unit to disband", false)
		end
	end
	rect.x = rect.x + rect.width + 5
	rect.width = 65
	ui.centered_text(tostring(current) .. '/' .. tostring(target), rect)
	rect.x = rect.x + rect.width + 5
	rect.width = rect.height


	local current_budget = warband:monthly_budget()
	local target_budget = warband:predict_upkeep()

	if character_warband == warband and possibility then
		if current_budget > target_budget + unit.upkeep then
			if ut.text_button('+1', rect, "Increase the number of units to recrut by one") then
				warband.units_target[unit] = math.max(0, target + 1)
			end
		else
			ut.text_button('X', rect, "Not enough military funding", false)
		end
	end
end

local WARBAND_SIPHON_AMOUNT = 1;

---comment
---@param gam GameScene
function inspector.draw(gam)

	if ui.is_key_held("lshift") or ui.is_key_held("rshift") then
		WARBAND_SIPHON_AMOUNT = 5
	elseif ui.is_key_held("lctrl") or ui.is_key_held("rctrl") then
		WARBAND_SIPHON_AMOUNT = 50
	else
		WARBAND_SIPHON_AMOUNT = 1
	end

	local panel = get_main_panel()
	local base_unit = UI_STYLE.scrollable_list_item_height

	local character = WORLD.player_character


	if character == nil then
		return
	end

	local warband = character.recruiter_for_warband

	if warband == nil then
		return
	end

	local can_transfer_money = false
	if character.leading_warband == warband then
		can_transfer_money = true
	end


	ui.panel(panel)

	local top = panel:subrect(
		0,
		0,
		panel.width,
		UI_STYLE.table_header_height,
		"left",
		'up'
	)
	ui.centered_text("Warband of " .. character.name, top)

	local bottom = panel:subrect(
		0,
		UI_STYLE.table_header_height,
		panel.width,
		panel.height - UI_STYLE.table_header_height,
		"left",
		'up'
	)

	local treasury_panel = bottom:subrect(
		0,
		0,
		bottom.width,
		UI_STYLE.scrollable_list_item_height,
		"left",
		'up'
	)

	local layout = ui.layout_builder()
		:horizontal()
		:position(treasury_panel.x, treasury_panel.y)
		:spacing(0)
		:build()

	ut.money_entry('Treasury', warband.treasury, layout:next(ut.BASE_HEIGHT * 8, treasury_panel.height))

	local treasury = warband.treasury
	local upkeep = warband:predict_upkeep()

	local months_of_upkeep = 9999
	if upkeep > 0 then
		months_of_upkeep = math.ceil(treasury / upkeep)
	end

	ut.integer_entry(
		"Upkeep: ",
		months_of_upkeep,
		layout:next(ut.BASE_HEIGHT * 8, treasury_panel.height),
		"Months of satisfied units upkeep"
	)

	ut.sqrt_number_entry(
		"Supply: ",
		warband:days_of_travel(),
		layout:next(ut.BASE_HEIGHT * 8, treasury_panel.height),
		"Days warband can move while using stored supply."
	)

	local warbands_treasury_control = bottom:subrect(
		0,
		UI_STYLE.scrollable_list_item_height,
		ut.BASE_HEIGHT * 4,
		UI_STYLE.scrollable_list_item_height,
		"left",
		'up'
	)

	---@param x number
	local function gift_to_treasury_target(x)
		local preposition = 'from'
		if x > 0 then
			preposition = 'to'
		end

		local amount = x * WARBAND_SIPHON_AMOUNT

		if ut.money_button(
			"Move",
			amount,
			warbands_treasury_control,
			"Move "
			.. ut.to_fixed_point2(math.abs(amount))
			.. MONEY_SYMBOL
			.. " of wealth "
			.. preposition
			.. " warband's treasury."
			.. " Press Ctrl or Shift to modify amount.",
			can_transfer_money
		) then
			economic_effects.gift_to_warband(WORLD.player_character, amount)
		end

		warbands_treasury_control.x = warbands_treasury_control.x + ut.BASE_HEIGHT * 4
	end

	gift_to_treasury_target(-1)
	gift_to_treasury_target(1)

	warbands_treasury_control.x = warbands_treasury_control.x + ut.BASE_HEIGHT * 4

	---comment
	---@param x WarbandIdleStance
	local function set_stance(x)
		if ut.text_button(
			x,
			warbands_treasury_control,
			"Order your party to "
			.. x,
			true,
			WORLD.player_character.leading_warband.idle_stance == x
		) then
			WORLD.player_character.leading_warband.idle_stance = x
		end

		warbands_treasury_control.x = warbands_treasury_control.x + ut.BASE_HEIGHT * 4
	end

	set_stance("work")
	set_stance("forage")

	local warband_hires_panel = bottom:subrect(
		0,
		UI_STYLE.scrollable_list_item_height * 2,
		bottom.width,
		bottom.height - UI_STYLE.scrollable_list_item_height * 2,
		"left",
		"up"
	)

	local province = character.province

	if province == nil then
		return
	end

	---@type table<UnitType, UnitType>
	local unit_types = {}

	for _, unit in pairs(province.unit_types) do
		unit_types[unit] = unit
	end

	for _, unit in pairs(warband.units) do
		unit_types[unit] = unit
	end

	units_scroll = ut.scrollview(
		warband_hires_panel,
		function(number, rect)
			if number > 0 then
				--print(number, ttab.size(tile.province.all_pops))
				---@type UnitType
				local unit, pops = tabb.nth(unit_types, number)
				local possibility = false
				if province.unit_types[unit] then
					possibility = true
				end
				render_unit(rect, unit, warband, possibility)
			end
		end,
		UI_STYLE.scrollable_list_large_item_height,
		tabb.size(unit_types),
		UI_STYLE.slider_width,
		units_scroll
	)
end


return inspector