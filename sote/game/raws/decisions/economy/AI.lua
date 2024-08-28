local Decision = require "game.raws.decisions"
local TRAIT = require "game.raws.traits.generic"

local economic_values = require "game.raws.values.economical"

return function ()
	Decision.Character:new {
		name = 'buy-something',
		ui_name = "(AI) Buy some goods",
		tooltip = function (root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			return "Buy some goods on the local market"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1 / 4 ,
		pretrigger = function(root)
			if root.busy then return false end
			if WORLD:is_player(root) then
				return false
			end
			if root.savings < 5 then
				return false
			end
			if (not root.traits[TRAIT.TRADER]) then
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
			if root.busy then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.traits[TRAIT.TRADER] then
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
			if root.busy then
				return "You are too busy to consider it."
			end
			return "???"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1 / 2 ,
		pretrigger = function(root)
			if root.busy then return false end
			if WORLD:is_player(root) then
				return false
			end
			if (not root.traits[TRAIT.TRADER]) then
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
			if root.busy then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.traits[TRAIT.TRADER] then
				return 1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			local function update_belief(trade_good)
				local price = economic_values.get_local_price(root.province, trade_good)
				if root.price_memory[trade_good] == nil then
					root.price_memory[trade_good] = price
				else
					if WORLD.player_character ~= root then
						root.price_memory[trade_good] = root.price_memory[trade_good] * (3 / 4) + price * (1 / 4)
					end
				end
			end
			DATA.for_each_trade_good(update_belief)
		end
	}

	Decision.Character:new {
		name = 'sell-something',
		ui_name = "(AI) Sell some goods",
		tooltip = function (root, primary_target)
			if root.busy then
				return "You are too busy to consider it."
			end
			return "Sell some goods on the local market"
		end,
		sorting = 2,
		primary_target = 'none',
		secondary_target = 'none',
		base_probability = 1 / 4,
		pretrigger = function(root)
			if root.busy then return false end
			if WORLD:is_player(root) then
				return false
			end
			if (not root.traits[TRAIT.TRADER]) then
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
			if root.busy then return false end
			return true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.traits[TRAIT.TRADER] then
				return 1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			WORLD:emit_immediate_event('sell-goods', root, {})
		end
	}
end