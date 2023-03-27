local ui = {}

-- #######################
-- ### DEFAULT STYLING ###
-- #######################

ui.style = {
	['reset_color'] = {
		['r'] = 1,
		['g'] = 1,
		['b'] = 1,
		['a'] = 1
	},
	['panel_outline'] = {
		['r'] = 0,
		['g'] = 0,
		['b'] = 0,
		['a'] = 0.85
	},
	['panel_inside'] = {
		['r'] = 0.1,
		['g'] = 0.1,
		['b'] = 0.1,
		['a'] = 0.75
	},
	['button_outline'] = {
		['r'] = 0,
		['g'] = 0,
		['b'] = 0,
		['a'] = 1
	},
	['button_inside'] = {
		['r'] = 0.2,
		['g'] = 0.2,
		['b'] = 0.2,
		['a'] = 1
	},
	['button_hovered'] = {
		['r'] = 0.3,
		['g'] = 0.3,
		['b'] = 0.5,
		['a'] = 1
	},
	['button_clicked'] = {
		['r'] = 0.5,
		['g'] = 0.3,
		['b'] = 0.3,
		['a'] = 1
	},
	['slider_filled'] = {
		['r'] = 0.75,
		['g'] = 0.75,
		['b'] = 0.75,
		['a'] = 1
	}
}

-- ##############
-- ### TABLES ###
-- ##############

local pressed_keys = {}
local held_keys = {}
local released_keys = {}
local mouse_press_positions = {} -- stores the position of the mouse then the press was registered!
local pressed_mouse = {}
local held_mouse = {}
local released_mouse = {}
local mouse_position = {}
local mouse_wheel_movement = 0
local tooltip_text = nil
local tooltip_x = 0
local tooltip_y = 0

---Returns a copy of the input state. Use it to implement hot loading.
---@return table
function ui.cache_input_state()
	local r = {}

	r.pressed_keys = pressed_keys
	r.held_keys = held_keys
	r.released_keys = released_keys
	r.mouse_press_positions = mouse_press_positions
	r.pressed_mouse = pressed_mouse
	r.held_mouse = held_mouse
	r.released_mouse = released_mouse
	r.mouse_position = mouse_position
	r.mouse_wheel_movement = mouse_wheel_movement

	return r
end

---Loads input state from a cache table -- used for hot loading
---@param cache any
function ui.load_input_state_from_cache(cache)
	pressed_keys = cache.pressed_keys
	held_keys = cache.held_keys
	released_keys = cache.released_keys
	mouse_press_positions = cache.mouse_press_positions
	pressed_mouse = cache.pressed_mouse
	held_mouse = cache.held_mouse
	released_mouse = cache.released_mouse
	mouse_position = cache.mouse_position
	mouse_wheel_movement = cache.mouse_wheel_movement
end

---Clears a table without allocating a new one
---@param table_to_clear table
local function clear_table(table_to_clear)
	for k, v in pairs(table_to_clear) do
		table_to_clear[k] = nil
	end
end

-- #########################
-- ### SCALING UTILITIES ###
-- #########################

-- Variables we'll use to "renormalize" UI coordinates.
-- This way it'll be easier to make UI that adapts to various screen displays.
local reference_width = 1280
local reference_height = 720

---Returns reference screen dimensions, if they're needed for any reason.
---@return number reference_width
---@return number reference_height
function ui.get_reference_screen_dimensions()
	return reference_width, reference_height
end

---Changes reference width and height. Use it if you're targetting screens with different aspect ratio than 16:9
---@param new_width number
---@param new_height number
function ui.set_reference_screen_dimensions(new_width, new_height)
	reference_width = new_width
	reference_height = new_height
end

---Returns scaling factors that transform froms reference space to screen space that can be used with Love's draw functions.
---@return number scale_x
---@return number scale_y
local function get_ui_scaling_factor()
	local dims_x, dims_y = love.graphics.getDimensions()
	local scale_x = dims_x / reference_width
	local scale_y = dims_y / reference_height
	return scale_x, scale_y
end

--- Given a target font size returns the equivalent font size for the reference screen
--- Use this to normalize font size across different screen resolutions.
---@param target_font_size number
---@return number font_size
function ui.font_size(target_font_size)
	local _, dims_y = love.graphics.getDimensions()
	return dims_y / reference_height * target_font_size
end

-- ############
-- ### RECT ###
-- ############

---@class Rect
---@field x number
---@field y number
---@field width number
---@field height number
local Rect = {}
Rect.__index = Rect
---Creates and returns a new rect
---@param x number
---@param y number
---@param width number
---@param height number
---@return Rect
function Rect:new(x, y, width, height)
	local rect = {
		['x'] = x,
		['y'] = y,
		['width'] = width,
		['height'] = height,
	}
	setmetatable(rect, self)
	return rect
end

---Shrinks this rect by the shrink amount
---@param shrink_amount number
---@return Rect self
function Rect:shrink(shrink_amount)
	self.x = self.x + shrink_amount
	self.y = self.y + shrink_amount
	self.width = self.width - 2 * shrink_amount
	self.height = self.height - 2 * shrink_amount
	return self
end

---Returns a copy of this rect, as a new object
---@return Rect copy
function Rect:copy()
	return Rect:new(self.x, self.y, self.width, self.height)
end

---Returns a new rect, using this rect as the new reference point.
---@param x number
---@param y number
---@param width number
---@param height number
---@param horizontal_align love.AlignMode
---@param vertical_align VerticalAlignMode
function Rect:subrect(x, y, width, height, horizontal_align, vertical_align)
	local ll = Rect:new(self.x + x, self.y + y, width, height)

	if horizontal_align == "left" then
		-- nothing to do
	elseif horizontal_align == "right" then
		-- move us to the right edge
		ll.x = ll.x + self.width - ll.width
	elseif horizontal_align == "center" then
		ll.x = ll.x + self.width / 2 - ll.width / 2
	else
		error("Unknown horizontal align mode: " .. tostring(horizontal_align))
	end

	if vertical_align == "up" then
		-- nothing to do
	elseif vertical_align == "down" then
		-- move us to the right edge
		ll.y = ll.y + self.height - ll.height
	elseif vertical_align == "center" then
		ll.y = ll.y + self.height / 2 - ll.height / 2
	else
		error("Unknown vertical align mode: " .. tostring(vertical_align))
	end

	return ll
end

---Returns x/y position, width and height for rect rendering for a given rect
---@return number x
---@return number y
---@return number width
---@return number height
function Rect:get_love_render_position()
	local x = self.x
	local y = self.y
	local width = self.width
	local height = self.height
	local scale_x, scale_y = get_ui_scaling_factor()
	return x * scale_x, y * scale_y, width * scale_x, height * scale_y
end

---Creates and returns a new rect
---@param x number
---@param y number
---@param width number
---@param height number
---@return Rect
function ui.rect(x, y, width, height)
	return Rect:new(x, y, width, height)
end

--- Returns x, y, width and height of a widget that covers the entire screen
---@return Rect rect
function ui.fullscreen()
	return Rect:new(0, 0, reference_width, reference_height)
end

-- #####################
-- ### UI PRIMITIVES ###
-- #####################

--- Draws a single UI image at x/y coordinates and with a given width and height
---@param image love.Image
---@param rect Rect
function ui.image(image, rect)
	local x = rect.x
	local y = rect.y
	local width = rect.width
	local height = rect.height
	-- Pull data
	local image_width = image:getWidth()
	local image_height = image:getHeight()
	local dims_x, dims_y = love.graphics.getDimensions()

	-- Calculate "scaling" factor for width and height
	local fill_x = width / reference_width
	local fill_y = height / reference_height
	local target_x = image_width / dims_x
	local target_y = image_height / dims_y
	local scale_x = fill_x / target_x
	local scale_y = fill_y / target_y

	-- Calculate "proper" x and y positions
	local position_fraction_x = x / reference_width
	local position_fraction_y = y / reference_height

	love.graphics.draw(image, dims_x * position_fraction_x, dims_y * position_fraction_y, 0, scale_x, scale_y)
end

---@alias VerticalAlignMode 'up' | 'center' | 'down'
--- Draws text at x/y coordinates in a given width/height quad.
--- Texts first line will be centered vertically.
---@param text string
---@param rect Rect
---@param horizontal_align love.AlignMode
---@param vertical_align VerticalAlignMode
function ui.text(text, rect, horizontal_align, vertical_align)
	local x = rect.x
	local y = rect.y
	local width = rect.width
	local height = rect.height
	horizontal_align = horizontal_align or "center"
	vertical_align = vertical_align or "center"
	local scale_x, scale_y = get_ui_scaling_factor()

	local font = love.graphics.getFont()
	local text_height = font:getHeight()

	local max_width = width * scale_x
	local _, lines = font:getWrap(text, max_width)
	local line_count = #lines
	text_height = text_height * line_count

	-- vertical pivot
	local pivot_y = 0
	if vertical_align == 'up' then
		pivot_y = 0
	elseif vertical_align == 'center' then
		pivot_y = 0.5
	elseif vertical_align == 'down' then
		pivot_y = 1.0
	else
		error('Uknown vertical align mode: ' ..
			tostring(vertical_align) .. ", only 'up', 'center' and 'down' are allowed values")
	end

	local pos_x = (x + width / 2) * scale_x
	local pos_y = (y + height * pivot_y) * scale_y
	love.graphics.printf(text, x * scale_x, pos_y - text_height * pivot_y, max_width, horizontal_align)
end

---Returns a boolean for whether or not the mouse is within a rect
---@param rect Rect
---@return boolean mouse_in_rect
function ui.trigger(rect)
	local x = rect.x
	local y = rect.y
	local width = rect.width
	local height = rect.height
	local mx, my = ui.mouse_position()
	return mx > x and
		mx < x + width and
		my > y and
		my < y + height
end

---Returns a boolean for whether or not a mouse click was started within a rect
---@param rect Rect
---@param button number 1 - primary, 2 - secondary, 3 - middle
---@return boolean mouse_in_rect
function ui.trigger_press(rect, button)
	local x = rect.x
	local y = rect.y
	local width = rect.width
	local height = rect.height
	local mx, my = ui.mouse_press_position(button)
	if mx ~= nil then
		return mx > x and
			mx < x + width and
			my > y and
			my < y + height
	else
		return false
	end
end

---Draws a filled rectangle using love.graphics.rectangle
---@param rect Rect
function ui.rectangle(rect)
	local x = rect.x
	local y = rect.y
	local width = rect.width
	local height = rect.height
	local scale_x, scale_y = get_ui_scaling_factor()
	love.graphics.rectangle(
		"fill",
		x * scale_x,
		y * scale_y,
		width * scale_x,
		height * scale_y
	)
end

---Draws an outline using love.graphics.rectangle
---@param rect Rect
function ui.outline(rect)
	local x = rect.x
	local y = rect.y
	local width = rect.width
	local height = rect.height
	local scale_x, scale_y = get_ui_scaling_factor()
	love.graphics.rectangle(
		"line",
		x * scale_x,
		y * scale_y,
		width * scale_x,
		height * scale_y
	)
end

-- #################
-- ### CALLBACKS ###
-- #################

---Call this at the end of any frame. It clears key and mouse button states.
function ui.finalize_frame()
	ui.draw_tooltip()

	clear_table(pressed_keys)
	for k, v in pairs(released_keys) do
		held_keys[k] = nil
	end
	clear_table(released_keys)

	clear_table(pressed_mouse)
	for k, v in pairs(released_mouse) do
		held_mouse[k] = nil
		mouse_press_positions[k] = nil
	end
	clear_table(released_mouse)

	mouse_wheel_movement = 0
end

---Call this in love.keypressed
---@param key love.KeyConstant
function ui.on_keypressed(key)
	pressed_keys[key] = true
	held_keys[key] = true
end

---Call this in love.keyreleased
---@param key love.KeyConstant
function ui.on_keyreleased(key)
	released_keys[key] = true
end

---Call this in love.mousepressed
function ui.on_mousepressed(x, y, button, istouch, presses)
	pressed_mouse[button] = true
	held_mouse[button] = true
	mouse_press_positions[button] = { x, y }
end

---Call this in love.mousereleased
function ui.on_mousereleased(x, y, button, istouch, presses)
	released_mouse[button] = true
end

---Call this in love.mousemoved
function ui.on_mousemoved(x, y, dx, dy, istouch)
	mouse_position.x = x
	mouse_position.y = y
end

---Call this in love.wheelmoved
function ui.on_wheelmoved(x, y)
	mouse_wheel_movement = mouse_wheel_movement + y
end

-- #################################
-- ### INPUT RETRIEVAL FUNCTIONS ###
-- #################################

---Returns true if key has just been pressed
---@param key love.KeyConstant
---@return boolean
function ui.is_key_pressed(key)
	return pressed_keys[key] == true
end

---Returns true if key is currently being held down
---@param key love.KeyConstant
---@return boolean
function ui.is_key_held(key)
	return held_keys[key] == true
end

---Returns true if key has just been released
---@param key love.KeyConstant
---@return boolean
function ui.is_key_released(key)
	return released_keys[key] == true
end

---Returns true if a mouse button has just been pressed
---@param button number 1 - primary, 2 - secondary, 3 - middle
---@return boolean
function ui.is_mouse_pressed(button)
	return pressed_mouse[button] == true
end

---Returns true if a mouse button is currently being held down
---@param button number 1 - primary, 2 - secondary, 3 - middle
---@return boolean
function ui.is_mouse_held(button)
	return held_mouse[button] == true
end

---Returns true if a mouse button has just been released
---@param button number 1 - primary, 2 - secondary, 3 - middle
---@return boolean
function ui.is_mouse_released(button)
	return released_mouse[button] == true
end

---Returns position of the mouse, using reference width and reference height
function ui.mouse_position()
	local x = mouse_position.x or 0
	local y = mouse_position.y or 0

	local scale_x, scale_y = get_ui_scaling_factor()

	return x / scale_x, y / scale_y
end

---Returns y-axis of mouse wheel movement. Positive for scrolling up, negative for scrolling down.
function ui.mouse_wheel()
	return mouse_wheel_movement
end

---Returns position of a mouse click (if it was clicked)
---Use this for finer control over UI primitives.
---@param button number 1 - primary, 2 - secondary, 3 - middle
---@return number | nil
---@return number | nil
function ui.mouse_press_position(button)
	if mouse_press_positions[button] ~= nil then
		local x = mouse_press_positions[button][1]
		local y = mouse_press_positions[button][2]

		local scale_x, scale_y = get_ui_scaling_factor()

		return x / scale_x, y / scale_y
	else
		return nil, nil
	end
end

-- ###############
-- ### LAYOUTS ###
-- ###############

---@class Layout
---@field _position_x number
---@field _position_y number
---@field _pivot_x number
---@field _pivot_y number
---@field _spacing number
---@field _layout_type string
---@field _pivot_type string
---@field _entries_per_row number
---@field _entries_in_row number
---@field next fun(self:Layout,width:number,height:number):Rect
local Layout = {}
Layout.__index = Layout
function Layout:new()
	local layout = {}
	layout._layout_type = "horizontal-left"
	layout._pivot_type = "normal"
	layout._spacing = 0
	layout._position_x = 0
	layout._position_y = 0
	layout._pivot_x = 0
	layout._pivot_y = 0
	layout._entries_per_row = 1
	layout._entries_in_row = 0
	setmetatable(layout, self)
	return layout
end

---Returns the next rect in the layout
---@param width number
---@param height number
---@return Rect rect
function Layout:next(width, height)
	local x = self._position_x + self._pivot_x
	local y = self._position_y + self._pivot_y

	if self._layout_type == "horizontal-right" then
		self._pivot_x = self._pivot_x + width + self._spacing
		if self._pivot_type == "normal" then
			-- nothing to do here
		elseif self._pivot_type == "flipped" then
			y = y - height
		elseif self._pivot_type == "centered" then
			y = y - height / 2.0
		else
			error("Unknown pivot type: " .. tostring(self._pivot_type))
		end
	elseif self._layout_type == "horizontal-left" then
		self._pivot_x = self._pivot_x - width - self._spacing
		x = x - width
		if self._pivot_type == "normal" then
			-- nothing to do here
		elseif self._pivot_type == "flipped" then
			y = y - height
		elseif self._pivot_type == "centered" then
			y = y - height / 2.0
		else
			error("Unknown pivot type: " .. tostring(self._pivot_type))
		end
	elseif self._layout_type == "vertical-up" then
		self._pivot_y = self._pivot_y - height - self._spacing
		y = y - height
		if self._pivot_type == "normal" then
			-- nothing to do here
		elseif self._pivot_type == "flipped" then
			x = x - width
		elseif self._pivot_type == "centered" then
			x = x - width / 2.0
		else
			error("Unknown pivot type: " .. tostring(self._pivot_type))
		end
	elseif self._layout_type == "vertical-down" then
		self._pivot_y = self._pivot_y + height + self._spacing
		if self._pivot_type == "normal" then
			-- nothing to do here
		elseif self._pivot_type == "flipped" then
			x = x - width
		elseif self._pivot_type == "centered" then
			x = x - width / 2.0
		else
			error("Unknown pivot type: " .. tostring(self._pivot_type))
		end
	elseif self._layout_type == "grid" then
		self._entries_in_row = self._entries_in_row + 1
		if self._entries_in_row == self._entries_per_row then
			self._entries_in_row = 0
			self._pivot_x = 0
			self._pivot_y = self._pivot_y + height + self._spacing
		else
			self._pivot_x = self._pivot_x + width + self._spacing
		end
	else
		error("Unknown layout type: " .. tostring(self._layout_type))
	end

	return Rect:new(x, y, width, height)
end

---@class LayoutBuilder
---@field new fun():LayoutBuilder
---@field position fun(self:LayoutBuilder,x:number,y:number):LayoutBuilder
---@field spacing fun(self:LayoutBuilder,space:number):LayoutBuilder
---@field horizontal fun(self:LayoutBuilder,left:boolean|nil):LayoutBuilder
---@field vertical fun(self:LayoutBuilder,up:boolean|nil):LayoutBuilder
---@field grid fun(self:LayoutBuilder,entries_per_row:number):LayoutBuilder
---@field flipped fun():LayoutBuilder
---@field centered fun():LayoutBuilder
---@field build fun():Layout
local LayoutBuilder = {}
LayoutBuilder.__index = LayoutBuilder
function LayoutBuilder:new()
	local lb = {}
	lb._x = 0
	lb._y = 0
	lb._spacing = 0
	lb._layout_type = "horizontal-right"
	lb._pivot_type = "normal"
	lb._entries_per_row = 1 -- used by grids
	setmetatable(lb, self)
	return lb
end

---@param x number
---@param y number
---@return LayoutBuilder
function LayoutBuilder:position(x, y)
	self._x = x
	self._y = y
	return self
end

---@param spacing number
---@return LayoutBuilder
function LayoutBuilder:spacing(spacing)
	self._spacing = spacing
	return self
end

---@param left ?boolean
---@return LayoutBuilder
function LayoutBuilder:horizontal(left)
	if left then
		self._layout_type = "horizontal-left"
	else
		self._layout_type = "horizontal-right"
	end
	return self
end

---@param up ?boolean
---@return LayoutBuilder
function LayoutBuilder:vertical(up)
	if up then
		self._layout_type = "vertical-up"
	else
		self._layout_type = "vertical-down"
	end
	return self
end

---@param entries_per_row number
---@return LayoutBuilder
function LayoutBuilder:grid(entries_per_row)
	entries_per_row = entries_per_row or 1
	self._entries_per_row = entries_per_row
	self._layout_type = "grid"
	return self
end

---@return LayoutBuilder
function LayoutBuilder:flipped()
	self._pivot_type = "flipped"
	return self
end

---@return LayoutBuilder
function LayoutBuilder:centered()
	self._pivot_type = "centered"
	return self
end

---@return Layout
function LayoutBuilder:build()
	local layout = Layout:new()
	layout._layout_type = self._layout_type
	layout._pivot_type = self._pivot_type
	layout._spacing = self._spacing
	layout._position_x = self._x
	layout._position_y = self._y
	layout._entries_per_row = self._entries_per_row
	return layout
end

---Returns the layout builder
---@return LayoutBuilder
function ui.layout_builder()
	return LayoutBuilder:new()
end

-- ##############################
-- ### READY-TO-US UI WIDGETS ###
-- ##############################

---Given a table with r/g/b/a values, set the love graphics color
---@param tab any
local function set_color(tab)
	love.graphics.setColor(
		tab.r,
		tab.g,
		tab.b,
		tab.a
	)
end

---Renders a panel, using the default style
---@param rect Rect
function ui.panel(rect)
	set_color(ui.style.panel_inside)
	ui.rectangle(rect)
	set_color(ui.style.panel_outline)
	ui.outline(rect)
	set_color(ui.style.reset_color)
end

---Renders a button panel, using the default style
---@param rect Rect
function ui.button_panel(rect)
	local hover = ui.trigger(rect)
	if hover then
		local clicking = ui.trigger_press(rect, 1)
		if clicking then
			set_color(ui.style.button_clicked)
		else
			set_color(ui.style.button_hovered)
		end
	else
		set_color(ui.style.button_inside)
	end
	ui.rectangle(rect)
	set_color(ui.style.button_outline)
	ui.outline(rect)
	set_color(ui.style.reset_color)
end

---Renders a slider panel, using the default style
---@param rect Rect rect of the filled part
---@param outter_rect Rect rect of the background part
function ui.slider_panel(rect, outter_rect)
	set_color(ui.style.panel_inside)
	ui.rectangle(outter_rect)
	local hover = ui.trigger(outter_rect)
	if hover then
		local clicking = ui.trigger_press(outter_rect, 1)
		if clicking then
			set_color(ui.style.button_clicked)
		else
			set_color(ui.style.button_hovered)
		end
	else
		set_color(ui.style.slider_filled)
	end
	ui.rectangle(rect)
	set_color(ui.style.button_outline)
	ui.outline(rect)
	set_color(ui.style.reset_color)
end

---Handles an invisible button. Returns a boolean if it was clicked.
---@param rect Rect
---@return boolean
function ui.invisible_button(rect)
	if ui.is_mouse_released(1) then
		if ui.trigger(rect) and ui.trigger_press(rect, 1) then
			return true
		end
	end
	return false
end

---Renders text using center/center alignment
---@param text string
---@param rect Rect
function ui.centered_text(text, rect)
	ui.text(text, rect, "center", "center")
end

---Renders text using right/center alignment
---@param text string
---@param rect Rect
function ui.left_text(text, rect)
	ui.text(text, rect, "left", "center")
end

---Renders text using left/center alignment
---@param text string
---@param rect Rect
function ui.right_text(text, rect)
	ui.text(text, rect, "right", "center")
end

---Draws a background image
---@param background_image love.Image
function ui.background(background_image)
	ui.image(background_image, ui.fullscreen())
end

---Draws a text button
---@param text string
---@param rect Rect
---@param tooltip string|nil
---@return boolean button_clicked
function ui.text_button(text, rect, tooltip)
	ui.button_panel(rect)
	ui.centered_text(text, rect)
	if tooltip then
		ui.tooltip(tooltip, rect)
	end
	return ui.invisible_button(rect)
end

---Draws a panel with text in the middle of it
---@param text string
---@param rect Rect
function ui.text_panel(text, rect)
	ui.panel(rect)
	ui.centered_text(text, rect)
end

---Draws a panel with text on the left side of it. Use it for drawing names.
---@param text string
---@param rect Rect
function ui.name_panel(text, rect)
	ui.panel(rect)
	rect.x = rect.x + 5
	ui.left_text(text, rect)
	rect.x = rect.x - 5
end

---Draws a panel with text on the right side of it. Use it for rendering numbers.
---@param text string
---@param rect Rect
function ui.field_panel(text, rect)
	ui.panel(rect)
	rect.x = rect.x - 5
	ui.right_text(text, rect)
	rect.x = rect.x + 5
end

---Draws a button with an icon on it.
---Note, this isn't the same as an image button, which uses 3 images to render the button instead of flat shaded rectangles.
---@param icon love.Image
---@param rect Rect
---@param tooltip string|nil
---@return boolean button_clicked
function ui.icon_button(icon, rect, tooltip)
	ui.button_panel(rect)
	ui.image(icon, rect)
	if tooltip then
		ui.tooltip(tooltip, rect)
	end
	return ui.invisible_button(rect)
end

---Draws a horizontal slider. Make sure the rect is long enough
---@param rect Rect
---@param current_value number
---@param min_value number
---@param max_value number
---@param vertical ?boolean
---@return number new_value
function ui.slider(rect, current_value, min_value, max_value, vertical)
	local ret = current_value

	local lr = ui.rect(rect.x, rect.y, rect.height, rect.height)
	if vertical then
		lr.width = rect.width
		lr.height = rect.width
	end
	if vertical then
		if ui.text_button("^", lr) then
			ret = min_value
		end
	else
		if ui.text_button("<", lr) then
			ret = min_value
		end
	end

	local fill = (current_value - min_value) / (max_value - min_value)
	local background = ui.rect(
		rect.x + rect.height,
		rect.y,
		rect.width - rect.height * 2,
		rect.height
	)
	local filled = ui.rect(
		rect.x + rect.height,
		rect.y,
		fill * (rect.width - rect.height * 2),
		rect.height
	)
	if vertical then
		background.x = rect.x
		background.y = rect.y + rect.width
		background.width = rect.width
		background.height = rect.height - rect.width * 2
		filled.x = rect.x
		filled.y = rect.y + rect.width
		filled.width = rect.width
		filled.height = fill * (rect.height - rect.width * 2)
	end
	ui.slider_panel(filled, background)

	local rr = ui.rect(rect.x + rect.width - rect.height, rect.y, rect.height, rect.height)
	if vertical then
		rr.x = rect.x
		rr.y = rect.y + rect.height - rect.width
		rr.width = rect.width
		rr.height = rect.width
	end
	if vertical then
		if ui.text_button("\\/", rr) then
			ret = max_value
		end
	else
		if ui.text_button(">", rr) then
			ret = max_value
		end
	end

	-- Lastly, check for clicks
	if ui.trigger(background) then
		if ui.is_mouse_held(1) then
			local pos_x, pos_y = ui.mouse_position()
			local frac = (pos_x - background.x) / background.width
			if vertical then
				frac = (pos_y - background.y) / background.height
			end
			ret = frac
		end
	end

	return ret
end

---Draws a horizontal slider. Includes a name on top of it. Make sure the rect is long enough
---@param slider_name string name to show above the slider
---@param rect Rect
---@param current_value number
---@param min_value number
---@param max_value number
---@return number new_value
function ui.named_slider(slider_name, rect, current_value, min_value, max_value)
	local up = ui.rect(rect.x, rect.y, rect.width, rect.height / 2)
	local down = ui.rect(rect.x, rect.y + rect.height / 2, rect.width, rect.height / 2)
	ui.text_panel(slider_name, up)
	return ui.slider(down, current_value, min_value, max_value)
end

---Draws a checkbox in a given rect.
---@param rect Rect
---@param is_on boolean
---@param shrink_amount number number of pixels to decrease the rect by for the purpose of rendering of checkbox's indicator of a clicked button
---@return boolean new_is_on
function ui.checkbox(rect, is_on, shrink_amount)
	local ret = is_on


	ui.button_panel(rect)
	if is_on then
		local n = rect:copy()
		n:shrink(shrink_amount)
		ui.rectangle(n)
	end

	if ui.invisible_button(rect) then
		ret = not ret
	end

	return ret
end

---Draws a panel with a given name and a square checkbox to the right of it.
---@param name string
---@param rect Rect
---@param is_on boolean
---@param shrink_amount number number of pixels to decrease the rect by for the purpose of rendering of checkbox's indicator of a clicked button
---@return boolean new_is_on
function ui.named_checkbox(name, rect, is_on, shrink_amount)
	local text_rect = ui.rect(rect.x, rect.y, rect.width - rect.height, rect.height)
	local checkbox_rect = ui.rect(rect.x + rect.width - rect.height, rect.y, rect.height, rect.height)
	ui.name_panel(name, text_rect)
	return ui.checkbox(checkbox_rect, is_on, shrink_amount)
end

-- ########################
-- ### ADVANCED WIDGETS ###
-- ########################
---
---@param rect Rect rect for the entire scroll view
---@param render_closure fun(number, Rect) fun(number, Rect) -- a drawing function for a given entry
---@param individual_height number height of a single entry, in pixels
---@param entries_count number number of entries in the scrollview
---@param slider_width number width of the slider
---@param slider_level number how "scrolled down" the slider is
---@return number new_slider_level
function ui.scrollview(
    rect,
    render_closure,
    individual_height,
    entries_count,
    slider_width,
    slider_level
)
	-- "Current" top-most level
	local current = math.min(
		entries_count,
		1 + math.floor(slider_level * entries_count)
	)
	local max_fit = math.floor(rect.height / individual_height)
	local last = math.min(entries_count, (current - 1) + max_fit)

	-- Draw the main panel
	local main_panel = ui.rect(rect.x, rect.y, rect.width - slider_width, rect.height)
	ui.panel(main_panel)

	-- Draw the contents
	local layout = ui.layout_builder()
		:position(main_panel.x, main_panel.y)
		:vertical()
		:build()
	for i = current, last do
		render_closure(i,
			layout:next(
				main_panel.width,
				individual_height
			)
		)
	end

	-- Draw the slider bar
	local sl = rect:copy()
	sl.x = sl.x + sl.width - slider_width
	sl.width = slider_width
	return ui.slider(sl, slider_level, 0, 1, true)
end

-- ###############
-- ### TOOLTIP ###
-- ###############

---Schedules the tooltip for display
---@param text string
---@param rect Rect collision area for the tooltips trigger...
function ui.tooltip(text, rect)
	if ui.trigger(rect) then
		tooltip_text = text
		tooltip_x, tooltip_y = ui.mouse_position()
	end
end

---Draws the tooltip on screen.
function ui.draw_tooltip()
	if tooltip_text ~= nil then
		local rect = ui.rect(0, 0, 300, 300)
		local offset = 10
		local scale_x, scale_y = get_ui_scaling_factor()
		local font = love.graphics.getFont()
		local ydim = font:getHeight()
		local max_width = 300 * scale_x
		local xdim, lines = font:getWrap(tooltip_text, max_width)
		local line_count = #lines
		ydim = ydim * line_count

		local prect = rect
		prect.x = tooltip_x + offset
		prect.y = tooltip_y + offset
		prect.width = xdim / scale_x + 2 * offset
		prect.height = ydim / scale_y + 2 * offset

		-- Flipping in case we hit an edge of the screen...
		if prect.x + prect.width > reference_width then
			prect.x = prect.x - 10
			prect.x = prect.x - prect.width
		end
		if prect.y + prect.height > reference_height then
			prect.y = prect.y - 10
			prect.y = prect.y - prect.height
		end
		ui.panel(prect)
		prect:shrink(5)
		ui.text(tooltip_text, prect, "left", 'up')
	end
	tooltip_text = nil -- clear the tooltip so that it doesn't stick around for the next frame
end

return ui
