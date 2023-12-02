local Event = require "game.raws.events"
local E_ut = require "game.raws.events._utils"

local ut = require "game.ui-utils"

local pe = require "game.raws.effects.political"
local pv = require "game.raws.values.political"
local ee = require "game.raws.effects.economic"
local me = require "game.raws.effects.military"
local ie = require "game.raws.effects.interpersonal"

local offices_triggers = require "game.raws.triggers.offices"

local function load()

    Event:new {
        name = "succession-death",
		automatic = false,
        hidden = true,
		base_probability = 0,
		on_trigger = function(self, character, associated_data)
            local successor = character.successor
            local realm = character.realm
            if realm == nil then
                return
            end
            local capitol = character.realm.capitol

            local leader = realm.leader
            if leader == nil then
                return
            end

            -- succession of realm leadership
            if leader == character then
                if not successor then
                    if realm.overseer then
                        successor = realm.overseer
                    else
                        ---@type Character?
                        local final_successor = nil
                        for _, pretender in pairs(capitol.characters) do
                            if
                                final_successor == nil
                                and pretender ~= character
                            then
                                final_successor = pretender
                            elseif
                                pv.popularity(pretender, realm) > pv.popularity(final_successor, realm)
                                and pretender ~= character
                            then
                                final_successor = pretender
                            end
                        end

                        successor = final_successor
                    end
                end

                if not successor then
                    ---@type Character?
                    local final_successor = nil
                    for _, pretender in pairs(capitol.home_to) do
                        if
                            final_successor == nil
                            and pretender ~= character
                        then
                            final_successor = pretender
                        elseif
                            pv.popularity(pretender, realm) > pv.popularity(final_successor, realm)
                            and pretender ~= character
                        then
                            final_successor = pretender
                        end
                    end

                    successor = final_successor
                end

                if not successor then
                    successor = pe.grant_nobility_to_random_pop(capitol)
                end

                if successor then
                    pe.transfer_power(realm, successor)
                    WORLD:emit_event("succession-leader-notification", successor, realm)
                else
                    -- no pops left: destroy realm
                    pe.dissolve_realm(realm)
                    realm.leader = nil
                end
            end

            -- succession of realm overseer
            if realm.overseer == character then
                pe.remove_overseer(realm)
                WORLD:emit_event("succession-overseer-death-notification", leader, character)
            end

            if offices_triggers.guard_leader(character, realm) then
                pe.remove_guard_leader(realm)
                WORLD:emit_event("succession-guard-leader-death-notification", leader, character)
            end

            -- succession of realm tribute collector
            if realm.tribute_collectors[character] then
                pe.remove_tribute_collector(realm, character)
                WORLD:emit_event("succession-tribute-collector-death-notification", leader, character)
            end

            -- succession of buildings
            local buildings_successor = character.successor
            for _, building in pairs(character.owned_buildings) do
                ee.set_ownership(building, buildings_successor)
            end

            -- dissolve warbands
            if character.leading_warband then
                me.dissolve_warband(character)
            end

            -- cancel all rewards:
            ---@type RewardFlag[]
            local rewards = {}
            for _, reward in pairs(realm.reward_flags) do
                if reward.owner == character then
                    table.insert(rewards, reward)
                end
            end
            for _, reward in pairs(rewards) do
                ee.cancel_reward_flag(realm, reward)
            end

            -- succession of wealth
            local wealth_successor = character.successor
            if wealth_successor then
                ee.add_pop_savings(wealth_successor, character.savings, ee.reasons.Inheritance)
                ee.add_pop_savings(character, - character.savings, ee.reasons.Inheritance)
            else
                ee.change_treasury(realm, character.savings, ee.reasons.Inheritance)
                ee.add_pop_savings(character, - character.savings, ee.reasons.Inheritance)
            end

            -- loyalty reset
            ie.remove_all_loyal(character)

            -- clear references to character
            character.province:remove_character(character)
            character.home_province:unset_home(character)
		end,
    }

    E_ut.notification_event(
        "succession-leader-notification",
        function(self, character, associated_data)
            ---@type Realm
            associated_data = associated_data
            return "I have become the chief of " .. associated_data.name
		end,
        function (root, associated_data)
            return "Sure"
        end,
        function (root, associated_data)
            return "I accept the title."
        end
    )

    E_ut.notification_event(
        "succession-overseer-death-notification",
        function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data
            return "My overseer " .. associated_data.name .. " had died. "
		end,
        function (root, associated_data)
            return "I see..."
        end,
        function (root, associated_data)
            ---@type Character
            associated_data = associated_data
            return "I acknowledge the death of " .. associated_data.name .. "."
        end
    )

    E_ut.notification_event(
        "succession-guard-leader-death-notification",
        function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data
            return "My guard leader " .. associated_data.name .. " had died. "
		end,
        function (root, associated_data)
            return "I see..."
        end,
        function (root, associated_data)
            ---@type Character
            associated_data = associated_data
            return "I acknowledge the death of " .. associated_data.name .. "."
        end
    )

    E_ut.notification_event(
        "succession-tribute-collector-death-notification",
        function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data
            return "My tribute collector " .. associated_data.name .. " had died. "
		end,
        function (root, associated_data)
            return "I see..."
        end,
        function (root, associated_data)
            ---@type Character
            associated_data = associated_data
            return "I acknowledge the death of " .. associated_data.name .. "."
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
                    .. associated_data.character.name
                    .. "."
		end,
        function (root, associated_data)
            return "I see..."
        end,
        function (root, associated_data)
            ---@type Character
            associated_data = associated_data
            return "I accept wealth of " .. associated_data.name .. "."
        end
    )

    E_ut.notification_event(
        "succession-set",
        function(self, character, associated_data)
            ---@type Character
            associated_data = associated_data
            return "I was set as a successor of "
                    .. associated_data.name
                    .. "."
		end,
        function (root, associated_data)
            return "Fine."
        end,
        function (root, associated_data)
            return "Fine."
        end
    )
end
return load