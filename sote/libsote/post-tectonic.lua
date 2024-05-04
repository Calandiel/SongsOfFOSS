local pt = {}

local function fix_elevation(world)
    local fixed_elevation = false

    for i = 0, world.tile_count - 1 do
        local elevation = world:get_elevation_by_index(i)

        world:for_each_neighbor(i, function(neighbor_index)
            local neighbor_elevation = world:get_elevation_by_index(neighbor_index)

            if neighbor_elevation == elevation then
                elevation = elevation + world.rng:random() * 0.001
                -- print("fixing elevation", i, world:get_elevation_by_index(i), elevation)
                world:set_elevation_by_index(i, elevation)

                fixed_elevation = true
            end
        end)
    end

    return fixed_elevation
end

function pt.run(world)
    while fix_elevation(world) do
    end
end

return pt