local wbt = {}

---@enum waterbody_type
wbt.types = {
	ocean           = 0,
	sea             = 1,
	saltwater_lake  = 2,
	freshwater_lake = 3,
	river           = 4,
	wetland         = 5,
	invalid         = 6
}

return wbt