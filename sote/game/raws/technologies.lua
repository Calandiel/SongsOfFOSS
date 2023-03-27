local tabb = require "engine.table"

---@class Technology
---@field name string
---@field icon string
---@field description string
---@field r number
---@field g number
---@field b number
---@field required_biome table<number, Biome>
---@field required_race table<number, Race>
---@field required_resource table<number, Resource>
---@field unlocked_by table<number, Technology>
---@field potentially_unlocks table<number, Technology> Do not touch this one. It's expanded automatically.
---@field unlocked_buildings table<number, BuildingType>
---@field research_cost number Amount of research points (education_endowment) per pop needed for the technology
---@field unlocked_unit_types table<number, UnitType>
---@field associated_job Job|nil The job that is needed to perform this research. Without it, the research odds will be significantly lower. We'll be using this to make technology implicitly tied to player decisions
---@field get_tooltip fun():string
---@field throughput_boosts table<ProductionMethod, number>
---@field input_efficiency_boosts table<ProductionMethod, number>
---@field output_efficiency_boosts table<ProductionMethod, number>
---@field new fun(self:Technology, o:Technology?):Technology

---@type Technology
local Technology = {}
Technology.__index = Technology
---Creates a new technology
---@param o Technology
---@return Technology
function Technology:new(o)
	print("Technology: " .. o.name)
	---@type Technology
	local r = {}

	r.name = "<technology>"
	r.icon = 'uncertainty.png'
	r.description = "<technology description>"
	r.r = 0
	r.g = 0
	r.b = 0
	r.required_biome = {}
	r.required_race = {}
	r.required_resource = {}
	r.unlocked_by = {}
	r.potentially_unlocks = {}
	r.unlocked_buildings = {}
	r.unlocked_unit_types = {}
	r.research_cost = 0.5
	r.throughput_boosts = {}
	r.input_efficiency_boosts = {}
	r.output_efficiency_boosts = {}


	for k, v in pairs(o) do
		r[k] = v
	end
	setmetatable(r, Technology)
	if WORLD.technologies_by_name[r.name] ~= nil then
		local msg = "Failed to load a technology (" .. tostring(r.name) .. ")"
		print(msg)
		error(msg)
	end
	WORLD.technologies_by_name[r.name] = r
	return r
end

function Technology:get_tooltip()
	local s = self.description .. "\n\n"

	s = s .. "Difficulty: " .. tostring(self.research_cost) .. "\n"
	if self.associated_job then
		s = s .. "\nAssociated job: " .. self.associated_job.name
	end

	if tabb.size(self.required_biome) > 0 then
		s = s .. "\nRequired biome: "
		for _, b in pairs(self.required_biome) do
			s = s .. b.name .. ", "
		end
		s = s .. "\n"
	end
	if tabb.size(self.required_race) > 0 then
		s = s .. "\nRequired race: "
		for _, b in pairs(self.required_race) do
			s = s .. b.name .. ", "
		end
		s = s .. "\n"
	end
	if tabb.size(self.required_resource) > 0 then
		s = s .. "\nRequired resource: "
		for _, b in pairs(self.required_resource) do
			s = s .. b.name .. ", "
		end
		s = s .. "\n"
	end

	if tabb.size(self.unlocked_buildings) > 0 then
		s = s .. "\nUnlocked buildings: "
		for _, b in pairs(self.unlocked_buildings) do
			s = s .. b.name .. ", "
		end
		s = s .. "\n"
	end
	if tabb.size(self.unlocked_unit_types) > 0 then
		s = s .. "\nUnlocked unit types: "
		for _, b in pairs(self.unlocked_unit_types) do
			s = s .. b.name .. ", "
		end
		s = s .. "\n"
	end
	if tabb.size(self.potentially_unlocks) > 0 then
		s = s .. "\nPotentially unlocks: "
		for _, b in pairs(self.potentially_unlocks) do
			s = s .. b.name .. ", "
		end
		s = s .. "\n"
	end
	if tabb.size(self.throughput_boosts) > 0 then
		s = s .. "\nThroughput: "
		for prod, am in pairs(self.throughput_boosts) do
			s = s .. prod.name .. " (+" .. tostring(math.floor(100 * am)) .. "%), "
		end
		s = s .. "\n"
	end
	if tabb.size(self.input_efficiency_boosts) > 0 then
		s = s .. "\nInput efficiency: "
		for prod, am in pairs(self.input_efficiency_boosts) do
			s = s .. prod.name .. " (+" .. tostring(math.floor(100 * am)) .. "%), "
		end
		s = s .. "\n"
	end
	if tabb.size(self.output_efficiency_boosts) > 0 then
		s = s .. "\nOutput efficiency: "
		for prod, am in pairs(self.output_efficiency_boosts) do
			s = s .. prod.name .. " (+" .. tostring(math.floor(100 * am)) .. "%), "
		end
		s = s .. "\n"
	end





	return s
end

return Technology
