local tabb = require "engine.table"
local Event = require "game.raws.events"
local gift_cost_per_pop = require "game.gifting".gift_cost_per_pop
local tg = require "game.raws.raws-utils".trade_good
local ev = require "game.raws.raws-utils".event


local function load()
	local water = tg('water')
-- 	Event:new {
-- 		name = "lack-water",
-- 		event_text = function(self, realm, associated_data)
-- 			return [["Scoundrel!" cries a soon-to-be-visible woman, her voice indicating vigor despite advanced age.
-- "Scumbag! Whoreson!" She rapidly approaches you while somehow perfectly balancing a rather large water jug on her head.
-- "You don't care about us at all! We're all shriveling into nothing 'cause we can't get even a sip of water, and here you are sitting nice while we suffer!" Her dauntless discourtesy is quite remarkable, given her station and presence before you.
-- Lifting the jug from her cranium, "Here. This is for you. I don't need it any more since I can't ever fill it anyway!", she throws it onto the ground before you, shards flying into the air.
-- Clearly the scarcity of water has become so severe that a little old lady now feels such behavior appropriate. You cannot help but address her:]]
-- 		end,
-- 		event_background_path = "data/gfx/backgrounds/background.png",
-- 		automatic = true,
-- 		base_probability = 1 / 14,
-- 		trigger = function(self, root)
-- 			---@type Realm
-- 			local realm = root.province.realm
-- 			return (realm.capitol.local_production[water] or 0) < 0.5 * (realm.capitol.local_consumption[water] or 0)
-- 		end,
-- 		on_trigger = function(self, root)
-- 			---@type Realm
-- 			local realm = root.province.realm
-- 			WORLD:emit_event(self.name, root, {})
-- 		end,
-- 		options = function(self, root, associated_data)
-- 			---@type Realm
-- 			local realm = root.province.realm
-- 			return {
-- 				{
-- 					text = "You rude wench! I am aware of the issue and I'm making every effort to fix it. Shouting at me won't help anybody. I will take no special action at this moment.",
-- 					tooltip = "People should appreciate your efforts more.",
-- 					viable = function()
-- 						return true
-- 					end,
-- 					outcome = function()
-- 						if WORLD:does_player_control_realm(realm) then
-- 							WORLD:emit_notification("People are concerned that their rulers may prove unable to help them.")
-- 						end
-- 						realm.capitol.mood = realm.capitol.mood - 10
-- 					end,
-- 					ai_preference = function()
-- 						return 0.25
-- 					end
-- 				},
-- 				{
-- 					text = "I did not realize the situation was so dire. I will send help immediately!",
-- 					tooltip = "We need to do something!\n-- spend " ..
-- 						tostring(realm.capitol:population()) .. MONEY_SYMBOL .. " to help the family",
-- 					viable = function()
-- 						return realm.capitol:population() < realm.treasury
-- 					end,
-- 					outcome = function()
-- 						realm.capitol.mood = realm.capitol.mood - 2
-- 						realm.treasury = realm.treasury - realm.capitol:population()
-- 					end,
-- 					ai_preference = function()
-- 						return 0.65
-- 					end
-- 				},
-- 				{
-- 					text = "If you're so worried about it, then you fix the problem! I'm not interested in your thirst and I will not help you",
-- 					tooltip = "You have better things to do anyway.",
-- 					viable = function()
-- 						return true
-- 					end,
-- 					outcome = function()
-- 						if WORLD:does_player_control_realm(realm)then
-- 							WORLD:emit_notification("People heavily disapproved of your decision. Social unrest may soon become an issue.")
-- 						end
-- 						realm.capitol.mood = realm.capitol.mood - 20
-- 					end,
-- 					ai_preference = function()
-- 						return 0.07
-- 					end
-- 				},
-- 			}
-- 		end
-- 	}
end

return load
