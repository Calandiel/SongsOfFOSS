local plate = {}

plate.Plate = {}

---Creates a new plate.
---@return plate_id
function plate.Plate:new()
	local id = DATA.create_plate()
	print(id)
	local fat = DATA.fatten_plate(id)

	fat.r = love.math.random()
	fat.g = love.math.random()
	fat.b = love.math.random()

	fat.done_expanding = false
	fat.speed = 0
	fat.direction = 1
	fat.current_tiles = {}
	fat.next_tiles = {}
	print("plate created")
	return id
end

---Adds a tile to the plate, removing it from the previous plate...
---@param plate_id plate_id
---@param tile_id tile_id ID of the tile to add!
function plate.Plate.add_tile(plate_id, tile_id)
	DATA.force_create_plate_tiles(plate_id, tile_id)
end

return plate
