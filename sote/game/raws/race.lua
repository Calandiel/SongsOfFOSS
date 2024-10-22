---@class (exact) PortraitSet
---@field fallback PortraitDescription
---@field child PortraitDescription?
---@field teen PortraitDescription?
---@field adult PortraitDescription?
---@field middle PortraitDescription?
---@field elder PortraitDescription?

---@class (exact) PortraitDescription
---@field folder string
---@field layers string[]
---@field layers_groups string[][]

local Race = {}
Race.__index = Race

---@class race_id_data_blob_definition_extended : race_id_data_blob_definition
---@field female_needs table<NEED, table<use_case_id, number>>
---@field male_needs table<NEED, table<use_case_id, number>>

---@param o race_id_data_blob_definition_extended
function Race:new(o)
	local r = DATA.create_race()


	-- assert that needs are valid
	---@type struct_need_definition[]
	local male_needs = {}
	---@type struct_need_definition[]
	local female_needs = {}

	for need, uses_table in pairs(o.male_needs) do
		for use_case, value in pairs(uses_table) do
			table.insert(male_needs, {
				need = need,
				use_case = use_case,
				required = value
			})
		end
	end

	for need, uses_table in pairs(o.female_needs) do
		for use_case, value in pairs(uses_table) do
			table.insert(female_needs, {
				need = need,
				use_case = use_case,
				required = value
			})
		end
	end

	--- check that they are consistent:

	for i = 1, math.max(#male_needs, #female_needs) do
		assert(male_needs[i].need == female_needs[i].need)
		assert(male_needs[i].use_case == female_needs[i].use_case)
		assert(male_needs[i].required > 0)
		assert(female_needs[i].required > 0)

		local need = male_needs[i].need
		local use_case = male_needs[i].use_case

		print(need, use_case)

		DATA.race_set_male_needs_need(r, i - 1, need)
		DATA.race_set_female_needs_need(r, i - 1, need)
		DATA.race_set_male_needs_use_case(r, i - 1, use_case)
		DATA.race_set_female_needs_use_case(r, i - 1, use_case)
		DATA.race_set_male_needs_required(r, i - 1, male_needs[i].required)
		DATA.race_set_female_needs_required(r, i - 1, female_needs[i].required)
	end

	DATA.setup_race(r, o)

	if RAWS_MANAGER.races_by_name[o.name] ~= nil then
		local msg = "Failed to load a race (" .. tostring(o.name) .. ")"
		print(msg)
		error(msg)
	end

	RAWS_MANAGER.races_by_name[o.name] = r
	return r
end

return Race
