local tabb = require "engine.table"
local Event = require "game.raws.events"
local E_ut = require "game.raws.events._utils"

local ef = require "game.raws.effects.economic"
local ev = require "game.raws.values.economical"
local ut = require "game.ui-utils"


local AI_VALUE = require "game.raws.values.ai_preferences"

local pv = require "game.raws.values.political"
local de = require "game.raws.effects.diplomacy"
local me = require "game.raws.effects.military"
local pe = require "game.raws.effects.political"
local messages = require "game.raws.effects.messages"


---@class PatrolData
---@field defender Character
---@field origin Realm
---@field target Province
---@field travel_time number
---@field patrol table<Warband, Warband>

---@class RaidData 
---@field raider Character
---@field origin Realm
---@field target RewardFlag
---@field travel_time number
---@field army Army

---@class AttackData 
---@field raider Character
---@field origin Realm
---@field target Province
---@field travel_time number
---@field army Army

---@class RaidResultSuccess
---@field raider Character
---@field origin Realm
---@field losses number
---@field army Army
---@field loot number
---@field target RewardFlag

---@class RaidResultFail
---@field raider Character
---@field origin Realm
---@field losses number
---@field army Army
---@field target RewardFlag

---@class RaidResultRetreat
---@field raider Character
---@field origin Realm
---@field army Army
---@field target RewardFlag


local function load()
	Event:new {
		name = "patrol-province",
		automatic = false,
		on_trigger = function(self, root, associated_data) 
			---@type PatrolData
			associated_data = associated_data
			local realm_leader = associated_data.defender


			associated_data.target.mood = associated_data.target.mood + 0.025
			if WORLD:does_player_see_realm_news(realm_leader.province.realm) then
				WORLD:emit_notification("Several of our warbands had finished patrolling of " .. associated_data.target.name .. ". Local people feel safety")
			end

			for _, w in pairs(associated_data.patrol) do
				w.status = 'idle'
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
				.. " Enemies potential forces consist of "
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
            ---@type Realm
            local target_realm = associated_data

            -- character assumes that realm will gain money at least for a year
            local gain_of_money = 0
            if target_realm then
                gain_of_money = ev.potential_monthly_tribute_size(target_realm) * 12
            end

            local my_warlords, my_power = pv.military_strength(character)
			local my_warlords_ready, my_power_ready = pv.military_strength_ready(character)
            local their_warlords, their_power = pv.military_strength(target_realm.leader)

			return {
				{
					text = "Forward!",
					tooltip = "Launch the invasion",
					viable = function() return true end,
					outcome = function()
                        local realm = character.realm

						local army = me.gather_loyal_army(character)
						if army == nil then
							if character == WORLD.player_character then
								WORLD:emit_notification("I had launched the invasion of " .. target_realm.name)
							end
						else
							local function callback(army, travel_time)
								---@type AttackData
								local data = {
									raider = character,
									origin = realm,
									target = target_realm.capitol,
									travel_time = travel_time,
									army = army
								}

								WORLD:emit_action('request-tribute-attack', character, data, travel_time, true)
							end

							me.send_army(army, character.province, target_realm.capitol, callback)

							if character == WORLD.player_character then
								WORLD:emit_notification("I had launched the invasion of " .. target_realm.name)
							end
						end
					end,

					ai_preference = function ()
                        local base_value = AI_VALUE.generic_event_option(character, target_realm.leader, 0, {
                            aggression = true,
                        })()

                        base_value = base_value + AI_VALUE.money_utility(character) * gain_of_money
                        base_value = base_value + (my_power_ready - their_power) * 20
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
					ai_preference = function ()
                        local base_value = AI_VALUE.generic_event_option(character, target_realm.leader, 0, {
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
                            WORLD:emit_notification("I decided to not attack " .. target_realm.leader.name)
                        end
						character.busy = false
                    end,
					ai_preference = AI_VALUE.generic_event_option(character, target_realm.leader, 0, {})
				}
			}
		end
	}

	Event:new {
		name = "request-tribute-attack",
		automatic = false,
		on_trigger = function(self, root, associated_data)
			---@type AttackData
			associated_data = associated_data

			local raider = associated_data.raider
			local target = associated_data.target
			local travel_time = associated_data.travel_time
			local army = associated_data.army

			local province = target
			local realm = province.realm

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
			messages.tribute_raid(raider, province.realm, attack_succeed, attack_losses, def_losses)

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
		automatic = false,
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

			root.busy = false	
		end,
	}

	E_ut.notification_event(
        "request-tribute-army-returns-success-notification",
        function(self, character, associated_data)
            ---@type Army
			local army = associated_data
            return "We succeeded to enforce tribute on " .. army.destination.realm.name
		end,
        function (root, associated_data)
            return "Great!"
        end,
        function (root, associated_data)
            return ""
        end
    )

	Event:new {
		name = "request-tribute-army-returns-fail",
		automatic = false,
		on_trigger = function(self, root, associated_data)
			local realm = root.realm

			---@type Army
			local army = associated_data

			if realm == nil then
				return
			end

			WORLD:emit_event("request-tribute-army-returns-fail-notification", root, army)
			messages.tribute_raid_fail(realm, army.destination.realm)

			realm.capitol.mood = math.max(0, realm.capitol.mood - 0.05)
			pe.small_popularity_decrease(realm.leader, realm)
			realm:disband_army(army)
			realm.prepare_attack_flag = false
			root.busy = false
		end,
	}

	E_ut.notification_event(
        "request-tribute-army-returns-fail-notification",
        function(self, character, associated_data)
            ---@type Army
			local army = associated_data
            return "We failed to enforce tribute on " .. army.destination.realm.name
		end,
        function (root, associated_data)
            return "Whatever. We will succeed next time"
        end,
        function (root, associated_data)
            return ""
        end
    )


	Event:new {
		name = "covert-raid",
		automatic = false,
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
			local province = target.target
			local realm = province.realm

			if not realm then
				-- The province doesn't have a realm
				return
			end

			if province:army_spot_test(army) then
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
								" warriors and our enemies lost " .. tostring(attack_losses) .. " and our province was looted.")
						end
					else
						success = false
						if WORLD:does_player_see_realm_news(realm) then
							WORLD:emit_notification("Our neighbor, " ..
								raider.name ..
								", sent warriors to raid us. We lost " ..
								tostring(def_losses) ..
								" warriors and our enemies lost " .. tostring(attack_losses) .. ". We managed to fight off the aggresors.")
						end
					end
				end
			else
				-- The army wasn't spotted. Nothing to do!
				success = true
			end
			if success then
				-- The army wasn't spotted!
				-- Therefore, it's a sure success.
				local max_loot = army:get_loot_capacity()
				local real_loot = math.min(max_loot, province.local_wealth)
				province.local_wealth = province.local_wealth - real_loot
				if max_loot > real_loot then
					local leftover = max_loot - real_loot
					local potential_loot = ev.raidable_treasury(realm)
					local extra = math.min(potential_loot, leftover)
					EconomicEffects.change_treasury(realm, -extra, EconomicEffects.reasons.Raid)
					real_loot = real_loot + extra
				end

				local mood_swing = real_loot / (province:population() + 1)
				province.mood = province.mood - mood_swing
				raider.popularity[realm] = (raider.popularity[realm] or 0) - mood_swing * 2

				---@type RaidResultSuccess
				local success_data = { army = army, target = target, loot = real_loot, losses = losses, raider = raider, origin = origin }
				WORLD:emit_action("covert-raid-success", raider,
					success_data,
					travel_time, true)
				if WORLD:does_player_see_realm_news(realm) then
					WORLD:emit_notification("An unknown adversary raided our province " ..
						province.name .. " and stole " .. ut.to_fixed_point2(real_loot) .. MONEY_SYMBOL .. " worth of goods!")
				end
			else
				if retreat then
					---@type RaidResultRetreat
					local retreat_data = { army = army, target = target, raider = raider, origin = origin }

					WORLD:emit_action("covert-raid-retreat", raider, retreat_data,
						travel_time, true)
				else
					---@type RaidResultFail
					local retreat_data = { army = army, target = target, raider = raider, losses = losses, origin = origin }

					WORLD:emit_action("covert-raid-fail", raider,
						retreat_data,
						travel_time, true)
				end
			end
		end,
	}
	Event:new {
		name = "covert-raid-fail",
		automatic = false,
		on_trigger = function(self, root, associated_data)
			---@type RaidResultFail
			associated_data = associated_data
			local raider = associated_data.raider
			local realm = associated_data.origin

			local target = associated_data.target
			local losses = associated_data.losses
			local army = associated_data.army

			realm:disband_army(army)
			realm.capitol.mood = realm.capitol.mood - 1
			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification("Raid attempt of " .. raider.name .. " in " ..
					target.target.name .. " failed. " .. tostring(losses) .. " warriors died. People are upset.")
			end
		end,
	}
	Event:new {
		name = "covert-raid-success",
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

			local warbands = realm:disband_army(army)

			local mood_swing = loot / (realm.capitol:population() + 1) / 2

			-- popularity to raid initiator
			pe.change_popularity(target.owner, realm, mood_swing)

			-- improve mood in a province
			realm.capitol.mood = realm.capitol.mood + mood_swing

			-- popularity to raid participants
			local num_of_warbands = 0
			for _, w in pairs(warbands) do
				pe.change_popularity(w.leader, target.owner.realm, mood_swing / tabb.size(warbands))
				num_of_warbands = num_of_warbands + 1
			end

			-- initiator gets 2 "coins" for each invested "coin"
			local total_loot = loot
			local initiator_share = loot * 0.5
			if initiator_share / 2 > target.reward then
				initiator_share = target.reward * 2
			end

			-- reward part
			-- if reward was 0 then this stage does nothing

			-- pay share to raid initiator
			ef.add_pop_savings(target.owner, initiator_share, ef.reasons.RewardFlag)
			loot = loot - initiator_share

			-- pay rewards to warband leaders
			target.reward = target.reward - initiator_share / 2
			for _, w in pairs(warbands) do
				ef.add_pop_savings(w.leader, initiator_share / 2 / num_of_warbands, ef.reasons.RewardFlag)
			end
			loot = loot - initiator_share / 2

			-- remained raided wealth part

			-- half of remaining loot goes again to raid_initiator as spoils of war
			ef.add_pop_savings(target.owner, loot / 2, ef.reasons.Raid)
			loot = loot - loot / 2

			-- half of remaining loot goes to warband leaders
			for _, w in pairs(warbands) do
				ef.add_pop_savings(w.leader, loot / 2 / num_of_warbands, ef.reasons.Raid)
			end
			loot = loot - loot / 2

			-- pay the remaining half of loot to population(warriors)
			target.owner.province.local_wealth = target.owner.province.local_wealth + loot

			if target.reward == 0 then
				realm:remove_reward_flag(target)
			end

			-- target.owner.province.realm:remove_reward_flag(target)

			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification("Our raid in " ..
					target.target.name ..
					" succeeded. Warriors brought home " ..
					ut.to_fixed_point2(total_loot) .. MONEY_SYMBOL .. " worth of loot. " ..
					target.owner.name .. ' receives ' .. ut.to_fixed_point2(initiator_share) .. MONEY_SYMBOL .. ' as initialtor.' ..
					' Warband leaders were additionally rewarded with ' .. ut.to_fixed_point2(initiator_share / 2) .. MONEY_SYMBOL .. '. '
					.. tostring(losses) .. " warriors died.")
			end
		end,
	}
	Event:new {
		name = "covert-raid-retreat",
		automatic = false,
		on_trigger = function(self, root, associated_data)
			---@type RaidResultRetreat
			associated_data = associated_data
			local realm = associated_data.origin

			local army = associated_data.army
			local target = associated_data.target
			realm.capitol.mood = realm.capitol.mood - 0.025
			pe.small_popularity_decrease(target.owner, target.owner.realm)

			realm:disband_army(army)
			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification("Our raid attempt in " ..
					target.target.name .. " failed. We were spotted but our warriors returned home safely")
			end
		end,
	}
end

return load
