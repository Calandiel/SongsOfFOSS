
local cube = {}


-- Cube face constants
cube.FRONT = 0
cube.LEFT = 1
cube.BACK = 2
cube.RIGHT = 3
cube.TOP = 4
cube.BOTTOM = 5

---Takes in cartesian coordinates, returns cube coordinates, normalized in [0, 1]
---@param x number
---@param y number
---@param z number
---@return number fx
---@return number fy
---@return number f
function cube.pos_to_cube(x, y, z)

	local abs_x = math.abs(x)
	local abs_y = math.abs(y)
	local abs_z = math.abs(z)

	local is_x_positive = false
	local is_y_positive = false
	local is_z_positive = false
	if x > 0 then is_x_positive = true end
	if y > 0 then is_y_positive = true end
	if z > 0 then is_z_positive = true end

	local face = cube.BACK
	local max_axis = 1
	local uc = 1
	local vc = 1

	if is_x_positive and abs_x >= abs_y and abs_x >= abs_z then
		-- POSITIVE X
		-- u (0 to 1) goes from +z to -z
		-- v (0 to 1) goes from -y to +y
		face = cube.RIGHT
		max_axis = abs_x
		uc = -z
		vc = y
	elseif not is_x_positive and abs_x >= abs_y and abs_x >= abs_z then
		-- NEGATIVE X
		-- u (0 to 1) goes from -z to +z
		-- v (0 to 1) goes from -y to +y
		face = cube.LEFT
		max_axis = abs_x
		uc = z
		vc = y
	elseif is_y_positive and abs_y >= abs_x and abs_y >= abs_z then
		-- POSITIVE Y
		-- u (0 to 1) goes from -x to +x
		-- v (0 to 1) goes from +z to -z
		face = cube.TOP
		max_axis = abs_y
		uc = z
		vc = x
	elseif not is_y_positive and abs_y >= abs_x and abs_y >= abs_z then
		-- NEGATIVE Y
		-- u (0 to 1) goes from -x to +x
		-- v (0 to 1) goes from -z to +z
		face = cube.BOTTOM
		max_axis = abs_y
		uc = -z
		vc = x
	elseif is_z_positive and abs_z >= abs_x and abs_z >= abs_y then
		-- POSITIVE Z
		-- u (0 to 1) goes from -x to +x
		-- v (0 to 1) goes from -y to +y
		face = cube.FRONT
		max_axis = abs_z
		uc = x
		vc = y
	elseif not is_z_positive and abs_z >= abs_x and abs_z >= abs_y then
		-- NEGATIVE Z
		-- u (0 to 1) goes from +x to -x
		-- v (0 to 1) goes from -y to +y
		face = cube.BACK
		max_axis = abs_z
		uc = -x
		vc = y
	else
		local msg = "ERRO! POSITION TO CUBE FAILED!"
		print(msg)
		error(msg)
	end

	return
		math.min(1, math.max(0, 0.5 * (uc / max_axis + 1))),
		math.min(1, math.max(0, 0.5 * (vc / max_axis + 1))),
		face
end

---Takes in cube coordinates, normalized in (0, 1), and returns position in cartesian coordinates, on the cube face
---@param fx number
---@param fy number
---@param f number
---@return number x
---@return number y
---@return number z
function cube.cube_to_pos(fx, fy, f)
	-- Rescale coords into -1, 1
	local px = fx * 2 - 1
	local py = fy * 2 - 1
	local x = 0
	local y = 0
	local z = 0
	if f == cube.TOP then
		x = py
		y = 1
		z = px
	elseif f == cube.BOTTOM then
		x = -py
		y = -1
		z = px
	elseif f == cube.FRONT then
		x = px
		y = py
		z = 1
	elseif f == cube.BACK then
		x = -px
		y = py
		z = -1
	elseif f == cube.LEFT then
		x = -1
		y = py
		z = px
	elseif f == cube.RIGHT then
		x = 1
		y = py
		z = -px
	end
	return x, y, z
end


return cube