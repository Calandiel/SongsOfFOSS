local tabb = require "engine.table"
local ui = require "engine.ui"
local uit = require "game.ui-utils"

local tb = {}

---@return boolean
function tb.mask(gam)
	local tr = ui.rect(0, 0, 800, uit.BASE_HEIGHT)
	if WORLD.player_realm then
		return not ui.trigger(tr)
	else
		return true
	end
end

---Draws the bar at the top of the screen (if a player realm has been selected...)
---@param gam table
function tb.draw(gam)
	if WORLD.player_realm ~= nil then
		local tr = ui.rect(0, 0, 800, uit.BASE_HEIGHT)
		ui.panel(tr)

		-- COA + name
		local layout = ui.layout_builder()
			:position(0, 0)
			:horizontal()
			:build()
		if uit.coa(WORLD.player_realm, layout:next(uit.BASE_HEIGHT, uit.BASE_HEIGHT)) then
			print("Player COA Clicked")
			gam.inspector = "realm"
			gam.selected_realm = WORLD.player_realm
			---@type Tile
			local captile = tabb.nth(WORLD.player_realm.capitol.tiles, 1)
			gam.click_tile(captile.tile_id)
		end
		ui.left_text(WORLD.player_realm.name, layout:next(uit.BASE_HEIGHT * 2.5, uit.BASE_HEIGHT))

		-- Treasury
		local tr = layout:next(uit.BASE_HEIGHT, uit.BASE_HEIGHT)
		local trs = "Treasury"
		ui.image(ASSETS.icons['coins.png'], tr)
		ui.tooltip(trs, tr)
		local trt = layout:next(uit.BASE_HEIGHT * 2, uit.BASE_HEIGHT)
		ui.right_text(tostring(math.floor(WORLD.player_realm.treasury * 100) / 100) .. MONEY_SYMBOL, trt)
		ui.tooltip(trs, trt)

		-- Food
		local amount = WORLD.player_realm.resources[WORLD.trade_goods_by_name['food']] or 0
		local tr = layout:next(uit.BASE_HEIGHT, uit.BASE_HEIGHT)
		local trs = "Food"
		ui.image(ASSETS.icons['noodles.png'], tr)
		ui.tooltip(trs, tr)
		local trt = layout:next(uit.BASE_HEIGHT * 2, uit.BASE_HEIGHT)
		ui.right_text(tostring(math.floor(amount * 100) / 100), trt)
		ui.tooltip(trs, trt)

		-- Technology
		local amount = WORLD.player_realm:get_education_efficiency()
		local tr = layout:next(uit.BASE_HEIGHT, uit.BASE_HEIGHT)
		local trs = "Current ability to research new technologies. When it's under 100%, technologies will be slowly forgotten, when above 100% they will be researched. Controlled largely through treasury spending on research and education but in most states the bulk of the contribution will come from POPs in the realm instead."
		ui.image(ASSETS.icons['erlenmeyer.png'], tr)
		ui.tooltip(trs, tr)
		local trt = layout:next(uit.BASE_HEIGHT * 2, uit.BASE_HEIGHT)
		ui.right_text(tostring(math.floor(amount * 100)) .. '%', trt)
		ui.tooltip(trs, trt)

		-- Happiness
		local amount = WORLD.player_realm:get_average_mood()
		local tr = layout:next(uit.BASE_HEIGHT, uit.BASE_HEIGHT)
		local trs = "Average mood (happiness) of population in our realm. Happy pops contribute more voluntarily to our treasury, whereas unhappy ones contribute less."
		ui.image(ASSETS.icons['duality-mask.png'], tr)
		ui.tooltip(trs, tr)
		local trt = layout:next(uit.BASE_HEIGHT * 2, uit.BASE_HEIGHT)
		ui.right_text(tostring(math.floor(amount)), trt)
		ui.tooltip(trs, trt)

		-- POP
		local amount = WORLD.player_realm:get_total_population()
		local tr = layout:next(uit.BASE_HEIGHT, uit.BASE_HEIGHT)
		local trs = "Current population of our realm."
		ui.image(ASSETS.icons['minions.png'], tr)
		ui.tooltip(trs, tr)
		local trt = layout:next(uit.BASE_HEIGHT * 2, uit.BASE_HEIGHT)
		ui.right_text(tostring(math.floor(amount)), trt)
		ui.tooltip(trs, trt)

		-- Army size
		local amount = WORLD.player_realm:get_realm_military()
		local target = WORLD.player_realm:get_realm_military_target() + WORLD.player_realm:get_realm_active_army_size()
		local tr = layout:next(uit.BASE_HEIGHT, uit.BASE_HEIGHT)
		local trs = "Size of our realms armies."
		ui.image(ASSETS.icons['barbute.png'], tr)
		ui.tooltip(trs, tr)
		local trt = layout:next(uit.BASE_HEIGHT * 2, uit.BASE_HEIGHT)
		ui.right_text(tostring(math.floor(amount)) .. ' / ' .. tostring(math.floor(target)), trt)
		ui.tooltip(trs, trt)

	end
end

return tb
