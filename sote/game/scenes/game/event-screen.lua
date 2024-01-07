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

			local left = fs:subrect(0, 0, fs.width / 3, fs.height * 2/3, "left", "up")
			local top = left:copy()
			top.height = top.height / 2
			top:shrink(15)
			ui.panel(top)
			top:shrink(5)
			ui.text(event:event_text(character, dat), top, "left", "up")

			local bot = left:copy()
			bot.height = bot.height / 2
			bot.y = bot.y + bot.height
			bot:shrink(15)
			gam.event_scrollbar = gam.event_scrollbar or 0
			gam.event_scrollbar = uit.scrollview(bot, function(i, rect)
				if i > 0 then
					local opt = opts[i]
					if uit.text_button(opt.text, rect, opt.tooltip) then
						-- Clear the event from the queue!
						WORLD.events_queue:dequeue()
						WORLD.pending_player_event_reaction = false

						-- And only then handle option:
						-- option might create instant events in the front of queue!
						opt.outcome()
						print(opt.text)
						gam.refresh_map_mode()
					end
				end
			end, uit.BASE_HEIGHT, #opts, uit.BASE_HEIGHT, gam.event_scrollbar)

			local portrait = fs:subrect(0, fs.height * 2/3, fs.height / 5, fs.height / 5, "left", "up")
			portrait:shrink(15)
			require "game.scenes.game.widgets.portrait"(portrait, character)

			local name = portrait:copy()
			name.y = name.y + portrait.height
			name.height = name.height / 2
			local wealth = name:copy()
			wealth.height = wealth.height / 2
			wealth.y = wealth.y + name.height

			name:shrink(0)
			ui.panel(name)
			wealth:shrink(0)
			ui.panel(wealth)

			require "game.scenes.game.widgets.character-name"(name, character)
			uit.money_entry_icon(character.savings, wealth, "My savings")

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
