local dcp = {}

dcp.align_to_sote_coords = false -- this will align hex world storage to match the order from original sote, very useful when debugging/validating port
dcp.map_tiles_from_file = false -- this will load cube world tile IDs mapping to hex coordinates from a file, as it's faster than computing them from lat lon
dcp.use_sote_climate_data = false -- climate model was ported from sote, but with some changes; this will enable import of original sote climate data from a csv file, to aid in debugging/validating port

dcp.save_maps = false -- this will export maps to PNG
dcp.maps_selection = {
	elevation = false,
	rocks = false,
	climate = false,
	waterflow = false,
	waterbodies = false,
	debug = false
}

-- seed = 58738 -- climate integration was done on this one
-- seed = 53201 -- banding
-- seed = 20836 -- north pole cells
-- seed = 6618 -- tiny islands?
-- seed = 49597 -- interesting looking one, huge northern ice cap (with lua climate model)
-- seed = 91170 -- huge lake
dcp.fixed_seed = nil
-- dcp.fixed_seed = 12177

return dcp