local province_utils = require "game.entities.province".Province

local demography_effects = require "game.raws.effects.demography"

local effects = {}

---comment
---@param character Character
---@param province Province
function effects.travel(character, province)
	---@type Province
	local initial_province = PROVINCE(character)

	province_utils.transfer_character(character, province)

	local leader_of = DATA.get_warband_leader_from_leader(character)

	if leader_of ~= INVALID_ID then
		local warband = DATA.warband_leader_get_warband(leader_of)

		local location = DATA.get_warband_location_from_warband(warband)
		DATA.warband_location_set_location(location, province)

		DATA.for_each_warband_unit_from_warband(warband, function (item)
			local pop = DATA.warband_unit_get_unit(item)

			demography_effects.fire_pop(character)
			province_utils.transfer_pop(pop, province)
		end)
	end

	if WORLD.player_character == character then
		WORLD:emit_notification('I had arrived to ' .. PROVINCE_NAME(province))
	end
	if WORLD:does_player_see_realm_news(PROVINCE_REALM(province)) then
		WORLD:emit_notification(NAME(character) .. " had arrived to " .. PROVINCE_NAME(province))
	end
end

return effects