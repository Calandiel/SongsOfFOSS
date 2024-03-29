local pla = {}

function pla.get_shader()
	local vs = [[
		attribute float Face;
		varying float FaceValue;

		uniform mat4 model;
		uniform mat4 view;
		uniform mat4 projection;

		vec4 position(mat4 _, vec4 vertex_position)
		{
			FaceValue = Face;
			return projection * view * model * vertex_position;
		}
	]]
	local fs = [[
		uniform sampler2D tile_colors;
		varying float FaceValue;

		vec2 get_face_offset(float face_value) {
			// 0 1 2
			// 3 4 5
			// - - -
			vec2 base_step_x = vec2(1, 0) / 3;
			vec2 base_step_y = vec2(0, 1) / 3;
			vec2 face_offset = vec2(0, 0);
			if (abs(face_value - 1.0) < 0.01) {
				face_offset += base_step_x;
			} else if (abs(face_value - 2.0) < 0.01) {
				face_offset += base_step_x * 2;
			} else if (abs(face_value - 3.0) < 0.01) {
				face_offset += base_step_y;
			} else if (abs(face_value - 4.0) < 0.01) {
				face_offset += base_step_y;
				face_offset += base_step_x;
			} else if (abs(face_value - 5.0) < 0.01) {
				face_offset += base_step_y;
				face_offset += base_step_x * 2;
			}
			return face_offset;
		}

		vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
		{
			vec2 face_offset = get_face_offset(FaceValue) + texcoord / 3;
			vec4 texcolor = Texel(tile_colors, face_offset);
			return texcolor;
		}
	]]

	return love.graphics.newShader(fs, vs)
end

return pla
