local gvc = {}

local ROCK_TYPES = require "libsote.rock-type".TYPES

local world
local rng
local already_checked

local mixed_volcano_tiles = {}
local basic_volcano_tiles = {}

local function gen_volcanic_silt()
end

function gvc.run(world_obj)
	world = world_obj
	already_checked = world.tmp_bool_1

	rng = world.rng
	local align_rng = require("libsote.debug-control-panel").soils.align_rng
	local preserved_state = nil
	if align_rng then
		preserved_state = rng:get_state()
		rng:set_seed(world.seed + 19832)
	end

	world:fill_ffi_array(already_checked, false)

	--* Generating lists for both types of volcanoes that will participate
	world:for_each_tile(function(ti)
		local rock_type = world.rock_type[ti]

		if rock_type == ROCK_TYPES.mixed_volcanics then
			if rng:random_int_max(100) < 1 then table.insert(mixed_volcano_tiles, ti) end
		elseif rock_type == ROCK_TYPES.basic_volcanics then
			if rng:random_int_max(100) < 1 then table.insert(basic_volcano_tiles, ti) end
		end
	end)

	local ticker = 1

	--* Use this loop to generate 2 different outcomes for each volcano type. Same code used, just insert different standards for each
	while ticker >= 0 do
		ticker = ticker - 1
		gen_volcanic_silt()
	end

	if align_rng then
		rng:set_state(preserved_state)
	end
end

return gvc