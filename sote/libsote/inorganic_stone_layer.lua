local isl = {}

function isl.load()
    local stone_layer = require "libsote.stone_layer"

    stone_layer:new {
        name = "SANDSTONE",
        r = 255 / 255,
        g = 234 / 255,
        b =   5 / 255,
        sedimentary = true,
        clastic = true,
        grain_size = 1,
        sedimentary_ocean_shallow = true,
    }
    stone_layer:new {
        name = "SILTSTONE",
        r = 166 / 255,
        g = 131 / 255,
        b =  17 / 255,
        sedimentary = true,
        clastic = true,
        grain_size = 0.5,
    }
    stone_layer:new {
        name = "MUDSTONE",
        r = 139 / 255,
        g =  59 / 255,
        b =  59 / 255,
        sedimentary = true,
        clastic = true,
        grain_size = 0.1,
    }
    stone_layer:new {
        name = "SHALE",
        r = 239 / 255,
        g = 228 / 255,
        b = 176 / 255,
        sedimentary = true,
        clastic = true,
        grain_size = 0.4,
        sedimentary_ocean_shallow = true,
    }
    stone_layer:new {
        name = "CLAYSTONE",
        r = 160 / 255,
        g =  40 / 255,
        b =  46 / 255,
        sedimentary = true,
        clastic = true,
        grain_size = 0,
    }
    stone_layer:new {
        name = "ROCK_SALT",
        r = 240 / 255,
        g = 240 / 255,
        b = 240 / 255,
        sedimentary = true,
        grain_size = 1,
        evaporative = true,
    }
    stone_layer:new {
        name = "LIMESTONE",
        r =  82 / 255,
        g = 242 / 255,
        b =  77 / 255,
        sedimentary = true,
        sedimentary_ocean_deep = true,
    }
    stone_layer:new {
        name = "CONGLOMERATE",
        r = 181 / 255,
        g = 230 / 255,
        b =  29 / 255,
        sedimentary = true,
        clastic = true,
        grain_size = 1,
        sedimentary_ocean_shallow = true,
    }
    stone_layer:new {
        name = "DOLOMITE",
        r =  34 / 255,
        g = 177 / 255,
        b =  76 / 255,
        sedimentary = true,
        evaporative = true,
    }
    stone_layer:new {
        name = "CHERT",
        r = 211 / 255,
        g = 221 / 255,
        b =  38 / 255,
        sedimentary = true,
    }
    stone_layer:new {
        name = "CHALK",
        r = 195 / 255,
        g = 195 / 255,
        b = 195 / 255,
        sedimentary = true,
    }
    stone_layer:new {
        name = "GRANITE",
        r = 215 / 255,
        g =  20 / 255,
        b =  20 / 255,
        acidity = 0.8,
        igneous_intrusive = true,
    }
    stone_layer:new {
        name = "DIORITE",
        r = 222 / 255,
        g = 103 / 255,
        b = 252 / 255,
        acidity = 0.5,
        igneous_intrusive = true,
    }
    stone_layer:new {
        name = "GABBRO",
        r =  25 / 255,
        g =  25 / 255,
        b =  25 / 255,
        acidity = 0.2,
        igneous_intrusive = true,
        oceanic = true,
    }
    stone_layer:new {
        name = "RHYOLITE",
        r = 239 / 255,
        g = 151 / 255,
        b = 216 / 255,
        igneous_extrusive = true,
        acidity = 0.8,
    }
    stone_layer:new {
        name = "BASALT",
        r = 255 / 255,
        g =  10 / 255,
        b = 190 / 255,
        igneous_extrusive = true,
        acidity = 0.2,
    }
    stone_layer:new {
        name = "ANDESITE",
        r = 253 / 255,
        g =  84 / 255,
        b = 208 / 255,
        igneous_extrusive = true,
        acidity = 0.5,
    }
    stone_layer:new {
        name = "DACITE",
        r = 180 / 255,
        g =  30 / 255,
        b = 200 / 255,
        igneous_extrusive = true,
        acidity = 0.8,
    }
    stone_layer:new {
        name = "OBSIDIAN",
        r = 200 / 255,
        g = 191 / 255,
        b = 231 / 255,
        igneous_extrusive = true,
        acidity = 0.8,
    }
    stone_layer:new {
        name = "QUARTZITE",
        r = 127 / 255,
        g = 127 / 255,
        b = 127 / 255,
        metamorphic_slate = true,
    }
    stone_layer:new {
        name = "SLATE",
        r =  90 / 255,
        g =  90 / 255,
        b =  90 / 255,
        metamorphic_slate = true,
    }
    stone_layer:new {
        name = "PHYLLITE",
        r = 185 / 255,
        g = 122 / 255,
        b =  87 / 255,
        metamorphic_slate = true,
    }
    stone_layer:new {
        name = "SCHIST",
        r =  90 / 255,
        g =  90 / 255,
        b =  10 / 255,
        metamorphic_slate = true,
    }
    stone_layer:new {
        name = "GNEISS",
        r = 150 / 255,
        g =  63 / 255,
        b = 172 / 255,
        metamorphic_slate = true,
    }
    stone_layer:new {
        name = "MARBLE",
        r = 237 / 255,
        g = 236 / 255,
        b = 225 / 255,
        metamorphic_marble = true,
    }
    end

return isl