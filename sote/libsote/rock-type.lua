local rock = {}

---@enum rock_type
rock.TYPES = {
	no_type         = 0,
	acid_plutonics  = 3,
	sandstone       = 4,
	siltstone       = 5,
	mudstone        = 7,
	limestone       = 10, -- 0x0000000A
	limestone_reef  = 12, -- 0x0000000C
	basic_volcanics = 22, -- 0x00000016
	basic_plutonics = 23, -- 0x00000017
	mixed_volcanics = 24, -- 0x00000018
	mixed_plutonics = 25, -- 0x00000019
	acid_volcanics  = 26, -- 0x0000001A
	slate           = 27, -- 0x0000001B
	marble          = 28, -- 0x0000001C
}

return rock