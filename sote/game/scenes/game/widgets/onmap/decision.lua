local ut = require "game.ui-utils"

---comment
---@param gam GameScene
---@param tile Tile
---@param rect Rect
local function macrodecision(gam, tile, rect)
	---@type DecisionCharacterProvince
	local decision = gam.selected.macrodecision
	if decision  == nil then
		return
	end

	local player = WORLD.player_character
	if player == nil then
		return
	end
	local province = tile.province

	if not decision.clickable(player, province) then
		return
	end

	local tooltip = decision.tooltip(player, province)
	local available = decision.available(player, province)

	if ut.icon_button(ASSETS.icons["circle.png"], rect, tooltip, available and decision.pretrigger(player)) then
		return function ()
			decision.effect(player, province)
		end
	end
end

return macrodecision