local ts = {}

local wgu = require "libsote.world-gen-utils"

function ts.run(world)
	world:for_each_tile(function(ti)
		if not world.is_land[ti] then return end

		local water_movement_contribution = math.max(0, math.sqrt(world.water_movement[ti]) - 10)
		local true_water_calc = world.jan_rainfall[ti] + world.jul_rainfall[ti] + water_movement_contribution
		local wind_factor = world.jan_wind_speed[ti] --*+ world.jul_wind_speed[ti]
		wind_factor = math.min(25, wind_factor)
		wind_factor = (1 - wind_factor / 25) * 0.65 + 0.35
		local permeability = wgu.permiation_calc(world.sand[ti], world.silt[ti], world.clay[ti])
		true_water_calc = true_water_calc * wind_factor * permeability

		local new_silt = world.silt[ti]

		if true_water_calc <= 60 then
			new_silt = new_silt * (true_water_calc / 60)
		end
		if true_water_calc <= 30 then
			new_silt = new_silt * math.pow(true_water_calc / 30, 2)
		end
		if true_water_calc <= 15 then
			new_silt = new_silt * math.pow(true_water_calc / 15, 2)
		end

		local total_material = world.sand[ti] + world.silt[ti] + world.clay[ti]
		local modified_material = total_material - (world.silt[ti] - new_silt)

		world.silt[ti] = math.floor(new_silt)
		world.mineral_richness[ti] = math.floor(world.mineral_richness[ti] * (modified_material / total_material))
	end)
end

return ts