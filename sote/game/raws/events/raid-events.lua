local tabb = require "engine.table"
local Event = require "game.raws.events"
local event_utils = require "game.raws.events._utils"

local realm_entity = require "game.entities.realm"
local warband_utils = require "game.entities.warband"
local province_utils = require "game.entities.province".Province
local realm_utils = require "game.entities.realm".Realm
local army_utils = require "game.entities.army"

local ut = require "game.ui-utils"


local ev = require "game.raws.values.economy"
local AI_VALUE = require "game.raws.values.ai"
local pv = require "game.raws.values.politics"

local economic_effects = require "game.raws.effects.economy"
local de = require "game.raws.effects.diplomacy"
local me = require "game.raws.effects.military"
local pe = require "game.raws.effects.politics"
local messages = require "game.raws.effects.messages"


---@class (exact) PatrolData
---@field defender Character
---@field origin Realm
---@field target Province
---@field travel_time number
---@field patrol table<Warband, Warband>

---@class (exact) RaidData
---@field raider Character
---@field origin Realm
---@field target Province
---@field travel_time number
---@field army Army

---@class (exact) AttackData
---@field raider Character
---@field origin Realm
---@field target Province
---@field travel_time number
---@field army Army

---@class (exact) RaidResultSuccess
---@field raider Character
---@field origin Realm
---@field losses number
---@field army Army
---@field loot number
---@field target Province

---@class (exact) RaidResultFail
---@field raider Character
---@field origin Realm
---@field losses number
---@field army Army
---@field target Province

---@class (exact) RaidResultRetreat
---@field raider Character
---@field origin Realm
---@field army Army
---@field target Province


local function load()
	Event:new {
		name = "patrol-province",
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		on_trigger = function(self, root, associated_data)
			---@type PatrolData
			associated_data = associated_data
			local realm_leader = associated_data.defender

			DATA.province_inc_mood(associated_data.target, 0.025)
			if WORLD:does_player_see_realm_news(PROVINCE_REALM(associated_data.target)) then
				WORLD:emit_notification("Several of our warbands had finished patrolling " ..
				PROVINCE_NAME(associated_data.target) .. ". Local people feel safety")
			end

			local total_patrol_size = 0
			for _, w in pairs(associated_data.patrol) do
				DATA.warband_set_current_status(w, WARBAND_STATUS.IDLE)
				local size = warband_utils.size(w)
				total_patrol_size = total_patrol_size + size
			end
			if total_patrol_size > 0 then
				local reward = 0
				local max_reward =  DATA.realm_get_quests_patrol(REALM(root))[associated_data.target]
				if max_reward then
					reward = math.min(max_reward, total_patrol_size)
					DATA.realm_get_quests_patrol(REALM(root))[associated_data.target] = max_reward - reward
				end

				for _, w in pairs(associated_data.patrol) do
					local size = warband_utils.size(w)
					DATA.warband_inc_treasury(w, reward * size / total_patrol_size)
					assert(DATA.warband_get_treasury(w) == DATA.warband_get_treasury(w),
						"NAN TREASURY FROM PATROL SUCCESS"
							.. "\n reward: "
							.. tostring(reward)
							.. "\n size: "
							.. tostring(size)
							.. "\n total_patrol_size: "
							.. tostring(total_patrol_size)
					)
				end
			end
		end
	}


	Event:new {
		name = "request-tribute-raid",
		event_text = function(self, character, associated_data)
			---@type Realm
			associated_data = associated_data
			local name = REALM_NAME(associated_data)

			local my_warlords, my_power = pv.military_strength(character)
			local my_warlords_ready, my_power_ready = pv.military_strength_ready(character)
			local their_warlords, their_power = pv.military_strength(LEADER(associated_data))

			local strength_estimation_string =
				"On my side there are "
				.. my_warlords
				.. " warlords with total strength of "
				.. my_power
				.. " warriors in total."
				.. "Currently, I have "
				.. my_warlords_ready
				.. " warlords with total strength of "
				.. my_power_ready
				.. " ready to join my campaign."
				.. " Enemy's potential forces consist of "
				.. their_warlords
				.. " warlords with total size of "
				.. their_power
				.. " warriors."

			return " We are planning the invasion of "
				.. name
				.. ". "
				.. strength_estimation_string
				.. " What should I do?"
		end,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, character)
			return false
		end,
		on_trigger = function(self, character, associated_data)
			---@type Realm
			associated_data = associated_data
			if WORLD.player_character == character then
				WORLD:emit_notification("I was asked to start paying tribute to " .. associated_data.name)
			end
		end,
		options = function(self, character, associated_data)
			assert(associated_data ~= nil, "INVALID ASSOCIATED DATA IN EVENT")

			---@type Realm
			local target_realm = associated_data

			-- character assumes that realm will gain money at least for a year
			local gain_of_money = 0
			if target_realm then
				gain_of_money = ev.potential_monthly_tribute_size(target_realm) * 12
			end

			if DEAD(character) then
				return event_utils.dead_options
			end

			local my_warlords, my_power = pv.military_strength(character)
			local my_warlords_ready, my_power_ready = pv.military_strength_ready(character)
			local their_warlords, their_power = pv.military_strength(LEADER(target_realm))

			return {
				{
					text = "Forward!",
					tooltip = "Launch the invasion",
					viable = function() return true end,
					outcome = function()
						local realm = REALM(character)

						local army = me.gather_loyal_army_attack(character)
						if army == nil then
							if character == WORLD.player_character then
								WORLD:emit_notification("I had launched the invasion of " .. REALM_NAME(target_realm))
							end
						else
							local function callback(army, travel_time)
								---@type AttackData
								local data = {
									raider = character,
									origin = realm,
									target = CAPITOL(target_realm),
									travel_time = travel_time,
									army = army
								}

								WORLD:emit_action('request-tribute-attack', character, data, travel_time, true)
							end

							me.send_army(army, PROVINCE(character), CAPITOL(target_realm), callback)

							if character == WORLD.player_character then
								WORLD:emit_notification("I had launched the invasion of " .. REALM_NAME(target_realm))
							end
						end
					end,

					ai_preference = function()
						local base_value = AI_VALUE.generic_event_option(character, LEADER(target_realm), 0, {
							aggression = true,
						})()

						base_value = base_value + AI_VALUE.money_utility(character) * gain_of_money
						base_value = base_value + (my_power_ready - their_power) * 20
						if my_power_ready <= 0 then
							base_value = 0
						end
						return base_value
					end
				},
				{
					text = "Wait for 10 days",
					tooltip = "Wait for our warlords to gather.",
					viable = function() return true end,
					outcome = function()
						if WORLD.player_character == character then
							WORLD:emit_notification("I have decided to wait. We need more forces.")
						end

						WORLD:emit_event('request-tribute-raid', character, target_realm, 10)
					end,
					ai_preference = function()
						local base_value = AI_VALUE.generic_event_option(character, LEADER(target_realm), 0, {
							aggression = true,
						})()

						base_value = base_value + AI_VALUE.money_utility(character) * gain_of_money
						base_value = base_value + (my_power - their_power) * 15
						return base_value
					end
				},
				{
					text = "Back down",
					tooltip = "We are not ready to fight",
					viable = function() return true end,
					outcome = function()
						if WORLD.player_character == character then
							WORLD:emit_notification("I decided to not attack " .. NAME(LEADER(target_realm)))
						end
						UNSET_BUSY(character)
					end,
					ai_preference = AI_VALUE.generic_event_option(character, LEADER(target_realm), 0, {})
				}
			}
		end
	}

	Event:new {
		name = "request-tribute-attack",
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		on_trigger = function(self, root, associated_data)
			---@type AttackData
			associated_data = associated_data

			local raider = associated_data.raider
			local target = associated_data.target
			local travel_time = associated_data.travel_time
			local army = associated_data.army

			local province = target
			local realm = PROVINCE_REALM(province)

			if realm == INVALID_ID then
				-- The province doesn't have a realm
				return
			end

			-- Battle time!

			-- spot test
			-- it's an open attack, so our visibility is multiplied by 10
			local spot_test = province_utils.army_spot_test(province, army, 10)

			-- First, raise the defending army.
			local def = realm_utils.raise_local_army(realm, province)
			local attack_succeed, attack_losses, def_losses = me.attack(army, def, spot_test)
			realm_utils.disband_army(realm, def) -- disband the army after battle

			-- Message handling
			messages.tribute_raid(raider, PROVINCE_REALM(province), attack_succeed, attack_losses, def_losses)

			-- setting tributary
			if attack_succeed then
				de.set_tributary(REALM(raider), PROVINCE_REALM(target))
				WORLD:emit_action("request-tribute-army-returns-success", raider, army, travel_time, true)
			else
				WORLD:emit_action("request-tribute-army-returns-fail", raider, army, travel_time, true)
			end
		end,
	}

	Event:new {
		name = "request-tribute-army-returns-success",
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		on_trigger = function(self, root, associated_data)
			local realm = REALM(root)

			---@type Army
			local army = associated_data

			if realm == nil then
				return
			end

			DATA.province_inc_mood(CAPITOL(realm), 0.05)
			pe.small_popularity_boost(LEADER(realm), realm)

			realm_utils.disband_army(realm, army)
			DATA.realm_set_prepare_attack_flag(realm, false)
			messages.tribute_raid_success(realm, PROVINCE_REALM(DATA.army_get_destination(army)))
			WORLD:emit_event('request-tribute-army-returns-success-notification', root, army)

			UNSET_BUSY(root)
		end,
	}

	event_utils.notification_event(
		"request-tribute-army-returns-success-notification",
		function(self, character, associated_data)
			---@type Army
			local army = associated_data
			return "We succeeded in enforcing tribute on " .. REALM_NAME(PROVINCE_REALM(DATA.army_get_destination(army)))
		end,
		function(root, associated_data)
			return "Great!"
		end,
		function(root, associated_data)
			return ""
		end
	)

	Event:new {
		name = "request-tribute-army-returns-fail",
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		on_trigger = function(self, root, associated_data)
			local realm = REALM(root)

			---@type Army
			local army = associated_data

			if realm == INVALID_ID or not DATA.realm_get_exists(realm) then
				return
			end

			WORLD:emit_event("request-tribute-army-returns-fail-notification", root, army)
			messages.tribute_raid_fail(realm, PROVINCE_REALM(DATA.army_get_destination(army)))

			local mood = DATA.province_get_mood(CAPITOL(realm))
			DATA.province_set_mood(CAPITOL(realm), math.max(0, mood - 0.05))
			pe.small_popularity_decrease(LEADER(realm), realm)

			realm_utils.disband_army(realm, army)
			DATA.realm_set_prepare_attack_flag(realm, false)
			UNSET_BUSY(root)
		end,
	}

	event_utils.notification_event(
		"request-tribute-army-returns-fail-notification",
		function(self, character, associated_data)
			---@type Army
			local army = associated_data
			return "We failed to enforce tribute on " .. REALM_NAME(PROVINCE_REALM(DATA.army_get_destination(army)))
		end,
		function(root, associated_data)
			return "Whatever. We will succeed next time"
		end,
		function(root, associated_data)
			return ""
		end
	)


	Event:new {
		name = "covert-raid",
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		on_trigger = function(self, root, associated_data)
			---@type RaidData
			associated_data = associated_data

			local raider = associated_data.raider
			local target = associated_data.target
			local travel_time = associated_data.travel_time
			local army = associated_data.army
			local origin = associated_data.origin

			local retreat = false
			local success = true
			local losses = 0
			local province = target
			local realm = PROVINCE_REALM(province)

			if (not DEAD(raider)) and (realm ~= INVALID_ID) and province_utils.army_spot_test(province, army) then
				-- The army was spotted!
				if (love.math.random() < 0.5) and (province_utils.local_army_size(province) > 0) then
					-- Let's just return and do nothing
					success = false
					if realm and WORLD:does_player_see_realm_news(realm) then
						WORLD:emit_notification("Our neighbor, " ..
							NAME(raider) .. ", sent warriors to raid us but they were spotted and returned home.")
					end
					retreat = true
				else
					-- Battle time!
					-- First, raise the defending army.
					local def = realm_utils.raise_local_army(realm, province)
					local attack_succeed, attack_losses, def_losses = me.attack(army, def, true)
					realm_utils.disband_army(realm, def) -- disband the army after battle
					losses = attack_losses
					if attack_succeed then
						success = true
						if WORLD:does_player_see_realm_news(realm) then
							WORLD:emit_notification("Our neighbor, " ..
								NAME(raider) ..
								", sent warriors to raid us. We lost " ..
								tostring(def_losses) ..
								" warriors and our enemies lost " ..
								tostring(attack_losses) .. " and our province was looted.")
						end
					else
						success = false
						if WORLD:does_player_see_realm_news(realm) then
							WORLD:emit_notification("Our neighbor, " ..
								NAME(raider) ..
								", sent warriors to raid us. We lost " ..
								tostring(def_losses) ..
								" warriors and our enemies lost " ..
								tostring(attack_losses) .. ". We managed to fight off the aggressors.")
						end
					end
				end
			else
				-- The army wasn't spotted. Nothing to do!
				if DEAD(raider) then
					success = false
				else
					success = true
				end
			end
			if success then
				-- The army wasn't spotted!
				-- Therefore, it's a sure success.
				local max_loot = army_utils.loot_capacity(army)
				local real_loot = math.min(max_loot, DATA.province_get_local_wealth(province))
				economic_effects.change_local_wealth(province, -real_loot, ECONOMY_REASON.RAID)
				if realm and max_loot > real_loot then
					local leftover = max_loot - real_loot
					local potential_loot = ev.raidable_treasury(realm)
					local extra = math.min(potential_loot, leftover)
					economic_effects.change_treasury(realm, -extra, ECONOMY_REASON.RAID)
					real_loot = real_loot + extra
				end

				if real_loot ~= real_loot then
					error("NAN LOOT FROM RAID"
						.. "\n max_loot: "
						.. tostring(max_loot)
						.. "\n real_loot: "
						.. tostring(real_loot)
						.. "\n province.local_wealt: "
						.. tostring(DATA.province_get_local_wealth(province))
					)
				end

				pe.mood_shift_from_wealth_shift(province, -real_loot)
				if realm ~= INVALID_ID then
					pe.popularity_shift_scaled_with_wealth(raider, realm, -real_loot)
				end

				---@type RaidResultSuccess
				local success_data = {
					army = army,
					target = target,
					loot = real_loot,
					losses = losses,
					raider = raider,
					origin = origin
				}
				WORLD:emit_action("covert-raid-success", raider,
					success_data,
					travel_time, true)
				if WORLD:does_player_see_realm_news(realm) then
					WORLD:emit_notification("An unknown adversary raided our province " ..
						PROVINCE_NAME(province) ..
						" and stole " .. ut.to_fixed_point2(real_loot) .. MONEY_SYMBOL .. " worth of goods!")
				end
			else
				if retreat then
					---@type RaidResultRetreat
					local retreat_data = { army = army, target = target, raider = raider, origin = origin }
					WORLD:emit_action("covert-raid-retreat", raider, retreat_data,
						travel_time, true)
				else
					---@type RaidResultFail
					local retreat_data = { army = army, target = target, raider = raider, losses = losses, origin =
					origin }

					WORLD:emit_action("covert-raid-fail", raider,
						retreat_data,
						travel_time, true)
				end
			end
		end,
	}
	Event:new {
		name = "covert-raid-fail",
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		on_trigger = function(self, root, associated_data)
			---@type RaidResultFail
			associated_data = associated_data
			local raider = associated_data.raider
			local realm = associated_data.origin

			local target = associated_data.target
			local losses = associated_data.losses
			local army = associated_data.army

			realm_utils.disband_army(realm, army)
			pe.mood_minor_decrease(CAPITOL(realm))
			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification("Raid attempt of " .. NAME(raider) .. " in " ..
					PROVINCE_NAME(target) .. " failed. " .. tostring(losses) .. " warriors died. People are upset.")
			end
		end,
	}
	Event:new {
		name = "covert-raid-success",
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		trigger = function(self, root) return false end,
		on_trigger = function(self, root, associated_data)
			---@type RaidResultSuccess
			associated_data = associated_data
			local realm = associated_data.origin
			local loot = associated_data.loot
			local target = associated_data.target
			local losses = associated_data.losses
			local army = associated_data.army

			if loot ~= loot then
				error("NAN TREASURY FROM RAID SUCCESS"
				.. "\n realm: "
				.. tostring(REALM_NAME(realm))
				.. "\n loot: "
				.. tostring(loot)
				.. "\n target: "
				.. tostring(PROVINCE_NAME(target))
				.. "\n losses: "
				.. tostring(losses)
				.. "\n army: "
				.. tostring(tabb.size(DATA.get_army_membership_from_army(army)))
			)
			end

			local warbands = realm_utils.disband_army(realm, army)

			pe.mood_shift_from_wealth_shift(CAPITOL(realm), loot)

			-- popularity to raid participants
			local num_of_warbands = 0
			for _, w in pairs(warbands) do
				if WARBAND_LEADER(w) ~= INVALID_ID then
					pe.popularity_shift_scaled_with_wealth(WARBAND_LEADER(w), realm, loot / tabb.size(warbands))
					num_of_warbands = num_of_warbands + 1
				end
			end

			local max_reward = DATA.realm_get_quests_raid(realm)[target] or 0
			local quest_reward = math.min(loot * 0.5, max_reward)
			DATA.realm_get_quests_raid(realm)[target] = max_reward - quest_reward

			-- save total loot for future
			local total_loot = loot

			-- pay quest rewards to warband leaders
			for _, w in pairs(warbands) do
				if WARBAND_LEADER(w) ~= INVALID_ID then
					economic_effects.add_pop_savings(
						WARBAND_LEADER(w),
						quest_reward / num_of_warbands,
						ECONOMY_REASON.QUEST
					)
				end
			end

			-- half of loot goes to warbands
			for _, w in pairs(warbands) do
				DATA.warband_inc_treasury(w, loot * 0.5 / num_of_warbands)
				if DATA.warband_get_treasury(w) ~= DATA.warband_get_treasury(w) then
					error("NAN TREASURY FROM RAID SUCCESS"
					.. "\n loot: "
					.. tostring(loot)
					.. "\n num_of_warbands: "
					.. tostring(num_of_warbands)
				)
				end
			end
			loot = loot - loot * 0.5

			-- pay the remaining half of loot to local population
			economic_effects.change_local_wealth(CAPITOL(realm), loot, ECONOMY_REASON.RAID)

			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification("Our raid in " .. PROVINCE_NAME(target) .. " succeeded. Warriors brought home " ..
					ut.to_fixed_point2(total_loot) .. MONEY_SYMBOL .. " worth of loot. " ..
					' Warband leaders were additionally rewarded with ' ..
					ut.to_fixed_point2(quest_reward) .. MONEY_SYMBOL .. '. '
					.. tostring(losses) .. " warriors died.")
			end
		end,
	}

	Event:new {
		name = "covert-raid-retreat",
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		on_trigger = function(self, root, associated_data)
			---@type RaidResultRetreat
			associated_data = associated_data
			local realm = associated_data.origin

			local army = associated_data.army
			local target = associated_data.target
			pe.mood_minor_decrease(CAPITOL(realm))

			realm_utils.disband_army(realm, army)
			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification("Our raid attempt in " ..
					PROVINCE_NAME(target) .. " failed. We were spotted but our warriors returned home safely")
			end
		end,
	}
end

return load
