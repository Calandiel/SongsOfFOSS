local tabb = require "engine.table"
local Event = require "game.raws.events"
local ef = require "game.raws.effects.economic"

---@class PatrolData
---@field defender Realm
---@field target Province
---@field travel_time number
---@field patrol table<Warband, Warband>

---@class RaidData 
---@field raider Realm
---@field target Province
---@field travel_time number
---@field army Army

---@class RaidResultSuccess
---@field losses number
---@field army Army
---@field loot number
---@field target Province

---@class RaidResultFail
---@field losses number
---@field army Army
---@field target Province

---@class RaidResultRetreat
---@field army Army
---@field target Province


local function load()
	Event:new {
		name = "patrol-province",
		automatic = false,
		on_trigger = function(self, realm, associated_data) 
			---@type PatrolData
			associated_data = associated_data
			---@type Realm
			local realm = realm
			associated_data.target.mood = associated_data.target.mood + 0.025
			if realm == WORLD.player_realm then
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
		on_trigger = function(self, realm, associated_data)
			---@type RaidData
			associated_data = associated_data
			---@type Realm
			local realm = realm

			local raider = associated_data.raider
			local target = associated_data.target
			local travel_time = associated_data.travel_time
			local army = associated_data.army

			local retreat = false
			local success = true
			local losses = 0
			if target:army_spot_test(army) then
				-- The army was spotted!
				if love.math.random() < 0.5 then
					-- Let's just return and do nothing
					success = false
					if target.realm == WORLD.player_realm then
						WORLD:emit_notification("Our neighbor, " ..
							raider.name .. ", sent warriors to raid us but they were spotted and returned home.")
					end
					retreat = true
				else
					-- Battle time!
					-- First, raise the defending army.
					local def = realm:raise_local_army(target)
					local attack_succeed, attack_losses, def_losses = army:attack(target, true, def)
					realm:disband_army(def) -- disband the army after battle
					losses = attack_losses
					if attack_succeed then
						success = true
						if target.realm == WORLD.player_realm then
							WORLD:emit_notification("Our neighbor, " ..
								raider.name ..
								", sent warriors to raid us. We lost " ..
								tostring(def_losses) ..
								" warriors and our enemies lost " .. tostring(attack_losses) .. " and our province was looted.")
						end
					else
						if target.realm == WORLD.player_realm then
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
				local real_loot = math.min(max_loot, target.local_wealth)
				target.local_wealth = target.local_wealth - real_loot
				if max_loot > real_loot then
					local leftover = max_loot - real_loot
					local extra = math.min(0.1 * realm.treasury, leftover)
					realm.treasury = realm.treasury - extra
					real_loot = real_loot + extra
				end
				WORLD:emit_action(WORLD.events_by_name["covert-raid-success"], raider, raider,
					{ army = army, target = target, loot = real_loot, losses = losses },
					travel_time, true)
				if target.realm == WORLD.player_realm then
					WORLD:emit_notification("An unknown adversary raided our province " ..
						target.name .. " and stole " .. real_loot .. MONEY_SYMBOL .. " worth of goods!")
				end
			else
				if retreat then
					WORLD:emit_action(WORLD.events_by_name["covert-raid-retreat"], raider, raider, { army = army, target = target },
						travel_time, true)
				else
					WORLD:emit_action(WORLD.events_by_name["covert-raid-fail"], raider, raider,
						{ army = army, target = target, losses = losses },
						travel_time, true)
				end
			end
		end,
	}
	Event:new {
		name = "covert-raid-fail",
		automatic = false,
		on_trigger = function(self, realm, associated_data)
			---@type RaidResultFail
			associated_data = associated_data
			---@type Realm
			local realm = realm

			local target = associated_data.target
			local losses = associated_data.losses
			local army = associated_data.army

			realm:disband_army(army)
			realm.capitol.mood = realm.capitol.mood - 1
			if realm == WORLD.player_realm then
				WORLD:emit_notification("Our raid attempt in " ..
					target.name .. " failed. " .. tostring(losses) .. " warriors died. People are upset.")
			end
		end,
	}
	Event:new {
		name = "covert-raid-success",
		automatic = false,
		on_trigger = function(self, realm, associated_data)
			---@type RaidResultSuccess
			associated_data = associated_data
			---@type Realm
			local realm = realm

			local loot = associated_data.loot
			local target = associated_data.target
			local losses = associated_data.losses
			local army = associated_data.army

			realm:disband_army(army)
			realm.capitol.mood = realm.capitol.mood + 1 / (3 * math.max(0, realm.capitol.mood) + 1)

			ef.add_treasury(realm, loot, ef.reasons.Raid)
			-- realm.treasury = realm.treasury + loot

			if realm == WORLD.player_realm then
				WORLD:emit_notification("Our raid attempt in " ..
					target.name ..
					" succeeded. People are rejoiced! Our warriors brought home " ..
					tostring(math.floor(100 * loot) / 100) .. MONEY_SYMBOL .. " worth of loot. " .. tostring(losses) .. " people died.")
			end
		end,
	}
	Event:new {
		name = "covert-raid-retreat",
		automatic = false,
		on_trigger = function(self, realm, associated_data)
			---@type RaidResultRetreat
			associated_data = associated_data
			---@type Realm
			local realm = realm

			local army = associated_data.army
			local target = associated_data.target
			realm.capitol.mood = realm.capitol.mood - 0.025

			realm:disband_army(army)
			if realm == WORLD.player_realm then
				WORLD:emit_notification("Our raid attempt in " ..
					target.name .. " failed. We were spotted but our warriors returned home safely")
			end
		end,
	}
end

return load
