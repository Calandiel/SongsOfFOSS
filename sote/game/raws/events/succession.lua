local Event = require "game.raws.events"
local E_ut = require "game.raws.events._utils"

local ut = require "game.ui-utils"

local tabb = require "engine.table"

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

            for _, realm in pairs(character.leader_of) do
                character.leader_of[realm] = nil
                local capitol = character.realm.capitol
                local leader = realm.leader

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
                                and pretender:is_character()
                                and pretender ~= character
                            then
                                final_successor = pretender
                            elseif
                                pretender:is_character()
                                and pv.popularity(pretender, realm) > pv.popularity(final_successor, realm)
                                and pretender ~= character
                            then
                                final_successor = pretender
                            end
                        end

                        successor = final_successor
                    end
                    if not successor then
                        successor = tabb.random_select_from_set(tabb.filter(capitol.home_to, function (a)
                            return a.province and a.province == capitol and not a:is_character()
                        end))
                        if successor then
                            pe.grant_nobility(successor, capitol, pe.reasons.NOT_ENOUGH_NOBLES)
                        end
                    end
                    if not successor then
                        successor = pe.grant_nobility_to_random_pop(capitol, pe.reasons.NOT_ENOUGH_NOBLES)
                        if successor then
                            -- at this point the original tribe is extinquished and a new tribe rise to fill the vacuum
                            capitol.realm.primary_culture = successor.culture
                            capitol.realm.primary_faith = successor.faith
                            capitol.realm.primary_race = successor.race
                            capitol.realm.name = successor.culture.language:get_random_realm_name()
                            capitol.name = successor.culture.language:get_random_province_name()
                            -- grab whatever similar pops you can and set their home to give the new realm pop
                            for _, v in pairs(tabb.filter(capitol.all_pops, function (a)
                                return a.culture == successor.culture and a.faith == successor.faith and a.race == successor.race
                            end)) do
                                capitol:set_home(v)
                            end
                        end
                    end

                    if successor then
                        pe.transfer_power(realm, successor, pe.reasons.SUCCESSION)
                        WORLD:emit_immediate_event("succession-leader-notification", successor, realm)
                    else
                        -- no pops left: destroy realm
                        pe.dissolve_realm(realm)
                        realm.leader = nil
                    end
                end


            end


            local realm = character.realm
            local leader = character.realm.leader

            -- succession of realm overseer
            if realm and realm.overseer == character then
                pe.remove_overseer(realm)

                if leader then
                    WORLD:emit_immediate_event("succession-overseer-death-notification", leader, character)
                end
            end

            if realm and offices_triggers.guard_leader(character, realm) then
                pe.remove_guard_leader(realm)
                if leader then
                    WORLD:emit_immediate_event("succession-guard-leader-death-notification", leader, character)
                end
            end

            -- succession of realm tribute collector
            if realm and realm.tribute_collectors[character] then
                pe.remove_tribute_collector(realm, character)
                if leader then
                    WORLD:emit_immediate_event("succession-tribute-collector-death-notification", leader, character)
                end
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
            if realm then
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
            end

            -- succession of wealth
            local wealth_successor = character.successor
            if wealth_successor then
                ee.add_pop_savings(wealth_successor, character.savings, ee.reasons.Inheritance)
                ee.add_pop_savings(character, -character.savings, ee.reasons.Inheritance)
            else
                ee.change_local_wealth(character.province, character.savings, ee.reasons.Inheritance)
                ee.add_pop_savings(character, -character.savings, ee.reasons.Inheritance)
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