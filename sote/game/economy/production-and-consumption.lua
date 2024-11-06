local province_utils = require "game.entities.province".Province
local economic_effects = require "game.raws.effects.economy"

local pro = {}

function pro.run_fast()
	DATA.for_each_province(function (item)
		DATA.province_set_infrastructure_efficiency(item, province_utils.get_infrastructure_efficiency(item));
	end)

	DCON.update_economy()

	DATA.for_each_pop(function (item)
		local pending = DATA.pop_get_pending_economy_income(item);
		economic_effects.add_pop_savings(item, pending, ECONOMY_REASON.TRADE)
	end)
end

return pro