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
		uniform float world_size;
		uniform sampler2D tile_colors;
        uniform sampler2D tile_improvement_texture;
		uniform sampler2D tile_raiding_targets;
		uniform sampler2D tile_provinces;
		uniform sampler2D tile_neighbor_province;
		uniform float clicked_tile;
		uniform float player_tile;
		uniform float camera_distance_from_sphere;
		uniform float time;
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

		float max3(vec4 a) {
			return max(a.r, max(a.g, a.b));
		}

		float id_to_face(float tile_id, float world_size) {
			return floor(tile_id / world_size / world_size);
		}

		vec4 mix(vec4 a, vec4 b, float alpha) {
			return a * (1 - alpha) + b * alpha;
		}


		vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
		{
			float y = floor(texcoord.y * world_size);
			float x = floor(texcoord.x * world_size);
			float tile_id = x + y * world_size + FaceValue * world_size * world_size;
			// This variable stores uv coordinates of *a single tile*
			vec2 tile_uv = vec2((texcoord.x * world_size) - x, (texcoord.y * world_size) - y);

			float clicked_face = id_to_face(clicked_tile, world_size);
			float remainder = clicked_tile - clicked_face * world_size * world_size;
			float clicked_y = floor(remainder / world_size);
			float clicked_x = remainder - clicked_y * world_size + 1; // these +1s are needed for reasons I dont understand. Maybe some weird love2d thing compiling glsl as if its 1 indexed like lua?
			clicked_y += 1 - 0.5;
			clicked_x -= 1 - 0.5;
			clicked_y /= world_size;
			clicked_x /= world_size;
			vec2 clickedcoords = vec2(clicked_x, clicked_y);


			float player_face = id_to_face(player_tile, world_size);
			remainder = player_tile - player_face * world_size * world_size;
			float player_y = floor(remainder / world_size);
			float player_x = remainder - player_y * world_size + 1; // these +1s are needed for reasons I dont understand. Maybe some weird love2d thing compiling glsl as if its 1 indexed like lua?
			player_y += 1 - 0.5;
			player_x -= 1 - 0.5;
			player_y /= world_size;
			player_x /= world_size;
			vec2 playercoords = vec2(player_x, player_y);
			

			vec2 clicked = clickedcoords / 3;
			vec2 player = playercoords / 3;

			clicked += get_face_offset(clicked_face);
			player += get_face_offset(player_face);	

			vec2 face_offset = get_face_offset(FaceValue) + texcoord / 3;
			vec4 texcolor = Texel(tile_colors, face_offset);
            vec4 texcolor_improv = Texel(tile_improvement_texture, face_offset);
			vec4 texcolor_raiding = Texel(tile_raiding_targets, face_offset);
            
            if (camera_distance_from_sphere < 1) {
				// Clicked tile!
				if (abs(tile_id - clicked_tile) < 0.05) {
					float d = sin(time) * 0.025;
					if (abs(tile_uv.x - 0.5) > 0.40 + d || abs(tile_uv.y - 0.5) > 0.40 + d) {
						return vec4(0.85, 0.4, 0.8, 1);
					}
				}                
				// Tile borders!                
				if ((abs(tile_uv.x - 0.5) < 0.40) && (abs(tile_uv.y - 0.5) < 0.40) && (texcolor_improv.r > 0.5)) {
                    if (abs(tile_uv.x - 0.5) > 0.20 || abs(tile_uv.y - 0.5) > 0.20) {
						return vec4(0.1, 0.1, 0.1, 1);
					}					
				}
			}            
            
			if (texcolor.a < 0.5) {
				// this tile is covered by fog of war -- ignore province and river information!
				texcolor.a = 1.0;
			} else {
				// since this tile isn't under fog of war, we can render further details on it.
				// Province borders!
				vec4 my_bord = Texel(tile_provinces, face_offset);
				vec4 n_data = Texel(tile_neighbor_province, face_offset);

				vec4 clicked_bord = Texel(tile_provinces, clicked);
				vec4 player_bord = Texel(tile_provinces, player);

				float province_border_thickness = 0.1;
				vec4 province_border_color = vec4(0.4, 0.4, 0.4, 1);

				if (max3(abs(my_bord - player_bord)) < 0.0001) {
					province_border_color = vec4(0.95, 0.1, 0.1, 1);
					province_border_thickness = 0.2;
				}

				if (max3(abs(my_bord - clicked_bord)) < 0.0001) {
					province_border_color = vec4(0.85, 0.4, 0.2, 1);
					province_border_thickness = 0.4;
				}

				float up_b = (province_border_thickness - tile_uv.y);
				float down_b = (tile_uv.y - (1 - province_border_thickness));
				float left_b = (tile_uv.x - (1 - province_border_thickness));
				float right_b = (province_border_thickness - tile_uv.x);

				float thld = 0.8;

				if (n_data.g > thld) {
					if (up_b > 0) {
						return province_border_color;
					}
				}
				if (n_data.r > thld) {
					if (down_b > 0) {
						return province_border_color;
					}
				}
				if (n_data.b > thld) {
					if (left_b > 0) {
						return province_border_color;
					}
				}
				if (n_data.a > thld) {
					if (right_b > 0) {
						return province_border_color;
					}
				}

				//if ((n_data.g > 0.1) && (n_data.b > 0.1)) {
				//	if ((up_b > 0) && (left_b > 0)) {
				//		return province_border_color;
				//	}
				//}
			}

			float raiding_target_indicator = 0.0;
			if (texcolor_raiding.r > 0.5) {
				raiding_target_indicator = abs(fract(time * 0.4) - 0.5) * 2.0;
			}
			vec4 red_overlay = vec4(1, 0, 0, 1);            
			return texcolor * mix(color, red_overlay, raiding_target_indicator);
		}
	]]

	return love.graphics.newShader(fs, vs)
end

return pla
