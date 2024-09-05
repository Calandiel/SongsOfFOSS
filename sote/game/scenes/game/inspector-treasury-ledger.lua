local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"



local window = {}

local scroll_character = 0
local scroll_realm = 0
local scroll_news = 0
window.current_tab = "Character"

---@return Rect
function window.rect()
    return ui.fullscreen():subrect(0, 0, 400, 600, "center", "center")
end

function window.mask()
    if ui.trigger(window.rect()) then
		return false
	else
		return true
	end
end

function window.draw(game, realm)
    local panel = window.rect()
    local base_unit = ut.BASE_HEIGHT
    ui.panel(panel)

    -- header
    panel.height = panel.height - base_unit * 2.5
    if ut.icon_button(ASSETS.icons["cancel.png"], panel:subrect(0, 0, base_unit, base_unit, "right", "up")) then
        game.inspector = nil
    end
    ui.left_text("Journal", panel:subrect(0, 0, base_unit * 6, base_unit, "left", "up"))

    local layout = ui.layout_builder()
        :position(panel.x, panel.y + base_unit)
        :spacing(2)
        :horizontal()
        :build()

    panel.y = panel.y + base_unit * 2.5

    local treasury_tab = nil

    if WORLD.player_character.rank == CHARACTER_RANK.CHIEF then
        treasury_tab = {
            text = "Treasury",
            tooltip = "Realm treasury ledger",
            closure = function()
                scroll_realm = require "game.scenes.game.widgets.treasury-ledger"(panel, "realm", scroll_realm, base_unit)
            end
        }
    end

    window.current_tab = ut.tabs(window.current_tab, layout, {
        {
            text = "Character",
            tooltip = "Character savings ledger",
            closure = function()
                scroll_character = require "game.scenes.game.widgets.treasury-ledger"(panel, "character", scroll_character, base_unit)
            end
        },
        treasury_tab,
        {
            text = "News",
            tooltip = "Recent news of the realm",
            closure = function()
                scroll_news = require "game.scenes.game.widgets.news"(panel, scroll_news)
            end
        }
    }, 1, base_unit * 5)

end

return window