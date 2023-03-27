local ut = {}

---@param id string
---@return Job
function ut.job(id)
	local r = WORLD.jobs_by_name[id]
	if r == nil then
		print("Job " .. id .. " doesn't exist!")
		error("Job " .. id .. " doesn't exist!")
		love.event.quit()
	end
	---@diagnostic disable-next-line: return-type-mismatch
	return r
end

---@param id string
---@return TradeGood
function ut.trade_good(id)
	local r = WORLD.trade_goods_by_name[id]
	if r == nil then
		print("Trade good " .. id .. " doesn't exist!")
		error("Trade good " .. id .. " doesn't exist!")
		love.event.quit()
	end
	---@diagnostic disable-next-line: return-type-mismatch
	return r
end

---@param id string
---@return Technology
function ut.technology(id)
	local r = WORLD.technologies_by_name[id]
	if r == nil then
		print("Technology " .. id .. " doesn't exist!")
		error("Technology " .. id .. " doesn't exist!")
		love.event.quit()
	end
	---@diagnostic disable-next-line: return-type-mismatch
	return r
end

---@param id string
---@return Race
function ut.race(id)
	local r = WORLD.races_by_name[id]
	if r == nil then
		print("Race " .. id .. " doesn't exist!")
		error("Race " .. id .. " doesn't exist!")
		love.event.quit()

	end
	---@diagnostic disable-next-line: return-type-mismatch
	return r
end

---@param id string
---@return ProductionMethod
function ut.production_method(id)
	local r = WORLD.production_methods_by_name[id]
	if r == nil then
		print("Production method " .. id .. " doesn't exist!")
		error("Production method " .. id .. " doesn't exist!")
		love.event.quit()

	end
	---@diagnostic disable-next-line: return-type-mismatch
	return r
end

---@param id string
---@return Biome
function ut.biome(id)
	local r = WORLD.biomes_by_name[id]
	if r == nil then
		print("Biome " .. id .. " doesn't exist!")
		error("Biome " .. id .. " doesn't exist!")
		love.event.quit()

	end
	---@diagnostic disable-next-line: return-type-mismatch
	return r
end

---@param id string
---@return Bedrock
function ut.bedrock(id)
	local r = WORLD.bedrocks_by_name[id]
	if r == nil then
		print("Bedrock " .. id .. " doesn't exist!")
		error("Bedrock " .. id .. " doesn't exist!")
		love.event.quit()

	end
	---@diagnostic disable-next-line: return-type-mismatch
	return r
end

---@param id string
---@return BiogeographicRealm
function ut.biogeographic_realm(id)
	local r = WORLD.biogeographic_realms_by_name[id]
	if r == nil then
		print("Biogeographic realm " .. id .. " doesn't exist!")
		error("Biogeographic realm " .. id .. " doesn't exist!")
		love.event.quit()

	end
	---@diagnostic disable-next-line: return-type-mismatch
	return r
end

---@param id string
---@return Resource
function ut.resource(id)
	local r = WORLD.resources_by_name[id]
	if r == nil then
		print("Resource " .. id .. " doesn't exist!")
		error("Resource " .. id .. " doesn't exist!")
		love.event.quit()

	end
	---@diagnostic disable-next-line: return-type-mismatch
	return r
end

---@param id string
---@return UnitType
function ut.unit_type(id)
	local r = WORLD.unit_types_by_name[id]
	if r == nil then
		print("Unit Type " .. id .. " doesn't exist!")
		error("Unit Type " .. id .. " doesn't exist!")
		love.event.quit()

	end
	---@diagnostic disable-next-line: return-type-mismatch
	return r
end

---@param id string
---@return Event
function ut.event(id)
	local r = WORLD.events_by_name[id]
	if r == nil then
		print("Event " .. id .. " doesn't exist!")
		error("Event " .. id .. " doesn't exist!")
		love.event.quit()

	end
	---@diagnostic disable-next-line: return-type-mismatch
	return r
end

return ut
