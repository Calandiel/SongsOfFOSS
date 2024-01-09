local ui = require "engine.ui"
local ut = require "game.ui-utils"

local callback = require "game.scenes.callbacks"

---@param gam GameScene
---@param tile Tile
---@param rect Rect rectangle of the according tile
---@param x number
---@param y number
---@param size number
return function(gam, tile, rect, x, y, size)
	-- unit sizes
	local width_unit = size * 4
	local height_unit = size / 2
	local length_of_line = 50 - height_unit

	if tile.province.realm == nil then
		return
	end

	rect.x = x - size / 5
	rect.y = y - length_of_line - height_unit * 2
	rect.width = width_unit
	rect.height = height_unit
	ut.data_entry("", tile.province.name, rect)

	rect.y = rect.y - height_unit
	local callback_coa = require "game.scenes.game.widgets.realm-name"(gam, tile.province.realm, rect, "callback")

	rect.y = y - length_of_line - height_unit
	local population = tile.province:population()
	ut.data_entry("", tostring(population), rect)

	local line_rect = ui.rect(x - 1, y - length_of_line, 2, 50 - height_unit)
	ui.rectangle(line_rect)

	if callback_coa then
		return callback_coa
	end
end

