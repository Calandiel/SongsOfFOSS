local tabb = require "engine.table"

local Technology = {}

---Creates a new technology
---commenting
---@param o technology_id_data_blob_definition
---@return technology_id
function Technology:new(o)
	if RAWS_MANAGER.do_logging then
		print("Technology: " .. tostring(o.name))
	end

	local new_id = DATA.create_technology()
	DATA.setup_technology(new_id, o)

	if ASSETS.icons[o.icon] == nil then
		print("Missing icon: " .. o.icon)
		error("Technology " .. o.name .. " has no icon. " .. "Missing icon: " .. o.icon)
	end

	if RAWS_MANAGER.technologies_by_name[o.name] ~= nil then
		local msg = "Failed to load a technology (" .. tostring(o.name) .. ")"
		print(msg)
		error(msg)
	end
	RAWS_MANAGER.technologies_by_name[o.name] = new_id

	return new_id
end

---Generates tooltip for a given technology
---@param technology technology_id
---@return string
function Technology.get_tooltip(technology)
	local technology_data = DATA.fatten_technology(technology)

	local s = technology_data.description .. "\n\n"

	s = s .. "Difficulty: " .. tostring(technology_data.research_cost) .. "\n"
	if technology_data.associated_job then
		s = s .. "\nAssociated job: " .. DATA.job_get_name(technology_data.associated_job)
	end

	do
		local requires = false
		local string = ""
		string = string .. "\n Required biome: "
		for i = 0, MAX_REQUIREMENTS_TECHNOLOGY - 1 do
			local thing = DATA.technology_get_required_biome(technology, i)
			if thing == INVALID_ID then
				break
			end
			local name = DATA.biome_get_name(thing)
			string = string .. name .. ", "
			requires = true
		end
		string = string .. "\n"
		if requires then
			s = s .. string
		end
	end

	do
		local requires = false
		local string = ""
		string = string .. "\n Required race: "
		for i = 0, MAX_REQUIREMENTS_TECHNOLOGY - 1 do
			local thing = DATA.technology_get_required_race(technology, i)
			if thing == INVALID_ID then
				break
			end
			local name = DATA.race_get_name(thing)
			string = string .. name .. ", "
			requires = true
		end
		string = string .. "\n"
		if requires then
			s = s .. string
		end
	end

	do
		local requires = false
		local string = ""
		string = string .. "\n Required resource: "
		for i = 0, MAX_REQUIREMENTS_TECHNOLOGY - 1 do
			local thing = DATA.technology_get_required_resource(technology, i)
			if thing == INVALID_ID then
				break
			end
			local name = DATA.resource_get_name(thing)
			string = string .. name .. ", "
			requires = true
		end
		string = string .. "\n"
		if requires then
			s = s .. string
		end
	end

	do
		local requires = false
		local string = ""
		string = string .. "\n Unlocked buildings: "
		for _, item in ipairs(DATA.get_technology_building_from_technology(technology)) do
			local name = DATA.building_type_get_description(item)
			string = string .. name .. ", "
			requires = true
		end
		string = string .. "\n"
		if requires then
			s = s .. string
		end
	end

	do
		local requires = false
		local string = ""
		string = string .. "\n Unlocked units: "
		for _, item in ipairs(DATA.get_technology_unit_from_technology(technology)) do
			local name = DATA.unit_type_get_name(item)
			string = string .. name .. ", "
			requires = true
		end
		string = string .. "\n"
		if requires then
			s = s .. string
		end
	end

	do
		local requires = false
		local string = ""
		string = string .. "\n Unlocked technology paths: "
		local thing = DATA.get_technology_unlock_from_origin(technology)
		for _, i in ipairs(thing) do
			local name = DATA.technology_get_name(i)
			string = string .. name .. ", "
			requires = true
		end
		string = string .. "\n"
		if requires then
			s = s .. string
		end
	end

	do
		local requires = false
		local string = ""
		string = string .. "\n Unlocked by: "
		local thing = DATA.get_technology_unlock_from_unlocked(technology)
		for _, i in ipairs(thing) do
			local name = DATA.technology_get_name(i)
			string = string .. name .. ", "
			requires = true
		end
		string = string .. "\n"
		if requires then
			s = s .. string
		end
	end

	do
		local requires = false
		local string = ""
		string = string .. "\n Throughput: "

		local function build_string(production_method_id)
			local thing = DATA.technology_get_throughput_boosts(technology, production_method_id)
			local name = DATA.production_method_get_name(production_method_id)
			if thing ~= 0 then
				string = string .. name .. " (+" .. tostring(math.floor(100 * thing)) .. "%), "
				requires = true
			end
		end

		DATA.for_each_production_method(build_string)

		string = string .. "\n"
		if requires then
			s = s .. string
		end
	end

	do
		local requires = false
		local string = ""
		string = string .. "\n Input: "

		local function build_string(production_method_id)
			local thing = DATA.technology_get_input_efficiency_boosts(technology, production_method_id)
			local name = DATA.production_method_get_name(production_method_id)
			if thing ~= 0 then
				string = string .. name .. " (+" .. tostring(math.floor(100 * thing)) .. "%), "
				requires = true
			end
		end

		DATA.for_each_production_method(build_string)

		string = string .. "\n"
		if requires then
			s = s .. string
		end
	end

	do
		local requires = false
		local string = ""
		string = string .. "\n Output: "

		local function build_string(production_method_id)
			local thing = DATA.technology_get_output_efficiency_boosts(technology, production_method_id)
			local name = DATA.production_method_get_name(production_method_id)
			if thing ~= 0 then
				string = string .. name .. " (+" .. tostring(math.floor(100 * thing)) .. "%), "
				requires = true
			end
		end

		DATA.for_each_production_method(build_string)

		string = string .. "\n"
		if requires then
			s = s .. string
		end
	end

	return s
end

return Technology
