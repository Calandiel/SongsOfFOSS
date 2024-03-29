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
local old_mouse_position = {}
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
	r.old_mouse_position = old_mouse_position
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
	old_mouse_position = cache.old_mouse_position
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
	local current_ratio = reference_width / reference_height
	local new_ratio = new_width / new_height
	if current_ratio ~= new_ratio then
		reference_width = reference_height * new_ratio
	end
	--print(reference_width / reference_height .. " " .. reference_width .. "x" .. reference_height)
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
---@param rotation number?
function ui.image(image, rect, rotation)
	if rotation == nil then
		rotation = 0
	end

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

	-- Adjust them for drawing offset
	position_fraction_x = position_fraction_x + fill_x / 2
	position_fraction_y = position_fraction_y + fill_y / 2

	love.graphics.draw(
		image,
		dims_x * position_fraction_x, dims_y * position_fraction_y,
		rotation,
		scale_x, scale_y,
		image_width / 2, image_height / 2
	)
end

local temp_quad = love.graphics.newQuad(0, 0, 256, 256, 256, 256)

--- Draws a part of UI image at x/y coordinates and with a given width and height
---@param image love.Image
---@param rect Rect
---@param rotation number?
function ui.image_ith(image, i, rect, rotation)
	if rotation == nil then
		rotation = 0
	end

	local x = rect.x
	local y = rect.y
	local width = rect.width
	local height = rect.height
	-- Pull data
	local image_width = image:getWidth()
	local image_height = image:getHeight()
	local dims_x, dims_y = love.graphics.getDimensions()

	local quads = image_width / image_height
	if (i > 0) and (i < 1) then
		i = math.floor(i * quads)
	end
	temp_quad:setViewport(image_height * i, 0, image_height, image_height, image_width, image_height)

	image_width = image_height

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

	-- Adjust them for drawing offset
	position_fraction_x = position_fraction_x + fill_x / 2
	position_fraction_y = position_fraction_y + fill_y / 2

	love.graphics.draw(
		image, temp_quad,
		dims_x * position_fraction_x, dims_y * position_fraction_y,
		rotation,
		scale_x, scale_y,
		image_width / 2, image_height / 2
	)
end

---@alias VerticalAlignMode "up" | "center" | "down"
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
---@param mouse_x number?
---@param mouse_y number?
---@param shrink number?
---@return boolean mouse_in_rect
function ui.trigger(rect, mouse_x, mouse_y, shrink)
	if shrink == nil then
		shrink = 0
	end

	local x = rect.x
	local y = rect.y
	local width = rect.width
	local height = rect.height
	local mx, my = ui.mouse_position()
	if mouse_x ~= nil then
		mx = mouse_x
	end
	if mouse_y ~= nil then
		my = mouse_y
	end
	return mx > x + shrink and
		mx < x + width - shrink and
		my > y + shrink and
		my < y + height - shrink
end

---Returns true if mouse just moved inside this rect
---@param rect any
---@return boolean
function ui.trigger_start_hover(rect)
	local old_mouse_x, old_mouse_y = ui.old_mouse_position()
	if ui.trigger(rect, nil, nil) and not ui.trigger(rect, old_mouse_x, old_mouse_y, -1) then
		return true
	end
	return false
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
---@param radius number?
function ui.rectangle(rect, radius)
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
		height * scale_y,
		radius or 0,
		radius or 0
	)
end

---Convets ui coordinates to screen coordinates
---@param x number
---@param y number
---@return number
---@return number
function ui.ui_coord_to_screen_coord(x, y)
	local scale_x, scale_y = get_ui_scaling_factor()
	return x * scale_x, y * scale_y
end

---Draws an outline using love.graphics.rectangle
---@param rect Rect
---@param radius number?
function ui.outline(rect, radius)
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
		height * scale_y,
		radius or 0,
		radius or 0
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
	old_mouse_position.x = mouse_position.x
	old_mouse_position.y = mouse_position.y
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
---@return number, number
function ui.mouse_position()
	local x = mouse_position.x or 0
	local y = mouse_position.y or 0

	local scale_x, scale_y = get_ui_scaling_factor()

	return x / scale_x, y / scale_y
end

---comment
---@return number
---@return number
function ui.old_mouse_position()
	local x = old_mouse_position.x or 0
	local y = old_mouse_position.y or 0

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
---@field new fun(self: LayoutBuilder):LayoutBuilder
---@field position fun(self:LayoutBuilder,x:number,y:number):LayoutBuilder
---@field spacing fun(self:LayoutBuilder,space:number):LayoutBuilder
---@field horizontal fun(self:LayoutBuilder,left:boolean|nil):LayoutBuilder
---@field vertical fun(self:LayoutBuilder,up:boolean|nil):LayoutBuilder
---@field grid fun(self:LayoutBuilder,entries_per_row:number):LayoutBuilder
---@field flipped fun(self: LayoutBuilder):LayoutBuilder
---@field centered fun(self: LayoutBuilder):LayoutBuilder
---@field build fun(self: LayoutBuilder):Layout
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
---@param radius number?
---@param border boolean?
---@param inside boolean?
function ui.panel(rect, radius, border, inside)
	if border == nil then
		border = true
	end
	if inside == nil then
		inside = true
	end

	set_color(ui.style.panel_inside)
	if inside then
		ui.rectangle(rect, radius)
	end
	set_color(ui.style.panel_outline)
	if border then
		ui.outline(rect, radius)
	end
	set_color(ui.style.reset_color)
end

---Renders a button provided depending on hover and clicked status
---@param rect Rect
---@param radius number?
---@param border boolean
---@param hover boolean
---@param clicking boolean
function ui.dummy_button_panel(rect, radius, border, hover, clicking)
	if hover then
		if clicking then
			set_color(ui.style.button_clicked)
		else
			set_color(ui.style.button_hovered)
		end
	else
		set_color(ui.style.button_inside)
	end

	ui.rectangle(rect, radius)
	set_color(ui.style.button_outline)

	if border then
		ui.outline(rect, radius)
	end

	set_color(ui.style.reset_color)
end

---Returns the hovered and clicked status of rect
---@param rect Rect
---@return boolean
---@return boolean
function ui.hover_clicking_status(rect)
	local hover = ui.trigger(rect)
	local clicking = ui.trigger_press(rect, 1)

	return hover, clicking
end

---@class (strict) ButtonImagesSet
---@field passive love.Image
---@field hovered love.Image
---@field clicked love.Image

---Renders an image button given images for all three states
---comment
---@param rect Rect
---@param images ButtonImagesSet
---@param rotation number?
function ui.dummy_button_image(images, rect, rotation)
	local hover, clicking = ui.hover_clicking_status(rect)

	if rotation == nil then
		rotation = 0
	end

	if hover then
		if clicking then
			ui.image(images.clicked, rect, rotation)
		else
			ui.image(images.hovered, rect, rotation)
		end
	else
		ui.image(images.passive, rect, rotation)
	end
end

---Renders a button panel, using the default style
---@param rect Rect
---@param radius number?
---@param border boolean?
function ui.button_panel(rect, radius, border)
	if border == nil then
		border = true
	end
	local hover, clicking = ui.hover_clicking_status(rect)
	ui.dummy_button_panel(rect, radius, border, hover, clicking)
end

---Renders a slider panel, using the default style
---@param rect Rect rect of the filled part
---@param outter_rect Rect rect of the background part
---@param circle_style boolean?
function ui.slider_panel(rect, outter_rect, circle_style)
	if circle_style == nil then
		circle_style = true
	end

	if circle_style then
		set_color(ui.style.slider_filled)
		if outter_rect.width > outter_rect.height then
			ui.rectangle(outter_rect:subrect(0, 0, outter_rect.width, 3, "center", 'center'))
		else
			ui.rectangle(outter_rect:subrect(0, 0, 3, outter_rect.height, "center", 'center'))
		end
	else
		set_color(ui.style.panel_inside)
		ui.rectangle(outter_rect)
	end
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
	if circle_style then
		local circle = rect:subrect(0, 0, 10, 10, "center", 'center')
		ui.rectangle(circle, 10)
		set_color(ui.style.button_outline)
		ui.outline(circle, 10)
	else
		ui.rectangle(rect)
		set_color(ui.style.button_outline)
		ui.outline(rect)
	end
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
---@param radius number?
---@param border boolean?
---@return boolean button_clicked
function ui.text_button(text, rect, tooltip, radius, border)
	ui.button_panel(rect, radius, border)
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

---Draws an image button
---@param images ButtonImagesSet
---@param rect Rect
---@param tooltip string|nil
function ui.image_button(images, rotation, rect, tooltip)
	ui.dummy_button_image(images, rect, rotation)
	if tooltip then
		ui.tooltip(tooltip, rect)
	end
	return ui.invisible_button(rect)
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
---@param height number ratio of slider to whole length
---@param circle_style boolean?
---@param slider_arrow_images ButtonImagesSet?
---@return number new_value
function ui.slider(rect, current_value, min_value, max_value, vertical, height, circle_style, slider_arrow_images)
	if circle_style == nil then
		circle_style = true
	end

	local ret = math.max(min_value, math.min(max_value, current_value))

	local slider_real_length = rect.width
	local control_button_size = rect.height
	local slider_size = height * (slider_real_length - 2 * control_button_size)

	local lr = ui.rect(rect.x, rect.y, rect.height, rect.height)
	if vertical then
		slider_real_length = rect.height
		control_button_size = rect.width
		slider_size = height * (slider_real_length - 2 * control_button_size)
		lr.width = rect.width
		lr.height = rect.width
	end

	if circle_style then
		slider_size = 10
	end

	if slider_arrow_images == nil then
		if vertical then
			if ui.text_button("/\\", lr) then
				ret = min_value
			end
		else
			if ui.text_button("<", lr) then
				ret = min_value
			end
		end
	else
		local rotation = -math.pi / 2
		if vertical then
			rotation = 0
		end
		if ui.image_button(slider_arrow_images, rotation, lr) then
			ret = min_value
		end
	end

	local active_zone = (rect.width - rect.height * 2)
	local value_ratio = (ret - min_value) / (max_value - min_value)

	-- 0 to height
	-- 1 to length - height - slider_size
	local start = value_ratio * (slider_real_length - 2 * control_button_size - slider_size) + control_button_size

	local background = ui.rect(
		rect.x + rect.height,
		rect.y,
		active_zone,
		rect.height
	)
	local filled = ui.rect(
		rect.x + start,
		rect.y,
		slider_size,
		rect.height
	)

	if vertical then
		local active_zone = (rect.height - rect.width * 2)
		background.x = rect.x
		background.y = rect.y + rect.width
		background.width = rect.width
		background.height = active_zone
		filled.x = rect.x
		filled.y = rect.y + start
		filled.width = rect.width
		filled.height = slider_size
	end
	ui.slider_panel(filled, background, circle_style)

	local rr = ui.rect(rect.x + rect.width - rect.height, rect.y, rect.height, rect.height)
	if vertical then
		rr.x = rect.x
		rr.y = rect.y + rect.height - rect.width
		rr.width = rect.width
		rr.height = rect.width
	end

	if slider_arrow_images == nil then
		if vertical then
			if ui.text_button("\\/", rr) then
				ret = max_value
			end
		else
			if ui.text_button(">", rr) then
				ret = max_value
			end
		end
	else
		local rotation = math.pi / 2
		if vertical then
			rotation = math.pi
		end
		if ui.image_button(slider_arrow_images, rotation, rr) then
			ret = max_value
		end
	end

	-- Lastly, check for clicks
	if ui.trigger(background) then
		if ui.is_mouse_held(1) then
			---@type number, number
			local pos_x, pos_y = ui.mouse_position()
			local frac = (pos_x - background.x) / background.width
			local active_area_length = background.width - slider_size
			if vertical then
				frac = (pos_y - background.y) / background.height
				active_area_length = background.height - slider_size
			end
			ret = frac

			local padding = slider_size / active_area_length
			-- scale range [low + slider_width_ratio / 2, high - slider_width_ratio / 2] to range [low, high]
			ret = math.min(1, math.max(0, ret * (1 + padding) - padding / 2))

			ret = min_value + (max_value - min_value) * ret
		end
	end

	-- love.graphics.print(tostring(ret), rect.x, rect.y)

	return ret
end

---Draws a horizontal slider. Includes a name on top of it. Make sure the rect is long enough
---@param slider_name string name to show above the slider
---@param rect Rect
---@param current_value number
---@param min_value number
---@param max_value number
---@param height number ratio of slider to whole length
---@param circle_style boolean?
---@param slider_arrow_images ButtonImagesSet?
---@return number new_value
function ui.named_slider(slider_name, rect, current_value, min_value, max_value, height, circle_style,
						 slider_arrow_images)
	local up = ui.rect(rect.x, rect.y, rect.width, rect.height / 2)
	local down = ui.rect(rect.x, rect.y + rect.height / 2, rect.width, rect.height / 2)
	ui.text_panel(slider_name, up)
	return ui.slider(down, current_value, min_value, max_value, false, height, circle_style, slider_arrow_images)
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

---SCROLLVIEW
---@param rect Rect rect for the entire scroll view
---@param render_closure fun(index: number, rect: Rect) fun(number, Rect) -- a drawing function for a given entry
---@param individual_height number height of a single entry, in pixels
---@param entries_count number number of entries in the scrollview
---@param slider_width number width of the slider
---@param slider_level number how "scrolled down" the slider is
---@param circle_style boolean?
---@param slider_arrow_images ButtonImagesSet?
---@return number new_slider_level
function ui.scrollview(
	rect,
	render_closure,
	individual_height,
	entries_count,
	slider_width,
	slider_level,
	circle_style,
	slider_arrow_images
)
	-- "mouse scroll"
	if ui.trigger(rect) then
		slider_level = math.min(math.max(0, slider_level - ui.mouse_wheel() / entries_count), 1)
	end

	-- "Current" top-most level
	local max_fit = math.floor(rect.height / individual_height)

	local slider_height = math.min(max_fit / entries_count, 1)

	-- local current = math.min(
	-- 	math.max(1, entries_count - max_fit + 1),
	-- 	1 + math.floor(slider_level * entries_count)
	-- )

	local current = 1 + math.floor(slider_level * (entries_count - max_fit) + 0.5)
	current = math.max(1, math.min(entries_count, current))

	local last = math.min(entries_count, (current - 1) + max_fit)

	-- Draw the main panel
	local main_panel = ui.rect(rect.x, rect.y, rect.width - slider_width, rect.height)
	ui.panel(main_panel)

	-- Draw the contents
	local layout = ui.layout_builder()
		:position(main_panel.x, main_panel.y)
		:vertical()
		:build()

	local old_color = ui.style.button_inside

	local color_1 = { r = 0, g = 0, b = 0, a = 0.05 }
	local color_2 = { r = 1, g = 1, b = 1, a = 0.05 }

	for i = current, last do
		local item_rect = layout:next(
			main_panel.width,
			individual_height
		)
		ui.style.button_inside = color_1
		if (i % 2) == 0 then
			ui.style.button_inside = color_2
		end
		ui.button_panel(item_rect, 2, false)
		render_closure(i, item_rect)
	end

	ui.style.button_inside = old_color


	-- Draw the slider bar
	local sl = rect:copy()
	sl.x = sl.x + sl.width - slider_width
	sl.width = slider_width
	return ui.slider(sl, slider_level, 0, 1, true, slider_height, circle_style, slider_arrow_images)
end

---@class TableState
---@field sorted_field number
---@field sorting_order boolean
---@field individual_height number
---@field slider_width number
---@field slider_level number
---@field header_height number



---@class TableColumn<TableEntry>: {render_closure: fun(rect: Rect, k:TableKey, v:TableEntry), header: string, width: number, value: (fun(k: TableKey, v: TableEntry): TableField), active: boolean|nil}

---@alias TableField number|string
---@alias TableKey table|string

---@class TablePair<TableEntry>: {key: TableKey, value: TableEntry}

---TABLE
---Renders a sortable table with header and scroll. Mutates state in place.
---@generic T : table
---@param rect Rect
---@param data table<TableKey, T>
---@param columns TableColumn<T>[]
---@param state TableState
---@param circle_style boolean?
---@param slider_arrow_images ButtonImagesSet?
function ui.table(rect, data, columns, state, circle_style, slider_arrow_images)
	--- data sorting
	---@type TablePair<T>[]
	local sorted_data = {}
	for _, entry in pairs(data) do
		table.insert(sorted_data, { key = _, value = entry })
	end
	table.sort(sorted_data, function(a, b)
		local value_a = columns[state.sorted_field].value(a.key, a.value)
		local value_b = columns[state.sorted_field].value(b.key, b.value)
		-- xor
		-- print(value_a, value_b, state.sorting_order, not ((value_a > value_b) == state.sorting_order))
		-- print(state.sorted_field, value_a, value_b)
		if state.sorting_order then
			return (value_a > value_b)
		else
			return (value_a < value_b)
		end
	end)

	--- header
	local layout = ui.layout_builder()
		:horizontal()
		:position(rect.x, rect.y)
		:spacing(0)
		:build()
	local total_weight = 0
	for index = 1, #columns do
		total_weight = total_weight + columns[index].width
	end
	local weight = (rect.width - 20) / total_weight
	for index = 1, #columns do
		local header_rect = layout:next(columns[index].width * weight, state.individual_height)
		header_rect.height = rect.height
		if not columns[index].active and ui.text_button("", header_rect) then
			if state.sorted_field == index then
				state.sorting_order = not state.sorting_order
			else
				state.sorted_field = index
				state.sorting_order = true
			end
		end
		if columns[index].active then
			ui.panel(header_rect)
		end
		header_rect.height = state.header_height

		if columns[index].active then
			if ui.text_button("", header_rect) then
				if state.sorted_field == index then
					state.sorting_order = not state.sorting_order
				else
					state.sorted_field = index
					state.sorting_order = true
				end
			end
		end

		ui.centered_text(columns[index].header, header_rect)
		-- ui.right_text(tostring(columns[index].width), header_rect)
	end

	rect.y = rect.y + state.header_height
	rect.height = rect.height - state.header_height
	local result = nil

	local function render_closure(i, rect)
		local entry = sorted_data[i]
		if entry == nil then return end
		local layout = ui.layout_builder()
			:horizontal()
			:position(rect.x, rect.y)
			:spacing(0)
			:build()
		for index = 1, #columns do
			local temp = columns[index].render_closure(
				layout:next(columns[index].width * weight, state.individual_height), entry.key, entry.value)
			if temp then
				result = temp
			end
		end
	end

	state.slider_level = ui.scrollview(rect, render_closure, state.individual_height, #sorted_data, state.slider_width,
		state.slider_level, circle_style, slider_arrow_images)
	return result
end

---@param rect Rect rect for the entire scroll view
---@param render_closure fun(number, Rect) fun(number, Rect) -- a drawing function for a given entry
---@param individual_height number height of a single entry, in pixels
---@param entries_count number number of entries in the scrollview
function ui.listview(
	rect,
	render_closure,
	individual_height,
	entries_count
)
	-- Draw the main panel
	local main_panel = ui.rect(rect.x, rect.y, rect.width, rect.height)
	ui.panel(main_panel)
	-- Draw the contents
	local layout = ui.layout_builder()
		:position(main_panel.x, main_panel.y)
		:vertical()
		:build()
	for i = 1, entries_count do
		render_closure(i,
			layout:next(
				main_panel.width,
				individual_height
			)
		)
	end
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
