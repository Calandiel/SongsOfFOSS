local car = {}

---Returns carrying capacity for humans, for a tile
---@param tile Tile
---@return number
function car.get_tile_carrying_capacity(tile)
	local cc = 0
	cc = cc +
		0.0125 * tile.grass +
		0.025 * tile.shrub +
		0.055 * tile.conifer +
		0.1 * tile.broadleaf
	if tile.ice == 0 and tile.has_river then
		cc = cc + 0.05
	end
	if tile.has_marsh then
		cc = cc + 0.025
	end

	local lat, lon = tile:latlon()
	for n in tile:iter_neighbors() do
		if not n.is_land then
			cc = cc + 0.2 * math.abs(lat / math.pi)
		end
	end

	return cc * 3
end

function car.calculate()
	local total = 0
	for _, province in pairs(WORLD.provinces) do
		local count = 0
		local acc = {bedrocks= {}, organics = 0, grass= 0, shrub = 0, broadleaf = 0, conifer = 0}
		if province.center.is_land then
			local cc = 5 -- I know it's unrealistic, but let's have a floor of 5 so that we don't have to make checks for livability of tiny provinces everywhere...
			for _, tile in pairs(province.tiles) do
				cc = cc + car.get_tile_carrying_capacity(tile)
				count = count + 1
				if not acc.bedrocks[tile.bedrock.name] then
					acc.bedrocks[tile.bedrock.name] = 1
				else
					acc.bedrocks[tile.bedrock.name] = acc.bedrocks[tile.bedrock.name] + 1
				end
				acc = {
					bedrocks = acc.bedrocks,
					organics = acc.organics + tile.soil_organics,
					grass = acc.grass + tile.grass,
					shrub = acc.shrub + tile.shrub,
					broadleaf = acc.broadleaf + tile.broadleaf,
					conifer = acc.conifer + tile.conifer
				}
			end
			cc = math.max(5, cc)
			province.foragers_limit = cc
			local bedrocks = {}
			for rock, number in pairs(acc.bedrocks) do
				bedrocks[rock] = number / count
			end
			province.bedrocks = bedrocks
			province.flora_spread = {
				organics = acc.organics / count,
				grass = acc.grass / count,
				shrub = acc.shrub / count,
				broadleaf = acc.broadleaf / count,
				conifer = acc.conifer / count,
			}
			total = total + cc
		else
			province.foragers_limit = 0
			province.flora_spread = acc
		end
	end
	--print("Total base carrying capacity: ", total)
end

return car
