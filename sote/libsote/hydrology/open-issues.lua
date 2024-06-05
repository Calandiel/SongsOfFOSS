local oi = {}

-- not part of the lua implementation of climate simulation
-- Calandiel said it was meant to be phased out, so just use a hardcoded value for now
function oi.seasonal_humidity()
	return 0.3
end

-- not implemented in SotE
function oi.add_sea_ice(world, ti)
	world.snow[ti] = 0
end

-- the formula in the original is overriden by 0, for as yet unknown reasons
function oi.current_saturation(world, ti, capacity)
	--return world.soil_moisture[ti] / capacity
	return 0
end

-- game\scenes\world-loader.lua:process_pixel does not seem to handle a rank 7 land waterflow (>= 1,000,000 or color 2, 35, 209)
-- they do seem to occur, at least during worldgen waterflow calculations, but perhaps they are clamped down somewhere later on?
function oi.waterflow_for_rank_7()
	return 50000
end

return oi