local Event = require "game.raws.events"
local E_ut = require "game.raws.events._utils"

local ut = require "game.ui-utils"

local tabb = require "engine.table"

local pe = require "game.raws.effects.politics"
local pv = require "game.raws.values.politics"
local ee = require "game.raws.effects.economy"
local me = require "game.raws.effects.military"
local ie = require "game.raws.effects.interpersonal"
local di = require "game.raws.effects.diplomacy"


local offices_triggers = require "game.raws.triggers.offices"
local office_effects = require "game.raws.effects.office"

local function load()
	Event:new {
		name = "succession-death",
		hidden = true,
		event_background_path = "data/gfx/backgrounds/background.png",
		automatic = false,
		base_probability = 0,
		on_trigger = function(self, character, associated_data)
			local succession = DATA.get_succession_from_successor_of(character)

			local successor = INVALID_ID
			if succession ~= INVALID_ID then
				successor = DATA.succession_get_successor(succession)
			end

			-- we should notify realm leader if his overseer is dead
			local overseership = DATA.get_realm_overseer_from_overseer(character)
			if overseership ~= INVALID_ID then
				local realm = DATA.realm_overseer_get_realm(overseership)
				pe.remove_overseer(realm)

				local realm_leader = DATA.get_realm_leadership_from_realm(realm)
				if realm_leader ~= INVALID_ID then
					local leader = DATA.realm_leadership_get_leader(realm_leader)
					WORLD:emit_immediate_event("succession-overseer-death-notification", leader, character)
				end
			end

			-- warbands without leader dissolve
			local leadership = DATA.get_warband_leader_from_leader(character)
			if leadership ~= INVALID_ID then
				me.dissolve_warband(character)
			end

			local commander = DATA.get_warband_commander_from_commander(character)
			if commander ~= INVALID_ID then
				local warband = DATA.warband_commander_get_warband(commander)
				-- check if it was a guard:
				local guard = DATA.get_realm_guard_from_guard(warband)

				if guard == INVALID_ID then
					-- TODO: notify leader of the guard
				else
					local realm = DATA.realm_guard_get_realm(guard)
					pe.remove_guard_leader(realm)
					local realm_leadership = DATA.get_realm_leadership_from_realm(realm)
					if realm_leadership ~= INVALID_ID then
						local leader = DATA.realm_leadership_get_leader(realm_leadership)
						WORLD:emit_immediate_event("succession-guard-leader-death-notification", leader, character)
					end
				end
			end

			-- succession of realm tribute collector
			local collector_status = DATA.get_tax_collector_from_collector(character)
			if collector_status ~= INVALID_ID then
				office_effects.fire_tax_collector(character)
				local realm_leadership = DATA.get_realm_leadership_from_realm(REALM(character))
				if realm_leadership ~= INVALID_ID then
					local leader = DATA.realm_leadership_get_leader(realm_leadership)
					WORLD:emit_immediate_event("succession-tribute-collector-death-notification", leader, character)
				end
			end

			-- succession of buildings and other worldly possessions
			local inheritance = DATA.pop_get_savings(character)
			if successor ~= INVALID_ID then
				DATA.for_each_ownership_from_owner(character, function (item)
					local building = DATA.ownership_get_building(item)
					ee.set_ownership(building, successor)
				end)
				ee.add_pop_savings(successor, inheritance, ECONOMY_REASON.INHERITANCE)
				ee.add_pop_savings(character, -inheritance, ECONOMY_REASON.INHERITANCE)
			else
				ee.change_local_wealth(PROVINCE(character), inheritance, ECONOMY_REASON.INHERITANCE)
				ee.add_pop_savings(character, -inheritance, ECONOMY_REASON.INHERITANCE)
			end

			---@type Realm[]
			local realms_to_dissolve = {}

			DATA.for_each_realm_leadership_from_leader(character, function (leadership)
				local realm = DATA.realm_leadership_get_realm(leadership)
				local capitol = DATA.realm_get_capitol(realm)

				-- trying to find a successor

				-- first candidate is overseer of the realm
				if successor == INVALID_ID then
					local overseership = DATA.get_realm_overseer_from_realm(realm)
					if overseership ~= INVALID_ID then
						local overseer = DATA.realm_overseer_get_overseer(overseership)
						successor = overseer
					end
				end

				-- find most popular noble which lives here and currently stays in the province:
				if successor == INVALID_ID then
					DATA.for_each_character_location_from_location(capitol, function (character_location)
						local noble = DATA.character_location_get_character(character_location)
						if noble == character then
							return
						end
						local home_location = HOME(noble)
						if home_location ~= capitol then
							return
						end

						if successor == INVALID_ID then
							successor = noble
						elseif
							pv.popularity(noble, realm) > pv.popularity(successor, realm)
						then
							successor = noble
						end
					end)
				end

				-- find noble again but remove restriction of being in capitol
				if successor == INVALID_ID then
					DATA.for_each_home_from_home(capitol, function (character_location)
						local noble = DATA.home_get_pop(character_location)
						if not IS_CHARACTER(noble) then
							return
						end
						if noble == character then
							return
						end

						if successor == INVALID_ID then
							successor = noble
						elseif
							pv.popularity(noble, realm) > pv.popularity(successor, realm)
						then
							successor = noble
						end
					end)
				end

				--- now we checked all local nobles candidates
				--- it means that there everyone else is a pop
				--- try to find the oldest local pop to turn into character
				if successor == INVALID_ID then
					DATA.for_each_home_from_home(capitol, function (character_location)
						local pop = DATA.home_get_pop(character_location)
						if pop == character then
							return
						end

						if successor == INVALID_ID then
							successor = pop
						elseif
							DATA.pop_get_age(pop) > DATA.pop_get_age(successor)
						then
							successor = pop
						end
					end)
				end

				--- if there is no pop which could become a leader: try to find at least some character here:
				if successor == INVALID_ID then
					DATA.for_each_character_location_from_location(capitol, function (character_location)
						local noble = DATA.character_location_get_character(character_location)
						if noble == character then
							return
						end

						if successor == INVALID_ID then
							successor = noble
						elseif
							pv.popularity(noble, realm) > pv.popularity(successor, realm)
						then
							successor = noble
						end
					end)
				end

				if successor == INVALID_ID then
					-- there are no candidates and province is empty: dissolve the realm
					table.insert(realms_to_dissolve, realm)

				else
					-- we found someone
					if not IS_CHARACTER(successor) then
						pe.grant_nobility(successor, POLITICS_REASON.NOTENOUGHNOBLES)
					end
					-- now we can guarantee that it's a character:

					pe.transfer_power(realm, successor, POLITICS_REASON.SUCCESSION)
					WORLD:emit_immediate_event("succession-leader-notification", successor, realm)
				end
			end)

			for index, realm in ipairs(realms_to_dissolve) do
				di.dissolve_realm_and_clear_diplomacy(realm)
			end

			-- delete character
			DATA.delete_pop(character)
		end,
	}

	E_ut.notification_event(
		"succession-leader-notification",
		function(self, character, associated_data)
			---@type Realm
			associated_data = associated_data
			return "I have become the chief of " .. REALM_NAME(associated_data)
		end,
		function(root, associated_data)
			return "Sure"
		end,
		function(root, associated_data)
			return "I accept the title."
		end
	)

	E_ut.notification_event(
		"succession-overseer-death-notification",
		function(self, character, associated_data)
			---@type Character
			associated_data = associated_data
			return "My overseer " .. NAME(associated_data) .. " had died. "
		end,
		function(root, associated_data)
			return "I see..."
		end,
		function(root, associated_data)
			---@type Character
			associated_data = associated_data
			return "I acknowledge the death of " .. NAME(associated_data) .. "."
		end
	)

	E_ut.notification_event(
		"succession-guard-leader-death-notification",
		function(self, character, associated_data)
			---@type Character
			associated_data = associated_data
			return "My guard leader " .. NAME(associated_data) .. " had died. "
		end,
		function(root, associated_data)
			return "I see..."
		end,
		function(root, associated_data)
			---@type Character
			associated_data = associated_data
			return "I acknowledge the death of " .. NAME(associated_data) .. "."
		end
	)

	E_ut.notification_event(
		"succession-tribute-collector-death-notification",
		function(self, character, associated_data)
			---@type Character
			associated_data = associated_data
			return "My tribute collector " .. NAME(associated_data) .. " had died. "
		end,
		function(root, associated_data)
			return "I see..."
		end,
		function(root, associated_data)
			---@type Character
			associated_data = associated_data
			return "I acknowledge the death of " .. NAME(associated_data) .. "."
		end
	)

	E_ut.notification_event(
		"succession-wealth-inheritance",
		function(self, character, associated_data)
			---@type {character: Character, wealth: number}
			associated_data = associated_data
			return "I inherited "
				.. ut.to_fixed_point2(associated_data.wealth)
				.. MONEY_SYMBOL
				.. " from "
				.. NAME(associated_data.character)
				.. "."
		end,
		function(root, associated_data)
			return "I see..."
		end,
		function(root, associated_data)
			---@type Character
			associated_data = associated_data
			return "I accept wealth of " .. NAME(associated_data) .. "."
		end
	)

	E_ut.notification_event(
		"succession-set",
		function(self, character, associated_data)
			---@type Character
			associated_data = associated_data
			return "I was designated successor of "
				.. NAME(associated_data)
				.. "."
		end,
		function(root, associated_data)
			return "Fine."
		end,
		function(root, associated_data)
			return "Fine."
		end
	)
end
return load
