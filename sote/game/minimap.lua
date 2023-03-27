

local mm = {}

local tile = require "game.entities.tile"
local latlon = require "game.latlon"

---Creates and returns a new minimap texture!
---@param width ?number
---@param height ?number
---@return love.ImageData
function mm.make_minimap_image_data(width, height)
	local w = width or 400
	local h = height or 200

	local imd = love.image.newImageData(w, h)

	for x = 1, w do
		for y = 1, h do
			local lon = ((x - 0.5) / w * 2 - 1) * math.pi
			local lat = ((y - 0.5) / h - 0.5) * math.pi
			local tt = WORLD.tiles[tile.lat_lont_to_index(lat, lon)]

			local r = tt.real_r
			local g = tt.real_g
			local b = tt.real_b

			imd:setPixel(x - 1, y - 1, r, g, b, 1)
		end
	end

	return imd
end
---Creates and returns a new minimap texture!
---@param width ?number
---@param height ?number
---@return love.Image
function mm.make_minimap(width, height)
	return love.graphics.newImage(mm.make_minimap_image_data(width, height))
end

local ui = require "engine.ui"
---Draws the minimap and handles changes to camera position caused by clicks
---@param img love.Image
---@param camera_position any -- cpml.Vec3
---@param rect Rect
function mm.draw(img, camera_position, rect)
	ui.image(img, rect)

	-- Calculate a rect for the camera location indicator!
	local lat, lon = latlon.lat_lon_from_cart(
		camera_position.x,
		camera_position.y,
		camera_position.z
	)
	local x = (lon + math.pi) / (2 * math.pi)
	local y = (lat + math.pi / 2) / math.pi
	local handle = rect:copy()
	local handle_size = 26
	handle.x = rect.x + rect.width * x - handle_size / 2
	handle.y = rect.y + rect.height * y - handle_size / 2
	handle.width = handle_size
	handle.height = handle_size


	if ui.trigger_press(rect, 1) then
		if ui.trigger(rect) then
			if ui.is_mouse_held(1) then
				local mouse_x, mouse_y = ui.mouse_position()
				local frac_x = (mouse_x - rect.x) / rect.width
				local frac_y = (mouse_y - rect.y) / rect.height

				local lat = (frac_y - 0.5) * math.pi
				local lon = (frac_x - 0.5) * 2 * math.pi

				local x, y, z = latlon.lat_lon_to_cart(lat, lon)
				local dist = camera_position:len()
				x = x * dist
				y = y * dist
				z = z * dist
				camera_position.x = x
				camera_position.y = y
				camera_position.z = z
			end
		end
	end


	love.graphics.setColor(0.35, 0.35, 0, 1)
	ui.image(ASSETS.icons["circle.png"], handle)
	handle:shrink(3)
	love.graphics.setColor(0.7, 0.7, 0, 1)
	ui.image(ASSETS.icons["circle.png"], handle)
	handle:shrink(3)
	love.graphics.setColor(0.35, 0.35, 0, 1)
	ui.image(ASSETS.icons["circle.png"], handle)
	love.graphics.setColor(1, 1, 1, 1)
end


return mm