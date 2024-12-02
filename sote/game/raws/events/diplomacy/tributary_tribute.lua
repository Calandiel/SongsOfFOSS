local Event = require "game.raws.events"
local economic_effects = require "game.raws.effects.economy"

---@class (exact) TributeCollection
---@field origin Realm
---@field target Realm
---@field travel_time number
---@field tribute number
---@field trade_goods_tribute table<trade_good_id, number?>

return function()
	Event:new {
		name = "tribute-collection-1",
		automatic = false,
		base_probability = 0,
		event_background_path = "",
		fallback = function(self, associated_data)

		end,
		on_trigger = function(self, root, associated_data)
			---@type TributeCollection
			associated_data = associated_data

			local can_collect_wealth = false
			local can_collect_goods = false

			local is_subject = false

			local overlord = associated_data.origin
			local subject = associated_data.target

			DATA.for_each_realm_subject_relation_from_subject(associated_data.target, function (item)
				local candidate = DATA.realm_subject_relation_get_overlord(item)

				if candidate ~= overlord then
					return
				end

				is_subject = true

				can_collect_goods = DATA.realm_subject_relation_get_goods_transfer(item)
				can_collect_wealth = DATA.realm_subject_relation_get_wealth_transfer(item)
			end)

			if is_subject then
				if can_collect_wealth then
					associated_data.tribute = economic_effects.collect_tribute(root, associated_data.target)
				end

				if can_collect_goods then
					DATA.for_each_trade_good(function (item)
						local tribute = DATA.realm_get_resources(subject, item) * 0.5
						associated_data.trade_goods_tribute[item] = tribute

						-- currently is cosmetic, so we do not deduct goods from subject
					end)
				end
			end

			WORLD:emit_action("tribute-collection-2", root, associated_data, associated_data.travel_time, true)
		end,
	}

	Event:new {
		name = "tribute-collection-2",
		automatic = false,
		base_probability = 0,
		event_background_path = "",
		fallback = function(self, associated_data)

		end,
		on_trigger = function(self, root, associated_data)
			---@type TributeCollection
			associated_data = associated_data
			economic_effects.return_tribute_home(root, associated_data.origin, associated_data.tribute)
			UNSET_BUSY(root)
		end,
	}
end
