local ui = require "engine.ui"

local ut = {}


ut.BASE_HEIGHT = 20
ut.BORDER_PADDING = 1
ut.DATA_PADDING = 2

---@class Entry
---@field weight number
---@field tooltip string
---@field r number
---@field g number
---@field b number

---Draws a linear, horizontal graph.
---@param entries table<number, Entry>
---@param rect Rect
function ut.graph(entries, rect)
	local total_weight = 0
	for _, entry in ipairs(entries) do
		---@type number
		total_weight = total_weight + entry.weight
	end
	if total_weight > 0 then
		local orx = rect.x
		local ory = rect.y
		local orw = rect.width
		local cr = ui.style.panel_inside.r
		local cg = ui.style.panel_inside.g
		local cb = ui.style.panel_inside.b
		local weight_thus_far = 0
		for _, entry in ipairs(entries) do
			ui.style.panel_inside.r = entry.r
			ui.style.panel_inside.g = entry.g
			ui.style.panel_inside.b = entry.b
			local current_weight = entry.weight / total_weight
			rect.x = orx + weight_thus_far * orw
			rect.width = orw * current_weight
			ui.panel(rect)
			ui.tooltip(entry.tooltip, rect)
			weight_thus_far = weight_thus_far + current_weight
		end
		rect.x = orx
		rect.y = ory
		rect.width = orw
		ui.style.panel_inside.r = cr
		ui.style.panel_inside.g = cg
		ui.style.panel_inside.b = cb
	end
end

---Draws a number of columns, given a table containing columns with closures to call
---@param columns table<number, fun(rect:Rect)>
---@param rect Rect
---@param column_width number?
---@param spacing number?
function ut.columns(columns, rect, column_width, spacing)
	if spacing == nil then
		spacing = 3
	end
	column_width = column_width or ut.BASE_HEIGHT * 5
	local layout = ui.layout_builder()
		:horizontal()
		:position(rect.x, rect.y)
		:spacing(spacing)
		:build()
	for _, col in ipairs(columns) do
		col(layout:next(column_width, rect.height))
	end
end

---Draws a number of rows, given a table containing rows with closures to call
---@param rows table<number, fun(rect:Rect)>
---@param rect Rect
---@param row_height number?
---@param spacing number?
function ut.rows(rows, rect, row_height, spacing)
	if spacing == nil then
		spacing = 3
	end
	row_height = row_height or ut.BASE_HEIGHT
	local layout = ui.layout_builder()
		:vertical()
		:position(rect.x, rect.y)
		:spacing(spacing)
		:build()
	for _, col in ipairs(rows) do
		col(layout:next(rect.width, row_height))
	end
end

---@enum NumberMode
ut.NUMBER_MODE = {
	MONEY = 1,
	BALANCE = 3,
	NUMBER = 4,
	INTEGER = 5,
	PERCENTAGE = 6,
}

---@enum NameMode
ut.NAME_MODE = {
	NAME = 1,
	ICON = 2,
}

---comment
---@param number number
---@param rect Rect
---@param negative boolean
local function render_money(number, rect, negative)
	local r, g, b, a = require "game.map-modes.political".hsv_to_rgb(51, 1, 1)
	if number < 0 and not negative or number > 0 and negative then
		r, g, b, a = require "game.map-modes.political".hsv_to_rgb(0, 1, 1)
	end
	local cr, cg, cb, ca = love.graphics.getColor()
	love.graphics.setColor(r, g, b, a)
	ut.data_font()
	ui.right_text(ut.to_fixed_point2(number) .. MONEY_SYMBOL, rect)
	ut.main_font()
	love.graphics.setColor(cr, cg, cb, ca)
end


---comment
---@param number number
---@param rect Rect
---@param negative boolean
local function render_balance(number, rect, negative)
	local cr, cg, cb, ca = love.graphics.getColor()

	local h = math.atan(number / 100) / math.pi * 120 + 60
	if negative then
		h = math.atan(-number / 100) / math.pi * 120 + 60
	end

	local r, g, b, a = require "game.map-modes.political".hsv_to_rgb(h, 1, 1)
	love.graphics.setColor(r, g, b, a)
	ut.data_font()
	ui.right_text(ut.to_fixed_point2(number), rect)
	ut.main_font()
	love.graphics.setColor(cr, cg, cb, ca)
end

local function render_percentage(number, rect, negative)
	local hue = math.min(number * 120, 359)
	if negative then
		hue = math.max(0, 120 - number * 120)
	end

	local r, g, b, a = require "game.map-modes.political".hsv_to_rgb(hue, 1, 1)
	local cr, cg, cb, ca = love.graphics.getColor()
	love.graphics.setColor(r, g, b, a)
	ut.data_font()
	ui.right_text( tostring(math.floor(number * 100 + 0.5)) .. '%', rect)
	ut.main_font()
	love.graphics.setColor(cr, cg, cb, ca)
end

---comment
---@param name_or_icon string
---@param data number
---@param rect Rect
---@param tooltip string?
---@param mode NumberMode
---@param name_mode NameMode
---@param negative boolean?
---@param panel boolean?
function ut.generic_number_field(name_or_icon, data, rect, tooltip, mode, name_mode, negative, panel)
	if panel == nil then
		panel = true
	end
	if negative == nil then
		negative = false
	end

	-- padded border
	rect = rect:copy():shrink(ut.BORDER_PADDING)
	if panel then
		ui.panel(rect, 3)
	end

	-- padded data
	rect = rect:copy():shrink(ut.DATA_PADDING)

	-- name or icon
	if name_mode == ut.NAME_MODE.NAME then
		ui.left_text(name_or_icon, rect)
	elseif name_mode == ut.NAME_MODE.ICON then
		local icon_rect = rect:subrect(0, 0, rect.height, rect.height, "left", 'center')
		ui.image(ASSETS.icons[name_or_icon], icon_rect)
	end

	-- data
	if mode == ut.NUMBER_MODE.MONEY then
		render_money(data, rect, negative)
	elseif mode == ut.NUMBER_MODE.BALANCE then
		render_balance(data, rect, negative)
	elseif mode == ut.NUMBER_MODE.NUMBER then
		ut.data_font()
		ui.right_text(ut.to_fixed_point2(data), rect)
		ut.main_font()
	elseif mode == ut.NUMBER_MODE.INTEGER then
		ut.data_font()
		ui.right_text(tostring(data), rect)
		ut.main_font()
	elseif mode == ut.NUMBER_MODE.PERCENTAGE then
		render_percentage(data, rect, negative)
	end

	-- tooltip
	if tooltip then
		ui.tooltip(tooltip, rect)
	end
end

---comment
---@param name_or_icon string
---@param data string
---@param rect Rect
---@param tooltip string?
---@param name_mode NameMode
---@param panel boolean?
---@param alignment 'left' | 'right' | nil
function ut.generic_string_field(name_or_icon, data, rect, tooltip, name_mode, panel, alignment)
	if alignment == nil then
		alignment = 'right'
	end

	if panel == nil then
		panel = true
	end

	rect = rect:copy():shrink(ut.BORDER_PADDING)
	if panel then
		ui.panel(rect, 3)
	end
	rect = rect:shrink(ut.DATA_PADDING)

	if name_mode == ut.NAME_MODE.NAME then
		ui.left_text(name_or_icon, rect)
	elseif name_mode == ut.NAME_MODE.ICON then
		local icon_rect = rect:subrect(0, 0, rect.height, rect.height, "left", 'center')
		ui.image(ASSETS.icons[name_or_icon], icon_rect)
	end

	ut.data_font()
	if alignment == 'right' then
		ui.right_text(data, rect)
	else
		rect.x = rect.x + rect.height + 5
		ui.left_text(data, rect)
		rect.x = rect.x - rect.height - 5
	end
	ut.main_font()

	if tooltip then
		ui.tooltip(tooltip, rect)
	end
end


---Draws a data field
---@param name string
---@param data string
---@param rect Rect
---@param tooltip string?
---@param panel boolean?
---@param alignment 'left' | 'right' | nil
function ut.data_entry(name, data, rect, tooltip, panel, alignment)
	if alignment == nil then
		alignment = 'right'
	end
	ut.generic_string_field(name, data, rect, tooltip, ut.NAME_MODE.NAME, panel, alignment)	
end

---Draws a data field with icon
---@param icon string
---@param data string
---@param rect Rect
---@param tooltip string?
---@param panel boolean?
---@param alignment 'left' | 'right' | nil
function ut.data_entry_icon(icon, data, rect, tooltip, panel, alignment)
	if alignment == nil then
		alignment = 'right'
	end
	ut.generic_string_field(icon, data, rect, tooltip, ut.NAME_MODE.ICON, panel, alignment)
end

---@param name string
---@param data number
---@param rect Rect
---@param tooltip string?
---@param negative boolean?
---@param panel boolean?
function ut.money_entry(name, data, rect, tooltip, negative, panel)
	ut.generic_number_field(name, data, rect, tooltip, ut.NUMBER_MODE.MONEY, ut.NAME_MODE.NAME, negative, panel)
end

---@param name string
---@param data number
---@param rect Rect
---@param tooltip string?
---@param negative boolean?
---@param panel boolean?
function ut.count_entry(name, data, rect, tooltip, negative, panel)
	ut.generic_number_field(name, data, rect, tooltip, ut.NUMBER_MODE.NUMBER, ut.NAME_MODE.NAME, negative, panel)
end

---@param name string
---@param data number
---@param rect Rect
---@param tooltip string?
---@param negative boolean?
---@param panel boolean?
function ut.integer_entry(name, data, rect, tooltip, negative, panel)
	ut.generic_number_field(name, data, rect, tooltip, ut.NUMBER_MODE.INTEGER, ut.NAME_MODE.NAME, negative, panel)
end

---@param name string
---@param data number
---@param rect Rect
---@param tooltip string?
---@param negative boolean?
---@param panel boolean?
function ut.balance_entry(name, data, rect, tooltip, negative, panel)
	ut.generic_number_field(name, data, rect, tooltip, ut.NUMBER_MODE.BALANCE, ut.NAME_MODE.NAME, negative, panel)
end

---Draws a money field with icon
---@param data number
---@param rect Rect
---@param tooltip string
---@param negative boolean?
---@param panel boolean?
function ut.money_entry_icon(data, rect, tooltip, negative, panel)
	ut.generic_number_field('coins.png', data, rect, tooltip, ut.NUMBER_MODE.MONEY, ut.NAME_MODE.ICON, negative, panel)
end

---Draws a data field
---@param name string
---@param data number ratio
---@param rect Rect
---@param tooltip string?
---@param positive boolean? Is big number good?
---@param panel boolean?
function ut.data_entry_percentage(name, data, rect, tooltip, positive, panel)
	if positive == nil then
		positive = true
	end
	ut.generic_number_field(name, data, rect, tooltip, ut.NUMBER_MODE.PERCENTAGE, ut.NAME_MODE.NAME, not positive, panel)
end

---Renders a color coded percentage
---@param value number
---@param rect Rect
---@param positive boolean?
---@param tooltip string?
---@param panel boolean?
function ut.color_coded_percentage(value, rect, positive, tooltip, panel)
	if positive == nil then
		positive = true
	end
	ut.generic_number_field("", value, rect, tooltip, ut.NUMBER_MODE.PERCENTAGE, ut.NAME_MODE.NAME, not positive, panel)
end


function ut.reload_font()
	-- ASSETS.main_font = love.graphics.newFont("data/fonts/Pelagiad.ttf", ui.font_size(12))
	-- ASSETS.data_font = love.graphics.newFont("data/fonts/CenturyGothic.ttf", ui.font_size(14))
	ASSETS.main_font = love.graphics.newFont("data/fonts/main-font.otf", ui.font_size(12))
	ASSETS.data_font = love.graphics.newFont("data/fonts/main-font.otf", ui.font_size(12))
	love.graphics.setFont(ASSETS.main_font)
end

function ut.data_font()
	love.graphics.setFont(ASSETS.data_font)
end

function ut.main_font()
	love.graphics.setFont(ASSETS.main_font)
end

function ut.set_font(font)
	love.graphics.setFont(font)
end

---Draws a coat of arms of a realm. Returns true if clicked.
---@param realm Realm
---@param rect Rect
function ut.coa(realm, rect)
	-- Pull old colors...
	local r = ui.style.panel_inside.r
	local g = ui.style.panel_inside.g
	local b = ui.style.panel_inside.b
	local a = ui.style.panel_inside.a
	ui.style.panel_inside.a = 1
	-- Base
	ui.style.panel_inside.r = realm.coa_base_r
	ui.style.panel_inside.g = realm.coa_base_g
	ui.style.panel_inside.b = realm.coa_base_b
	ui.panel(rect)
	-- Background
	love.graphics.setColor(realm.coa_background_r, realm.coa_background_g, realm.coa_background_b, 1)
	ui.image(ASSETS.coas[realm.coa_background_image], rect)
	-- Foreground
	love.graphics.setColor(realm.coa_foreground_r, realm.coa_foreground_g, realm.coa_foreground_b, 1)
	ui.image(ASSETS.coas[realm.coa_foreground_image], rect)
	-- Emblem
	if realm.coa_emblem_image ~= 0 then
		love.graphics.setColor(realm.coa_emblem_r, realm.coa_emblem_g, realm.coa_emblem_b, 1)
		ui.image(ASSETS.emblems[realm.coa_emblem_image], rect)
	end
	local rr = ui.invisible_button(rect)
	-- Write colors back...
	ui.style.panel_inside.r = r
	ui.style.panel_inside.g = g
	ui.style.panel_inside.b = b
	ui.style.panel_inside.a = a
	love.graphics.setColor(1, 1, 1, 1)
	return rr
end

ut.months = {
	'January',
	'February',
	'March',
	'April',
	'May',
	'June',
	'July',
	'August',
	'September',
	'October',
	'November',
	'December'
}

local gold_color = {
	['r'] = 1,
	['g'] = 0.87,
	['b'] = 0,
	['a'] = 1
}

local dark_yellow = {
	['r'] = 0.5,
	['g'] = 0.4,
	['b'] = 0,
	['a'] = 1
}

local black_color = {
	['r'] = 0,
	['g'] = 0,
	['b'] = 0,
	['a'] = 1
}

local blue_color = {
	['r'] = 0.5,
	['g'] = 0.5,
	['b'] = 1,
	['a'] = 1
}

local silver_color = {
	['r'] = 0.87,
	['g'] = 0.87,
	['b'] = 0.87,
	['a'] = 1
}

local dark_grey_color = {
	['r'] = 0.2,
	['g'] = 0.2,
	['b'] = 0.2,
	['a'] = 1
}

local dark_green_color = {
	['r'] = 56 / 255,
	['g'] = 70 / 255,
	['b'] = 56 / 255,
	['a'] = 1
}

local dark_blue_color = {
	['r'] = 29 / 255,
	['g'] = 53 / 255,
	['b'] = 92 / 255,
	['a'] = 1
}

local light_lime_color = {
	['r'] = 0.5,
	['g'] = 1,
	['b'] = 0.5,
	['a'] = 1
}

---Renders button border / background depending on potential and active, returns button result and Rect to draw some data inside
---@param rect Rect
---@param potential boolean can you take this action?
---@param active boolean?
---@param sound string? The sound to be played by this button. Leave blank to play a default sound.
---@return boolean, Rect
function ut.button(rect, potential, active, sound)
	-- handle logic part immediately to avoid gaps between buttons
	local hover, clicked = ui.hover_clicking_status(rect)
	local result = ui.invisible_button(rect) and potential
	local sound = sound or "menu_click.wav"
	hover = hover and potential
	clicked = clicked and potential

	rect = rect:copy():shrink(1)

	local old_style = ui.style.panel_outline
	local old_style_inside = ui.style.panel_inside
	local old_style_button_inside = ui.style.button_inside
	local old_style_button_hovered = ui.style.button_hovered
	local old_style_button_clicked = ui.style.button_clicked

	-- outer border
	ui.style.panel_outline = dark_yellow
	if not potential then
		ui.style.panel_outline = dark_grey_color
	end
	ui.panel(rect, 1, true, false)

	-- inner border
	rect = rect:shrink(1)
	ui.style.panel_inside = black_color
	ui.panel(rect, 1, false, true)

	-- inner background
	ui.style['button_inside'] = dark_blue_color --dark_green_color
	ui.style['button_hovered'] = blue_color
	ui.style['button_clicked'] = light_lime_color

	if not potential then
		ui.style['button_inside'] = dark_grey_color
		ui.style['button_hovered'] = dark_grey_color
		ui.style['button_clicked'] = dark_grey_color
	end

	rect = rect:shrink(1)
	ui.style.panel_inside = dark_blue_color -- dark_green_color
	if not potential then
		ui.style.panel_inside = dark_grey_color
	end

	-- button background
	ui.dummy_button_panel(rect, 1, false, hover, clicked)

	-- overlay for active buttons
	if active then
		ui.style.panel_inside = dark_green_color
		ui.style.panel_outline = dark_green_color
		-- ui.panel(rect, math.min(rect.height, rect.width), false)
		ui.panel(rect, 1, false)
	end


	ui.style.panel_outline = old_style
	ui.style.panel_inside = old_style_inside
	ui.style.button_inside = old_style_button_inside
	ui.style.button_hovered = old_style_button_hovered
	ui.style.button_clicked = old_style_button_clicked

	-- play audio
	if result then
		print(sound)
		love.audio.play(ASSETS.sfx[sound])
	end
	return result, rect
end

---comment
---@param icon love.Image
---@param rect Rect
---@param tooltip string?
---@param potential boolean?
---@param active boolean?
function ut.icon_button(icon, rect, tooltip, potential, active)
	if potential == nil then
		potential = true
	end

	local result, rect_icon = ut.button(rect, potential, active)

	ui.image(icon, rect_icon)
	if tooltip then
		ui.tooltip(tooltip, rect)
	end

	return result
end


---comment
---@param text string
---@param rect Rect
---@param tooltip string?
---@param potential boolean?
---@param active boolean?
function ut.text_button(text, rect, tooltip, potential, active)
	if potential == nil then
		potential = true
	end

	local result, rect_text = ut.button(rect, potential, active)

	ui.centered_text(text, rect_text)

	if tooltip then
		ui.tooltip(tooltip, rect)
	end

	return result
end


---Draws the calendar and returns whether or not the mouse if over it
---@param gam table
---@return boolean
function ut.calendar(gam)
	gam.speed = gam.speed or 1

	local rx, ry = ui.get_reference_screen_dimensions()
	local hor = ui.layout_builder()
		:horizontal(true)
		:position(rx, 0)
		:build()
	local main = hor:next(ut.BASE_HEIGHT * 12, ut.BASE_HEIGHT)
	ui.panel(main)
	local www = (require "game.entities.world").ticks_per_hour
	local sht = WORLD.sub_hourly_tick
	local minutes = math.floor(sht / www * 60)
	local seconds = math.floor(sht / www * 60 * 60) % 60
	main.x = main.x - 5 -- shift it slightly so that the numbers dont touch the edge of the screen...
	ui.right_text(tostring(WORLD.hour) ..
		' : ' .. tostring(minutes) .. ' : ' .. tostring(seconds) .. ' -- ' ..
		tostring(WORLD.day) .. '.' .. ut.months[WORLD.month + 1] .. '.' .. tostring(WORLD.year), main)
	main.x = main.x + 5 -- move it back so that the trigger isnt broken

	local main_button = hor:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT)
	if gam.paused ~= nil and not gam.paused then
		-- the game is unpaused
		if ut.icon_button(ASSETS.icons['pause-button.png'], main_button, "Pause") then
			gam.paused = true
		end
	else
		-- the game is paused
		if ut.icon_button(ASSETS.icons['play-button.png'], main_button, "Unpause") then
			gam.paused = false
		end
	end
	-- Hotkeys for calendar
	if ui.is_key_pressed("space") then
		gam.paused = not gam.paused
	end
	local speed_up = hor:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT)
	local speed = hor:next(ut.BASE_HEIGHT * 2, ut.BASE_HEIGHT)
	local speed_down = hor:next(ut.BASE_HEIGHT, ut.BASE_HEIGHT)
	if ut.icon_button(ASSETS.icons['fast-forward-button.png'], speed_up, "Speed up") or ui.is_key_pressed("+") or
		ui.is_key_pressed("kp+") then
		gam.speed = math.min(10, gam.speed + 1)
	end
	ui.panel(speed)
	ui.centered_text(tostring(gam.speed) .. " / 10", speed)
	ui.tooltip("Game speed", speed)
	if ut.icon_button(ASSETS.icons['fast-backward-button.png'], speed_down, "Slown down") or ui.is_key_pressed("-") or
		ui.is_key_pressed("kp-") then
		gam.speed = math.max(1, gam.speed - 1)
	end

	return ui.trigger(main) or ui.trigger(main_button) or ui.trigger(speed_up) or ui.trigger(speed) or
		ui.trigger(speed_down)
end

---@class Tab
---@field text string
---@field tooltip string
---@field closure fun()
---@field on_select fun()|nil

---Used for drawing tabs.
---@param current_tab string the currently selected tab
---@param layout Layout A layout for placing tabs
---@param tabs table<number, Tab> a table with tabs
---@param scale number
---@param width_tab_header number?
---@return string new_tab
function ut.tabs(current_tab, layout, tabs, scale, width_tab_header)
	if width_tab_header == nil then
		width_tab_header = ut.BASE_HEIGHT * 2
	end
	local new_tab = current_tab
	for _, tab in pairs(tabs) do
		local rect = layout:next(width_tab_header * scale, ut.BASE_HEIGHT * scale)
		if current_tab == tab.text then
			ut.text_button(tab.text, rect, tab.tooltip, false, true)
			tab.closure()
		else
			if ut.text_button(tab.text, rect, tab.tooltip) then
				new_tab = tab.text
				if tab.on_select then
					tab.on_select()
				end
			end
		end
	end
	return new_tab
end

function ut.to_fixed_point2(x)
	local temp = math.abs(x)
	local sign = ''
	if x < 0 then
		sign = '-'
	end
	local frac_1 = math.floor((temp - math.floor(temp)) * 10)
	local frac_2 = math.floor((temp * 10 - math.floor(temp * 10)) * 10)
	return sign .. tostring(math.floor(temp)) .. '.' .. frac_1 .. frac_2
end

return ut
