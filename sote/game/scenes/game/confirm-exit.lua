local tabb = require "engine.table"
local ui = require "engine.ui"
local uit = require "game.ui-utils"

local window = {}
---@return Rect
function window.rect() 
    return ui.fullscreen():subrect(0, 0, 300, 50, "center", "center")
end

function window.mask()
    if ui.trigger(window.rect()) then
		return false
	else
		return true
	end
end

function window.draw(game)
    local rect = window.rect()
    ui.panel(rect)

    rect.width = rect.width / 2

    --- confirm
    if ui.text_button("Confirm exit", rect) then
        game.inspector = nil
		return true
    end

    rect.x = rect.x + rect.width
    --- cancel
    if ui.text_button("Return to the game", rect) then
        game.inspector = nil
        return false
    end
end

return window