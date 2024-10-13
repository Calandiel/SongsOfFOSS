local ui = require "engine.ui";
local uit = require "game.ui-utils"
local tile_utils = require "game.entities.tile"
local province_utils = require "game.entities.province".Province
local building_type_tooltip = require "game.raws.building-types".get_tooltip

local economic_effects = require "game.raws.effects.economy"
local EconomicValues = require "game.raws.values.economy"
local pv = require "game.raws.values.politics"

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
---@param owner POP
---@param overseer POP
---@param public_flag boolean
local function construction_button(gam, rect, building_type, tile_id, owner, overseer, public_flag)
	local character = WORLD.player_character
	if character == INVALID_ID then
		return
	end
	local realm = REALM(character)
	if realm == INVALID_ID then
		return
	end

	local local_province = tile_utils.province(tile_id)

	local is_public_project = public_flag
	if owner == INVALID_ID then
		is_public_project = true
	end

	local funds = 0
	if is_public_project then
		funds = DATA.realm_get_budget_treasury(realm)
	else
		funds = DATA.pop_get_savings(owner)
	end

	local success, reason = province_utils.can_build(
		local_province,
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

			WORLD:emit_notification("Tile improvement complete (" .. DATA.building_type_get_name(building_type) .. ")")

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
	local icon = DATA.building_type_get_icon(building_type)
	local name = DATA.building_type_get_name(building_type)

	ui.tooltip(building_type_tooltip(building_type), rect)
	---@type Rect
	local r = rect
	local im = r:subrect(0, 0, rect.height, rect.height, "left", "up")
	ui.image(ASSETS.get_icon(icon), im)
	r.x = r.x + rect.height
	r.width = r.width - rect.height * 4

	uit.data_entry(name, "", r)

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
	local realm = province_utils.realm(province)

	if (WORLD.player_character ~= INVALID_ID) and WORLD:player_province() == province then
		construction_button(gam, r, building_type, tile_id, WORLD.player_character, WORLD.player_character, false)
	end

	r.x = r.x + rect.height
	r.width = rect.height
	if WORLD:does_player_control_realm(realm) then
		construction_button(gam, r, building_type, tile_id, INVALID_ID, pv.overseer(realm), true)
	end
end

return btb
