local oi = {}

-- open issue due the original comment
function oi.waterflow_weathering_base(water_movement)
	return math.pow(water_movement, 0.333) / 10 --* NEEDS REVISION BASED ON ELEVATION CHANGE TO INFER INTENSITY OF DRAINAGE
end

-- the bias matrix was not finalized by the original author, and sand/clay slider/bias was set to 1
-- however, the sign is used in gen-parent-material, so it's always positive, meaning always sand disposed
-- Demian said it might be due the sandy soil being more common, but let's keep it in open issues for now
function oi.sand_clay_bias(world, ti)
	return world.tmp_float_2[ti]
end

return oi