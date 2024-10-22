local gbm = {}

-- NOTE 2024.07.03: The comments are close to the original, but may have been edited for clarity and relevance to the current state.
-- In order to distinguish between the original comments and the new ones, the original ones are marked with "--*"

-- local cuts = { 150, 50, 10, 0 } -- Big cut, Medium cut, Small cut, No cut
-- local probs = { 0.1, 1, 5 } -- Probabilities for the cuts, in %

-- function gbm.run(world)
-- 	local rng = world.rng
-- 	local sampler = require("libsote.distribution").create_discrete_distribution(probs, rng)

-- 	-- Sand = 3, Clay = 2, Silt = 1
-- 	local contributing_factor = 3

-- 	--* We want to loop this process 3 times, once for each of the soil texture contributing factors
-- 	while contributing_factor > 0 do
-- 		world:for_each_tile(function(ti)
-- 			local move_base = cuts[sampler()]
-- 			if move_base == 0 then return end

-- 			local move_distance = math.floor(move_base * rng:random_float_min_max(0.5, 2))

-- 			--* Here we will start our formal cut algorithm and set criteria for bias

-- 			local moves_left = move_distance

-- 			local num_of_expansions = 0
-- 			if move_distance > 15 then
-- 				num_of_expansions = math.max(move_distance / 50, 1)
-- 			end

-- 			while moves_left > 0 do
-- 				moves_left = moves_left - 1
-- 			end
-- 		end)

-- 		world:for_each_tile(function(ti)
-- 		end)

-- 		contributing_factor = contributing_factor - 1
-- 	end
-- end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Whatever the original purpose of GenBiasMatrix was, it was not finalized, so a port does not make sense for now. The function below is a placeholder that will simply set the
-- corresponding outputs (sandSlider as TmpFloat_2 and siltMultiplier as TmpFloat_3) to a neutral 1, for the next stage in the pipeline.
-- In its current form, the original implementation produces the same output.

function gbm.run(world)
	world:fill_ffi_array(world.tmp_float_2, 1)
	world:fill_ffi_array(world.tmp_float_3, 1)
end

--* Generate soil texture from bedrock * our bias matrix. So, first order of business is to create unmodified standards for each rock type, as far as its contribution of 
--* silt, clay, sand and mineral nutrients.

--* Plan for soil creation ///

--* First, we create some local resolution biases in generation of silt, sand, clay. Then we will evaluate each tile, apply the biases, and then based on the bias and
--* bedrock type we will produce a specific quantity of sand, silt, and clay. We'll need a number of factors influencing this production. Some silt will be produced by glacial action,
--* either historic or current, some production of sand, silt, and clay will be the result of alluvial weathering, some silt will be produced as a result of the decomposition,
--* of organics into 2 micrometer humus particles, and some sand, silt, and clay will result from "other" weathering causes (seasonal temperature changes, etc).

--* Once we have this "mass" of material, we will then transport it either by wind or water. In effect, some tiles will have material which is mostly native, aka,
--* the material was produced by local bedrock weathering. However, some locations will be dominated by subsidies of material, such as loess soils and alluvial soils
--* along river banks. Some locations will be a mix.

--* We then either create 3 byte sized variables for a tile's soil texture (silt, sand and clay) or we simply create an enumeration for the 16 or so soil texture categories.

return gbm