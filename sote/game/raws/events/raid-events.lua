local tabb = require "engine.table"
local Event = require "game.raws.events"
local event_utils = require "game.raws.events._utils"

local realm_entity = require "game.entities.realm"

local economic_effects = require "game.raws.effects.economy"
local ev = require "game.raws.values.economy"
local ut = require "game.ui-utils"


local AI_VALUE = require "game.raws.values.ai"

local pv = require "game.raws.values.politics"
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

			associated_data.target.mood = associated_data.target.mood + 0.025
			if WORLD:does_player_see_realm_news(associated_data.target.realm) then
				WORLD:emit_notification("Several of our warbands had finished patrolling " ..
				associated_data.target.name .. ". Local people feel safety")
			end

			local total_patrol_size = 0
			for _, w in pairs(associated_data.patrol) do
				w.status = 'idle'
				total_patrol_size = total_patrol_size + w:size()
			end
			if total_patrol_size > 0 then
				local reward = 0
				if root.realm.quests_patrol[associated_data.target] then
					reward = math.min(root.realm.quests_patrol[associated_data.target] or 0, total_patrol_size)
				end
				root.realm.quests_patrol[associated_data.target] = (root.realm.quests_patrol[associated_data.target] or 0) -
				reward

				for _, w in pairs(associated_data.patrol) do
					w.treasury = w.treasury + reward * w:size() / total_patrol_size
					if w.treasury ~= w.treasury then
						error("NAN TREASURY FROM PATROL SUCCESS"
							.. "\n reward: "
							.. tostring(reward)
							.. "\n size: "
							.. tostring(w:size())
							.. "\n total_patrol_size: "
							.. tostring(total_patrol_size)
						)
					end
				end
			end
		end
	}


	Event:new {
		name = "request-tribute-raid",
		event_text = function(self, character, associated_data)
			---@type Realm
			associated_data = associated_data
			local name = associated_data.name

			local my_warlords, my_power = pv.military_strength(character)
			local my_warlords_ready, my_power_ready = pv.military_strength_ready(character)
			local their_warlords, their_power = pv.military_strength(associated_data.leader)

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

			if character.dead then
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
						local realm = character.realm

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

							me.send_army(army, character.province, CAPITOL(target_realm), callback)

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

			if not realm then
				-- The province doesn't have a realm
				return
			end

			-- Battle time!

			-- spot test
			-- it's an open attack, so our visibility is multiplied by 10
			local spot_test = province:army_spot_test(army, 10)

			-- First, raise the defending army.
			local def = realm:raise_local_army(province)
			local attack_succeed, attack_losses, def_losses = army:attack(province, spot_test, def)
			realm:disband_army(def) -- disband the army after battle

			-- Message handling
			messages.tribute_raid(raider, PROVINCE_REALM(province), attack_succeed, attack_losses, def_losses)

			-- setting tributary
			if attack_succeed then
				de.set_tributary(raider.realm, target.realm)
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
			local realm = root.realm

			---@type Army
			local army = associated_data

			if realm == nil then
				return
			end

			realm.capitol.mood = realm.capitol.mood + 0.05
			pe.small_popularity_boost(realm.leader, realm)

			realm:disband_army(army)
			realm.prepare_attack_flag = false
			messages.tribute_raid_success(realm, army.destination.realm)
			WORLD:emit_event('request-tribute-army-returns-success-notification', root, army)

			UNSET_BUSY(root)
		end,
	}

	event_utils.notification_event(
		"request-tribute-army-returns-success-notification",
		function(self, character, associated_data)
			---@type Army
			local army = associated_data
			return "We succeeded in enforcing tribute on " .. army.destination.realm.name
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
			local realm = root.realm

			---@type Army
			local army = associated_data

			if realm == nil or not realm.exists then
				return
			end

			WORLD:emit_event("request-tribute-army-returns-fail-notification", root, army)
			messages.tribute_raid_fail(realm, army.destination.realm)

			realm.capitol.mood = math.max(0, realm.capitol.mood - 0.05)
			pe.small_popularity_decrease(realm.leader, realm)
			realm:disband_army(army)
			realm.prepare_attack_flag = false
			UNSET_BUSY(root)
		end,
	}

	event_utils.notification_event(
		"request-tribute-army-returns-fail-notification",
		function(self, character, associated_data)
			---@type Army
			local army = associated_data
			return "We failed to enforce tribute on " .. army.destination.realm.name
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

			if (not raider.dead) and (realm) and (province:army_spot_test(army)) then
				-- The army was spotted!
				if (love.math.random() < 0.5) and (province:local_army_size() > 0) then
					-- Let's just return and do nothing
					success = false
					if realm and WORLD:does_player_see_realm_news(realm) then
						WORLD:emit_notification("Our neighbor, " ..
							raider.name .. ", sent warriors to raid us but they were spotted and returned home.")
					end
					retreat = true
				else
					-- Battle time!
					-- First, raise the defending army.
					local def = realm:raise_local_army(province)
					local attack_succeed, attack_losses, def_losses = army:attack(province, true, def)
					realm:disband_army(def) -- disband the army after battle
					losses = attack_losses
					if attack_succeed then
						success = true
						if WORLD:does_player_see_realm_news(realm) then
							WORLD:emit_notification("Our neighbor, " ..
								raider.name ..
								", sent warriors to raid us. We lost " ..
								tostring(def_losses) ..
								" warriors and our enemies lost " ..
								tostring(attack_losses) .. " and our province was looted.")
						end
					else
						success = false
						if WORLD:does_player_see_realm_news(realm) then
							WORLD:emit_notification("Our neighbor, " ..
								raider.name ..
								", sent warriors to raid us. We lost " ..
								tostring(def_losses) ..
								" warriors and our enemies lost " ..
								tostring(attack_losses) .. ". We managed to fight off the aggressors.")
						end
					end
				end
			else
				-- The army wasn't spotted. Nothing to do!
				if raider.dead then
					success = false
				else
					success = true
				end
			end
			if success then
				-- The army wasn't spotted!
				-- Therefore, it's a sure success.
				local max_loot = army:loot_capacity()
				local real_loot = math.min(max_loot, province.local_wealth)
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
						.. tostring(province.local_wealth)
					)
				end

				local mood_swing = real_loot / (province:local_population() + 1)
				province.mood = province.mood - mood_swing
				if realm then
					raider.popularity[realm] = (raider.popularity[realm] or 0) - mood_swing * 2
				end

				---@type RaidResultSuccess
				local success_data = { army = army, target = target, loot = real_loot, losses = losses, raider = raider, origin =
				origin }
				WORLD:emit_action("covert-raid-success", raider,
					success_data,
					travel_time, true)
				if WORLD:does_player_see_realm_news(realm) then
					WORLD:emit_notification("An unknown adversary raided our province " ..
						province.name ..
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

			realm:disband_army(army)
			realm.capitol.mood = realm.capitol.mood - 0.025
			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification("Raid attempt of " .. raider.name .. " in " ..
					target.name .. " failed. " .. tostring(losses) .. " warriors died. People are upset.")
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
				.. tostring(realm.name)
				.. "\n loot: "
				.. tostring(loot)
				.. "\n target: "
				.. tostring(target.name)
				.. "\n losses: "
				.. tostring(losses)
				.. "\n army: "
				.. tostring(tabb.size(army.warbands))
			)
			end

			local warbands = realm:disband_army(army)

			local mood_swing = loot / (realm.capitol:local_population() + 1) / 2

			-- improve mood in a province
			realm.capitol.mood = realm.capitol.mood + mood_swing

			-- popularity to raid participants
			local num_of_warbands = 0
			for _, w in pairs(warbands) do
				if w.leader then
					pe.change_popularity(w.leader, realm, mood_swing / tabb.size(warbands))
					num_of_warbands = num_of_warbands + 1
				end
			end

			local quest_reward = math.min(loot * 0.5, realm.quests_raid[target] or 0)
			realm.quests_raid[target] = (realm.quests_raid[target] or 0) - quest_reward

			-- save total loot for future
			local total_loot = loot

			-- pay quest rewards to warband leaders
			for _, w in pairs(warbands) do
				if w.leader then
					economic_effects.add_pop_savings(
						w.leader,
						quest_reward / num_of_warbands,
						ECONOMY_REASON.QUEST
					)
				end
			end

			-- half of loot goes to warbands
			for _, w in pairs(warbands) do
				w.treasury = w.treasury + loot * 0.5 / num_of_warbands
				if w.treasury ~= w.treasury then
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
			economic_effects.change_local_wealth(realm.capitol, loot, ECONOMY_REASON.RAID)

			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification("Our raid in " .. target.name .. " succeeded. Warriors brought home " ..
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
			realm.capitol.mood = realm.capitol.mood - 0.025

			realm:disband_army(army)
			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification("Our raid attempt in " ..
					target.name .. " failed. We were spotted but our warriors returned home safely")
			end
		end,
	}
end

return load
