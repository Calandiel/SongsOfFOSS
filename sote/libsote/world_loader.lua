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

function wl.load_heightmap_from(world)
    print("Loading heightmap")

    local start = love.timer.getTime()

    for _, tile in pairs(WORLD.tiles) do
        local lat, lon = tile:latlon()
        local q, r, face = world:latlon_to_hex_coords(lat, lon)
        local generated_elev = world:get_elevation(q, r, face)
        local is_land = world:get_is_land(q, r, face)
        local elev_as_grey = elev_to_gray(generated_elev, is_land)

        local sea_level = 94
        local elev = elev_as_grey - sea_level
        if elev < 0 then
            elev = elev / sea_level * 8000
        else
            elev = elev / (255 - sea_level) * 8000
        end

        tile.elevation = elev
        tile.is_land = is_land
    end

    local duration = love.timer.getTime() - start
    print("load_heightmap: " .. tostring(duration * 1000) .. "ms")
end

-- local data_loader = require("libsote.debug_data_loader")
-- data_loader.loadDataFromFile("D:/temp/sote_output.txt")

-- function wl.load_heightmap_from(world)
--     -- print(love.filesystem.getSaveDirectory())
--     -- local file = love.filesystem.newFile("lua.txt", "w")

--     local width = 1600
--     local height = 800
--     local image_data = love.image.newImageData(width, height)

--     local start = love.timer.getTime()

--     for x = 0, width-1 do
--         for y = 0, height-1 do
--             local lon = x / width * 2.0 * math.pi
--             local lat = (y / height - 0.5) * math.pi
--             local q, r, face = world:latlon_to_hex_coords(lat, lon)
--             local generated_elev = world:get_elevation(q, r, face)
--             -- local imported_vals = data_loader.getValuesForCoordinates(x, y)
--             local is_land = world:get_is_land(q, r, face)
--             -- local is_land = imported_vals[5]
--             local elev_as_grey = elev_to_gray(generated_elev, is_land)

--             -- local diff = math.abs(generated_elev - imported_vals[4])
--             -- if diff > 0.001 then
--                 -- file:write(x .. " " .. y .. " " .. q .. " " .. r .. " " .. face .. " " .. string.format("%.17f", generated_elev) .. "\n")
--             -- end

--             local col_r = elev_as_grey / 255
--             local col_g = elev_as_grey / 255
--             local col_b = elev_as_grey / 255
--             -- if face == 17 and q == 121 and r == -59
--             -- then
--             --     -- col_r = 1
--             --     -- col_g = 0
--             --     -- col_b = 0
--             --     world:_investigate_tile(q, r, face)
--             -- end

--             image_data:setPixel(x, height-1 - y, col_r, col_g, col_b, 1)
--         end
--     end

--     local duration = love.timer.getTime() - start
--     print("load_heightmap: " .. tostring(duration * 1000) .. "ms")

--     -- Encode the ImageData to a PNG FileData
--     local file_data = image_data:encode('png')

--     -- Write the FileData to a file
--     love.filesystem.write('output.png', file_data)

--     -- file:close()
-- end

return wl