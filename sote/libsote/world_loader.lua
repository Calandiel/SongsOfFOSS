local wl = {}

local function elev_to_gray(elev, is_land)
    local base_color_value = 94
    local land_color_factor = 161
    local water_color_factor = 93

    local final_color_value = 0
    if is_land then
        local land_color_ratio = math.min(elev / 13000, 1)
        final_color_value = base_color_value + land_color_ratio * land_color_factor
    else
        local water_color_ratio = math.max(math.min(elev, 0) / 13000, -1)
        final_color_value = base_color_value + water_color_ratio * water_color_factor - 1
    end

    final_color_value = math.floor(final_color_value + 0.5)
    return final_color_value
end

local mu = require("game.math-utils")

-- function wl.load_heightmap_from(world)
--     print("Loading heightmap")
--     local start = love.timer.getTime()

--     for _, tile in pairs(WORLD.tiles) do
--         local lat, lon = tile:latlon()
--         lat = mu.num_to_float(lat)
--         lon = mu.num_to_float(lon)
--         local q, r, face = world:latlon_to_hex_coords(lat, lon)
--         local generated_elev = world:get_elevation(q, r, face)
--         local is_land = world:get_is_land(q, r, face)
--         local elev_as_grey = elev_to_gray(generated_elev, is_land)
--         -- local r, g, b = read_pixel(tile, height)
--         -- r, g, b = color.to_255(r, g, b)
--         -- local r = math.random()
--         -- r = r * 255

--         local sea_level = 94
--         local elev = elev_as_grey - sea_level
--         if elev < 0 then
--             elev = elev / sea_level * 8000
--         else
--             elev = elev / (255 - sea_level) * 8000
--         end

--         tile.elevation = elev
--         tile.is_land = is_land
--     end

--     local duration = love.timer.getTime() - start
--     print("load_heightmap: " .. tostring(duration * 1000) .. "ms")
-- end

local data_loader = require("libsote.data_loader")

-- Specify the filename containing your data
local diff_filename = "C:/Users/Daniel Secrieru/AppData/Roaming/LOVE/sote/diff.txt"
local diff_fmt = ""
local exported_filename = "D:/temp/sote_output.txt"
local exported_fmt = "(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(.*)$"

-- Load data from the file
data_loader.loadDataFromFile(exported_filename, exported_fmt)

function wl.load_heightmap_from(world)
    print(love.filesystem.getSaveDirectory())

    local width = 1600
    local height = 800
    local file = love.filesystem.newFile("lua.txt", "w")
    local image_data = love.image.newImageData(width, height)

    for x = 0, width-1 do
        for y = 0, height-1 do
            local lon = mu.num_to_float(x / width * 2.0 * 3.1415927410125732)
            local lat = mu.num_to_float((y / height - 0.5) * 3.1415927410125732)
            local q, r, face = world:latlon_to_hex_coords(lat, lon)
            local index = world.coord[world:_key_from_coord(q, r, face)]
            if index == nil then
                local s = -(q + r)
                print(y, x, "q", q, "r", r, "s", s, "q - s", q - s, "r - q", r - q, "s - r", s - r)
            end
            local generated_elev = world:get_elevation(q, r, face)
            local imported_vals = data_loader.getValuesForCoordinates(x, y)
            local is_land = world:get_is_land(q, r, face)
            -- local is_land = imported_vals[5]
            local elev_as_grey = elev_to_gray(generated_elev, is_land)
            -- local elev_as_grey = elev_to_gray(imported_vals[4], is_land)

            local diff = math.abs(generated_elev - imported_vals[4])
            -- if diff > 0.001 then
                file:write(x .. " " .. y .. " " .. q .. " " .. r .. " " .. face .. " " .. string.format("%.17f", generated_elev) .. "\n")
            -- end

            local col_r = elev_as_grey / 255
            local col_g = elev_as_grey / 255
            local col_b = elev_as_grey / 255
            if face == 17 and q == 121 and r == -59
            then
                -- col_r = 1
                -- col_g = 0
                -- col_b = 0
                world:investigate_tile(q, r, face)
            end
            local a = 1 -- alpha (transparency), 1 is fully opaque

            image_data:setPixel(x, height-1 - y, col_r, col_g, col_b, a)
        end
    end

    -- Encode the ImageData to a PNG FileData
    local file_data = image_data:encode('png')

    -- Write the FileData to a file
    love.filesystem.write('output_new.png', file_data)
    file:close()
end

-- function wl.load_heightmap_from(world)
--     local width = 1600
--     local height = 800

--     local file = love.filesystem.newFile("lua.txt", "w")

--     -- for x = 62, 62 do
--     --     for y = 380, 380 do
--     for x = 0, width-1 do
--         for y = 0,height-1 do
--             local lon = mu.num_to_float(x / width * 2.0 * 3.1415927410125732)
--             local lat = mu.num_to_float((y / height - 0.5) * 3.1415927410125732)
--             local q, r, face = world:latlon_to_hex_coords(lat, lon, file)
--             file:write(x .. " " .. y .. " " .. q .. " " .. r .. " " .. face .. "\n")

--             -- local index = world.coord[world:_key_from_coord(q, r, face)]
--             -- if index == nil then
--             --     local s = -(q + r)
--             --     file:write(x .. " " .. y .. " " .. lon .. " " .. lat .. " " .. q .. " " .. r .. " " .. face .. " invalid: " .. q-s .. " " .. r-q .. " " .. s-r .. "\n")
--             -- else
--             --     file:write(x .. " " .. y .. " " .. lon .. " " .. lat .. " " .. q .. " " .. r .. " " .. face .. "\n")
--             -- end
--         end
--     end

--     file:close()
-- end

return wl