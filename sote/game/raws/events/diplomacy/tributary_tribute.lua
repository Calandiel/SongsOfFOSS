local Event = require "game.raws.events"
local economic_effects = require "game.raws.effects.economic"

---@class (exact) TributeCollection
---@field origin Realm
---@field target Realm
---@field travel_time number
---@field tribute number
---@field trade_goods_tribute table<TradeGoodReference, number?>

return function()
	Event:new {
		name = "tribute-collection-1",
		automatic = false,
		on_trigger = function(self, root, associated_data)
			---@type TributeCollection
			associated_data = associated_data

			if associated_data.origin.tributaries[associated_data.target] then
				local status = associated_data.origin.tributary_status[associated_data.target]

				if status.wealth_transfer then
					associated_data.tribute = economic_effects.collect_tribute(root, associated_data.target)
				end

				if status.goods_transfer then
					for _, item in pairs(RAWS_MANAGER.trade_goods_list) do
						local tribute = (associated_data.target.resources[item] or 0) * 0.5
						associated_data.trade_goods_tribute[item] = tribute
					end
				end
			end

			WORLD:emit_action("tribute-collection-2", root, associated_data, associated_data.travel_time, true)
		end,
	}

	Event:new {
		name = "tribute-collection-2",
		automatic = false,
		on_trigger = function(self, root, associated_data)
			---@type TributeCollection
			associated_data = associated_data
			economic_effects.return_tribute_home(root, associated_data.origin, associated_data.tribute)
			root.busy = false
		end,
	}
end
