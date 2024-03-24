local tabb = require "engine.table"
local path = require "game.ai.pathfinding"

local Decision = require "game.raws.decisions"
local dt = require "game.raws.triggers.diplomacy"
local ot = require "game.raws.triggers.offices"
local pv = require "game.raws.values.political"

local pretriggers = require "game.raws.triggers.tooltiped_triggers".Pretrigger
local triggers = require "game.raws.triggers.tooltiped_triggers".Targeted

local OR = pretriggers.OR
local NOT_BUSY = pretriggers.not_busy
local IS_LEADER = pretriggers.leader
local IS_LOCAL_LEADER = pretriggers.leader_of_local_territory



local IS_OVERLORD_OF_TARGET = triggers.is_overlord_of_target
local NOT_IN_NEGOTIATIONS = triggers.is_not_in_negotiations

local economic_effects = require "game.raws.effects.economic"
local character_values = require "game.raws.values.character"

local TRAIT = require "game.raws.traits.generic"

local function load()
	Decision.Character:new {
		name = 'request-tribute',
		ui_name = "Request tribute",
		tooltip = function(root, primary_target)
			if root.busy then
				return "You are busy."
			end
			return "Suggest " .. primary_target.name .. " to become your tributary."
		end,
		sorting = 1,
		primary_target = 'character',
		secondary_target = 'none',
		base_probability = 1 / 12, -- Once every year on average
		pretrigger = function(root)
			if not ot.decides_foreign_policy(root, root.realm) then return false end
			if root.realm.prepare_attack_flag then return false end
			if root.busy then return false end

			return true
		end,
		clickable = function(root, primary_target)
			---@type Character
			local primary_target = primary_target
			if not dt.valid_negotiators(root, primary_target) then return false end
			if primary_target.realm.paying_tribute_to[root.realm] then return false end

			return true
		end,
		available = function(root, primary_target)
			if not dt.valid_negotiators(root, primary_target) then return false end
			if primary_target.realm.paying_tribute_to[root.realm] then return false end

			return true
		end,
		ai_target = function(root)
			--print("ait")
			---@type Realm
			local realm = root.realm
			if realm == nil then
				return nil, false
			end

			---@type fun(province:Province):boolean
			local function valid_realm_check(province)
				if province then
					if province.realm then
						if province.realm ~= root.realm then
							return true
						end
					end
				end
				return false
			end

			-- select random province
			local random_realm_province = realm:get_random_province()
			if random_realm_province then
				-- Once you target a province, try selecting a random neighbor
				local neighbor_province = random_realm_province:get_random_neighbor()
				if neighbor_province then
					if valid_realm_check(neighbor_province) then
						return neighbor_province.realm.leader, true
					end
				end
			end

			-- if that still fails, try targetting a random tributaries neighbor
			local tributary_count = tabb.size(realm.tributaries)
			if tributary_count > 0 then
				local random_tributary = tabb.nth(realm.tributaries, love.math.random(tributary_count))
				local random_tributary_province = random_tributary:get_random_province()
				if random_tributary_province then
					if valid_realm_check(random_tributary_province) then
						return random_tributary_province.realm.leader, true
					end
				end
			end
			return nil, false
		end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			---@type Character
			primary_target = primary_target

			local _, root_power = pv.military_strength(root)
			local _, target_power = pv.military_strength(primary_target)
			local trait_modifier = 0
			if root.traits[TRAIT.WARLIKE] then
				trait_modifier = 2.0
			end
			if root.traits[TRAIT.LAZY] then
				trait_modifier = trait_modifier * 0.25
			end
			if root.traits[TRAIT.CONTENT] then
				trait_modifier = trait_modifier * 0.25
			end
			if root.traits[TRAIT.AMBITIOUS] then
				trait_modifier = trait_modifier * 1.5
			end

			if target_power == 0 and root_power > 0 then
				return trait_modifier
			end

			return (root_power - target_power) / target_power * trait_modifier
		end,
		effect = function(root, primary_target, secondary_target)
			if WORLD.player_character == root then
				WORLD:emit_notification("I requested " .. primary_target.name .. " to become my tributary.")
			elseif WORLD:does_player_see_realm_news(root.realm) then
				WORLD:emit_notification("Our chief requested " .. primary_target.name .. " to become his tributary.")
			end

			WORLD:emit_event('request-tribute', primary_target, root, 10)
		end
	}

	-- negotiation rough blueprint

	---@class NegotiationTradeData
	---@field goods_transfer_from_initiator_to_target table<TradeGoodReference, number?>
	---@field wealth_transfer_from_initiator_to_target number

	---@class NegotiationRealmToRealm
	---@field root Realm
	---@field target Realm
	---@field subjugate boolean
	---@field free boolean
	---@field demand_freedom boolean
	---@field trade NegotiationTradeData

	---@class NegotiationCharacterToRealm
	---@field target Realm
	---@field trade_permission boolean

	---@class NegotiationCharacterToCharacter
	---@field trade NegotiationTradeData

	---@class NegotiationData
	---@field initiator Character
	---@field target Character
	---@field negotiations_terms_realms NegotiationRealmToRealm[]
	---@field negotiations_terms_character_to_realm NegotiationCharacterToRealm[]
	---@field selected_realm_origin Realm?
	---@field selected_realm_target Realm?
	---@field negotiations_terms_characters NegotiationCharacterToCharacter
	---@field days_of_travel number

	Decision.CharacterCharacter:new_from_trigger_lists (
		'start-negotiations',
		"Start negotiations",
		function(root, primary_target)
			return "Start negotiations with " .. primary_target.name
		end,
		0, -- never
		{
			NOT_BUSY
		},
		{

		},
		{

		},

		function(root, primary_target, secondary_target)
			---@type NegotiationData
			local negotiation_data = {
				initiator = root,
				target = primary_target,
				negotiations_terms_characters = {
					trade = {
						wealth_transfer_from_initiator_to_target = 0,
						goods_transfer_from_initiator_to_target = {}
					}
				},
				negotiations_terms_character_to_realm = {},
				negotiations_terms_realms = {},
				days_of_travel = 10
			}

			root.current_negotiations[primary_target] = primary_target
			primary_target.current_negotiations[root] = root

			WORLD:emit_immediate_event('negotiation-initiator', root, negotiation_data)
		end,

		--- AI SHOULD HAVE SEPARATE DECISIONS WITH PRESET NEGOTIATION PROPOSALS
		function(root, primary_target, secondary_target)
			return 0
		end,
		function(root)
			return nil, false
		end
	)

	-- migrate decision

	Decision.CharacterProvince:new {
		name = 'migrate-realm',
		ui_name = "Migrate to targeted province",
		tooltip = function (root, primary_target)
            if root.busy then
                return "You are too busy to consider it."
            end
			if not ot.decides_foreign_policy(root, root.realm) then
				return "You have no right to order your tribe to do this"
			end
			if root.province ~= root.realm.capitol then
				return "You has to be with your people during migration"
			end
			if primary_target.realm then
				return "Migrate to "
					.. primary_target.name
					.. " controlled by "
					.. primary_target.realm.name
					.. ". Our tribe will be merged into their if they agree."
			else
				return "Migrate to "
					.. primary_target.name
					.. "."
			end
        end,
		path = function (root, primary_target)
			return path.pathfind(
				root.realm.capitol,
				primary_target.realm.capitol,
				character_values.travel_speed_race(root.realm.primary_race),
				root.realm.known_provinces
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0.9 , -- Almost every month
		pretrigger = function(root)
			if not ot.decides_foreign_policy(root, root.realm) then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if not primary_target.center.is_land then
				return false
			end
			if root.realm.capitol.neighbors[primary_target] then
				return true
			end
            return false
		end,
		available = function(root, primary_target)
            if root.busy then
                return false
            end
			if not ot.decides_foreign_policy(root, root.realm) then
				return false
			end
			if root.province ~= root.realm.capitol then
				return false
			end
			if primary_target.realm == root.realm then
				return false
			end
			return true
		end,
        ai_target = function(root)
			return tabb.random_select_from_set(root.realm.capitol.neighbors), true
        end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			root.busy = true

			local travel_time, _ = path.hours_to_travel_days(
				path.pathfind(
					root.realm.capitol,
					primary_target.realm.capitol,
					character_values.travel_speed_race(root.realm.primary_race),
					root.realm.known_provinces
				)
			)
			if travel_time == math.huge then
				travel_time = 150
			end

			if primary_target.realm == nil then
				---@type MigrationData
				local migration_data = {
					origin_province = root.realm.capitol,
					target_province = primary_target,
					invasion = false
				}
				WORLD:emit_immediate_action('migration-merge', root, migration_data)
			else
				WORLD:emit_event('migration-request', primary_target.realm.leader, root, travel_time)
			end
		end
	}

	Decision.CharacterProvince:new {
		name = 'migrate-realm-invasion',
		ui_name = "Invade targeted province",
		tooltip = function (root, primary_target)
            if root.busy then
                return "You are too busy to consider it."
            end
			if not ot.decides_foreign_policy(root, root.realm) then
				return "You have no right to order your tribe to do this"
			end
			if root.province ~= root.realm.capitol then
				return "You has to be with your people during migration"
			end
			return "Migrate to "
				.. primary_target.name
				.. " controlled by "
				.. primary_target.realm.name
				.. ". Their tribe will be merged into our if we succeed."
        end,
		path = function (root, primary_target)
			return path.pathfind(
				root.realm.capitol,
				primary_target.realm.capitol,
				character_values.travel_speed_race(root.realm.primary_race),
				root.realm.known_provinces
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0.9 , -- Almost every month
		pretrigger = function(root)
			if not ot.decides_foreign_policy(root, root.realm) then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if primary_target.realm == nil then
				return false
			end
			if root.realm.capitol.neighbors[primary_target] then
				return true
			end
            return false
		end,
		available = function(root, primary_target)
            if root.busy then
                return false
            end
			if not ot.decides_foreign_policy(root, root.realm) then
				return false
			end
			if root.province ~= root.realm.capitol then
				return false
			end
			if primary_target.realm == root.realm then
				return false
			end
			return true
		end,
        ai_target = function(root)
			return tabb.random_select_from_set(root.realm.capitol.neighbors), true
        end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			root.busy = true
			WORLD:emit_immediate_event('migration-invasion-preparation', root, primary_target.realm)
		end
	}

	local colonisation_cost = 60

	Decision.CharacterProvince:new {
		name = 'colonize-province',
		ui_name = "Colonize targeted province",
		tooltip = function (root, primary_target)
            if root.busy then
                return "You are too busy to consider it."
            end
			if root.realm.capitol:population() < 11 then
				return "Your population is too low"
			end
			if root.realm.budget.treasury < colonisation_cost then
				return "You need " .. colonisation_cost .. MONEY_SYMBOL
			end

			if not ot.decides_foreign_policy(root, root.realm) then
				return "You have no right to order your tribe to do this"
			end
			if root.province ~= root.realm.capitol then
				return "You has to be in your capital to organize colonisation"
			end
			return "Colonize "
				.. primary_target.name
				.. ". Our colonists will organise a new tribe which will pay tribute to us."
        end,
		path = function (root, primary_target)
			return path.pathfind(
				root.realm.capitol,
				primary_target.realm.capitol,
				character_values.travel_speed_race(root.realm.primary_race),
				root.realm.known_provinces
			)
		end,
		sorting = 1,
		primary_target = "province",
		secondary_target = 'none',
		base_probability = 0.9 , -- Almost every month
		pretrigger = function(root)
			if not ot.decides_foreign_policy(root, root.realm) then
				return false
			end
			return true
		end,
		clickable = function(root, primary_target)
			if not primary_target.center.is_land then
				return false
			end
			if root.realm.capitol:population() < 11 then
				return false
			end
			if primary_target.realm ~= nil then
				return false
			end
			if not primary_target:neighbors_realm_tributary(root.realm) then
				return false
			end
            return true
		end,
		available = function(root, primary_target)
            if root.busy then
                return false
            end
			if not ot.decides_foreign_policy(root, root.realm) then
				return false
			end
			if root.province ~= root.realm.capitol then
				return false
			end
			if root.realm.budget.treasury < colonisation_cost then
				return false
			end
			return true
		end,
        ai_target = function(root)
			return tabb.random_select_from_set(root.realm.capitol.neighbors), true
        end,
		ai_secondary_target = function(root, primary_target)
			return nil, true
		end,
		ai_will_do = function(root, primary_target, secondary_target)
			if root.realm.capitol:population() > 20 and primary_target.realm == nil then
				return 1
			end
			return 0
		end,
		effect = function(root, primary_target, secondary_target)
			root.busy = true

			---@type MigrationData
			local migration_data = {
				invasion = false,
				origin_province = root.province,
				target_province = primary_target
			}

			economic_effects.change_treasury(root.realm, -colonisation_cost, economic_effects.reasons.Colonisation)
			WORLD:emit_immediate_action('migration-colonize', root, migration_data)
		end
	}
end

return load
