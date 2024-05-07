local pt = {}

local elevations_fixed = 0

local function fix_elevation(world)
	local fixed_elevation = false

	world:for_each_tile(function(i, _)
		local elevation = world.elevation[i]

		world:for_each_neighbor(i, function(ni)
			local neighbor_elevation = world.elevation[ni]

			if neighbor_elevation == elevation then
				elevation = elevation + world.rng:random() * 0.001
				world.elevation[i] = elevation

				fixed_elevation = true
				elevations_fixed = elevations_fixed + 1
			end
		end)
	end)

	return fixed_elevation
end

function pt.run(world)
	while fix_elevation(world) do
	end

	print("Elevations fixed: " .. elevations_fixed)
end

return pt