local pla = {}

function pla.get_shader()
	local vs = [[
		attribute float Face;
		varying float FaceValue;
		varying vec4 Position;

		uniform mat4 model;
		uniform mat4 view;
		uniform mat4 projection;

		vec4 position(mat4 _, vec4 vertex_position)
		{
			FaceValue = Face;
			Position = vertex_position;
			return projection * view * model * vertex_position;
		}
	]]
	local fs = [[
		uniform float world_size;
		uniform sampler2D tile_colors;

		uniform sampler2D province_colors; // stores colors assigned to provinces
		uniform sampler2D province_index; // sample to retrieve indices for province colors - it's technically a "tile" texture
		uniform float max_province_index;

		uniform sampler2D tile_provinces;
		uniform sampler2D tile_neighbor_province;
		uniform sampler2D tile_corner_neighbor_realm;
		uniform sampler2D tile_neighbor_realm;
		uniform sampler2D fog_of_war;

		uniform float clicked_tile;
		uniform float player_tile;
		uniform float camera_distance_from_sphere;
		uniform float time;
		varying float FaceValue;
		varying vec4 Position;

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

		float rand_2_1(vec2 v) {
			return fract(sin(
				dot(
					v,
					vec2(0.9898,78.233))
				) * 43758.5453123
			);
		}

		float rand_3_1(vec3 v) {
			return fract(sin(
				dot(
					v,
					vec3(0.9898, 78.233, 34.153546))
				) * 443758.5553123
			);
		}

		float smooth_noise(vec3 v) {
			vec3 integer_part = floor(v);
			vec3 fractional_part = fract(v);

			vec3 smooth_step = fractional_part
				* fractional_part
				* (3.0 - 2.0 * fractional_part);

			float local_value = rand_3_1(integer_part);

			float r_0_0_0 = rand_3_1(integer_part + vec3(0, 0, 0));
			float r_0_0_1 = rand_3_1(integer_part + vec3(0, 0, 1));
			float r_0_1_0 = rand_3_1(integer_part + vec3(0, 1, 0));
			float r_0_1_1 = rand_3_1(integer_part + vec3(0, 1, 1));
			float r_1_0_0 = rand_3_1(integer_part + vec3(1, 0, 0));
			float r_1_0_1 = rand_3_1(integer_part + vec3(1, 0, 1));
			float r_1_1_0 = rand_3_1(integer_part + vec3(1, 1, 0));
			float r_1_1_1 = rand_3_1(integer_part + vec3(1, 1, 1));

			return
				  r_0_0_0 * (1 - smooth_step.x) * (1 - smooth_step.y) * (1 - smooth_step.z)
				+ r_0_0_1 * (1 - smooth_step.x) * (1 - smooth_step.y) * (smooth_step.z)
				+ r_0_1_0 * (1 - smooth_step.x) * (smooth_step.y) * (1 - smooth_step.z)
				+ r_0_1_1 * (1 - smooth_step.x) * (smooth_step.y) * (smooth_step.z)
				+ r_1_0_0 * (smooth_step.x) * (1 - smooth_step.y) * (1 - smooth_step.z)
				+ r_1_0_1 * (smooth_step.x) * (1 - smooth_step.y) * (smooth_step.z)
				+ r_1_1_0 * (smooth_step.x) * (smooth_step.y) * (1 - smooth_step.z)
				+ r_1_1_1 * (smooth_step.x) * (smooth_step.y) * (smooth_step.z);
		}

		float smoothstep(float x) {
			return x * x * (3 - 2 * x);
		}

		// classic interpolation
		float simple_function(float x, float y) {
			return (1 - x) * (1 - y);
		}

		float fancy_function(float x, float y) {
			return -(x * x + y * y - x * y - 1) * (1 - x) * (1 - y);
		}

		// to prevent tile-central values from being large
		float cirle_function(float x, float y) {
			return ((x - 0.5) * (x - 0.5) + (y - 0.5) * (y - 0.5));
		}

		float soft_box(float x, float y) {
			return ((x - 0.5) * (x - 0.5) * (x - 0.5) * (x - 0.5) + (y - 0.5) * (y - 0.5) * (y - 0.5) * (y - 0.5));
		}

		float pretty_function(float x, float y) {
			return simple_function(x, y) * soft_box(x, y);
		}

		float sample_value_from_sphere(sampler2D target_tile_texture, vec2 face_offset, vec2 tile_uv) {
			vec4 data = Texel(target_tile_texture, face_offset);

			float d_top 	= smoothstep(tile_uv.y);
			float d_bottom 	= smoothstep(1 - tile_uv.y);
			float d_right 	= smoothstep(1 - tile_uv.x);
			float d_left 	= smoothstep(tile_uv.x);

			//return data.b * d_right    * d_bottom
			//	+ data.a  * d_right     * d_top
			//	+ data.r  * d_left      * d_top
			//	+ data.g  * d_left      * d_bottom;

			return
				data.b * pretty_function(d_left, d_top)
				+ data.a  * pretty_function(d_left, d_bottom)
				+ data.r  * pretty_function(d_right, d_bottom)
				+ data.g  * pretty_function(d_right, d_top);

		}

		// quite nice looking set of values, leaving them there for future experiments
		// vec3 albedo_forest = vec3(67.0 / 255.0, 89.0 / 255.0, 52.0 / 255.0) * (noise_1000 * 0.01 + 0.99);
		// vec3 albedo_grass = vec3(112.0 / 255.0, 141.0 / 255.0, 75.0 / 255.0) * (noise_100 * 0.01 + 0.99);
		// vec3 albedo_sand = vec3(223.0 / 255.0, 220.0 / 255.0, 207.0 / 255.0);
		// vec3 albedo_wasteland = vec3(135.0 / 255.0, 118.0 / 255.0, 98.0 / 255.0);
		// vec3 sea_albedo = vec3(0.75, 0.86, 0.98);
		// vec4(sea_albedo / (1 + 0.2 * log(1 + floor(sea / 250.0))), 1);

		vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
		{
			float noise_100  = smooth_noise((vec3(1, 1, 1) + Position.xyz) * 100.0);
			//float noise_250  = smooth_noise(-Position.xyz * 250.0);
			//float noise_500  = smooth_noise(Position.xyz * 500.0);
			//float noise_1000 = smooth_noise(Position.xyz * 1000.0);

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

			vec2 province_index_uv = Texel(province_index, face_offset).rg;
			vec4 fog_of_war_rgba = Texel(fog_of_war, province_index_uv);
			if (fog_of_war_rgba.a > 0.5) {
				return fog_of_war_rgba;
			}
			vec4 texcolor = Texel(tile_colors, face_offset) * Texel(province_colors, province_index_uv);

			float distance_for_improvments_and_clicked_tiles = 0.15; // controls the distance threshold from the sphere at which details on tiles are rendered.
			if (camera_distance_from_sphere < distance_for_improvments_and_clicked_tiles) {
				// Clicked tile!
				if (abs(tile_id - clicked_tile) < 0.05) {
					float d = sin(time) * 0.025;
					if (abs(tile_uv.x - 0.5) > 0.40 + d || abs(tile_uv.y - 0.5) > 0.40 + d) {
						return vec4(0.85, 0.4, 0.8, 1);
					}
				}
				// Tile borders!
				//if ((abs(tile_uv.x - 0.5) < 0.40) && (abs(tile_uv.y - 0.5) < 0.40) && (texcolor_improv.r > 0.5)) {
				//	if (abs(tile_uv.x - 0.5) > 0.20 || abs(tile_uv.y - 0.5) > 0.20) {
				//		return vec4(0.1, 0.1, 0.1, 1);
				//	}
				//}
			}

			if (texcolor.a < 0.5) {
				// this tile is covered by fog of war -- ignore province and river information!
				texcolor.a = 1.0;
			} else {
				float province_border_thickness = 0.05;
				vec4 province_border_color = vec4(0.45, 0.45, 0.45, 1);
				float realm_border_thickness = 0.2;
				vec4 realm_border_color = vec4(0.35, 0.4, 0.5, 1);
				float threshold = 0.8;

				// We need to handle realm borders before province borders.
				// We're gonna do it here.

				//float same_realm_value = sample_value_from_sphere(tile_neighbor_realm, face_offset, tile_uv);
				//if ((same_realm_value > 0.022) && (same_realm_value < 1)) {
				//	return realm_border_color;
				//}

				float realm_up_b = (realm_border_thickness - tile_uv.y);
				float realm_down_b = (tile_uv.y - (1 - realm_border_thickness));
				float realm_left_b = (tile_uv.x - (1 - realm_border_thickness));
				float realm_right_b = (realm_border_thickness - tile_uv.x);
				vec4 realm_corner_neighbor_data = Texel(tile_corner_neighbor_realm, face_offset);
				float realm_threshold = 0.1;

				if (realm_corner_neighbor_data.g  > realm_threshold && realm_up_b > 0 && realm_left_b > 0) {
					return realm_border_color;
				}
				if (realm_corner_neighbor_data.a > realm_threshold && realm_down_b > 0 && realm_right_b > 0) {
					return realm_border_color;
				}
				if (realm_corner_neighbor_data.r > realm_threshold && realm_left_b > 0 && realm_down_b > 0 ) {
					return realm_border_color;
				}
				if (realm_corner_neighbor_data.b > realm_threshold && realm_right_b > 0 && realm_up_b > 0) {
					return realm_border_color;
				}

				vec4 realm_neighbor_data = Texel(tile_neighbor_realm, face_offset);

				if (realm_neighbor_data.g > threshold && realm_up_b > 0) {
					return realm_border_color;
				}
				if (realm_neighbor_data.r > threshold && realm_down_b > 0) {
					return realm_border_color;
				}
				if (realm_neighbor_data.b > threshold && realm_left_b > 0) {
					return realm_border_color;
				}
				if (realm_neighbor_data.a > threshold && realm_right_b > 0) {
					return realm_border_color;
				}


				// since this tile isn't under fog of war, we can render further details on it.
				// Province borders!
				if(camera_distance_from_sphere < 1) {
					vec4 my_bord = Texel(tile_provinces, face_offset);
					vec4 n_data = Texel(tile_neighbor_province, face_offset);

					vec4 clicked_bord = Texel(tile_provinces, clicked);
					vec4 player_bord = Texel(tile_provinces, player);

					if (max3(abs(my_bord - player_bord)) < 0.0001) {
						province_border_color = vec4(0.95, 0.1, 0.1, 1);
						province_border_thickness = 0.35;
					}

					if (max3(abs(my_bord - clicked_bord)) < 0.0001) {
						province_border_color = vec4(0.85, 0.4, 0.2, 1);
						province_border_thickness = 0.3;
					}

					float up_b = (province_border_thickness - tile_uv.y);
					float down_b = (tile_uv.y - (1 - province_border_thickness));
					float left_b = (tile_uv.x - (1 - province_border_thickness));
					float right_b = (province_border_thickness - tile_uv.x);

					if (n_data.g > threshold && up_b > 0) {
						return province_border_color;
					}
					if (n_data.r > threshold && down_b > 0) {
						return province_border_color;
					}
					if (n_data.b > threshold && left_b > 0) {
						return province_border_color;
					}
					if (n_data.a > threshold && right_b > 0) {
						return province_border_color;
					}

					//if ((n_data.g > 0.1) && (n_data.b > 0.1)) {
					//	if ((up_b > 0) && (left_b > 0)) {
					//		return province_border_color;
					//	}
					//}
				}
			}

			return texcolor * color;
		}
	]]

	return love.graphics.newShader(fs, vs)
end

return pla
