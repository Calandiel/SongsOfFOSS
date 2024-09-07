local bld = {}
bld.Building = {}

---@param province province_id province to build the building in
---@param building_type building_type_id
---@return building_id
function bld.Building.new(province, building_type)
	local new_id = DATA.create_building()
	DATA.building_set_type(new_id, building_type)

	local location = DATA.fatten_building_location(DATA.create_building_location())

	location.building = new_id
	location.location = province

	return new_id
end

---Removes a building from the province and other relevant data structures.
---@param building building_id
function bld.Building.remove_from_province(building)
	DATA.delete_building(building)
end

function bld.Building.amount_of_workers(building)
	local amount = 0
	DATA.for_each_employment_from_building(building, function (item)
		amount = amount + 1
	end)
	return amount
end

function bld.Building.province(building)
	local location = DATA.get_building_location_from_building(building)
	assert(location ~= INVALID_ID, "BUILDING DOESN'T BELONG TO THIS WORLD?")
	return DATA.building_location_get_location(location)
end

return bld
