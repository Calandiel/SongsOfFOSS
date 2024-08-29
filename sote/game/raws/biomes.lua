local Biome = {}
Biome.__index = Biome
---@param o biome_id_data_blob_definition
---@return biome_id
function Biome:new(o)
	local new_biome = DATA.create_biome()
	DATA.setup_biome(new_biome, o)

	if RAWS_MANAGER.biomes_by_name[o.name] ~= nil then
		local msg = "Failed to load a biome (" .. tostring(o.name) .. ")"
		print(msg)
		error(msg)
	end

	RAWS_MANAGER.biomes_by_name[o.name] = new_biome
	return new_biome
end

return Biome
