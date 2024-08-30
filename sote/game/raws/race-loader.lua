
local retrieve_use_case = require "game.raws.raws-utils".trade_good_use_case

local ll = {}

-- temp stock values for body size and related needs and efficiencies
local small_size = 0.5
local dwarf_size = 0.75
local medium_size = 1
local large_size = 1.25
local largest_size = 1.5

function ll.load()
	local Race = require "game.raws.race"

	local human_male_portrait = {
		folder = "human",
		layers = {"base.PNG", "eye.PNG", "nose.PNG", "cloth.PNG", "beard.PNG", "brow.PNG", "hair_male.PNG", "headgear.PNG"},
		layers_groups = {
		}
	}

	local human_female_portrait = {
		folder = "human",
		layers = {"base.PNG", "eye.PNG", "nose.PNG", "cloth.PNG", "brow.PNG", "hair_female.PNG", "headgear.PNG"},
		layers_groups = {
		}
	}

	---@type PortraitDescription
	local null_portrait = {
		folder = "null_middle",
		layers = {"hair_behind.png", "base.png", "neck.png", "cheeks.png",
					"chin.png", "ear.png", "eyes.png", "nose.png", "mouth.png", "hair.png", "clothes.png", "beard.png"},
		layers_groups = {
			hair = {"hair_behind.png", "hair.png"}
		}
	}

	-- BASE: HUMAN
	Race:new {
		name = "human",
		description = "humans",
		r = 0.8,
		g = 0.8,
		b = 0.8,
		male_portrait = {
			fallback = human_male_portrait
		},
		female_portrait = {
			fallback = human_female_portrait
		},
		female_needs = {
			{need = NEED.FOOD, use_case = WATER_USE_CASE, required = 1},
			{need = NEED.FOOD, use_case = CALORIES_USE_CASE, required = 1}, -- 1000
			{need = NEED.FOOD, use_case = retrieve_use_case('fruit'), required = 0.5}, --- 500
			{need = NEED.FOOD, use_case = retrieve_use_case('meat'), required = 0.25}, --- 500
			{need = NEED.CLOTHING, use_case = retrieve_use_case('clothes'), required = 1},
			{need = NEED.FURNITURE, use_case = retrieve_use_case('furniture'), required = 1},
			{need = NEED.HEALTHCARE, use_case = retrieve_use_case('healthcare'), required = 1},
			{need = NEED.LUXURY, use_case = retrieve_use_case('liquors'), required = 1}
		},
		male_needs = {
			{need = NEED.FOOD, use_case = WATER_USE_CASE, required = 1},
			{need = NEED.FOOD, use_case = CALORIES_USE_CASE, required = 1}, -- 1000
			{need = NEED.FOOD, use_case = retrieve_use_case('fruit'), required = 0.5}, --- 500
			{need = NEED.FOOD, use_case = retrieve_use_case('meat'), required = 0.25}, --- 500
			{need = NEED.CLOTHING, use_case = retrieve_use_case('clothes'), required = 1},
			{need = NEED.FURNITURE, use_case = retrieve_use_case('furniture'), required = 1},
			{need = NEED.HEALTHCARE, use_case = retrieve_use_case('healthcare'), required = 1},
			{need = NEED.LUXURY, use_case = retrieve_use_case('liquors'), required = 1}
		},
		female_efficiency = {
			[JOBTYPE.FARMER] = 1,
			[JOBTYPE.ARTISAN] = 1,
			[JOBTYPE.CLERK] = 1,
			[JOBTYPE.LABOURER] = 1,
			[JOBTYPE.WARRIOR] = 1,
			[JOBTYPE.HAULING] = 1,
			[JOBTYPE.FORAGER] = 1,
			[JOBTYPE.HUNTING] = 1
		},
		male_efficiency = {
			[JOBTYPE.FARMER] = 1,
			[JOBTYPE.ARTISAN] = 1,
			[JOBTYPE.CLERK] = 1,
			[JOBTYPE.LABOURER] = 1,
			[JOBTYPE.WARRIOR] = 1,
			[JOBTYPE.HAULING] = 1,
			[JOBTYPE.FORAGER] = 1,
			[JOBTYPE.HUNTING] = 1
		},
		icon = 'barbute.png',
		males_per_hundred_females = 104,
		child_age = 3,
		teen_age = 12,
		adult_age = 16,
		middle_age = 40,
		elder_age = 65,
		max_age = 85,
		minimum_comfortable_temperature = 5,
		minimum_absolute_temperature = -10,
		minimum_comfortable_elevation = 0,
		fecundity = 1,
		spotting = 1,
		visibility = 1,
		female_body_size = 1,
		female_infrastructure_needs = 1,
		male_body_size = 1,
		male_infrastructure_needs = 1,
		carrying_capacity_weight = 1
	}

	---@type PortraitDescription
	local beaver_portrait = {
		folder = "beaver",
		layers = {"cloth_behind.png", "base.png", "over_1.png", "over_2.png", "ear.png", "cloth.png"},
		layers_groups = {
			cloth = {"cloth_behind.png", "cloth.png"}
		}
	}
	Race:new {
		name = 'high beaver',
		r = 0.7,
		g = 0.4,
		b = 0.3,
		icon = 'beaver.png',
		male_portrait = {
			--- fallback is a portrait description which is active when needed portrait is not provided
			fallback = beaver_portrait,

			--- just to list all possible fields
			child = beaver_portrait,
			teen = beaver_portrait,
			adult = beaver_portrait,
			middle = beaver_portrait,
			elder = beaver_portrait
		},
		female_portrait = {
			fallback = beaver_portrait
		},
		description = 'high beavers',
		males_per_hundred_females = 110,
		child_age = 4,
		teen_age = 15,
		adult_age = 20,
		middle_age = 50,
		elder_age = 70,
		max_age = 100,
		minimum_comfortable_temperature = -15,
		minimum_absolute_temperature = -30,
		fecundity = 0.85,
		spotting = 0.75,
		visibility = 1,
		female_body_size = large_size,
		female_efficiency = {
			[JOBTYPE.FARMER] = 1,
			[JOBTYPE.ARTISAN] = 1.5, -- beavers are natural builders
			[JOBTYPE.CLERK] = 1,
			[JOBTYPE.LABOURER] = large_size,
			[JOBTYPE.WARRIOR] = 1.125, -- beavers have sharp teeth
			[JOBTYPE.HAULING] = large_size,
			[JOBTYPE.FORAGER] = 1.25, -- beavers are herbavores
			[JOBTYPE.HUNTING] = 0.5 -- beavers are herbavores
		},
		female_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = large_size,
				[CALORIES_USE_CASE] = large_size,		-- 1250 kcal
				[retrieve_use_case('cambium')] = 0.5,			--  750 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = large_size * 0.5 -- beavers have really nice fur
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = large_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = large_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = large_size,
			}
		},
		female_infrastructure_needs = large_size,
		male_body_size = largest_size,
		male_efficiency = {
			[JOBTYPE.FARMER] = 1,
			[JOBTYPE.ARTISAN] = 1.5, -- beavers are natural builders
			[JOBTYPE.CLERK] = 1,
			[JOBTYPE.LABOURER] = largest_size,
			[JOBTYPE.WARRIOR] = 1.25, -- beavers have sharp teeth
			[JOBTYPE.HAULING] = largest_size,
			[JOBTYPE.FORAGER] = 1.25, -- beavers are herbavores
			[JOBTYPE.HUNTING] = 0.5 -- beavers are herbavores
		},
		male_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = largest_size,
				[CALORIES_USE_CASE] = largest_size,	-- 1500 kcal
				[retrieve_use_case('cambium')] = 0.5,				-- 1000 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = largest_size * 0.5 -- beavers have really nice fur
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = largest_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = largest_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = largest_size,
			}
		},
		male_infrastructure_needs = largest_size,
		carrying_capacity_weight = largest_size,
		requires_large_river = true
	}

	---@type PortraitDescription
	local gnoll_portrait = {
		folder = "gnoll",
		layers = {"base.PNG", "braid.PNG", "spine.PNG", "pattern.PNG", "eye.PNG"},
		layers_groups = {}
	}
	Race:new {
		name = 'gnoll',
		r = 0.7,
		g = 0.1,
		b = 0.4,
		icon = 'hound.png',
		male_portrait = {
			fallback = gnoll_portrait
		},
		female_portrait = {
			fallback = gnoll_portrait
		},
		description = 'gnolls',
		males_per_hundred_females = 50,
		child_age = 2,
		teen_age = 6,
		adult_age = 10,
		middle_age = 20,
		elder_age = 35,
		max_age = 40,
		minimum_comfortable_temperature = -5,
		minimum_absolute_temperature = -20,
		fecundity = 1.15,
		spotting = 1.25,
		visibility = 1.25,
		female_body_size = largest_size,
		female_efficiency = {
			[JOBTYPE.FARMER] = 0.75,
			[JOBTYPE.ARTISAN] = 0.5,
			[JOBTYPE.CLERK] = 0.5,
			[JOBTYPE.LABOURER] = largest_size,
			[JOBTYPE.WARRIOR] = 1.5, -- gnolls have sharp teeth
			[JOBTYPE.HAULING] = largest_size,
			[JOBTYPE.FORAGER] = 1,
			[JOBTYPE.HUNTING] = 1.5
		},
		female_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = largest_size,
				[CALORIES_USE_CASE] = largest_size,	-- 1500 kcal
				[retrieve_use_case('meat')] = 0.5,					-- 1000 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = largest_size * 0.5, -- gnolls have nice fur
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = largest_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = largest_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = largest_size,
			},

		},
		female_infrastructure_needs = large_size,
		male_body_size = large_size,
		male_efficiency = {
			[JOBTYPE.FARMER] = 0.75,
			[JOBTYPE.ARTISAN] = 0.5,
			[JOBTYPE.CLERK] = 0.5,
			[JOBTYPE.LABOURER] = large_size,
			[JOBTYPE.WARRIOR] = 1.25, -- gnolls have sharp teeth
			[JOBTYPE.HAULING] = large_size,
			[JOBTYPE.FORAGER] = 1,
			[JOBTYPE.HUNTING] = 1.5
		},
		male_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = large_size,
				[CALORIES_USE_CASE] = large_size,		-- 1250 kcal
				[retrieve_use_case('meat')] = 0.5,					--  750 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = large_size * 0.5, -- gnolls have nice fur
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = large_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = large_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = large_size,
			},

		},
		male_infrastructure_needs = medium_size,
		carrying_capacity_weight = largest_size
	}

	---@type PortraitDescription
	local orc_portrait = {
		folder = "orc",
		layers = {"base.PNG", "chin.PNG", "right_eye.PNG", "nose_mouth.PNG", "left_eye.PNG", "pattern.PNG", "hair.PNG", "cloth.PNG"},
		layers_groups = {
			eyes = {"right_eye.PNG", "left_eye.PNG"}
		}
	}
	Race:new {
		name = 'orc',
		r = 0.1,
		g = 0.7,
		b = 0.7,
		icon = 'orc-head.png',
		male_portrait = {
			fallback = orc_portrait
		},
		female_portrait = {
			fallback = orc_portrait
		},
		description = 'orc',
		males_per_hundred_females = 90,
		child_age = 3,
		teen_age = 7,
		adult_age = 10,
		middle_age = 30,
		elder_age = 50,
		max_age = 65,
		minimum_comfortable_temperature = 5,
		minimum_absolute_temperature = -10,
		fecundity = 1.1,
		spotting = 1.0,
		visibility = 1.25,
		female_body_size = large_size,
		female_efficiency = {
			[JOBTYPE.FARMER] = 	0.75,
			[JOBTYPE.ARTISAN] = 0.5,
			[JOBTYPE.CLERK] = 0.75,
			[JOBTYPE.LABOURER] = large_size,
			[JOBTYPE.WARRIOR] = 1.25, -- orks have tusks
			[JOBTYPE.HAULING] = large_size,
			[JOBTYPE.FORAGER] = 1.5,
			[JOBTYPE.HUNTING] = 1.25
		},
		female_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = largest_size,
				[CALORIES_USE_CASE] = 2.5,		-- 2500 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = large_size
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = large_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = large_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = large_size,
			},

		},
		female_infrastructure_needs = medium_size,
		male_body_size = large_size,
		male_efficiency = {
			[JOBTYPE.FARMER] = 	0.75,
			[JOBTYPE.ARTISAN] = 0.5,
			[JOBTYPE.CLERK] = 0.75,
			[JOBTYPE.LABOURER] = large_size,
			[JOBTYPE.WARRIOR] = 1.25, -- orks have tusks
			[JOBTYPE.HAULING] = large_size,
			[JOBTYPE.FORAGER] = 1.5,
			[JOBTYPE.HUNTING] = 1.25
		},
		male_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = largest_size,
				[CALORIES_USE_CASE] = 2.5,		-- 2500 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = large_size
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = large_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = large_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = large_size,
			},

		},
		male_infrastructure_needs = medium_size,
		carrying_capacity_weight = large_size,
		requires_large_forest = true,
	}

	---@type PortraitDescription
	local elf_portrait = {
		folder = "elf",
		layers = {"hair_back.PNG", "ear_right.PNG", "base.PNG", "ear_left.PNG", "cloth.PNG", "brow.PNG", "eyelash.PNG", "hair_front.PNG", "flowers.PNG"},
		layers_groups = {
			hair = {"hair_back.PNG", "hair_front.PNG"},
			ears = {"ear_right.PNG", "ear_left.PNG"}
		}
	}

	---@type PortraitDescription
	local elf_bald_portrait = {
		folder = "elf",
		layers = {"ear_right.PNG", "base.PNG", "ear_left.PNG", "cloth.PNG", "brow.PNG", "eyelash.PNG"},
		layers_groups = {
			ears = {"ear_right.PNG", "ear_left.PNG"}
		}
	}

	Race:new {
		name = 'elf',
		r = 0.1,
		g = 0.1,
		b = 0.9,
		icon = 'woman-elf-face.png',
		male_portrait = {
			fallback = elf_bald_portrait
		},
		female_portrait = {
			fallback = elf_portrait
		},
		description = 'elves',
		males_per_hundred_females = 95,
		child_age = 10,
		teen_age = 40,
		adult_age = 60,
		middle_age = 140,
		elder_age = 195,
		max_age = 250,
		minimum_comfortable_temperature = 0,
		minimum_absolute_temperature = -15,
		fecundity = 0.5,
		spotting = 1.5,
		visibility = 0.5,
		female_body_size = medium_size,
		female_efficiency = {
			[JOBTYPE.FARMER] = 1.25,
			[JOBTYPE.ARTISAN] = 1.5,
			[JOBTYPE.CLERK] = 1.5,
			[JOBTYPE.LABOURER] = medium_size * 0.75,
			[JOBTYPE.WARRIOR] = 1.5,
			[JOBTYPE.HAULING] = medium_size * 0.75,
			[JOBTYPE.FORAGER] = 1.125,
			[JOBTYPE.HUNTING] = 1
		},
		female_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = medium_size * 0.75,
				[CALORIES_USE_CASE] = dwarf_size,		--  750 kcal
				[retrieve_use_case('fruit')] = 0.45,				--  450 kcal
				[retrieve_use_case('meat')] = 0.4,					--  800 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = medium_size
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = medium_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = medium_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = medium_size,
			},

		},
		female_infrastructure_needs = large_size,
		male_body_size = medium_size,
		male_efficiency = {
			[JOBTYPE.FARMER] = 1.25,
			[JOBTYPE.ARTISAN] = 1.5,
			[JOBTYPE.CLERK] = 1.5,
			[JOBTYPE.LABOURER] = medium_size * 0.75,
			[JOBTYPE.WARRIOR] = 1.5,
			[JOBTYPE.HAULING] = medium_size * 0.75,
			[JOBTYPE.FORAGER] = 1.125,
			[JOBTYPE.HUNTING] = 1
		},
		male_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = medium_size * 0.75,
				[CALORIES_USE_CASE] = dwarf_size,		--  750 kcal
				[retrieve_use_case('fruit')] = 0.45,				--  450 kcal
				[retrieve_use_case('meat')] = 0.4,					--  800 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = medium_size
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = medium_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = medium_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = medium_size,
			},

		},
		male_infrastructure_needs = large_size,
		carrying_capacity_weight = medium_size,
		requires_large_forest = true
	}

	---@type PortraitDescription
	local dwarf_portrait = {
		folder = "dwarf",
		layers = {"cloth behind.PNG", "base.PNG", "cloth.PNG", "beard_front.PNG", "hair_front.PNG", "hat.PNG"},
		layers_groups = {cloth = {"cloth behind.PNG", "cloth.PNG"}}
	}
	Race:new {
		name = 'dwarf',
		r = 0.9,
		g = 0.1,
		b = 0.1,
		icon = 'dwarf.png',
		male_portrait = {
			fallback = dwarf_portrait
		},
		female_portrait = {
			fallback = dwarf_portrait
		},
		description = 'dwarf',
		males_per_hundred_females = 105,
		child_age = 4,
		teen_age = 20,
		adult_age = 30,
		middle_age = 75,
		elder_age = 110,
		max_age = 150,
		minimum_comfortable_temperature = -5,
		minimum_absolute_temperature = -20,
		minimum_comfortable_elevation = 800,
		fecundity = 0.75,
		spotting = 1.0,
		visibility = 1.0,
		female_body_size = dwarf_size,
		female_efficiency = {
			[JOBTYPE.FARMER] = 1.25,
			[JOBTYPE.ARTISAN] = 1.5,
			[JOBTYPE.CLERK] = 1.25,
			[JOBTYPE.LABOURER] = dwarf_size * 2, -- a short, sturdy creature fond of drink and industry
			[JOBTYPE.WARRIOR] = 1,
			[JOBTYPE.HAULING] = dwarf_size * 2, -- a short, sturdy creature fond of drink and industry
			[JOBTYPE.FORAGER] = 1,
			[JOBTYPE.HUNTING] = 1
		},
		female_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = dwarf_size,
				[CALORIES_USE_CASE] = medium_size,	-- 1000 kcal
				[retrieve_use_case('fruit')] = 0.375,			--  375 kcal
				[retrieve_use_case('meat')] = 0.375,			--  750 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = dwarf_size
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = dwarf_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = dwarf_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = large_size, -- a short, sturdy creature fond of drink and industry
			},

		},
		female_infrastructure_needs = large_size,
		male_body_size = dwarf_size,
		male_efficiency = {
			[JOBTYPE.FARMER] = 1.25,
			[JOBTYPE.ARTISAN] = 1.5,
			[JOBTYPE.CLERK] = 1.25,
			[JOBTYPE.LABOURER] = dwarf_size * 2, -- a short, sturdy creature fond of drink and industry
			[JOBTYPE.WARRIOR] = 1,
			[JOBTYPE.HAULING] = dwarf_size * 2, -- a short, sturdy creature fond of drink and industry
			[JOBTYPE.FORAGER] = 1,
			[JOBTYPE.HUNTING] = 1
		},
		male_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = dwarf_size,
				[CALORIES_USE_CASE] = medium_size,	-- 1000 kcal
				[retrieve_use_case('fruit')] = 0.375,			--  375 kcal
				[retrieve_use_case('meat')] = 0.375,			--  750 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = dwarf_size
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = dwarf_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = dwarf_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = large_size, -- a short, sturdy creature fond of drink and industry
			},

		},
		male_infrastructure_needs = large_size,
		carrying_capacity_weight = large_size,
	}

	---@type PortraitDescription
	local goblin_portrait = {
		folder = "goblin",
		layers = {"04.png", "05.png", "055.png", "06.png", "07.png", "08.png", "09.png", "10.png", "11.png"},
		layers_groups = {
			ear = {"04.png", "07.png"},
			hair = {"055.png", "10.png"}
		}
	}
	Race:new {
		name = 'goblin',
		r = 0.1,
		g = 0.9,
		b = 0.1,
		icon = 'goblin.png',
		male_portrait = {
			fallback = goblin_portrait
		},
		female_portrait = {
			fallback = goblin_portrait
		},
		description = 'goblin',
		males_per_hundred_females = 110,
		child_age = 1,
		teen_age = 4,
		adult_age = 6,
		middle_age = 15,
		elder_age = 32,
		max_age = 47,
		minimum_comfortable_temperature = 5,
		minimum_absolute_temperature = -10,
		fecundity = 1.25,
		spotting = 0.75,
		visibility = 0.75,
		female_body_size = small_size,
		female_efficiency = {
			[JOBTYPE.FARMER] = 0.75,
			[JOBTYPE.ARTISAN] = 0.75,
			[JOBTYPE.CLERK] = 1.125,
			[JOBTYPE.LABOURER] = small_size,
			[JOBTYPE.WARRIOR] = small_size * 1.5, -- goblins find raiding profitable
			[JOBTYPE.HAULING] = small_size * 1.5, -- goblins find raiding profitable
			[JOBTYPE.FORAGER] = 0.875,
			[JOBTYPE.HUNTING] = 1
		},
		female_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = small_size,
				[CALORIES_USE_CASE] = small_size,	-- 500 kcal
				[retrieve_use_case('meat')] = 0.125,			-- 250 kcal
				[retrieve_use_case('fruit')] = 0.125,			-- 125 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = small_size
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = small_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = small_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = small_size,
			},

		},
		female_infrastructure_needs = small_size,
		male_body_size = small_size,
		male_efficiency = {
			[JOBTYPE.FARMER] = 0.75,
			[JOBTYPE.ARTISAN] = 0.75,
			[JOBTYPE.CLERK] = 1.125,
			[JOBTYPE.LABOURER] = small_size,
			[JOBTYPE.WARRIOR] = small_size * 1.5, -- goblins find raiding profitable
			[JOBTYPE.HAULING] = small_size * 1.5, -- goblins find raiding profitable
			[JOBTYPE.FORAGER] = 0.875,
			[JOBTYPE.HUNTING] = 1
		},
		male_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = small_size,
				[CALORIES_USE_CASE] = small_size,	-- 500 kcal
				[retrieve_use_case('meat')] = 0.125,			-- 250 kcal
				[retrieve_use_case('fruit')] = 0.125,			-- 125 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = small_size
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = small_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = small_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = small_size,
			},

		},
		male_infrastructure_needs = small_size,
		carrying_capacity_weight = small_size,
	}

	---@type PortraitDescription
	local vermen_portrait = {
		folder = "vermen",
		layers = {"ear_behind.PNG", "base.PNG", "ear_front.PNG", "eye.PNG", "patterns.PNG", "cloth.PNG", "hat.PNG"},
		layers_groups = {
			ear = {"ear_behind.PNG", "ear_front.PNG"}
		}
	}
	Race:new {
		name = 'verman',
		r = 0.4,
		g = 0.4,
		b = 0.4,
		icon = 'rat.png',
		male_portrait = {
			fallback = vermen_portrait
		},
		female_portrait = {
			fallback = vermen_portrait
		},
		description = 'vermen',
		males_per_hundred_females = 100,
		child_age = 1,
		teen_age = 3,
		adult_age = 4,
		middle_age = 1,
		elder_age = 15,
		max_age = 21,
		minimum_comfortable_temperature = -5,
		minimum_absolute_temperature = -20,
		fecundity = 1.5,
		spotting = 1.25,
		visibility = 0.75,
		female_body_size = small_size,
		female_efficiency = {
			[JOBTYPE.FARMER] = 1.125,
			[JOBTYPE.ARTISAN] = 0.75,
			[JOBTYPE.CLERK] = 0.5,
			[JOBTYPE.LABOURER] = small_size * 2, -- vermen are energetic and persistant
			[JOBTYPE.WARRIOR] = 0.5,
			[JOBTYPE.HAULING] = small_size * 2, -- vermen are energetic and persistant
			[JOBTYPE.FORAGER] = 1.25,
			[JOBTYPE.HUNTING] = 0.5
		},
		female_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = small_size,
				[CALORIES_USE_CASE] = dwarf_size,	--  750 kcal
				[retrieve_use_case('fruit')] = 0.25,			--  250 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = small_size * 0.5 -- vermen have nice fur
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = small_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = small_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = small_size,
			},

		},
		female_infrastructure_needs = small_size,
		male_body_size = small_size,
		male_efficiency = {
			[JOBTYPE.FARMER] = 1.125,
			[JOBTYPE.ARTISAN] = 0.75,
			[JOBTYPE.CLERK] = 0.5,
			[JOBTYPE.LABOURER] = small_size * 2, -- vermen are energetic and persistant
			[JOBTYPE.WARRIOR] = 0.5,
			[JOBTYPE.HAULING] = small_size * 2, -- vermen are energetic and persistant
			[JOBTYPE.FORAGER] = 1.25,
			[JOBTYPE.HUNTING] = 0.5
		},
		male_needs = {
			[NEED.FOOD] = {
				[WATER_USE_CASE] = small_size,
				[CALORIES_USE_CASE] = dwarf_size,	--  750 kcal
				[retrieve_use_case('fruit')] = 0.25,			--  250 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = small_size * 0.5 -- vermen have nice fur
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = small_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = small_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = small_size,
			},

		},
		male_infrastructure_needs = small_size,
		carrying_capacity_weight = small_size,
	}

	---@type PortraitDescription
	local harpy_portrait = {
		folder = "harpy",
		layers = {"base.PNG", "base_patterns.PNG", "male_beard.PNG", "fluff.PNG", "head.PNG", "fluff_overlay.PNG", "hair.PNG"},
		layers_groups = {
			fluff = {"male_beard.PNG", "fluff.PNG"}
		}
	}

	local harpy_fem_portrait = {
		folder = "harpy",
		layers = {"base.PNG", "base_patterns.PNG", "fluff.PNG", "head.PNG", "fluff_overlay.PNG", "hair.PNG"},
		layers_groups = {}
	}

	Race:new {
		name = 'harpy',
		r = 0.3,
		g = 0.2,
		b = 0.7,
		icon = 'harpy.png',
		description = 'harpies',

		male_portrait = {
			fallback = harpy_portrait
		},
		female_portrait = {
			fallback = harpy_fem_portrait
		},

		males_per_hundred_females = 75,
		child_age = 2,
		teen_age = 9,
		adult_age = 15,
		middle_age = 37,
		elder_age = 45,
		max_age = 60,
		minimum_comfortable_temperature = -10,
		minimum_absolute_temperature = -25,
		minimum_comfortable_elevation = 400,
		fecundity = 0.9,
		spotting = 2.0,
		visibility = 1.25,
		female_body_size = medium_size,
		female_efficiency = {
			[JOBTYPE.FARMER] = 0.75,
			[JOBTYPE.ARTISAN] = 1,
			[JOBTYPE.CLERK] = 1.25,
			[JOBTYPE.LABOURER] = medium_size * 0.5, -- harpies light for their size
			[JOBTYPE.WARRIOR] = 1.25, -- harpies have sharp claws
			[JOBTYPE.HAULING] = medium_size * 0.75, -- harpies light for their size
			[JOBTYPE.FORAGER] = 1.25,
			[JOBTYPE.HUNTING] = 1.25
		},
		female_needs = {
			[NEED.FOOD] = {					-- ~1500 kcal
				[WATER_USE_CASE] =  medium_size * 0.5,
				[CALORIES_USE_CASE] = medium_size,	--  1000 kcal
				[retrieve_use_case('fruit')] = 0.15,			--   150 kcal
				[retrieve_use_case('meat')] = 0.175,			--   350 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = medium_size * 0.5 -- harpies have pretty feathers
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = medium_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = medium_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = medium_size,
			},

		},
		female_infrastructure_needs = large_size,
		male_body_size = dwarf_size,
		male_efficiency = {
			[JOBTYPE.FARMER] = 0.75,
			[JOBTYPE.ARTISAN] = 1,
			[JOBTYPE.CLERK] = 1.25,
			[JOBTYPE.LABOURER] = dwarf_size * 0.5, -- harpies light for their size
			[JOBTYPE.WARRIOR] = 1.125, -- harpies have sharp claws
			[JOBTYPE.HAULING] = dwarf_size * 0.75, -- harpies light for their size
			[JOBTYPE.FORAGER] = 1.125,
			[JOBTYPE.HUNTING] = 1.125
		},
		male_needs = {
			[NEED.FOOD] = {					-- ~1250 kcal
				[WATER_USE_CASE] = dwarf_size * 0.5,
				[CALORIES_USE_CASE] = dwarf_size,	--   750 kcal
				[retrieve_use_case('fruit')] = 0.15,			--   150 kcal
				[retrieve_use_case('meat')] = 0.175,			--   350 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = dwarf_size * 0.5 -- harpies have nice feathers
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = dwarf_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = dwarf_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = dwarf_size,
			},

		},
		male_infrastructure_needs = medium_size,
		carrying_capacity_weight = dwarf_size,
	}

	---@type PortraitDescription
	local kappa_portrait = {
		folder = "kappa",
		layers = {"base.PNG", "eye.PNG", "beak.PNG", "pattern.PNG", "hair.PNG"},
		layers_groups = {}
	}

	Race:new {
		name = 'kappa',
		r = 0.8,
		g = 0.9,
		b = 0.1,
		icon = 'toad-teeth.png',
		male_portrait = {
			fallback = kappa_portrait
		},
		female_portrait = {
			fallback = kappa_portrait
		},
		description = 'kappa',
		males_per_hundred_females = 125,
		child_age = 5,
		teen_age = 15,
		adult_age = 20,
		middle_age = 50,
		elder_age = 80,
		max_age = 110,
		minimum_comfortable_temperature = 10,
		minimum_absolute_temperature = -5,
		fecundity = 1,
		spotting = 1,
		visibility = 0.5,
		female_body_size = small_size,
		female_efficiency = {
			[JOBTYPE.FARMER] = 0.75,
			[JOBTYPE.ARTISAN] = 0.75,
			[JOBTYPE.CLERK] = 0.5,
			[JOBTYPE.LABOURER] = small_size * 2,
			[JOBTYPE.WARRIOR] = 1.25, -- kappa are ambush predators
			[JOBTYPE.HAULING] = small_size * 2, -- kappa are ambush predators
			[JOBTYPE.FORAGER] = 1.25,
			[JOBTYPE.HUNTING] = 1.375 -- kappa are ambush predators
		},
		female_needs = {
			[NEED.FOOD] = {					-- ~1250 kcal
				[WATER_USE_CASE] = medium_size,
				[CALORIES_USE_CASE] = dwarf_size,	--   750 kcal
				[retrieve_use_case('meat')] = 0.25,			--   500 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = small_size
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = small_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = small_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = small_size,
			},

		},
		female_infrastructure_needs = small_size,
		male_body_size = dwarf_size,
		male_efficiency = {
			[JOBTYPE.FARMER] = 0.75,
			[JOBTYPE.ARTISAN] = 0.75,
			[JOBTYPE.CLERK] = 0.5,
			[JOBTYPE.LABOURER] = dwarf_size,
			[JOBTYPE.WARRIOR] = 1.5, -- kappa are ambush predators
			[JOBTYPE.HAULING] = dwarf_size * 2, -- kappa are ambush predators
			[JOBTYPE.FORAGER] = 1.375,
			[JOBTYPE.HUNTING] = 1.5 -- kappa are ambush predators
		},
		male_needs = {
			[NEED.FOOD] = {					-- ~1500 kcal
				[WATER_USE_CASE] = medium_size,
				[CALORIES_USE_CASE] = dwarf_size,	--   750 kcal
				[retrieve_use_case('meat')] = 0.375,			--   750 kcal
			},
			[NEED.CLOTHING] = {
				[retrieve_use_case('clothes')] = dwarf_size
			},
			[NEED.FURNITURE] = {
				[retrieve_use_case('furniture')] = dwarf_size
			},
			[NEED.HEALTHCARE] = {
				[retrieve_use_case('healthcare')] = dwarf_size,
			},
			[NEED.LUXURY] = {
				[retrieve_use_case('liquors')] = dwarf_size,
			},

		},
		male_infrastructure_needs = dwarf_size,
		carrying_capacity_weight = dwarf_size,
		requires_large_river = true
	}

	-- for testing purpose
	-- Race:new {
	-- 	name = 'WeakGoblin',
	-- 	r = 0.0,
	-- 	g = 0.9,
	-- 	b = 0.0,
	-- 	icon = 'goblin.png',
	-- 	description = 'weak goblin',
	-- 	males_per_hundred_females = 102,
	-- 	child_age = 1,
	-- 	teen_age = 2,
	-- 	adult_age = 3,
	-- 	middle_age = 4,
	-- 	elder_age = 5,
	-- 	max_age = 6,
	-- 	minimum_comfortable_temperature = 5,
	-- 	minimum_absolute_temperature = -10,
	-- 	fecundity = 4,
	-- 	spotting = 1.5,
	-- 	visibility = 0.5,
	-- 	female_body_size = 0.5,
	-- 	female_efficiency = {
	-- 		[JOBTYPE.FARMER] = 0.25,
	-- 		[JOBTYPE.ARTISAN] = 0.25,
	-- 		[JOBTYPE.CLERK] = 0.25,
	-- 		[JOBTYPE.LABOURER] = 0.25,
	-- 		[JOBTYPE.WARRIOR] = 0.25,
	-- 		[JOBTYPE.HAULING] = 0.5,
	-- 		[JOBTYPE.FORAGER] = 0.25
	-- 	},
	-- 	female_needs = {
	-- 		[NEED.WATER] = 0.25,
	-- 		[NEED.FOOD] = 0.25,
	-- 		-- [NEED.FRUIT] = 0.25,
	-- 		-- [NEED.GRAIN] = 0.25,
	-- 		-- [NEED.MEAT] = 0.25,
	-- 		[NEED.CLOTHING] = 0.25,
	-- 		[NEED.FURNITURE] = 0.25,
	-- 		[NEED.TOOLS] = 0.125 * 0.5,
	-- 		[NEED.HEALTHCARE] = 0.125,
	-- 		[NEED.STORAGE] = 0.125,
	-- 		[NEED.LUXURY] = 1
	-- 	},
	-- 	female_infrastructure_needs = 0.25,
	-- 	male_body_size = 0.6,
	-- 	male_efficiency = {
	-- 		[JOBTYPE.FARMER] = 0.25,
	-- 		[JOBTYPE.ARTISAN] = 0.25,
	-- 		[JOBTYPE.CLERK] = 0.25,
	-- 		[JOBTYPE.LABOURER] = 0.25,
	-- 		[JOBTYPE.WARRIOR] = 0.25,
	-- 		[JOBTYPE.HAULING] = 0.5,
	-- 		[JOBTYPE.FORAGER] = 0.25
	-- 	},
	-- 	male_needs = {
	-- 		[NEED.WATER] = 0.25,
	-- 		[NEED.FOOD] = 0.25,
	-- 		-- [NEED.FRUIT] = 0.25,
	-- 		-- [NEED.GRAIN] = 0.25,
	-- 		-- [NEED.MEAT] = 0.25,
	-- 		[NEED.CLOTHING] = 0.25,
	-- 		[NEED.FURNITURE] = 0.25,
	-- 		[NEED.HEALTHCARE] = 0.125,
	-- 		[NEED.STORAGE] = 0.125,
	-- 		[NEED.LUXURY] = 1
	-- 	},
	-- 	male_infrastructure_needs = 0.25,
	-- 	carrying_capacity_weight = 0.25,
	-- }
end

return ll
