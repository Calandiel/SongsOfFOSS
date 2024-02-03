local wg = {
  state = "init"
}

local ffi = require("ffi")
local libsote = require("libsote.libsote")

------------------------------------------------------------------------------------------------------------------

function wg.init()
  wg.message = nil

  if not libsote.init() then
    wg.state = "error"
    wg.message = libsote.get_message()
    return
  end

  libsote.generate_world()
  wg.message = libsote.get_message()
  wg.state = "generated"
end

function wg.update(dt)
end

function wg.draw()
	local ui = require "engine.ui"
  local fs = ui.fullscreen()

  ui.background(ASSETS.background)
  ui.left_text(VERSION_STRING, fs:subrect(5, 0, 400, 30, "left", "down"))

  if wg.state == "error" then
    ui.text_panel(wg.message, ui.fullscreen():subrect(0, 0, 300, 60, "center", "down"))

    local menu_button_width = 380
    local menu_button_height = 30
    local base = fs:subrect(0, 20, 400, 300, "center", "center")
    ui.panel(base)

    local ll = base:subrect(0, 10, 0, 0, "center", "up")
    local layout = ui.layout_builder()
      :position(ll.x, ll.y)
      :vertical()
      :centered()
      :spacing(10)
      :build()

    local ut = require "game.ui-utils"

--    if ut.text_button(
--      "Retry",
--      layout:next(menu_button_width, menu_button_height)
--    ) then
--      print "retry"
--    end
    if ut.text_button(
      "Return",
      layout:next(menu_button_width, menu_button_height)
    ) then
      local manager = require "game.scene-manager"
      manager.transition("main-menu")
    end
  elseif wg.state == "generated" then
    ui.text_panel(wg.message, ui.fullscreen():subrect(0, 0, 300, 60, "center", "down"))
  end
end

return wg