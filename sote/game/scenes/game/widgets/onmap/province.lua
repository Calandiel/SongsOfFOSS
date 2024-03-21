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
	rect.width = rect.width / 2
	ut.data_entry_icon("duality-mask.png", ut.to_fixed_point2(tile.province.mood), rect, "Local mood")
	rect.x = rect.x + rect.width
	ut.data_entry_icon("village.png", tostring(tile.province:total_home_population()), rect, "Home population")
	rect.y = y + length_of_line
	ut.data_entry_icon("minions.png", tostring(tile.province:local_population()), rect, "Local population")
	rect.x = rect.x - rect.width
	ut.data_entry_icon("inner-self.png", tostring(tile.province:local_characters()), rect, "Local characters")

	local line_rect = ui.rect(x - 1, y - length_of_line, 2, 50 - height_unit)
	ui.rectangle(line_rect)

	if callback_coa then
		return callback_coa
	end

	if WORLD.player_character and tile.province.realm then
		local button_rect = ui.rect(
			x - size / 5 + width_unit,
			y - 50 - height_unit * 2,
			size,
			size
		)
		if ut.icon_button(ASSETS.get_icon("barbute.png"), button_rect) then
			return callback.toggle_raiding_target(gam, tile.province)
		end
	end
end

