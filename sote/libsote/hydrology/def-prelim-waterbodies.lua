local dpw = {}

function dpw.run(world)
	world:for_each_waterbody(function(waterbody)
		local tiles_count = #waterbody.tiles
		if tiles_count > 5000 then
			waterbody.type = waterbody.TYPES.ocean
		else
			waterbody.type = waterbody.TYPES.saltwater_lake
		end

		waterbody:build_perimeter(world)
		waterbody:set_lowest_shore_tile(world)
		waterbody.water_level = 0
	end)
end

return dpw