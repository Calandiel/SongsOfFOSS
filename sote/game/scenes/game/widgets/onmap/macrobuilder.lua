local ui = require "engine.ui"
local ut = require "game.ui-utils"


local ev = require "game.raws.values.economical"
local ee = require "game.raws.effects.economic"
local pv = require "game.raws.values.political"


---comment
---@param gam GameScene
---@param tile Tile
---@param rect Rect
---@param x number
---@param y number
---@param size number
---@return function|nil
local function macrobuilder(gam, tile, rect, x, y, size)
	local player_character = WORLD.player_character
	if player_character == nil then
		return
	end
	if player_character.province ~= tile:province() then
		return
	end
	---@type BuildingType
	local building_type = gam.selected.macrobuilder_building_type

	if building_type then
		local public_flag = false
		local funds = player_character.savings
		---@type Character | nil
		local owner = player_character
		---@type Character | nil
		local overseer = player_character

		if gam.macrobuilder_public_mode then
			overseer = pv.overseer(tile:province().realm)
			public_flag = true
			funds = player_character.realm.budget.treasury
			owner = nil
		end

		if not tile:province():can_build(9999, building_type, overseer, public_flag) then
			return
		end

		local icon = building_type.icon
		local name = building_type.name

		local amount = 0

		for _, building in pairs(tile:province().buildings) do
			if building.type == building_type then
				amount = amount + 1
			end
		end

		local unit = size * 1.5

		local rect = ui.rect(
			x - unit / 2,
			y - unit / 2,
			unit,
			unit
		)

		local construction_cost = ev.building_cost(
			building_type,
			overseer,
			public_flag
		)

		local icon_rect = rect:subrect(0, 0, unit, unit, "left", "up")
		local count_rect = rect:subrect(0, unit, unit, unit / 2, "left", "up")

		if funds < construction_cost then
			ut.icon_button(ASSETS.icons["cancel.png"], icon_rect, "Not possible to build", false)
		elseif ut.icon_button(ASSETS.get_icon(icon), icon_rect, "Build " .. name .. " for " .. ut.to_fixed_point2(construction_cost) .. MONEY_SYMBOL) then
			return function()
				ee.construct_building_with_payment(
					building_type,
					tile:province(),
					owner,
					overseer,
					public_flag
				)
			end
		end

		ut.integer_entry("", amount, count_rect, "Current amount of buildings")
	end
end

return macrobuilder
