local ll = {}

---Given x/y/z cartesian coordinates in a [-1,1]^3 cube, return latitude and longitude
---@param x number
---@param y number
---@param z number
---@return number
---@return number
function ll.lat_lon_from_cart(x, y, z)
	local r = math.sqrt(x * x + y * y + z * z)
	local inclination = math.acos(y / r)
	local azimuth = math.pi / 2
	if x ~= 0 then
		azimuth = math.atan2(z, x)
	else
		-- :c
		-- TODO: Check is x == 0 corresponds to azimuth = -pi/2,
		-- if it doesn't, comment this case in more detail
	end
	return math.pi / 2 - inclination, -azimuth
end
---comment
---@param lat number Latitude, between [-pi / 2, pi / 2]
---@param lon number Longitude, between [-pi, pi]
---@return number x
---@return number y
---@return number z
function ll.lat_lon_to_cart(lat, lon)
	local azimuth = -lon
	local inclination = -(lat - math.pi / 2)
	return
		math.cos(azimuth) * math.sin(inclination),
		math.cos(inclination),
		math.sin(azimuth) * math.sin(inclination)
end

local half_pi = math.pi / 2

---@param lat number Latitude, between [-pi / 2, pi / 2]
---@return number
function ll.lat_to_colat(lat)
	return half_pi - lat
end

---@param colat number Colatitude, between [0, pi]
---@return number
function ll.colat_to_lat(colat)
	return half_pi - colat
end

return ll