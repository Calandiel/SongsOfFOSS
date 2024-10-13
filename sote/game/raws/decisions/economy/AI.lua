local Decision = require "game.raws.decisions"

local economic_values = require "game.raws.values.economy"
local pop_utils = require "game.entities.pop".POP

return function ()
	Decision.Character:new {
		name = 'buy-something',
		ui_name = "(AI) Buy some goods",
		tooltip = function (root, primary_target)
			if DATA.pop_get_busy(root) then
				return "You are too busy to consider it."
			end
			return "Buy some goods on the local market"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1 / 4 ,
		pretrigger = function(root)
			if DATA.pop_get_busy(root) then return false end
			if WORLD:is_player(root) then
				return false
			end
			if DATA.pop_get_savings(root) < 5 then
				return false
			end
			if not pop_utils.has_trait(root, TRAIT.TRADER) then
				return false
			end
			return true
		end,
		clickable = function(root)
			if WORLD:is_player(root) then
				return false
			end
			return true
		end,
		available = function(root)
			if DATA.pop_get_busy(root) then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if pop_utils.has_trait(root, TRAIT.TRADER) then
				return 1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			WORLD:emit_immediate_event('buy-goods', root, {})
		end
	}

	Decision.Character:new {
		name = 'update-price-beliefs',
		ui_name = "(AI) Check local prices",
		tooltip = function (root, primary_target)
			if DATA.pop_get_busy(root) then
				return "You are too busy to consider it."
			end
			return "???"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1 / 2 ,
		pretrigger = function(root)
			if DATA.pop_get_busy(root) then return false end
			if WORLD:is_player(root) then
				return false
			end
			if not pop_utils.has_trait(root, TRAIT.TRADER) then
				return false
			end
			return true
		end,
		clickable = function(root)
			if WORLD:is_player(root) then
				return false
			end
			return true
		end,
		available = function(root)
			if DATA.pop_get_busy(root) then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if pop_utils.has_trait(root, TRAIT.TRADER) then
				return 1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			local function update_belief(trade_good)
				local price = economic_values.get_local_price(PROVINCE(root), trade_good)
				local prev_belief = DATA.pop_get_price_memory(root, trade_good)
				DATA.pop_set_price_memory(root, trade_good, prev_belief * 3 / 4 + price / 4)
			end
			DATA.for_each_trade_good(update_belief)
		end
	}

	Decision.Character:new {
		name = 'sell-something',
		ui_name = "(AI) Sell some goods",
		tooltip = function (root, primary_target)
			if DATA.pop_get_busy(root) then
				return "You are too busy to consider it."
			end
			return "Sell some goods on the local market"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1 / 4,
		pretrigger = function(root)
			if DATA.pop_get_busy(root) then return false end
			if WORLD:is_player(root) then
				return false
			end
			if not pop_utils.has_trait(root, TRAIT.TRADER) then
				return false
			end
			return true
		end,
		clickable = function(root)
			if WORLD:is_player(root) then
				return false
			end
			return true
		end,
		available = function(root)
			if DATA.pop_get_busy(root) then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if pop_utils.has_trait(root, TRAIT.TRADER) then
				return 1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			WORLD:emit_immediate_event('sell-goods', root, {})
		end
	}
end