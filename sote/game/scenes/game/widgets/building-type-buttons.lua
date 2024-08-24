local ui = require "engine.ui";
local uit = require "game.ui-utils"
local tile_utils = require "game.entities.tile"

local economic_effects = require "game.raws.effects.economic"
local EconomicValues = require "game.raws.values.economical"
local pv = require "game.raws.values.political"

---comment
---@param rect Rect
---@param reason BuildingAttemptFailureReason?
---@param funds number
---@param cost number
local function validate_building_tooltip(rect, reason, funds, cost)
	local icon = nil
	local tooltip = ""
	if reason == "unique_duplicate" then
		icon = ASSETS.icons["triangle-target.png"]
		tooltip = "There can be at most a single building of this type per province!"
	elseif reason == "not_enough_funds" then
		icon = ASSETS.icons["uncertainty.png"]
		tooltip = "Not enough funds: "
			.. uit.to_fixed_point2(funds)
			.. " / "
			.. uit.to_fixed_point2(cost)
			.. MONEY_SYMBOL
	elseif reason == "missing_local_resources" then
		icon = ASSETS.icons["triangle-target.png"]
		tooltip = "Missing local resources!"
	end

	if icon then
		uit.icon_button(
			icon,
			rect,
			tooltip,
			false,
			false
		)
	end
end

---comment
---@param gam table
---@param rect Rect
---@param building_type BuildingType
---@param tile_id tile_id
---@param owner POP?
---@param overseer POP?
---@param public_flag boolean
local function construction_button(gam, rect, building_type, tile_id, owner, overseer, public_flag)
	local character = WORLD.player_character
	if character == nil then
		return
	end
	local realm = character.realm
	if realm == nil then
		return
	end

	local funds = 0
	if public_flag or owner == nil then
		funds = realm.budget.treasury
	else
		funds = owner.savings
	end

	local success, reason = tile_utils.province(tile_id):can_build(
		funds,
		building_type,
		overseer,
		public_flag
	)

	local construction_cost = EconomicValues.building_cost(
		building_type,
		overseer,
		public_flag
	)

	if not success then
		validate_building_tooltip(rect, reason, funds, construction_cost)
	else
		local tooltip = "(private)"
		if public_flag then
			tooltip = "(public)"
		end
		if uit.icon_button(
			ASSETS.icons["hammer-drop.png"],
			rect,
			"Build " .. tooltip .. " (" .. tostring(construction_cost) .. MONEY_SYMBOL .. ")")
		then
			economic_effects.construct_building_with_payment(
				building_type,
				tile_utils.province(tile_id),
				owner,
				overseer,
				public_flag
			)

			WORLD:emit_notification("Tile improvement complete (" .. building_type.name .. ")")

			if gam.selected.building_type == building_type then
				gam.selected.building_type = building_type
				gam.refresh_map_mode(true)
			end
		end
	end
end

local btb = {}
---comment
---@param gam GameScene
---@param rect Rect
---@param building_type BuildingType
---@param tile_id tile_id
function btb.building_type_buttons(gam, rect, building_type, tile_id)
	ui.tooltip(building_type:get_tooltip(), rect)
	---@type Rect
	local r = rect
	local im = r:subrect(0, 0, rect.height, rect.height, "left", "up")
	ui.image(ASSETS.get_icon(building_type.icon), im)
	r.x = r.x + rect.height
	r.width = r.width - rect.height * 4

	uit.data_entry(building_type.name, "", r)

	r.x = r.x + r.width
	r.width = rect.height
	if uit.icon_button(ASSETS.icons["mesh-ball.png"], r,
			"Show local efficiency on map") then
		CACHED_BUILDING_TYPE = building_type
		gam.update_map_mode("selected_building_type_efficiency")
		gam.refresh_map_mode(true)
	end

	r.x = r.x + rect.height
	r.width = rect.height

	local province = tile_utils.province(tile_id)

	if (WORLD.player_character) and WORLD.player_character.province == province then
		construction_button(gam, r, building_type, tile_id, WORLD.player_character, WORLD.player_character, false)
	end

	r.x = r.x + rect.height
	r.width = rect.height
	if WORLD:does_player_control_realm(province.realm) then
		construction_button(gam, r, building_type, tile_id, nil, pv.overseer(province.realm), true)
	end
end

return btb
