local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"

local province_utils = require "game.entities.province".Province


---Draws demography data
---@param provinces Province[]
---@param ui_panel Rect
---@param collapsed boolean?
local function demography(provinces, ui_panel, collapsed)

    local function graph_races (rect)
        ---@type table<Race, number>
        local counts = {}
        for _, province in pairs(provinces) do
            DATA.for_each_pop_location_from_location(province, function (item)
                local pop = DATA.pop_location_get_pop(item)
                local race = DATA.pop_get_race(pop)
                assert(race ~= INVALID_ID)
                local old = counts[race] or 0
                counts[race] = old + 1
            end)
        end

        ---@type Entry[]
        local entries = {}
        for race_id, count in pairs(counts) do
            local fat_race = DATA.fatten_race(race_id)
            entries[#entries + 1] = {
                weight = count,
                tooltip = fat_race.name .. " (" .. count .. ")",
                r = fat_race.r,
                g = fat_race.g,
                b = fat_race.b,
            }
        end
        ut.graph(entries, rect)
    end

    local function graph_cultures(rect)
        ---@type table<culture_id, number>
        local counts = {}
        for _, province in pairs(provinces) do
            DATA.for_each_pop_location_from_location(province, function (item)
                local pop = DATA.pop_location_get_pop(item)
                local culture = DATA.pop_get_culture(pop)
                local old = counts[culture] or 0
                counts[culture] = old + 1
            end)
        end

        ---@type Entry[]
        local entries = {}
        for culture, count in pairs(counts) do
            entries[#entries + 1] = {
                weight = count,
                tooltip = DATA.culture_get_name(culture) .. " (" .. count .. ")\n" .. require "game.economy.diet-breadth-model".culture_target_tooltip(culture),
                r = DATA.culture_get_r(culture),
                g = DATA.culture_get_g(culture),
                b = DATA.culture_get_b(culture),
            }
        end

        ut.graph(entries, rect)
    end

    local function graph_faiths(rect)
        ---@type table<Faith, number>
        local counts = {}
        for _, province in pairs(provinces) do
            DATA.for_each_pop_location_from_location(province, function (item)
                local pop = DATA.pop_location_get_pop(item)
                local faith = DATA.pop_get_faith(pop)
                local old = counts[faith] or 0
                counts[faith] = old + 1
            end)
        end

        ---@type Entry[]
        local entries = {}
        for faith, count in pairs(counts) do
            entries[#entries + 1] = {
                weight = count,
                tooltip = faith.name .. " (" .. count .. ")",
                r = faith.r,
                g = faith.g,
                b = faith.b,
            }
        end

        ut.graph(entries, rect)
    end


    local function graph_jobs (rect)
        ---@type table<job_id, number>
        local counts = {}
        counts[UNEMPLOYED] = 0
        counts[CHILDREN] = 0
        counts[WARRIORS] = 0

        for _, province in pairs(provinces) do
            DATA.for_each_pop_location_from_location(province, function (item)
                local pop = DATA.pop_location_get_pop(item)
                local employment = DATA.get_employment_from_worker(pop)
                local employer = DATA.employment_get_building(employment)
                local job = DATA.employment_get_job(employment)
                local age = DATA.pop_get_age(pop)
                local race = DATA.pop_get_race(pop)
                local teen_age = DATA.race_get_teen_age(race)
                if employer ~= INVALID_ID then
                    if counts[job] then
                        counts[job] = counts[job] + 1
                    else
                        counts[job] = 1
                    end
                else
                    if age > teen_age then
                        local warband_membership = DATA.get_warband_unit_from_unit(pop)
                        local warband = DATA.warband_unit_get_warband(warband_membership)
                        if warband ~= INVALID_ID then
                            counts[WARRIORS] = counts[WARRIORS] + 1
                        else
                            counts[UNEMPLOYED] = counts[UNEMPLOYED] + 1
                        end
                    else
                        counts[CHILDREN] = counts[CHILDREN] + 1
                    end
                end
            end)
        end

        ---@type NamedEntry[]
        local entries = {}
        for job, count in pairs(counts) do
            local fat = DATA.fatten_job(job)
            local description = fat.description
            assert(description ~= nil, "job " .. tostring(job) .. " has no description")
            entries[#entries + 1] = {
                weight = count,
                tooltip = description .. " (" .. count .. ")",
                r = fat.r,
                g = fat.g,
                b = fat.b,
                name = description,
            }
        end
        table.sort(entries, function(a, b)
            return a.name < b.name
        end)
        ut.graph(entries, rect)
    end


    local function population_item (rect)
        local carr_cap = 0
        local population = 0
        for _, province in ipairs(provinces) do
            carr_cap = carr_cap + math.floor(DATA.province_get_foragers_limit(province))
            population = population + province_utils.local_population(province)
        end

        ut.data_entry("Population: ", tostring(population) .. "/" .. tostring(carr_cap), rect)
    end


    return function()
        if collapsed then
            ut.rows(
                {
                    function(rect)
                        ui.centered_text("Races", rect)
                    end,
                    graph_races,
                    function(rect)
                        ui.centered_text("Culture", rect)
                    end,
                    graph_cultures,
                    function(rect)
                        ui.centered_text("Faiths", rect)
                    end,
                    graph_faiths,
                    function(rect)
                        ui.centered_text("Jobs", rect)
                    end,
                    graph_jobs,
                },
                ui_panel,
                UI_STYLE.scrollable_list_thin_item_height
            )
            return
        end
        ut.rows(
            {
                population_item,
                function(rect)
                    ui.centered_text("Races", rect)
                end,
                graph_races,
                function(rect)
                    ui.centered_text("Culture", rect)
                end,
                graph_cultures,
                function(rect)
                    ui.centered_text("Faiths", rect)
                end,
                graph_faiths,
                function(rect)
                    ui.centered_text("Jobs", rect)
                end,
                graph_jobs,
            },
            ui_panel
        )
    end
end

return demography