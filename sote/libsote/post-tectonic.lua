local pt = {}

local elevations_fixed = 0

local function fix_elevation(world)
	local fixed_elevation = false

	world:for_each_tile(function(ti)
		local elevation = world.elevation[ti]

		for i = 0, world:neighbors_count(ti) - 1 do
			local nti = world.neighbors[ti * 6 + i]
			local neighbor_elevation = world.elevation[nti]

			if neighbor_elevation == elevation then
				elevation = elevation + world.rng:random() * 0.001
				world.elevation[ti] = elevation

				fixed_elevation = true
				elevations_fixed = elevations_fixed + 1
			end
		end
	end)

	return fixed_elevation
end

function pt.run(world)
	while fix_elevation(world) do
	end

	print("Elevations fixed: " .. elevations_fixed)
end

return pt