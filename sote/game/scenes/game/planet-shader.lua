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
		#define PI 3.1415926535897932384626433832795

		uniform float world_size;
		uniform sampler2D tile_colors;
		uniform samplerCube face_id_cubemap;
		uniform sampler2D texture_index_cubemap;
		uniform sampler2D texture_atlas;

		uniform sampler2D province_colors; // stores colors assigned to provinces
		uniform sampler2D texture_sprawl_frequency;
		uniform sampler2D province_index; // sample to retrieve indices for province colors - it's technically a "tile" texture

		uniform sampler2D tile_provinces;
		uniform sampler2D tile_neighbor_province;
		uniform sampler2D tile_corner_neighbor_realm;
		uniform sampler2D tile_neighbor_realm;
		uniform sampler2D fog_of_war;

		uniform float clicked_tile;
		uniform float player_tile;
		uniform float camera_distance_from_sphere;
		uniform float time;
		uniform float show_terrain;

		varying float FaceValue;
		varying vec4 Position;

		vec2 get_face_offset(float face_value) {
			// 0 1 2
			// 3 4 5
			// - - -
			vec2 base_step_x = vec2(1, 0) / 3;
			vec2 base_step_y = vec2(0, 1) / 2;
			vec2 face_offset = vec2(0, 0);
			if (abs(face_value - 1.0) < 0.5) {
				face_offset += base_step_x;
			} else if (abs(face_value - 2.0) < 0.5) {
				face_offset += base_step_x * 2;
			} else if (abs(face_value - 3.0) < 0.5) {
				face_offset += base_step_y;
			} else if (abs(face_value - 4.0) < 0.5) {
				face_offset += base_step_y;
				face_offset += base_step_x;
			} else if (abs(face_value - 5.0) < 0.5) {
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

		//float rand_3_1(vec3 v) {
		//	return fract(sin(
		//		dot(
		//			v,
		//			vec3(0.9898, 78.233, 34.153546))
		//		) * 443758.5553123
		//	);
		//}

		float rand_3_1_2(vec3 v) {
			return fract(sin(
				dot(
					v,
					vec3(85.9898, 0.233, 18.153546))
				) * 290556.452848
			);
		}

		float rand_3_1(vec3 v, vec3 dot_with, float mult) {
			return fract(sin(dot(v, dot_with)) * mult);
		}

		float smooth_noise(vec3 v, vec3 dot_with, float mult) {
			vec3 integer_part = floor(v);
			vec3 fractional_part = fract(v);

			vec3 smooth_step = fractional_part
				* fractional_part
				* (3.0 - 2.0 * fractional_part);

			float local_value = rand_3_1(integer_part, dot_with, mult);

			float r_0_0_0 = rand_3_1(integer_part + vec3(0, 0, 0), dot_with, mult);
			float r_0_0_1 = rand_3_1(integer_part + vec3(0, 0, 1), dot_with, mult);
			float r_0_1_0 = rand_3_1(integer_part + vec3(0, 1, 0), dot_with, mult);
			float r_0_1_1 = rand_3_1(integer_part + vec3(0, 1, 1), dot_with, mult);
			float r_1_0_0 = rand_3_1(integer_part + vec3(1, 0, 0), dot_with, mult);
			float r_1_0_1 = rand_3_1(integer_part + vec3(1, 0, 1), dot_with, mult);
			float r_1_1_0 = rand_3_1(integer_part + vec3(1, 1, 0), dot_with, mult);
			float r_1_1_1 = rand_3_1(integer_part + vec3(1, 1, 1), dot_with, mult);

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

			//return (data.b + data.a + data.r + data.g) / 4;

			return data.b * d_right    * d_bottom
				+ data.a  * d_right     * d_top
				+ data.r  * d_left      * d_top
				+ data.g  * d_left      * d_bottom;

			//return
			//	data.b * pretty_function(d_left, d_top)
			//	+ data.a  * pretty_function(d_left, d_bottom)
			//	+ data.r  * pretty_function(d_right, d_bottom)
			//	+ data.g  * pretty_function(d_right, d_top);

		}

		// quite nice looking set of values, leaving them there for future experiments
		// vec3 albedo_forest = vec3(67.0 / 255.0, 89.0 / 255.0, 52.0 / 255.0) * (noise_1000 * 0.01 + 0.99);
		// vec3 albedo_grass = vec3(112.0 / 255.0, 141.0 / 255.0, 75.0 / 255.0) * (noise_100 * 0.01 + 0.99);
		// vec3 albedo_sand = vec3(223.0 / 255.0, 220.0 / 255.0, 207.0 / 255.0);
		// vec3 albedo_wasteland = vec3(135.0 / 255.0, 118.0 / 255.0, 98.0 / 255.0);
		// vec3 sea_albedo = vec3(0.75, 0.86, 0.98);
		// vec4(sea_albedo / (1 + 0.2 * log(1 + floor(sea / 250.0))), 1);

		vec2 cartesian_to_uv(vec3 coord, float face) {
			vec3 absolute_value = abs(coord);

			float max_axis = 1.0;
			vec2 result = vec2(1.0, 1.0);

			if (abs(face - 3.0) < 0.5) {
				max_axis = absolute_value.x;
				result = vec2(-coord.z, coord.y);
			}

			if (abs(face - 1.0) < 0.5) {
				max_axis = absolute_value.x;
				result = vec2(coord.z, coord.y);
			}

			if (abs(face - 4.0) < 0.5) {
				max_axis = absolute_value.y;
				result = vec2(coord.z, coord.x);
			}

			if (abs(face - 5.0) < 0.5) {
				max_axis = absolute_value.y;
				result = vec2(-coord.z, coord.x);
			}

			if (abs(face - 0.0) < 0.5) {
				max_axis = absolute_value.z;
				result = vec2(coord.x, coord.y);
			}

			if (abs(face - 2.0) < 0.5) {
				max_axis = absolute_value.z;
				result = vec2(-coord.x, coord.y);
			}

			return 0.5 * (result / max_axis + 1.0);
		}

		vec2 uvface_to_texcoord(vec2 uv, float face) {
			vec2 offset = get_face_offset(face);
			return vec2(uv.x / 3, uv.y / 2) + offset;
		}


		vec4 sample_texture_atlas_by_image_index(float texture_index, float u, float v) {
			texture_index = texture_index + 0.5;
			float padding = 18.0 / 2048.0;
			float shift_per_image = 256.0 / 2048.0;
			float row = floor(texture_index / 7.0);
			float column = floor(texture_index - row * 7.0);
			float x_start = (shift_per_image + padding * 2) * row + padding;
			float y_start = (shift_per_image + padding * 2) * column + padding;
			float local_x = u * shift_per_image;
			float local_y = v * shift_per_image;
			vec2 texture_uv = vec2(y_start + local_y, x_start + local_x);
			return Texel(texture_atlas, texture_uv);
		}

		float corner_border_check(vec2 tile_uv, vec2 anchor, float radius, float thickness, float margin) {
			float distance_from_corner_anchor = distance(tile_uv, anchor);
			if (distance_from_corner_anchor > radius) {
				if (distance_from_corner_anchor - radius < thickness) {
					return 1.0;
				}
			}
			return 0.0;
		}

		float parabola_for_grid(float x) {
			x = 2 * x - 1;
			return (1 - x * x);
		}

		vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
		{
			float noise_100  = smooth_noise(Position.xyz * 1000.0, vec3(0.9898, 78.233, 34.153546), 443758.5553123);
			float noise_100_2  = smooth_noise(Position.xyz * 1000.0, vec3(86.9898, 1.233, 50.153546), 443758.5553123);
			float noise_100_3 = smooth_noise(Position.xyz * 1000.0, vec3(53.9898, 15.233, 10.153546), 443758.5553123);

			float high_frequency_noise = smooth_noise(Position.xyz * 10000.0, vec3(53.9898, 15.233, 10.153546), 443758.5553123);

			//return vec4(noise_100, noise_100_2, noise_100_3, 1);


			//float sea_ratio = 0.0;
			//float total_counter = 0.0;
			//int M = 10;

			//for (int i = -M; i <= M; i++) {
			//	for (int j = -M; j <= M; j++) {
			//		for (int k = -M; j <= M; j++) {
			//			vec3 new_position = Position.xyz + vec3(i, j, k) * 0.0005;
			//			float new_face = Texel(face_id_cubemap, new_position).r * 6.0;
			//			vec2 pixel_center_shift = vec2(0.5 / world_size / 3.0, -0.5 / world_size / 3.0);
			//			vec2 new_uv = cartesian_to_uv(new_position, new_face) + pixel_center_shift;
			//			vec2 new_texcoord = uvface_to_texcoord(new_uv, new_face);
			//			sea_ratio += Texel(texture_index_cubemap, new_texcoord).b;
			//			total_counter += 1.0;
			//		}
			//	}
			//}
			//sea_ratio /= total_counter;
			//float noise_amplitude_multiplier = abs(sea_ratio - 0.5) * 2.0;

			vec3 original_position = Position.xyz;
			vec3 shift = (vec3(noise_100, noise_100_2, noise_100_3) - 0.5f);
			vec3 shifted_position = original_position + shift * 0.0015;
			vec3 slightly_shifted_position = original_position + shift * 0.001;

			float phi = asin(original_position.y); // sqrt(sqrt(1 - original_position.y * original_position.y));
			float psi = asin(original_position.z / length(original_position.xz));

			if (abs(phi) > 1) {
				phi = texcoord.x;
				psi = texcoord.y;
			}

			vec2 original_texcoord = texcoord;
			float original_face = FaceValue;

			shifted_position /= length(shifted_position);
			slightly_shifted_position /= length(slightly_shifted_position);

			float shifted_face = Texel(face_id_cubemap, shifted_position).r * 6.0;
			float slightly_shifted_face = Texel(face_id_cubemap, slightly_shifted_position).r * 6.0;


			vec2 shifted_texcoord = cartesian_to_uv(shifted_position, shifted_face);
			vec2 slightly_shifted_texcoord = cartesian_to_uv(slightly_shifted_position, slightly_shifted_face);

			float y = floor(shifted_texcoord.y * world_size);
			float x = floor(shifted_texcoord.x * world_size);

			float slightly_shifted_y = floor(slightly_shifted_texcoord.y * world_size);
			float slightly_shifted_x = floor(slightly_shifted_texcoord.x * world_size);

			float original_y = floor(original_texcoord.y * world_size);
			float original_x = floor(original_texcoord.x * world_size);

			float tile_id = x + y * world_size + shifted_face * world_size * world_size;
			float original_tile_id = original_x + original_y * world_size + original_face * world_size * world_size;

			// This variable stores uv coordinates of *a single tile*
			vec2 tile_uv = vec2((slightly_shifted_texcoord.x * world_size) - slightly_shifted_x, (slightly_shifted_texcoord.y * world_size) - slightly_shifted_y);
			vec2 original_tile_uv = vec2((original_texcoord.x * world_size) - original_x, (original_texcoord.y * world_size) - original_y);

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


			vec2 clicked = clickedcoords * vec2(1.0/3.0, 1.0/2.0);
			vec2 player = playercoords * vec2(1.0/3.0, 1.0/2.0);

			clicked += get_face_offset(clicked_face);
			player += get_face_offset(player_face);

			vec2 face_offset = get_face_offset(shifted_face) + shifted_texcoord * vec2(1.0/3.0, 1.0/2.0);
			vec2 slightly_shifted_face_offset = get_face_offset(slightly_shifted_face) + slightly_shifted_texcoord * vec2(1.0/3.0, 1.0/2.0);
			vec2 original_face_offset = get_face_offset(original_face) + original_texcoord * vec2(1.0/3.0, 1.0/2.0);

			vec2 province_index_uv = Texel(province_index, slightly_shifted_face_offset).rg;
			vec4 fog_of_war_rgba = Texel(fog_of_war, province_index_uv);
			if (fog_of_war_rgba.a > 0.5) {
				return fog_of_war_rgba;
			}
			vec4 texcolor = Texel(tile_colors, face_offset) * Texel(province_colors, province_index_uv);
			float sprawl_frequency = Texel(texture_sprawl_frequency, province_index_uv).r;

			vec3 radius = shifted_position;
			radius.y = 0.f;
			vec3 tangent = vec3(radius.z, 0, -radius.x);

			//return vec4(sprawl_heat, sprawl_heat, sprawl_heat, 1);
			if (show_terrain > 0.5) {
				float index_scaler = 1.0 / 64.0;

				float counter = 0.0;
				int N = 2;
				//float shift_unit = 0.0005;
				float shift_unit = 0.0010;

				vec2 origin_new_uv = shifted_texcoord;
				vec2 origin_texcoord = uvface_to_texcoord(origin_new_uv, shifted_face);
				float origin_is_sea = Texel(texture_index_cubemap, origin_texcoord).b;

				float is_coast = 0.f;

				float counter_land = 0.f;
				float counter_sea = 0.f;

				//detecting coast:
				for (int i = -N; i <= N; i++) {
					for (int j = -N; j <= N; j++) {
						vec3 new_position = shifted_position + vec3(0, j, 0) * shift_unit + tangent * i * shift_unit;
						float new_face = Texel(face_id_cubemap, new_position).r * 6.0;
						vec2 new_uv = cartesian_to_uv(new_position, new_face);
						vec2 new_texcoord = uvface_to_texcoord(new_uv, new_face);

						float target_is_sea = Texel(texture_index_cubemap, new_texcoord).b;

						if (target_is_sea > 0.5f) {
							counter_sea += 2.0;
						} else {
							counter_land += 1.0;
						}
					}
				}

				vec4 average_texture;

				if (counter_land > counter_sea) {
					if (counter_sea > 0.f) {
						is_coast = 1.f;
					}
				}


				if (counter_land == 0.f || counter_sea == 0.f) {
					// float texture_index = Texel(texture_index_cubemap, origin_texcoord).r / index_scaler - 1.0;
					// average_texture += sample_texture_atlas_by_image_index(texture_index, fract(phi * 200), fract(psi * 200));
					// counter += 1.f;

					if (counter_sea > 0.f) {
						average_texture += sample_texture_atlas_by_image_index(13.f, fract(phi * 200), fract(psi * 200));
						counter += 1.f;
					}
				} else {
					float total_score = counter_land + counter_sea;

					float dist_sea = counter_sea / total_score;
					float dist_land = counter_land / total_score;

					average_texture += sample_texture_atlas_by_image_index(13.f, fract(phi * 200), fract(psi * 200)) * dist_sea;
					average_texture += sample_texture_atlas_by_image_index(4.0, fract(phi * 200), fract(psi * 200)) * dist_land;

					counter += 1.f;
				}

				if (counter_land > counter_sea) {
					for (int i = -N; i <= N; i++) {
						for (int j = -N; j <= N; j++) {
							vec3 new_position = shifted_position + vec3(0, j, 0) * shift_unit + tangent * i * shift_unit;
							float new_face = Texel(face_id_cubemap, new_position).r * 6.0;
							vec2 new_uv = cartesian_to_uv(new_position, new_face);
							vec2 new_texcoord = uvface_to_texcoord(new_uv, new_face);

							float target_is_sea = Texel(texture_index_cubemap, new_texcoord).b;

							float sprawl_heat = Texel(texture_index_cubemap, new_texcoord).g;
							if (!((target_is_sea == 1.0) && (is_coast == 1.0))) {
								if ((Texel(texture_index_cubemap, new_texcoord).r > 0)) {
									float texture_index = Texel(texture_index_cubemap, new_texcoord).r / index_scaler - 1.0;
									average_texture += sample_texture_atlas_by_image_index(texture_index, fract(phi * 200), fract(psi * 200));

									vec4 sprawl_texture = sample_texture_atlas_by_image_index(29.0, fract(phi * 200), fract(psi * 200));
									float sprawl_weight = sprawl_heat * sprawl_heat * sprawl_frequency * 10.0;
									average_texture += sprawl_texture * sprawl_weight;

									counter += 1 + sprawl_heat * sprawl_weight;
								}
							}
						}
					}
				}

				//if (is_coast == 1.0) {
				//	average_texture = sample_texture_atlas_by_image_index(4.0, fract(phi * 200), fract(psi * 200));
				//	counter = 1.0;
				//}

				average_texture /= counter;
				float terrain_alpha = (1 / camera_distance_from_sphere) * 1.3;
				if (terrain_alpha > 1) {
					terrain_alpha = 1;
				}
				texcolor = mix(texcolor, average_texture, terrain_alpha);
			}

			float distance_for_improvments_and_clicked_tiles = 0.15; // controls the distance threshold from the sphere at which details on tiles are rendered.
			if (camera_distance_from_sphere < distance_for_improvments_and_clicked_tiles) {
				// Clicked tile!
				if (abs(original_tile_id - clicked_tile) < 0.05) {
					float d = sin(time) * 0.025;
					float distance_from_tile_center = distance(vec2(0.5, 0.5), original_tile_uv);
					if (distance_from_tile_center > 0.40 + d && distance_from_tile_center < 0.5 + d) {
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

			vec4 result_province_border_colour = vec4(1.0, 1.0, 1.0, 1.0);
			vec4 result_realm_border_colour = vec4(1.0, 1.0, 1.0, 1.0);

			float is_realm_border = 0.f;

			if (texcolor.a < 0.5) {
				// this tile is covered by fog of war -- ignore province and river information!
				texcolor.a = 1.0;
			} else {
				float province_border_thickness = 0.04;
				vec4 province_border_color = vec4(1.0, 0.95, 0.95, 1);
				vec4 realm_border_color = vec4(1.0, 0.8, 0.8, 1);
				float threshold = 0.8;

				// We need to handle realm borders before province borders.
				// We're gonna do it here.

				//float same_realm_value = sample_value_from_sphere(tile_neighbor_realm, face_offset, tile_uv);
				//if ((same_realm_value > 0.022) && (same_realm_value < 1)) {
				//	return realm_border_color;
				//}

				float margin = 0.08;
				float radius = 0.2;
				float thickness = 0.07;

				vec2 corner_0_0_center = vec2(margin + radius, margin + radius);
				vec2 corner_0_1_center = vec2(margin + radius, 1.0 - margin - radius);
				vec2 corner_1_0_center = vec2(1.0 - margin - radius, margin + radius);
				vec2 corner_1_1_center = vec2(1.0 - margin - radius, 1.0 - margin - radius);

				float realm_up_b = (thickness - tile_uv.y);
				float realm_down_b = (tile_uv.y - (1 - thickness));
				float realm_left_b = (tile_uv.x - (1 - thickness));
				float realm_right_b = (thickness - tile_uv.x);

				vec4 realm_neighbor_data = Texel(tile_neighbor_realm, slightly_shifted_face_offset);
				vec4 realm_corner_neighbor_data = Texel(tile_corner_neighbor_realm, slightly_shifted_face_offset);

				float realm_threshold = 0.1;


				float neigh_up = 0.0;
				float neigh_down = 0.0;
				float neigh_left = 0.0;
				float neigh_right = 0.0;

				if (realm_neighbor_data.g > threshold) {
					neigh_up = 1.0;
				}
				if (realm_neighbor_data.r > threshold) {
					neigh_down = 1.0;
				}
				if (realm_neighbor_data.b > threshold) {
					neigh_left = 1.0;
				}
				if (realm_neighbor_data.a > threshold) {
					neigh_right = 1.0;
				}

				float cornered_pixel = 0.0;

				// lonely corner

				if (neigh_left + neigh_up < 0.5) {
					if (realm_corner_neighbor_data.g > realm_threshold) {
						if ((tile_uv.x > 1.0 - margin - radius) && (tile_uv.y < margin + radius)) {
							if (corner_border_check(tile_uv, vec2(1, 0), margin - thickness, thickness, 0) > 0.5) {
								result_province_border_colour = realm_border_color;
							}

							cornered_pixel = 1.0;
							is_realm_border = 1.0;
						}
					}
				}

				if (neigh_right + neigh_down < 0.5) {
					if (realm_corner_neighbor_data.a > realm_threshold) {
						if ((tile_uv.x < margin + radius) && (tile_uv.y > 1.0 - margin - radius)) {
							if (corner_border_check(tile_uv, vec2(0, 1), margin - thickness, thickness, 0) > 0.5) {
								result_province_border_colour = realm_border_color;
							}

							cornered_pixel = 1.0;
							is_realm_border = 1.0;
						}
					}
				}

				if (neigh_left + neigh_down < 0.5) {
					if (realm_corner_neighbor_data.r > realm_threshold) {
						if ((tile_uv.x > 1.0 - margin - radius) && (tile_uv.y > 1.0 - margin - radius)) {
							if (corner_border_check(tile_uv, vec2(1, 1), margin - thickness, thickness, 0) > 0.5) {
								result_province_border_colour = realm_border_color;
							}

							cornered_pixel = 1.0;
							is_realm_border = 1.0;
						}
					}
				}

				if (neigh_right + neigh_up < 0.5) {
					if (realm_corner_neighbor_data.b > realm_threshold) {
						if ((tile_uv.x < margin + radius) && (tile_uv.y < margin + radius)) {
							if (corner_border_check(tile_uv, vec2(0, 0), margin - thickness, thickness, 0) > 0.5) {
								result_province_border_colour = realm_border_color;
							}

							cornered_pixel = 1.0;
							is_realm_border = 1.0;
						}
					}
				}

				// corner with a lot of friends

				if (neigh_left + neigh_up > 1.5) {
					if (realm_corner_neighbor_data.g > realm_threshold) {
						if ((tile_uv.x > 1.0 - margin - radius) && (tile_uv.y < margin + radius)) {
							if (corner_border_check(tile_uv, corner_1_0_center, radius, thickness, margin) > 0.5) {
								result_province_border_colour = realm_border_color;
							}

							cornered_pixel = 1.0;
							is_realm_border = 1.0;
						}
					}
				}

				if (neigh_right + neigh_down > 1.5) {
					if (realm_corner_neighbor_data.a > realm_threshold) {
						if ((tile_uv.x < margin + radius) && (tile_uv.y > 1.0 - margin - radius)) {
							if (corner_border_check(tile_uv, corner_0_1_center, radius, thickness, margin) > 0.5) {
								result_province_border_colour = realm_border_color;
							}

							cornered_pixel = 1.0;
							is_realm_border = 1.0;
						}
					}
				}

				if (neigh_left + neigh_down > 1.5) {
					if (realm_corner_neighbor_data.r > realm_threshold) {
						if ((tile_uv.x > 1.0 - margin - radius) && (tile_uv.y > 1.0 - margin - radius)) {
							if (corner_border_check(tile_uv, corner_1_1_center, radius, thickness, margin) > 0.5) {
								result_province_border_colour = realm_border_color;
							}

							cornered_pixel = 1.0;
							is_realm_border = 1.0;
						}
					}
				}

				if (neigh_right + neigh_up > 1.5) {
					if (realm_corner_neighbor_data.b > realm_threshold) {
						if ((tile_uv.x < margin + radius) && (tile_uv.y < margin + radius)) {
							if (corner_border_check(tile_uv, corner_0_0_center, radius, thickness, margin) > 0.5) {
								result_province_border_colour = realm_border_color;
							}

							cornered_pixel = 1.0;
							is_realm_border = 1.0;
						}
					}
				}

				if (cornered_pixel < 0.5) {
					if (realm_neighbor_data.g > threshold) {
						if ((tile_uv.y > margin - thickness) && (tile_uv.y < margin)) {
							result_province_border_colour = realm_border_color;
						}

						if (tile_uv.y < margin) {
							is_realm_border = 1.0;
						}
					}

					if (realm_neighbor_data.r > threshold) {
						if ((tile_uv.y < 1.0 - margin + thickness) && (tile_uv.y > 1.0 - margin)) {
							result_province_border_colour = realm_border_color;
						}

						if (tile_uv.y > 1.0 - margin) {
							is_realm_border = 1.0;
						}
					}

					if (realm_neighbor_data.b > threshold) {
						if ((tile_uv.x < 1.0 - margin + thickness) && (tile_uv.x > 1.0 - margin)) {
							result_province_border_colour = realm_border_color;
						}

						if (tile_uv.x > 1.0 - margin) {
							is_realm_border = 1.0;
						}
					}

					if (realm_neighbor_data.a > threshold) {
						if ((tile_uv.x > margin - thickness) && (tile_uv.x < margin)) {
							result_province_border_colour = realm_border_color;
						}

						if (tile_uv.x < margin) {
							is_realm_border = 1.0;
						}
					}
				}

				// since this tile isn't under fog of war, we can render further details on it.
				// Province borders!
				vec4 my_bord = Texel(tile_provinces, slightly_shifted_face_offset);
				vec4 clicked_bord = Texel(tile_provinces, clicked);
				vec4 player_bord = Texel(tile_provinces, player);

				if(camera_distance_from_sphere < 1 && ((is_realm_border < 0.5) || (max3(abs(my_bord - player_bord)) < 0.0001) || (max3(abs(my_bord - clicked_bord)) < 0.0001))) {
					vec4 n_data = Texel(tile_neighbor_province, slightly_shifted_face_offset);

					if (max3(abs(my_bord - player_bord)) < 0.0001) {
						province_border_color = vec4(0.95, 0.1, 0.1, 1);
						province_border_thickness = 0.04;
					}

					if (max3(abs(my_bord - clicked_bord)) < 0.0001) {
						province_border_color = vec4(0.85, 0.4, 0.2, 1);
						province_border_thickness = 0.04;
					}

					float up_b = (province_border_thickness - tile_uv.y);
					float down_b = (tile_uv.y - (1 - province_border_thickness));
					float left_b = (tile_uv.x - (1 - province_border_thickness));
					float right_b = (province_border_thickness - tile_uv.x);

					if (n_data.g > threshold && up_b > 0) {
						result_province_border_colour = province_border_color;
					}
					if (n_data.r > threshold && down_b > 0) {
						result_province_border_colour = province_border_color;
					}
					if (n_data.b > threshold && left_b > 0) {
						result_province_border_colour = province_border_color;
					}
					if (n_data.a > threshold && right_b > 0) {
						result_province_border_colour = province_border_color;
					}

					//if ((n_data.g > 0.1) && (n_data.b > 0.1)) {
					//	if ((up_b > 0) && (left_b > 0)) {
					//		return province_border_color;
					//	}
					//}
				}
			}

			vec4 high_frequency_noise_texture = 0.95 + 0.05 * vec4(high_frequency_noise, high_frequency_noise, high_frequency_noise, 1);
			return texcolor * high_frequency_noise_texture * color * result_province_border_colour * result_realm_border_colour;
		}
	]]

	return love.graphics.newShader(fs, vs)
end

return pla
