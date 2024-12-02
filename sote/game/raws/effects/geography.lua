local tabb = require "engine.table"

local geo_effects = {}

---Deforests tile with given power and returns amount of collected resource
---@param province province_id
---@param power number
---@return number
function geo_effects.deforest_random_tile(province, power)
	local _, deforested_tile_membership = tabb.random_select_from_set(DATA.get_tile_province_membership_from_province(province))
	local deforested_tile = DATA.fatten_tile(DATA.tile_province_membership_get_tile(deforested_tile_membership))

	local woods = deforested_tile.broadleaf + deforested_tile.conifer + deforested_tile.shrub
	if woods > 0 then
		local broadleaf_ratio = deforested_tile.broadleaf / woods
		local conifer_ratio = deforested_tile.conifer / woods
		local shrub_ratio = deforested_tile.shrub / woods

		local broad_leaf_change = math.min(deforested_tile.broadleaf, power * broadleaf_ratio)
		local conifer_change = math.min(deforested_tile.conifer, power * conifer_ratio)
		local shrub_change = math.min(deforested_tile.shrub, power * shrub_ratio)

		deforested_tile.broadleaf = deforested_tile.broadleaf - broad_leaf_change
		deforested_tile.conifer = deforested_tile.conifer - conifer_change
		deforested_tile.shrub = deforested_tile.shrub - shrub_change

		local total_change = broad_leaf_change + conifer_change + shrub_change
		deforested_tile.grass = deforested_tile.grass + total_change

		return total_change
	end

	return 0
end

return geo_effects