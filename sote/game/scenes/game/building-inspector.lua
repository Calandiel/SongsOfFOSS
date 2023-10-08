local re = {}
local tabb = require "engine.table"
local trade_good = require "game.raws.raws-utils".trade_good
local ui = require "engine.ui"
local uit = require "game.ui-utils"

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
	local panel = fs:subrect(0, 0, 500, 500, "left", 'down')
	return panel
end

---Returns whether or not clicks on the planet can be registered.
---@return boolean
function re.mask()
	if ui.trigger(get_main_panel()) then
		return false
	else
		return true
	end
end

---@param gam table
function re.draw(gam)
	-- -@diagnostic disable-next-line: assign-type-mismatch

	---@type Building
	local bbuild = gam.selected_building
	if bbuild ~= nil then
		---@type Building
		local building = bbuild
		local panel = get_main_panel()
		ui.panel(panel)

		if ui.icon_button(ASSETS.icons["cancel.png"], panel:subrect(0, 0, uit.BASE_HEIGHT, uit.BASE_HEIGHT, "right", 'up')) then
			gam.click_tile(-1)
			gam.selected_building = nil
			gam.inspector = nil
		end

		local topbar = ui.layout_builder()
			:position(panel.x, panel.y)
			:horizontal()
			:spacing(5)
			:build()
		ui.image(ASSETS.icons[building.type.icon], topbar:next(uit.BASE_HEIGHT, uit.BASE_HEIGHT))
		ui.left_text(building.type.name, topbar:next(10 * uit.BASE_HEIGHT, uit.BASE_HEIGHT))

		local pan = panel:subrect(5, 5 + uit.BASE_HEIGHT, panel.width - 10, uit.BASE_HEIGHT * 3, "left", 'up')
		ui.panel(pan)
		local ppan = pan:subrect(0, uit.BASE_HEIGHT + 5, pan.width, uit.BASE_HEIGHT, "left", 'down')
		pan:shrink(5)
		ui.text(building.type.description, pan, "left", 'up')

		uit.columns({
			function(rect)
				ui.panel(rect)
				rect:shrink(5)
				ui.left_text("Current workers:", rect)
				ui.right_text(tostring(tabb.size(building.workers)) ..
					' / ' .. tostring(tabb.size(building.type.production_method.jobs)), rect)

				rect:shrink(-5)
				rect.y = rect.y + rect.height
				rect.height = rect.height * 5
				gam.building_workers_scrollbar = gam.building_workers_scrollbar or 0
				gam.building_workers_scrollbar = ui.scrollview(rect, function(entry, rect)
					if entry > 0 then
						---@type POP
						local worker, _ = tabb.nth(building.workers, entry)
						local w = rect.width
						rect.width = uit.BASE_HEIGHT
						ui.image(ASSETS.icons[worker.race.icon], rect)
						rect.width = w
						rect.x = rect.x + uit.BASE_HEIGHT + 5
						rect.width = rect.width - uit.BASE_HEIGHT - 5
						ui.left_text(worker.job.name, rect)
					end
				end, uit.BASE_HEIGHT, tabb.size(building.workers), uit.BASE_HEIGHT, gam.building_workers_scrollbar)
			end,
			function(rect)
				local layout = ui.layout_builder()
					:position(rect.x, rect.y)
					:vertical()
					:build()
				local next = layout:next(rect.width, rect.height)
				ui.panel(next)
				next:shrink(5)

				next = layout:next(rect.width, rect.height)
				ui.panel(next)
				ui.centered_text("Base inputs", next)
				next = layout:next(rect.width, rect.height * 4)
				gam.building_inputs_scrollbar = gam.building_inputs_scrollbar or 0
				gam.building_inputs_scrollbar = ui.scrollview(next, function(entry, rect)
					if entry > 0 then
						---@type TradeGoodReference
						local input, amount = tabb.nth(building.type.production_method.inputs, entry)
						local input_data = trade_good(input)
						local w = rect.width
						rect.width = uit.BASE_HEIGHT
						ui.image(ASSETS.icons[input_data.icon], rect)
						rect.width = w
						rect.x = rect.x + uit.BASE_HEIGHT + 5
						rect.width = rect.width - uit.BASE_HEIGHT - 5
						ui.left_text(input, rect)
						rect.x = rect.x - 5
						ui.right_text(tostring(amount), rect)
					end
				end, uit.BASE_HEIGHT, tabb.size(building.type.production_method.inputs), uit.BASE_HEIGHT,
					gam.building_inputs_scrollbar)

				next = layout:next(rect.width, rect.height)
				ui.panel(next)
				ui.centered_text("Base outputs", next)
				next = layout:next(rect.width, rect.height * 4)
				gam.building_outputs_scrollbar = gam.building_outputs_scrollbar or 0
				gam.building_outputs_scrollbar = ui.scrollview(next, function(entry, rect)
					if entry > 0 then
						---@type TradeGoodReference
						local input, amount = tabb.nth(building.type.production_method.outputs, entry)
						local input_data = trade_good(input)

						local w = rect.width
						rect.width = uit.BASE_HEIGHT
						ui.image(ASSETS.icons[input_data.icon], rect)
						rect.width = w
						rect.x = rect.x + uit.BASE_HEIGHT + 5
						rect.width = rect.width - uit.BASE_HEIGHT - 5
						ui.left_text(input, rect)
						rect.x = rect.x - 5
						ui.right_text(tostring(amount), rect)
					end
				end, uit.BASE_HEIGHT, tabb.size(building.type.production_method.outputs), uit.BASE_HEIGHT,
					gam.building_outputs_scrollbar)
			end
		}, ppan, uit.BASE_HEIGHT * 8.08)

	end
end

return re
