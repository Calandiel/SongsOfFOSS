local ui = require "engine.ui"
local ut = require "game.ui-utils"

local tile_utils = require "game.entities.tile"
local province_utils = require "game.entities.province".Province

local ev = require "game.raws.values.economy"
local ee = require "game.raws.effects.economy"
local pv = require "game.raws.values.politics"


---comment
---@param gam GameScene
---@param tile_id tile_id
---@param rect Rect
---@param x number
---@param y number
---@param size number
---@return function|nil
local function macrobuilder(gam, tile_id, rect, x, y, size)
	local player_character = WORLD.player_character
	if player_character == INVALID_ID then
		return
	end
	local province = tile_utils.province(tile_id)
	if PROVINCE(player_character) ~= province then
		return
	end
	---@type BuildingType
	local building_type = gam.selected.macrobuilder_building_type

	if building_type ~= INVALID_ID then
		local public_flag = false
		local funds = SAVINGS(player_character)
		---@type Character
		local owner = player_character
		---@type Character
		local overseer = player_character

		local realm = PROVINCE_REALM(province)

		if gam.macrobuilder_public_mode then
			overseer = pv.overseer(realm)
			public_flag = true
			funds = DATA.realm_get_budget_treasury(REALM(player_character))
			owner = INVALID_ID
		end

		if not province_utils.can_build(province, 9999, building_type, overseer, public_flag) then
			return
		end

		local icon = DATA.building_type_get_icon(building_type)
		local name = DATA.building_type_get_name(building_type)

		local amount = 0


		DATA.for_each_building_location_from_location(province, function (item)
			local building = DATA.building_location_get_building(item)
			local btype = DATA.building_get_current_type(building)
			if btype == building_type then
				amount = amount + 1
			end
		end)

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
					province,
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
