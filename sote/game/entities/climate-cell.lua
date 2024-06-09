---@class (exact) ClimateCell
---@field __index ClimateCell
---@field cell_id number
---@field elevation number
---@field water_fraction number
---@field january_temperature number
---@field january_rainfall number
---@field january_humidity number
---@field july_temperature number
---@field july_rainfall number
---@field july_humidity number
---@field hadley_influence number
---@field med_influence number
---@field itcz_january number
---@field itcz_july number
---@field left_to_right_continentality number
---@field right_to_left_continentality number
---@field true_continentality number
---@field distance_to_sea number
---@field left_to_right_rain_shadow number
---@field right_to_left_rain_shadow number
---@field true_rain_shadow number
---@field saldo_north number abstract number showing the "weight" of landmasses on either of the hemispheres...
---@field saldo_south number abstract number showing the "weight" of landmasses on either of the hemispheres...
---@field cache table<number, number> A debug cache containing a bunch of values to use... (10 by default)
---@field land_tiles number
---@field water_tiles number

local cell = {}

---@class ClimateCell
local ClimateCell = {}
ClimateCell.__index = ClimateCell
---Returns a new cell
---@param cell_id number
---@return ClimateCell
function ClimateCell:new(cell_id)
	---@type ClimateCell
	local new = {}
	new.cell_id = cell_id
	new.elevation = 0
	new.water_fraction = 1

	new.january_temperature = 0
	new.january_rainfall = 0
	new.january_humidity = 0
	new.july_temperature = 0
	new.july_rainfall = 0
	new.july_humidity = 0

	new.hadley_influence = 0
	new.med_influence = 0
	new.left_to_right_continentality = 0
	new.right_to_left_continentality = 0
	new.left_to_right_rain_shadow = 0
	new.right_to_left_rain_shadow = 0
	new.true_continentality = 0
	new.true_rain_shadow = 0
	new.distance_to_sea = 0
	new.water_tiles = 0
	new.land_tiles = 0
	new.saldo_north = 0
	new.saldo_south = 0
	new.itcz_january = 0
	new.itcz_july = 0

	new.cache = {
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
	}

	setmetatable(new, ClimateCell)
	return new
end

cell.ClimateCell = ClimateCell
return cell
