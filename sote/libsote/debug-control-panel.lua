local dcp = {}

dcp.map_tiles_from_file = true -- this will load cube world tile IDs mapping to hex from a file, as it's faster than computing them from lat lon
dcp.use_sote_climate_data = true -- climate model was ported from SotE, but with some changes; this will enable import of original SotE climate data from a csv file, to aid in debugging/validating port
dcp.use_sote_ice_data = true -- this will enable import of original SotE ice data from a csv file, to aid in debugging/validating port
dcp.align_to_sote_coords = dcp.use_sote_climate_data or dcp.use_sote_ice_data -- this will align hex world storage to match the order from original SotE, very useful when debugging/validating port

dcp.glaciation = {
	align_rng = true -- this will align RNG seed to match original SotE seed
}

dcp.soils = {
	align_rng = true -- this will align RNG seed to match original SotE seed
}

dcp.save_maps = false -- this will export maps to PNG
dcp.maps_selection = {
	elevation = false,
	rocks = false,
	climate = false,
	waterflow = false,
	waterbodies = false,
	watersheds = false,
	debug1 = false,
	debug2 = false
}

-- seed = 58738 -- climate integration was done on this one
-- seed = 53201 -- banding
-- seed = 20836 -- north pole cells
-- seed = 6618 -- tiny islands?
-- seed = 49597 -- interesting looking one, huge northern ice cap (with lua climate model)
-- seed = 91170 -- huge lake
dcp.fixed_seed = 12177

return dcp