local tabb = require "engine.table"
local ui = require "engine.ui"
local uit = require "game.ui-utils"
local mmut = require "game.map-modes.utils"

local window = {}
---@return Rect
function window.rect()
    return ui.fullscreen():subrect(0, 0, 200, uit.BASE_HEIGHT * 16, "center", "center")
end

function window.mask()
    if ui.trigger(window.rect()) then
		return false
	else
		return true
	end
end

---@param game GameScene
---@return string
function window.draw(game)
    local rect = window.rect()
    ui.panel(rect)

    local base_unit = uit.BASE_HEIGHT * 2
    local layout = ui.layout_builder():position(rect.x, rect.y):vertical():spacing(4):build()

    if uit.text_button(
			"Save game",
			layout:next(rect.width, base_unit),
			"Save"
	) then
		DEFINES = require "game.defines".init()
		DEFINES.world_gen = false
		DEFINES.world_to_load = "quicksave.binbeaver"
		local manager = require "game.scene-manager"
		manager.transition("world-saver")
		return "stop"
	end
	if uit.text_button(
			"Load game",
			layout:next(rect.width, base_unit),
			"Load"
	) then
		-- world.load("quicksave.binbeaver")
		DEFINES = require "game.defines".init()
		DEFINES.world_gen = false
		DEFINES.world_to_load = "quicksave.binbeaver"
		local manager = require "game.scene-manager"
		manager.transition("world-loader")
		return "stop"
	end
	if uit.text_button(
			"Export map",
			layout:next(rect.width, base_unit),
			"Export map"
	) then
		local to_save = require "game.minimap".make_minimap_image_data(
			1600, 800,
			game.map_mode_data[game.map_mode][5] == mmut.MAP_MODE_GRANULARITY.PROVINCE
		)
		to_save:encode("png", game.map_mode .. ".png")
		-- game.click_callback = callback.nothing()
	end
	if uit.text_button(
			"Options",
			layout:next(rect.width, base_unit),
			"Options"
	) then
		game.inspector = "options"
		-- game.click_callback = callback.nothing()
	end

	if WORLD.player_character then
		if uit.text_button("Change country", layout:next(rect.width, base_unit), "Change country") then
			require "game.raws.effects.player".to_observer()
			game.refresh_map_mode()
			-- game.click_callback = callback.nothing()
		end
	end

    if uit.text_button("Exit", layout:next(rect.width, base_unit), "EXIT THE GAME!") then
        game.inspector = nil
		return true
    end
    if uit.text_button("Return to the game", layout:next(rect.width, base_unit)) then
        game.inspector = nil
        return false
    end
end

return window