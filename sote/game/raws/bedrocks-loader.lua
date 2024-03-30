local d = {}

function d.load()
	local Bedrock = require "game.raws.bedrocks"
	Bedrock:new {
		name = "siltstone",
		r = 166 / 255,
		g = 131 / 255,
		b = 17 / 255,
		sand = 0.2,
		clay = 0.3,
		silt = 0.5,
		organics = 0,
		minerals = 0.05,
		weathering = 0.8,
		sedimentary = true,
		clastic = true,
		grain_size = 0.5
	}
	Bedrock:new {
		name = "claystone",
		r = 160 / 255,
		g = 40 / 255,
		b = 46 / 255,
		sand = 0.1,
		clay = 0.8,
		silt = 0.1,
		organics = 0,
		minerals = 0.05,
		weathering = 0.75,
		sedimentary = true,
		clastic = true,
		grain_size = 0
	}
	Bedrock:new {
		name = "mudstone",
		r = 139 / 255,
		g = 59 / 255,
		b = 59 / 255,
		sand = 0.1,
		clay = 0.7,
		silt = 0.2,
		organics = 0,
		minerals = 0.2,
		weathering = 0.8,
		sedimentary = true,
		clastic = true,
		grain_size = 0.1
	}
	Bedrock:new {
		name = "sandstone",
		r = 255 / 255,
		g = 234 / 255,
		b = 5 / 255,
		sand = 0.85,
		clay = 0.05,
		silt = 0.1,
		organics = 0,
		minerals = 0.05,
		weathering = 0.7,
		sedimentary = true,
		clastic = true,
		grain_size = 1,
		sedimentary_ocean_shallow = true
	}
	Bedrock:new {
		name = "conglomerate",
		r = 181 / 255,
		g = 230 / 255,
		b = 29 / 255,
		sand = 0.9,
		clay = 0.025,
		silt = 0.075,
		organics = 0,
		minerals = 0.15,
		weathering = 0.6,
		sedimentary = true,
		clastic = true,
		grain_size = 1,
		sedimentary_ocean_shallow = true
	}
	Bedrock:new {
		name = "shale",
		r = 239 / 255,
		g = 228 / 255,
		b = 176 / 255,
		sand = 0.1,
		clay = 0.7,
		silt = 0.2,
		organics = 0,
		minerals = 0.2,
		weathering = 0.8,
		sedimentary = true,
		clastic = true,
		grain_size = 0.4,
		sedimentary_ocean_shallow = true
	}
	Bedrock:new {
		name = "limestone",
		r = 82 / 255,
		g = 242 / 255,
		b = 77 / 255,
		sand = 0.4,
		clay = 0.3,
		silt = 0.3,
		organics = 0,
		minerals = 0.25,
		weathering = 1,
		sedimentary = true,
		sedimentary_ocean_deep = true
	}
	Bedrock:new {
		name = "dolostone",
		r = 34 / 255,
		g = 177 / 255,
		b = 76 / 255,
		sand = 0.35,
		clay = 0.325,
		silt = 0.325,
		organics = 0,
		minerals = 0.15,
		weathering = 1
	}
	Bedrock:new {
		name = "chert",
		r = 211 / 255,
		g = 221 / 255,
		b = 38 / 255,
		sand = 0.3,
		clay = 0.3,
		silt = 0.4,
		organics = 0,
		minerals = 0.01,
		weathering = 1,
		sedimentary = true
	}
	Bedrock:new {
		name = "chalk",
		r = 195 / 255,
		g = 195 / 255,
		b = 195 / 255,
		sand = 0.3,
		clay = 0.35,
		silt = 0.35,
		organics = 0,
		minerals = 0.01,
		weathering = 1,
		sedimentary = true
	}
	Bedrock:new {
		name = "granite",
		r = 215 / 255,
		g = 20 / 255,
		b = 20 / 255,
		sand = 1,
		clay = 0,
		silt = 0,
		organics = 0,
		minerals = 0.55,
		weathering = 0.4,
		acidity = 0.8,
		igneous_intrusive = true
	}
	Bedrock:new {
		name = "granodiorite",
		r = 218 / 255,
		g = 62 / 255,
		b = 116 / 255,
		sand = 0.95,
		clay = 0.05,
		silt = 0,
		organics = 0,
		minerals = 0.6,
		weathering = 0.5
	}
	Bedrock:new {
		name = "diorite",
		r = 222 / 255,
		g = 103 / 255,
		b = 252 / 255,
		sand = 0.65,
		clay = 0.35,
		silt = 0,
		organics = 0,
		minerals = 0.65,
		weathering = 0.75,
		acidity = 0.5,
		igneous_intrusive = true
	}
	Bedrock:new {
		name = "gabbro",
		r = 25 / 255,
		g = 25 / 255,
		b = 25 / 255,
		sand = 0.35,
		clay = 0.65,
		silt = 0,
		organics = 0,
		minerals = 0.7,
		weathering = 0.8,
		acidity = 0.2,
		igneous_intrusive = true,
		oceanic = true
	}
	Bedrock:new {
		name = "peridotite",
		r = 30 / 255,
		g = 125 / 255,
		b = 30 / 255,
		sand = 0.5,
		clay = 0.5,
		silt = 0,
		organics = 0,
		minerals = 0.75,
		weathering = 0.85
	}
	Bedrock:new {
		name = "rhyolite",
		r = 239 / 255,
		g = 151 / 255,
		b = 216 / 255,
		sand = 0.34,
		clay = 0.33,
		silt = 0.33,
		organics = 0,
		minerals = 0.85,
		weathering = 0.7,
		igneous_extrusive = true,
		acidity = 0.8
	}
	Bedrock:new {
		name = "dacite",
		r = 180 / 255,
		g = 30 / 255,
		b = 200 / 255,
		sand = 0.4,
		clay = 0.3,
		silt = 0.3,
		organics = 0,
		minerals = 0.9,
		weathering = 0.8,
		igneous_extrusive = true,
		acidity = 0.8
	}
	Bedrock:new {
		name = "andesite",
		r = 253 / 255,
		g = 84 / 255,
		b = 208 / 255,
		sand = 0.35,
		clay = 0.3,
		silt = 0.35,
		organics = 0,
		minerals = 0.95,
		weathering = 0.9,
		igneous_extrusive = true,
		acidity = 0.5
	}
	Bedrock:new {
		name = "basalt",
		r = 255 / 255,
		g = 10 / 255,
		b = 190 / 255,
		sand = 0.1,
		clay = 0.4,
		silt = 0.5,
		organics = 0,
		minerals = 1,
		weathering = 1,
		igneous_extrusive = true,
		acidity = 0.2
	}
	Bedrock:new {
		name = "komatiite",
		r = 135 / 255,
		g = 30 / 255,
		b = 30 / 255,
		sand = 0.05,
		clay = 0.25,
		silt = 0.7,
		organics = 0,
		minerals = 1,
		weathering = 1
	}
	Bedrock:new {
		name = "gneiss",
		r = 150 / 255,
		g = 63 / 255,
		b = 172 / 255,
		sand = 0.33,
		clay = 0.34,
		silt = 0.33,
		organics = 0,
		minerals = 0.4,
		weathering = 0.8,
		metamorphic_slate = true
	}
	Bedrock:new {
		name = "schist",
		r = 90 / 255,
		g = 90 / 255,
		b = 10 / 255,
		sand = 0.6,
		clay = 0.35,
		silt = 0.05,
		organics = 0,
		minerals = 0.4,
		weathering = 0.8,
		metamorphic_slate = true
	}
	Bedrock:new {
		name = "phyllite",
		r = 185 / 255,
		g = 122 / 255,
		b = 87 / 255,
		sand = 0.3,
		clay = 0.5,
		silt = 0.2,
		organics = 0,
		minerals = 0.4,
		weathering = 0.8,
		metamorphic_slate = true
	}
	Bedrock:new {
		name = "slate",
		r = 90 / 255,
		g = 90 / 255,
		b = 90 / 255,
		sand = 0.4,
		clay = 0.55,
		silt = 0.05,
		organics = 0,
		minerals = 0.4,
		weathering = 0.7,
		metamorphic_slate = true
	}
	Bedrock:new {
		name = "quartzite",
		r = 127 / 255,
		g = 127 / 255,
		b = 127 / 255,
		sand = 0.85,
		clay = 0.05,
		silt = 0.1,
		organics = 0,
		minerals = 0.05,
		weathering = 0.4,
		metamorphic_slate = true
	}
	Bedrock:new {
		name = "marble",
		r = 237 / 255,
		g = 236 / 255,
		b = 255 / 255,
		sand = 0.4,
		clay = 0.3,
		silt = 0.3,
		organics = 0,
		minerals = 0.25,
		weathering = 1,
		metamorphic_marble = true
	}
	Bedrock:new {
		name = "rock salt",
		r = 240 / 255,
		g = 240 / 255,
		b = 240 / 255,
		sand = 0,
		clay = 0,
		silt = 0,
		organics = 0,
		minerals = 0,
		weathering = 0,
		sedimentary = true,
		grain_size = 1,
		evaporative = true
	}
	Bedrock:new {
		name = "obsidian",
		r = 200 / 255,
		g = 191 / 255,
		b = 231 / 255,
		sand = 0,
		clay = 0,
		silt = 0,
		organics = 0,
		minerals = 0,
		weathering = 0,
		igneous_extrusive = true,
		acidity = 0.8
	}
end

return d
