local tabb = require "engine.table"
local ui = require "engine.ui"
local ut = require "game.ui-utils"


---Draws demography data
---@param provinces Province[]
---@param ui_panel Rect
---@param collapsed boolean?
local function demography(provinces, ui_panel, collapsed)

    local function graph_races (rect)
        ---@type table<Race, number>
        local counts = {}
        for _, province in pairs(provinces) do
            for _, pop in pairs(province.all_pops) do
                local old = counts[pop.race] or 0
                counts[pop.race] = old + 1
            end
        end

        ---@type Entry[]
        local entries = {}
        for race, count in pairs(counts) do
            entries[#entries + 1] = {
                weight = count,
                tooltip = race.name .. " (" .. count .. ")",
                r = race.r,
                g = race.g,
                b = race.b,
            }
        end
        ut.graph(entries, rect)
    end

    local function graph_cultures(rect)
        ---@type table<Culture, number>
        local counts = {}
        for _, province in pairs(provinces) do
            for _, pop in pairs(province.all_pops) do
                local old = counts[pop.culture] or 0
                counts[pop.culture] = old + 1
            end
        end

        ---@type Entry[]
        local entries = {}
        for culture, count in pairs(counts) do
            entries[#entries + 1] = {
                weight = count,
                tooltip = culture.name .. " (" .. count .. ")",
                r = culture.r,
                g = culture.g,
                b = culture.b,
            }
        end

        ut.graph(entries, rect)
    end

    local function graph_faiths(rect)
        ---@type table<Faith, number>
        local counts = {}
        for _, province in pairs(provinces) do
            for _, pop in pairs(province.all_pops) do
                local old = counts[pop.faith] or 0
                counts[pop.faith] = old + 1
            end
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
        local unemp = {
            name = "Unemployed",
            r = 0.23,
            g = 0.23,
            b = 0.23,
        }
        local warr = {
            name = "Warriors",
            r = 0.43,
            g = 0.23,
            b = 0.13,
        }
        local child = {
            name = "Children",
            r = 0.83,
            g = 0.83,
            b = 0.83,
        }

        ---@type table<Job, number>
        local counts = {}
        counts[unemp] = 0
        counts[child] = 0
        counts[warr] = 0
        for _, province in pairs(provinces) do
            for __, pop in pairs(province.all_pops) do
                if pop.job then
                    if counts[pop.job] then
                        counts[pop.job] = counts[pop.job] + 1
                    else
                        counts[pop.job] = 1
                    end
                else
                    if pop.age > pop.race.teen_age then
                        if pop.drafted then
                            counts[warr] = counts[warr] + 1
                        else
                            counts[unemp] = counts[unemp] + 1
                        end
                    else
                        counts[child] = counts[child] + 1
                    end
                end
            end
        end

        ---@type Entry[]
        local entries = {}
        for job, count in pairs(counts) do
            entries[#entries + 1] = {
                weight = count,
                tooltip = job.name .. " (" .. count .. ")",
                r = job.r,
                g = job.g,
                b = job.b,
                name = job.name,
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
            carr_cap = math.floor(province.foragers_limit) + carr_cap
            population = population + province:population()
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