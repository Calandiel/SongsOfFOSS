local ui = require "engine.ui"
local uit = require "game.ui-utils"
local ev = {}

local loaded_image = nil
local loaded_image_name = nil

---@param gam table
function ev.draw(gam)

	if WORLD.pending_player_event_reaction then
		local peek = WORLD.events_queue:peek()

		local event_string = peek[1]
		local character = peek[2]
		local dat = peek[3]

		-- print(event_string)
		-- print(character.name)
		-- print(WORLD.player_character.name)

		if WORLD.player_character == character then
			local fs = ui.fullscreen()
			local event = RAWS_MANAGER.events_by_name[event_string]
			local opts = event:options(character, dat)

			if event.event_background_path ~= loaded_image_name then
				loaded_image_name = event.event_background_path
				loaded_image = love.graphics.newImage(loaded_image_name)
			end

			-- Draw the background
			ui.background(loaded_image)

			local left = fs:subrect(0, 0, uit.BASE_HEIGHT * 10, fs.height, "left", 'up')
			local top = left:copy()
			top.height = top.height / 2
			top:shrink(5)
			ui.panel(top)
			top:shrink(5)
			ui.text(event:event_text(character, dat), top, "left", 'up')

			local bot = left:copy()
			bot.height = bot.height / 2
			bot.y = bot.y + bot.height
			bot:shrink(5)
			gam.event_scrollbar = gam.event_scrollbar or 0
			gam.event_scrollbar = ui.scrollview(bot, function(i, rect)
				if i > 0 then
					local opt = opts[i]
					if ui.text_button(opt.text, rect, opt.tooltip) then
						opt.outcome()
						-- Clear the event from the queue!
						WORLD.events_queue:dequeue()
						WORLD.pending_player_event_reaction = false
					end
				end
			end, uit.BASE_HEIGHT, #opts, uit.BASE_HEIGHT, gam.event_scrollbar)
		else
			print("We're trying to draw the event screen but the next event isn't meant for the player!")
			love.event.quit()
		end
	else
		print("We're trying to draw the event screen but we're not pending player events!")
		love.event.quit()
	end
end

return ev
