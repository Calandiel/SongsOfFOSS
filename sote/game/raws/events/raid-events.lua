local tabb = require "engine.table"
local Event = require "game.raws.events"
local ef = require "game.raws.effects.economic"
local ut = require "game.ui-utils"

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
					local extra = math.min(0.1 * realm.treasury, leftover)
					realm.treasury = realm.treasury - extra
					real_loot = real_loot + extra
				end

				---@type RaidResultSuccess
				local success_data = { army = army, target = target, loot = real_loot, losses = losses, raider = raider, origin = origin }
				WORLD:emit_action("covert-raid-success", raider, raider,
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

					WORLD:emit_action("covert-raid-retreat", raider, raider, retreat_data,
						travel_time, true)
				else
					---@type RaidResultFail
					local retreat_data = { army = army, target = target, raider = raider, losses = losses, origin = origin }

					WORLD:emit_action("covert-raid-fail", raider, raider,
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
			realm.capitol.mood = realm.capitol.mood + 1 / (3 * math.max(0, realm.capitol.mood) + 1)
			-- popularity to raid initiator
			target.owner.popularity = target.owner.popularity + 0.1
			-- popularity to raid participants
			local num_of_warbands = 0
			for _, w in pairs(warbands) do
				w.leader.popularity = w.leader.popularity + 0.01
				num_of_warbands = num_of_warbands + 1
			end

			-- initiator gets 2 "coins" for each invested "coin"
			-- so one part of loot goes to pay his expenses on raid
			-- second part of loot goes to his income
			-- remaining half goes to population
			local total_loot = loot
			local initiator_share = loot * 0.5
			if initiator_share / 2 > target.reward then
				initiator_share = target.reward * 2
			end
			-- pay share to raid initiator
			ef.add_pop_savings(target.owner, initiator_share, ef.reasons.Raid)
			loot = loot - initiator_share
			-- pay rewards to warband leaders
			target.reward = target.reward - initiator_share / 2
			for _, w in pairs(warbands) do
				ef.add_pop_savings(w.leader, initiator_share / 2 / num_of_warbands, ef.reasons.Raid)
			end
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
			target.owner.popularity = target.owner.popularity - 0.01

			realm:disband_army(army)
			if WORLD:does_player_see_realm_news(realm) then
				WORLD:emit_notification("Our raid attempt in " ..
					target.target.name .. " failed. We were spotted but our warriors returned home safely")
			end
		end,
	}
end

return load
