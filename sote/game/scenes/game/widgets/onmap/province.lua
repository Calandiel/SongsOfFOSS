local ui = require "engine.ui"
local ut = require "game.ui-utils"

local tile_utils = require "game.entities.tile"
local province_utils = require "game.entities.province".Province

local callback = require "game.scenes.callbacks"

---@param gam GameScene
---@param tile_id tile_id
---@param rect Rect rectangle of the according tile
---@param x number
---@param y number
---@param size number
return function(gam, tile_id, rect, x, y, size)
	-- unit sizes
	local width_unit = size * 4
	local height_unit = size / 2
	local length_of_line = 50 - height_unit

	local province = tile_utils.province(tile_id)
	if province == INVALID_ID then
		return
	end

	local realm =  province_utils.realm(province)

	if realm == INVALID_ID then
		return
	end

	rect.x = x - size / 5
	rect.y = y - length_of_line - height_unit * 2
	rect.width = width_unit
	rect.height = height_unit
	ut.data_entry("", DATA.province_get_name(province), rect)

	rect.y = rect.y - height_unit
	local callback_coa = require "game.scenes.game.widgets.realm-name"(gam, realm, rect, "callback")

	rect.y = y - length_of_line - height_unit
	local population = province_utils.local_population(province)
	ut.data_entry("", tostring(population), rect)

	local line_rect = ui.rect(x - 1, y - length_of_line, 2, 50 - height_unit)
	ui.rectangle(line_rect)

	if callback_coa then
		return callback_coa
	end
end

