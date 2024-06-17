local gbm = {}

-- Generate soil texture from bedrock * our bias matrix. So, first order of business is to create unmodified standards for each rock type, as far as its contribution of 
-- silt, clay, sand and mineral nutrients.

--- Plan for soil creation ---

-- First, we create some local resolution biases in generation of silt, sand, clay. Then we will evaluate each tile, apply the biases, and then based on the bias and
-- bedrock type we will produce a specific quantity of sand, silt, and clay. We'll need a number of factors influencing this production. Some silt will be produced by glacial action,
-- either historic or current, some production of sand, silt, and clay will be the result of alluvial weathering, some silt will be produced as a result of the decomposition,
-- of organics into 2 micrometer humus particles, and some sand, silt, and clay will result from "other" weathering causes (seasonal temperature changes, etc).

-- Once we have this "mass" of material, we will then transport it either by wind or water. In effect, some tiles will have material which is mostly native, aka,
-- the material was produced by local bedrock weathering. However, some locations will be dominated by subsidies of material, such as loess soils and alluvial soils
-- along river banks. Some locations will be a mix.

-- We then either create 3 byte sized variables for a tile's soil texture (silt, sand and clay) or we simply create an enumeration for the 16 or so soil texture categories.

function gbm.run()
end

return gbm