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

---@param o race_id_data_blob_definition
function Race:new(o)
	local r = DATA.create_race()


	-- assert that needs are valid
	local amount = 0
	for i = 1, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
		if o.male_needs[i] then
			assert(o.male_needs[i].need == o.female_needs[i].need)
			assert(o.male_needs[i].use_case == o.female_needs[i].use_case)

			amount = amount + 1
		end
	end

	DATA.setup_race(o)

	if RAWS_MANAGER.races_by_name[o.name] ~= nil then
		local msg = "Failed to load a race (" .. tostring(o.name) .. ")"
		print(msg)
		error(msg)
	end

	RAWS_MANAGER.races_by_name[o.name] = r
	return r
end

return Race
